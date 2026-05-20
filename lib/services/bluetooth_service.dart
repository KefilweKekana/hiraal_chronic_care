import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart' as fbp;
import 'package:permission_handler/permission_handler.dart';

import '../core/utils/app_logger.dart';
import '../models/ble_protocol.dart';
import 'ble_protocol_registry.dart';

/// BLE health device service using [flutter_blue_plus].
/// Supports multiple device families via [BleProtocolRegistry].
class BluetoothHealthService extends ChangeNotifier {
  BluetoothHealthService._();
  static final BluetoothHealthService _instance = BluetoothHealthService._();
  static BluetoothHealthService get instance => _instance;

  final BleProtocolRegistry _registry = BleProtocolRegistry.instance;

  final List<fbp.ScanResult> _scanResults = [];
  fbp.BluetoothDevice? _connectedDevice;
  List<fbp.BluetoothService> _discoveredServices = [];
  bool _isScanning = false;
  bool _isConnecting = false;
  String? _lastError;
  BleDeviceProtocol? _activeProtocol;
  StreamSubscription<List<fbp.ScanResult>>? _scanSubscription;
  StreamSubscription<fbp.BluetoothConnectionState>? _connectionSubscription;

  final StreamController<Map<String, dynamic>> _readingController =
      StreamController<Map<String, dynamic>>.broadcast();

  List<fbp.ScanResult> get scanResults => List.unmodifiable(_scanResults);
  fbp.BluetoothDevice? get connectedDevice => _connectedDevice;
  bool get isScanning => _isScanning;
  bool get isConnecting => _isConnecting;
  bool get isConnected => _connectedDevice != null;
  String? get lastError => _lastError;
  BleDeviceProtocol? get activeProtocol => _activeProtocol;

  Stream<Map<String, dynamic>> get readingStream => _readingController.stream;

  /// Request required BLE permissions (Android 12+).
  Future<bool> requestPermissions() async {
    final statuses = await [
      Permission.bluetoothScan,
      Permission.bluetoothConnect,
      Permission.locationWhenInUse,
    ].request();
    return statuses.values.every((s) => s.isGranted);
  }

  /// Start scanning for BLE devices that advertise health services.
  Future<void> startScan({Duration timeout = const Duration(seconds: 12)}) async {
    if (_isScanning) return;

    final hasPermission = await requestPermissions();
    if (!hasPermission) {
      _lastError = 'Bluetooth permissions not granted';
      notifyListeners();
      return;
    }

    _scanResults.clear();
    _isScanning = true;
    _lastError = null;
    notifyListeners();

    try {
      // Collect all unique service UUIDs from all protocols
      final allUuids = <fbp.Guid>{};
      for (final p in _registry.all) {
        allUuids.addAll(p.serviceUuids);
      }

      await fbp.FlutterBluePlus.startScan(
        withServices: allUuids.toList(),
        timeout: timeout,
      );

      _scanSubscription = fbp.FlutterBluePlus.scanResults.listen((results) {
        for (final r in results) {
          if (!_scanResults.any((s) => s.device.remoteId == r.device.remoteId)) {
            _scanResults.add(r);
          }
        }
        notifyListeners();
      });

      await Future.delayed(timeout);
    } catch (e) {
      _lastError = 'Scan failed: $e';
      log.e('BLE scan error', error: e);
    } finally {
      await stopScan();
    }
  }

  /// Stop an active scan.
  Future<void> stopScan() async {
    await _scanSubscription?.cancel();
    _scanSubscription = null;
    await fbp.FlutterBluePlus.stopScan();
    _isScanning = false;
    notifyListeners();
  }

