import '../../core/utils/result.dart';
import '../activity_service.dart';

class MockActivityService implements ActivityService {
  @override
  Future<Result<ActivityCounts>> getCounts(String patientId) async {
    await Future.delayed(const Duration(milliseconds: 200));
    return Success(ActivityCounts(
      upcomingAppointments: 3,
      scheduledLabTests: 1,
      activeOrders: 2,
    ));
  }
}
