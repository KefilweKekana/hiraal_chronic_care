import 'package:flutter/foundation.dart';

import '../core/constants/app_constants.dart';

/// In-memory unlock session for sensitive health screens.
///
/// Remembers a successful PIN for a short window so the patient does not
/// re-enter on every tap. Cleared when the app backgrounds or the TTL ends.
class HealthPinController extends ChangeNotifier {
  HealthPinController._();
  static final HealthPinController instance = HealthPinController._();

  static const unlockTtl = Duration(minutes: AppConstants.healthPinUnlockMinutes);

  final Map<String, DateTime> _until = {};

  bool isUnlocked(String patientId) {
    if (patientId.isEmpty) return false;
    final until = _until[patientId];
    if (until == null) return false;
    if (DateTime.now().isAfter(until)) {
      _until.remove(patientId);
      return false;
    }
    return true;
  }

  void markUnlocked(String patientId) {
    if (patientId.isEmpty) return;
    _until[patientId] = DateTime.now().add(unlockTtl);
    notifyListeners();
  }

  void lockPatient(String patientId) {
    if (_until.remove(patientId) != null) notifyListeners();
  }

  void lockAll() {
    if (_until.isEmpty) return;
    _until.clear();
    notifyListeners();
  }
}
