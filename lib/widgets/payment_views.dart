import 'package:flutter/material.dart';
import '../core/theme/app_colors.dart';

/// Shared "waiting for the customer to approve on their phone" view, used by
/// the order-payment and subscription-payment screens. Capitec-style: radar
/// pulse around a phone icon, the amount, a live countdown, and the approval
/// steps. The host screen owns the timers/animation and passes them in.
class PaymentWaitingView extends StatelessWidget {
  /// Drives the radar pulse (start on pay, stop on success/failure/cancel).
  final Animation<double> pulse;

  /// Formatted amount, e.g. `$16.00`.
  final String amountText;

  /// Display name of the chosen wallet, e.g. `WaafiPay`.
  final String methodLabel;

  /// The wallet number the request was sent to.
  final String phone;

  /// Countdown seconds remaining; at 0 the pill swaps to [expiredMessage].
  final int secondsLeft;

  /// Shown once the countdown expires (the "taking longer" reassurance).
  final String expiredMessage;

  final bool busy;
  final VoidCallback onCheckNow;
  final VoidCallback onCancel;

  const PaymentWaitingView({
    super.key,
    required this.pulse,
    required this.amountText,
    required this.methodLabel,
    required this.phone,
    required this.secondsLeft,
    required this.expiredMessage,
    required this.busy,
    required this.onCheckNow,
    required this.onCancel,
  });

  String get _mmss =>
      '${secondsLeft ~/ 60}:${(secondsLeft % 60).toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          const Spacer(),
          _PulseRings(animation: pulse),
          const SizedBox(height: 32),
          const Text(
            'Waiting for payment',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
          ),
          const SizedBox(height: 10),
          Text.rich(
            TextSpan(
              style: const TextStyle(fontSize: 15, color: AppColors.textSecondary, height: 1.4),
              children: [
                const TextSpan(text: 'Approve the payment of '),
                TextSpan(
                  text: amountText,
                  style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                ),
                TextSpan(text: ' in $methodLabel'),
              ],
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 6),
          Text(
            'Request sent to $phone',
            style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 18),
          if (secondsLeft > 0)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.inputBackground,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.inputBorder),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.timer_outlined, size: 16, color: AppColors.textSecondary),
                  const SizedBox(width: 6),
                  Text('Expires in $_mmss',
                      style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
                ],
              ),
            )
          else
            Text(
              expiredMessage,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 13, color: AppColors.textSecondary, height: 1.4),
            ),
          const SizedBox(height: 28),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.inputBorder),
            ),
            child: Column(
              children: [
                _step('1', 'Open $methodLabel on your phone'),
                const SizedBox(height: 10),
                _step('2', 'Enter your PIN to approve the payment'),
                const SizedBox(height: 10),
                _step('3', 'This screen confirms automatically'),
              ],
            ),
          ),
          const Spacer(),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: busy ? null : onCheckNow,
              child: busy
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.white),
                    )
                  : const Text("I've paid — check now"),
            ),
          ),
          const SizedBox(height: 8),
          TextButton(
            onPressed: onCancel,
            child: const Text('Cancel and try again'),
          ),
        ],
      ),
    );
  }

  Widget _step(String n, String text) => Row(
        children: [
          Container(
            width: 22,
            height: 22,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Text(
              n,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.primary),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(text, style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
          ),
        ],
      );
}

/// Outcome screens for the payment flow: a "paid" success view and a friendly
/// "declined" view that translates raw gateway errors into guidance (the raw
/// reason is kept as small print for support). Shared by the order- and
/// subscription-payment screens.
class PaymentResultView extends StatelessWidget {
  final bool success;
  final String? subtitle;
  final String? failureReason;
  final String primaryLabel;
  final VoidCallback onPrimary;
  final String? secondaryLabel;
  final VoidCallback? onSecondary;

  const PaymentResultView._({
    required this.success,
    this.subtitle,
    this.failureReason,
    required this.primaryLabel,
    required this.onPrimary,
    this.secondaryLabel,
    this.onSecondary,
  });

