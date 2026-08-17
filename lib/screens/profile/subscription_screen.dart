import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../core/constants/app_constants.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/result.dart';
import '../../models/subscription.dart';
import '../../services/service_locator.dart';
import 'subscription_payment_screen.dart';

/// Care subscription: shows the patient's current plan/status, lets them
/// self-subscribe to a plan, pay/renew, and view payment history.
class SubscriptionScreen extends StatefulWidget {
  const SubscriptionScreen({super.key});

  @override
  State<SubscriptionScreen> createState() => _SubscriptionScreenState();
}

class _SubscriptionScreenState extends State<SubscriptionScreen> {
  SubscriptionInfo? _info;
  bool _loading = true;
  bool _busy = false;
  String? _error;
  String? _categoryFilter;

  String get _cur => AppConstants.currencySymbol;

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
    final result = await ServiceLocator.instance.payments.getSubscription();
    if (!mounted) return;
    setState(() {
      _loading = false;
      switch (result) {
        case Success(data: final info):
          _info = info;
        case Failure(message: final msg):
          _error = msg;
      }
    });
  }

  Future<void> _openPay({required double amount, String? planName}) async {
    final paid = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => SubscriptionPaymentScreen(amount: amount, planName: planName)),
    );
    if (!mounted) return;
    if (paid == true) _load();
  }

  Future<void> _subscribe(SubscriptionPlan plan, {bool startTrial = false}) async {
    setState(() => _busy = true);
    final result = await ServiceLocator.instance.payments
        .subscribe(plan.name, startTrial: startTrial);
    if (!mounted) return;
    setState(() => _busy = false);
    switch (result) {
      case Success(data: final subResult):
        if (subResult.isOnTrial || subResult.amountDueNow <= 0) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(subResult.isOnTrial
                  ? 'Free trial started'
                  : 'Subscription updated'),
            ),
          );
          await _load();
          return;
        }
        await _openPay(amount: subResult.amountDueNow, planName: plan.name);
      case Failure(message: final msg):
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(msg), backgroundColor: AppColors.error),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Subscription'),
        backgroundColor: AppColors.white,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? _errorView()
              : RefreshIndicator(
                  onRefresh: _load,
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: _buildBody(),
                  ),
                ),
    );
  }

  Widget _errorView() => Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(_error ?? 'Something went wrong', style: const TextStyle(color: AppColors.error)),
            const SizedBox(height: 8),
            TextButton(onPressed: _load, child: const Text('Retry')),
          ],
        ),
      );

  List<Widget> _buildBody() {
    final info = _info;
    if (info == null) return [const SizedBox.shrink()];
    final sub = info.subscription;
    final trial = info.trial;

    return [
      if (sub != null) ...[
        _statusCard(sub),
        const SizedBox(height: 20),
      ] else ...[
        const Text('Choose your plan', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
        const SizedBox(height: 4),
        Text(
          trial.enabled && trial.eligible
              ? 'Pick a category. Free trial (${trial.days} days) is available on eligible plans.'
              : 'Subscribe to keep your care team monitoring your health.',
          style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
        ),
        if (info.categories.length > 1) ...[
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: info.categories.map((c) {
              final selected = _categoryFilter == c;
              return ChoiceChip(
                label: Text(c),
                selected: selected,
                onSelected: (_) => setState(() => _categoryFilter = selected ? null : c),
              );
            }).toList(),
          ),
        ],
        const SizedBox(height: 14),
        ...info.plans
            .where((p) => _categoryFilter == null || p.category == _categoryFilter)
            .map((p) => _planCard(p, trial)),
        const SizedBox(height: 12),
        const Row(children: [
          Icon(Icons.lock, size: 13, color: AppColors.success),
          SizedBox(width: 4),
          Expanded(child: Text('Pay securely with ZAAD, SAHAL, EVC Plus or eDahab.',
              style: TextStyle(fontSize: 12, color: AppColors.success))),
        ]),
      ],
      if (info.history.isNotEmpty) ...[
        const SizedBox(height: 24),
        const Text('Payment history', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
        const SizedBox(height: 10),
        ...info.history.map(_historyRow),
      ],
      const SizedBox(height: 24),
    ];
  }

  // ── current subscription ───────────────────────────────
  Color _statusColor(Subscription s) {
    if (s.isActive) return AppColors.success;
    if (s.isAwaitingFirstPayment || s.status == 'Overdue' || s.status == 'Past Due') return AppColors.warning;
    if (s.status == 'Suspended' || s.status == 'Cancelled') return AppColors.error;
    return AppColors.textTertiary;
  }

  Widget _statusCard(Subscription s) {
    final color = _statusColor(s);
    final needsPay = !s.isActive; // awaiting first payment, overdue, past due
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(s.plan ?? 'Care subscription',
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(color: color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(20)),
                child: Text(s.statusLabel, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: color)),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text('$_cur${s.monthlyFee.toStringAsFixed(2)} / month',
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: AppColors.primary)),
          const SizedBox(height: 14),
          if (s.isOnTrial && s.trialEndDate != null)
            _row(Icons.hourglass_bottom, 'Trial ends', DateFormat('MMM dd, yyyy').format(s.trialEndDate!)),
          if (s.isActive && !s.isOnTrial && s.nextBillingDate != null)
            _row(Icons.event_repeat, 'Next payment', DateFormat('MMM dd, yyyy').format(s.nextBillingDate!)),
          if (s.lastPaymentDate != null)
            _row(Icons.check_circle_outline, 'Last paid', DateFormat('MMM dd, yyyy').format(s.lastPaymentDate!)),
          if (s.startDate != null)
            _row(Icons.calendar_today_outlined, 'Started', DateFormat('MMM dd, yyyy').format(s.startDate!)),
          _row(s.autoRenew ? Icons.autorenew : Icons.sync_disabled, 'Auto-renew', s.autoRenew ? 'On' : 'Off'),
          if (!s.isOnTrial) ...[
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton.icon(
                onPressed: _busy ? null : () => _openPay(amount: s.monthlyFee, planName: s.plan),
                icon: const Icon(Icons.payment, size: 20),
                label: Text(needsPay ? 'Complete payment' : 'Pay / renew now'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: needsPay ? AppColors.warning : AppColors.primary,
                  foregroundColor: AppColors.white,
                ),
              ),
            ),
          ] else
            const Padding(
              padding: EdgeInsets.only(top: 12),
              child: Text(
                'Enjoy your free trial — payment will be due when it ends.',
                style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
              ),
            ),
        ],
      ),
    );
  }

  Widget _row(IconData icon, String label, String value) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 5),
        child: Row(
          children: [
            Icon(icon, size: 16, color: AppColors.textTertiary),
            const SizedBox(width: 10),
            Text(label, style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
            const Spacer(),
            Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
          ],
        ),
      );

  // ── plan cards (no subscription) ───────────────────────
  Widget _planCard(SubscriptionPlan plan, SubscriptionTrialInfo trial) {
    final canTrial = trial.enabled && trial.eligible && plan.allowsTrial;
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(plan.displayName, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                    Text(plan.category, style: const TextStyle(fontSize: 12, color: AppColors.textTertiary)),
                  ],
                ),
              ),
              Text('$_cur${plan.monthlyFee.toStringAsFixed(0)}',
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: AppColors.primary)),
              const Padding(
                padding: EdgeInsets.only(top: 4, left: 2),
                child: Text('/mo', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ...plan.features.map((f) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 3),
                child: Row(
                  children: [
                    const Icon(Icons.check, size: 16, color: AppColors.success),
                    const SizedBox(width: 8),
                    Expanded(child: Text(f, style: const TextStyle(fontSize: 13))),
                  ],
                ),
              )),
          const SizedBox(height: 14),
          if (canTrial) ...[
            SizedBox(
              width: double.infinity,
              height: 44,
              child: OutlinedButton(
                onPressed: _busy ? null : () => _subscribe(plan, startTrial: true),
                child: Text('Start ${trial.days}-day free trial'),
              ),
            ),
            const SizedBox(height: 8),
          ],
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              onPressed: _busy ? null : () => _subscribe(plan),
              child: _busy
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.white))
                  : Text('Subscribe — $_cur${plan.monthlyFee.toStringAsFixed(0)}/mo'),
            ),
          ),
        ],
      ),
    );
  }

  // ── history ────────────────────────────────────────────
  Widget _historyRow(SubscriptionPayment p) {
    final ok = (p.status ?? '').toLowerCase() == 'success';
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Row(
        children: [
          Icon(ok ? Icons.check_circle : Icons.error_outline,
              color: ok ? AppColors.success : AppColors.error, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('$_cur${p.amount.toStringAsFixed(2)}',
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                Text(
                  [
                    if (p.date != null) DateFormat('MMM dd, yyyy').format(p.date!),
                    if ((p.method ?? '').isNotEmpty) p.method,
                  ].whereType<String>().join(' • '),
                  style: const TextStyle(fontSize: 12, color: AppColors.textTertiary),
                ),
              ],
            ),
          ),
          Text(p.status ?? '', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: ok ? AppColors.success : AppColors.error)),
        ],
      ),
    );
  }
}
