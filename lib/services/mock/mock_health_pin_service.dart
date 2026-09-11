import '../../core/utils/result.dart';
import '../health_pin_service.dart';

/// In-memory PIN store for demo builds. Hashes are not persisted.
class MockHealthPinService implements HealthPinService {
  final Map<String, String> _pins = {'1': '0000'};
  final Map<String, int> _fails = {};

  String _key(String? patient) =>
      (patient != null && patient.isNotEmpty) ? patient : '1';

  @override
  Future<Result<bool>> hasHealthPin({String? patient}) async {
    return Success(_pins.containsKey(_key(patient)));
  }

  @override
  Future<Result<void>> setHealthPin(String pin, {String? currentPin}) async {
    await Future<void>.delayed(const Duration(milliseconds: 200));
    if (pin.length != 4 || int.tryParse(pin) == null) {
      return const Failure('PIN must be 4 digits');
    }
    final key = _key(null);
    if (_pins.containsKey(key)) {
      if (currentPin == null || currentPin != _pins[key]) {
        return const Failure('Current PIN is incorrect');
      }
    }
    _pins[key] = pin;
    _fails[key] = 0;
    return const Success(null);
  }

  @override
  Future<Result<HealthPinVerifyResult>> verifyHealthPin(
    String pin, {
    String? patient,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 200));
    final key = _key(patient);
    final fails = _fails[key] ?? 0;
    if (fails >= 5) {
      return const Success(HealthPinVerifyResult(
        ok: false,
        locked: true,
        retryAfter: 900,
        attemptsLeft: 0,
        message: 'Too many incorrect attempts. Please wait 900 seconds.',
      ));
    }
    if (!_pins.containsKey(key)) {
      return const Success(HealthPinVerifyResult(
        ok: false,
        hasPin: false,
        attemptsLeft: 5,
        message: 'This patient has not created a health PIN yet',
      ));
    }
    if (pin == _pins[key]) {
      _fails[key] = 0;
      return const Success(HealthPinVerifyResult(
        ok: true,
        token: 'mock-health-pin-token',
        expiresIn: 900,
      ));
    }
    final nxt = fails + 1;
    _fails[key] = nxt;
    final locked = nxt >= 5;
    return Success(HealthPinVerifyResult(
      ok: false,
      locked: locked,
      retryAfter: locked ? 900 : 0,
      attemptsLeft: locked ? 0 : 5 - nxt,
      message: locked
          ? 'Too many incorrect attempts. Please wait 900 seconds.'
          : 'Incorrect PIN',
    ));
  }

  @override
  Future<Result<void>> resetHealthPin({
    required String otp,
    required String newPin,
    String? mobile,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 200));
    if (otp.length != 6) return const Failure('Invalid or expired code');
    if (newPin.length != 4 || int.tryParse(newPin) == null) {
      return const Failure('PIN must be 4 digits');
    }
    final key = _key(null);
    _pins[key] = newPin;
    _fails[key] = 0;
    return const Success(null);
  }
}
