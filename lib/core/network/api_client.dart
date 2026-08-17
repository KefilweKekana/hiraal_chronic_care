import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:intl/intl.dart';
import '../config/env_config.dart';
import '../utils/app_logger.dart';
import '../utils/result.dart';
import '../../models/otp_delivery.dart';

typedef UnauthorizedCallback = Future<void> Function();

/// Configured Dio instance for ERPNext API calls.
/// Auth priority: API-key header → session login.
/// On web: browser-managed cookies via withCredentials.
/// On native: sid extracted from login response and sent as a Cookie header.
class ApiClient {
  late final Dio dio;
  final UnauthorizedCallback? _onUnauthorized;

  String? _sid;
  // Shared in-flight login so concurrent requests await the same session
  // instead of racing (and clobbering each other's sid).
  Future<bool>? _loginFuture;

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
  /// Concurrent callers share the in-flight login future.
  Future<bool> _loginWithCredentials() {
    final inFlight = _loginFuture;
    if (inFlight != null) return inFlight;
    final future = _doLogin();
    _loginFuture = future;
    return future;
  }

  Future<bool> _doLogin() async {
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
      _loginFuture = null;
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

  Future<Result<OtpDelivery>> requestOtp(String identifier, {String channel = 'sms'}) async {
    try {
      final response = await dio.post(
        '/method/hiraal_emr.api.request_otp',
        data: channel == 'email'
            ? {'email': identifier, 'channel': 'email'}
            : {'mobile': identifier, 'channel': 'sms'},
      );
      final msg = response.data?['message'] as Map<String, dynamic>?;
      return Success(OtpDelivery.fromMessage(msg));
    } on DioException catch (e) {
      return Failure(
        e.response?.data?['message']?.toString() ?? 'Failed to request OTP',
        statusCode: e.response?.statusCode,
      );
    } catch (e) {
      return Failure(e.toString());
    }
  }

  Future<Result<Map<String, String>>> verifyOtp(String identifier, String code, {String channel = 'sms'}) async {
    try {
      final response = await dio.post(
        '/method/hiraal_emr.api.verify_otp',
        data: channel == 'email'
            ? {'email': identifier, 'otp': code, 'channel': 'email'}
            : {'mobile': identifier, 'otp': code, 'channel': 'sms'},
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

  /// Create a new patient account. The OTP proves phone ownership; on success
  /// the server returns API credentials (same shape as verifyOtp), logging the
  /// new patient straight in.
  Future<Result<Map<String, String>>> selfRegister({
    required String fullName,
    required String mobile,
    required String otp,
    required String sex,
    required String dob,
    String? email,
  }) async {
    try {
      final response = await dio.post(
        '/method/hiraal_emr.api.self_register',
        data: {
          'full_name': fullName,
          'mobile': mobile,
          'otp': otp,
          'sex': sex,
          'dob': dob,
          if (email != null && email.isNotEmpty) 'email': email,
        },
      );
      final data = response.data?['message'] as Map<String, dynamic>?;
      if (data == null || data['success'] != true) {
        return const Failure('Registration failed');
      }
      return Success(<String, String>{
        'api_key': data['api_key']?.toString() ?? '',
        'api_secret': data['api_secret']?.toString() ?? '',
        'patient': data['patient']?.toString() ?? '',
        'patient_name': data['patient_name']?.toString() ?? '',
      });
    } on DioException catch (e) {
      return Failure(
        e.response?.data?['message']?.toString() ?? 'Registration failed',
        statusCode: e.response?.statusCode,
      );
    } catch (e) {
      return Failure(e.toString());
    }
  }

  Future<Result<OtpDelivery>> resendOtp(String identifier, {String channel = 'sms'}) async {
    try {
      final response = await dio.post(
        '/method/hiraal_emr.api.resend_otp',
        data: channel == 'email'
            ? {'email': identifier, 'channel': 'email'}
            : {'mobile': identifier, 'channel': 'sms'},
      );
      final msg = response.data?['message'] as Map<String, dynamic>?;
      return Success(OtpDelivery.fromMessage(msg));
    } on DioException catch (e) {
      return Failure(
        e.response?.data?['message']?.toString() ?? 'Failed to resend OTP',
        statusCode: e.response?.statusCode,
      );
    } catch (e) {
      return Failure(e.toString());
    }
  }

  /// Register this device's FCM push token with the server (best-effort).
  Future<void> registerPushToken(String token, {String platform = 'Android'}) async {
    try {
      await dio.post(
        '/method/hiraal_emr.api.register_push_token',
        data: {'token': token, 'platform': platform},
      );
    } catch (e) {
      log.w('registerPushToken failed', error: e);
    }
  }

  /// Fetch the logged-in patient's full data export (profile, readings,
  /// orders, subscription, payments) for the "Export My Data" feature.
  Future<Result<Map<String, dynamic>>> exportMyData() async {
    try {
      final response = await dio.post('/method/hiraal_emr.api.export_my_data');
      final data = response.data?['message'] as Map<String, dynamic>?;
      if (data == null) return const Failure('No data returned');
      return Success(data);
    } on DioException catch (e) {
      return Failure(
        e.response?.data?['message']?.toString() ?? 'Could not export your data',
        statusCode: e.response?.statusCode,
      );
    } catch (e) {
      return Failure(e.toString());
    }
  }

  /// Disable this user's push tokens on the server (best-effort). Called on
  /// logout so the device stops receiving the previous patient's notifications.
  Future<void> unregisterPushToken() async {
    try {
      await dio.post('/method/hiraal_emr.api.unregister_my_push_token');
    } catch (e) {
      log.w('unregisterPushToken failed', error: e);
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
    String? referenceId,
    DateTime? date,
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
          if (referenceId != null && referenceId.isNotEmpty) 'reference_id': referenceId,
          // Device-recorded measurement time (store-and-forward meters) —
          // omitted for live entries so the server stamps them itself.
          if (date != null) 'reading_date': DateFormat('yyyy-MM-dd').format(date),
          if (date != null) 'reading_time': DateFormat('HH:mm:ss').format(date),
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
      // Use existing sid (preset or from login) — Cookie header only, never
      // the query string, so it stays out of URLs and request logs.
      options.headers['Cookie'] = 'sid=${_client._sid}';
    } else if (EnvConfig.hasSessionCredentials) {
      // Login to obtain sid
      await _client._loginWithCredentials();
      if (_client._sid != null) {
        options.headers['Cookie'] = 'sid=${_client._sid}';
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
        // Don't wipe a sid an in-flight login may have just obtained.
        if (_client._loginFuture == null) _client._sid = null;
        final ok = await _client._loginWithCredentials();
        if (ok) {
          try {
            final opts = err.requestOptions;
            opts.extra['_retried'] = true;
            if (_client._sid != null) {
              opts.headers['Cookie'] = 'sid=${_client._sid}';
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
