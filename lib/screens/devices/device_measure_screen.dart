import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_colors.dart';
import '../../providers/app_provider.dart';
import '../../services/bluetooth_service.dart';

/// Live measurement screen for a connected monitor.
///
/// Blood pressure: circular gauge with live cuff pressure, then SYS/DIA/PUL.
/// Blood sugar (Samico / ADF-B27): requests stored/latest records via RACP and
/// shows the glucose value when it arrives.
///
/// Readings are auto-saved by [DeviceAutoSubmitService]; this screen only
/// drives the live UI.
class DeviceMeasureScreen extends StatefulWidget {
  const DeviceMeasureScreen({super.key});

  @override
  State<DeviceMeasureScreen> createState() => _DeviceMeasureScreenState();
}

enum _Phase { waiting, measuring, done, disconnected, reconnecting }

class _DeviceMeasureScreenState extends State<DeviceMeasureScreen> {
  final BluetoothHealthService _ble = BluetoothHealthService.instance;

  StreamSubscription<int>? _liveSub;
  StreamSubscription<Map<String, dynamic>>? _readingSub;

  _Phase _phase = _Phase.waiting;
  int? _livePressure;
  Map<String, dynamic>? _reading;

  bool get _isGlucose =>
      _ble.isConnectedGlucose || (_reading?['type'] == 'blood_sugar');

  @override
  void initState() {
    super.initState();
    // Never auto-reconnect while another monitor is already linked — that
    // dropped Samico and opened an empty BP screen.
    if (!_ble.isConnected) {
      _phase = _Phase.reconnecting;
      unawaited(_tryAutoReconnect());
    } else if (_isGlucose) {
      // Proprietary Samico streams on notify after time-sync; SIG meters need
      // an RACP request. requestStoredRecords is a no-op without initSequence.
      setState(() => _phase = _Phase.measuring);
      unawaited(_ble.requestStoredRecords(preferLast: true));
    }
    _liveSub = _ble.liveStream.listen((pressure) {
      if (!mounted || _isGlucose) return;
      setState(() {
        _phase = _Phase.measuring;
        _livePressure = pressure;
      });
    });
    _readingSub = _ble.readingStream.listen((reading) {
      if (!mounted) return;
      unawaited(context.read<AppProvider>().refreshReadings());
      final type = reading['type'] as String?;
      if (_isGlucose) {
        if (type != 'blood_sugar') return;
      } else {
        if (type != 'blood_pressure') return;
      }
      setState(() {
        _phase = _Phase.done;
        _reading = reading;
      });
    });
    _ble.addListener(_onBleChanged);
  }

  Future<void> _tryAutoReconnect() async {
    final ok = await _ble.autoReconnect();
    if (!mounted) return;
    if (_phase != _Phase.reconnecting) return;
    setState(() => _phase = ok ? _Phase.waiting : _Phase.disconnected);
    if (ok && _isGlucose) {
      setState(() => _phase = _Phase.measuring);
      await _ble.requestStoredRecords(preferLast: true);
    }
  }

  void _onBleChanged() {
    if (!mounted) return;
    if (!_ble.isConnected &&
        !_ble.isAutoReconnecting &&
        _phase != _Phase.done &&
        _phase != _Phase.reconnecting) {
      setState(() => _phase = _Phase.disconnected);
    }
  }

  @override
  void dispose() {
    _liveSub?.cancel();
    _readingSub?.cancel();
    _ble.removeListener(_onBleChanged);
    super.dispose();
  }

  void _measureAgain() {
    setState(() {
      _reading = null;
      _livePressure = null;
      _phase = _ble.isConnected
          ? (_isGlucose ? _Phase.measuring : _Phase.waiting)
          : _Phase.disconnected;
    });
    if (_ble.isConnected && _isGlucose) {
      unawaited(_ble.requestStoredRecords(preferLast: true));
    }
  }

