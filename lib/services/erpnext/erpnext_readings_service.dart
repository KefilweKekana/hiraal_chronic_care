import 'package:dio/dio.dart';

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
      final response = await _api.dio.post(
        '/resource/Vital Signs',
        data: {
          'patient': reading.note, // patient ID stored in note temporarily
          'signs_date': reading.date.toIso8601String().split('T').first,
          'signs_time':
              '${reading.date.hour.toString().padLeft(2, '0')}:${reading.date.minute.toString().padLeft(2, '0')}:00',
          'systolic': reading.systolic,
          'diastolic': reading.diastolic,
          'blood_sugar_fasting': reading.bloodSugar,
          'pulse': null,
          'temperature': null,
          'vital_signs_note': reading.note,
        },
      );

      final data = response.data?['data'] as Map<String, dynamic>?;
      if (data != null) {
        return Success(_fromVitalSigns(data));
      }
      return const Failure('No data returned');
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
      final response = await _api.dio.get(
        '/resource/Vital Signs',
        queryParameters: {
          'fields':
              '["name","patient","signs_date","signs_time","systolic","diastolic","blood_sugar_fasting","pulse","temperature","respiratory_rate","oxygen_saturation","weight","height","bmi","vital_signs_note","docstatus"]',
          'order_by': 'signs_date desc, signs_time desc',
          'limit_page_length': limit ?? 50,
        },
      );

      final list = response.data?['data'] as List? ?? [];
      final readings = list
          .cast<Map<String, dynamic>>()
          .map(_fromVitalSigns)
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

  /// Maps an ERPNext Vital Signs document → app [VitalReading].
  VitalReading _fromVitalSigns(Map<String, dynamic> json) {
    DateTime date;
    try {
      final d = json['signs_date']?.toString() ?? '';
      final t = json['signs_time']?.toString() ?? '00:00:00';
      date = DateTime.parse('${d}T$t');
    } catch (_) {
      date = DateTime.now();
    }

    return VitalReading(
      id: json['name']?.toString(),
      referenceId: json['name']?.toString(),
      date: date,
      systolic: _toInt(json['systolic']),
      diastolic: _toInt(json['diastolic']),
      bloodSugar: _toDouble(json['blood_sugar_fasting']),
      note: json['vital_signs_note']?.toString(),
      source: 'ERPNext',
      syncStatus: 'Synced',
      status: json['docstatus'] == 1 ? 'Sent' : 'Pending',
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
