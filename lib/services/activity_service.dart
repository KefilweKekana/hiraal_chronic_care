import '../core/utils/result.dart';

class ActivityCounts {
  final int upcomingAppointments;
  final int scheduledLabTests;
  final int activeOrders;

  ActivityCounts({
    required this.upcomingAppointments,
    required this.scheduledLabTests,
    required this.activeOrders,
  });

  factory ActivityCounts.fromJson(Map<String, dynamic> json) => ActivityCounts(
    upcomingAppointments: json['upcoming_appointments'] ?? 0,
    scheduledLabTests: json['scheduled_lab_tests'] ?? 0,
    activeOrders: json['active_orders'] ?? 0,
  );
}

/// Fetches activity counts from ERPNext (appointments, lab tests, orders).
abstract class ActivityService {
  Future<Result<ActivityCounts>> getCounts(String patientId);
}
