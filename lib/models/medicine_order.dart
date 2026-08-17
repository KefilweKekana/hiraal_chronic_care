/// A single line item in a medicine order. Pricing is filled in by the
/// pharmacy when it reviews the prescription.
class MedicineLine {
  final String name;
  final int quantity;
  final String? dosage;
  final String? frequency;
  final double? unitPrice;
  final double? totalPrice;
  final bool inStock;

  const MedicineLine({
    required this.name,
    this.quantity = 1,
    this.dosage,
    this.frequency,
    this.unitPrice,
    this.totalPrice,
    this.inStock = true,
  });

  static double? _toDouble(Object? v) {
    if (v == null) return null;
    if (v is num) return v.toDouble();
    return double.tryParse(v.toString());
  }

  factory MedicineLine.fromJson(Map<String, dynamic> j) => MedicineLine(
        name: (j['medicine_name'] ?? j['name'] ?? '').toString(),
        quantity: int.tryParse('${j['quantity'] ?? 1}') ?? 1,
        dosage: (j['dosage'] as Object?)?.toString(),
        frequency: (j['frequency'] as Object?)?.toString(),
        unitPrice: _toDouble(j['unit_price']),
        totalPrice: _toDouble(j['total_price']),
        inStock: '${j['in_stock'] ?? 1}' == '1' || j['in_stock'] == true,
      );
}

/// A patient's medicine delivery order, mirroring the server "Medicine Request"
/// doctype, including its live status and delivery timeline.
class MedicineOrder {
  final String id;
  final String status;
  final String priority;
  final int totalItems;
  final String? deliveryType;
  final String? deliveryAddress;
  final DateTime? estimatedDelivery;
  final DateTime? preparationStarted;
  final DateTime? dispatchedAt;
  final DateTime? deliveredAt;
  final String? paymentMethod;
  final String? paymentStatus;
  final String? paymentReference;
  final double? amount;
  final double? deliveryFee;
  final double? tax;
  final double? total;
  final String? prescription;
  final bool receivedConfirmed;
  final String? pharmacistNote;
  final String? cancellationReason;
  final DateTime? createdAt;
  final bool cancellable;
  final bool payable;
  final List<MedicineLine> medicines;

  const MedicineOrder({
    required this.id,
    required this.status,
    this.priority = 'Normal',
    this.totalItems = 0,
    this.deliveryType,
    this.deliveryAddress,
    this.estimatedDelivery,
    this.preparationStarted,
    this.dispatchedAt,
    this.deliveredAt,
    this.paymentMethod,
    this.paymentStatus,
    this.paymentReference,
    this.amount,
    this.deliveryFee,
    this.tax,
    this.total,
    this.prescription,
    this.receivedConfirmed = false,
    this.pharmacistNote,
    this.cancellationReason,
    this.createdAt,
    this.cancellable = false,
    this.payable = false,
    this.medicines = const [],
  });

  /// Patient-facing lifecycle stages, in order. "Cancelled" is terminal and
  /// rendered separately.
  static const List<String> stages = [
    'Received',
    'Under Review',
    'Awaiting Payment',
    'Paid',
    'Preparing',
    'Out for Delivery',
    'Delivered',
  ];

  /// Friendly labels for each stage, in the same order.
  static const List<String> stageLabels = [
    'Prescription received',
    'Under pharmacist review',
    'Awaiting your payment',
    'Payment confirmed',
    'Preparing your medicines',
    'Out for delivery',
    'Delivered',
  ];

  bool get isCancelled => status == 'Cancelled';
  bool get isDelivered => status == 'Delivered';
  bool get isPaid => (paymentStatus ?? '') == 'Paid';

  /// Index of the current stage in [stages]; -1 if cancelled/unknown.
  int get stageIndex => stages.indexOf(status);

  /// A short, patient-friendly description of the current status.
  String get statusLabel {
    if (isCancelled) return 'Cancelled';
    final i = stageIndex;
    return (i >= 0 && i < stageLabels.length) ? stageLabels[i] : status;
  }

  /// What the patient owes — the priced total, falling back to the medicines
  /// subtotal before delivery/tax are added.
  double get amountDue => total ?? amount ?? 0;

  static DateTime? _dt(Object? v) {
    if (v == null) return null;
    return DateTime.tryParse(v.toString());
  }

  static double? _toDouble(Object? v) {
    if (v == null) return null;
    if (v is num) return v.toDouble();
    return double.tryParse(v.toString());
  }

  factory MedicineOrder.fromJson(Map<String, dynamic> j) {
    final rawItems = (j['medicines'] as List?) ?? const [];
    return MedicineOrder(
      id: (j['name'] ?? '').toString(),
      status: (j['status'] ?? 'Received').toString(),
      priority: (j['priority'] ?? 'Normal').toString(),
      totalItems: int.tryParse('${j['total_items'] ?? 0}') ?? 0,
      deliveryType: (j['delivery_type'] as Object?)?.toString(),
      deliveryAddress: (j['delivery_address'] as Object?)?.toString(),
      estimatedDelivery: _dt(j['estimated_delivery']),
      preparationStarted: _dt(j['preparation_started']),
      dispatchedAt: _dt(j['dispatched_at']),
      deliveredAt: _dt(j['delivered_at']),
      paymentMethod: (j['payment_method'] as Object?)?.toString(),
      paymentStatus: (j['payment_status'] as Object?)?.toString(),
      paymentReference: (j['payment_reference'] as Object?)?.toString(),
      amount: _toDouble(j['amount']),
      deliveryFee: _toDouble(j['delivery_fee']),
      tax: _toDouble(j['tax']),
      total: _toDouble(j['total']),
      prescription: (j['prescription'] as Object?)?.toString(),
      receivedConfirmed:
          '${j['received_confirmed'] ?? 0}' == '1' || j['received_confirmed'] == true,
      pharmacistNote: (j['pharmacist_note'] as Object?)?.toString(),
      cancellationReason: (j['cancellation_reason'] as Object?)?.toString(),
      createdAt: _dt(j['creation']),
      cancellable: '${j['cancellable'] ?? 0}' == '1' || j['cancellable'] == true,
      payable: '${j['payable'] ?? 0}' == '1' || j['payable'] == true,
      medicines: rawItems
          .whereType<Map>()
          .map((e) => MedicineLine.fromJson(Map<String, dynamic>.from(e)))
          .toList(),
    );
  }
}
