import '../core/utils/age_dob.dart';

class Patient {
  final String id;
  final String name;
  final String patientId;
  final String phone;
  final String? photoUrl;
  final List<String> conditions;
  final String clinic;
  final String carePlan;
  final String nextCheckIn;
  final String assignedNurse;
  final String subscriptionStatus;
  final String riskLevel;
  final String? deviceAssigned;
  final String? sex;
  final String? dob;

  /// Whether the patient currently has a paid, active subscription. Drives the
  /// app's feature gate — false means the paywall is shown until they subscribe.
  final bool subscriptionActive;

  Patient({
    required this.id,
    required this.name,
    required this.patientId,
    required this.phone,
    this.photoUrl,
    required this.conditions,
    required this.clinic,
    required this.carePlan,
    required this.nextCheckIn,
    required this.assignedNurse,
    required this.subscriptionStatus,
    required this.riskLevel,
    this.deviceAssigned,
    this.sex,
    this.dob,
    this.subscriptionActive = false,
  });

  String get initials {
    final letters = name
        .split(RegExp(r'\s+'))
        .where((part) => part.isNotEmpty)
        .map((part) => part[0])
        .take(2)
        .join()
        .toUpperCase();
    return letters.isEmpty ? '?' : letters;
  }

  int? get ageYears => AgeDob.ageFromIso(dob);

  factory Patient.mock() => Patient(
        id: '1',
        name: 'Amina Ahmed',
        patientId: 'HCC-2024-000125',
        phone: '+252 61 123 4567',
        conditions: ['Hypertension', 'Diabetes'],
        clinic: 'Hiraal Health Center',
        carePlan: 'Daily monitoring & follow-up',
        nextCheckIn: 'Tomorrow',
        assignedNurse: 'Nurse Ayaan',
        subscriptionStatus: 'Active',
        subscriptionActive: true,
        riskLevel: 'Very High',
        dob: '1961-01-01',
      );

  factory Patient.fromJson(Map<String, dynamic> json) {
    final id = _asString(json['name']);
    final member = _asString(json['patient_id']);
    final dob = _asString(json['dob']);
    return Patient(
      id: id,
      name: _asString(json['patient_name']),
      patientId: member.isNotEmpty ? member : id,
      phone: _asString(json['mobile'] ?? json['phone']),
      photoUrl: json['image']?.toString(),
      conditions: List<String>.from(json['conditions'] ?? []),
      clinic: _asString(json['clinic']),
      carePlan: _asString(json['care_plan']),
      nextCheckIn: _asString(json['next_check_in']),
      assignedNurse: _asString(json['assigned_nurse']),
      subscriptionStatus: _asString(json['subscription_status']).isEmpty
          ? 'Active'
          : _asString(json['subscription_status']),
      riskLevel: _asString(json['risk_level']).isEmpty
          ? 'Low'
          : _asString(json['risk_level']),
      deviceAssigned: json['device_assigned']?.toString(),
      sex: json['sex']?.toString(),
      dob: dob.isEmpty ? null : dob,
      subscriptionActive: '${json['subscription_active'] ?? 0}' == '1' ||
          json['subscription_active'] == true,
    );
  }
}

String _asString(Object? value) {
  if (value == null) return '';
  return value.toString().trim();
}
