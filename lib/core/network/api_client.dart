import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import '../config/env_config.dart';
import '../utils/app_logger.dart';
import '../utils/result.dart';

typedef UnauthorizedCallback = Future<void> Function();

/// Configured Dio instance for ERPNext API calls.
/// Auth priority: API-key header → session login.
/// On web: browser-managed cookies via withCredentials.
/// On native: sid extracted from login response and sent as query param.
class ApiClient {
  late final Dio dio;
  final UnauthorizedCallback? _onUnauthorized;

  String? _sid;
  bool _loggingIn = false;

  // Patient-specific API key auth (set after OTP verification)
  String? _patientApiKey;
  String? _patientApiSecret;

  ApiClient({
    UnauthorizedCallback? onUnauthorized,
  }) : _onUnauthorized = onUnauthorized {
    // Use pre-obtained sid if provided (useful for web debugging)
    if (EnvConfig.hasPresetSid) {
      _sid = EnvConfig.erpSid;
    }

    dio = Dio(
      BaseOptions(
        baseUrl: EnvConfig.baseUrl + EnvConfig.apiPrefix,
        connectTimeout: const Duration(milliseconds: EnvConfig.connectTimeoutMs),
        receiveTimeout: const Duration(milliseconds: EnvConfig.receiveTimeoutMs),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        // withCredentials tells the browser to include cookies cross-origin
        extra: kIsWeb ? {'withCredentials': true} : {},
      ),
    );

    dio.interceptors.add(_AuthInterceptor(this));
    dio.interceptors.add(_LoggingInterceptor());
  }

  /// Login with username/password and store the session id.
  Future<bool> _loginWithCredentials() async {
    if (_loggingIn) return _sid != null;
    _loggingIn = true;
    try {
      // Use a separate Dio for login to avoid interceptor loops.
      // On both web and native, we try to extract the sid from Set-Cookie.
      final loginDio = Dio(BaseOptions(
        baseUrl: EnvConfig.baseUrl,
        connectTimeout: const Duration(milliseconds: EnvConfig.connectTimeoutMs),
        receiveTimeout: const Duration(milliseconds: EnvConfig.receiveTimeoutMs),
        extra: kIsWeb ? {'withCredentials': true} : {},
      ));

      final response = await loginDio.post(
        '/api/method/login',
        data: {'usr': EnvConfig.erpUser, 'pwd': EnvConfig.erpPassword},
        options: Options(
          contentType: Headers.formUrlEncodedContentType,
          validateStatus: (s) => s != null && s < 500,
          extra: kIsWeb ? {'withCredentials': true} : {},
        ),
      );

      if (response.statusCode == 200) {
        // Try to extract sid from Set-Cookie header (works on native,
        // and on web with --disable-web-security).
        final cookies = response.headers['set-cookie'];
        log.d('Login response headers: ${response.headers.map}');
        if (cookies != null) {
          for (final cookie in cookies) {
            if (cookie.startsWith('sid=')) {
              _sid = cookie.split(';').first.replaceFirst('sid=', '');
              break;
            }
          }
        }
        if (_sid != null && _sid != 'Guest') {
          log.i('ERPNext session established for ${EnvConfig.erpUser} (sid extracted)');
          return true;
        }
        log.w('ERPNext login OK but no sid in headers. Cookie headers: $cookies');
        return false;
      }
      log.w('ERPNext login failed: ${response.statusCode}');
      return false;
    } catch (e) {
      log.e('ERPNext login error', error: e);
      return false;
    } finally {
      _loggingIn = false;
    }
  }

  /// Set patient-specific API key auth (used after OTP verification).
  void setPatientAuth(String apiKey, String apiSecret) {
    _patientApiKey = apiKey;
    _patientApiSecret = apiSecret;
    log.i('Patient API auth configured');
  }

  /// Clear patient-specific auth (on logout).
  void clearPatientAuth() {
    _patientApiKey = null;
    _patientApiSecret = null;
  }

  /// Clear session on logout.
  Future<void> clearSession() async {
    _sid = null;
    clearPatientAuth();
  }

  // ── OTP ───────────────────────────────────────────────

  Future<Result<void>> requestOtp(String phone) async {
    try {
      await dio.post(
        '/method/hiraal_emr.api.request_otp',
        data: {'mobile': phone},
      );
      return const Success(null);
    } on DioException catch (e) {
      return Failure(
        e.response?.data?['message']?.toString() ?? 'Failed to request OTP',
        statusCode: e.response?.statusCode,
      );
    } catch (e) {
      return Failure(e.toString());
    }
  }

