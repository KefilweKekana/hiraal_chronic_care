import 'package:flutter/foundation.dart';

/// Environment configuration for the app.
class EnvConfig {
  EnvConfig._();

  static const String environment = String.fromEnvironment(
    'APP_ENV',
    defaultValue: 'development',
  );

  static const bool useMock = bool.fromEnvironment(
    'USE_MOCK',
    defaultValue: true,
  );

  static const String baseUrl = String.fromEnvironment(
    'BASE_URL',
    defaultValue: 'https://alfuraat.com',
  );
  static const String apiPrefix = '/api';

  static const bool enableCrashReporting = bool.fromEnvironment(
    'ENABLE_CRASH_REPORTING',
    defaultValue: false,
  );

  static const String sentryDsn = String.fromEnvironment(
    'SENTRY_DSN',
    defaultValue: '',
  );

  // Timeouts
  static const int connectTimeoutMs = 15000;
  static const int receiveTimeoutMs = 15000;

  // Session
  static const int sessionTimeoutMinutes = 30;

  // Retry
  static const int maxRetries = 3;

  // ERPNext API key authentication
  // Pass via: --dart-define=ERP_API_KEY=xxx --dart-define=ERP_API_SECRET=xxx
  static const String erpApiKey = String.fromEnvironment(
    'ERP_API_KEY',
    defaultValue: '',
  );
  static const String erpApiSecret = String.fromEnvironment(
    'ERP_API_SECRET',
    defaultValue: '',
  );

  // ERPNext session auth fallback (used when API key is empty or invalid)
  // Pass via: --dart-define=ERP_USER=xxx --dart-define=ERP_PASSWORD=xxx
  static const String erpUser = String.fromEnvironment(
    'ERP_USER',
    defaultValue: '',
  );
  static const String erpPassword = String.fromEnvironment(
    'ERP_PASSWORD',
    defaultValue: '',
  );

  // Pre-obtained session ID (useful for web debugging where cookies can't be extracted)
  // Pass via: --dart-define=ERP_SID=xxx
  static const String erpSid = String.fromEnvironment(
    'ERP_SID',
    defaultValue: '',
  );

  static bool get hasApiKey => erpApiKey.isNotEmpty && erpApiSecret.isNotEmpty;
  static bool get hasSessionCredentials => erpUser.isNotEmpty && erpPassword.isNotEmpty;
  static bool get hasPresetSid => erpSid.isNotEmpty;

  static bool get isProduction => environment == 'production';

  static bool get enableVerboseLogging => const bool.fromEnvironment(
        'ENABLE_VERBOSE_LOGGING',
        defaultValue: !kReleaseMode,
      );

  /// Full method URL for an ERPNext whitelisted method.
  static String methodUrl(String method) {
    final normalizedMethod = method.startsWith('/') ? method : '/$method';
    if (isProduction && !baseUrl.startsWith('https://')) {
      throw StateError('Production builds must use an HTTPS base URL.');
    }
    return '$baseUrl$apiPrefix$normalizedMethod';
  }
}
