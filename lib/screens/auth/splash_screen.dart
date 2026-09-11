import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/theme/app_colors.dart';
import '../../core/constants/app_constants.dart';
import '../../l10n/app_localizations.dart';
import '../../providers/app_provider.dart';
import '../../services/biometric_service.dart';
import '../../widgets/shared_widgets.dart';

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
  // Adaptive biometric labelling (Face ID vs Fingerprint).
  String _bioLabel = 'Fingerprint';
  bool _bioIsFace = false;

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

    // --- Logo entrance: scale from 0.5 + fade in ---
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

    // --- Pulse ring: repeating expand + fade ---
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

    // --- Heartbeat line drawing animation ---
    _heartbeatController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    )..repeat();
    _heartbeatProgress = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _heartbeatController, curve: Curves.linear),
    );

    // --- Welcome screen slide+fade in ---
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
    _entranceController.dispose();
    _pulseController.dispose();
    _heartbeatController.dispose();
    _welcomeController.dispose();
    super.dispose();
  }

  Future<void> _tryRestore() async {
    final provider = context.read<AppProvider>();

    try {
      // Returning user with biometric login enabled: show the dedicated
      // biometric login screen (clear "Log in with Fingerprint" option) and
      // auto-offer the prompt once. The button stays available if cancelled.
      final hasSession = await provider.hasPersistedSession();
      if (hasSession && await _biometricEnabled()) {
        // Label the unlock screen for the device's actual biometric.
        final label = await BiometricService.instance.biometricLabel();
        final isFace = await BiometricService.instance.hasFaceBiometric();
        if (mounted) {
          setState(() {
            _checkingSession = false;
            _needsUnlock = true;
            _bioLabel = label;
            _bioIsFace = isFace;
          });
          unawaited(_unlock());
        }
        return;
      }

      final restored = await provider.tryRestoreSession();
      if (mounted && !restored) {
        // Ensure entrance has played for at least 800ms before switching
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
      // Session restore failed (e.g. corrupt local DB): fall back to the
      // welcome flow instead of hanging on the splash screen forever.
      if (mounted) {
        setState(() => _checkingSession = false);
        _welcomeController.forward();
        await _maybeRunDemoDeepLink(provider);
      }
    }
  }

  /// Mock demo capture: `http://host/?demo=patient|family|otp|login|role|support`
  Future<void> _maybeRunDemoDeepLink(AppProvider provider) async {
    final demo = Uri.base.queryParameters['demo'];
    if (demo == null || demo.isEmpty) return;
    await Future.delayed(const Duration(milliseconds: 400));
    if (!mounted) return;
    await provider.demoGo(demo);
  }

  Future<bool> _biometricEnabled() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (!(prefs.getBool('pref_biometric') ?? false)) return false;
      return await BiometricService.instance.isDeviceSupported;
    } catch (_) {
      return false;
    }
  }

  /// Retry the biometric prompt from the unlock screen.
  Future<void> _unlock() async {
    final ok = await BiometricService.instance.authenticate();
    if (!ok || !mounted) return;
    final restored = await context.read<AppProvider>().tryRestoreSession();
    if (!restored && mounted) {
      setState(() => _needsUnlock = false);
      _welcomeController.forward();
    }
  }

  /// Skip biometric and go to the normal welcome/login flow.
  void _signInAnotherWay() {
    setState(() => _needsUnlock = false);
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
    return Scaffold(
      key: const ValueKey('unlock'),
      backgroundColor: AppColors.of(context).scaffold,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const HiraalLogo(size: 64),
              const SizedBox(height: 40),
              Container(
                width: 96,
                height: 96,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(_bioIsFace ? Icons.face : Icons.fingerprint,
                    size: 56, color: AppColors.primary),
              ),
              const SizedBox(height: 24),
              Text(
                l10n.welcomeBack,
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: AppColors.of(context).text,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                l10n.unlockWithBio(_bioLabel),
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14, color: AppColors.of(context).textMuted),
              ),
              const SizedBox(height: 40),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton.icon(
                  onPressed: _unlock,
                  icon: Icon(_bioIsFace ? Icons.face : Icons.fingerprint),
                  label: Text(l10n.logInWithBio(_bioLabel)),
                ),
              ),
              const SizedBox(height: 12),
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
              // Pulsing ring + icon
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
                            // Outer pulse ring
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
                            // Icon container
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
              // App name
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
              // Animated heartbeat line
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

/// Animates a heartbeat line that draws itself from left to right, then
/// shows a trailing glow dot moving across the drawn portion.
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

    // Define heartbeat waypoints as fractions of width
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

    // Draw only the portion up to `progress`
    final totalLength = _pathLength(waypoints);
    final targetLength = progress * totalLength;

    final path = Path();
    path.moveTo(waypoints[0].dx, waypoints[0].dy);

    double drawn = 0;
    Offset? tipPoint;

    for (int i = 1; i < waypoints.length; i++) {
      final segLen =
          (waypoints[i] - waypoints[i - 1]).distance;
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

    // Draw glowing tip dot
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
