import 'dart:async';

import 'package:flutter/material.dart';
import 'package:pin_code_fields/pin_code_fields.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/constants/app_constants.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/otp_wait.dart';
import '../../core/utils/result.dart';
import '../../l10n/app_localizations.dart';
import '../../providers/app_provider.dart';
import '../../providers/health_pin_controller.dart';
import '../../services/service_locator.dart';
import '../../widgets/shared_widgets.dart';
import 'health_pin_unlock.dart';

class SplashScreen extends StatefulWidget {
  final VoidCallback onGetStarted;
  /// Optional "For My Family" path. Falls back to [onGetStarted] in tests.
  final VoidCallback? onForFamily;

  const SplashScreen({super.key, required this.onGetStarted, this.onForFamily});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  bool _checkingSession = true;
  bool _needsUnlock = false;
  String _patientId = '';

  final _pinController = TextEditingController();
  String _pin = '';
  bool _busy = false;
  String? _pinError;
  int _lockSeconds = 0;
  Timer? _lockTicker;

  // Branded loading animations
  late AnimationController _entranceController;
  late Animation<double> _logoScale;
  late Animation<double> _logoFade;
  late Animation<double> _textFade;

  late AnimationController _pulseController;
  late Animation<double> _pulseScale;
  late Animation<double> _pulseOpacity;

  late AnimationController _heartbeatController;
  late Animation<double> _heartbeatProgress;

  // Welcome screen entrance
  late AnimationController _welcomeController;
  late Animation<double> _welcomeFade;
  late Animation<Offset> _welcomeSlide;

