import '../core/utils/result.dart';
import '../models/subscription.dart';

/// One selectable mobile-money method (e.g. WaafiPay/ZAAD, eDahab).
class PaymentMethodOption {
  final String provider; // WaafiPay | Edahab
  final String method; // ZAAD | SAHAL | EVCPlus | Edahab
  final String label;

  const PaymentMethodOption({
    required this.provider,
    required this.method,
    required this.label,
  });

  factory PaymentMethodOption.fromJson(Map<String, dynamic> j) => PaymentMethodOption(
        provider: (j['provider'] ?? '').toString(),
        method: (j['method'] ?? '').toString(),
        label: (j['label'] ?? j['method'] ?? '').toString(),
      );
}

/// Mobile-money payments via the server's gateway (WaafiPay / eDahab).
abstract class PaymentService {
  /// Available payment methods (empty when the gateway is off/unconfigured).
  Future<Result<List<PaymentMethodOption>>> getMethods();

  /// Start a care-subscription payment; returns the transaction-log id to poll.
  Future<Result<String>> paySubscription({
    required String provider,
    required String method,
    required String phone,
  });

  /// Poll a payment; returns its status: Pending / Completed / Failed.
  Future<Result<String>> checkStatus(String transactionLog);

  /// Start a payment for a priced medicine order; returns the transaction-log
  /// id to poll. Only valid while the order is "Awaiting Payment".
  Future<Result<String>> payOrder({
    required String orderId,
    required String provider,
    required String method,
    required String phone,
  });

  /// Poll a medicine-order payment; returns its status: Pending / Completed /
  /// Failed. On Completed the server marks the order Paid.
  Future<Result<String>> checkOrderStatus({
    required String orderId,
    required String transactionLog,
  });

  /// The patient's current Care Subscription (or null), the plan catalog, and
  /// recent payment history.
  Future<Result<SubscriptionInfo>> getSubscription();

  /// Subscribe the patient to a plan. Pass [startTrial] when free trial is
  /// available — then [SubscribeResult.amountDueNow] is 0 and the gate opens.
  Future<Result<SubscribeResult>> subscribe(String plan, {bool startTrial = false});
}
