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
      invitationCode: (json['invitation_code'] ?? json['invite_code'])?.toString(),
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
      invitationCode: (json['invitation_code'] ?? json['invite_code'])?.toString(),
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
  final String? familyMember;
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
    this.familyMember,
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
      familyMember: (json['family_member'] as Object?)?.toString(),
      invitationCode: (json['invitation_code'] ?? json['invite_code'])?.toString(),
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
  final bool canPayForCare;
  final int? age;
  final DateTime? memberSince;

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
    this.canPayForCare = false,
    this.age,
    this.memberSince,
  });

  bool get isPending => status.toLowerCase() == 'pending';
  bool get isAccepted => status.toLowerCase() == 'accepted';
  bool get isActive => status.toLowerCase() == 'active';

  factory SponsorshipSummary.fromJson(Map<String, dynamic> json) {
    final sub = json['subscription'];
    final permissions = json['permissions'];
    var plan = (json['plan'] as Object?)?.toString();
    var monthlyAmount = _toDouble(json['monthly_amount'] ?? json['amount']) ?? 0;
    var nextPaymentDate = _parseDate(json['next_payment_date']);
    var canPayForCare = json['can_pay_for_care'] == true || json['can_pay_for_care'] == 1;
    if (permissions is Map) {
      canPayForCare = canPayForCare ||
          permissions['can_pay_for_care'] == true ||
          permissions['view_subscription'] == true;
    }
    if (sub is Map) {
      plan ??= (sub['plan'] as Object?)?.toString();
      monthlyAmount = _toDouble(sub['monthly_fee']) ?? monthlyAmount;
      nextPaymentDate ??= _parseDate(sub['next_billing_date']);
    }
    return SponsorshipSummary(
      name: (json['name'] ?? '').toString(),
      patient: (json['patient'] ?? '').toString(),
      patientName: (json['patient_name'] ?? '').toString(),
      patientId: (json['patient_id'] ?? json['patient'] ?? '').toString(),
      status: (json['status'] ?? json['link_status'] ?? 'Pending').toString(),
      relationship: (json['relationship'] ?? '').toString(),
      plan: plan,
      monthlyAmount: monthlyAmount,
      nextPaymentDate: nextPaymentDate,
      canPayForCare: canPayForCare,
      age: json['age'] is num
          ? (json['age'] as num).toInt()
          : int.tryParse('${json['age'] ?? ''}'),
      memberSince: _parseDate(json['member_since'] ?? json['creation'] ?? json['activated_on']),
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
  final bool canPayForCare;
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
    this.canPayForCare = false,
    this.raw = const {},
  });

  bool get isPending => status.toLowerCase() == 'pending';
  bool get isAccepted => status.toLowerCase() == 'accepted';
  bool get isActive => status.toLowerCase() == 'active';

  factory SponsorshipDashboard.fromJson(Map<String, dynamic> json) {
    final link = json['link'];
    final sub = json['subscription'];
    final linkMap = link is Map ? Map<String, dynamic>.from(link) : <String, dynamic>{};
    final subMap = sub is Map ? Map<String, dynamic>.from(sub) : <String, dynamic>{};
    final updateList = (json['updates'] as List? ?? const [])
        .map((e) => e is Map ? (e['title'] ?? e['message'] ?? '').toString() : e.toString())
        .where((e) => e.isNotEmpty)
        .toList();
    return SponsorshipDashboard(
      name: (json['name'] ?? linkMap['name'] ?? '').toString(),
      patient: (json['patient'] ?? linkMap['patient'] ?? '').toString(),
      patientName: (json['patient_name'] ?? linkMap['patient_name'] ?? '').toString(),
      patientId: (json['patient_id'] ?? json['patient'] ?? linkMap['patient'] ?? '').toString(),
      status: (json['status'] ?? linkMap['link_status'] ?? 'Pending').toString(),
      relationship: (json['relationship'] ?? linkMap['relationship'] ?? '').toString(),
      plan: (json['plan'] ?? subMap['plan'])?.toString(),
      monthlyAmount: _toDouble(json['monthly_amount'] ?? subMap['monthly_fee']) ?? 0,
      nextPaymentDate: _parseDate(json['next_payment_date'] ?? subMap['next_billing_date']),
      updates: updateList,
      canPayForCare: json['can_pay_for_care'] == true ||
          json['can_pay_for_care'] == 1 ||
          linkMap['can_pay_for_care'] == true ||
          linkMap['can_pay_for_care'] == 1,
      raw: Map<String, dynamic>.from(json),
    );
  }
}

Map<String, bool> _parsePermissions(dynamic raw) {
  final parsed = <String, bool>{};
  if (raw is Map) {
    raw.forEach((key, value) {
      parsed[key.toString()] =
          value == true || value == 1 || value?.toString().toLowerCase() == 'true';
    });
  } else if (raw is List) {
    for (final item in raw) {
      parsed[item.toString()] = true;
    }
  }

  if (parsed.isEmpty) {
    return const {
      'view_readings': true,
      'view_medicines': true,
      'view_appointments': true,
    };
  }

  return {
    'view_readings':
        parsed['view_readings'] ?? parsed['can_view_vitals'] ?? false,
    'view_medicines':
        parsed['view_medicines'] ?? parsed['can_view_medications'] ?? false,
    'view_appointments':
        parsed['view_appointments'] ?? parsed['can_view_appointments'] ?? false,
    'view_subscription':
        parsed['view_subscription'] ?? parsed['can_pay_for_care'] ?? false,
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