  @override
  Widget build(BuildContext context) {
    final title = _isGlucose ? 'Blood Sugar' : 'Blood Pressure';
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(title),
        backgroundColor: AppColors.white,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const SizedBox(height: 12),
              Text(
                _ble.connectedDevice?.advName.isNotEmpty == true
                    ? _ble.connectedDevice!.advName
                    : (_ble.activeProtocol?.name ?? 'Connected monitor'),
                style: const TextStyle(fontSize: 14, color: AppColors.textSecondary),
              ),
              const Spacer(),
              _gauge(),
              const SizedBox(height: 28),
              _statusText(),
              const Spacer(),
              _bottom(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _gauge() {
    final done = _phase == _Phase.done;
    final color = done ? AppColors.success : AppColors.primary;
    return SizedBox(
      width: 240,
      height: 240,
      child: Stack(
        alignment: Alignment.center,
        children: [
          SizedBox(
            width: 240,
            height: 240,
            child: CircularProgressIndicator(
              value: 1,
              strokeWidth: 10,
              valueColor: AlwaysStoppedAnimation(color.withValues(alpha: 0.12)),
            ),
          ),
          SizedBox(
            width: 240,
            height: 240,
            child: CircularProgressIndicator(
              value: (_phase == _Phase.measuring || _phase == _Phase.waiting)
                  ? null
                  : 1,
              strokeWidth: 10,
              valueColor: AlwaysStoppedAnimation(color),
            ),
          ),
          _gaugeCenter(),
        ],
      ),
    );
  }

  Widget _gaugeCenter() {
    switch (_phase) {
      case _Phase.done:
        if (_isGlucose) {
          final g = _reading?['glucose'];
          final unit = _reading?['unit'] ?? 'mg/dL';
          final display = g is num ? g.toStringAsFixed(g % 1 == 0 ? 0 : 1) : '--';
          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(display,
                  style: const TextStyle(
                      fontSize: 52,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary)),
              Text('$unit',
                  style: const TextStyle(
                      fontSize: 14, color: AppColors.textSecondary)),
            ],
          );
        }
        final sys = _reading?['systolic'];
        final dia = _reading?['diastolic'];
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text('${sys ?? '--'}',
                    style: const TextStyle(
                        fontSize: 52,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary)),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 4),
                  child: Text('/',
                      style: TextStyle(
                          fontSize: 32, color: AppColors.textTertiary)),
                ),
                Text('${dia ?? '--'}',
                    style: const TextStyle(
                        fontSize: 52,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary)),
              ],
            ),
            const Text('mmHg',
                style: TextStyle(fontSize: 14, color: AppColors.textSecondary)),
          ],
        );
      case _Phase.measuring:
        if (_isGlucose) {
          return const Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.water_drop, size: 40, color: AppColors.primary),
              SizedBox(height: 8),
              Text('Fetching…',
                  style: TextStyle(fontSize: 14, color: AppColors.textSecondary)),
            ],
          );
        }
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(_livePressure != null ? '$_livePressure' : '· · ·',
                style: const TextStyle(
                    fontSize: 48,
                    fontWeight: FontWeight.w800,
                    color: AppColors.primary)),
            const Text('Measuring…',
                style:
                    TextStyle(fontSize: 14, color: AppColors.textSecondary)),
          ],
        );
      case _Phase.waiting:
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(_isGlucose ? Icons.water_drop : Icons.favorite,
                size: 40, color: AppColors.primary),
            const SizedBox(height: 8),
            const Text('Ready',
                style:
                    TextStyle(fontSize: 16, color: AppColors.textSecondary)),
          ],
        );
      case _Phase.disconnected:
        return const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.bluetooth_disabled, size: 40, color: AppColors.error),
            SizedBox(height: 8),
            Text('Not connected',
                style: TextStyle(fontSize: 14, color: AppColors.error)),
          ],
        );
      case _Phase.reconnecting:
        return const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 40,
              height: 40,
              child: CircularProgressIndicator(
                strokeWidth: 3,
                color: AppColors.primary,
              ),
            ),
            SizedBox(height: 12),
            Text('Reconnecting…',
                style:
                    TextStyle(fontSize: 14, color: AppColors.textSecondary)),
          ],
        );
    }
  }

  Widget _statusText() {
    switch (_phase) {
      case _Phase.waiting:
        return Text(
          _isGlucose
              ? 'Take a reading on the meter, then tap Get Reading again if needed.'
              : 'Place the cuff and press START on your monitor.',
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 15, color: AppColors.textSecondary),
        );
      case _Phase.measuring:
        return Text(
          _isGlucose
              ? 'Asking the meter for your reading — keep Bluetooth connected.'
              : 'Measuring, please wait — keep still.',
          textAlign: TextAlign.center,
          style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: AppColors.primary),
        );
      case _Phase.done:
        final pulse = _reading?['pulse'];
        return Column(
          children: [
            if (!_isGlucose && pulse != null)
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.favorite, size: 18, color: AppColors.error),
                  const SizedBox(width: 6),
                  Text('$pulse bpm',
                      style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary)),
                ],
              ),
            const SizedBox(height: 8),
            const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.cloud_done, size: 16, color: AppColors.success),
                SizedBox(width: 6),
                Text('Saved to your records',
                    style: TextStyle(fontSize: 13, color: AppColors.success)),
              ],
            ),
          ],
        );
      case _Phase.disconnected:
        return const Text(
          'Your monitor isn’t connected. Reconnect it and try again.',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 15, color: AppColors.textSecondary),
        );
      case _Phase.reconnecting:
        return const Text(
          'Looking for your last monitor…',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 15, color: AppColors.textSecondary),
        );
    }
  }

  Widget _bottom() {
    switch (_phase) {
      case _Phase.done:
        return SizedBox(
          width: double.infinity,
          height: 52,
          child: ElevatedButton(
            onPressed: _measureAgain,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: AppColors.white,
            ),
            child: Text(_isGlucose ? 'Get Another Reading' : 'Measure Again'),
          ),
        );
      case _Phase.disconnected:
        return SizedBox(
          width: double.infinity,
          height: 52,
          child: ElevatedButton(
            onPressed: () => Navigator.of(context).pop(),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: AppColors.white,
            ),
            child: const Text('Back to Connect Device'),
          ),
        );
      case _Phase.waiting:
        if (_isGlucose) {
          return SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: () {
                setState(() => _phase = _Phase.measuring);
                unawaited(_ble.requestStoredRecords(preferLast: true));
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: AppColors.white,
              ),
              child: const Text('Get Reading'),
            ),
          );
        }
        return const SizedBox.shrink();
      default:
        return const SizedBox.shrink();
    }
  }
}
