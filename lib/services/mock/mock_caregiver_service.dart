import '../../core/utils/result.dart';
import '../../models/caregiver_link.dart';
import '../caregiver_service.dart';

class MockCaregiverService implements CaregiverService {
  final List<CaregiverLink> _caregivers = [
    const CaregiverLink(
      name: 'CG-001',
      fullName: 'Ahmed Adan',
      relationship: 'Brother',
      countryCode: '+252',
      whatsappNumber: '612345678',
      linkStatus: 'Active',
      permissions: {
        'view_readings': true,
        'view_medicines': true,
        'view_appointments': true,
        'view_subscription': false,
      },
      createdAt: null,
    ),
  ];

  final List<CaregiverLink> _pending = [
    const CaregiverLink(
      name: 'CG-002',
      fullName: 'Khadija Hassan',
      relationship: 'Daughter',
      countryCode: '+252',
      whatsappNumber: '615551122',
      linkStatus: 'Pending',
      permissions: {
        'view_readings': true,
        'view_medicines': false,
        'view_appointments': true,
        'view_subscription': false,
      },
      invitationCode: 'KHADIJA-2026',
      familyMemberName: 'Hooyo Amina',
    ),
  ];

  final List<SponsorPatientMatch> _matches = const [
    SponsorPatientMatch(
      patient: 'PAT-001',
      patientName: 'Amina Ahmed',
      patientId: 'HCC-2024-000125',
      phone: '+252 61 123 4567',
      clinic: 'Hiraal Health Center',
      relationshipHint: 'Mother',
      familyMemberName: 'Amina Ahmed',
      invitationCode: 'AMINA-CARE-88',
    ),
  ];

  final List<SponsorshipSummary> _sponsorships = [
    SponsorshipSummary(
      name: 'SP-001',
      patient: 'PAT-001',
      patientName: 'Amina Ahmed',
      patientId: 'HCC-2024-000125',
      status: 'Active',
      relationship: 'Mother',
      plan: 'Standard Care',
      monthlyAmount: 5,
      nextPaymentDate: DateTime.now().add(const Duration(days: 12)),
    ),
  ];

  final Map<String, int> _paymentPolls = {};

  @override
  Future<Result<CaregiverInvitation>> inviteCaregiver({
    required String countryCode,
    required String whatsappNumber,
    required String relationship,
    String? familyMemberName,
    Map<String, bool>? permissions,
  }) async {
    await Future.delayed(const Duration(milliseconds: 500));
    final name = 'CG-${_pending.length + _caregivers.length + 1}'.padLeft(6, '0');
    final link = CaregiverLink(
      name: name,
      fullName: familyMemberName?.isNotEmpty == true ? familyMemberName! : 'New Caregiver',
      relationship: relationship,
      countryCode: countryCode,
      whatsappNumber: whatsappNumber,
      familyMemberName: familyMemberName,
      linkStatus: 'Pending',
      permissions: permissions ?? const {
        'view_readings': true,
        'view_medicines': true,
        'view_appointments': true,
      },
      invitationCode: 'INV-${DateTime.now().millisecondsSinceEpoch}',
    );
    _pending.insert(0, link);
    return Success(
      CaregiverInvitation(
        caregiverName: link.displayName,
        whatsappUrl:
            'https://wa.me/${countryCode.replaceAll('+', '')}${whatsappNumber.replaceAll(' ', '')}?text=${Uri.encodeComponent('You have been invited to support care in Hiraal. Invitation code: ${link.invitationCode ?? ''}')}',
        invitationCode: link.invitationCode,
        message: 'Invitation ready',
      ),
    );
  }

  @override
  Future<Result<String>> requestSponsorConnection({
    required String countryCode,
    required String whatsappNumber,
    required String relationship,
  }) async {
    await Future.delayed(const Duration(milliseconds: 400));
    return const Success('Connection request sent');
  }

  @override
  Future<Result<List<SponsorPatientMatch>>> findPatientForSponsor(String query) async {
    await Future.delayed(const Duration(milliseconds: 350));
    final needle = query.toLowerCase().trim();
    final matches = _matches.where((item) {
      return item.patientName.toLowerCase().contains(needle) ||
          item.patientId.toLowerCase().contains(needle) ||
          item.phone.toLowerCase().contains(needle);
    }).toList();
    return Success(matches);
  }

  @override
  Future<Result<CaregiverLink>> redeemInvitationCode(String code) async {
    await Future.delayed(const Duration(milliseconds: 400));
    final match = _matches.first;
    return Success(
      CaregiverLink(
        name: 'SP-CONNECTION',
        fullName: match.patientName,
        relationship: match.relationshipHint ?? 'Family',
        countryCode: '+252',
        whatsappNumber: '611111111',
        familyMemberName: match.familyMemberName,
        linkStatus: 'Active',
        permissions: const {
          'view_readings': true,
          'view_medicines': true,
          'view_appointments': true,
        },
        invitationCode: code,
      ),
    );
  }

