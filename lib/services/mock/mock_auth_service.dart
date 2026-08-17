import '../../core/utils/result.dart';
import '../../models/otp_delivery.dart';
import '../../models/patient.dart';
import '../auth_service.dart';

/// Mock auth that always succeeds. Replace with [ErpNextAuthService] for production.
class MockAuthService implements AuthService {
  @override
  Future<Result<OtpDelivery>> requestOtp(String phone, {String channel = 'sms'}) async {
    await Future.delayed(const Duration(seconds: 1));
    if (phone.replaceAll(' ', '').length < 8) {
      return const Failure('Invalid phone number');
    }
    return Success(_mockDelivery(channel));
  }

  @override
  Future<Result<OtpDelivery>> resendOtp(String phone, {String channel = 'sms'}) async {
    await Future.delayed(const Duration(seconds: 1));
    return Success(_mockDelivery(channel));
  }

  OtpDelivery _mockDelivery(String channel) => channel == 'email'
      ? const OtpDelivery(channel: 'email', sentTo: 'p***@example.com')
      : const OtpDelivery(channel: 'sms');

  @override
  Future<Result<Map<String, String>>> verifyOtp(String identifier, String code, {String channel = 'sms'}) async {
    await Future.delayed(const Duration(milliseconds: 800));
    if (code.length != 6) {
      return const Failure('Invalid OTP code');
    }
    return Success({
      'api_key': 'mock_key_${identifier.hashCode}',
      'api_secret': 'mock_secret',
      'patient': 'PAT-001',
      'patient_name': 'Mock Patient',
    });
  }

  @override
  Future<Result<Map<String, String>>> selfRegister({
    required String fullName,
    required String mobile,
    required String otp,
    required String sex,
    required String dob,
    String? email,
  }) async {
    await Future.delayed(const Duration(milliseconds: 800));
    if (otp.length != 6) return const Failure('Invalid code');
    return Success({
      'api_key': 'mock_key_${mobile.hashCode}',
      'api_secret': 'mock_secret',
      'patient': 'PAT-NEW',
      'patient_name': fullName,
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
