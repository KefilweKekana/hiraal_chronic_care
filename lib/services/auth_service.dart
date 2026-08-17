import '../../core/utils/result.dart';
import '../../models/otp_delivery.dart';
import '../../models/patient.dart';

/// Contract for authentication operations.
/// Implement with ERPNext calls or use [MockAuthService].
abstract class AuthService {
  /// Request an OTP for the given phone number, delivered via [channel]
  /// ('sms' or 'email'). Returns how/where the code was actually delivered.
  Future<Result<OtpDelivery>> requestOtp(String phone, {String channel = 'sms'});

  /// Resend an OTP to the given phone number via [channel] ('sms' or 'email').
  Future<Result<OtpDelivery>> resendOtp(String phone, {String channel = 'sms'});

  /// Verify the OTP [code] for the given [identifier] (phone for SMS login, or
  /// email for email login — selected by [channel]).
  /// Returns patient credentials (api_key, api_secret, patient, patient_name) on success.
  Future<Result<Map<String, String>>> verifyOtp(String identifier, String code, {String channel = 'sms'});

  /// Create a new patient account (self-registration). The [otp] proves phone
  /// ownership. Returns patient credentials on success, same as [verifyOtp].
  Future<Result<Map<String, String>>> selfRegister({
    required String fullName,
    required String mobile,
    required String otp,
    required String sex,
    required String dob,
    String? email,
  });

  /// Look up a patient by phone number. Returns the [Patient] on success.
  Future<Result<Patient>> lookupPatient(String phone);

  /// Check if a valid session exists.
  Future<Result<bool>> checkSession();

  /// Log out and clear stored credentials.
  Future<Result<void>> logout();
}