  Future<Result<Map<String, String>>> verifyOtp(String phone, String code) async {
    try {
      final response = await dio.post(
        '/method/hiraal_emr.api.verify_otp',
        data: {'mobile': phone, 'otp': code},
      );
      final data = response.data?['message'] as Map<String, dynamic>?;
      if (data == null || data['success'] != true) {
        return const Failure('OTP verification failed');
      }
      final credentials = <String, String>{
        'api_key': data['api_key']?.toString() ?? '',
        'api_secret': data['api_secret']?.toString() ?? '',
        'patient': data['patient']?.toString() ?? '',
        'patient_name': data['patient_name']?.toString() ?? '',
      };
      return Success(credentials);
    } on DioException catch (e) {
      return Failure(
        e.response?.data?['message']?.toString() ?? 'Invalid or expired OTP',
        statusCode: e.response?.statusCode,
      );
    } catch (e) {
      return Failure(e.toString());
    }
  }

  Future<Result<void>> resendOtp(String phone) async {
    try {
      await dio.post(
        '/method/hiraal_emr.api.resend_otp',
        data: {'mobile': phone},
      );
      return const Success(null);
    } on DioException catch (e) {
      return Failure(
        e.response?.data?['message']?.toString() ?? 'Failed to resend OTP',
        statusCode: e.response?.statusCode,
      );
    } catch (e) {
      return Failure(e.toString());
    }
  }

  // ── Health Tips ───────────────────────────────────────

  Future<Result<List<Map<String, dynamic>>>> getHealthTips() async {
    try {
      final response = await dio.get(
        '/method/chronic_care.content.health_tips',
      );
      final data = response.data?['message'] as List? ?? [];
      return Success(data.cast<Map<String, dynamic>>());
    } on DioException catch (e) {
      return Failure(
        e.response?.data?['message']?.toString() ?? 'Failed to fetch health tips',
        statusCode: e.response?.statusCode,
      );
    } catch (e) {
      return Failure(e.toString());
    }
  }

  // ── Care Plan ─────────────────────────────────────────

  Future<Result<Map<String, dynamic>>> getCarePlan(String patientId) async {
    try {
      final response = await dio.get(
        '/method/chronic_care.care_plan.get',
        queryParameters: {'patient': patientId},
      );
      final data = response.data?['message'] as Map<String, dynamic>? ?? {};
      return Success(data);
    } on DioException catch (e) {
      return Failure(
        e.response?.data?['message']?.toString() ?? 'Failed to fetch care plan',
        statusCode: e.response?.statusCode,
      );
    } catch (e) {
      return Failure(e.toString());
    }
  }

  // ── Weekly Summary ────────────────────────────────────

  Future<Result<Map<String, dynamic>>> getWeeklySummary(String patientId) async {
    try {
      final response = await dio.get(
        '/method/chronic_care.summary.weekly',
        queryParameters: {'patient': patientId},
      );
      final data = response.data?['message'] as Map<String, dynamic>? ?? {};
      return Success(data);
    } on DioException catch (e) {
      return Failure(
        e.response?.data?['message']?.toString() ?? 'Failed to fetch weekly summary',
        statusCode: e.response?.statusCode,
      );
    } catch (e) {
      return Failure(e.toString());
    }
  }

  // ── BLE Protocols ─────────────────────────────────────

  Future<Result<List<Map<String, dynamic>>>> getBleProtocols() async {
    try {
      final response = await dio.get('/method/hiraal_emr.api.get_ble_protocols');
      final data = response.data?['message'] as Map<String, dynamic>? ?? {};
      final protocols = data['protocols'] as List? ?? [];
      return Success(protocols.cast<Map<String, dynamic>>());
    } on DioException catch (e) {
      return Failure(
        e.response?.data?['message']?.toString() ?? 'Failed to fetch BLE protocols',
        statusCode: e.response?.statusCode,
      );
    } catch (e) {
      return Failure(e.toString());
    }
  }

  // ── Device Pairing ────────────────────────────────────

  Future<Result<Map<String, dynamic>>> pairDevice({
    required String patient,
    required String deviceId,
    required String deviceType,
    String? deviceName,
    String? manufacturer,
    String? model,
    String? serialNumber,
  }) async {
    try {
      final response = await dio.post(
        '/method/hiraal_emr.api.pair_device',
        data: {
          'patient': patient,
          'device_id': deviceId,
          'device_type': deviceType,
          if (deviceName != null) 'device_name': deviceName,
          if (manufacturer != null) 'manufacturer': manufacturer,
          if (model != null) 'model': model,
          if (serialNumber != null) 'serial_number': serialNumber,
        },
      );
      final data = response.data?['message'] as Map<String, dynamic>? ?? {};
      return Success(data);
    } on DioException catch (e) {
      return Failure(
        e.response?.data?['message']?.toString() ?? 'Failed to pair device',
        statusCode: e.response?.statusCode,
      );
    } catch (e) {
      return Failure(e.toString());
    }
  }

