class CaregiverLink {
  final String name;
  final String fullName;
  final String relationship;
  final String countryCode;
  final String whatsappNumber;
  final String? familyMemberName;
  final String linkStatus;
  final Map<String, bool> permissions;
  final String? invitationCode;
  final String? note;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const CaregiverLink({
    required this.name,
    required this.fullName,
    required this.relationship,
    required this.countryCode,
    required this.whatsappNumber,
    this.familyMemberName,
    this.linkStatus = 'Pending',
    this.permissions = const {},
    this.invitationCode,
    this.note,
    this.createdAt,
    this.updatedAt,
  });

  String get displayName => fullName.isNotEmpty ? fullName : name;
  String get fullWhatsappNumber => '${countryCode.trim()} ${whatsappNumber.trim()}'.trim();
  bool get isPending => linkStatus.toLowerCase() == 'pending';
  bool get isActive => linkStatus.toLowerCase() == 'active';

  factory CaregiverLink.fromJson(Map<String, dynamic> json) {
    final permissionsRaw = json['permissions'];
    return CaregiverLink(
      name: (json['name'] ?? json['id'] ?? '').toString(),
      fullName: (json['full_name'] ??
              json['caregiver_name'] ??
              json['patient_name'] ??
              json['sponsor_name'] ??
              json['name'] ??
              '')
          .toString(),
      relationship: (json['relationship'] ?? '').toString(),
      countryCode: (json['country_code'] ?? '+252').toString(),
      whatsappNumber: (json['whatsapp_number'] ?? json['phone'] ?? json['mobile'] ?? '').toString(),
      familyMemberName: (json['family_member_name'] as Object?)?.toString(),
      linkStatus: (json['link_status'] ?? json['status'] ?? 'Pending').toString(),
      permissions: _parsePermissions(permissionsRaw),
      invitationCode: (json['invitation_code'] as Object?)?.toString(),
      note: (json['note'] as Object?)?.toString(),
      createdAt: _parseDate(json['created_at'] ?? json['creation']),
      updatedAt: _parseDate(json['updated_at'] ?? json['modified']),
    );
  }
}

class CaregiverInvitation {
  final String caregiverName;
  final String whatsappUrl;
  final String? invitationCode;
  final String message;

  const CaregiverInvitation({
    required this.caregiverName,
    required this.whatsappUrl,
    this.invitationCode,
    this.message = '',
  });

  factory CaregiverInvitation.fromJson(Map<String, dynamic> json) {
    return CaregiverInvitation(
      caregiverName: (json['caregiver_name'] ?? json['name'] ?? '').toString(),
      whatsappUrl: (json['whatsapp_url'] ?? '').toString(),
      invitationCode: (json['invitation_code'] as Object?)?.toString(),
      message: (json['message'] ?? '').toString(),
    );
  }
}

class CaregiverListData {
  final List<CaregiverLink> caregivers;
  final List<CaregiverLink> pending;

  const CaregiverListData({
    this.caregivers = const [],
    this.pending = const [],
  });

  factory CaregiverListData.fromJson(Map<String, dynamic> json) {
    return CaregiverListData(
      caregivers: _parseLinks(json['caregivers']),
      pending: _parseLinks(json['pending']),
    );
  }
}

class SponsorPatientMatch {
  final String patient;
  final String patientName;
  final String patientId;
  final String phone;
  final String? clinic;
  final String? relationshipHint;
  final String? familyMemberName;
  final String? invitationCode;
  final bool exactMatch;

  const SponsorPatientMatch({
    required this.patient,
    required this.patientName,
    required this.patientId,
    required this.phone,
    this.clinic,
    this.relationshipHint,
    this.familyMemberName,
    this.invitationCode,
    this.exactMatch = true,
  });

  factory SponsorPatientMatch.fromJson(Map<String, dynamic> json) {
    return SponsorPatientMatch(
      patient: (json['patient'] ?? json['name'] ?? '').toString(),
      patientName: (json['patient_name'] ?? json['full_name'] ?? '').toString(),
      patientId: (json['patient_id'] ?? json['member_id'] ?? '').toString(),
      phone: (json['phone'] ?? json['mobile'] ?? json['whatsapp_number'] ?? '').toString(),
      clinic: (json['clinic'] as Object?)?.toString(),
      relationshipHint: (json['relationship'] as Object?)?.toString(),
      familyMemberName: (json['family_member_name'] as Object?)?.toString(),
      invitationCode: (json['invitation_code'] as Object?)?.toString(),
      exactMatch: json['exact_match'] != false,
    );
  }
}

