import 'package:dio/dio.dart';

import '../../core/network/api_client.dart';
import '../../core/utils/app_logger.dart';
import '../../core/utils/result.dart';
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
  Future<Result<void>> requestOtp(String phone) async {
    return _api.requestOtp(phone);
  }

  @override
  Future<Result<void>> resendOtp(String phone) async {
    return _api.resendOtp(phone);
  }

  @override
  Future<Result<Map<String, String>>> verifyOtp(String phone, String code) async {
    return _api.verifyOtp(phone, code);
  }

  @override
  Future<Result<Patient>> lookupPatient(String phone) async {
    try {
      // The service account session is already managed by ApiClient.
      // Look up the patient by phone number using the REST API.
      // Strip country code — ERPNext stores local numbers only.
      final mobile = phone.replaceFirst('+252', '');
      final patientResponse = await _api.dio.get(
        '/resource/Patient',
        queryParameters: {
          'filters': '[["mobile","=","$mobile"]]',
          'fields':
              '["name","patient_name","mobile","sex","dob","blood_group","image"]',
          'limit_page_length': 1,
        },
      );

      final patients = patientResponse.data?['data'] as List?;
      if (patients == null || patients.isEmpty) {
        return const Failure('No patient record found for this number');
      }

      final patientData = patients.first as Map<String, dynamic>;

      // Fetch full patient details
      final patientName = patientData['name'];
      final detailResponse = await _api.dio.get(
        '/resource/Patient/$patientName',
      );

      final fullData =
          detailResponse.data?['data'] as Map<String, dynamic>? ??
              patientData;

      return Success(Patient.fromJson(fullData));
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
