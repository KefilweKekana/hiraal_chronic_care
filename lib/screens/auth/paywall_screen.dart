import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/result.dart';
import '../../models/subscription.dart';
import '../../providers/app_provider.dart';
import '../../services/service_locator.dart';
import '../../widgets/shared_widgets.dart';
import '../profile/subscription_payment_screen.dart';

/// Shown after sign-up / sign-in when the patient has no active subscription.
/// Blocks the app until they choose a plan and pay (or start a free trial when
/// enabled in ERPNext).
class PaywallScreen extends StatefulWidget {
  const PaywallScreen({super.key});

  @override
  State<PaywallScreen> createState() => _PaywallScreenState();
}

class _PaywallScreenState extends State<PaywallScreen> {
  bool _loading = true;
  String? _error;
  List<SubscriptionPlan> _plans = [];
  List<String> _categories = [];
  SubscriptionTrialInfo _trial = const SubscriptionTrialInfo();
  Subscription? _existing;
  String? _selectedPlan;
  String? _selectedCategory;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  List<SubscriptionPlan> get _filteredPlans {
    final cat = _selectedCategory;
    if (cat == null || cat.isEmpty) return _plans;
    return _plans.where((p) => p.category == cat).toList();
  }

  SubscriptionPlan? get _selectedPlanObj {
    final name = _selectedPlan;
    if (name == null) return null;
    for (final p in _plans) {
      if (p.name == name) return p;
    }
    return null;
  }

  bool get _canStartTrial {
    final plan = _selectedPlanObj;
    return _trial.enabled &&
        _trial.eligible &&
        plan != null &&
        plan.allowsTrial &&
        (_existing == null || !_existing!.isActive);
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    final result = await ServiceLocator.instance.payments.getSubscription();
    if (!mounted) return;
    switch (result) {
      case Success(data: final info):
        setState(() {
          _plans = info.plans;
          _categories = info.categories;
          _trial = info.trial;
          _existing = info.subscription;
          _selectedCategory =
              info.categories.isNotEmpty ? info.categories.first : null;
          _selectedPlan =
              _existing?.plan ?? (info.plans.isNotEmpty ? info.plans.first.name : null);
          _loading = false;
        });
      case Failure(message: final msg):
        setState(() {
          _error = msg;
          _loading = false;
        });
    }
  }

