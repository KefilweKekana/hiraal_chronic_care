/// A care-subscription plan from the server catalog (Subscription Plan DocType).
class SubscriptionPlan {
  final String name;
  final String planName;
  final String category;
  final double monthlyFee;
  final String description;
  final List<String> features;
  final bool allowsTrial;
  final bool isFeatured;

  const SubscriptionPlan({
    required this.name,
    this.planName = '',
    this.category = 'General',
    required this.monthlyFee,
    this.description = '',
    this.features = const [],
    this.allowsTrial = true,
    this.isFeatured = false,
  });

  String get displayName => planName.isNotEmpty ? planName : name;

  factory SubscriptionPlan.fromJson(Map<String, dynamic> j) => SubscriptionPlan(
        name: (j['name'] ?? j['plan_name'] ?? '').toString(),
        planName: (j['plan_name'] ?? j['name'] ?? '').toString(),
        category: (j['category'] ?? 'General').toString(),
        monthlyFee: _toDouble(j['monthly_fee']) ?? 0,
        description: (j['description'] ?? '').toString(),
        features: ((j['features'] as List?) ?? const []).map((e) => e.toString()).toList(),
        allowsTrial: '${j['allows_trial'] ?? 0}' == '1' || j['allows_trial'] == true,
        isFeatured: '${j['is_featured'] ?? 0}' == '1' || j['is_featured'] == true,
      );
}

/// Global free-trial settings returned with the subscription payload.
class SubscriptionTrialInfo {
  final bool enabled;
  final int days;
  final bool eligible;

  const SubscriptionTrialInfo({
    this.enabled = false,
    this.days = 14,
    this.eligible = false,
  });

  factory SubscriptionTrialInfo.fromJson(Map<String, dynamic>? j) {
    if (j == null) return const SubscriptionTrialInfo();
    return SubscriptionTrialInfo(
      enabled: j['enabled'] == true || '${j['enabled']}' == '1',
      days: int.tryParse('${j['days'] ?? 14}') ?? 14,
      eligible: j['eligible'] == true || '${j['eligible']}' == '1',
    );
  }
}

/// One past subscription payment (for the history list).
class SubscriptionPayment {
  final double amount;
  final DateTime? date;
  final String? method;
  final String? status;
  final String? reference;

  const SubscriptionPayment({required this.amount, this.date, this.method, this.status, this.reference});

  factory SubscriptionPayment.fromJson(Map<String, dynamic> j) => SubscriptionPayment(
        amount: _toDouble(j['amount']) ?? 0,
        date: _dt(j['payment_date']),
        method: (j['payment_method'] as Object?)?.toString(),
        status: (j['status'] as Object?)?.toString(),
        reference: (j['reference_id'] as Object?)?.toString(),
      );
}

/// The patient's current Care Subscription.
class Subscription {
  final String? plan;
  final String? planCategory;
  final double monthlyFee;
  final String status;
  final DateTime? startDate;
  final DateTime? nextBillingDate;
  final DateTime? lastPaymentDate;
  final String? lastPaymentStatus;
  final bool autoRenew;
  final double totalCollected;
  final bool isOnTrial;
  final DateTime? trialEndDate;

  const Subscription({
    this.plan,
    this.planCategory,
    this.monthlyFee = 0,
    this.status = '',
    this.startDate,
    this.nextBillingDate,
    this.lastPaymentDate,
    this.lastPaymentStatus,
    this.autoRenew = false,
    this.totalCollected = 0,
    this.isOnTrial = false,
    this.trialEndDate,
  });

  /// True once the subscription has been paid and is live (or on trial).
  bool get isActive => status == 'Active' || status == 'Expiring Soon';

  /// A new, never-paid subscription is technically "Overdue" — present that as
  /// "awaiting payment" rather than alarming the patient.
  bool get isAwaitingFirstPayment =>
      (status == 'Overdue' || status == 'Past Due') && lastPaymentDate == null;

  /// Patient-friendly status label.
  String get statusLabel {
    if (isOnTrial && isActive) return 'Free trial';
    if (isAwaitingFirstPayment) return 'Awaiting payment';
    switch (status) {
      case 'Active':
        return 'Active';
      case 'Expiring Soon':
        return 'Expiring soon';
      case 'Overdue':
      case 'Past Due':
        return 'Payment due';
      case 'Suspended':
        return 'Suspended';
      case 'Cancelled':
        return 'Cancelled';
      default:
        return status.isEmpty ? 'Inactive' : status;
    }
  }