  // ── Daily Reading Submission ──────────────────────────

  Future<Result<Map<String, dynamic>>> submitDailyReading({
    required String patient,
    int? bpSystolic,
    int? bpDiastolic,
    double? bloodSugar,
    double? weight,
    String? sugarUnit,
    bool? medicineTaken,
    String? note,
    String source = 'App',
    String? deviceId,
  }) async {
    try {
      final response = await dio.post(
        '/method/hiraal_emr.api.submit_reading',
        data: {
          'patient': patient,
          if (bpSystolic != null) 'bp_systolic': bpSystolic,
          if (bpDiastolic != null) 'bp_diastolic': bpDiastolic,
          if (bloodSugar != null) 'blood_sugar': bloodSugar,
          if (weight != null) 'weight': weight,
          if (sugarUnit != null) 'sugar_unit': sugarUnit,
          if (medicineTaken != null) 'medicine_taken': medicineTaken ? 'Yes' : 'No',
          if (note != null && note.isNotEmpty) 'note': note,
          'source': source,
          if (deviceId != null) 'device_id': deviceId,
        },
      );
      final data = response.data?['message'] as Map<String, dynamic>? ?? {};
      return Success(data);
    } on DioException catch (e) {
      return Failure(
        e.response?.data?['message']?.toString() ?? 'Failed to submit reading',
        statusCode: e.response?.statusCode,
      );
    } catch (e) {
      return Failure(e.toString());
    }
  }
}

/// Injects auth into every request.
class _AuthInterceptor extends Interceptor {
  final ApiClient _client;

  _AuthInterceptor(this._client);

  @override
  void onRequest(
      RequestOptions options, RequestInterceptorHandler handler) async {
    // Skip auth for login requests
    if (options.extra['_isLogin'] == true) {
      handler.next(options);
      return;
    }

    // Ensure withCredentials on web for every request
    if (kIsWeb) {
      options.extra['withCredentials'] = true;
    }

    if (_client._patientApiKey != null && _client._patientApiSecret != null) {
      // Patient-specific API key auth (post-OTP)
      options.headers['Authorization'] =
          'token ${_client._patientApiKey}:${_client._patientApiSecret}';
    } else if (EnvConfig.hasApiKey) {
      // Service-account API key auth (fallback)
      options.headers['Authorization'] =
          'token ${EnvConfig.erpApiKey}:${EnvConfig.erpApiSecret}';
    } else if (_client._sid != null) {
      // Use existing sid (preset or from login)
      options.headers['Cookie'] = 'sid=${_client._sid}';
      options.queryParameters['sid'] = _client._sid;
    } else if (EnvConfig.hasSessionCredentials) {
      // Login to obtain sid
      await _client._loginWithCredentials();
      if (_client._sid != null) {
        options.headers['Cookie'] = 'sid=${_client._sid}';
        options.queryParameters['sid'] = _client._sid;
      }
    }
    handler.next(options);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    if (err.response?.statusCode == 401 || err.response?.statusCode == 403) {
      log.w('Auth error ${err.response?.statusCode}: ${err.response?.data}');

      // Only retry once
      if (err.requestOptions.extra['_retried'] == true) {
        await _client._onUnauthorized?.call();
        handler.next(err);
        return;
      }

      // Re-login and retry
      if (!EnvConfig.hasApiKey && EnvConfig.hasSessionCredentials) {
        _client._sid = null;
        final ok = await _client._loginWithCredentials();
        if (ok) {
          try {
            final opts = err.requestOptions;
            opts.extra['_retried'] = true;
            if (_client._sid != null) {
              opts.headers['Cookie'] = 'sid=${_client._sid}';
              opts.queryParameters['sid'] = _client._sid!;
            }
            final response = await _client.dio.fetch(opts);
            return handler.resolve(response);
          } catch (_) {}
        }
      }
      await _client._onUnauthorized?.call();
    }
    handler.next(err);
  }
}

/// Logs requests and responses at debug level.
class _LoggingInterceptor extends Interceptor {
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    log.d('→ ${options.method} ${options.uri}');
    handler.next(options);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    log.d('← ${response.statusCode} ${response.requestOptions.uri}');
    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    log.e('✗ ${err.requestOptions.uri}', error: err.message);
    handler.next(err);
  }
}