  Future<void> _subscribeAndPay({required bool startTrial}) async {
    final plan = _selectedPlan;
    if (plan == null) return;
    setState(() => _busy = true);

    double amount;
    if (!startTrial &&
        _existing != null &&
        _existing!.plan == plan &&
        !_existing!.isActive) {
      amount = _existing!.monthlyFee;
    } else {
      final result = await ServiceLocator.instance.payments
          .subscribe(plan, startTrial: startTrial);
      if (!mounted) return;
      switch (result) {
        case Success(data: final subResult):
          if (subResult.isOnTrial || subResult.amountDueNow <= 0) {
            setState(() => _busy = false);
            await context.read<AppProvider>().refreshSubscriptionGate();
            return;
          }
          amount = subResult.amountDueNow;
        case Failure(message: final msg):
          setState(() => _busy = false);
          _snack(msg, error: true);
          return;
      }
    }
    if (!mounted) return;
    setState(() => _busy = false);

    final paid = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => SubscriptionPaymentScreen(amount: amount, planName: plan),
      ),
    );
    if (!mounted) return;
    if (paid == true) {
      await context.read<AppProvider>().refreshSubscriptionGate();
    }
  }

  void _snack(String m, {bool error = false}) =>
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(m),
          backgroundColor: error ? AppColors.error : AppColors.textSecondary,
        ),
      );

  Widget _planCard(SubscriptionPlan plan) {
    final selected = _selectedPlan == plan.name;
    return InkWell(
      onTap: () => setState(() => _selectedPlan = plan.name),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: selected ? AppColors.primaryLight : AppColors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: selected ? AppColors.primary : AppColors.cardBorder,
            width: selected ? 2 : 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  selected ? Icons.radio_button_checked : Icons.radio_button_off,
                  color: selected ? AppColors.primary : AppColors.textTertiary,
                  size: 20,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(plan.displayName,
                          style: const TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary)),
                      Text(plan.category,
                          style: const TextStyle(
                              fontSize: 12, color: AppColors.textTertiary)),
                    ],
                  ),
                ),
                if (plan.isFeatured)
                  Container(
                    margin: const EdgeInsets.only(right: 8),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Text('Popular',
                        style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: AppColors.primary)),
                  ),
                Text('\$${plan.monthlyFee.toStringAsFixed(0)}',
                    style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: AppColors.primary)),
                const Text(' /mo',
                    style:
                        TextStyle(fontSize: 13, color: AppColors.textSecondary)),
              ],
            ),
            if (plan.description.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(plan.description,
                  style: const TextStyle(
                      fontSize: 13, color: AppColors.textSecondary)),
            ],
            if (plan.features.isNotEmpty) ...[
              const SizedBox(height: 12),
              ...plan.features.map((f) => Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(Icons.check_circle,
                              size: 16, color: AppColors.primary),
                          const SizedBox(width: 8),
                          Expanded(
                              child: Text(f,
                                  style: const TextStyle(
                                      fontSize: 13,
                                      color: AppColors.textSecondary))),
                        ]),
                  )),
            ],
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final plans = _filteredPlans;
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 16),
                    const Center(child: HiraalLogo(size: 52)),
                    const SizedBox(height: 20),
                    const Text('Choose your plan',
                        style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w800,
                            color: AppColors.textPrimary)),
                    const SizedBox(height: 6),
                    Text(
                      _trial.enabled && _trial.eligible
                          ? 'Pick a category and plan. You can start a ${_trial.days}-day free trial when enabled for that plan.'
                          : 'Subscribe to a plan to start using Hiraal Lifecare — daily monitoring, nurse & doctor review, medicine delivery and more.',
                      style: const TextStyle(
                          fontSize: 14,
                          color: AppColors.textSecondary,
                          height: 1.5),
                    ),
                    if (_categories.length > 1) ...[
                      const SizedBox(height: 16),
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: _categories.map((c) {
                            final selected = _selectedCategory == c;
                            return Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: ChoiceChip(
                                label: Text(c),
                                selected: selected,
                                onSelected: (_) {
                                  setState(() {
                                    _selectedCategory = c;
                                    final filtered = _plans
                                        .where((p) => p.category == c)
                                        .toList();
                                    if (filtered.isNotEmpty &&
                                        !filtered.any(
                                            (p) => p.name == _selectedPlan)) {
                                      _selectedPlan = filtered.first.name;
                                    }
                                  });
                                },
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                    ],
                    const SizedBox(height: 16),
                    if (_error != null)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Row(children: [
                          Expanded(
                              child: Text(_error!,
                                  style:
                                      const TextStyle(color: AppColors.error))),
                          TextButton(
                              onPressed: _load, child: const Text('Retry')),
                        ]),
                      ),
                    ...plans.map(_planCard),
                    if (plans.isEmpty)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 24),
                        child: Text(
                            'No plans in this category yet. Ask the clinic to add Subscription Plans in ERPNext.'),
                      ),
                    const SizedBox(height: 8),
                    if (_canStartTrial) ...[
                      SizedBox(
                        width: double.infinity,
                        height: 54,
                        child: OutlinedButton(
                          onPressed: _busy
                              ? null
                              : () => _subscribeAndPay(startTrial: true),
                          child: Text('Start ${_trial.days}-day free trial'),
                        ),
                      ),
                      const SizedBox(height: 8),
                    ],
                    SizedBox(
                      width: double.infinity,
                      height: 54,
                      child: ElevatedButton(
                        onPressed: (_selectedPlan == null || _busy)
                            ? null
                            : () => _subscribeAndPay(startTrial: false),
                        child: _busy
                            ? const SizedBox(
                                height: 22,
                                width: 22,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2.5, color: Colors.white))
                            : const Text('Subscribe & Pay'),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Center(
                      child: TextButton(
                        onPressed: () => context.read<AppProvider>().logout(),
                        child: const Text('Sign out',
                            style: TextStyle(color: AppColors.textSecondary)),
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.lock_outline,
                            size: 14, color: AppColors.textTertiary),
                        SizedBox(width: 4),
                        Text('Secure mobile-money payment',
                            style: TextStyle(
                                fontSize: 12, color: AppColors.textTertiary)),
                      ],
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
      ),
    );
  }
}
