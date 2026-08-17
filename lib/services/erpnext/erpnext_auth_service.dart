import 'package:dio/dio.dart';

import '../../core/network/api_client.dart';
import '../../core/utils/app_logger.dart';
import '../../core/utils/result.dart';
import '../../models/otp_delivery.dart';
import '../../models/patient.dart';
import '../auth_service.dart';

/// ERPNext implementation of [AuthService].
///
/// Uses the service account session (managed by [ApiClient]) to look up
/// patients by phone number.
class ErpNextAuthService implements AuthService {
  final ApiClient _api;

  ErpNextAuthService(this._api);

  @override
  Future<Result<OtpDelivery>> requestOtp(String phone, {String channel = 'sms'}) async {
    return _api.requestOtp(phone, channel: channel);
  }

  @override
  Future<Result<OtpDelivery>> resendOtp(String phone, {String channel = 'sms'}) async {
    return _api.resendOtp(phone, channel: channel);
  }

  @override
  Future<Result<Map<String, String>>> verifyOtp(String identifier, String code, {String channel = 'sms'}) async {
    return _api.verifyOtp(identifier, code, channel: channel);
  }

  @override
  Future<Result<Map<String, String>>> selfRegister({
    required String fullName,
    required String mobile,
    required String otp,
    required String sex,
    required String dob,
    String? email,
  }) {
    return _api.selfRegister(
      fullName: fullName,
      mobile: mobile,
      otp: otp,
      sex: sex,
      dob: dob,
      email: email,
    );
  }

  @override
  Future<Result<Patient>> lookupPatient(String phone) async {
    try {
      // After OTP login the app is authenticated as the patient's own user.
      // Use the scoped server endpoint that returns *this* user's patient,
      // rather than the generic /resource/Patient (which needs doctype
      // permissions and an exact mobile-format match).
      final response = await _api.dio.post(
        '/method/hiraal_emr.api.get_my_patient',
      );

      final data = response.data?['message'] as Map<String, dynamic>?;
      if (data == null || data.isEmpty) {
        return const Failure('No patient record found for this number');
      }

      return Success(Patient.fromJson(data));
    } on DioException catch (e) {
      log.e('lookupPatient failed', error: e);
      final msg = e.response?.data?['message']?.toString() ??
          'Could not find your record. Please try again.';
      return Failure(msg, statusCode: e.response?.statusCode);
    } catch (e) {
      return Failure(e.toString());
    }
  }

  @override
  Future<Result<bool>> checkSession() async {
    try {
      final response = await _api.dio.get(
        '/method/frappe.auth.get_logged_user',
      );
      final user = response.data?['message']?.toString() ?? '';
      return Success(user.isNotEmpty && user != 'Guest');
    } on DioException catch (e) {
      if (e.response?.statusCode == 401 || e.response?.statusCode == 403) {
        return const Success(false);
      }
      return Failure('Session check failed',
        statusCode: e.response?.statusCode,
      );
    } catch (e) {
      return Failure(e.toString());
    }
  }

  @override
  Future<Result<void>> logout() async {
    try {
      await _api.dio.post('/method/logout');
    } catch (_) {
      // Ignore errors — we clear local session regardless
    }
    await _api.clearSession();
    return const Success(null);
  }
}
