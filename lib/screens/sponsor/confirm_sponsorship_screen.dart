import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/constants/app_constants.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/result.dart';
import '../../l10n/app_localizations.dart';
import '../../models/caregiver_link.dart';
import '../../models/subscription.dart';
import '../../services/payment_service.dart';
import '../../services/service_locator.dart';
import 'sponsor_payment_screen.dart';

class ConfirmSponsorshipScreen extends StatefulWidget {
  final SponsorPatientMatch match;
  final SubscriptionPlan plan;

  const ConfirmSponsorshipScreen({
    super.key,
    required this.match,
    required this.plan,
  });

  @override
  State<ConfirmSponsorshipScreen> createState() => _ConfirmSponsorshipScreenState();
}

class _ConfirmSponsorshipScreenState extends State<ConfirmSponsorshipScreen> {
  final _phoneCtrl = TextEditingController();
  List<PaymentMethodOption> _methods = const [];
  PaymentMethodOption? _selectedMethod;
  bool _loadingMethods = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadMethods();
  }

  @override
  void dispose() {
    _phoneCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadMethods() async {
    setState(() {
      _loadingMethods = true;
      _error = null;
    });
    final result = await ServiceLocator.instance.payments.getMethods();
    if (!mounted) return;
    setState(() {
      _loadingMethods = false;
      switch (result) {
        case Success(data: final data):
          _methods = data;
          _selectedMethod = data.isNotEmpty ? data.first : null;
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
        title: Text(l10n.confirmSponsorshipTitle),
        backgroundColor: AppColors.white,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _SummaryCard(
            title: widget.match.patientName,
            rows: [
              _SummaryRow(l10n.memberIdLabel, widget.match.patientId),
              _SummaryRow(l10n.planLabel, widget.plan.displayName),
              _SummaryRow(
                l10n.monthlyCostLabel,
                '${AppConstants.currencySymbol}${widget.plan.monthlyFee.toStringAsFixed(2)}',
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(l10n.payWith, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
          const SizedBox(height: 10),
          if (_loadingMethods)
            const Center(child: Padding(padding: EdgeInsets.all(20), child: CircularProgressIndicator()))
          else if (_error != null)
            _InlineError(message: _error!, onRetry: _loadMethods)
          else
            ..._methods.map(
              (method) => RadioListTile<PaymentMethodOption>(
                value: method,
                groupValue: _selectedMethod,
                onChanged: (value) => setState(() => _selectedMethod = value),
                activeColor: AppColors.primary,
                title: Text(method.label),
                subtitle: Text(method.provider),
                contentPadding: EdgeInsets.zero,
              ),
            ),
          const SizedBox(height: 12),
          TextField(
            controller: _phoneCtrl,
            keyboardType: TextInputType.phone,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(15)],
            decoration: InputDecoration(
              labelText: l10n.mobileMoneyNumber,
              hintText: l10n.mobileMoneyHint,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            height: 54,
            child: ElevatedButton(
              onPressed: _selectedMethod == null
                  ? null
                  : () async {
                      if (_phoneCtrl.text.trim().length < 7) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(l10n.enterMobileMoneyNumber), backgroundColor: AppColors.error),
                        );
                        return;
                      }
                      final completed = await Navigator.of(context).push<bool>(
                        MaterialPageRoute(
                          builder: (_) => SponsorPaymentScreen(
                            match: widget.match,
                            plan: widget.plan,
                            method: _selectedMethod!,
                            phone: _phoneCtrl.text.trim(),
                          ),
                        ),
                      );
                      if (completed == true) {
                        if (!context.mounted) return;
                        Navigator.pop(context, true);
                      }
                    },
              child: Text(l10n.payAndStartSponsorship),
            ),
          ),
        ],
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final String title;
  final List<_SummaryRow> rows;

  const _SummaryCard({required this.title, required this.rows});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
          const SizedBox(height: 12),
          ...rows.map(
            (row) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  Expanded(
                    child: Text(row.label, style: const TextStyle(color: AppColors.textSecondary)),
                  ),
                  Text(row.value, style: const TextStyle(fontWeight: FontWeight.w600)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SummaryRow {
  final String label;
  final String value;

  const _SummaryRow(this.label, this.value);
}

class _InlineError extends StatelessWidget {
  final String message;
  final Future<void> Function() onRetry;

  const _InlineError({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        children: [
          Text(message, textAlign: TextAlign.center),
          const SizedBox(height: 8),
          OutlinedButton(onPressed: onRetry, child: Text(l10n.retry)),
        ],
      ),
    );
  }
}
