import 'dart:async';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/config/env_config.dart';
import '../core/database/database_helper.dart';
import '../core/database/patient_dao.dart';
import '../core/database/readings_dao.dart';
import '../core/utils/app_logger.dart';
import '../core/network/api_client.dart';
import '../core/utils/result.dart';
import '../models/patient.dart';
import '../models/vital_reading.dart';
import '../services/ble_protocol_registry.dart';
import '../services/device_auto_submit_service.dart';
import '../services/service_locator.dart';

enum AppState { splash, register, otp, success, home, sessionExpired }

class AppProvider extends ChangeNotifier {
  static const _sessionActiveKey = 'session_active';
  static const _lastActivityKey = 'last_activity_ms';
  static const _patientApiKeyKey = 'patient_api_key';
  static const _patientApiSecretKey = 'patient_api_secret';

  AppState _state = AppState.splash;
  Patient? _patient;
  List<VitalReading> _readings = [];
  bool _isLoggedIn = false;
  bool _isOnline = true;
  bool _isDeviceConnected = false;
  int _pendingSyncCount = 0;
  int _unreadNotificationCount = 0;
  String _phoneNumber = '';
  String _otpCode = '';
  int _currentTab = 0;
  bool _isLoading = false;
  String? _errorMessage;

  final _services = ServiceLocator.instance;
  final _readingsDao = ReadingsDao();
  final _patientDao = PatientDao();
  DeviceAutoSubmitService? _autoSubmitService;

  AppState get state => _state;
  Patient? get patient => _patient;
  Patient? get currentPatient => _patient;
  List<VitalReading> get readings => _readings;
  bool get isLoggedIn => _isLoggedIn;
  bool get isOnline => _isOnline;
  bool get isDeviceConnected => _isDeviceConnected;
  int get pendingSyncCount => _pendingSyncCount;
  int get unreadNotificationCount => _unreadNotificationCount;
  String get phoneNumber => _phoneNumber;
  String get otpCode => _otpCode;
  int get currentTab => _currentTab;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  ApiClient? get apiClient => _services.apiClient;

  int get totalSubmissions => _readings.where((r) => r.status == 'Sent').length;

  double get avgSystolic {
    final valid = _readings.where((r) => r.systolic != null).toList();
    if (valid.isEmpty) return 0;
    return valid.map((r) => r.systolic!).reduce((a, b) => a + b) / valid.length;
  }

  double get avgSugar {
    final valid = _readings.where((r) => r.bloodSugar != null).toList();
    if (valid.isEmpty) return 0;
    return valid.map((r) => r.bloodSugar!).reduce((a, b) => a + b) / valid.length;
  }

  double get avgWeight {
    final valid = _readings.where((r) => r.weight != null).toList();
    if (valid.isEmpty) return 0;
    return valid.map((r) => r.weight!).reduce((a, b) => a + b) / valid.length;
  }

  Future<SharedPreferences> get _prefs async => SharedPreferences.getInstance();

  Future<void> fetchUnreadNotificationCount() async {
    final result = await _services.notifications.getNotifications();
    if (result case Success(data: final list)) {
      _unreadNotificationCount = list.where((n) => !n.isRead).length;
      notifyListeners();
    }
  }

  void decrementUnreadNotifications() {
    if (_unreadNotificationCount > 0) {
      _unreadNotificationCount--;
      notifyListeners();
    }
  }

  void setState(AppState state) {
    _state = state;
    _errorMessage = null;
    if (_isLoggedIn) {
      unawaited(markUserActivity());
    }
    notifyListeners();
  }

  void setTab(int tab) {
    _currentTab = tab;
    if (_isLoggedIn) {
      unawaited(markUserActivity());
    }
    notifyListeners();
  }

  void setPhoneNumber(String number) {
    _phoneNumber = number;
    notifyListeners();
  }

  void setOtpCode(String code) {
    _otpCode = code;
    notifyListeners();
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  Future<bool> requestOtp() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    final result = await _services.auth.requestOtp(_phoneNumber);
    _isLoading = false;

    return switch (result) {
      Success() => (() {
          notifyListeners();
          return true;
        })(),
      Failure(message: final msg) => (() {
          _errorMessage = msg;
          notifyListeners();
          return false;
        })(),
    };
  }

