import '../../core/utils/result.dart';
import '../booking_service.dart';

/// Mock booking service that always succeeds.
class MockBookingService implements BookingService {
  @override
  Future<Result<String>> bookDoctor({
    required String doctorType,
    required DateTime date,
    required String timeSlot,
    String? reason,
    String? practitioner,
    bool isVideoCall = false,
  }) async {
    await Future.delayed(const Duration(milliseconds: 500));
    return Success('MOCK-BOOKING-123');
  }

  @override
  Future<Result<String>> requestLabTest({
    required List<String> tests,
    required DateTime preferredDate,
    required String location,
  }) async {
    await Future.delayed(const Duration(seconds: 1));
    return const Success('LAB-2024-001');
  }

  @override
  Future<Result<String>> orderMedicine({
    required List<String> medications,
    required String deliveryAddress,
  }) async {
    await Future.delayed(const Duration(seconds: 1));
    return const Success('MED-2024-001');
  }

  @override
  Future<Result<List<Map<String, dynamic>>>> getLabTestTemplates() async {
    return Success([
      {'name': 'CBC', 'lab_test_name': 'CBC', 'lab_test_group': 'Laboratory', 'department': 'laboratory'},
      {'name': 'Blood Sugar FBS', 'lab_test_name': 'Blood Sugar FBS', 'lab_test_group': 'Laboratory', 'department': 'laboratory'},
      {'name': 'Creatinine', 'lab_test_name': 'Creatinine', 'lab_test_group': 'Laboratory', 'department': 'laboratory'},
    ]);
  }

  @override
  Future<Result<List<Map<String, dynamic>>>> getDoctors() async {
    return Success([
      {'name': 'Dr. Omer', 'practitioner_name': 'Dr. Omer Yusuf', 'department': 'General Surgery'},
      {'name': 'Dr. Dinah', 'practitioner_name': 'Dr. Dinah', 'department': 'PHYSIOTHERAPY'},
    ]);
  }
}
