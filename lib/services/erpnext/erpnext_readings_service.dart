import 'package:dio/dio.dart';
import 'package:intl/intl.dart';

import '../../core/database/readings_dao.dart';
import '../../core/network/api_client.dart';
import '../../core/utils/app_logger.dart';
import '../../core/utils/result.dart';
import '../../models/vital_reading.dart';
import '../readings_service.dart';

/// ERPNext implementation of [ReadingsService].
///
/// Maps app [VitalReading] ↔ ERPNext **Vital Signs** doctype.
/// Uses Frappe REST API: `/api/resource/Vital Signs`.
class ErpNextReadingsService implements ReadingsService {
  final ApiClient _api;

  ErpNextReadingsService(this._api);

  @override
  Future<Result<VitalReading>> submitReading(VitalReading reading) async {
    try {
      // Session-scoped server method resolves the patient from the login and
      // stores a hiraal_emr "Daily Reading".
      final response = await _api.dio.post(
        '/method/hiraal_emr.api.submit_reading',
        data: {
          'bp_systolic': reading.systolic,
          'bp_diastolic': reading.diastolic,
          'blood_sugar': reading.bloodSugar,
          'weight': reading.weight,
          if (reading.medicineTaken != null)
            'medicine_taken': reading.medicineTaken! ? 'Yes' : 'No',
          'note': reading.note,
          'source': reading.source,
          // Server dedupes by this id, so offline retries never duplicate.
          if ((reading.referenceId ?? '').isNotEmpty) 'reference_id': reading.referenceId,
          // Preserve the original measurement time on (offline) resubmission.
          'reading_date': DateFormat('yyyy-MM-dd').format(reading.date),
          'reading_time': DateFormat('HH:mm:ss').format(reading.date),
        },
      );

      final data = response.data?['message'] as Map<String, dynamic>?;
      if (data != null && data['success'] == true) {
        // Mark synced locally so the background sync never re-sends it.
        await ReadingsDao().markSyncedByReference(
          reading.referenceId,
          serverId: data['reference_id']?.toString(),
        );
        return Success(reading);
      }
      return const Failure('Failed to submit reading');
    } on DioException catch (e) {
      log.e('submitReading failed', error: e);
      return Failure(e.response?.data?['message']?.toString() ??
            'Failed to submit reading',
        statusCode: e.response?.statusCode,
      );
    } catch (e) {
      return Failure(e.toString());
    }
  }

  @override
  Future<Result<List<VitalReading>>> getReadings({int? limit}) async {
    try {
      // Scoped server endpoint returns the logged-in patient's Daily Readings.
      final response = await _api.dio.post(
        '/method/hiraal_emr.api.get_my_readings',
        data: {'limit': limit ?? 60},
      );

      final list = response.data?['message'] as List? ?? [];
      final readings = list
          .cast<Map<String, dynamic>>()
          .map(_fromDailyReading)
          .toList();
      return Success(readings);
    } on DioException catch (e) {
      log.e('getReadings failed', error: e);
      return Failure(e.response?.data?['message']?.toString() ??
            'Failed to fetch readings',
        statusCode: e.response?.statusCode,
      );
    } catch (e) {
      return Failure(e.toString());
    }
  }

  @override
  Future<Result<int>> syncPendingReadings(List<VitalReading> readings) async {
    int synced = 0;
    for (final reading in readings) {
      final result = await submitReading(reading);
      if (result.isSuccess) synced++;
    }
    return Success(synced);
  }

  /// Maps a hiraal_emr "Daily Reading" document → app [VitalReading].
  VitalReading _fromDailyReading(Map<String, dynamic> json) {
    DateTime date;
    try {
      final d = json['reading_date']?.toString() ?? '';
      final t = json['reading_time']?.toString() ?? '00:00:00';
      date = DateTime.parse('${d}T$t');
    } catch (_) {
      date = DateTime.now();
    }

    return VitalReading(
      id: json['name']?.toString(),
      referenceId: (json['reference_id'] ?? json['name'])?.toString(),
      date: date,
      systolic: _toInt(json['bp_systolic']),
      diastolic: _toInt(json['bp_diastolic']),
      bloodSugar: _toDouble(json['blood_sugar']),
      weight: _toDouble(json['weight']),
      medicineTaken: json['medicine_taken'] == null
          ? null
          : json['medicine_taken'].toString() == 'Yes',
      note: json['patient_note']?.toString(),
      source: json['source']?.toString() ?? 'ERPNext',
      syncStatus: 'Synced',
      status: 'Sent',
    );
  }

  int? _toInt(dynamic v) {
    if (v == null) return null;
    if (v is int) return v;
    if (v is double) return v.toInt();
    return int.tryParse(v.toString());
  }

  double? _toDouble(dynamic v) {
    if (v == null) return null;
    if (v is double) return v;
    if (v is int) return v.toDouble();
    return double.tryParse(v.toString());
  }
}
