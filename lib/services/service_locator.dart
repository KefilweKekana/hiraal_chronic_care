import '../core/config/env_config.dart';
import '../core/network/api_client.dart';
import 'auth_service.dart';
import 'readings_service.dart';
import 'notification_service.dart';
import 'booking_service.dart';
import 'patient_record_service.dart';
import 'address_service.dart';
import 'activity_service.dart';
import 'mock/mock_auth_service.dart';
import 'mock/mock_readings_service.dart';
import 'mock/mock_notification_service.dart';
import 'mock/mock_booking_service.dart';
import 'mock/mock_patient_record_service.dart';
import 'mock/mock_address_service.dart';
import 'mock/mock_activity_service.dart';
import 'erpnext/erpnext_auth_service.dart';
import 'erpnext/erpnext_readings_service.dart';
import 'erpnext/erpnext_notification_service.dart';
import 'erpnext/erpnext_booking_service.dart';
import 'erpnext/erpnext_patient_record_service.dart';
import 'erpnext/erpnext_address_service.dart';
import 'erpnext/erpnext_activity_service.dart';

/// Simple service locator.
/// When [EnvConfig.useMock] is false, swap in ERPNext implementations.
class ServiceLocator {
  ServiceLocator._();
  static final ServiceLocator _instance = ServiceLocator._();
  static ServiceLocator get instance => _instance;

  late final AuthService auth;
  late final ReadingsService readings;
  late final NotificationService notifications;
  late final BookingService bookings;
  late final PatientRecordService records;
  late final AddressService addresses;
  late final ActivityService activity;

  ApiClient? _apiClient;

  /// The shared [ApiClient] instance, available when not using mocks.
  ApiClient? get apiClient => _apiClient;

  bool _initialized = false;

  void init() {
    if (_initialized) return;

    if (EnvConfig.useMock) {
      auth = MockAuthService();
      readings = MockReadingsService();
      notifications = MockNotificationService();
      bookings = MockBookingService();
      records = MockPatientRecordService();
      addresses = MockAddressService();
      activity = MockActivityService();
    } else {
      _apiClient = ApiClient();
      auth = ErpNextAuthService(_apiClient!);
      readings = ErpNextReadingsService(_apiClient!);
      notifications = ErpNextNotificationService(_apiClient!);
      bookings = ErpNextBookingService(_apiClient!, patientId: '');
      records = ErpNextPatientRecordService(_apiClient!);
      addresses = ErpNextAddressService(_apiClient!);
      activity = ErpNextActivityService(_apiClient!);
    }

    _initialized = true;
  }

  /// Update the patient ID used by services that need it.
  void updatePatientId(String patientId, {String? sex}) {
    final b = bookings;
    if (b is ErpNextBookingService) {
      b.patientId = patientId;
      if (sex != null) b.patientSex = sex;
    }
  }
}
