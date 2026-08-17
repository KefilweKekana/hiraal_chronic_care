import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart' show defaultTargetPlatform, kIsWeb, TargetPlatform, debugPrint;
import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart' as fbp;
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/utils/app_logger.dart';
import '../models/ble_protocol.dart';
import 'ble_protocol_registry.dart';

// #region agent log
final List<String> agentLogRing = <String>[];

void agentDebugLog(String hypothesisId, String location, String message, [Map<String, Object?>? data]) =>
    _agentLog(hypothesisId, location, message, data);

void _agentLog(String hypothesisId, String location, String message, [Map<String, Object?>? data]) {
  final payload = <String, Object?>{
    'sessionId': '9c72b7',
    'runId': 'pre-fix',
    'hypothesisId': hypothesisId,
    'location': location,
    'message': message,
    'data': data ?? const <String, Object?>{},
    'timestamp': DateTime.now().millisecondsSinceEpoch,
  };
  final encoded = jsonEncode(payload);
  debugPrint('AGENT_LOG $encoded');
  agentLogRing.add(encoded);
  if (agentLogRing.length > 80) agentLogRing.removeRange(0, agentLogRing.length - 80);
  if (kIsWeb) return;
  () async {
    for (final host in ['127.0.0.1', '10.0.2.2']) {
      try {
        final req = await HttpClient()
            .postUrl(Uri.parse(
                'http://$host:7907/ingest/f6bd39fb-6e8c-460b-911c-ee36dceb51d4'))
            .timeout(const Duration(milliseconds: 600));
        req.headers.set('Content-Type', 'application/json');
        req.headers.set('X-Debug-Session-Id', '9c72b7');
        req.add(utf8.encode(encoded));
        await req.close().timeout(const Duration(milliseconds: 600));
        break;
      } catch (_) {}
    }
  }();
}
// #endregion

/// BLE health device service using [flutter_blue_plus].
/// Supports multiple device families via [BleProtocolRegistry].
class BluetoothHealthService extends ChangeNotifier {
  BluetoothHealthService._();
  static final BluetoothHealthService _instance = BluetoothHealthService._();
  static BluetoothHealthService get instance => _instance;

  final BleProtocolRegistry _registry = BleProtocolRegistry.instance;

  final List<fbp.ScanResult> _scanResults = [];
  // Devices the OS already knows (system-connected or bonded in Android
  // Bluetooth settings). These do NOT advertise, so a scan can never see
  // them — listing them here is the only way to reconnect.
  final List<fbp.BluetoothDevice> _knownDevices = [];
  fbp.BluetoothDevice? _connectedDevice;
  List<fbp.BluetoothService> _discoveredServices = [];
  bool _isScanning = false;
  bool _isConnecting = false;
  String? _lastError;
  bool _bluetoothOff = false;
  BleDeviceProtocol? _activeProtocol;
  StreamSubscription<List<fbp.ScanResult>>? _scanSubscription;
  StreamSubscription<fbp.BluetoothConnectionState>? _connectionSubscription;

  // Per-connection characteristic listeners. Tracked so a reconnect never
  // stacks a second listener on the same characteristic (which would emit —
  // and submit — every reading twice).
  final List<StreamSubscription<List<int>>> _valueSubs = [];
  final Set<String> _subscribedChars = {};

  // Last raw frame seen, for dropping device-side repeats of the same
  // measurement (many monitors re-send the final frame several times).
  List<int>? _lastFrame;
  DateTime? _lastFrameAt;

  final StreamController<Map<String, dynamic>> _readingController =
      StreamController<Map<String, dynamic>>.broadcast();

  // Live cuff-pressure feedback during a measurement (Andesfit B180 streams
  // [0x20, pressure] while the cuff inflates/deflates). Drives the live
  // "Measuring…" screen. mmHg as a plain int.
  final StreamController<int> _liveController =
      StreamController<int>.broadcast();
  bool _measuring = false;

  // ── Last-used device (for silent auto-reconnect) ──
  static const String _kLastDeviceId = 'hiraal_last_device_id';
  static const String _kLastDeviceName = 'hiraal_last_device_name';
  String? _lastDeviceId;
  String? _lastDeviceName;
  bool _autoReconnecting = false;

  List<fbp.ScanResult> get scanResults => List.unmodifiable(_scanResults);
  /// Devices the phone already knows (bonded/system-connected) that don't
  /// advertise and therefore never appear in [scanResults].
  List<fbp.BluetoothDevice> get knownDevices => List.unmodifiable(_knownDevices);
  fbp.BluetoothDevice? get connectedDevice => _connectedDevice;
  bool get isScanning => _isScanning;
  bool get isConnecting => _isConnecting;
  bool get isConnected => _connectedDevice != null;
  String? get lastError => _lastError;
  /// True when the last failure was because the phone's Bluetooth is off — the
  /// UI can then show a "Turn on Bluetooth" action.
  bool get isBluetoothOff => _bluetoothOff;
  BleDeviceProtocol? get activeProtocol => _activeProtocol;

