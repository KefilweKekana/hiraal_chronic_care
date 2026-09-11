import '../core/utils/result.dart';

class HealthPinVerifyResult {
  final bool ok;
  final bool locked;
  final bool hasPin;
  final String? token;
  final int expiresIn;
  final int retryAfter;
  final int attemptsLeft;
  final String? message;

  const HealthPinVerifyResult({
    required this.ok,
    this.locked = false,
    this.hasPin = true,
    this.token,
    this.expiresIn = 0,
    this.retryAfter = 0,
    this.attemptsLeft = 0,
    this.message,
  });
}

/// Contract for the 4-digit health PIN that gates lab results and records.
abstract class HealthPinService {
  Future<Result<bool>> hasHealthPin({String? patient});

  Future<Result<void>> setHealthPin(String pin, {String? currentPin});

  Future<Result<HealthPinVerifyResult>> verifyHealthPin(
    String pin, {
    String? patient,
  });

  Future<Result<void>> resetHealthPin({
    required String otp,
    required String newPin,
    String? mobile,
  });
}
