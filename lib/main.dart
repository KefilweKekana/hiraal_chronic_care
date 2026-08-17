import 'dart:async';
import 'dart:ui';

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

import 'core/config/env_config.dart';
import 'core/theme/app_theme.dart';
import 'core/network/connectivity_service.dart';
import 'core/utils/app_logger.dart';
import 'l10n/app_localizations.dart';
import 'l10n/fallback_material_localizations.dart';
import 'providers/app_provider.dart';
import 'models/patient.dart';
import 'services/service_locator.dart';
import 'services/background_sync_service.dart';
import 'services/push_notification_service.dart';
import 'services/local_reminder_service.dart';
import 'screens/auth/splash_screen.dart';
import 'screens/auth/register_screen.dart';
import 'screens/auth/signup_screen.dart';
import 'screens/auth/paywall_screen.dart';
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

  // Background sync and push notifications must never block app startup.
  // Firebase isn't configured in every build (no google-services.json), so
  // these calls can throw at launch. Catch failures and log them instead of
  // letting them prevent runApp() and leave the user on a black screen.
  try {
    await BackgroundSyncService.instance.initialize();
    await BackgroundSyncService.instance.registerPeriodicSync();
  } catch (e, st) {
    log.e('Background sync init failed', error: e, stackTrace: st);
  }

  try {
    await Firebase.initializeApp();
    await PushNotificationService.instance.initialize();
  } catch (e, st) {
    log.e('Push notification init failed', error: e, stackTrace: st);
  }

  // Local reminders are offline-only and must also never block startup.
  try {
    await LocalReminderService.instance.init();
    await LocalReminderService.instance.syncFromPrefs();
  } catch (e, st) {
    log.e('Local reminder init failed', error: e, stackTrace: st);
  }

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
      title: 'Hiraal Lifecare',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      locale: provider.locale,
      supportedLocales: AppLocalizations.supportedLocales,
      // Somali is supported by AppLocalizations but not by Flutter's stock
      // Material/Cupertino delegates — use fallbacks so locale='so' does not
      // blank the app. WidgetsLocalizations covers all locales already.
      localizationsDelegates: const [
        AppLocalizations.delegate,
        FallbackMaterialLocalizationsDelegate(),
        GlobalWidgetsLocalizations.delegate,
        FallbackCupertinoLocalizationsDelegate(),
      ],
      // Apply the large-text accessibility preference app-wide.
      builder: (context, child) {
        final largeText = context.watch<AppProvider>().largeText;
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(
            textScaler: TextScaler.linear(largeText ? 1.2 : 1.0),
          ),
          child: child ?? const SizedBox.shrink(),
        );
      },
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
        '/error': (_) => const ErrorScreen(),
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
          onSendCode: (phone, channel) async {
            provider.setPhoneNumber(phone);
            final ok = await provider.requestOtp(channel: channel);
            if (ok) {
              provider.setState(AppState.otp);
            }
          },
          onCreateAccount: () => provider.setState(AppState.signup),
          onBack: () => provider.setState(AppState.splash),
        );
      case AppState.signup:
        return SignUpScreen(
          onCreateAccount: (fullName, phone, sex, dob, email) async {
            final ok = await provider.beginSignup(
              fullName: fullName, phone: phone, sex: sex, dob: dob, email: email,
            );
            if (ok) provider.setState(AppState.otp);
          },
          onBack: () => provider.setState(AppState.register),
        );
      case AppState.otp:
        return OtpScreen(
          phoneNumber: provider.phoneNumber,
          delivery: provider.otpDelivery,
          channel: provider.otpRequestedChannel,
          onVerified: (code) async {
            provider.setOtpCode(code);
            // Sign-up flow: verify the code and create the account in one call.
            if (provider.isSignupFlow) {
              final ok = await provider.completeSignup();
              if (!ok) {
                return provider.errorMessage ?? 'Could not create your account';
              }
              return null;
            }
            // Sign-in flow: single backend verification (the OTP screen no
            // longer verifies separately, which previously consumed the code
            // twice), then load the patient.
            final ok = await provider.verifyOtp();
            if (!ok) {
              return provider.errorMessage ?? 'Invalid or expired code';
            }
            final found = await provider.lookupPatient();
            if (!found) {
              return provider.errorMessage ??
                  'No patient record found for this number';
            }
            return null;
          },
          onBack: () => provider.setState(
              provider.isSignupFlow ? AppState.signup : AppState.register),
        );
      case AppState.success:
        return RegistrationSuccessScreen(
          patient: provider.patient ?? Patient.mock(),
          onContinue: () => provider.setState(AppState.home),
        );
      case AppState.paywall:
        return const PaywallScreen();
      case AppState.home:
        return const AppShell();
      case AppState.sessionExpired:
        return SessionExpiredScreen(
          onLogin: () => provider.setState(AppState.register),
          onBack: () => provider.setState(AppState.splash),
        );
    }
  }
}
