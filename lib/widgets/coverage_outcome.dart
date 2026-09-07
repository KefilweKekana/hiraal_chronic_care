import 'package:flutter/material.dart';
import '../core/theme/app_colors.dart';
import '../l10n/app_localizations.dart';
import '../models/service_coverage.dart';

/// Full-screen result after a coverage check: FREE confirmation or pay wall.
class CoverageOutcomePage extends StatelessWidget {
  final ServiceCoverage coverage;
  final String title;
  final VoidCallback onContinue;
  final VoidCallback? onPay;

  const CoverageOutcomePage({
    super.key,
    required this.coverage,
    required this.title,
    required this.onContinue,
    this.onPay,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final free = coverage.covered;
    return Scaffold(
      backgroundColor: AppColors.scaffold(context),
      appBar: AppBar(title: Text(title)),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const Spacer(),
            Container(
              width: 88,
              height: 88,
              decoration: BoxDecoration(
                color: free ? AppColors.success : AppColors.warning,
                shape: BoxShape.circle,
              ),
              child: Icon(
                free ? Icons.check : Icons.payments_outlined,
                color: AppColors.white,
                size: 44,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              free ? l10n.includedInPlanFree : l10n.paymentRequiredNotInPlan,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w700,
                color: AppColors.text(context),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              coverage.message,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16, color: AppColors.textMuted(context), height: 1.4),
            ),
            if (!free && coverage.amount > 0) ...[
              const SizedBox(height: 16),
              Text(
                '${coverage.currency} ${coverage.amount.toStringAsFixed(2)}',
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  color: AppColors.primary,
                ),
              ),
            ],
            const Spacer(),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: free ? onContinue : (onPay ?? onContinue),
                child: Text(free ? l10n.confirm : l10n.completePayment),
              ),
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }
}

class BigChoiceButton extends StatelessWidget {
  final String label;
  final String? subtitle;
  final bool selected;
  final bool enabled;
  final VoidCallback? onTap;
  final IconData? icon;

  const BigChoiceButton({
    super.key,
    required this.label,
    this.subtitle,
    this.selected = false,
    this.enabled = true,
    this.onTap,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final fg = enabled
        ? (selected ? AppColors.primary : AppColors.text(context))
        : AppColors.textTertiary;
    return Opacity(
      opacity: enabled ? 1 : 0.45,
      child: Material(
        color: selected
            ? (AppColors.isDark(context) ? AppColors.darkPrimaryLight : AppColors.primaryLight)
            : AppColors.card(context),
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          onTap: enabled ? onTap : null,
          borderRadius: BorderRadius.circular(14),
          child: Container(
            constraints: const BoxConstraints(minHeight: 48, minWidth: 48),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: selected ? AppColors.primary : AppColors.border(context),
                width: selected ? 2 : 1,
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (icon != null) ...[
                  Icon(icon, color: fg, size: 22),
                  const SizedBox(height: 6),
                ],
                Text(
                  label,
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: fg),
                ),
                if (subtitle != null)
                  Text(
                    subtitle!,
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 13, color: fg),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
