import '../../core/utils/result.dart';
import '../../models/subscription.dart';
import '../payment_service.dart';

/// Mock payments for the demo build: a couple of methods, and a payment that
/// "completes" after a couple of polls.
class MockPaymentService implements PaymentService {
  // Poll counts per transaction so overlapping flows don't advance each other.
  final Map<String, int> _polls = {};

  @override
  Future<Result<List<PaymentMethodOption>>> getMethods() async {
    await Future.delayed(const Duration(milliseconds: 400));
    return Success(const [
      PaymentMethodOption(provider: 'WaafiPay', method: 'ZAAD', label: 'ZAAD'),
      PaymentMethodOption(provider: 'WaafiPay', method: 'SAHAL', label: 'SAHAL'),
      PaymentMethodOption(provider: 'WaafiPay', method: 'EVCPlus', label: 'EVC Plus'),
      PaymentMethodOption(provider: 'Edahab', method: 'Edahab', label: 'eDahab'),
    ]);
  }

  @override
  Future<Result<String>> paySubscription({
    required String provider,
    required String method,
    required String phone,
  }) async {
    await Future.delayed(const Duration(seconds: 1));
    _polls['MOCK-TXN-001'] = 0;
    return const Success('MOCK-TXN-001');
  }

  @override
  Future<Result<String>> checkStatus(String transactionLog) async {
    await Future.delayed(const Duration(seconds: 1));
    final polls = _polls[transactionLog] = (_polls[transactionLog] ?? 0) + 1;
    return Success(polls >= 2 ? 'Completed' : 'Pending');
  }

  @override
  Future<Result<String>> payOrder({
    required String orderId,
    required String provider,
    required String method,
    required String phone,
  }) async {
    await Future.delayed(const Duration(seconds: 1));
    _polls[orderId] = 0;
    return const Success('MOCK-ORDER-TXN-001');
  }

  @override
  Future<Result<String>> checkOrderStatus({
    required String orderId,
    required String transactionLog,
  }) async {
    await Future.delayed(const Duration(seconds: 1));
    final polls = _polls[orderId] = (_polls[orderId] ?? 0) + 1;
    return Success(polls >= 2 ? 'Completed' : 'Pending');
  }

  static const _plans = [
    SubscriptionPlan(
      name: 'Standard Care',
      planName: 'Standard Care',
      category: 'General',
      monthlyFee: 5,
      allowsTrial: true,
      features: [
        'Daily vitals monitoring',
        'Nurse & doctor review',
        'Medicine delivery',
        'Telemedicine visits',
      ],
    ),
    SubscriptionPlan(
      name: 'Premium Care',
      planName: 'Premium Care',
      category: 'General',
      monthlyFee: 10,
      allowsTrial: true,
      isFeatured: true,
      features: [
        'Everything in Standard Care',
        'Priority alerts & faster review',
        'Optional 5G home hub',
        'Extended support',
      ],
    ),
    SubscriptionPlan(
      name: 'Hypertension Care',
      planName: 'Hypertension Care',
      category: 'Hypertension',
      monthlyFee: 5,
      allowsTrial: true,
      features: ['Daily BP tracking', 'Nurse review', 'Medicine delivery', 'Telemedicine'],
    ),
    SubscriptionPlan(
      name: 'Diabetes Care',
      planName: 'Diabetes Care',
      category: 'Diabetes',
      monthlyFee: 5,
      allowsTrial: true,
      features: ['Daily sugar tracking', 'Nurse review', 'Medicine delivery', 'Telemedicine'],
    ),
  ];

  @override
  Future<Result<SubscriptionInfo>> getSubscription() async {
    await Future.delayed(const Duration(milliseconds: 400));
    return Success(SubscriptionInfo(
      subscription: null,
      plans: _plans,
      categories: const ['General', 'Hypertension', 'Diabetes'],
      trial: const SubscriptionTrialInfo(enabled: true, days: 14, eligible: true),
      history: const [],
    ));
  }

  @override
  Future<Result<SubscribeResult>> subscribe(String plan, {bool startTrial = false}) async {
    await Future.delayed(const Duration(milliseconds: 600));
    for (final p in _plans) {
      if (p.name == plan) {
        if (startTrial) {
          return Success(SubscribeResult(
            amountDueNow: 0,
            monthlyFee: p.monthlyFee,
            isOnTrial: true,
            trialEndDate: DateTime.now().add(const Duration(days: 14)),
            plan: p.name,
            status: 'Active',
          ));
        }
        return Success(SubscribeResult(
          amountDueNow: p.monthlyFee,
          monthlyFee: p.monthlyFee,
          plan: p.name,
          status: 'Overdue',
        ));
      }
    }
    return const Failure('Unknown plan');
  }
}