  /// The "paid" screen.
  factory PaymentResultView.success({
    String? subtitle,
    String doneLabel = 'Done',
    required VoidCallback onDone,
  }) =>
      PaymentResultView._(
        success: true,
        subtitle: subtitle,
        primaryLabel: doneLabel,
        onPrimary: onDone,
      );

  /// The "declined" screen. [reason] is the raw server/gateway message — it is
  /// mapped to friendly copy and shown verbatim only as small print.
  factory PaymentResultView.failure({
    String? reason,
    required VoidCallback onTryAgain,
    VoidCallback? onBack,
  }) =>
      PaymentResultView._(
        success: false,
        failureReason: reason,
        primaryLabel: 'Try again',
        onPrimary: onTryAgain,
        secondaryLabel: onBack != null ? 'Back' : null,
        onSecondary: onBack,
      );

  /// Translate raw gateway/server errors into a title a patient understands.
  static String _friendlyFailureTitle(String? reason) {
    final r = (reason ?? '').toLowerCase();
    if (r.contains('user_rejected') ||
        r.contains('rejected') ||
        r.contains('declined') ||
        r.contains('cancelled')) {
      return 'Payment declined';
    }
    if (r.contains('insufficient') || r.contains('balance')) {
      return 'Not enough balance';
    }
    if (r.contains('timeout') || r.contains('timed out') || r.contains('taking longer')) {
      return 'No response from your wallet';
    }
    if (r.contains('pin')) {
      return 'Wrong PIN';
    }
    if (r.contains('invalid') || r.contains('number') || r.contains('phone')) {
      return 'Check the wallet number';
    }
    return 'Payment not completed';
  }

  @override
  Widget build(BuildContext context) {
    final title = success ? 'Payment successful' : _friendlyFailureTitle(failureReason);
    final message = subtitle ?? 'Thank you!';
    final color = success ? AppColors.success : AppColors.error;

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          const Spacer(),
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0.5, end: 1),
            duration: const Duration(milliseconds: 350),
            curve: Curves.easeOutBack,
            builder: (context, v, child) => Transform.scale(scale: v, child: child),
            child: Container(
              width: 84,
              height: 84,
              decoration: BoxDecoration(
                color: success ? AppColors.success : AppColors.error.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                success ? Icons.check : Icons.close,
                color: success ? AppColors.white : AppColors.error,
                size: 44,
              ),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            title,
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: color),
          ),
          if (success) ...[
            const SizedBox(height: 10),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 15, color: AppColors.textSecondary, height: 1.5),
            ),
          ],
          const Spacer(),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: onPrimary,
              child: Text(primaryLabel),
            ),
          ),
          if (onSecondary != null) ...[
            const SizedBox(height: 8),
            TextButton(
              onPressed: onSecondary,
              child: Text(secondaryLabel ?? 'Back'),
            ),
          ],
        ],
      ),
    );
  }
}

/// Capitec-style "radar" pulse: three concentric rings expanding and fading
/// around a phone icon while the customer approves the payment on their phone.
class _PulseRings extends StatelessWidget {
  final Animation<double> animation;

  const _PulseRings({required this.animation});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: animation,
      builder: (context, child) => SizedBox(
        width: 180,
        height: 180,
        child: Stack(
          alignment: Alignment.center,
          children: [
            for (var i = 0; i < 3; i++) _ring(i),
            child!,
          ],
        ),
      ),
      child: Container(
        width: 84,
        height: 84,
        decoration: BoxDecoration(
          color: AppColors.primary.withValues(alpha: 0.12),
          shape: BoxShape.circle,
        ),
        child: const Icon(Icons.phone_iphone, size: 40, color: AppColors.primary),
      ),
    );
  }

  Widget _ring(int i) {
    // Stagger the three rings evenly across the animation cycle.
    final t = (animation.value + i / 3) % 1.0;
    return Transform.scale(
      scale: 0.6 + 0.9 * t,
      child: Container(
        width: 120,
        height: 120,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(
            color: AppColors.primary.withValues(alpha: (1 - t) * 0.5),
            width: 2,
          ),
        ),
      ),
    );
  }
}
