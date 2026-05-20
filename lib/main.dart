import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

import 'core/config/env_config.dart';
import 'core/theme/app_theme.dart';
import 'core/network/connectivity_service.dart';
import 'core/utils/app_logger.dart';
import 'providers/app_provider.dart';
import 'models/patient.dart';
import 'services/service_locator.dart';
import 'services/background_sync_service.dart';
import 'services/push_notification_service.dart';
import 'screens/auth/splash_screen.dart';
import 'screens/auth/register_screen.dart';
import 'screens/auth/otp_screen.dart';
import 'screens/auth/registration_success_screen.dart';
import 'screens/navigation/app_shell.dart';
import 'screens/services/book_doctor_screen.dart';
import 'screens/services/lab_test_screen.dart';
import 'screens/services/medicine_order_screen.dart';
import 'screens/alerts/contact_care_team_screen.dart';
import 'screens/notifications/notification_screen.dart';
import 'screens/health_tips/health_tips_screen.dart';
import 'screens/summary/weekly_summary_screen.dart';
import 'screens/offline/offline_screen.dart';
import 'screens/offline/sync_screen.dart';
import 'screens/error/error_screen.dart';
import 'screens/reminders/reminder_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (EnvConfig.enableCrashReporting && EnvConfig.sentryDsn.isNotEmpty) {
    await SentryFlutter.init(
      (options) {
        options.dsn = EnvConfig.sentryDsn;
        options.environment = EnvConfig.environment;
        options.tracesSampleRate = EnvConfig.isProduction ? 0.1 : 1.0;
      },
      appRunner: () => runZonedGuarded(
        () async {
          await _initAndRun();
        },
        _reportUnhandledError,
      ),
    );
    return;
  }

  runZonedGuarded(
    () async {
      await _initAndRun();
    },
    _reportUnhandledError,
  );
}

Future<void> _initAndRun() async {
  // Initialize service locator (mock or ERPNext).
  ServiceLocator.instance.init();

  // Initialize background sync and push notifications.
  await BackgroundSyncService.instance.initialize();
  await BackgroundSyncService.instance.registerPeriodicSync();
  await PushNotificationService.instance.initialize();

  // Global error handler – catches unhandled Flutter errors.
  FlutterError.onError = (details) {
    log.e('FlutterError', error: details.exception, stackTrace: details.stack);
    if (EnvConfig.enableCrashReporting && EnvConfig.sentryDsn.isNotEmpty) {
      Sentry.captureException(details.exception, stackTrace: details.stack);
    }
  };

  PlatformDispatcher.instance.onError = (error, stackTrace) {
    log.e('PlatformDispatcherError', error: error, stackTrace: stackTrace);
    if (EnvConfig.enableCrashReporting && EnvConfig.sentryDsn.isNotEmpty) {
      Sentry.captureException(error, stackTrace: stackTrace);
    }
    return true;
  };

  runApp(const HiraalApp());
}

void _reportUnhandledError(Object error, StackTrace stackTrace) {
  log.e('UncaughtZoneError', error: error, stackTrace: stackTrace);
  if (EnvConfig.enableCrashReporting && EnvConfig.sentryDsn.isNotEmpty) {
    Sentry.captureException(error, stackTrace: stackTrace);
  }
}

class HiraalApp extends StatelessWidget {
  const HiraalApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AppProvider()),
        ChangeNotifierProvider(create: (_) => ConnectivityService()),
      ],
      child: const _LifecycleScope(child: _AppRoot()),
    );
  }
}

class _LifecycleScope extends StatefulWidget {
  final Widget child;

  const _LifecycleScope({required this.child});

  @override
  State<_LifecycleScope> createState() => _LifecycleScopeState();
}

class _LifecycleScopeState extends State<_LifecycleScope>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final provider = context.read<AppProvider>();
    if (state == AppLifecycleState.resumed) {
      unawaited(provider.handleAppResumed());
    }
    if (state == AppLifecycleState.inactive ||
        state == AppLifecycleState.hidden ||
        state == AppLifecycleState.paused) {
      unawaited(provider.markUserActivity());
    }
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

class _AppRoot extends StatelessWidget {
  const _AppRoot();

  @override
  Widget build(BuildContext context) {
    // Sync connectivity state into app provider.
    final connectivity = context.watch<ConnectivityService>();
    final provider = context.watch<AppProvider>();
    if (provider.isOnline != connectivity.isOnline) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        provider.setOnlineStatus(connectivity.isOnline);
      });
    }

    return MaterialApp(
      title: 'Hiraal Chronic Care',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: _buildScreen(context, provider),
      routes: {
        '/book-doctor': (_) => const BookDoctorScreen(),
        '/lab-test': (_) => const LabTestScreen(),
        '/medicine-order': (_) => const MedicineOrderScreen(),
        '/contact-care-team': (_) => const ContactCareTeamScreen(),
        '/notifications': (_) => const NotificationScreen(),
        '/health-tips': (_) => const HealthTipsScreen(),
        '/weekly-summary': (_) => const WeeklySummaryScreen(),
        '/offline': (_) => const OfflineScreen(),
        '/sync': (_) => const SyncScreen(),
        '/reminder': (ctx) => ReminderScreen(
              onLogNow: () {
                Provider.of<AppProvider>(ctx, listen: false).setTab(0);
              },
            ),
        '/otp': (ctx) => OtpScreen(
              phoneNumber: '',
              onVerified: (_) {},
              onBack: () => Navigator.of(ctx).pop(),
            ),
        '/error': (_) => const ErrorScreen(),
        '/session-expired': (ctx) => SessionExpiredScreen(
              onLogin: () {
                Provider.of<AppProvider>(ctx, listen: false).logout();
              },
            ),
      },
    );
  }

  Widget _buildScreen(BuildContext context, AppProvider provider) {
    switch (provider.state) {
      case AppState.splash:
        return SplashScreen(
          onGetStarted: () => provider.setState(AppState.register),
        );
      case AppState.register:
        return RegisterScreen(
          onSendCode: (phone) async {
            provider.setPhoneNumber(phone);
            final ok = await provider.requestOtp();
            if (ok) {
              provider.setState(AppState.otp);
            }
          },
          onBack: () => provider.setState(AppState.splash),
        );
      case AppState.otp:
        return OtpScreen(
          phoneNumber: provider.phoneNumber,
          onVerified: (code) async {
            provider.setOtpCode(code);
            final ok = await provider.verifyOtp();
            if (ok) {
              await provider.lookupPatient();
            }
          },
          onBack: () => provider.setState(AppState.register),
        );
      case AppState.success:
        return RegistrationSuccessScreen(
          patient: provider.patient ?? Patient.mock(),
          onContinue: () => provider.setState(AppState.home),
        );
      case AppState.home:
        return const AppShell();
      case AppState.sessionExpired:
        return SessionExpiredScreen(
          onLogin: () => provider.setState(AppState.register),
        );
    }
  }
}
