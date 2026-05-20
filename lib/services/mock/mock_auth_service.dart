import '../../core/utils/result.dart';
import '../../models/patient.dart';
import '../auth_service.dart';

/// Mock auth that always succeeds. Replace with [ErpNextAuthService] for production.
class MockAuthService implements AuthService {
  @override
  Future<Result<void>> requestOtp(String phone) async {
    await Future.delayed(const Duration(seconds: 1));
    if (phone.replaceAll(' ', '').length < 8) {
      return const Failure('Invalid phone number');
    }
    return const Success(null);
  }

  @override
  Future<Result<void>> resendOtp(String phone) async {
    await Future.delayed(const Duration(seconds: 1));
    return const Success(null);
  }

  @override
  Future<Result<Map<String, String>>> verifyOtp(String phone, String code) async {
    await Future.delayed(const Duration(milliseconds: 800));
    if (code.length != 6) {
      return const Failure('Invalid OTP code');
    }
    return Success({
      'api_key': 'mock_key_${phone.hashCode}',
      'api_secret': 'mock_secret',
      'patient': 'PAT-001',
      'patient_name': 'Mock Patient',
    });
  }

  @override
  Future<Result<Patient>> lookupPatient(String phone) async {
    await Future.delayed(const Duration(seconds: 1));
    if (phone.replaceAll(' ', '').length < 8) {
      return const Failure('Invalid phone number');
    }
    return Success(Patient.mock());
  }

  @override
  Future<Result<bool>> checkSession() async {
    await Future.delayed(const Duration(milliseconds: 300));
    return const Success(false); // No persisted session in mock mode
  }

  @override
  Future<Result<void>> logout() async {
    await Future.delayed(const Duration(milliseconds: 200));
    return const Success(null);
  }
}