  @override
  Future<Result<CaregiverListData>> listMyCaregivers() async {
    await Future.delayed(const Duration(milliseconds: 350));
    return Success(CaregiverListData(caregivers: List.of(_caregivers), pending: List.of(_pending)));
  }

  @override
  Future<Result<String>> respondCaregiverRequest({
    required String name,
    required String action,
  }) async {
    await Future.delayed(const Duration(milliseconds: 400));
    final index = _pending.indexWhere((item) => item.name == name);
    if (index < 0) return const Failure('Request not found');
    final request = _pending.removeAt(index);
    if (action == 'accept') {
      _caregivers.insert(
        0,
        CaregiverLink(
          name: request.name,
          fullName: request.fullName,
          relationship: request.relationship,
          countryCode: request.countryCode,
          whatsappNumber: request.whatsappNumber,
          familyMemberName: request.familyMemberName,
          linkStatus: 'Active',
          permissions: request.permissions,
          invitationCode: request.invitationCode,
        ),
      );
    }
    return Success(action == 'accept' ? 'Caregiver accepted' : 'Caregiver rejected');
  }

  @override
  Future<Result<String>> updateCaregiverPermissions({
    required String name,
    required Map<String, bool> permissions,
  }) async {
    await Future.delayed(const Duration(milliseconds: 350));
    final index = _caregivers.indexWhere((item) => item.name == name);
    if (index < 0) return const Failure('Caregiver not found');
    final current = _caregivers[index];
    _caregivers[index] = CaregiverLink(
      name: current.name,
      fullName: current.fullName,
      relationship: current.relationship,
      countryCode: current.countryCode,
      whatsappNumber: current.whatsappNumber,
      familyMemberName: current.familyMemberName,
      linkStatus: current.linkStatus,
      permissions: permissions,
      invitationCode: current.invitationCode,
      createdAt: current.createdAt,
      updatedAt: DateTime.now(),
    );
    return const Success('Permissions updated');
  }

  @override
  Future<Result<String>> revokeCaregiver(String name) async {
    await Future.delayed(const Duration(milliseconds: 350));
    _caregivers.removeWhere((item) => item.name == name);
    return const Success('Caregiver access revoked');
  }

  @override
  Future<Result<String>> getCaregiverWhatsappInvite(String name) async {
    await Future.delayed(const Duration(milliseconds: 300));
    final caregiver = [..._caregivers, ..._pending].firstWhere(
      (item) => item.name == name,
      orElse: () => _pending.first,
    );
    return Success(
      'https://wa.me/${caregiver.countryCode.replaceAll('+', '')}${caregiver.whatsappNumber}?text=${Uri.encodeComponent('Hello ${caregiver.displayName}, here is your Hiraal caregiver invitation code: ${caregiver.invitationCode ?? 'HIRAAL-CARE'}')}',
    );
  }

  @override
  Future<Result<List<SponsorshipSummary>>> listMySponsorships() async {
    await Future.delayed(const Duration(milliseconds: 350));
    return Success(List.of(_sponsorships));
  }

  @override
  Future<Result<SponsorshipDashboard>> getSponsorshipDashboard(String name) async {
    await Future.delayed(const Duration(milliseconds: 400));
    final summary = _sponsorships.firstWhere((item) => item.name == name, orElse: () => _sponsorships.first);
    return Success(
      SponsorshipDashboard(
        name: summary.name,
        patient: summary.patient,
        patientName: summary.patientName,
        patientId: summary.patientId,
        status: summary.status,
        relationship: summary.relationship,
        plan: summary.plan,
        monthlyAmount: summary.monthlyAmount,
        nextPaymentDate: summary.nextPaymentDate,
        updates: const [
          'Latest blood pressure was shared with the care team.',
          'Medication refill was delivered this week.',
          'Next nurse follow-up is scheduled for Thursday.',
        ],
      ),
    );
  }

  @override
  Future<Result<String>> sponsorPatientSubscription({
    required String patient,
    required String plan,
    required String provider,
    required String method,
    required String phone,
    String? familyMember,
  }) async {
    await Future.delayed(const Duration(milliseconds: 700));
    final transaction = 'SPONSOR-TXN-${DateTime.now().millisecondsSinceEpoch}';
    _paymentPolls[transaction] = 0;
    return Success(transaction);
  }

  @override
  Future<Result<String>> checkSponsorPayment(String transactionLog) async {
    await Future.delayed(const Duration(milliseconds: 700));
    final polls = _paymentPolls[transactionLog] = (_paymentPolls[transactionLog] ?? 0) + 1;
    return Success(polls >= 2 ? 'Completed' : 'Pending');
  }

  @override
  Future<Result<Map<String, dynamic>>> getSponsoredPatientData({
    required String patient,
    required String dataType,
  }) async {
    await Future.delayed(const Duration(milliseconds: 250));
    return Success({
      'patient': patient,
      'data_type': dataType,
      'items': const [
        {'label': 'Blood pressure', 'value': '128/82 mmHg'},
        {'label': 'Medicine adherence', 'value': '6 of 7 days'},
      ],
    });
  }
}
