import 'package:dio/dio.dart';

import '../../core/network/api_client.dart';
import '../../core/utils/app_logger.dart';
import '../../core/utils/result.dart';
import '../activity_service.dart';

/// ERPNext implementation of [ActivityService].
///
/// Fetches counts of upcoming appointments, scheduled lab tests,
/// and active medication orders for the given patient.
class ErpNextActivityService implements ActivityService {
  final ApiClient _api;

  ErpNextActivityService(this._api);

  @override
  Future<Result<ActivityCounts>> getCounts(String patientId) async {
    try {
      // Scoped server endpoint returns the logged-in patient's counts.
      final response =
          await _api.dio.post('/method/hiraal_emr.api.get_my_activity_counts');
      final data = response.data?['message'] as Map<String, dynamic>? ?? {};

      return Success(
        ActivityCounts(
          upcomingAppointments: (data['upcoming_appointments'] as num?)?.toInt() ?? 0,
          scheduledLabTests: (data['scheduled_lab_tests'] as num?)?.toInt() ?? 0,
          activeOrders: (data['active_orders'] as num?)?.toInt() ?? 0,
        ),
      );
    } on DioException catch (e) {
      log.e('getCounts failed', error: e);
      return Failure(e.response?.data?['message']?.toString() ??
            'Failed to fetch activity counts',
        statusCode: e.response?.statusCode,
      );
    } catch (e) {
      return Failure(e.toString());
    }
  }

  // No longer needed — counts extracted from list length
}
