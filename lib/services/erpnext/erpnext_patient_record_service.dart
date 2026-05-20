import 'package:dio/dio.dart';

import '../../core/network/api_client.dart';
import '../../core/utils/app_logger.dart';
import '../../core/utils/result.dart';
import '../patient_record_service.dart';

/// ERPNext implementation of [PatientRecordService].
///
/// Reads **Patient Encounter** records from ERPNext Healthcare.
class ErpNextPatientRecordService implements PatientRecordService {
  final ApiClient _api;

  ErpNextPatientRecordService(this._api);

  @override
  Future<Result<List<MedicalRecord>>> getRecords(String patientId) async {
    try {
      final response = await _api.dio.get(
        '/resource/Patient Encounter',
        queryParameters: {
          'filters': '[["patient","=","$patientId"]]',
          'fields':
              '["name","encounter_date","encounter_type","practitioner_name","diagnosis","medical_department"]',
          'order_by': 'encounter_date desc',
          'limit_page_length': 50,
        },
      );

      final list = response.data?['data'] as List? ?? [];
      final records = list
          .cast<Map<String, dynamic>>()
          .map(_fromEncounter)
          .toList();
      return Success(records);
    } on DioException catch (e) {
      log.e('getRecords failed', error: e);
      return Failure(e.response?.data?['message']?.toString() ??
            'Failed to fetch records',
        statusCode: e.response?.statusCode,
      );
    } catch (e) {
      return Failure(e.toString());
    }
  }

  MedicalRecord _fromEncounter(Map<String, dynamic> json) {
    final encounterType =
        (json['encounter_type'] ?? 'checkup').toString().toLowerCase();
    String type;
    if (encounterType.contains('diagnosis')) {
      type = 'diagnosis';
    } else if (encounterType.contains('procedure')) {
      type = 'procedure';
    } else if (encounterType.contains('enrol')) {
      type = 'enrollment';
    } else {
      type = 'checkup';
    }

    return MedicalRecord(
      id: json['name']?.toString() ?? '',
      date: json['encounter_date']?.toString() ?? '',
      title: json['encounter_type']?.toString() ?? 'Consultation',
      subtitle:
          '${json['practitioner_name'] ?? ''} — ${json['medical_department'] ?? ''}'
              .trim(),
      type: type,
    );
  }
}
