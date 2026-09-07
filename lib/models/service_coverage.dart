class ServiceCoverage {
  final bool covered;
  final bool paymentRequired;
  final double amount;
  final String currency;
  final String reason;
  final String message;
  final String service;
  final String? plan;
  final int quotaUsed;
  final int quotaLimit;

  const ServiceCoverage({
    required this.covered,
    required this.paymentRequired,
    this.amount = 0,
    this.currency = 'USD',
    this.reason = '',
    this.message = '',
    this.service = '',
    this.plan,
    this.quotaUsed = 0,
    this.quotaLimit = 0,
  });

  factory ServiceCoverage.fromJson(Map<String, dynamic> json) {
    return ServiceCoverage(
      covered: json['covered'] == true || json['covered'] == 1,
      paymentRequired: json['payment_required'] == true || json['payment_required'] == 1,
      amount: (json['amount'] is num)
          ? (json['amount'] as num).toDouble()
          : double.tryParse('${json['amount'] ?? 0}') ?? 0,
      currency: (json['currency'] ?? 'USD').toString(),
      reason: (json['reason'] ?? '').toString(),
      message: (json['message'] ?? '').toString(),
      service: (json['service'] ?? '').toString(),
      plan: json['plan']?.toString(),
      quotaUsed: int.tryParse('${json['quota_used'] ?? 0}') ?? 0,
      quotaLimit: int.tryParse('${json['quota_limit'] ?? 0}') ?? 0,
    );
  }

  static const included = ServiceCoverage(
    covered: true,
    paymentRequired: false,
    message: 'Included in your plan, FREE for you',
  );
}

class AppointmentSlot {
  final String time;
  final String label;
  final bool available;

  const AppointmentSlot({
    required this.time,
    required this.label,
    this.available = true,
  });

  factory AppointmentSlot.fromJson(Map<String, dynamic> json) {
    return AppointmentSlot(
      time: (json['time'] ?? '').toString(),
      label: (json['label'] ?? json['time'] ?? '').toString(),
      available: json['available'] == true || json['available'] == 1,
    );
  }
}

class AppointmentDaySlots {
  final String date;
  final String weekday;
  final String dayLabel;
  final List<AppointmentSlot> slots;

  const AppointmentDaySlots({
    required this.date,
    required this.weekday,
    required this.dayLabel,
    this.slots = const [],
  });

  factory AppointmentDaySlots.fromJson(Map<String, dynamic> json) {
    final raw = json['slots'];
    return AppointmentDaySlots(
      date: (json['date'] ?? '').toString(),
      weekday: (json['weekday'] ?? '').toString(),
      dayLabel: (json['day_label'] ?? json['weekday'] ?? '').toString(),
      slots: raw is List
          ? raw
              .whereType<Map>()
              .map((e) => AppointmentSlot.fromJson(Map<String, dynamic>.from(e)))
              .toList()
          : const [],
    );
  }
}

class SlotAvailability {
  final List<AppointmentDaySlots> days;
  final bool empty;
  final String? message;

  const SlotAvailability({
    this.days = const [],
    this.empty = false,
    this.message,
  });

  factory SlotAvailability.fromJson(Map<String, dynamic> json) {
    final raw = json['days'];
    return SlotAvailability(
      days: raw is List
          ? raw
              .whereType<Map>()
              .map((e) => AppointmentDaySlots.fromJson(Map<String, dynamic>.from(e)))
              .toList()
          : const [],
      empty: json['empty'] == true || json['empty'] == 1,
      message: json['message']?.toString(),
    );
  }
}
