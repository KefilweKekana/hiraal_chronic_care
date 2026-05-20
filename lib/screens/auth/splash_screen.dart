import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/constants/app_constants.dart';
import '../../providers/app_provider.dart';
import '../../widgets/shared_widgets.dart';

class SplashScreen extends StatefulWidget {
  final VoidCallback onGetStarted;

  const SplashScreen({super.key, required this.onGetStarted});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  bool _checkingSession = true;

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
      }
    }
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
          : _buildWelcomeView(),
    );
  }

  Widget _buildLoadingView() {
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
                child: const Text(
                  'Hiraal Chronic Care',
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
                  'Better Monitoring. Better Health.',
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
    return Scaffold(
      key: const ValueKey('welcome'),
      backgroundColor: AppColors.white,
      body: SafeArea(
        child: FadeTransition(
          opacity: _welcomeFade,
          child: SlideTransition(
            position: _welcomeSlide,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Column(
                children: [
                  const Spacer(flex: 2),
                  const HiraalLogo(size: 80),
                  const SizedBox(height: 32),
                  const Text(
                    'Better Monitoring.\nBetter Health.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                      height: 1.3,
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    AppConstants.appSubtitle,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      color: AppColors.textSecondary,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 40),
                  SizedBox(
                    height: 40,
                    child: CustomPaint(
                      size: const Size(200, 40),
                      painter: _HeartbeatPainter(),
                    ),
                  ),
                  const SizedBox(height: 40),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _TrustBadge(
                        icon: Icons.verified_user_outlined,
                        label: 'Your data is\nsafe & secure',
                        color: AppColors.success,
                      ),
                      const SizedBox(width: 40),
                      _TrustBadge(
                        icon: Icons.people_outline,
                        label: 'Trusted by clinics\nthat care',
                        color: AppColors.primary,
                      ),
                    ],
                  ),
                  const Spacer(flex: 2),
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: widget.onGetStarted,
                      child: const Text('Get Started'),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextButton(
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: (_) => AlertDialog(
                          title: const Text('Contact Support'),
                          content: const Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Email: support@hiraalhealth.so'),
                              SizedBox(height: 8),
                              Text('Phone: +252 61 000 0000'),
                              SizedBox(height: 8),
                              Text('Hours: 8:00 AM - 8:00 PM (EAT)'),
                            ],
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context),
                              child: const Text('Close'),
                            ),
                          ],
                        ),
                      );
                    },
                    child: const Text(
                      'Need help? Contact support',
                      style: TextStyle(
                        fontSize: 14,
                        color: AppColors.textTertiary,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _TrustBadge extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _TrustBadge({
    required this.icon,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: color, size: 22),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 12,
            color: AppColors.textSecondary,
            height: 1.3,
          ),
        ),
      ],
    );
  }
}

class _HeartbeatPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.primary.withValues(alpha: 0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    final path = Path();
    final midY = size.height / 2;
    path.moveTo(0, midY);
    path.lineTo(size.width * 0.3, midY);
    path.lineTo(size.width * 0.35, midY - 15);
    path.lineTo(size.width * 0.4, midY + 15);
    path.lineTo(size.width * 0.45, midY - 20);
    path.lineTo(size.width * 0.5, midY + 10);
    path.lineTo(size.width * 0.55, midY);
    path.lineTo(size.width, midY);
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
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
