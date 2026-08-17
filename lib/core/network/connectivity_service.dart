import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import '../utils/app_logger.dart';

/// Monitors network connectivity and notifies listeners.
class ConnectivityService extends ChangeNotifier {
  final Connectivity _connectivity = Connectivity();
  StreamSubscription<List<ConnectivityResult>>? _subscription;
  bool _isOnline = true;
  bool _disposed = false;

  bool get isOnline => _isOnline;

  ConnectivityService() {
    _init();
  }

  Future<void> _init() async {
    final results = await _connectivity.checkConnectivity();
    // The service may have been disposed while the check was in flight.
    if (_disposed) return;
    _updateStatus(results);
    _subscription = _connectivity.onConnectivityChanged.listen(_updateStatus);
  }

  void _updateStatus(List<ConnectivityResult> results) {
    if (_disposed) return;
    final online = results.any((r) => r != ConnectivityResult.none);
    if (online != _isOnline) {
      _isOnline = online;
      log.i('Connectivity changed: ${online ? "online" : "offline"}');
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _disposed = true;
    _subscription?.cancel();
    super.dispose();
  }
}
