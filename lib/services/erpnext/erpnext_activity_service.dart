import 'package:dio/dio.dart';
import 'package:intl/intl.dart';

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
      final today = DateFormat('yyyy-MM-dd').format(DateTime.now());

      // Count upcoming appointments
      final apptResponse = await _api.dio.get(
        '/resource/Patient Appointment',
        queryParameters: {
          'filters': '[["patient","=","$patientId"],["appointment_date",">=","$today"],["status","=","Open"]]',
          'fields': '["name"]',
          'limit_page_length': 100,
        },
      );
      final appointments = (apptResponse.data?['data'] as List?)?.length ?? 0;

      // Count scheduled lab tests
      final labResponse = await _api.dio.get(
        '/resource/Lab Test',
        queryParameters: {
          'filters': '[["patient","=","$patientId"],["docstatus","=",0]]',
          'fields': '["name"]',
          'limit_page_length': 100,
        },
      );
      final labTests = (labResponse.data?['data'] as List?)?.length ?? 0;

      // Count active medication orders (if doctype exists)
      int orders = 0;
      try {
        final orderResponse = await _api.dio.get(
          '/resource/Medication Request',
          queryParameters: {
            'filters': '[["patient","=","$patientId"],["status","=","Pending"]]',
            'fields': '["name"]',
            'limit_page_length': 100,
          },
        );
        orders = (orderResponse.data?['data'] as List?)?.length ?? 0;
      } catch (_) {
        // Medication Request doctype may not exist — that's fine
      }

      return Success(
        ActivityCounts(
          upcomingAppointments: appointments,
          scheduledLabTests: labTests,
          activeOrders: orders,
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
