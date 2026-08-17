import 'package:flutter/material.dart';

import '../../core/constants/app_constants.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/result.dart';
import '../../l10n/app_localizations.dart';
import '../../models/caregiver_link.dart';
import '../../models/subscription.dart';
import '../../services/service_locator.dart';
import 'confirm_sponsorship_screen.dart';

class SponsorPatientScreen extends StatefulWidget {
  final SponsorPatientMatch match;

  const SponsorPatientScreen({super.key, required this.match});

  @override
  State<SponsorPatientScreen> createState() => _SponsorPatientScreenState();
}

class _SponsorPatientScreenState extends State<SponsorPatientScreen> {
  bool _loading = true;
  String? _error;
  List<SubscriptionPlan> _plans = const [];
  SubscriptionPlan? _selectedPlan;

  @override
  void initState() {
    super.initState();
    _loadPlans();
  }

  Future<void> _loadPlans() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    final result = await ServiceLocator.instance.payments.getSubscription();
    if (!mounted) return;
    setState(() {
      _loading = false;
      switch (result) {
        case Success(data: final data):
          _plans = data.plans;
          _selectedPlan = data.plans.isNotEmpty ? data.plans.first : null;
        case Failure(message: final message):
          _error = message;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(l10n.sponsorPatientTitle),
        backgroundColor: AppColors.white,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.cardBorder),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(widget.match.patientName, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
                const SizedBox(height: 6),
                Text(l10n.memberId(widget.match.patientId), style: const TextStyle(color: AppColors.textSecondary)),
                Text(widget.match.phone, style: const TextStyle(color: AppColors.textSecondary)),
                if ((widget.match.clinic ?? '').isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(widget.match.clinic!, style: const TextStyle(color: AppColors.textSecondary)),
                ],
              ],
            ),
          ),
          const SizedBox(height: 20),
          Text(l10n.chooseMonthlyPlan, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
          const SizedBox(height: 10),
          if (_loading)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 30),
              child: Center(child: CircularProgressIndicator()),
            )
          else if (_error != null)
            _ErrorCard(message: _error!, onRetry: _loadPlans)
          else if (_plans.isEmpty)
            _ErrorCard(message: l10n.noPlansAvailable, onRetry: _loadPlans)
          else
            ..._plans.map(
              (plan) => GestureDetector(
                onTap: () => setState(() => _selectedPlan = plan),
                child: Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: _selectedPlan?.name == plan.name ? AppColors.primary : AppColors.cardBorder,
                      width: _selectedPlan?.name == plan.name ? 1.5 : 1,
                    ),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Radio<SubscriptionPlan>(
                        value: plan,
                        groupValue: _selectedPlan,
                        onChanged: (value) => setState(() => _selectedPlan = value),
                        activeColor: AppColors.primary,
                      ),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(plan.displayName, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                            const SizedBox(height: 4),
                            Text(
                              '${AppConstants.currencySymbol}${plan.monthlyFee.toStringAsFixed(2)} / month',
                              style: const TextStyle(fontSize: 14, color: AppColors.primary, fontWeight: FontWeight.w600),
                            ),
                            if (plan.description.isNotEmpty) ...[
                              const SizedBox(height: 4),
                              Text(plan.description, style: const TextStyle(color: AppColors.textSecondary)),
                            ],
                            if (plan.features.isNotEmpty) ...[
                              const SizedBox(height: 8),
                              ...plan.features.take(3).map(
                                (feature) => Padding(
                                  padding: const EdgeInsets.only(bottom: 3),
                                  child: Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Icon(Icons.check_circle, size: 16, color: AppColors.success),
                                      const SizedBox(width: 6),
                                      Expanded(child: Text(feature, style: const TextStyle(fontSize: 12))),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: 54,
            child: ElevatedButton(
              onPressed: _selectedPlan == null
                  ? null
                  : () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => ConfirmSponsorshipScreen(
                            match: widget.match,
                            plan: _selectedPlan!,
                          ),
                        ),
                      );
                    },
              child: Text(l10n.sponsorThisPatient),
            ),
          ),
        ],
      ),
    );
  }
}

class _ErrorCard extends StatelessWidget {
  final String message;
  final Future<void> Function() onRetry;

  const _ErrorCard({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        children: [
          Text(message, textAlign: TextAlign.center),
          const SizedBox(height: 10),
          ElevatedButton(onPressed: onRetry, child: Text(l10n.retry)),
        ],
      ),
    );
  }
}