class SponsorshipSummary {
  final String name;
  final String patient;
  final String patientName;
  final String patientId;
  final String status;
  final String relationship;
  final String? plan;
  final double monthlyAmount;
  final DateTime? nextPaymentDate;

  const SponsorshipSummary({
    required this.name,
    required this.patient,
    required this.patientName,
    required this.patientId,
    required this.status,
    required this.relationship,
    this.plan,
    this.monthlyAmount = 0,
    this.nextPaymentDate,
  });

  factory SponsorshipSummary.fromJson(Map<String, dynamic> json) {
    return SponsorshipSummary(
      name: (json['name'] ?? '').toString(),
      patient: (json['patient'] ?? '').toString(),
      patientName: (json['patient_name'] ?? '').toString(),
      patientId: (json['patient_id'] ?? '').toString(),
      status: (json['status'] ?? json['link_status'] ?? 'Pending').toString(),
      relationship: (json['relationship'] ?? '').toString(),
      plan: (json['plan'] as Object?)?.toString(),
      monthlyAmount: _toDouble(json['monthly_amount'] ?? json['amount']) ?? 0,
      nextPaymentDate: _parseDate(json['next_payment_date']),
    );
  }
}

class SponsorshipDashboard {
  final String name;
  final String patient;
  final String patientName;
  final String patientId;
  final String status;
  final String relationship;
  final String? plan;
  final double monthlyAmount;
  final DateTime? nextPaymentDate;
  final List<String> updates;
  final Map<String, dynamic> raw;

  const SponsorshipDashboard({
    required this.name,
    required this.patient,
    required this.patientName,
    required this.patientId,
    required this.status,
    required this.relationship,
    this.plan,
    this.monthlyAmount = 0,
    this.nextPaymentDate,
    this.updates = const [],
    this.raw = const {},
  });

  factory SponsorshipDashboard.fromJson(Map<String, dynamic> json) {
    final updateList = (json['updates'] as List? ?? const [])
        .map((e) => e is Map ? (e['label'] ?? e['message'] ?? '').toString() : e.toString())
        .where((e) => e.isNotEmpty)
        .toList();
    return SponsorshipDashboard(
      name: (json['name'] ?? '').toString(),
      patient: (json['patient'] ?? '').toString(),
      patientName: (json['patient_name'] ?? '').toString(),
      patientId: (json['patient_id'] ?? '').toString(),
      status: (json['status'] ?? 'Pending').toString(),
      relationship: (json['relationship'] ?? '').toString(),
      plan: (json['plan'] as Object?)?.toString(),
      monthlyAmount: _toDouble(json['monthly_amount'] ?? json['amount']) ?? 0,
      nextPaymentDate: _parseDate(json['next_payment_date']),
      updates: updateList,
      raw: Map<String, dynamic>.from(json),
    );
  }
}

Map<String, bool> _parsePermissions(dynamic raw) {
  if (raw is Map) {
    return raw.map(
      (key, value) => MapEntry(
        key.toString(),
        value == true || value == 1 || value?.toString().toLowerCase() == 'true',
      ),
    );
  }
  if (raw is List) {
    return {
      for (final item in raw)
        item.toString(): true,
    };
  }
  return const {
    'view_readings': true,
    'view_medicines': true,
    'view_appointments': true,
  };
}

List<CaregiverLink> _parseLinks(dynamic raw) {
  if (raw is! List) return const [];
  return raw
      .whereType<Map>()
      .map((e) => CaregiverLink.fromJson(Map<String, dynamic>.from(e)))
      .toList();
}

DateTime? _parseDate(Object? value) {
  if (value == null) return null;
  return DateTime.tryParse(value.toString());
}

double? _toDouble(Object? value) {
  if (value == null) return null;
  if (value is num) return value.toDouble();
  return double.tryParse(value.toString());
}
