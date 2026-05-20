import '../../core/utils/result.dart';

/// Contract for appointment / service booking operations.
abstract class BookingService {
  /// Book a doctor appointment.
  Future<Result<String>> bookDoctor({
    required String doctorType,
    required DateTime date,
    required String timeSlot,
    String? reason,
    String? practitioner,
    bool isVideoCall = false,
  });

  /// Request a lab test.
  Future<Result<String>> requestLabTest({
    required List<String> tests,
    required DateTime preferredDate,
    required String location,
  });

  /// Order medicine refill.
  Future<Result<String>> orderMedicine({
    required List<String> medications,
    required String deliveryAddress,
  });

  Future<Result<List<Map<String, dynamic>>>> getDoctors();

  Future<Result<List<Map<String, dynamic>>>> getLabTestTemplates();
}
