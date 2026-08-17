import 'dart:async';

import 'package:flutter/material.dart';

import '../../core/constants/app_constants.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/result.dart';
import '../../l10n/app_localizations.dart';
import '../../models/caregiver_link.dart';
import '../../models/subscription.dart';
import '../../services/payment_service.dart';
import '../../services/service_locator.dart';

class SponsorPaymentScreen extends StatefulWidget {
  final SponsorPatientMatch match;
  final SubscriptionPlan plan;
  final PaymentMethodOption method;
  final String phone;

  const SponsorPaymentScreen({
    super.key,
    required this.match,
    required this.plan,
    required this.method,
    required this.phone,
  });

  @override
  State<SponsorPaymentScreen> createState() => _SponsorPaymentScreenState();
}

enum _Stage { starting, waiting, success, failed }

class _SponsorPaymentScreenState extends State<SponsorPaymentScreen> {
  _Stage _stage = _Stage.starting;
  String? _transaction;
  String? _message;
  Timer? _pollTimer;
  int _polls = 0;
  bool _busy = true;

  @override
  void initState() {
    super.initState();
    _startPayment();
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    super.dispose();
  }

  Future<void> _startPayment() async {
    final result = await ServiceLocator.instance.caregivers.sponsorPatientSubscription(
      patient: widget.match.patient,
      plan: widget.plan.name,
      provider: widget.method.provider,
      method: widget.method.method,
      phone: widget.phone,
      familyMember: widget.match.familyMemberName,
    );
    if (!mounted) return;
    switch (result) {
      case Success(data: final txn):
        setState(() {
          _transaction = txn;
          _stage = _Stage.waiting;
          _busy = false;
        });
        _poll();
      case Failure(message: final message):
        setState(() {
          _stage = _Stage.failed;
          _message = message;
          _busy = false;
        });
    }
  }

  void _poll() {
    _pollTimer?.cancel();
    _pollTimer = Timer.periodic(const Duration(seconds: 3), (_) async {
      final txn = _transaction;
      if (txn == null) return;
      _polls++;
      final result = await ServiceLocator.instance.caregivers.checkSponsorPayment(txn);
      if (!mounted) return;
      if (result case Success(data: final status)) {
        if (status == 'Completed') {
          _pollTimer?.cancel();
          setState(() => _stage = _Stage.success);
        } else if (status == 'Failed') {
          _pollTimer?.cancel();
          setState(() {
            _stage = _Stage.failed;
            _message = AppLocalizations.of(context).sponsorshipPaymentFailed;
          });
        }
      }
      if (_polls >= 80) {
        _pollTimer?.cancel();
        if (mounted) {
          setState(() {
            _message = AppLocalizations.of(context).paymentStillProcessing;
          });
        }
      }
    });
  }

  Future<void> _checkNow() async {
    final txn = _transaction;
    if (txn == null) return;
    setState(() => _busy = true);
    final result = await ServiceLocator.instance.caregivers.checkSponsorPayment(txn);
    if (!mounted) return;
    setState(() => _busy = false);
    switch (result) {
      case Success(data: final status):
        if (status == 'Completed') {
          _pollTimer?.cancel();
          setState(() => _stage = _Stage.success);
        } else if (status == 'Failed') {
          _pollTimer?.cancel();
          setState(() {
            _stage = _Stage.failed;
            _message = AppLocalizations.of(context).sponsorshipPaymentFailed;
          });
        }
      case Failure(message: final message):
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(message), backgroundColor: AppColors.error),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final amountText = '${AppConstants.currencySymbol}${widget.plan.monthlyFee.toStringAsFixed(2)}';
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(l10n.sponsorPaymentTitle),
        backgroundColor: AppColors.white,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: switch (_stage) {
            _Stage.starting => _LoadingCard(
                title: l10n.startingPayment,
                subtitle: l10n.startingSponsorPaymentHint,
              ),
            _Stage.waiting => _WaitingCard(
                title: l10n.waitingForPayment,
                amount: amountText,
                method: widget.method.label,
                phone: widget.phone,
                message: _message,
                busy: _busy,
                onCheckNow: _checkNow,
              ),
            _Stage.success => _ResultCard(
                success: true,
                title: l10n.sponsorshipActiveTitle,
                subtitle: l10n.sponsorshipActiveHint(widget.match.patientName),
                primaryLabel: l10n.doneLabel,
                onPrimary: () => Navigator.pop(context, true),
              ),
            _Stage.failed => _ResultCard(
                success: false,
                title: l10n.paymentFailedTitle,
                subtitle: _message ?? l10n.sponsorshipPaymentFailed,
                primaryLabel: l10n.tryAgain,
                onPrimary: () {
                  Navigator.pop(context, false);
                },
              ),
          },
        ),
      ),
    );
  }
}

class _LoadingCard extends StatelessWidget {
  final String title;
  final String subtitle;

  const _LoadingCard({required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const CircularProgressIndicator(),
          const SizedBox(height: 16),
          Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          Text(subtitle, textAlign: TextAlign.center, style: const TextStyle(color: AppColors.textSecondary)),
        ],
      ),
    );
  }
}

class _WaitingCard extends StatelessWidget {
  final String title;
  final String amount;
  final String method;
  final String phone;
  final String? message;
  final bool busy;
  final Future<void> Function() onCheckNow;

  const _WaitingCard({
    required this.title,
    required this.amount,
    required this.method,
    required this.phone,
    required this.message,
    required this.busy,
    required this.onCheckNow,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const CircularProgressIndicator(),
          const SizedBox(height: 16),
          Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          Text(l10n.approvePayWith(amount, method), textAlign: TextAlign.center),
          const SizedBox(height: 4),
          Text(l10n.requestSentTo(phone), style: const TextStyle(color: AppColors.textSecondary)),
          if (message != null) ...[
            const SizedBox(height: 12),
            Text(message!, textAlign: TextAlign.center, style: const TextStyle(color: AppColors.textSecondary)),
          ],
          const SizedBox(height: 18),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: busy ? null : onCheckNow,
              child: busy
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.white),
                    )
                  : Text(l10n.iPaidCheckNow),
            ),
          ),
        ],
      ),
    );
  }
}

class _ResultCard extends StatelessWidget {
  final bool success;
  final String title;
  final String subtitle;
  final String primaryLabel;
  final VoidCallback onPrimary;

  const _ResultCard({
    required this.success,
    required this.title,
    required this.subtitle,
    required this.primaryLabel,
    required this.onPrimary,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            success ? Icons.check_circle : Icons.error_outline,
            size: 56,
            color: success ? AppColors.success : AppColors.error,
          ),
          const SizedBox(height: 16),
          Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          Text(subtitle, textAlign: TextAlign.center, style: const TextStyle(color: AppColors.textSecondary)),
          const SizedBox(height: 18),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(onPressed: onPrimary, child: Text(primaryLabel)),
          ),
        ],
      ),
    );
  }
}
