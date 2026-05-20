import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart' as fbp;
import 'package:provider/provider.dart';

import '../../core/database/device_dao.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/app_logger.dart';
import '../../core/utils/result.dart';
import '../../models/device.dart';
import '../../providers/app_provider.dart';
import '../../services/ble_protocol_registry.dart';
import '../../services/bluetooth_service.dart';

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

  @override
  void initState() {
    super.initState();
    _loadPairedDevices();
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
    await _bleService.startScan(timeout: const Duration(seconds: 12));
  }

  Future<void> _connectAndPair(fbp.ScanResult scanResult) async {
    setState(() => _isPairing = true);

    try {
      final connected = await _bleService.connectToDevice(scanResult.device.remoteId.str);
      if (!connected) {
        setState(() => _isPairing = false);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Could not connect to device')),
          );
        }
        return;
      }

      final name = scanResult.device.advName.isNotEmpty
          ? scanResult.device.advName
          : scanResult.device.platformName;
      final type = _guessTypeFromName(name);

      if (!mounted) return;
      final shouldPair = await _showPairingDialog(
        context,
        deviceId: scanResult.device.remoteId.str,
        deviceName: name,
        deviceType: type,
      );

      if (shouldPair != null) {
        await _saveDevice(
          deviceId: scanResult.device.remoteId.str,
          deviceName: shouldPair['name'] as String,
          deviceType: shouldPair['type'] as String,
        );
      }

      await _bleService.disconnect();
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
    if (lower.contains('gluco') || lower.contains('sugar') || lower.contains('accu') || lower.contains('contour')) {
      return 'Blood Sugar';
    }
    if (lower.contains('bp') || lower.contains('pressure') || lower.contains('omron') || lower.contains('a&d')) {
      return 'Blood Pressure';
    }
    if (lower.contains('scale') || lower.contains('weight')) {
      return 'Smart Scale';
    }
    if (lower.contains('oxi') || lower.contains('spo2')) {
      return 'Pulse Oximeter';
    }
    return 'Blood Pressure';
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

    if (patient != null && provider.apiClient != null) {
      try {
        final result = await provider.apiClient!.pairDevice(
          patient: patient.id,
          deviceId: deviceId,
          deviceType: deviceType,
          deviceName: deviceName,
        );
        result.onSuccess((_) => log.i('Device paired with backend'));
        result.onFailure((err) => log.w('Backend pair failed: $err'));
      } catch (e) {
        log.w('Backend pair exception', error: e);
      }
    }

    await _loadPairedDevices();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Device paired successfully')),
      );
    }
  }

  Future<void> _deleteDevice(DeviceModel device) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Remove Device?'),
        content: Text('Remove "${device.deviceName}" from paired devices?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Remove')),
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
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Connect Device'),
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
                _buildStatusCard(),
                const SizedBox(height: 24),
                _buildScanSection(),
                const SizedBox(height: 24),
                _buildPairedDevicesSection(),
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

  Widget _buildStatusCard() {
    final isConnected = _bleService.isConnected;
    final connectedDevice = _bleService.connectedDevice;
    final protocol = _bleService.activeProtocol;

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
                      ? 'Connected to ${connectedDevice?.advName ?? connectedDevice?.platformName ?? 'device'}'
                      : 'No device connected',
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              if (isConnected)
                TextButton(
                  onPressed: () => _bleService.disconnect(),
                  child: const Text('Disconnect'),
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

  Widget _buildScanSection() {
    final scanResults = _bleService.scanResults;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Available Devices',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            ElevatedButton.icon(
              onPressed: _bleService.isScanning ? null : _startScan,
              icon: _bleService.isScanning
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.search, size: 18),
              label: Text(_bleService.isScanning ? 'Scanning...' : 'Scan'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: AppColors.white,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (scanResults.isEmpty && !_bleService.isScanning)
          const Text(
            'Tap Scan to find nearby Bluetooth health devices.\nEnsure your device is in pairing mode.',
            style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
          ),
        if (scanResults.isEmpty && _bleService.isScanning)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Center(child: Text('Looking for devices...')),
          ),
        ...scanResults.map((result) => _buildDeviceTile(result)),
      ],
    );
  }

  Widget _buildDeviceTile(fbp.ScanResult result) {
    final device = result.device;
    final name = device.advName.isNotEmpty ? device.advName : device.platformName;
    final type = _guessTypeFromName(name);
    final protocol = BleProtocolRegistry.instance.detect(
      deviceName: name,
      advertisedServices: result.advertisementData.serviceUuids,
    );

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
      default:
        icon = Icons.monitor_heart;
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
        title: Text(name.isNotEmpty ? name : 'Unknown Device'),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('$type • ${device.remoteId.str}'),
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
                ),
                child: const Text('Connect'),
              ),
      ),
    );
  }

  Widget _buildPairedDevicesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'My Devices',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 12),
        if (_isLoadingPaired)
          const Center(child: CircularProgressIndicator()),
        if (!_isLoadingPaired && _pairedDevices.isEmpty)
          const Text(
            'No paired devices yet. Connect a device above to get started.',
            style: TextStyle(color: AppColors.textSecondary),
          ),
        ..._pairedDevices.map((device) => _buildPairedDeviceTile(device)),
      ],
    );
  }

  Widget _buildPairedDeviceTile(DeviceModel device) {
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
          '${device.deviceType} • ${device.status}${device.batteryLevel != null ? ' • ${device.batteryLevel}%' : ''}',
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
            const SizedBox(width: 8),
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
