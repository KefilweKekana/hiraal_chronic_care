import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart' as fbp;
import 'package:provider/provider.dart';

import '../../core/database/device_dao.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/app_logger.dart';
import '../../core/utils/result.dart';
import '../../l10n/app_localizations.dart';
import '../../models/device.dart';
import '../../providers/app_provider.dart';
import '../../services/ble_protocol_registry.dart';
import '../../services/bluetooth_service.dart';
import 'device_measure_screen.dart';

/// Screen for scanning, connecting to, and pairing BLE medical devices.
class DevicePairingScreen extends StatefulWidget {
  const DevicePairingScreen({super.key});

  @override
  State<DevicePairingScreen> createState() => _DevicePairingScreenState();
}

class _DevicePairingScreenState extends State<DevicePairingScreen> {
  final BluetoothHealthService _bleService = BluetoothHealthService.instance;
  final DeviceDao _deviceDao = DeviceDao();

  List<DeviceModel> _pairedDevices = [];
  bool _isLoadingPaired = true;

  StreamSubscription<Map<String, dynamic>>? _readingSubscription;
  Map<String, dynamic>? _lastReading;
  bool _isPairing = false;
  bool _showDebugInfo = false;
  bool _showAllKnownDevices = false;

  @override
  void initState() {
    super.initState();
    _loadPairedDevices();
    // Load protocols first so bonded Andesfit/Omron names classify as medical,
    // then surface OS-known devices (they don't appear in scans).
    unawaited(() async {
      await BleProtocolRegistry.instance.load();
      await _bleService.refreshKnownDevices();
      if (mounted) setState(() {});
    }());
    _readingSubscription = _bleService.readingStream.listen((reading) {
      if (mounted) {
        setState(() => _lastReading = reading);
        _showReadingSnack(reading);
      }
    });
  }

  @override
  void dispose() {
    _readingSubscription?.cancel();
    super.dispose();
  }

  Future<void> _loadPairedDevices() async {
    try {
      final devices = await _deviceDao.getAll();
      if (mounted) {
        setState(() {
          _pairedDevices = devices;
          _isLoadingPaired = false;
        });
      }
    } catch (e) {
      log.e('Failed to load paired devices', error: e);
      if (mounted) setState(() => _isLoadingPaired = false);
    }
  }