  factory Subscription.fromJson(Map<String, dynamic> j) => Subscription(
        plan: (j['plan'] as Object?)?.toString(),
        planCategory: (j['plan_category'] as Object?)?.toString(),
        monthlyFee: _toDouble(j['monthly_fee']) ?? 0,
        status: (j['status'] ?? '').toString(),
        startDate: _dt(j['start_date']),
        nextBillingDate: _dt(j['next_billing_date']),
        lastPaymentDate: _dt(j['last_payment_date']),
        lastPaymentStatus: (j['last_payment_status'] as Object?)?.toString(),
        autoRenew: '${j['auto_renew'] ?? 0}' == '1' || j['auto_renew'] == true,
        totalCollected: _toDouble(j['total_collected']) ?? 0,
        isOnTrial: '${j['is_on_trial'] ?? 0}' == '1' || j['is_on_trial'] == true,
        trialEndDate: _dt(j['trial_end_date']),
      );
}

/// Result of creating / attaching to a subscription (pay now or trial).
class SubscribeResult {
  final double amountDueNow;
  final double monthlyFee;
  final bool isOnTrial;
  final DateTime? trialEndDate;
  final String? plan;
  final String? status;

  const SubscribeResult({
    required this.amountDueNow,
    required this.monthlyFee,
    this.isOnTrial = false,
    this.trialEndDate,
    this.plan,
    this.status,
  });

  factory SubscribeResult.fromJson(Map<String, dynamic> j) => SubscribeResult(
        amountDueNow: _toDouble(j['amount_due_now']) ??
            _toDouble(j['monthly_fee']) ??
            0,
        monthlyFee: _toDouble(j['monthly_fee']) ?? 0,
        isOnTrial: '${j['is_on_trial'] ?? 0}' == '1' || j['is_on_trial'] == true,
        trialEndDate: _dt(j['trial_end_date']),
        plan: (j['plan'] as Object?)?.toString(),
        status: (j['status'] as Object?)?.toString(),
      );
}

/// The full payload for the Subscriptions screen.
class SubscriptionInfo {
  final Subscription? subscription;
  final List<SubscriptionPlan> plans;
  final List<String> categories;
  final List<SubscriptionPayment> history;
  final SubscriptionTrialInfo trial;
  final bool active;

  const SubscriptionInfo({
    this.subscription,
    this.plans = const [],
    this.categories = const [],
    this.history = const [],
    this.trial = const SubscriptionTrialInfo(),
    this.active = false,
  });

  factory SubscriptionInfo.fromJson(Map<String, dynamic> j) {
    final sub = j['subscription'];
    final cats = ((j['categories'] as List?) ?? const [])
        .map((e) => e.toString())
        .where((e) => e.isNotEmpty)
        .toList();
    final plans = ((j['plans'] as List?) ?? const [])
        .whereType<Map>()
        .map((e) => SubscriptionPlan.fromJson(Map<String, dynamic>.from(e)))
        .toList();
    final derivedCats = cats.isNotEmpty
        ? cats
        : {
            for (final p in plans) p.category,
          }.toList();
    return SubscriptionInfo(
      subscription: (sub is Map) ? Subscription.fromJson(Map<String, dynamic>.from(sub)) : null,
      plans: plans,
      categories: derivedCats,
      history: ((j['history'] as List?) ?? const [])
          .whereType<Map>()
          .map((e) => SubscriptionPayment.fromJson(Map<String, dynamic>.from(e)))
          .toList(),
      trial: SubscriptionTrialInfo.fromJson(
        j['trial'] is Map ? Map<String, dynamic>.from(j['trial'] as Map) : null,
      ),
      active: j['active'] == true || '${j['active']}' == '1',
    );
  }
}

DateTime? _dt(Object? v) {
  if (v == null) return null;
  return DateTime.tryParse(v.toString());
}

double? _toDouble(Object? v) {
  if (v == null) return null;
  if (v is num) return v.toDouble();
  return double.tryParse(v.toString());
}
