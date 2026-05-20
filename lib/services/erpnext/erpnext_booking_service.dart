import 'dart:convert';
import 'package:dio/dio.dart';

import '../../core/network/api_client.dart';
import '../../core/utils/app_logger.dart';
import '../../core/utils/result.dart';
import '../booking_service.dart';

/// ERPNext implementation of [BookingService].
///
/// via the Frappe REST API.
class ErpNextBookingService implements BookingService {
  final ApiClient _api;
  String _patientId;
  String? _patientSex;

  ErpNextBookingService(this._api, {required String patientId})
      : _patientId = patientId;

  set patientId(String id) => _patientId = id;
  set patientSex(String sex) => _patientSex = sex;

  /// Extract a human-readable message from Frappe's _server_messages JSON.
  String _parseServerError(dynamic responseData, String fallback) {
    try {
      final raw = responseData?['_server_messages']?.toString();
      if (raw != null && raw.isNotEmpty) {
        final List msgs = json.decode(raw);
        if (msgs.isNotEmpty) {
          final inner = json.decode(msgs.first.toString());
          final msg = inner['message']?.toString() ?? '';
          // Strip HTML tags
          return msg.replaceAll(RegExp(r'<[^>]*>'), '');
        }
      }
      return responseData?['message']?.toString() ?? fallback;
    } catch (_) {
      return responseData?['message']?.toString() ?? fallback;
    }
  }

  @override
  Future<Result<String>> bookDoctor({
    required String doctorType,
    required DateTime date,
    required String timeSlot,
    String? reason,
    String? practitioner,
    bool isVideoCall = false,
  }) async {
    try {
      final payload = {
        'appointment_for': 'Practitioner',
        'patient': _patientId,
        'appointment_date': date.toIso8601String().substring(0, 10),
        'appointment_time': timeSlot,
        if (reason != null && reason.isNotEmpty) 'notes': reason,
        if (practitioner != null) 'practitioner': practitioner,
        if (doctorType.isNotEmpty) 'department': doctorType,
        if (isVideoCall) 'add_video_conferencing': 1,
      };
      final response = await _api.dio.post(
        '/resource/Patient Appointment',
        data: payload,
      );
      final docname = response.data?['data']?['name']?.toString();
      if (docname != null) return Success(docname);
      return Failure('Booking failed');
    } on DioException catch (e) {
      log.e('bookDoctor failed', error: e);
      return Failure(
        _parseServerError(e.response?.data, 'Booking failed'),
        statusCode: e.response?.statusCode,
      );
    } catch (e) {
      return Failure(e.toString());
    }
  }

  @override
  Future<Result<String>> requestLabTest({
    required List<String> tests,
    required DateTime preferredDate,
    required String location,
  }) async {
    try {
      // Create one Lab Test per template selected
      String? lastCreated;
      for (final template in tests) {
        final response = await _api.dio.post(
          '/resource/Lab Test',
          data: {
            'patient': _patientId,
            'template': template,
            'company': 'HALDOOR HOSPITAL',
            if (_patientSex != null) 'patient_sex': _patientSex,
          },
        );
        lastCreated = response.data?['data']?['name']?.toString();
      }
      if (lastCreated != null && lastCreated.isNotEmpty) {
        return Success(lastCreated);
      }
      return const Failure('Failed to request lab test');
    } on DioException catch (e) {
      log.e('requestLabTest failed', error: e);
      return Failure(
        _parseServerError(e.response?.data, 'Failed to request lab test'),
        statusCode: e.response?.statusCode,
      );
    } catch (e) {
      return Failure(e.toString());
    }
  }

  @override
  Future<Result<String>> orderMedicine({
    required List<String> medications,
    required String deliveryAddress,
  }) async {
    try {
      // Use a custom doctype or Frappe's standard if available
      final response = await _api.dio.post(
        '/resource/Medication Request',
        data: {
          'patient': _patientId,
          'medications': medications.join(', '),
          'delivery_address': deliveryAddress,
          'status': 'Pending',
        },
      );

      final name = response.data?['data']?['name']?.toString() ?? '';
      if (name.isNotEmpty) {
        return Success(name);
      }
      return const Failure('Failed to order medicine');
    } on DioException catch (e) {
      log.e('orderMedicine failed', error: e);
      return Failure(
        _parseServerError(e.response?.data, 'Failed to order medicine'),
        statusCode: e.response?.statusCode,
      );
    } catch (e) {
      return Failure(e.toString());
    }
  }

  @override
  Future<Result<List<Map<String, dynamic>>>> getLabTestTemplates() async {
    try {
      final response = await _api.dio.get(
        '/resource/Lab Test Template',
        queryParameters: {
          'fields': '["name","lab_test_name","lab_test_group","department"]',
          'limit_page_length': 100,
        },
      );
      final list = response.data?['data'] as List? ?? [];
      return Success(list.cast<Map<String, dynamic>>());
    } on DioException catch (e) {
      log.e('getLabTestTemplates failed', error: e);
      return Failure(e.response?.data?['message']?.toString() ?? 'Failed to fetch lab test templates');
    } catch (e) {
      return Failure(e.toString());
    }
  }

  @override
  Future<Result<List<Map<String, dynamic>>>> getDoctors() async {
    try {
      final response = await _api.dio.get(
        '/resource/Healthcare Practitioner',
        queryParameters: {
          'fields': '["name","practitioner_name","department"]',
          'limit_page_length': 50,
        },
      );
      final list = response.data?['data'] as List? ?? [];
      return Success(list.cast<Map<String, dynamic>>());
    } on DioException catch (e) {
      log.e('getDoctors failed', error: e);
      return Failure(e.response?.data?['message']?.toString() ?? 'Failed to fetch doctors');
    } catch (e) {
      return Failure(e.toString());
    }
  }
}