  void _showReadingSnack(Map<String, dynamic> reading) {
    final type = reading['type'] as String?;
    String message;
    if (type == 'blood_pressure') {
      message = 'BP reading received: ${reading['systolic']}/${reading['diastolic']}';
    } else if (type == 'blood_sugar') {
      message = 'Glucose reading received: ${reading['glucose']} ${reading['unit']}';
    } else if (type == 'weight') {
      message = 'Weight reading received: ${reading['weight']} kg';
    } else {
      message = 'Reading received from device';
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), duration: const Duration(seconds: 3)),
    );
  }

  Future<void> _startScan() async {
    // Customer expectation: Scan must surface the monitor even when it is
    // already bonded to the phone (bonded devices do not advertise).
    await BleProtocolRegistry.instance.load();
    await _bleService.releaseConnectedMedicalDevices();
    await _bleService.startScan(timeout: const Duration(seconds: 12));
    // #region agent log
    if (!mounted) return;
    final scanResults = _bleService.scanResults;
    final known = _bleService.knownDevices;
    agentDebugLog('H3', 'device_pairing_screen.dart:_startScan', 'post-scan UI filter summary', {
      'scanTotal': scanResults.length,
      'scanNames': scanResults
          .map((r) => r.device.advName.isNotEmpty
              ? r.device.advName
              : r.device.platformName)
          .toList(),
      'knownTotal': known.length,
      'knownNames': known
          .map((d) => d.platformName.isNotEmpty ? d.platformName : d.advName)
          .toList(),
      'isScanning': _bleService.isScanning,
      'lastError': _bleService.lastError,
    });
    // #endregion
    if (mounted) setState(() => _showAllKnownDevices = true);
  }

  Future<void> _connectAndPair(fbp.ScanResult scanResult) {
    final name = scanResult.device.advName.isNotEmpty
        ? scanResult.device.advName
        : scanResult.device.platformName;
    return _connectAndPairById(scanResult.device.remoteId.str, name);
  }

  Future<void> _connectKnownDevice(fbp.BluetoothDevice device) {
    final name = device.advName.isNotEmpty ? device.advName : device.platformName;
    return _connectAndPairById(device.remoteId.str, name);
  }

  Future<void> _connectAndPairById(String deviceId, String name) async {
    setState(() => _isPairing = true);

    try {
      final connected = await _bleService.connectToDevice(deviceId);
      if (!connected) {
        if (mounted) {
          setState(() => _isPairing = false);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(_bleService.lastError ?? 'Could not connect to the device.'),
              backgroundColor: AppColors.error,
            ),
          );
        }
        return;
      }

      final type = _displayTypeFor(name: name);

      if (!mounted) return;
      final shouldPair = await _showPairingDialog(
        context,
        deviceId: deviceId,
        deviceName: name,
        // The dialog offers the four fixed types — when the name tells us
        // nothing, default to Blood Pressure and let the user correct it.
        deviceType: type == 'Unknown' ? 'Blood Pressure' : type,
      );

      if (shouldPair != null) {
        await _saveDevice(
          deviceId: deviceId,
          deviceName: shouldPair['name'] as String,
          deviceType: shouldPair['type'] as String,
        );
      }

      // Stay connected so the patient can take a live measurement straight away
      // (the "Start Measurement" CTA appears while connected).
    } catch (e) {
      log.e('Pairing error', error: e);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Pairing failed: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isPairing = false);
    }
  }

  String _guessTypeFromName(String name) {
    final lower = name.toLowerCase();
    if (lower.contains('gluco') || lower.contains('sugar') || lower.contains('accu') || lower.contains('contour') || lower.contains('bgm') || lower.contains('samico') || lower.contains('adf-b27') || lower.contains('bg-207')) {
      return 'Blood Sugar';
    }
    if (lower.contains('bp') || lower.contains('pressure') || lower.contains('omron') || lower.contains('a&d') || lower.contains('u80') || lower.contains('andon') || lower.contains('bpm')) {
      return 'Blood Pressure';
    }
    if (lower.contains('scale') || lower.contains('weight')) {
      return 'Smart Scale';
    }
    if (lower.contains('oxi') || lower.contains('spo2')) {
      return 'Pulse Oximeter';
    }
    // No fake default: an unrecognized name is 'Unknown', not 'Blood
    // Pressure' — mislabeling every gadget as BP made the list confusing.
    return 'Unknown';
  }

  /// Best-effort display type: the detected protocol's own device type first
  /// (a nameless standard-BP/glucose advertisement still resolves correctly
  /// from its service UUID), then name heuristics, then 'Unknown'.
  String _displayTypeFor({
    required String name,
    List<fbp.Guid> services = const [],
  }) {
    final protocol = BleProtocolRegistry.instance
        .detect(deviceName: name, advertisedServices: services);
    if (protocol != null && protocol.deviceTypes.isNotEmpty) {
      return protocol.deviceTypes.first;
    }
    return _guessTypeFromName(name);
  }

  Future<Map<String, String>?> _showPairingDialog(
    BuildContext context, {
    required String deviceId,
    required String deviceName,
    required String deviceType,
  }) async {
    return showDialog<Map<String, String>?>(
      context: context,
      builder: (ctx) => _PairingDialog(
        deviceId: deviceId,
        deviceName: deviceName,
        deviceType: deviceType,
      ),
    );
  }

  Future<void> _saveDevice({
    required String deviceId,
    required String deviceName,
    required String deviceType,
  }) async {
    final provider = context.read<AppProvider>();
    final patient = provider.currentPatient;

    final existing = await _deviceDao.getByDeviceId(deviceId);
    final device = DeviceModel(
      localId: existing?.localId,
      deviceId: deviceId,
      deviceName: deviceName,
      deviceType: deviceType,
      patientId: patient?.id,
      status: 'Online',
      lastSync: DateTime.now(),
    );

    if (existing != null) {
      await _deviceDao.update(device);
    } else {
      await _deviceDao.insert(device);
    }

    var backendSynced = provider.apiClient == null;
    if (patient != null && provider.apiClient != null) {
      try {
        final result = await provider.apiClient!.pairDevice(
          patient: patient.id,
          deviceId: deviceId,
          deviceType: deviceType,
          deviceName: deviceName,
        );
        backendSynced = result is Success;
        result.onSuccess((_) => log.i('Device paired with backend'));
        result.onFailure((err) => log.w('Backend pair failed: $err'));
      } catch (e) {
        log.w('Backend pair exception', error: e);
      }
    }

    await _loadPairedDevices();
    if (mounted) {
      // Honest feedback: a server-registration failure must not masquerade
      // as full success (the device itself works — it just isn't on the
      // clinic's registry yet).
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(backendSynced
              ? 'Device paired successfully'
              : 'Paired on this phone — will sync to the server later'),
        ),
      );
    }
  }

  Future<void> _deleteDevice(DeviceModel device) async {
    final l10n = AppLocalizations.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.removeDeviceQuestion),
        content: Text(l10n.removeDeviceMessage(device.deviceName)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(l10n.cancelAction)),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: Text(l10n.removeAction)),
        ],
      ),
    );

    if (confirmed == true && device.localId != null) {
      await _deviceDao.delete(device.localId!);
      await _loadPairedDevices();
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(l10n.connectMeasurementDevice),
        backgroundColor: AppColors.surface,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(_showDebugInfo ? Icons.bug_report : Icons.bug_report_outlined),
            onPressed: () => setState(() => _showDebugInfo = !_showDebugInfo),
            tooltip: 'Toggle debug info',
          ),
        ],
      ),
      body: AnimatedBuilder(
        animation: _bleService,
        builder: (context, _) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildStatusCard(l10n),
                _buildErrorBanner(l10n),
                if (_bleService.isConnected) ...[
                  const SizedBox(height: 12),
                  _buildMeasureCta(),
                  const SizedBox(height: 16),
                  Text(
                    _bleService.isConnectedGlucose
                        ? 'You’re connected to a glucose meter. Tap Get Reading '
                            'after you measure on the device, or Disconnect to '
                            'switch to your blood pressure cuff.'
                        : _bleService.isConnectedBloodPressure
                            ? 'You’re connected to a BP cuff. Start a measurement, '
                                'or Disconnect to pair a different monitor.'
                            : 'You’re connected. Take a reading, or Disconnect to '
                                'pair a different monitor.',
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ] else ...[
                  const SizedBox(height: 24),
                  _buildScanSection(l10n),
                  const SizedBox(height: 24),
                  _buildKnownDevicesSection(l10n),
                ],
                const SizedBox(height: 24),
                _buildPairedDevicesSection(l10n),
                const SizedBox(height: 24),
                if (_lastReading != null) _buildLastReadingCard(),
                if (_showDebugInfo) ...[
                  const SizedBox(height: 24),
                  _buildDebugInfoCard(),
                ],
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildStatusCard(AppLocalizations l10n) {
    final isConnected = _bleService.isConnected;
    final connectedDevice = _bleService.connectedDevice;
    final protocol = _bleService.activeProtocol;
    final deviceName = connectedDevice?.advName ??
        connectedDevice?.platformName ??
        l10n.unknownDevice;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isConnected ? AppColors.successLight : AppColors.primaryLight,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isConnected ? AppColors.success : AppColors.primary,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                isConnected ? Icons.bluetooth_connected : Icons.bluetooth,
                color: isConnected ? AppColors.success : AppColors.primary,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  isConnected
                      ? l10n.connectedToDevice(deviceName)
                      : l10n.noDeviceConnected,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              if (isConnected)
                TextButton(
                  onPressed: () => _bleService.disconnect(),
                  child: Text(l10n.disconnect),
                ),
            ],
          ),
          if (protocol != null)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                'Protocol detected: ${protocol.name}',
                style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
              ),
            ),
          if (_bleService.lastError != null)
            Text(
              _bleService.lastError!,
              style: const TextStyle(fontSize: 12, color: AppColors.error),
            ),
        ],
      ),
    );
  }

  Widget _buildErrorBanner(AppLocalizations l10n) {
    final err = _bleService.lastError;
    if (err == null || _bleService.isConnected || _bleService.isScanning) {
      return const SizedBox.shrink();
    }
    final btOff = _bleService.isBluetoothOff;
    final color = btOff ? AppColors.warning : AppColors.error;
    final bg = btOff ? AppColors.warningLight : AppColors.errorLight;
    final isAndroid = Theme.of(context).platform == TargetPlatform.android;
    return Container(
      margin: const EdgeInsets.only(top: 16),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(btOff ? Icons.bluetooth_disabled : Icons.error_outline, color: color, size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: Text(err, style: const TextStyle(fontSize: 13, color: AppColors.textPrimary, height: 1.4)),
              ),
            ],
          ),
          if (btOff && isAndroid) ...[
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () async {
                  await _bleService.turnOnBluetooth();
                  if (mounted) _startScan();
                },
                icon: const Icon(Icons.bluetooth, size: 18),
                label: Text(l10n.turnOnBluetooth),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: AppColors.white,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildMeasureCta() {
    final isGlucose = _bleService.isConnectedGlucose;
    final label = isGlucose
        ? 'Get Reading'
        : (_bleService.isConnectedBloodPressure
            ? 'Start Measurement'
            : 'Take Reading');
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: () => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const DeviceMeasureScreen()),
        ),
        icon: Icon(isGlucose ? Icons.water_drop : Icons.monitor_heart, size: 22),
        label: Text(label,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.white,
          minimumSize: const Size.fromHeight(54),
        ),
      ),
    );
  }

  Widget _buildScanSection(AppLocalizations l10n) {
    // Nearby ads: medical profiles / known brand names only (no random BLE junk).
    final scanResults = _bleService.scanResults.where(_isPairable).toList()
      ..sort((a, b) => b.rssi.compareTo(a.rssi));
    // Bonded monitors never advertise — always include phone-paired *health*
    // devices here (not headsets / cars / watches).
    final scanIds = scanResults.map((r) => r.device.remoteId.str).toSet();
    final knownExtras = _bleService.knownDevices
        .where((d) => !scanIds.contains(d.remoteId.str) && _isKnownPairable(d))
        .toList();

    final hasAnything = scanResults.isNotEmpty || knownExtras.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.availableDevices,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          l10n.availableDevicesHint,
          style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          height: 54,
          child: ElevatedButton.icon(
            onPressed: _bleService.isScanning ? null : _startScan,
            icon: _bleService.isScanning
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Icon(Icons.bluetooth_searching, size: 22),
            label: Text(
              _bleService.isScanning ? l10n.scanning : l10n.scanForDevices,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: AppColors.white,
            ),
          ),
        ),
        const SizedBox(height: 12),
        if (!hasAnything && !_bleService.isScanning)
          Text(
            l10n.scanDevicesHint,
            style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
          ),
        if (!hasAnything && _bleService.isScanning)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Center(child: Text(l10n.lookingForDevices)),
          ),
        ...knownExtras.map(
          (d) => _buildKnownDeviceTile(
            l10n,
            d,
            subtitlePrefix: 'Paired to this phone • ',
          ),
        ),
        ...scanResults.map((result) => _buildDeviceTile(l10n, result)),
      ],
    );
  }

  /// Nearby device worth showing: medical GATT or known health-device name.
  bool _isPairable(fbp.ScanResult r) {
    final name = r.device.advName.isNotEmpty
        ? r.device.advName
        : r.device.platformName;
    final uuids = r.advertisementData.serviceUuids
        .map((u) => u.str.toLowerCase())
        .toList();

    const strong = ['1810', '1808', '181d', '181c', 'fff0'];
    for (final u in uuids) {
      for (final s in strong) {
        if (u == s || u.startsWith('0000$s-')) return true;
      }
    }

    if (name.isEmpty || _isNoiseDeviceName(name)) return false;

    return BleProtocolRegistry.instance
            .detect(deviceName: name, advertisedServices: const []) !=
        null;
  }

  bool _isNoiseDeviceName(String name) {
    final lower = name.toLowerCase();
    const noise = [
      'airpods',
      'galaxy buds',
      'buds',
      'headset',
      'headphones',
      'jbl',
      'sony wh',
      'bose',
      'hands-free',
      'watch',
      'fitbit',
      'mi band',
      'laptop',
      'macbook',
      'iphone',
      'pixel buds',
    ];
    return noise.any(lower.contains);
  }

  /// Devices the phone already knows from Android Bluetooth settings or a
  /// system-level connection. They don't advertise, so scanning can't find
  /// them — but we can still connect directly.
  Widget _buildKnownDevicesSection(AppLocalizations l10n) {
    final known = _bleService.knownDevices.where(_isKnownPairable).toList();
    if (known.isEmpty ||
        _bleService.isConnected ||
        _bleService.scanResults.isNotEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Already on this phone',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 4),
        const Text(
          'These health devices are paired in Bluetooth settings. Tap Scan '
          '(or Connect below) — Hiraal will take over the link.',
          style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
        ),
        const SizedBox(height: 12),
        ...known.map((d) => _buildKnownDeviceTile(l10n, d)),
      ],
    );
  }

  Widget _buildKnownDeviceTile(
    AppLocalizations l10n,
    fbp.BluetoothDevice device, {
    String subtitlePrefix = '',
  }) {
    final name = device.advName.isNotEmpty ? device.advName : device.platformName;
    final paired = _pairedDevices
        .where((p) => p.deviceId == device.remoteId.str);
    final type = paired.isNotEmpty
        ? paired.first.deviceType
        : _displayTypeFor(name: name);
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: AppColors.primaryLight,
          child: const Icon(Icons.bluetooth, color: AppColors.primary),
        ),
        title: Text(name.isNotEmpty ? name : l10n.unknownDevice),
        subtitle: Text(type == 'Unknown'
            ? '$subtitlePrefix${device.remoteId.str}'
            : '$subtitlePrefix$type • ${device.remoteId.str}'),
        trailing: _isPairing
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : ElevatedButton(
                onPressed: () => _connectKnownDevice(device),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: AppColors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  minimumSize: const Size(0, 40),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: Text(l10n.connectAction),
              ),
      ),
    );
  }

  /// Bonded device to surface: already in My Devices, or looks like a
  /// supported health monitor (not headphones / cars / watches).
  bool _isKnownPairable(fbp.BluetoothDevice device) {
    final name = device.advName.isNotEmpty ? device.advName : device.platformName;
    if (_isNoiseDeviceName(name)) return false;
    if (_pairedDevices.any((p) => p.deviceId == device.remoteId.str)) {
      return true;
    }
    return _bleService.isLikelyMedicalDevice(device);
  }

  Widget _buildDeviceTile(AppLocalizations l10n, fbp.ScanResult result) {
    final device = result.device;
    final name = device.advName.isNotEmpty ? device.advName : device.platformName;
    final protocol = BleProtocolRegistry.instance.detect(
      deviceName: name,
      advertisedServices: result.advertisementData.serviceUuids,
    );
    final type = protocol != null && protocol.deviceTypes.isNotEmpty
        ? protocol.deviceTypes.first
        : _guessTypeFromName(name);

    IconData icon;
    switch (type) {
      case 'Blood Sugar':
        icon = Icons.water_drop;
        break;
      case 'Smart Scale':
        icon = Icons.monitor_weight;
        break;
      case 'Pulse Oximeter':
        icon = Icons.favorite;
        break;
      case 'Blood Pressure':
        icon = Icons.monitor_heart;
        break;
      default:
        icon = Icons.bluetooth;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: AppColors.primaryLight,
          child: Icon(icon, color: AppColors.primary),
        ),
        title: Text(name.isNotEmpty ? name : l10n.unknownDevice),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(type == 'Unknown'
                ? device.remoteId.str
                : '$type • ${device.remoteId.str}'),
            if (protocol != null)
              Text(
                'Detected: ${protocol.name}',
                style: const TextStyle(fontSize: 11, color: AppColors.success),
              ),
          ],
        ),
        isThreeLine: protocol != null,
        trailing: _isPairing
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : ElevatedButton(
                onPressed: () => _connectAndPair(result),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: AppColors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  // The global theme forces buttons to full width — inside a
                  // ListTile trailing that starves title/subtitle to ~13px and
                  // renders them one character per line. Shrink to content.
                  minimumSize: const Size(0, 40),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: Text(l10n.connectAction),
              ),
      ),
    );
  }

  Widget _buildPairedDevicesSection(AppLocalizations l10n) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.myDevices,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 12),
        if (_isLoadingPaired)
          const Center(child: CircularProgressIndicator()),
        if (!_isLoadingPaired && _pairedDevices.isEmpty)
          Text(
            _bleService.isConnected
                ? 'This monitor is connected. It will stay in My Devices after you leave this screen.'
                : l10n.noPairedDevicesYet,
            style: const TextStyle(color: AppColors.textSecondary),
          ),
        ..._pairedDevices.map((device) => _buildPairedDeviceTile(l10n, device)),
      ],
    );
  }

  Widget _buildPairedDeviceTile(AppLocalizations l10n, DeviceModel device) {
    IconData icon;
    Color statusColor;
    switch (device.deviceType) {
      case 'Blood Sugar':
        icon = Icons.water_drop;
        break;
      case 'Smart Scale':
        icon = Icons.monitor_weight;
        break;
      case 'Pulse Oximeter':
        icon = Icons.favorite;
        break;
      case 'Blood Pressure':
      default:
        icon = Icons.monitor_heart;
    }

    final isLive = _bleService.isConnected &&
        _bleService.connectedDevice?.remoteId.str == device.deviceId;

    switch (device.status) {
      case 'Online':
        statusColor = AppColors.success;
        break;
      case 'Low Battery':
        statusColor = AppColors.warning;
        break;
      case 'Offline':
        statusColor = AppColors.error;
        break;
      default:
        statusColor = AppColors.textTertiary;
    }
    if (isLive) statusColor = AppColors.success;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: AppColors.primaryLight,
          child: Icon(icon, color: AppColors.primary),
        ),
        title: Text(device.deviceName),
        subtitle: Text(
          isLive
              ? '${device.deviceType} • Connected now'
              : '${device.deviceType} • ${device.status}${device.batteryLevel != null ? ' • ${device.batteryLevel}%' : ''}',
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: statusColor,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 4),
            TextButton(
              onPressed: _isPairing
                  ? null
                  : () async {
                      if (!isLive) {
                        await _connectAndPairById(device.deviceId, device.deviceName);
                      }
                      if (!mounted) return;
                      if (_bleService.isConnected) {
                        await Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => const DeviceMeasureScreen(),
                          ),
                        );
                      }
                    },
              style: TextButton.styleFrom(
                foregroundColor: AppColors.primary,
                padding: const EdgeInsets.symmetric(horizontal: 8),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: Text(isLive ? l10n.measureAction : l10n.connectAction),
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline, color: AppColors.error),
              onPressed: () => _deleteDevice(device),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLastReadingCard() {
    final reading = _lastReading!;
    final type = reading['type'] as String?;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Last Reading from Device',
            style: TextStyle(fontWeight: FontWeight.w600, color: AppColors.textPrimary),
          ),
          const SizedBox(height: 8),
          if (type == 'blood_pressure')
            Text(
              'BP: ${reading['systolic']}/${reading['diastolic']} mmHg',
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: AppColors.primary),
            ),
          if (type == 'blood_sugar')
            Text(
              'Glucose: ${reading['glucose']} ${reading['unit']}',
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: AppColors.primary),
            ),
          if (type == 'weight')
            Text(
              'Weight: ${reading['weight']} kg',
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: AppColors.primary),
            ),
          if (reading['pulse'] != null)
            Text('Pulse: ${reading['pulse']} bpm', style: const TextStyle(color: AppColors.textSecondary)),
          if (reading['protocol'] != null)
            Text(
              'Protocol: ${reading['protocol']}',
              style: const TextStyle(fontSize: 12, color: AppColors.textTertiary),
            ),
        ],
      ),
    );
  }

  Widget _buildDebugInfoCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.errorLight,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.error.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Debug Info',
            style: TextStyle(fontWeight: FontWeight.w700, color: AppColors.error),
          ),
          const SizedBox(height: 8),
          Text('Active Protocol: ${_bleService.activeProtocol?.name ?? "None"}'),
          const SizedBox(height: 8),
          const Text('Discovered Services:', style: TextStyle(fontWeight: FontWeight.w600)),
          ..._bleService.discoveredServiceUuids.map((u) => Text('  • $u')),
          const SizedBox(height: 8),
          const Text('Discovered Characteristics:', style: TextStyle(fontWeight: FontWeight.w600)),
          ..._bleService.discoveredCharacteristicUuids.map((u) => Text('  • $u')),
          // #region agent log
          const SizedBox(height: 8),
          Row(
            children: [
              const Expanded(
                child: Text('Agent scan log (last 12):',
                    style: TextStyle(fontWeight: FontWeight.w600)),
              ),
              TextButton.icon(
                onPressed: () async {
                  final text = agentLogRing.isEmpty
                      ? 'No agent logs yet — tap Scan first.'
                      : agentLogRing.join('\n');
                  await Clipboard.setData(ClipboardData(text: text));
                  if (!mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Debug logs copied — paste into chat/WhatsApp'),
                      duration: Duration(seconds: 2),
                    ),
                  );
                },
                icon: const Icon(Icons.copy, size: 16),
                label: const Text('Copy logs'),
              ),
            ],
          ),
          ...agentLogRing.reversed.take(12).map((line) => Text(
                line.length > 220 ? '${line.substring(0, 220)}…' : line,
                style: const TextStyle(fontSize: 10, fontFamily: 'monospace'),
              )),
          // #endregion
        ],
      ),
    );
  }
}

