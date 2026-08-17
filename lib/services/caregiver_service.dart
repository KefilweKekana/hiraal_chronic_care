import '../core/utils/result.dart';
import '../models/caregiver_link.dart';

abstract class CaregiverService {
  Future<Result<CaregiverInvitation>> inviteCaregiver({
    required String countryCode,
    required String whatsappNumber,
    required String relationship,
    String? familyMemberName,
    Map<String, bool>? permissions,
  });

  Future<Result<String>> requestSponsorConnection({
    required String countryCode,
    required String whatsappNumber,
    required String relationship,
  });

  Future<Result<List<SponsorPatientMatch>>> findPatientForSponsor(String query);

  Future<Result<CaregiverLink>> redeemInvitationCode(String code);

  Future<Result<CaregiverListData>> listMyCaregivers();

  Future<Result<String>> respondCaregiverRequest({
    required String name,
    required String action,
  });

  Future<Result<String>> updateCaregiverPermissions({
    required String name,
    required Map<String, bool> permissions,
  });

  Future<Result<String>> revokeCaregiver(String name);

  Future<Result<String>> getCaregiverWhatsappInvite(String name);

  Future<Result<List<SponsorshipSummary>>> listMySponsorships();

  Future<Result<SponsorshipDashboard>> getSponsorshipDashboard(String name);

  Future<Result<String>> sponsorPatientSubscription({
    required String patient,
    required String plan,
    required String provider,
    required String method,
    required String phone,
    String? familyMember,
  });

  Future<Result<String>> checkSponsorPayment(String transactionLog);

  Future<Result<Map<String, dynamic>>> getSponsoredPatientData({
    required String patient,
    required String dataType,
  });
}
