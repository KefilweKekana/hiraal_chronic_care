import '../../core/utils/result.dart';
import '../../models/medicine_order.dart';
import '../../models/telemedicine_session.dart';

/// A patient's upcoming appointment, mirroring the server "Patient
/// Appointment" doctype — summary for the home 'Next appointment' card.
class AppointmentInfo {
  final String id;
  final String practitionerName;
  final DateTime date;
  final String time;
  final String status;
  final String type;

  const AppointmentInfo({
    required this.id,
    required this.practitionerName,
    required this.date,
    this.time = '',
    this.status = '',
    this.type = '',
  });

  factory AppointmentInfo.fromJson(Map<String, dynamic> j) => AppointmentInfo(
        id: (j['name'] ?? '').toString(),
        practitionerName:
            (j['practitioner_name'] ?? j['practitioner'] ?? '').toString(),
        date: DateTime.tryParse('${j['appointment_date'] ?? ''}') ??
            DateTime.now(),
        time: (j['appointment_time'] ?? '').toString(),
        status: (j['status'] ?? '').toString(),
        type: (j['appointment_type'] ?? '').toString(),
      );
}

/// A patient's lab test, mirroring the server "Lab Test" doctype — for the
/// 'My Lab Tests' screen behind the profile activity card.
class LabTestInfo {
  final String id;
  final String template;
  final String status;
  final DateTime? created;
  final DateTime? resultDate;

  const LabTestInfo({
    required this.id,
    required this.template,
    this.status = '',
    this.created,
    this.resultDate,
  });

  factory LabTestInfo.fromJson(Map<String, dynamic> j) => LabTestInfo(
        id: (j['name'] ?? '').toString(),
        template: (j['template'] ?? '').toString(),
        status: (j['status'] ?? '').toString(),
        created: DateTime.tryParse('${j['creation'] ?? ''}'),
        resultDate: DateTime.tryParse('${j['result_date'] ?? ''}'),
      );
}

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
    String? careStation,
  });

  /// Request a lab test.
  Future<Result<String>> requestLabTest({
    required List<String> tests,
    required DateTime preferredDate,
    required String location,
  });

  /// Order medicine refill. Returns the new order id on success.
  Future<Result<String>> orderMedicine({
    required List<MedicineLine> medicines,
    required String deliveryAddress,
  });

  /// Upload a prescription image to start a pharmacy order. Creates the order
  /// (status "Received") and attaches the prescription. Returns the order id.
  Future<Result<String>> orderWithPrescription({
    required String imagePath,
    String? deliveryAddress,
    String? note,
  });

  /// The logged-in patient's medicine orders, newest first, with live status.
  Future<Result<List<MedicineOrder>>> getMyOrders();

  /// Cancel one of the patient's own orders (while still cancellable).
  Future<Result<void>> cancelMedicineOrder(String orderId, {String? reason});

  /// Patient confirms they received a delivered order.
  Future<Result<void>> confirmOrderReceived(String orderId);

  /// The logged-in patient's upcoming appointments, soonest first.
  Future<Result<List<AppointmentInfo>>> getMyAppointments();

  /// The logged-in patient's lab tests, newest first.
  Future<Result<List<LabTestInfo>>> getMyLabTests();

  /// Cancel one of the patient's own lab tests (before sample collection).
  Future<Result<void>> cancelMyLabTest(String labTestId);

  /// The logged-in patient's telemedicine (video) visits, newest first.
  Future<Result<List<TelemedicineSession>>> getMyVideoVisits();

  /// Tell the server the patient is joining this video visit so the assigned
  /// doctor is alerted (in-app + SMS). Best-effort; ignore failures.
  Future<Result<void>> notifyJoiningVideoVisit(String sessionId);

  /// Mark the patient's own video visit finished (server sets it Completed,
  /// stamps the end time, and records the duration).
  Future<Result<void>> endVideoVisit(String sessionId);

  Future<Result<List<Map<String, dynamic>>>> getDoctors();

  /// Active care stations (clinic locations) for in-person booking.
  Future<Result<List<Map<String, dynamic>>>> getCareStations();

  Future<Result<List<Map<String, dynamic>>>> getLabTestTemplates();
}