/// Dialog to confirm device name and type before pairing.
class _PairingDialog extends StatefulWidget {
  final String deviceId;
  final String deviceName;
  final String deviceType;

  const _PairingDialog({
    required this.deviceId,
    required this.deviceName,
    required this.deviceType,
  });

  @override
  State<_PairingDialog> createState() => _PairingDialogState();
}

class _PairingDialogState extends State<_PairingDialog> {
  late final TextEditingController _nameController;
  late String _selectedType;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.deviceName);
    _selectedType = widget.deviceType;
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Pair Device'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Device ID: ${widget.deviceId}', style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
            const SizedBox(height: 16),
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Device Name',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _selectedType,
              decoration: const InputDecoration(
                labelText: 'Device Type',
                border: OutlineInputBorder(),
              ),
              items: const [
                DropdownMenuItem(value: 'Blood Pressure', child: Text('Blood Pressure')),
                DropdownMenuItem(value: 'Blood Sugar', child: Text('Blood Sugar')),
                DropdownMenuItem(value: 'Smart Scale', child: Text('Smart Scale')),
                DropdownMenuItem(value: 'Pulse Oximeter', child: Text('Pulse Oximeter')),
              ],
              onChanged: (v) {
                if (v != null) setState(() => _selectedType = v);
              },
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, null),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () => Navigator.pop(context, {
            'name': _nameController.text.trim(),
            'type': _selectedType,
          }),
          child: const Text('Pair'),
        ),
      ],
    );
  }
}
