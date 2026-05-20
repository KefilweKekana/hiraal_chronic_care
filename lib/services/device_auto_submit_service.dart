import 'dart:async';

import '../core/database/device_dao.dart';
import '../core/database/readings_dao.dart';
import '../core/network/api_client.dart';
import '../core/utils/app_logger.dart';
import '../core/utils/result.dart';
import '../models/patient.dart';
import '../models/vital_reading.dart';
import 'bluetooth_service.dart';

/// Listens to BLE health-device readings and automatically submits them
/// to the local SQLite cache and the ERPNext backend.
class DeviceAutoSubmitService {
  final ApiClient? _api;
  final Patient? _patient;
  final BluetoothHealthService _bleService;
  final ReadingsDao _readingsDao;
  final DeviceDao _deviceDao;

  StreamSubscription<Map<String, dynamic>>? _readingSubscription;
  bool _isListening = false;

  DeviceAutoSubmitService({
    required ApiClient? apiClient,
    required Patient? patient,
    BluetoothHealthService? bleService,
    ReadingsDao? readingsDao,
    DeviceDao? deviceDao,
  })  : _api = apiClient,
        _patient = patient,
        _bleService = bleService ?? BluetoothHealthService.instance,
        _readingsDao = readingsDao ?? ReadingsDao(),
        _deviceDao = deviceDao ?? DeviceDao();

  bool get isListening => _isListening;

  /// Start listening to BLE reading stream.
  void startListening() {
    if (_isListening) return;
    if (_patient == null) {
      log.w('Cannot start auto-submit: no patient logged in');
      return;
    }

    _readingSubscription = _bleService.readingStream.listen(
      _onReadingReceived,
      onError: (e) => log.e('BLE reading stream error', error: e),
    );
    _isListening = true;
    log.i('DeviceAutoSubmitService started listening');
  }

  /// Stop listening to BLE reading stream.
  void stopListening() {
    _readingSubscription?.cancel();
    _readingSubscription = null;
    _isListening = false;
    log.i('DeviceAutoSubmitService stopped listening');
  }

  /// Process a single reading from the BLE stream.
  Future<void> _onReadingReceived(Map<String, dynamic> bleReading) async {
    final deviceId = bleReading['device_id'] as String?;
    final type = bleReading['type'] as String?;

    if (type == null) {
      log.w('Ignoring BLE reading with no type');
      return;
    }

    // Build VitalReading from BLE data
    final reading = _convertBleToVitalReading(bleReading);
    if (reading == null) {
      log.w('Failed to convert BLE reading to VitalReading: $bleReading');
      return;
    }

    // Save locally first (offline-first)
    try {
      await _readingsDao.insert(reading);
      log.i('Auto-submitted reading saved locally: ${reading.bpString} / ${reading.sugarString}');
    } catch (e) {
      log.e('Failed to save auto-reading locally', error: e);
    }

    // Update device lastSync
    if (deviceId != null) {
      try {
        await _deviceDao.updateSyncStatus(deviceId, 'Online', DateTime.now());
      } catch (e) {
        log.w('Failed to update device sync status', error: e);
      }
    }

    // Push to backend if online
    if (_api != null) {
      final result = await _api.submitDailyReading(
        patient: _patient!.id,
        bpSystolic: reading.systolic,
        bpDiastolic: reading.diastolic,
        bloodSugar: reading.bloodSugar,
        weight: reading.weight,
        sugarUnit: 'mg/dL',
        medicineTaken: reading.medicineTaken,
        note: reading.note,
        source: _sourceFromType(type),
        deviceId: deviceId,
      );

      result.onSuccess((data) {
        log.i('Auto-reading synced to ERPNext: ${data['reference_id']}');
      });
      result.onFailure((msg) {
        log.w('Auto-reading backend sync failed (saved locally): $msg');
      });
    }
  }

  /// Convert a BLE parsed reading map into a [VitalReading].
  VitalReading? _convertBleToVitalReading(Map<String, dynamic> ble) {
    final type = ble['type'] as String?;
    final DateTime now = DateTime.now();

    try {
      if (type == 'blood_pressure') {
        final systolic = ble['systolic'] as int?;
        final diastolic = ble['diastolic'] as int?;
        if (systolic == null || diastolic == null) return null;
        return VitalReading(
          referenceId: 'BLE-${now.millisecondsSinceEpoch}',
          date: now,
          systolic: systolic,
          diastolic: diastolic,
          source: 'BP Device',
          syncStatus: _api != null ? 'Pending' : 'Synced',
          status: 'Pending',
        );
      }

      if (type == 'blood_sugar') {
        final glucose = ble['glucose'] as double?;
        if (glucose == null) return null;
        return VitalReading(
          referenceId: 'BLE-${now.millisecondsSinceEpoch}',
          date: now,
          bloodSugar: glucose,
          source: 'Glucometer',
          syncStatus: _api != null ? 'Pending' : 'Synced',
          status: 'Pending',
        );
      }

      if (type == 'weight') {
        final weight = ble['weight'] as double?;
        if (weight == null) return null;
        return VitalReading(
          referenceId: 'BLE-${now.millisecondsSinceEpoch}',
          date: now,
          weight: weight,
          source: 'Smart Scale',
          syncStatus: _api != null ? 'Pending' : 'Synced',
          status: 'Pending',
        );
      }
    } catch (e) {
      log.e('Conversion error', error: e);
    }

    return null;
  }

  String _sourceFromType(String type) {
    switch (type) {
      case 'blood_pressure':
        return 'BP Device';
      case 'blood_sugar':
        return 'Glucometer';
      case 'weight':
        return 'Smart Scale';
      default:
        return 'App';
    }
  }

  void dispose() {
    stopListening();
  }
}
