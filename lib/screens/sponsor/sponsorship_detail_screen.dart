import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../core/constants/app_constants.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/result.dart';
import '../../l10n/app_localizations.dart';
import '../../models/caregiver_link.dart';
import '../../services/service_locator.dart';
import 'sponsor_patient_screen.dart';

class SponsorshipDetailScreen extends StatefulWidget {
  final SponsorshipSummary summary;

  const SponsorshipDetailScreen({super.key, required this.summary});

  @override
  State<SponsorshipDetailScreen> createState() => _SponsorshipDetailScreenState();
}

class _SponsorshipDetailScreenState extends State<SponsorshipDetailScreen> {
  bool _loading = true;
  String? _error;
  SponsorshipDashboard? _dashboard;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    final result = await ServiceLocator.instance.caregivers.getSponsorshipDashboard(widget.summary.name);
    if (!mounted) return;
    setState(() {
      _loading = false;
      switch (result) {
        case Success(data: final data):
          _dashboard = data;
        case Failure(message: final message):
          _error = message;
      }
    });
  }

  Future<void> _openPayment() async {
    final dash = _dashboard;
    if (dash == null) return;
    final match = SponsorPatientMatch(
      patient: dash.patient,
      patientName: dash.patientName,
      patientId: dash.patientId,
      phone: '',
      familyMember: dash.name,
    );
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => SponsorPatientScreen(match: match)),
    );
    if (!mounted) return;
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final dash = _dashboard;
    final canPay = (dash?.canPayForCare ?? widget.summary.canPayForCare) &&
        (dash?.isAccepted == true || dash?.isActive == true);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(l10n.sponsorshipDetailsTitle),
        backgroundColor: AppColors.white,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? _ErrorBody(message: _error!, onRetry: _load)
              : ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    _HeaderCard(
                      patientName: dash?.patientName ?? widget.summary.patientName,
                      status: dash?.status ?? widget.summary.status,
                      plan: dash?.plan ?? widget.summary.plan,
                      monthlyAmount: dash?.monthlyAmount ?? widget.summary.monthlyAmount,
                      nextPaymentDate: dash?.nextPaymentDate ?? widget.summary.nextPaymentDate,
                    ),
                    if ((dash?.isPending ?? widget.summary.isPending)) ...[
                      const SizedBox(height: 16),
                      _InfoBanner(
                        icon: Icons.hourglass_top,
                        message: l10n.sponsorshipPendingHint(
                          dash?.patientName ?? widget.summary.patientName,
                        ),
                      ),
                    ],
                    if (canPay) ...[
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: ElevatedButton(
                          onPressed: _openPayment,
                          child: Text(l10n.sponsorshipPayNow),
                        ),
                      ),
                    ],
                    if (dash != null && dash.updates.isNotEmpty) ...[
                      const SizedBox(height: 20),
                      Text(l10n.latestUpdates, style: const TextStyle(fontWeight: FontWeight.w700)),
                      const SizedBox(height: 8),
                      ...dash.updates.map(
                        (update) => Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Icon(Icons.check_circle, size: 18, color: AppColors.success),
                              const SizedBox(width: 8),
                              Expanded(child: Text(update)),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
    );
  }
}

class _HeaderCard extends StatelessWidget {
  final String patientName;
  final String status;
  final String? plan;
  final double monthlyAmount;
  final DateTime? nextPaymentDate;

  const _HeaderCard({
    required this.patientName,
    required this.status,
    required this.plan,
    required this.monthlyAmount,
    required this.nextPaymentDate,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(patientName, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
          const SizedBox(height: 12),
          _row(l10n.status, status),
          _row(l10n.planLabel, plan?.isNotEmpty == true ? plan! : '–'),
          _row(
            l10n.nextPaymentLabel,
            nextPaymentDate != null ? DateFormat('dd MMM yyyy').format(nextPaymentDate!) : '–',
          ),
          const SizedBox(height: 8),
          Text(
            '${AppConstants.currencySymbol}${monthlyAmount.toStringAsFixed(2)} / month',
            style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w700, fontSize: 16),
          ),
        ],
      ),
    );
  }

  Widget _row(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Expanded(child: Text(label, style: const TextStyle(color: AppColors.textSecondary))),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

class _InfoBanner extends StatelessWidget {
  final IconData icon;
  final String message;

  const _InfoBanner({required this.icon, required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.primarySurface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: AppColors.primary),
          const SizedBox(width: 10),
          Expanded(child: Text(message, style: const TextStyle(height: 1.4))),
        ],
      ),
    );
  }
}

class _ErrorBody extends StatelessWidget {
  final String message;
  final Future<void> Function() onRetry;

  const _ErrorBody({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 12),
            ElevatedButton(onPressed: onRetry, child: Text(l10n.retry)),
          ],
        ),
      ),
    );
  }
}