  @override
  void initState() {
    super.initState();

    _entranceController = AnimationController(
      duration: const Duration(milliseconds: 900),
      vsync: this,
    );
    _logoScale = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(
        parent: _entranceController,
        curve: const Interval(0.0, 0.75, curve: Curves.elasticOut),
      ),
    );
    _logoFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _entranceController,
        curve: const Interval(0.0, 0.5, curve: Curves.easeOut),
      ),
    );
    _textFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _entranceController,
        curve: const Interval(0.45, 1.0, curve: Curves.easeOut),
      ),
    );

    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1600),
      vsync: this,
    )..repeat();
    _pulseScale = Tween<double>(begin: 1.0, end: 1.6).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeOut),
    );
    _pulseOpacity = Tween<double>(begin: 0.5, end: 0.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeOut),
    );

    _heartbeatController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    )..repeat();
    _heartbeatProgress = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _heartbeatController, curve: Curves.linear),
    );

    _welcomeController = AnimationController(
      duration: const Duration(milliseconds: 550),
      vsync: this,
    );
    _welcomeFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _welcomeController, curve: Curves.easeOut),
    );
    _welcomeSlide = Tween<Offset>(
      begin: const Offset(0, 0.06),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _welcomeController, curve: Curves.easeOut),
    );

    _entranceController.forward();
    _tryRestore();
  }

  @override
  void dispose() {
    _lockTicker?.cancel();
    _pinController.dispose();
    _entranceController.dispose();
    _pulseController.dispose();
    _heartbeatController.dispose();
    _welcomeController.dispose();
    super.dispose();
  }

  Future<void> _tryRestore() async {
    final provider = context.read<AppProvider>();

    try {
      // Returning patient: unlock with health PIN (not fingerprint).
      final hasSession = await provider.hasPersistedSession();
      if (hasSession) {
        final patient = await provider.peekPersistedPatient();
        final authOk = await provider.attachPersistedApiAuth();
        final id = patient?.id ?? '';
        if (authOk && id.isNotEmpty && mounted) {
          // Clear stale biometric-as-login preference from older installs.
          final prefs = await SharedPreferences.getInstance();
          await prefs.setBool('pref_biometric', false);
          setState(() {
            _checkingSession = false;
            _needsUnlock = true;
            _patientId = id;
          });
          return;
        }
      }

      final restored = await provider.tryRestoreSession();
      if (mounted && !restored) {
        await Future.delayed(
          Duration(
            milliseconds:
                (800 - (_entranceController.value * 900).toInt()).clamp(0, 800),
          ),
        );
        if (mounted) {
          setState(() => _checkingSession = false);
          _welcomeController.forward();
          await _maybeRunDemoDeepLink(provider);
        }
      } else if (mounted && restored) {
        await _maybeRunDemoDeepLink(provider);
      }
    } catch (_) {
      if (mounted) {
        setState(() => _checkingSession = false);
        _welcomeController.forward();
        await _maybeRunDemoDeepLink(provider);
      }
    }
  }

  Future<void> _maybeRunDemoDeepLink(AppProvider provider) async {
    final demo = Uri.base.queryParameters['demo'];
    if (demo == null || demo.isEmpty) return;
    await Future.delayed(const Duration(milliseconds: 400));
    if (!mounted) return;
    await provider.demoGo(demo);
  }

  void _startLock(int seconds) {
    _lockTicker?.cancel();
    setState(() => _lockSeconds = seconds);
    _lockTicker = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) {
        t.cancel();
        return;
      }
      if (_lockSeconds <= 1) {
        t.cancel();
        setState(() => _lockSeconds = 0);
      } else {
        setState(() => _lockSeconds--);
      }
    });
  }

  Future<void> _unlockWithPin() async {
    final l10n = AppLocalizations.of(context);
    if (_pin.length != AppConstants.healthPinLength || _busy || _lockSeconds > 0) {
      return;
    }
    setState(() {
      _busy = true;
      _pinError = null;
    });
    final result = await ServiceLocator.instance.healthPin.verifyHealthPin(
      _pin,
      patient: _patientId,
    );
    if (!mounted) return;
    setState(() => _busy = false);
    switch (result) {
      case Success(data: final data):
        if (data.ok) {
          context.read<HealthPinController>().markUnlocked(_patientId);
          final restored = await context.read<AppProvider>().tryRestoreSession();
          if (!restored && mounted) {
            setState(() {
              _needsUnlock = false;
              _pin = '';
              _pinController.clear();
            });
            _welcomeController.forward();
          }
          return;
        }
        if (data.locked && data.retryAfter > 0) {
          _startLock(data.retryAfter);
        }
        setState(() {
          _pinError = data.message ?? l10n.healthPinWrong;
          _pin = '';
          _pinController.clear();
        });
      case Failure(message: final msg):
        final wait = parseOtpRetryAfterSeconds(msg);
        if (wait != null) _startLock(wait);
        setState(() {
          _pinError = msg;
          _pin = '';
          _pinController.clear();
        });
    }
  }

  Future<void> _forgotPin() async {
    final ok = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => ForgotHealthPinScreen(patientId: _patientId),
      ),
    );
    if (ok == true && mounted) {
      context.read<HealthPinController>().markUnlocked(_patientId);
      await context.read<AppProvider>().tryRestoreSession();
    }
  }

  void _signInAnotherWay() {
    setState(() {
      _needsUnlock = false;
      _pin = '';
      _pinError = null;
      _pinController.clear();
    });
    _welcomeController.forward();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 350),
      transitionBuilder: (child, animation) => FadeTransition(
        opacity: animation,
        child: child,
      ),
      child: _checkingSession
          ? _buildLoadingView()
          : (_needsUnlock ? _buildUnlockView() : _buildWelcomeView()),
    );
  }

  Widget _buildUnlockView() {
    final l10n = AppLocalizations.of(context);
    final palette = AppColors.of(context);
    final locked = _lockSeconds > 0;
    return Scaffold(
      key: const ValueKey('unlock'),
      backgroundColor: palette.scaffold,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const HiraalLogo(size: 64),
              const SizedBox(height: 32),
              Container(
                width: 88,
                height: 88,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.lock_outline, size: 44, color: AppColors.primary),
              ),
              const SizedBox(height: 20),
              Text(
                l10n.welcomeBack,
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: palette.text,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                l10n.unlockWithHealthPin,
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14, color: palette.textMuted, height: 1.4),
              ),
              const SizedBox(height: 28),
              PinCodeTextField(
                appContext: context,
                controller: _pinController,
                length: AppConstants.healthPinLength,
                obscureText: true,
                enabled: !locked && !_busy,
                animationType: AnimationType.fade,
                keyboardType: TextInputType.number,
                autoFocus: true,
                textStyle: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: palette.text,
                ),
                pinTheme: PinTheme(
                  shape: PinCodeFieldShape.box,
                  borderRadius: BorderRadius.circular(12),
                  fieldHeight: 56,
                  fieldWidth: 56,
                  activeFillColor: palette.card,
                  inactiveFillColor: palette.inputFill,
                  selectedFillColor: palette.primarySoft,
                  activeColor: AppColors.primary,
                  inactiveColor: palette.inputBorder,
                  selectedColor: AppColors.primary,
                  borderWidth: 1.5,
                ),
                enableActiveFill: true,
                onChanged: (value) => setState(() => _pin = value),
                onCompleted: (_) => _unlockWithPin(),
              ),
              if (_pinError != null) ...[
                const SizedBox(height: 8),
                Text(
                  _pinError!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: AppColors.error, fontSize: 13),
                ),
              ],
              if (locked) ...[
                const SizedBox(height: 8),
                Text(
                  l10n.healthPinLocked(formatOtpCountdown(_lockSeconds)),
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: AppColors.warning, fontSize: 13),
                ),
              ],
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _busy ||
                          locked ||
                          _pin.length != AppConstants.healthPinLength
                      ? null
                      : _unlockWithPin,
                  child: _busy
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            color: Colors.white,
                          ),
                        )
                      : Text(l10n.logInWithHealthPin),
                ),
              ),
              TextButton(
                onPressed: _busy ? null : _forgotPin,
                child: Text(l10n.healthPinForgot),
              ),
              TextButton(
                onPressed: _signInAnotherWay,
                child: Text(l10n.signInAnotherWay),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingView() {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      key: const ValueKey('loading'),
      backgroundColor: AppColors.primary,
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(flex: 3),
              AnimatedBuilder(
                animation: Listenable.merge(
                    [_pulseController, _entranceController]),
                builder: (context, _) {
                  return FadeTransition(
                    opacity: _logoFade,
                    child: ScaleTransition(
                      scale: _logoScale,
                      child: SizedBox(
                        width: 140,
                        height: 140,
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            Transform.scale(
                              scale: _pulseScale.value,
                              child: Opacity(
                                opacity: _pulseOpacity.value,
                                child: Container(
                                  width: 120,
                                  height: 120,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: Colors.white,
                                      width: 2.5,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            Container(
                              width: 100,
                              height: 100,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.18),
                                    blurRadius: 24,
                                    offset: const Offset(0, 8),
                                  ),
                                ],
                              ),
                              child: Center(
                                child: Image.asset(
                                  'assets/icon/app_icon.png',
                                  width: 68,
                                  height: 68,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 36),
              FadeTransition(
                opacity: _textFade,
                child: Text(
                  l10n.appNameFull,
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                    letterSpacing: 0.3,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              FadeTransition(
                opacity: _textFade,
                child: Text(
                  l10n.appTagline,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.white.withValues(alpha: 0.8),
                    letterSpacing: 0.2,
                  ),
                ),
              ),
              const Spacer(flex: 3),
              FadeTransition(
                opacity: _textFade,
                child: SizedBox(
                  height: 48,
                  width: 220,
                  child: AnimatedBuilder(
                    animation: _heartbeatProgress,
                    builder: (context, _) => CustomPaint(
                      painter: _AnimatedHeartbeatPainter(
                        progress: _heartbeatProgress.value,
                        color: Colors.white.withValues(alpha: 0.6),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildWelcomeView() {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      key: const ValueKey('welcome'),
      backgroundColor: AppColors.of(context).scaffold,
      body: SafeArea(
        child: FadeTransition(
          opacity: _welcomeFade,
          child: SlideTransition(
            position: _welcomeSlide,
            child: LayoutBuilder(
              builder: (context, constraints) {
                return SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(minHeight: constraints.maxHeight),
                    child: Column(
                      children: [
                  const SizedBox(height: 40),
                  const HiraalLogo(size: 80),
                  const SizedBox(height: 32),
                  Text(
                    l10n.welcomeHello,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w700,
                      color: AppColors.of(context).text,
                      height: 1.2,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    l10n.roleChooserTitle,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: AppColors.of(context).text,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    l10n.welcomeContinueHint,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 15,
                      color: AppColors.of(context).textMuted,
                      height: 1.45,
                    ),
                  ),
                  const SizedBox(height: 28),
                  _WelcomePathCard(
                    icon: Icons.person_outline,
                    iconColor: AppColors.primary,
                    title: l10n.roleChooserPatientTitle,
                    subtitle: l10n.roleChooserPatientHint,
                    onTap: widget.onGetStarted,
                  ),
                  const SizedBox(height: 12),
                  _WelcomePathCard(
                    icon: Icons.groups_outlined,
                    iconColor: AppColors.info,
                    title: l10n.roleChooserCaregiverTitle,
                    subtitle: l10n.roleChooserCaregiverHint,
                    onTap: widget.onForFamily ?? widget.onGetStarted,
                  ),
                  const SizedBox(height: 16),
                  TextButton(
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: (dialogContext) => AlertDialog(
                          title: Text(l10n.contactSupportTitle),
                          content: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(l10n.supportPhoneLine(
                                AppConstants.supportPhonePrimary,
                                AppConstants.supportPhoneSecondary,
                              )),
                              const SizedBox(height: 8),
                              Text(l10n.supportShortCodeLine(
                                AppConstants.supportShortCode,
                              )),
                              const SizedBox(height: 8),
                              Text(l10n.supportEmailLine(
                                AppConstants.supportEmail,
                              )),
                              const SizedBox(height: 8),
                              Text(l10n.supportHoursLine(
                                AppConstants.supportHours,
                              )),
                            ],
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(dialogContext),
                              child: Text(l10n.close),
                            ),
                          ],
                        ),
                      );
                    },
                    child: Text(
                      l10n.needHelpContactSupport,
                      style: TextStyle(
                        fontSize: 14,
                        color: AppColors.of(context).textFaint,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

class _WelcomePathCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _WelcomePathCard({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.of(context).card,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.of(context).border),
          ),
          child: Row(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(icon, color: iconColor, size: 28),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 19,
                        fontWeight: FontWeight.w700,
                        color: AppColors.of(context).text,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 14,
                        height: 1.35,
                        color: AppColors.of(context).textMuted,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: iconColor, size: 28),
            ],
          ),
        ),
      ),
    );
  }
}

class _AnimatedHeartbeatPainter extends CustomPainter {
  final double progress;
  final Color color;

  _AnimatedHeartbeatPainter({required this.progress, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final midY = size.height / 2;
    final waypoints = [
      Offset(0, midY),
      Offset(size.width * 0.28, midY),
      Offset(size.width * 0.33, midY - 16),
      Offset(size.width * 0.38, midY + 16),
      Offset(size.width * 0.43, midY - 22),
      Offset(size.width * 0.50, midY + 12),
      Offset(size.width * 0.56, midY),
      Offset(size.width, midY),
    ];

    final totalLength = _pathLength(waypoints);
    final targetLength = progress * totalLength;

    final path = Path();
    path.moveTo(waypoints[0].dx, waypoints[0].dy);

    double drawn = 0;
    Offset? tipPoint;

    for (int i = 1; i < waypoints.length; i++) {
      final segLen = (waypoints[i] - waypoints[i - 1]).distance;
      if (drawn + segLen <= targetLength) {
        path.lineTo(waypoints[i].dx, waypoints[i].dy);
        drawn += segLen;
        tipPoint = waypoints[i];
      } else {
        final remaining = targetLength - drawn;
        final t = remaining / segLen;
        final partial = Offset(
          waypoints[i - 1].dx + (waypoints[i].dx - waypoints[i - 1].dx) * t,
          waypoints[i - 1].dy + (waypoints[i].dy - waypoints[i - 1].dy) * t,
        );
        path.lineTo(partial.dx, partial.dy);
        tipPoint = partial;
        break;
      }
    }

    canvas.drawPath(path, paint);

    if (tipPoint != null) {
      final glowPaint = Paint()
        ..color = color.withValues(alpha: 0.35)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);
      canvas.drawCircle(tipPoint, 7, glowPaint);
      canvas.drawCircle(tipPoint, 4, Paint()..color = color);
    }
  }

  double _pathLength(List<Offset> points) {
    double len = 0;
    for (int i = 1; i < points.length; i++) {
      len += (points[i] - points[i - 1]).distance;
    }
    return len;
  }

  @override
  bool shouldRepaint(_AnimatedHeartbeatPainter old) =>
      old.progress != progress;
}
