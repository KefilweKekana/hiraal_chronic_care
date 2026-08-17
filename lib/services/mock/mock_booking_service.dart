import '../../core/utils/result.dart';
import '../../models/medicine_order.dart';
import '../../models/telemedicine_session.dart';
import '../booking_service.dart';

/// Mock booking service that always succeeds.
class MockBookingService implements BookingService {
  final List<MedicineOrder> _orders = [];
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
    required List<MedicineLine> medicines,
    required String deliveryAddress,
  }) async {
    await Future.delayed(const Duration(seconds: 1));
    final id = 'MED-${1000 + _orders.length}';
    _orders.insert(
      0,
      MedicineOrder(
        id: id,
        status: 'Received',
        totalItems: medicines.length,
        deliveryType: 'Delivery',
        deliveryAddress: deliveryAddress,
        createdAt: DateTime.now(),
        cancellable: true,
        estimatedDelivery: DateTime.now().add(const Duration(days: 1)),
        medicines: medicines,
      ),
    );
    return Success(id);
  }

  @override
  Future<Result<String>> orderWithPrescription({
    required String imagePath,
    String? deliveryAddress,
    String? note,
  }) async {
    await Future.delayed(const Duration(seconds: 1));
    final id = 'MED-${1000 + _orders.length}';
    _orders.insert(
      0,
      MedicineOrder(
        id: id,
        status: 'Received',
        totalItems: 0,
        deliveryType: 'Delivery',
        deliveryAddress: deliveryAddress,
        prescription: imagePath,
        pharmacistNote: note,
        createdAt: DateTime.now(),
        cancellable: true,
        medicines: const [],
      ),
    );
    return Success(id);
  }

  @override
  Future<Result<void>> confirmOrderReceived(String orderId) async {
    await Future.delayed(const Duration(milliseconds: 400));
    final i = _orders.indexWhere((o) => o.id == orderId);
    if (i >= 0) {
      final o = _orders[i];
      _orders[i] = MedicineOrder(
        id: o.id,
        status: o.status,
        priority: o.priority,
        totalItems: o.totalItems,
        deliveryType: o.deliveryType,
        deliveryAddress: o.deliveryAddress,
        estimatedDelivery: o.estimatedDelivery,
        preparationStarted: o.preparationStarted,
        dispatchedAt: o.dispatchedAt,
        deliveredAt: o.deliveredAt,
        paymentMethod: o.paymentMethod,
        paymentStatus: o.paymentStatus,
        paymentReference: o.paymentReference,
        amount: o.amount,
        deliveryFee: o.deliveryFee,
        tax: o.tax,
        total: o.total,
        prescription: o.prescription,
        receivedConfirmed: true,
        pharmacistNote: o.pharmacistNote,
        cancellationReason: o.cancellationReason,
        createdAt: o.createdAt,
        cancellable: o.cancellable,
        payable: o.payable,
        medicines: o.medicines,
      );
    }
    return const Success(null);
  }

  @override
  Future<Result<List<MedicineOrder>>> getMyOrders() async {
    await Future.delayed(const Duration(milliseconds: 400));
    if (_orders.isEmpty) {
      // Seed a couple of orders so the tracking UI has something to show.
      _orders.addAll([
        MedicineOrder(
          id: 'MED-1043',
          status: 'Awaiting Payment',
          totalItems: 2,
          deliveryType: 'Delivery',
          deliveryAddress: 'Hargeisa, Somaliland',
          createdAt: DateTime.now().subtract(const Duration(hours: 4)),
          paymentStatus: 'Unpaid',
          payable: true,
          cancellable: true,
          amount: 14.0,
          deliveryFee: 2.0,
          tax: 0.0,
          total: 16.0,
          medicines: const [
            MedicineLine(
                name: 'Amlodipine 5mg',
                quantity: 1,
                dosage: 'Once daily',
                unitPrice: 6.0,
                totalPrice: 6.0),
            MedicineLine(
                name: 'Metformin 500mg',
                quantity: 2,
                dosage: 'Twice daily',
                unitPrice: 4.0,
                totalPrice: 8.0),
          ],
        ),
        MedicineOrder(
          id: 'MED-1042',
          status: 'Out for Delivery',
          totalItems: 2,
          deliveryType: 'Delivery',
          deliveryAddress: 'Hargeisa, Somaliland',
          createdAt: DateTime.now().subtract(const Duration(days: 1)),
          dispatchedAt: DateTime.now().subtract(const Duration(hours: 2)),
          estimatedDelivery: DateTime.now().add(const Duration(hours: 3)),
          paymentMethod: 'Zaad',
          paymentStatus: 'Paid',
          amount: 10.0,
          total: 12.0,
          medicines: const [
            MedicineLine(name: 'Amlodipine 5mg', quantity: 1, dosage: 'Once daily', unitPrice: 6.0, totalPrice: 6.0),
            MedicineLine(name: 'Metformin 500mg', quantity: 1, dosage: 'Twice daily', unitPrice: 4.0, totalPrice: 4.0),
          ],
        ),
        MedicineOrder(
          id: 'MED-1037',
          status: 'Delivered',
          totalItems: 1,
          deliveryType: 'Delivery',
          deliveryAddress: 'Hargeisa, Somaliland',
          createdAt: DateTime.now().subtract(const Duration(days: 6)),
          deliveredAt: DateTime.now().subtract(const Duration(days: 5)),
          paymentMethod: 'Zaad',
          paymentStatus: 'Paid',
          amount: 5.0,
          total: 7.0,
          medicines: const [
            MedicineLine(name: 'Vitamin D3', quantity: 1, dosage: 'Once daily', unitPrice: 5.0, totalPrice: 5.0),
          ],
        ),
      ]);
    }
    return Success(List.unmodifiable(_orders));
  }

  @override
  Future<Result<void>> cancelMedicineOrder(String orderId, {String? reason}) async {
    await Future.delayed(const Duration(milliseconds: 400));
    final i = _orders.indexWhere((o) => o.id == orderId);
    if (i >= 0) {
      final o = _orders[i];
      _orders[i] = MedicineOrder(
        id: o.id,
        status: 'Cancelled',
        priority: o.priority,
        totalItems: o.totalItems,
        deliveryType: o.deliveryType,
        deliveryAddress: o.deliveryAddress,
        estimatedDelivery: o.estimatedDelivery,
        preparationStarted: o.preparationStarted,
        dispatchedAt: o.dispatchedAt,
        deliveredAt: o.deliveredAt,
        paymentMethod: o.paymentMethod,
        paymentStatus: o.paymentStatus,
        paymentReference: o.paymentReference,
        amount: o.amount,
        deliveryFee: o.deliveryFee,
        tax: o.tax,
        total: o.total,
        prescription: o.prescription,
        receivedConfirmed: o.receivedConfirmed,
        pharmacistNote: o.pharmacistNote,
        cancellationReason: reason ?? 'Cancelled by patient',
        createdAt: o.createdAt,
        cancellable: o.cancellable,
        payable: o.payable,
        medicines: o.medicines,
      );
    }
    return const Success(null);
  }

  @override
  Future<Result<void>> endVideoVisit(String sessionId) async {
    await Future.delayed(const Duration(milliseconds: 300));
    return const Success(null);
  }

  @override
  Future<Result<List<AppointmentInfo>>> getMyAppointments() async {
    await Future.delayed(const Duration(milliseconds: 400));
    return Success([
      AppointmentInfo(
        id: 'MOCK-APPT-001',
        practitionerName: 'Dr. Omer Yusuf',
        date: DateTime.now().add(const Duration(days: 2)),
        time: '10:00',
        status: 'Scheduled',
        type: 'Chronic Care Follow Up',
      ),
    ]);
  }

  @override
  Future<Result<List<LabTestInfo>>> getMyLabTests() async {
    await Future.delayed(const Duration(milliseconds: 300));
    return Success([
      LabTestInfo(
        id: 'MOCK-LAB-001',
        template: 'HBA1C',
        status: 'Completed',
        created: DateTime.now().subtract(const Duration(days: 3)),
        resultDate: DateTime.now().subtract(const Duration(days: 2)),
      ),
      LabTestInfo(
        id: 'MOCK-LAB-002',
        template: 'Lipid Profile',
        status: 'Approved',
        created: DateTime.now().subtract(const Duration(hours: 6)),
      ),
    ]);
  }

  @override
  Future<Result<void>> cancelMyLabTest(String labTestId) async {
    await Future.delayed(const Duration(milliseconds: 300));
    return const Success(null);
  }

  @override
  Future<Result<List<TelemedicineSession>>> getMyVideoVisits() async {
    await Future.delayed(const Duration(milliseconds: 400));
    return Success([
      TelemedicineSession(
        id: 'TM-001',
        practitionerName: 'Dr. Omer Yusuf',
        status: 'Scheduled',
        startTime: DateTime.now().add(const Duration(hours: 2)),
        meetingUrl: 'https://meet.jit.si/HiraalCare-DEMO-abc123',
      ),
      TelemedicineSession(
        id: 'TM-000',
        practitionerName: 'Dr. Dinah',
        status: 'Completed',
        startTime: DateTime.now().subtract(const Duration(days: 3)),
        durationMinutes: 18,
      ),
    ]);
  }

  @override
  Future<Result<void>> notifyJoiningVideoVisit(String sessionId) async {
    await Future.delayed(const Duration(milliseconds: 300));
    return const Success(null);
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

  @override
  Future<Result<List<Map<String, dynamic>>>> getCareStations() async {
    await Future.delayed(const Duration(milliseconds: 200));
    return Success([
      {
        'name': 'Hargeisa Central',
        'station_name': 'Hargeisa Central',
        'address': 'Main Road, near Central Hospital',
        'city': 'Hargeisa',
        'phone': '0657002889',
      },
      {
        'name': 'Hargeisa East Station',
        'station_name': 'Hargeisa East Station',
        'address': '26 June District',
        'city': 'Hargeisa',
        'phone': '0638902929',
      },
      {
        'name': 'Berbera Station',
        'station_name': 'Berbera Station',
        'address': 'Berbera City Center',
        'city': 'Berbera',
        'phone': '',
      },
    ]);
  }
}
