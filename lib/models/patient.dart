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
  });

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
    riskLevel: 'Very High',
  );

  factory Patient.fromJson(Map<String, dynamic> json) => Patient(
    id: json['name'] ?? '',
    name: json['patient_name'] ?? '',
    patientId: json['patient_id'] ?? '',
    phone: json['mobile'] ?? '',
    photoUrl: json['image'],
    conditions: List<String>.from(json['conditions'] ?? []),
    clinic: json['clinic'] ?? '',
    carePlan: json['care_plan'] ?? '',
    nextCheckIn: json['next_check_in'] ?? '',
    assignedNurse: json['assigned_nurse'] ?? '',
    subscriptionStatus: json['subscription_status'] ?? 'Active',
    riskLevel: json['risk_level'] ?? 'Low',
    deviceAssigned: json['device_assigned'],
    sex: json['sex'],
  );
}
