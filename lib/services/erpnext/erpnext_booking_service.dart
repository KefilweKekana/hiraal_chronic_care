import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/network/api_client.dart';
import '../../core/utils/app_logger.dart';
import '../../core/utils/result.dart';
import '../../models/medicine_order.dart';
import '../../models/telemedicine_session.dart';
import '../booking_service.dart';

/// ERPNext implementation of [BookingService].
///
/// via the Frappe REST API.
class ErpNextBookingService implements BookingService {
  final ApiClient _api;
  String _patientId;

  ErpNextBookingService(this._api, {required String patientId})
      : _patientId = patientId;

  set patientId(String id) => _patientId = id;

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
    String? careStation,
  }) async {
    try {
      final response = await _api.dio.post(
        '/method/hiraal_emr.api.book_appointment',
        data: {
          'patient': _patientId,
          // Required positionally server-side; '' means no preference.
          'practitioner': practitioner ?? '',
          'appointment_type': doctorType,
          'appointment_date': date.toIso8601String().substring(0, 10),
          'appointment_time': timeSlot,
          if (reason != null && reason.isNotEmpty) 'notes': reason,
          'is_video': isVideoCall ? 1 : 0,
          if (!isVideoCall &&
              careStation != null &&
              careStation.isNotEmpty)
            'care_station': careStation,
        },
      );
      final msg = response.data?['message'] as Map<String, dynamic>?;
      final docname = msg?['appointment']?.toString();
      if (msg?['success'] == true && docname != null) return Success(docname);
      return const Failure('Booking failed');
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
      // The endpoint only accepts (patient, template, practitioner, note), so
      // the preferred date and collection location travel inside the note.
      final note = 'Preferred date: '
          '${preferredDate.toIso8601String().substring(0, 10)}. '
          'Collection: $location';
      // Create one Lab Test per template selected, tracking each outcome so a
      // partial failure only reports the templates that actually failed.
      String? lastCreated;
      final failed = <String>[];
      for (final template in tests) {
        try {
          final response = await _api.dio.post(
            '/method/hiraal_emr.api.request_lab_test',
            data: {'patient': _patientId, 'template': template, 'note': note},
          );
          final msg = response.data?['message'] as Map<String, dynamic>?;
          if (msg?['success'] == true) {
            lastCreated = msg?['lab_test']?.toString();
          } else {
            failed.add(template);
          }
        } catch (e) {
          log.e('requestLabTest failed for $template', error: e);
          failed.add(template);
        }
      }
      if (failed.isNotEmpty) {
        return Failure('Failed to request: ${failed.join(', ')}');
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
    required List<MedicineLine> medicines,
    required String deliveryAddress,
  }) async {
    try {
      final items = medicines
          .where((m) => m.name.trim().isNotEmpty)
          .map((m) => {
                'name': m.name.trim(),
                'quantity': m.quantity,
                if (m.dosage != null && m.dosage!.trim().isNotEmpty) 'dosage': m.dosage,
              })
          .toList();
      final response = await _api.dio.post(
        '/method/hiraal_emr.api.order_medicine',
        data: {
          'patient': _patientId,
          'items': jsonEncode(items),
          if (deliveryAddress.isNotEmpty) 'delivery_address': deliveryAddress,
        },
      );

      final msg = response.data?['message'] as Map<String, dynamic>?;
      final name = msg?['order']?.toString() ?? '';
      if (msg?['success'] == true && name.isNotEmpty) {
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
  Future<Result<String>> orderWithPrescription({
    required String imagePath,
    String? deliveryAddress,
    String? note,
  }) async {
    try {
      // 1) Create the order shell (status "Received").
      final created = await _api.dio.post(
        '/method/hiraal_emr.api.order_medicine',
        data: {
          'patient': _patientId,
          if (deliveryAddress != null && deliveryAddress.isNotEmpty)
            'delivery_address': deliveryAddress,
          if (note != null && note.isNotEmpty) 'note': note,
        },
      );
      final createdMsg = created.data?['message'] as Map<String, dynamic>?;
      final orderId = createdMsg?['order']?.toString() ?? '';
      if (createdMsg?['success'] != true || orderId.isEmpty) {
        return const Failure('Could not create your order');
      }

      // 2) Attach the prescription image (base64).
      // XFile works on web too, where dart:io File cannot read blob URLs.
      final bytes = await XFile(imagePath).readAsBytes();
      final filename = imagePath.split(RegExp(r'[\\/]')).last;
      final attached = await _api.dio.post(
        '/method/hiraal_emr.api.attach_my_prescription',
        data: {
          'order': orderId,
          'filename': filename,
          'content_base64': base64Encode(bytes),
        },
      );
      final attachedMsg = attached.data?['message'] as Map<String, dynamic>?;
      if (attachedMsg?['success'] != true) {
        // The order exists but the image didn't attach — surface it so the
        // patient can retry the upload rather than silently losing it.
        return Failure('Order $orderId created but the prescription failed to upload');
      }
      return Success(orderId);
    } on DioException catch (e) {
      log.e('orderWithPrescription failed', error: e);
      return Failure(
        _parseServerError(e.response?.data, 'Could not upload your prescription'),
        statusCode: e.response?.statusCode,
      );
    } catch (e) {
      return Failure(e.toString());
    }
  }

  @override
  Future<Result<void>> confirmOrderReceived(String orderId) async {
    try {
      await _api.dio.post(
        '/method/hiraal_emr.api.confirm_my_order_received',
        data: {'order': orderId},
      );
      return const Success(null);
    } on DioException catch (e) {
      log.e('confirmOrderReceived failed', error: e);
      return Failure(
        _parseServerError(e.response?.data, 'Could not confirm receipt'),
        statusCode: e.response?.statusCode,
      );
    } catch (e) {
      return Failure(e.toString());
    }
  }

  @override
  Future<Result<List<MedicineOrder>>> getMyOrders() async {
    try {
      final response =
          await _api.dio.post('/method/hiraal_emr.api.get_my_orders');
      final list = response.data?['message'] as List? ?? [];
      final orders = list
          .whereType<Map>()
          .map((e) => MedicineOrder.fromJson(Map<String, dynamic>.from(e)))
          .toList();
      return Success(orders);
    } on DioException catch (e) {
      log.e('getMyOrders failed', error: e);
      return Failure(
        _parseServerError(e.response?.data, 'Failed to load your orders'),
        statusCode: e.response?.statusCode,
      );
    } catch (e) {
      return Failure(e.toString());
    }
  }

  @override
  Future<Result<List<AppointmentInfo>>> getMyAppointments() async {
    try {
      final response =
          await _api.dio.post('/method/hiraal_emr.api.get_my_appointments');
      final list = response.data?['message'] as List? ?? [];
      final appointments = list
          .whereType<Map>()
          .map((e) => AppointmentInfo.fromJson(Map<String, dynamic>.from(e)))
          .toList();
      return Success(appointments);
    } on DioException catch (e) {
      log.e('getMyAppointments failed', error: e);
      return Failure(
        _parseServerError(e.response?.data, 'Failed to load your appointments'),
        statusCode: e.response?.statusCode,
      );
    } catch (e) {
      return Failure(e.toString());
    }
  }

  @override
  Future<Result<List<LabTestInfo>>> getMyLabTests() async {
    try {
      final response =
          await _api.dio.post('/method/hiraal_emr.api.get_my_lab_tests');
      final list = response.data?['message'] as List? ?? [];
      final tests = list
          .whereType<Map>()
          .map((e) => LabTestInfo.fromJson(Map<String, dynamic>.from(e)))
          .toList();
      return Success(tests);
    } on DioException catch (e) {
      log.e('getMyLabTests failed', error: e);
      return Failure(
        _parseServerError(e.response?.data, 'Failed to load your lab tests'),
        statusCode: e.response?.statusCode,
      );
    } catch (e) {
      return Failure(e.toString());
    }
  }

  @override
  Future<Result<void>> cancelMyLabTest(String labTestId) async {
    try {
      await _api.dio.post(
        '/method/hiraal_emr.api.cancel_my_lab_test',
        data: {'name': labTestId},
      );
      return const Success(null);
    } on DioException catch (e) {
      log.e('cancelMyLabTest failed', error: e);
      return Failure(
        _parseServerError(e.response?.data, 'Could not cancel the lab test'),
        statusCode: e.response?.statusCode,
      );
    } catch (e) {
      return Failure(e.toString());
    }
  }

  @override
  Future<Result<void>> endVideoVisit(String sessionId) async {
    try {
      await _api.dio.post(
        '/method/hiraal_emr.api.complete_telemedicine_session',
        data: {'name': sessionId},
      );
      return const Success(null);
    } on DioException catch (e) {
      log.e('endVideoVisit failed', error: e);
      return Failure(
        _parseServerError(e.response?.data, 'Could not end the visit'),
        statusCode: e.response?.statusCode,
      );
    } catch (e) {
      return Failure(e.toString());
    }
  }

  @override
  Future<Result<List<TelemedicineSession>>> getMyVideoVisits() async {
    try {
      final response =
          await _api.dio.post('/method/hiraal_emr.api.get_my_telemedicine_sessions');
      final list = response.data?['message'] as List? ?? [];
      final sessions = list
          .whereType<Map>()
          .map((e) => TelemedicineSession.fromJson(Map<String, dynamic>.from(e)))
          .toList();
      return Success(sessions);
    } on DioException catch (e) {
      log.e('getMyVideoVisits failed', error: e);
      return Failure(
        _parseServerError(e.response?.data, 'Failed to load your video visits'),
        statusCode: e.response?.statusCode,
      );
    } catch (e) {
      return Failure(e.toString());
    }
  }

  @override
  Future<Result<void>> notifyJoiningVideoVisit(String sessionId) async {
    try {
      await _api.dio.post(
        '/method/hiraal_emr.api.join_my_telemedicine_session',
        data: {'name': sessionId},
      );
      return const Success(null);
    } on DioException catch (e) {
      log.e('notifyJoiningVideoVisit failed', error: e);
      return Failure(
        _parseServerError(e.response?.data, 'Could not alert the care team'),
        statusCode: e.response?.statusCode,
      );
    } catch (e) {
      return Failure(e.toString());
    }
  }

  @override
  Future<Result<void>> cancelMedicineOrder(String orderId, {String? reason}) async {
    try {
      await _api.dio.post(
        '/method/hiraal_emr.api.cancel_my_order',
        data: {'name': orderId, if (reason != null) 'reason': reason},
      );
      return const Success(null);
    } on DioException catch (e) {
      log.e('cancelMedicineOrder failed', error: e);
      return Failure(
        _parseServerError(e.response?.data, 'Failed to cancel order'),
        statusCode: e.response?.statusCode,
      );
    } catch (e) {
      return Failure(e.toString());
    }
  }

  @override
  Future<Result<List<Map<String, dynamic>>>> getLabTestTemplates() async {
    try {
      final response =
          await _api.dio.post('/method/hiraal_emr.api.get_lab_test_templates');
      final list = response.data?['message'] as List? ?? [];
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
      final response =
          await _api.dio.post('/method/hiraal_emr.api.get_doctors');
      final list = response.data?['message'] as List? ?? [];
      return Success(list.cast<Map<String, dynamic>>());
    } on DioException catch (e) {
      log.e('getDoctors failed', error: e);
      return Failure(e.response?.data?['message']?.toString() ?? 'Failed to fetch doctors');
    } catch (e) {
      return Failure(e.toString());
    }
  }

  @override
  Future<Result<List<Map<String, dynamic>>>> getCareStations() async {
    try {
      final response =
          await _api.dio.post('/method/hiraal_emr.api.get_care_stations');
      final list = response.data?['message'] as List? ?? [];
      return Success(
        list
            .whereType<Map>()
            .map((e) => Map<String, dynamic>.from(e))
            .toList(),
      );
    } on DioException catch (e) {
      log.e('getCareStations failed', error: e);
      return Failure(
        e.response?.data?['message']?.toString() ??
            'Failed to fetch care stations',
      );
    } catch (e) {
      return Failure(e.toString());
    }
  }
}