  /// Auto-detect protocol and connect to a device.
  Future<bool> connectToDevice(String deviceId) async {
    final result = _scanResults.firstWhere(
      (r) => r.device.remoteId.str == deviceId,
      orElse: () => throw StateError('Device not found in scan results'),
    );

    _isConnecting = true;
    _lastError = null;
    notifyListeners();

    try {
      await result.device.connect(autoConnect: false, mtu: null);
      _discoveredServices = await result.device.discoverServices();
      _connectedDevice = result.device;

      // Detect protocol from advertisement data + name
      final advertisedServices = result.advertisementData.serviceUuids;
      final name = result.device.advName.isNotEmpty
          ? result.device.advName
          : result.device.platformName;

      _activeProtocol = _registry.detect(
        deviceName: name,
        advertisedServices: advertisedServices,
      );

      if (_activeProtocol == null) {
        log.w('Unknown device protocol for "$name". Falling back to generic.');
        // Try to find any protocol that matches discovered services
        final discoveredUuids = _discoveredServices.map((s) => s.uuid).toList();
        final matches = _registry.findByServices(discoveredUuids);
        if (matches.isNotEmpty) _activeProtocol = matches.first;
      }

      log.i('Detected protocol: ${_activeProtocol?.name ?? "Unknown"}');

      // Listen for disconnects
      _connectionSubscription = result.device.connectionState.listen((state) {
        if (state == fbp.BluetoothConnectionState.disconnected) {
          _connectedDevice = null;
          _discoveredServices = [];
          _activeProtocol = null;
          notifyListeners();
        }
      });

      // Subscribe to characteristics based on protocol
      if (_activeProtocol != null) {
        await _subscribeToProtocol(result.device, _activeProtocol!);
      } else {
        // Fallback: try to subscribe to all known measurement chars
        await _subscribeFallback(result.device);
      }

      return true;
    } catch (e) {
      _lastError = 'Connection failed: $e';
      log.e('BLE connect error', error: e);
      return false;
    } finally {
      _isConnecting = false;
      notifyListeners();
    }
  }

  /// Subscribe to characteristics according to the detected protocol.
  Future<void> _subscribeToProtocol(
    fbp.BluetoothDevice device,
    BleDeviceProtocol protocol,
  ) async {
    // Run init sequence if any (e.g. RACP for glucose)
    if (protocol.initSequence != null && protocol.initSequence!.isNotEmpty) {
      for (final step in protocol.initSequence!) {
        try {
          final char = _findCharacteristic(step.target.serviceUuid, step.target.charUuid);
          if (char != null) {
            await char.write(step.value, withoutResponse: false);
            log.i('Init step written to ${step.target.charUuid.str}');
          }
        } catch (e) {
          log.w('Init step failed for ${step.target.charUuid.str}', error: e);
        }
      }
    }

    // Andesfit B180: send dynamic time-sync command after static init
    if (protocol.name == 'Andesfit B180' && protocol.controlChars != null) {
      try {
        final control = protocol.controlChars!.first;
        final char = _findCharacteristic(control.serviceUuid, control.charUuid);
        if (char != null) {
          final now = DateTime.now();
          final timeSync = <int>[
            0xFD, 0xFD, 0xFA, 0x09, // header
            now.year % 100, now.month, now.day,
            now.hour, now.minute, now.second,
            0x0D, 0x0A, // footer
          ];
          await char.write(timeSync, withoutResponse: false);
          log.i('Andesfit B180 time sync sent: ${now.toIso8601String()}');
        }
      } catch (e) {
        log.w('Andesfit B180 time sync failed', error: e);
      }
    }

    // Subscribe to measurement characteristics
    for (final spec in protocol.measurementChars) {
      try {
        final char = _findCharacteristic(spec.serviceUuid, spec.charUuid);
        if (char == null) continue;

        if (protocol.deliveryMode == DeliveryMode.indicate) {
          await _subscribeIndicate(device, char, protocol);
        } else if (protocol.deliveryMode == DeliveryMode.notify) {
          await _subscribeNotify(device, char, protocol);
        }
      } catch (e) {
        log.w('Subscribe failed for ${spec.charUuid.str}', error: e);
      }
    }
  }

  /// Fallback: try subscribing to all known characteristics across all protocols.
  Future<void> _subscribeFallback(fbp.BluetoothDevice device) async {
    for (final protocol in _registry.all) {
      for (final spec in protocol.measurementChars) {
        try {
          final char = _findCharacteristic(spec.serviceUuid, spec.charUuid);
          if (char == null) continue;

          if (protocol.deliveryMode == DeliveryMode.indicate) {
            await _subscribeIndicate(device, char, protocol);
          } else {
            await _subscribeNotify(device, char, protocol);
          }
        } catch (e) {
          // silently try next
        }
      }
    }
  }

  Future<void> _subscribeNotify(
    fbp.BluetoothDevice device,
    fbp.BluetoothCharacteristic char,
    BleDeviceProtocol protocol,
  ) async {
    final isNotifying = await char.setNotifyValue(true);
    if (isNotifying) {
      char.lastValueStream.listen((value) {
        _onCharacteristicValue(protocol, value);
      });
      log.i('Subscribed to NOTIFY on ${char.uuid.str} (${protocol.name})');
    }
  }

