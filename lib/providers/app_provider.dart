import 'dart:async';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/config/env_config.dart';
import '../core/database/database_helper.dart';
import '../core/database/patient_dao.dart';
import '../core/database/readings_dao.dart';
import '../core/network/sync_manager.dart';
import '../core/utils/app_logger.dart';
import '../core/network/api_client.dart';
import '../core/utils/result.dart';
import '../models/otp_delivery.dart';
import '../models/patient.dart';
import '../models/vital_reading.dart';
import '../services/ble_protocol_registry.dart';
import '../services/biometric_service.dart';
import '../services/device_auto_submit_service.dart';
import '../services/push_notification_service.dart';
import '../services/service_locator.dart';

enum AppState { splash, register, signup, otp, success, paywall, home, sessionExpired }

class AppProvider extends ChangeNotifier {
  static const _patientApiKeyKey = 'patient_api_key';
  static const _patientApiSecretKey = 'patient_api_secret';
  static const _largeTextKey = 'pref_large_text';
  static const _localeKey = 'pref_locale';

  AppProvider() {
    unawaited(_loadLargeText());
    unawaited(_loadLocale());
  }

  AppState _state = AppState.splash;
  Patient? _patient;
  List<VitalReading> _readings = [];
  bool _isLoggedIn = false;
  bool _isOnline = true;
  int _pendingSyncCount = 0;
  int _unreadNotificationCount = 0;
  String _phoneNumber = '';
  String _otpCode = '';
  OtpDelivery _otpDelivery = const OtpDelivery();
  String _otpRequestedChannel = 'sms';
  // Self-registration: details collected on the Sign Up screen, held until the
  // OTP is confirmed and the account is created.
  bool _isSignupFlow = false;
  String? _signupName;
  String? _signupSex;
  String? _signupDob;
  String? _signupEmail;
  int _currentTab = 0;
  bool _isLoading = false;
  String? _errorMessage;
  bool _largeText = false;
  Locale _locale = const Locale('en');

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
  int get pendingSyncCount => _pendingSyncCount;
  int get unreadNotificationCount => _unreadNotificationCount;
  String get phoneNumber => _phoneNumber;
  String get otpCode => _otpCode;
  OtpDelivery get otpDelivery => _otpDelivery;
  String get otpRequestedChannel => _otpRequestedChannel;
  bool get isSignupFlow => _isSignupFlow;
  int get currentTab => _currentTab;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get largeText => _largeText;
  Locale get locale => _locale;

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
    // Landing on the sign-in or splash screen means we're no longer mid-signup;
    // clear the flag so a subsequent OTP is treated as a sign-in, not a signup.
    if (state == AppState.register || state == AppState.splash) {
      _isSignupFlow = false;
    }
    notifyListeners();
  }

  void setTab(int tab) {
    _currentTab = tab;
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

  Future<bool> requestOtp({String channel = 'sms'}) async {
    _isLoading = true;
    _errorMessage = null;
    _otpRequestedChannel = channel;
    notifyListeners();

    final result = await _services.auth.requestOtp(_phoneNumber, channel: channel);
    _isLoading = false;

    return switch (result) {
      Success(data: final delivery) => (() {
          _otpDelivery = delivery;
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

    final result = await _services.auth.verifyOtp(_phoneNumber, _otpCode, channel: _otpRequestedChannel);
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
          // Feature gate: no active subscription → paywall. A brand-new sign-up
          // is never active, so it always lands on the paywall. An existing
          // active patient goes to the normal onboarding/home.
          _state = p.subscriptionActive ? AppState.home : AppState.paywall;
          _services.updatePatientId(p.id, sex: p.sex);
          await _patientDao.save(p);
          await _enableBiometricAfterLogin();
          await _loadReadings();
          _startDeviceServices();
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

  /// Begin self-registration: stash the details from the Sign Up screen and
  /// send an SMS OTP to verify the phone. On success the UI moves to the OTP
  /// screen, where [completeSignup] finishes creating the account.
  Future<bool> beginSignup({
    required String fullName,
    required String phone,
    required String sex,
    required String dob,
    String? email,
  }) async {
    _isSignupFlow = true;
    _signupName = fullName;
    _signupSex = sex;
    _signupDob = dob;
    _signupEmail = email;
    _phoneNumber = phone;
    return requestOtp(channel: 'sms');
  }

  /// Finish self-registration once the OTP is entered: create the account,
  /// store credentials, load the new patient, and route through the paywall.
  Future<bool> completeSignup() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    final result = await _services.auth.selfRegister(
      fullName: _signupName ?? '',
      mobile: _phoneNumber,
      otp: _otpCode,
      sex: _signupSex ?? '',
      dob: _signupDob ?? '',
      email: _signupEmail,
    );
    _isLoading = false;

    switch (result) {
      case Success(data: final creds):
        final apiKey = creds['api_key'] ?? '';
        final apiSecret = creds['api_secret'] ?? '';
        if (apiKey.isNotEmpty && apiSecret.isNotEmpty) {
          _services.apiClient?.setPatientAuth(apiKey, apiSecret);
          final prefs = await _prefs;
          await prefs.setString(_patientApiKeyKey, apiKey);
          await prefs.setString(_patientApiSecretKey, apiSecret);
        }
        // Load the freshly-created patient and let the gate route to paywall.
        final ok = await lookupPatient();
        _isSignupFlow = false;
        return ok;
      case Failure(message: final msg):
        _errorMessage = msg;
        notifyListeners();
        return false;
    }
  }

  /// Re-check the subscription gate from the server and route accordingly.
  /// Called after a payment completes on the paywall, and on session restore.
  Future<void> refreshSubscriptionGate() async {
    final result = await _services.auth.lookupPatient(_phoneNumber);
    if (result case Success(data: final p)) {
      _patient = p;
      await _patientDao.save(p);
      if (p.subscriptionActive) {
        _state = AppState.home;
      } else if (_state != AppState.paywall) {
        _state = AppState.paywall;
      }
      notifyListeners();
    }
  }

  /// Load the patient's reading history for display.
  ///
  /// Live build: the patient's real ERPNext Daily Readings are the source of
  /// truth (plus any locally-queued readings not yet synced). No mock data is
  /// ever seeded or shown. Demo build (USE_MOCK): seed/show local sample data.
  Future<void> _loadReadings() async {
    if (EnvConfig.useMock) {
      await _readingsDao.seedIfEmpty();
      _readings = await _readingsDao.getAll();
      _pendingSyncCount = await _readingsDao.pendingCount();
      return;
    }

    final result = await _services.readings.getReadings(limit: 100);
    if (result case Success(data: final server)) {
      final pendingLocal = await _readingsDao.getPending();
      // Newest first: pending rows come back oldest-first, so re-sort the
      // merged list or "Last Submitted" can show a stale pending reading.
      _readings = [...pendingLocal, ...server]
        ..sort((a, b) => b.date.compareTo(a.date));
    } else {
      // Offline / fetch failed: show whatever is cached locally — never mock.
      _readings = await _readingsDao.getAll();
    }
    _pendingSyncCount = await _readingsDao.pendingCount();
  }

  Future<void> logout({bool clearLocalData = true}) async {
    // Stop this device receiving the patient's pushes (needs the session, so
    // it must happen before the server-side logout).
    try {
      await _services.apiClient?.unregisterPushToken();
    } catch (_) {}
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

    return switch (result) {
      Success() => (() async {
          // Inserted as Pending; mark it synced so the background sync never
          // re-sends it, and mirror the persisted state in memory.
          await _readingsDao.markSyncedByReference(reading.referenceId);
          _replaceReadingSyncState(reading, 'Synced');
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

  /// Mirror a reading's persisted sync state in memory (VitalReading is
  /// immutable, so swap in a copy) so history matches the local DB.
  void _replaceReadingSyncState(VitalReading reading, String syncStatus) {
    final i = _readings.indexWhere((r) =>
        reading.referenceId != null && r.referenceId == reading.referenceId);
    if (i == -1) return;
    final r = _readings[i];
    _readings[i] = VitalReading(
      id: r.id,
      referenceId: r.referenceId,
      date: r.date,
      systolic: r.systolic,
      diastolic: r.diastolic,
      bloodSugar: r.bloodSugar,
      weight: r.weight,
      medicineTaken: r.medicineTaken,
      note: r.note,
      source: r.source,
      syncStatus: syncStatus,
      status: r.status,
    );
  }

  void addReading(VitalReading reading) {
    _readings.insert(0, reading);
    notifyListeners();
  }

  Future<void> refreshReadings() async {
    await _loadReadings();
    notifyListeners();
  }

  /// Whether this device has a remembered login. OTP is a one-time step per
  /// device — once done, the patient stays remembered (biometric-gated) until
  /// they explicitly log out. Used on launch to decide whether to prompt for
  /// biometric unlock instead of OTP.
  Future<bool> hasPersistedSession() async {
    return (await _patientDao.get()) != null;
  }

  Future<bool> tryRestoreSession() async {
    final patient = await _patientDao.get();
    if (patient != null) {
      _patient = patient;
      _isLoggedIn = true;
      _phoneNumber = patient.phone;
      _services.updatePatientId(patient.id, sex: patient.sex);
      // Restore patient API auth if available
      final prefs = await _prefs;
      final apiKey = prefs.getString(_patientApiKeyKey);
      final apiSecret = prefs.getString(_patientApiSecretKey);
      if (apiKey != null && apiSecret != null) {
        _services.apiClient?.setPatientAuth(apiKey, apiSecret);
      }
      await _loadReadings();
      _startDeviceServices();
      // Gate on the last-known subscription state, then confirm live in case it
      // changed (paid/expired) since this device last synced.
      _state = patient.subscriptionActive ? AppState.home : AppState.paywall;
      unawaited(fetchUnreadNotificationCount());
      unawaited(refreshSubscriptionGate());
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

  void setPendingSyncCount(int count) {
    _pendingSyncCount = count;
    notifyListeners();
  }

  /// Load the large-text accessibility preference once at construction.
  Future<void> _loadLargeText() async {
    final prefs = await _prefs;
    _largeText = prefs.getBool(_largeTextKey) ?? false;
    notifyListeners();
  }

  /// Persist and apply the large-text accessibility preference.
  Future<void> setLargeText(bool value) async {
    if (_largeText == value) return;
    _largeText = value;
    notifyListeners();
    final prefs = await _prefs;
    await prefs.setBool(_largeTextKey, value);
  }

  Future<void> _loadLocale() async {
    final prefs = await _prefs;
    final code = prefs.getString(_localeKey);
    if (code == 'so' || code == 'en') {
      _locale = Locale(code!);
      // Keep intl date patterns on English — Somali UI strings come from
      // AppLocalizations; DateFormat has no reliable `so` symbol data.
      Intl.defaultLocale = 'en';
      notifyListeners();
    }
  }

  /// Persist and apply the app language (English or Somali only).
  Future<void> setLocale(Locale locale) async {
    final code = locale.languageCode;
    if (code != 'en' && code != 'so') return;
    if (_locale.languageCode == code) return;
    _locale = Locale(code);
    Intl.defaultLocale = 'en';
    notifyListeners();
    final prefs = await _prefs;
    await prefs.setString(_localeKey, code);
  }

  /// Load the BLE protocol registry and start auto-submitting device readings.
  /// Called on every login path (OTP login, mock login, biometric/session
  /// restore) so connected devices sync regardless of how the user signed in.
  void _startDeviceServices() {
    unawaited(BleProtocolRegistry.instance.load(apiClient: _services.apiClient));
    _autoSubmitService?.stopListening();
    _autoSubmitService = DeviceAutoSubmitService(
      apiClient: _services.apiClient,
      patient: _patient,
    );
    _autoSubmitService!.startListening();
    unawaited(_registerPushToken());
    // Drain any offline readings now that we're logged in. Safe to repeat:
    // synced readings are marked locally and the server dedupes by reference.
    unawaited(SyncManager().syncAll());
  }

  /// Send this device's FCM push token to the server so we can push to it.
  /// Best-effort and only on real-backend builds.
  Future<void> _registerPushToken() async {
    final api = _services.apiClient;
    if (api == null) return;
    try {
      final token = await PushNotificationService.instance.ensureToken();
      if (token != null && token.isNotEmpty) {
        await api.registerPushToken(token);
      }
    } catch (e) {
      log.w('registerPushToken failed', error: e);
    }
  }

  Future<void> handleAppResumed() async {
    if (!_isLoggedIn) return;
    // Re-attempt push-token registration on every foreground — idempotent, and
    // recovers a token that failed to register on a previous launch.
    unawaited(_registerPushToken());
    // Push any readings that queued while offline/backgrounded.
    unawaited(SyncManager().syncAll());
  }

  /// After the one-time OTP login on a device, enable biometric unlock so
  /// future launches use Face ID / fingerprint instead of another OTP.
  Future<void> _enableBiometricAfterLogin() async {
    try {
      if (await BiometricService.instance.isDeviceSupported) {
        final prefs = await _prefs;
        await prefs.setBool('pref_biometric', true);
      }
    } catch (_) {}
  }

  Future<void> _clearSessionPersistence() async {
    final prefs = await _prefs;
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