  /// What the currently connected monitor is for — drives Get Reading vs
  /// Start Measurement so we never open a BP gauge on a glucose meter.
  String get connectedMeasureType {
    final types = _activeProtocol?.deviceTypes ?? const <String>[];
    if (types.contains('Blood Sugar')) return 'Blood Sugar';
    if (types.contains('Blood Pressure')) return 'Blood Pressure';
    final name = (_connectedDevice?.advName.isNotEmpty == true
            ? _connectedDevice!.advName
            : _connectedDevice?.platformName) ??
        '';
    final lower = name.toLowerCase();
    if (lower.contains('samico') ||
        lower.contains('gluco') ||
        lower.contains('sugar') ||
        lower.contains('adf-b27') ||
        lower.contains('bg-207') ||
        lower.contains('bgm')) {
      return 'Blood Sugar';
    }
    if (lower.contains('bpm') ||
        lower.contains('b180') ||
        lower.contains('pressure') ||
        lower.contains('andon') ||
        lower.contains('omron') ||
        lower.contains('u80')) {
      return 'Blood Pressure';
    }
    return 'Unknown';
  }

  bool get isConnectedGlucose => connectedMeasureType == 'Blood Sugar';
  bool get isConnectedBloodPressure =>
      connectedMeasureType == 'Blood Pressure';

  /// Whether the connected device is mid-measurement (cuff inflating).
  bool get measuring => _measuring;

  /// True while a silent auto-reconnect attempt is in flight.
  bool get isAutoReconnecting => _autoReconnecting;

  /// Display name of the monitor last used with this app, if any.
  String? get lastDeviceName => _lastDeviceName;

  Stream<Map<String, dynamic>> get readingStream => _readingController.stream;

  /// Live cuff pressure (mmHg) emitted while a measurement is in progress.
  Stream<int> get liveStream => _liveController.stream;

  /// Request required BLE permissions (Android 12+).
  Future<bool> requestPermissions() async {
    final bleStatuses = await [
      Permission.bluetoothScan,
      Permission.bluetoothConnect,
    ].request();
    // Location is required for unfiltered BLE scans (Android ≤ 11 always;
    // Android 12+ once BLUETOOTH_SCAN is declared without neverForLocation).
    // Without it, BP cuffs that omit service UUIDs in ads never appear.
    final locStatus = await Permission.locationWhenInUse.request();
    final bleOk = bleStatuses.values.every((s) => s.isGranted);
    if (!bleOk) return false;
    // Soft-require location: still allow filtered scans if denied, but warn.
    if (!locStatus.isGranted && !locStatus.isLimited) {
      log.w('Location permission denied — unfiltered BLE fallback may return nothing');
    }
    return true;
  }

  /// Whether any required Bluetooth permission is permanently denied (so the
  /// user must enable it from system Settings).
  Future<bool> _permissionsBlocked() async {
    for (final p in [Permission.bluetoothScan, Permission.bluetoothConnect]) {
      if (await p.isPermanentlyDenied) return true;
    }
    return false;
  }

  /// Pre-flight checks before scanning/connecting. Returns a clear, user-facing
  /// message describing exactly what to fix, or null when everything is ready.
  /// Sets [isBluetoothOff] so the UI can offer a "Turn on Bluetooth" button.
  Future<String?> checkReady() async {
    _bluetoothOff = false;

    // 1. Hardware support.
    try {
      if (!await fbp.FlutterBluePlus.isSupported) {
        return 'This phone doesn’t support Bluetooth, so it can’t connect to health devices.';
      }
    } catch (_) {}

    // 2. Adapter state (is Bluetooth actually turned on?).
    try {
      var state = fbp.FlutterBluePlus.adapterStateNow;
      if (state == fbp.BluetoothAdapterState.unknown) {
        state = await fbp.FlutterBluePlus.adapterState
            .firstWhere((s) => s != fbp.BluetoothAdapterState.unknown)
            .timeout(const Duration(seconds: 4),
                onTimeout: () => fbp.FlutterBluePlus.adapterStateNow);
      }
      if (state == fbp.BluetoothAdapterState.off ||
          state == fbp.BluetoothAdapterState.turningOff) {
        _bluetoothOff = true;
        return 'Bluetooth is turned off. Please turn on Bluetooth, then try again.';
      }
      if (state == fbp.BluetoothAdapterState.unauthorized) {
        return 'Bluetooth access is off for Hiraal. Allow Bluetooth in your phone’s Settings, then try again.';
      }
      if (state == fbp.BluetoothAdapterState.unavailable) {
        return 'Bluetooth isn’t available on this device.';
      }
    } catch (_) {}

    // 3. Runtime permissions.
    final granted = await requestPermissions();
    if (!granted) {
      if (await _permissionsBlocked()) {
        return 'Bluetooth permission is blocked. Open Settings → Hiraal → Permissions and allow Nearby devices, then try again.';
      }
      return 'Bluetooth permission is needed to find your device. Please allow it and try again.';
    }
    return null;
  }