  Future<bool> verifyOtp() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    final result = await _services.auth.verifyOtp(_phoneNumber, _otpCode);
    _isLoading = false;

    return switch (result) {
      Success(data: final creds) => (() async {
          final apiKey = creds['api_key'] ?? '';
          final apiSecret = creds['api_secret'] ?? '';
          if (apiKey.isNotEmpty && apiSecret.isNotEmpty) {
            _services.apiClient?.setPatientAuth(apiKey, apiSecret);
            final prefs = await _prefs;
            await prefs.setString(_patientApiKeyKey, apiKey);
            await prefs.setString(_patientApiSecretKey, apiSecret);
          }
          notifyListeners();
          return true;
        })(),
      Failure(message: final msg) => (() {
          _errorMessage = msg;
          notifyListeners();
          return false;
        })(),
    };
  }

  Future<bool> lookupPatient() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    final result = await _services.auth.lookupPatient(_phoneNumber);
    _isLoading = false;

    return switch (result) {
      Success(data: final p) => (() async {
          _patient = p;
          _isLoggedIn = true;
          _state = AppState.success;
          _services.updatePatientId(p.id, sex: p.sex);
          await _patientDao.save(p);
          await _activateSession();
          await _readingsDao.seedIfEmpty();
          final dbReadings = await _readingsDao.getAll();
          _readings =
              dbReadings.isNotEmpty ? dbReadings : VitalReading.mockReadings();
          _pendingSyncCount = await _readingsDao.pendingCount();
          unawaited(fetchUnreadNotificationCount());
          notifyListeners();
          return true;
        })(),
      Failure(message: final msg) => (() async {
          _errorMessage = msg;
          notifyListeners();
          log.w('lookupPatient failed: $msg');
          return false;
        })(),
    };
  }

  Future<void> logout({bool clearLocalData = true}) async {
    await _services.auth.logout();
    await _clearSessionPersistence();
    if (clearLocalData) {
      await DatabaseHelper.instance.clearAll();
    } else {
      await _patientDao.clear();
    }
    _resetInMemoryState();
    _state = AppState.splash;
    notifyListeners();
  }

  Future<void> expireSession() async {
    _autoSubmitService?.stopListening();
    _autoSubmitService = null;
    await _services.auth.logout();
    await _clearSessionPersistence();
    await _patientDao.clear();
    _isLoggedIn = false;
    _patient = null;
    _state = AppState.sessionExpired;
    _currentTab = 0;
    _errorMessage = 'Session expired. Please log in again.';
    notifyListeners();
  }

  Future<bool> submitReading(VitalReading reading) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    await _readingsDao.insert(reading);
    _readings.insert(0, reading);
    _pendingSyncCount = await _readingsDao.pendingCount();
    notifyListeners();

    final result = await _services.readings.submitReading(reading);
    _isLoading = false;
    await markUserActivity();

    return switch (result) {
      Success() => (() async {
          _pendingSyncCount = await _readingsDao.pendingCount();
          notifyListeners();
          return true;
        })(),
      Failure(message: final msg) => (() {
          log.w('API sync failed (saved locally): $msg');
          notifyListeners();
          return true;
        })(),
    };
  }

  void addReading(VitalReading reading) {
    _readings.insert(0, reading);
    if (_isLoggedIn) {
      unawaited(markUserActivity());
    }
    notifyListeners();
  }

  Future<void> refreshReadings() async {
    _readings = await _readingsDao.getAll();
    _pendingSyncCount = await _readingsDao.pendingCount();
    if (_isLoggedIn) {
      await markUserActivity();
    }
    notifyListeners();
  }

  Future<bool> tryRestoreSession() async {
    if (await _isSessionExpired()) {
      await _clearSessionPersistence();
      await _patientDao.clear();
      return false;
    }

    final patient = await _patientDao.get();
    if (patient != null) {
      _patient = patient;
      _isLoggedIn = true;
      _services.updatePatientId(patient.id);
      // Restore patient API auth if available
      final prefs = await _prefs;
      final apiKey = prefs.getString(_patientApiKeyKey);
      final apiSecret = prefs.getString(_patientApiSecretKey);
      if (apiKey != null && apiSecret != null) {
        _services.apiClient?.setPatientAuth(apiKey, apiSecret);
      }
      final dbReadings = await _readingsDao.getAll();
      _readings =
          dbReadings.isNotEmpty ? dbReadings : VitalReading.mockReadings();
      _pendingSyncCount = await _readingsDao.pendingCount();
      _state = AppState.home;
      await markUserActivity();
      unawaited(fetchUnreadNotificationCount());
      notifyListeners();
      log.i('Session restored for ${patient.name}');
      return true;
    }
    return false;
  }

  void setOnlineStatus(bool online) {
    _isOnline = online;
    notifyListeners();
  }

  void setDeviceConnected(bool connected) {
    _isDeviceConnected = connected;
    notifyListeners();
  }

  void setPendingSyncCount(int count) {
    _pendingSyncCount = count;
    notifyListeners();
  }

  void login() {
    _isLoggedIn = true;
    _patient = Patient.mock();
    _state = AppState.home;
    unawaited(_activateSession());
    unawaited(_patientDao.save(_patient!));
    _readingsDao.seedIfEmpty().then((_) async {
      final dbReadings = await _readingsDao.getAll();
      _readings =
          dbReadings.isNotEmpty ? dbReadings : VitalReading.mockReadings();
      _pendingSyncCount = await _readingsDao.pendingCount();
      notifyListeners();
    });
    // Load BLE protocol registry from server/cache
    unawaited(BleProtocolRegistry.instance.load(apiClient: _services.apiClient));

    // Start auto-submit service for BLE device readings
    _autoSubmitService = DeviceAutoSubmitService(
      apiClient: _services.apiClient,
      patient: _patient,
    );
    _autoSubmitService!.startListening();
    notifyListeners();
  }

  Future<void> handleAppResumed() async {
    if (!_isLoggedIn) return;
    if (await _isSessionExpired()) {
      await expireSession();
      return;
    }
    await markUserActivity();
  }

  Future<void> markUserActivity() async {
    if (!_isLoggedIn) return;
    final prefs = await _prefs;
    await prefs.setInt(_lastActivityKey, DateTime.now().millisecondsSinceEpoch);
    await prefs.setBool(_sessionActiveKey, true);
  }

  Future<void> _activateSession() async {
    final prefs = await _prefs;
    await prefs.setBool(_sessionActiveKey, true);
    await prefs.setInt(_lastActivityKey, DateTime.now().millisecondsSinceEpoch);
  }

  Future<bool> _isSessionExpired() async {
    final prefs = await _prefs;
    final isActive = prefs.getBool(_sessionActiveKey) ?? false;
    if (!isActive) {
      return false;
    }

    final lastActivityMs = prefs.getInt(_lastActivityKey);
    if (lastActivityMs == null) {
      return false;
    }

    final lastActivity = DateTime.fromMillisecondsSinceEpoch(lastActivityMs);
    final elapsedMinutes = DateTime.now().difference(lastActivity).inMinutes;
    return elapsedMinutes >= EnvConfig.sessionTimeoutMinutes;
  }

  Future<void> _clearSessionPersistence() async {
    final prefs = await _prefs;
    await prefs.remove(_sessionActiveKey);
    await prefs.remove(_lastActivityKey);
    await prefs.remove(_patientApiKeyKey);
    await prefs.remove(_patientApiSecretKey);
    _services.apiClient?.clearPatientAuth();
  }

  void _resetInMemoryState() {
    _autoSubmitService?.stopListening();
    _autoSubmitService = null;
    _isLoggedIn = false;
    _patient = null;
    _readings = [];
    _currentTab = 0;
    _errorMessage = null;
    _pendingSyncCount = 0;
  }

  @override
  void dispose() {
    _autoSubmitService?.dispose();
    super.dispose();
  }
}
