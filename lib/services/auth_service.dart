import '../../core/utils/result.dart';
import '../../models/patient.dart';

/// Contract for authentication operations.
/// Implement with ERPNext calls or use [MockAuthService].
abstract class AuthService {
  /// Request an OTP to be sent to the given phone number.
  Future<Result<void>> requestOtp(String phone);

  /// Resend an OTP to the given phone number.
  Future<Result<void>> resendOtp(String phone);

  /// Verify the OTP code for the given phone number.
  /// Returns patient credentials (api_key, api_secret, patient, patient_name) on success.
  Future<Result<Map<String, String>>> verifyOtp(String phone, String code);

  /// Look up a patient by phone number. Returns the [Patient] on success.
  Future<Result<Patient>> lookupPatient(String phone);

  /// Check if a valid session exists.
  Future<Result<bool>> checkSession();

  /// Log out and clear stored credentials.
  Future<Result<void>> logout();
}