  /// Ask the OS to turn Bluetooth on (Android shows a prompt; no-op on iOS).
  Future<void> turnOnBluetooth() async {
    try {
      await fbp.FlutterBluePlus.turnOn();
    } catch (e) {
      log.w('Bluetooth turnOn failed/declined', error: e);
    }
  }

  /// Enumerate devices the OS already knows: currently system-connected ones
  /// plus (Android only) everything bonded in the phone's Bluetooth settings.
  /// A bonded or connected monitor stops advertising, so scanning can never
  /// find it — this list is the only way to see and reconnect to it.
  Future<void> refreshKnownDevices() async {
    await _registry.load();
    _knownDevices.clear();
    try {
      _knownDevices.addAll(fbp.FlutterBluePlus.connectedDevices);
    } catch (e) {
      log.w('Listing connected devices failed', error: e);
    }
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
      try {
        final bonded = await fbp.FlutterBluePlus.bondedDevices;
        for (final d in bonded) {
          if (!_knownDevices.any((k) => k.remoteId == d.remoteId)) {
            _knownDevices.add(d);
          }
        }
      } catch (e) {
        log.w('Listing bonded devices failed', error: e);
      }
    }
    notifyListeners();
  }

  /// Whether a bonded/connected device looks like a supported health monitor.
  bool isLikelyMedicalDevice(fbp.BluetoothDevice device) {
    final name = device.advName.isNotEmpty ? device.advName : device.platformName;
    if (name.isEmpty) return false;
    return _registry.detect(deviceName: name, advertisedServices: const []) != null;
  }

  /// Drop any OS-level GATT link to [device] so this app can own the connection.
  /// Bonded pairing in Android settings is kept — we only disconnect the live link.
  Future<void> _forceReleaseDevice(fbp.BluetoothDevice device) async {
    try {
      final held = fbp.FlutterBluePlus.connectedDevices
          .any((d) => d.remoteId == device.remoteId);
      var state = fbp.BluetoothConnectionState.disconnected;
      try {
        state = await device.connectionState.first.timeout(
          const Duration(milliseconds: 400),
          onTimeout: () => held
              ? fbp.BluetoothConnectionState.connected
              : fbp.BluetoothConnectionState.disconnected,
        );
      } catch (_) {
        if (held) state = fbp.BluetoothConnectionState.connected;
      }
      if (state == fbp.BluetoothConnectionState.disconnected && !held) {
        return;
      }
      log.i('Releasing OS Bluetooth link so Hiraal can connect: '
          '${device.platformName.isNotEmpty ? device.platformName : device.remoteId.str}');
      try {
        await device.disconnect();
      } catch (e) {
        log.w('Force-release disconnect failed', error: e);
      }
      try {
        await device.connectionState
            .firstWhere((s) => s == fbp.BluetoothConnectionState.disconnected)
            .timeout(const Duration(seconds: 5));
      } catch (_) {}
      await Future.delayed(const Duration(milliseconds: 400));
    } catch (e) {
      log.w('Force-release skipped', error: e);
    }
  }

  /// Disconnect system-connected medical monitors so Scan/Connect can take over.
  Future<void> releaseConnectedMedicalDevices() async {
    await refreshKnownDevices();
    final connected = List<fbp.BluetoothDevice>.from(
      fbp.FlutterBluePlus.connectedDevices,
    );
    for (final d in connected) {
      if (!isLikelyMedicalDevice(d)) continue;
      // Don't tear down our own active session.
      if (_connectedDevice?.remoteId == d.remoteId) continue;
      await _forceReleaseDevice(d);
    }
    await refreshKnownDevices();
  }

  /// Persist the just-connected monitor so the next app session can
  /// reconnect to it silently.
  Future<void> _rememberDevice(fbp.BluetoothDevice device) async {
    _lastDeviceId = device.remoteId.str;
    _lastDeviceName =
        device.advName.isNotEmpty ? device.advName : device.platformName;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_kLastDeviceId, _lastDeviceId!);
      await prefs.setString(_kLastDeviceName, _lastDeviceName ?? '');
    } catch (_) {}
  }

  Future<void> _loadLastDevice() async {
    if (_lastDeviceId != null) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      _lastDeviceId = prefs.getString(_kLastDeviceId);
      _lastDeviceName = prefs.getString(_kLastDeviceName);
    } catch (_) {}
  }

  /// Silently reconnect to the monitor last used with this app. Tries the
  /// OS-known (bonded/system-connected) list first — that path needs no
  /// advertising at all — then falls back to a short scan. Returns true when
  /// connected. Never throws.
  Future<bool> autoReconnect({
    Duration scanWindow = const Duration(seconds: 8),
  }) async {
    if (isConnected) return true;
    if (_autoReconnecting) return false;
    _autoReconnecting = true;
    notifyListeners();
    try {
      await _loadLastDevice();
      final id = _lastDeviceId;
      if (id == null) return false;
      if (await checkReady() != null) return false;

      // Path 1: the phone already knows this device (bonded or connected at
      // OS level) — connect directly, no scan needed.
      await refreshKnownDevices();
      if (_knownDevices.any((d) => d.remoteId.str == id)) {
        return await connectToDevice(id);
      }

      // Path 2: short scan for it.
      unawaited(startScan(timeout: scanWindow));
      final deadline = DateTime.now().add(scanWindow + const Duration(seconds: 1));
      while (DateTime.now().isBefore(deadline)) {
        if (_scanResults.any((r) => r.device.remoteId.str == id)) break;
        await Future.delayed(const Duration(milliseconds: 300));
      }
      if (_scanResults.any((r) => r.device.remoteId.str == id)) {
        await stopScan();
        return await connectToDevice(id);
      }
      return false;
    } catch (e) {
      log.w('autoReconnect failed', error: e);
      return false;
    } finally {
      _autoReconnecting = false;
      notifyListeners();
    }
  }

  /// Start scanning for BLE devices that advertise health services.
  Future<void> startScan({Duration timeout = const Duration(seconds: 12)}) async {
    // #region agent log
    _agentLog('H1', 'bluetooth_service.dart:startScan', 'startScan called', {
      'alreadyScanning': _isScanning,
      'timeoutSec': timeout.inSeconds,
    });
    // #endregion
    if (_isScanning) return;

    final issue = await checkReady();
    if (issue != null) {
      // #region agent log
      _agentLog('H5', 'bluetooth_service.dart:checkReady', 'preflight blocked scan', {
        'issue': issue,
        'btOff': _bluetoothOff,
      });
      // #endregion
      _lastError = issue;
      notifyListeners();
      return;
    }

    _scanResults.clear();
    _isScanning = true;
    _lastError = null;
    notifyListeners();

    // Surface OS-known (bonded/connected) devices alongside the scan — they
    // don't advertise, so the scan alone would never show them. Also drop any
    // live OS/other-app link to medical monitors so this app can take over.
    await releaseConnectedMedicalDevices();

    try {
      // Filter by every service UUID our protocols know. Android 12+ blocks
      // UNFILTERED scans when BLUETOOTH_SCAN is declared neverForLocation
      // (zero results unless Location Services are on) — and most medical
      // devices advertise their service UUID anyway. Protocol detection for
      // name-only devices happens post-connect from the GATT table.
      // The registry load is normally kicked off at login; make sure it has
      // actually landed — an empty filter here IS an unfiltered scan.
      await _registry.load();
      final allUuids = <fbp.Guid>{};
      for (final p in _registry.all) {
        allUuids.addAll(p.serviceUuids);
      }
      // Safety net: an EMPTY filter is an unfiltered scan, and Android 12+
      // silently returns zero results for unfiltered scans when
      // BLUETOOTH_SCAN is declared neverForLocation. If the registry somehow
      // yielded no UUIDs (e.g. a cached server protocol with an empty UUID
      // table), fall back to the standard medical service UUIDs so the scan
      // can never come back blank for that reason.
      if (allUuids.isEmpty) {
        for (final s in ['1810', '1808', '181d', '181c', 'fff0']) {
          allUuids.add(fbp.Guid(s));
        }
        log.w('Protocol registry had no service UUIDs — scanning with built-in medical UUIDs');
      }

      // #region agent log
      _agentLog('H2', 'bluetooth_service.dart:filter', 'scan filter ready', {
        'protocolCount': _registry.all.length,
        'uuidCount': allUuids.length,
        'uuids': allUuids.map((u) => u.str).toList(),
        'knownCount': _knownDevices.length,
        'knownNames': _knownDevices
            .map((d) => d.platformName.isNotEmpty ? d.platformName : d.advName)
            .toList(),
      });
      // #endregion

      // Subscribe BEFORE starting the scan, so results that arrive within the
      // first milliseconds are never missed.
      _scanSubscription = fbp.FlutterBluePlus.scanResults.listen((results) {
        for (final r in results) {
          if (!_scanResults.any((s) => s.device.remoteId == r.device.remoteId)) {
            _scanResults.add(r);
            // #region agent log
            final n = r.device.advName.isNotEmpty ? r.device.advName : r.device.platformName;
            final svcs = r.advertisementData.serviceUuids.map((u) => u.str).toList();
            _agentLog('H2', 'bluetooth_service.dart:scanResult', 'device discovered', {
              'name': n,
              'id': r.device.remoteId.str,
              'rssi': r.rssi,
              'services': svcs,
              'totalSoFar': _scanResults.length,
            });
            // #endregion
          }
        }
        notifyListeners();
      });

      // #region agent log
      _agentLog('H1', 'bluetooth_service.dart:filteredStart', 'starting filtered scan');
      // #endregion
      await fbp.FlutterBluePlus.startScan(
        withServices: allUuids.toList(),
        timeout: timeout,
      );

      await Future.delayed(timeout);
      // #region agent log
      _agentLog('H1', 'bluetooth_service.dart:filteredDone', 'filtered scan window ended', {
        'resultCount': _scanResults.length,
      });
      // #endregion

      // Always run a short unfiltered pass after the filtered one. Proprietary
      // BP cuffs often omit fff0/1810 from the advertisement; if a glucose
      // meter already filled _scanResults, the old "empty-only" fallback never
      // ran and the cuff stayed invisible.
      if (_lastError == null) {
        log.i('Running unfiltered fallback scan (merge with filtered hits)');
        // #region agent log
        _agentLog('H2', 'bluetooth_service.dart:unfilteredFallback', 'starting unfiltered fallback', {
          'filteredCount': _scanResults.length,
        });
        // #endregion
        try {
          await fbp.FlutterBluePlus.stopScan();
          await fbp.FlutterBluePlus.startScan(
            timeout: const Duration(seconds: 8),
          );
          await Future.delayed(const Duration(seconds: 8));
          // #region agent log
          _agentLog('H2', 'bluetooth_service.dart:unfilteredDone', 'unfiltered fallback ended', {
            'resultCount': _scanResults.length,
          });
          // #endregion
        } catch (e) {
          log.w('Unfiltered fallback scan failed', error: e);
          // #region agent log
          _agentLog('H2', 'bluetooth_service.dart:unfilteredError', 'unfiltered fallback failed', {
            'error': e.toString(),
          });
          // #endregion
        }
      }

      // Scan completed — if nothing showed up, say so helpfully.
      if (_scanResults.isEmpty && _lastError == null) {
        // On Android <= 11, BLE scanning silently returns nothing when
        // Location Services are off. Detect it and say so instead of
        // blaming the monitor.
        var locationNote = '';
        var locDisabled = false;
        try {
          final locStatus = await Permission.locationWhenInUse.serviceStatus;
          if (locStatus.isDisabled) {
            locDisabled = true;
            locationNote = '\n• Location Services are OFF — some Android versions '
                'need Location turned on to see Bluetooth devices';
          }
        } catch (_) {}
        // #region agent log
        _agentLog('H3', 'bluetooth_service.dart:emptyResult', 'scan ended with zero results', {
          'knownCount': _knownDevices.length,
          'knownNames': _knownDevices
              .map((d) => d.platformName.isNotEmpty ? d.platformName : d.advName)
              .toList(),
          'locationDisabled': locDisabled,
        });
        // #endregion
        _lastError = _knownDevices.isEmpty
            ? 'No devices found. Check these, then scan again:\n'
                '• The monitor is ON and in pairing mode (many cuffs only advertise for ~1 minute after switching on)\n'
                '• It is not connected to another phone — Bluetooth devices only pair with one phone at a time\n'
                '• It stayed close to this phone'
                '$locationNote'
            : 'No new devices in the scan. Use Connect under "Known to this phone" '
                'below — Hiraal will disconnect any other Bluetooth link and take over.'
                '$locationNote';
      }
    } catch (e) {
      _lastError = 'Couldn’t scan for devices. Please make sure Bluetooth is on and try again.\n'
          'If you scanned several times in a row, wait about 30 seconds first — Android limits rapid repeated scans.';
      log.e('BLE scan error', error: e);
      // #region agent log
      _agentLog('H1', 'bluetooth_service.dart:scanCatch', 'scan threw', {
        'error': e.toString(),
      });
      // #endregion
    } finally {
      // #region agent log
      _agentLog('H1', 'bluetooth_service.dart:finally', 'entering stopScan finally', {
        'resultCount': _scanResults.length,
        'lastError': _lastError,
      });
      // #endregion
      await stopScan();
      // #region agent log
      _agentLog('H1', 'bluetooth_service.dart:afterStop', 'scan fully stopped', {
        'isScanning': _isScanning,
      });
      // #endregion
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
    // Bluetooth can be switched off between scanning and connecting.
    final issue = await checkReady();
    if (issue != null) {
      _lastError = issue;
      notifyListeners();
      return false;
    }

    // Resolve the device from scan results OR the OS-known (bonded / system-
    // connected) list — a bonded monitor doesn't advertise, so it can only be
    // reached through _knownDevices.
    fbp.BluetoothDevice? device;
    List<fbp.Guid> advertisedServices = const <fbp.Guid>[];
    final scanMatches = _scanResults.where((r) => r.device.remoteId.str == deviceId);
    if (scanMatches.isNotEmpty) {
      device = scanMatches.first.device;
      advertisedServices = scanMatches.first.advertisementData.serviceUuids;
    } else {
      final knownMatches = _knownDevices.where((d) => d.remoteId.str == deviceId);
      if (knownMatches.isNotEmpty) device = knownMatches.first;
    }
    if (device == null) {
      _lastError = 'That device is no longer nearby. Tap Scan and try again.';
      notifyListeners();
      return false;
    }
    final dev = device;

    // Fresh connection — fully tear down any previous one first (connection
    // listener, value subscriptions, and the old device link itself). Otherwise
    // the stale disconnect listener can fire after _connectedDevice has been
    // reassigned and null the NEW device's state.
    await disconnect();

    // If Android (or another app) already holds a GATT link to this bonded
    // monitor, disconnect it first so Hiraal can own the connection.
    await _forceReleaseDevice(dev);

    _isConnecting = true;
    _lastError = null;
    notifyListeners();

    try {
      // Android's first connect attempt very commonly dies with the infamous
      // GATT error 133, especially right after a scan. Drop the half-open
      // link and retry once before giving up — this alone eliminates most
      // "sometimes it just won't connect" reports. The explicit timeout keeps
      // a hung attempt from spinning forever.
      try {
        await dev.connect(
          autoConnect: false,
          mtu: null,
          timeout: const Duration(seconds: 15),
        );
      } catch (firstError) {
        log.w('First connect attempt failed — retrying once', error: firstError);
        try {
          await dev.disconnect();
        } catch (_) {}
        await Future.delayed(const Duration(milliseconds: 600));
        await _forceReleaseDevice(dev);
        await dev.connect(
          autoConnect: false,
          mtu: null,
          timeout: const Duration(seconds: 15),
        );
      }
      _discoveredServices = await dev.discoverServices();
      _connectedDevice = dev;

      // Detect protocol from advertisement data + name
      final name = dev.advName.isNotEmpty
          ? dev.advName
          : dev.platformName;

      _activeProtocol = _registry.detect(
        deviceName: name,
        advertisedServices: advertisedServices,
      );

      // A name/advertisement match can pick a proprietary profile the device
      // doesn't actually expose (e.g. an Andesfit name matching the fff0 profile
      // when the unit really speaks standard BP 1810/2A35). If the detected
      // protocol's measurement characteristic isn't present in the discovered
      // GATT table, discard it and re-detect from what the device truly exposes.
      if (_activeProtocol != null && !_protocolPresentOnDevice(_activeProtocol!)) {
        log.w('Detected "${_activeProtocol!.name}" but its characteristic is '
            'absent on the device; re-detecting from the GATT table.');
        _activeProtocol = null;
      }

      if (_activeProtocol == null) {
        log.w('Resolving protocol for "$name" from discovered services.');
        final discoveredUuids = _discoveredServices.map((s) => s.uuid).toList();
        final matches = _registry
            .findByServices(discoveredUuids)
            .where(_protocolPresentOnDevice)
            .toList();
        if (matches.isNotEmpty) _activeProtocol = matches.first;
      }

      log.i('Detected protocol: ${_activeProtocol?.name ?? "Unknown"}');
      log.i('Device GATT exposes: ${discoveredCharacteristicUuids.join(", ")}');

      // Listen for disconnects
      _connectionSubscription = dev.connectionState.listen((state) {
        if (state == fbp.BluetoothConnectionState.disconnected) {
          _connectedDevice = null;
          _discoveredServices = [];
          _activeProtocol = null;
          _measuring = false;
          unawaited(_cancelValueSubs());
          notifyListeners();
        }
      });

      // Subscribe to characteristics based on protocol
      if (_activeProtocol != null) {
        await _subscribeToProtocol(dev, _activeProtocol!);
      } else {
        // Fallback: try to subscribe to all known measurement chars
        await _subscribeFallback(dev);
      }

      // Connection fully up — remember this monitor so the next session can
      // auto-reconnect without scanning or pairing again.
      unawaited(_rememberDevice(dev));

      return true;
    } catch (e) {
      _lastError = 'Couldn’t connect to the device. Make sure it’s switched on and close to your phone, then try again.';
      log.e('BLE connect error', error: e);
      // connect() may have succeeded before a later step (service discovery,
      // subscribing) threw — drop the OS-level link or the device refuses
      // future connections until reboot.
      try {
        await dev.disconnect();
      } catch (_) {}
      return false;
    } finally {
      _isConnecting = false;
      notifyListeners();
    }
  }

  /// Subscribe to characteristics according to the detected protocol.
  ///
  /// Order matters: notifications/indications must be enabled BEFORE any
  /// control-point writes — a glucose meter rejects the RACP "report records"
  /// command until the CCCDs are set, which is why readings would silently
  /// never arrive with the old init-first order.
  Future<void> _subscribeToProtocol(
    fbp.BluetoothDevice device,
    BleDeviceProtocol protocol,
  ) async {
    // 1. Subscribe to measurement characteristics.
    for (final spec in protocol.measurementChars) {
      try {
        final char = _findCharacteristic(spec.serviceUuid, spec.charUuid);
        if (char == null) continue;
        await _subscribeChar(device, char, protocol);
      } catch (e) {
        log.w('Subscribe failed for ${spec.charUuid.str}', error: e);
      }
    }

    // 1b. Subscribe to control characteristics (e.g. glucose RACP 0x2A52).
    // Strict firmware rejects control-point writes (ATT 0x81 "CCCD improperly
    // configured") until the control char's OWN CCCD is enabled for
    // indications — without this the init write below throws and the meter
    // connects but never sends a reading.
    for (final spec in protocol.controlChars ?? const <CharacteristicSpec>[]) {
      try {
        final char = _findCharacteristic(spec.serviceUuid, spec.charUuid);
        if (char == null) continue;
        await _subscribeChar(device, char, protocol);
      } catch (e) {
        log.w('Control subscribe failed for ${spec.charUuid.str}', error: e);
      }
    }

    // 2. Andesfit B180 / Samico GL: proprietary time-sync on the control char.
    if (protocol.controlChars != null &&
        (protocol.name == 'Andesfit B180' ||
            protocol.name == 'Andesfit ADF-B27 Glucose')) {
      try {
        final control = protocol.controlChars!.first;
        final char = _findCharacteristic(control.serviceUuid, control.charUuid);
        if (char != null) {
          final now = DateTime.now();
          late final List<int> timeSync;
          if (protocol.name == 'Andesfit ADF-B27 Glucose') {
            // Samico / ADF-B27 field format (see AndesfitGlucoseMeter.py).
            final body = <int>[
              0x5A,
              0x0A,
              0x00,
              now.year % 100,
              now.month,
              now.day,
              now.hour,
              now.minute,
              now.second,
            ];
            var sum = 0;
            for (final b in body) {
              sum = (sum + b) & 0xFF;
            }
            timeSync = [...body, sum];
          } else {
            timeSync = <int>[
              0xFD, 0xFD, 0xFA, 0x09, // header
              now.year % 100, now.month, now.day,
              now.hour, now.minute, now.second,
              0x0D, 0x0A, // footer
            ];
          }
          await char.write(timeSync, withoutResponse: false);
          log.i('${protocol.name} time sync sent: ${now.toIso8601String()}');
        }
      } catch (e) {
        log.w('${protocol.name} time sync failed', error: e);
      }
    }

    // 3. Init sequence last (e.g. SIG glucose RACP "report all records").
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

    // SIG glucose meters sometimes need a second RACP nudge after CCCD settles.
    // Skip for proprietary Andesfit/Samico (no RACP).
    if (protocol.deviceTypes.contains('Blood Sugar') &&
        protocol.initSequence != null &&
        protocol.initSequence!.isNotEmpty) {
      unawaited(Future<void>.delayed(const Duration(milliseconds: 1500), () async {
        if (_connectedDevice?.remoteId != device.remoteId) return;
        await requestStoredRecords(preferLast: true);
      }));
    }
  }

  /// Re-send the glucose RACP (or protocol init) so a connected meter dumps
  /// stored / latest readings. Call after the patient takes a new strip reading
  /// while already connected — "Start Measurement" used to open a BP-only
  /// screen and never asked the meter for data again.
  Future<bool> requestStoredRecords({bool preferLast = false}) async {
    final protocol = _activeProtocol;
    if (_connectedDevice == null || protocol == null) return false;

    // Ensure control CCCD is still enabled (some stacks drop it quietly).
    for (final spec in protocol.controlChars ?? const <CharacteristicSpec>[]) {
      try {
        final char = _findCharacteristic(spec.serviceUuid, spec.charUuid);
        if (char == null) continue;
        await _subscribeChar(_connectedDevice!, char, protocol);
      } catch (e) {
        log.w('Control re-subscribe failed for ${spec.charUuid.str}', error: e);
      }
    }

    var wrote = false;
    // Prefer last record first — matches "I just measured, send that one".
    if (preferLast && protocol.deviceTypes.contains('Blood Sugar')) {
      for (final spec in protocol.controlChars ?? const <CharacteristicSpec>[]) {
        try {
          final char = _findCharacteristic(spec.serviceUuid, spec.charUuid);
          if (char == null) continue;
          await char.write([0x01, 0x06], withoutResponse: false);
          wrote = true;
          log.i('RACP report LAST record written to ${spec.charUuid.str}');
          await Future.delayed(const Duration(milliseconds: 400));
        } catch (e) {
          log.w('RACP last-record write failed', error: e);
        }
      }
    }

    if (protocol.initSequence != null) {
      for (final step in protocol.initSequence!) {
        try {
          final char =
              _findCharacteristic(step.target.serviceUuid, step.target.charUuid);
          if (char == null) continue;
          await char.write(step.value, withoutResponse: false);
          wrote = true;
          log.i('RACP/init re-request written to ${step.target.charUuid.str}');
        } catch (e) {
          log.w('RACP/init re-request failed', error: e);
        }
      }
    }
    return wrote;
  }

  /// Fallback: try subscribing to all known characteristics across all protocols.
  Future<void> _subscribeFallback(fbp.BluetoothDevice device) async {
    for (final protocol in _registry.all) {
      for (final spec in protocol.measurementChars) {
        try {
          final char = _findCharacteristic(spec.serviceUuid, spec.charUuid);
          if (char == null) continue;
          await _subscribeChar(device, char, protocol);
          // The device speaks a known protocol — adopt it so its control-char
          // subscription + init sequence also run (e.g. glucose RACP), or it
          // would stay silent forever despite being "connected".
          _activeProtocol ??= protocol;
        } catch (e) {
          // silently try next
        }
      }
    }
    // A protocol was adopted: run the full setup (double-subscribes are
    // guarded inside _subscribeChar). No match at all → unrecognized device.
    final adopted = _activeProtocol;
    if (adopted != null) {
      await _subscribeToProtocol(device, adopted);
    } else {
      log.w('Connected, but no known protocol matched the GATT table.');
    }
  }

  /// Enable notify/indicate on a characteristic and route its values to the
  /// parser. Guards against double-subscribing the same characteristic (the
  /// fallback path can reach one characteristic via several protocols), and
  /// uses [fbp.BluetoothCharacteristic.onValueReceived] — NOT lastValueStream,
  /// which replays the previous cached value on re-listen and would re-submit
  /// a stale reading after every reconnect.
  Future<void> _subscribeChar(
    fbp.BluetoothDevice device,
    fbp.BluetoothCharacteristic char,
    BleDeviceProtocol protocol,
  ) async {
    final key = '${char.remoteId.str}:${char.serviceUuid.str}:${char.uuid.str}';
    if (_subscribedChars.contains(key)) return;

    // setNotifyValue enables notify or indicate based on the characteristic's
    // actual properties.
    final enabled = await char.setNotifyValue(true);
    if (!enabled) return;

    _subscribedChars.add(key);
    final sub = char.onValueReceived.listen((value) {
      _onCharacteristicValue(protocol, value);
    });
    _valueSubs.add(sub);
    // Also let the plugin cancel it if the link drops without our handler.
    device.cancelWhenDisconnected(sub);
    log.i('Subscribed to ${char.uuid.str} (${protocol.name})');
  }

  /// Cancel all characteristic listeners from the current/previous connection.
  Future<void> _cancelValueSubs() async {
    for (final sub in _valueSubs) {
      try {
        await sub.cancel();
      } catch (_) {}
    }
    _valueSubs.clear();
    _subscribedChars.clear();
    _lastFrame = null;
    _lastFrameAt = null;
  }

  /// Whether at least one of a protocol's measurement characteristics is
  /// actually present in the connected device's discovered GATT table.
  bool _protocolPresentOnDevice(BleDeviceProtocol protocol) {
    for (final spec in protocol.measurementChars) {
      if (_findCharacteristic(spec.serviceUuid, spec.charUuid) != null) return true;
    }
    return false;
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

    // Live inflation feedback: only the Andesfit B180 streams
    // [0x20, current_pressure] (plain mmHg byte) while the cuff
    // inflates/deflates, before the final result. Scoped to that protocol —
    // any 2-byte frame starting 0x20 from other devices is NOT live pressure.
    if (protocol.name == 'Andesfit B180' &&
        value.length == 2 &&
        value[0] == 0x20) {
      _measuring = true;
      if (!_liveController.isClosed) _liveController.add(value[1]);
      notifyListeners();
      return;
    }

    // Many monitors re-send the final measurement frame several times in quick
    // succession; treat an identical frame within 3s as the same reading.
    final now = DateTime.now();
    if (_lastFrame != null &&
        _lastFrameAt != null &&
        now.difference(_lastFrameAt!) < const Duration(seconds: 3) &&
        _sameBytes(_lastFrame!, value)) {
      return;
    }
    _lastFrame = List.of(value);
    _lastFrameAt = now;

    // A parser throw here would escape the BLE listener as an unhandled async
    // error; log it and drop the bad frame instead (same guard as readFromDevice).
    final BleParsedReading? parsed;
    try {
      parsed = protocol.parser(value);
    } catch (e) {
      log.w('Parser threw for ${protocol.name}', error: e);
      return;
    }
    if (parsed == null || !parsed.isValid) {
      log.w('Failed to parse reading with ${protocol.name}');
      return;
    }

    // A valid final reading ends the measurement.
    _measuring = false;

    final reading = <String, dynamic>{
      'type': parsed.type,
      // Prefer the device's own measurement time (store-and-forward meters
      // upload history); fall back to now for live readings.
      'timestamp': (parsed.timestamp ?? DateTime.now()).toIso8601String(),
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
    await _cancelValueSubs();
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
    _measuring = false;
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

  static bool _sameBytes(List<int> a, List<int> b) {
    if (a.length != b.length) return false;
    for (int i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  @override
  void dispose() {
    _readingController.close();
    _liveController.close();
    _scanSubscription?.cancel();
    _connectionSubscription?.cancel();
    for (final sub in _valueSubs) {
      sub.cancel();
    }
    _valueSubs.clear();
    super.dispose();
  }
}
