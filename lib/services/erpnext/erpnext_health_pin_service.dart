import 'package:dio/dio.dart';

import '../../core/network/api_client.dart';
import '../../core/utils/result.dart';
import '../health_pin_service.dart';

class ErpNextHealthPinService implements HealthPinService {
  final ApiClient _api;

  ErpNextHealthPinService(this._api);

  Map<String, dynamic>? _message(dynamic data) {
    if (data is Map && data['message'] is Map) {
      return Map<String, dynamic>.from(data['message'] as Map);
    }
    if (data is Map<String, dynamic>) return data;
    if (data is Map) return Map<String, dynamic>.from(data);
    return null;
  }

  @override
  Future<Result<bool>> hasHealthPin({String? patient}) async {
    try {
      final response = await _api.dio.post(
        '/method/hiraal_emr.api.has_health_pin',
        data: {if (patient != null && patient.isNotEmpty) 'patient': patient},
      );
      final msg = _message(response.data);
      final raw = msg?['has_pin'];
      return Success(raw == true || raw == 1 || raw == '1');
    } on DioException catch (e) {
      return Failure(
        dioErrorMessage(e, 'Could not check health PIN'),
        statusCode: e.response?.statusCode,
      );
    } catch (e) {
      return Failure(e.toString());
    }
  }

  @override
  Future<Result<void>> setHealthPin(String pin, {String? currentPin}) async {
    try {
      final response = await _api.dio.post(
        '/method/hiraal_emr.api.set_health_pin',
        data: {
          'pin': pin,
          if (currentPin != null && currentPin.isNotEmpty) 'current_pin': currentPin,
        },
      );
      final msg = _message(response.data);
      if (msg != null && msg['success'] == false) {
        return Failure(msg['message']?.toString() ?? 'Could not save health PIN');
      }
      return const Success(null);
    } on DioException catch (e) {
      return Failure(
        dioErrorMessage(e, 'Could not save health PIN'),
        statusCode: e.response?.statusCode,
      );
    } catch (e) {
      return Failure(e.toString());
    }
  }

  @override
  Future<Result<HealthPinVerifyResult>> verifyHealthPin(
    String pin, {
    String? patient,
  }) async {
    try {
      final response = await _api.dio.post(
        '/method/hiraal_emr.api.verify_health_pin',
        data: {
          'pin': pin,
          if (patient != null && patient.isNotEmpty) 'patient': patient,
        },
      );
      final msg = _message(response.data) ?? {};
      return Success(_parseVerify(msg));
    } on DioException catch (e) {
      return Failure(
        dioErrorMessage(e, 'Could not verify health PIN'),
        statusCode: e.response?.statusCode,
      );
    } catch (e) {
      return Failure(e.toString());
    }
  }

  HealthPinVerifyResult _parseVerify(Map<String, dynamic> msg) {
    int asInt(dynamic v) => int.tryParse('${v ?? 0}') ?? 0;
    return HealthPinVerifyResult(
      ok: msg['ok'] == true,
      locked: msg['locked'] == true,
      hasPin: msg['has_pin'] != false,
      token: msg['token']?.toString(),
      expiresIn: asInt(msg['expires_in']),
      retryAfter: asInt(msg['retry_after']),
      attemptsLeft: asInt(msg['attempts_left']),
      message: msg['message']?.toString(),
    );
  }

  @override
  Future<Result<void>> resetHealthPin({
    required String otp,
    required String newPin,
    String? mobile,
  }) async {
    try {
      final response = await _api.dio.post(
        '/method/hiraal_emr.api.reset_health_pin',
        data: {
          'otp': otp,
          'new_pin': newPin,
          if (mobile != null && mobile.isNotEmpty) 'mobile': mobile,
        },
      );
      final msg = _message(response.data);
      if (msg != null && msg['success'] == false) {
        return Failure(msg['message']?.toString() ?? 'Could not reset health PIN');
      }
      return const Success(null);
    } on DioException catch (e) {
      return Failure(
        dioErrorMessage(e, 'Could not reset health PIN'),
        statusCode: e.response?.statusCode,
      );
    } catch (e) {
      return Failure(e.toString());
    }
  }
}