  Future<void> _subscribeIndicate(
    fbp.BluetoothDevice device,
    fbp.BluetoothCharacteristic char,
    BleDeviceProtocol protocol,
  ) async {
    final isIndicating = await char.setNotifyValue(true);
    if (isIndicating) {
      char.lastValueStream.listen((value) {
        _onCharacteristicValue(protocol, value);
      });
      log.i('Subscribed to INDICATE on ${char.uuid.str} (${protocol.name})');
    }
  }

  /// Find a characteristic in discovered services.
  fbp.BluetoothCharacteristic? _findCharacteristic(fbp.Guid svcUuid, fbp.Guid charUuid) {
    for (final svc in _discoveredServices) {
      if (_uuidEq(svc.uuid, svcUuid)) {
        for (final char in svc.characteristics) {
          if (_uuidEq(char.uuid, charUuid)) return char;
        }
      }
    }
    return null;
  }

  /// Handle incoming characteristic values and parse readings.
  void _onCharacteristicValue(BleDeviceProtocol protocol, List<int> value) {
    if (value.isEmpty) return;

    final parsed = protocol.parser(value);
    if (parsed == null || !parsed.isValid) {
      log.w('Failed to parse reading with ${protocol.name}');
      return;
    }

    final reading = <String, dynamic>{
      'type': parsed.type,
      'timestamp': DateTime.now().toIso8601String(),
      'device_id': _connectedDevice?.remoteId.str,
      'protocol': protocol.name,
      ...parsed.raw,
    };

    if (parsed.type == 'blood_pressure') {
      reading['systolic'] = parsed.systolic;
      reading['diastolic'] = parsed.diastolic;
      reading['pulse'] = parsed.pulse;
    } else if (parsed.type == 'blood_sugar') {
      reading['glucose'] = parsed.glucose;
      reading['unit'] = parsed.glucoseUnit;
    } else if (parsed.type == 'weight') {
      reading['weight'] = parsed.weight;
    }

    _readingController.add(reading);
    log.i('Parsed BLE reading: ${parsed.type} via ${protocol.name}');
  }

  /// Disconnect the currently connected device.
  Future<void> disconnect() async {
    await _connectionSubscription?.cancel();
    _connectionSubscription = null;
    final device = _connectedDevice;
    if (device == null) return;
    try {
      await device.disconnect();
    } catch (e) {
      log.w('BLE disconnect error', error: e);
    }
    _connectedDevice = null;
    _discoveredServices = [];
    _activeProtocol = null;
    notifyListeners();
  }

  /// One-shot read from the current protocol's primary characteristic.
  Future<Map<String, dynamic>?> readFromDevice() async {
    if (_connectedDevice == null || _activeProtocol == null) return null;

    for (final spec in _activeProtocol!.measurementChars) {
      final char = _findCharacteristic(spec.serviceUuid, spec.charUuid);
      if (char == null) continue;

      try {
        final value = await char.read();
        final parsed = _activeProtocol!.parser(value);
        if (parsed != null && parsed.isValid) {
          return <String, dynamic>{
            'type': parsed.type,
            'timestamp': DateTime.now().toIso8601String(),
            'device_id': _connectedDevice?.remoteId.str,
            'protocol': _activeProtocol!.name,
            ...parsed.raw,
            if (parsed.systolic != null) 'systolic': parsed.systolic,
            if (parsed.diastolic != null) 'diastolic': parsed.diastolic,
            if (parsed.pulse != null) 'pulse': parsed.pulse,
            if (parsed.glucose != null) 'glucose': parsed.glucose,
            if (parsed.glucoseUnit != null) 'unit': parsed.glucoseUnit,
            if (parsed.weight != null) 'weight': parsed.weight,
          };
        }
      } catch (e) {
        log.w('Read failed for ${spec.charUuid.str}', error: e);
      }
    }
    return null;
  }

  /// Get discovered service UUIDs as strings (for debugging).
  List<String> get discoveredServiceUuids {
    return _discoveredServices.map((s) => s.uuid.str).toList();
  }

  /// Get discovered characteristic UUIDs as strings (for debugging).
  List<String> get discoveredCharacteristicUuids {
    final uuids = <String>[];
    for (final svc in _discoveredServices) {
      for (final char in svc.characteristics) {
        uuids.add('${svc.uuid.str} → ${char.uuid.str}');
      }
    }
    return uuids;
  }

  static bool _uuidEq(fbp.Guid a, fbp.Guid b) {
    return a.str.toLowerCase() == b.str.toLowerCase();
  }

  @override
  void dispose() {
    _readingController.close();
    _scanSubscription?.cancel();
    _connectionSubscription?.cancel();
    super.dispose();
  }
}
