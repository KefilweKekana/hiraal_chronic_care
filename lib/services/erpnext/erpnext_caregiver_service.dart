import 'dart:convert';

import 'package:dio/dio.dart';

import '../../core/network/api_client.dart';
import '../../core/utils/result.dart';
import '../../models/caregiver_link.dart';
import '../caregiver_service.dart';

class ErpNextCaregiverService implements CaregiverService {
  final ApiClient _api;

  ErpNextCaregiverService(this._api);

  String _parseServerError(dynamic data, String fallback) {
    try {
      final raw = data?['_server_messages']?.toString();
      if (raw != null && raw.isNotEmpty) {
        final List messages = json.decode(raw);
        if (messages.isNotEmpty) {
          final inner = json.decode(messages.first.toString());
          return (inner['message']?.toString() ?? fallback).replaceAll(RegExp(r'<[^>]*>'), '');
        }
      }
      final exception = data?['exception']?.toString();
      if (exception != null && exception.isNotEmpty) {
        final separator = exception.indexOf(': ');
        return (separator > 0 ? exception.substring(separator + 2) : exception)
            .replaceAll(RegExp(r'<[^>]*>'), '');
      }
      return data?['message']?.toString() ?? fallback;
    } catch (_) {
      return data?['message']?.toString() ?? fallback;
    }
  }

  Map<String, dynamic> _messageMap(Response response) {
    final message = response.data?['message'];
    if (message is Map) return Map<String, dynamic>.from(message);
    return <String, dynamic>{};
  }

  @override
  Future<Result<CaregiverInvitation>> inviteCaregiver({
    required String countryCode,
    required String whatsappNumber,
    required String relationship,
    String? familyMemberName,
    Map<String, bool>? permissions,
  }) async {
    try {
      final response = await _api.dio.post(
        '/method/hiraal_emr.api.invite_caregiver',
        data: {
          'country_code': countryCode,
          'whatsapp_number': whatsappNumber,
          'relationship': relationship,
          if (familyMemberName != null && familyMemberName.isNotEmpty)
            'family_member_name': familyMemberName,
          if (permissions != null) 'permissions': permissions,
        },
      );
      return Success(CaregiverInvitation.fromJson(_messageMap(response)));
    } on DioException catch (e) {
      return Failure(
        _parseServerError(e.response?.data, 'Could not create the caregiver invitation'),
        statusCode: e.response?.statusCode,
      );
    } catch (e) {
      return Failure(e.toString());
    }
  }

  @override
  Future<Result<String>> requestSponsorConnection({
    required String countryCode,
    required String whatsappNumber,
    required String relationship,
  }) async {
    try {
      final response = await _api.dio.post(
        '/method/hiraal_emr.api.request_sponsor_connection',
        data: {
          'country_code': countryCode,
          'whatsapp_number': whatsappNumber,
          'relationship': relationship,
        },
      );
      final message = _messageMap(response);
      return Success((message['message'] ?? 'Connection request sent').toString());
    } on DioException catch (e) {
      return Failure(
        _parseServerError(e.response?.data, 'Could not send the connection request'),
        statusCode: e.response?.statusCode,
      );
    } catch (e) {
      return Failure(e.toString());
    }
  }

  @override
  Future<Result<List<SponsorPatientMatch>>> findPatientForSponsor(String query) async {
    try {
      final response = await _api.dio.post(
        '/method/hiraal_emr.api.find_patient_for_sponsor',
        data: {'query': query},
      );
      final message = _messageMap(response);
      final matches = (message['patients'] ?? message['results'] ?? message['matches'] ?? message['patient'])
          as dynamic;
      final items = matches is List ? matches : (matches is Map ? [matches] : const []);
      return Success(
        items
            .whereType<Map>()
            .map((e) => SponsorPatientMatch.fromJson(Map<String, dynamic>.from(e)))
            .toList(),
      );
    } on DioException catch (e) {
      return Failure(
        _parseServerError(e.response?.data, 'Could not find that patient'),
        statusCode: e.response?.statusCode,
      );
    } catch (e) {
      return Failure(e.toString());
    }
  }

  @override
  Future<Result<CaregiverLink>> redeemInvitationCode(String code) async {
    try {
      final response = await _api.dio.post(
        '/method/hiraal_emr.api.redeem_invitation_code',
        data: {'code': code},
      );
      return Success(CaregiverLink.fromJson(_messageMap(response)));
    } on DioException catch (e) {
      return Failure(
        _parseServerError(e.response?.data, 'Could not redeem the invitation code'),
        statusCode: e.response?.statusCode,
      );
    } catch (e) {
      return Failure(e.toString());
    }
  }

  @override
  Future<Result<CaregiverListData>> listMyCaregivers() async {
    try {
      final response = await _api.dio.post('/method/hiraal_emr.api.list_my_caregivers');
      return Success(CaregiverListData.fromJson(_messageMap(response)));
    } on DioException catch (e) {
      return Failure(
        _parseServerError(e.response?.data, 'Could not load caregivers'),
        statusCode: e.response?.statusCode,
      );
    } catch (e) {
      return Failure(e.toString());
    }
  }

  @override
  Future<Result<String>> respondCaregiverRequest({
    required String name,
    required String action,
  }) async {
    try {
      final response = await _api.dio.post(
        '/method/hiraal_emr.api.respond_caregiver_request',
        data: {'name': name, 'action': action},
      );
      final message = _messageMap(response);
      return Success((message['message'] ?? 'Request updated').toString());
    } on DioException catch (e) {
      return Failure(
        _parseServerError(e.response?.data, 'Could not respond to the request'),
        statusCode: e.response?.statusCode,
      );
    } catch (e) {
      return Failure(e.toString());
    }
  }

  @override
  Future<Result<String>> updateCaregiverPermissions({
    required String name,
    required Map<String, bool> permissions,
  }) async {
    try {
      final response = await _api.dio.post(
        '/method/hiraal_emr.api.update_caregiver_permissions',
        data: {'name': name, 'permissions': permissions},
      );
      final message = _messageMap(response);
      return Success((message['message'] ?? 'Permissions updated').toString());
    } on DioException catch (e) {
      return Failure(
        _parseServerError(e.response?.data, 'Could not update permissions'),
        statusCode: e.response?.statusCode,
      );
    } catch (e) {
      return Failure(e.toString());
    }
  }

  @override
  Future<Result<String>> revokeCaregiver(String name) async {
    try {
      final response = await _api.dio.post(
        '/method/hiraal_emr.api.revoke_caregiver',
        data: {'name': name},
      );
      final message = _messageMap(response);
      return Success((message['message'] ?? 'Caregiver revoked').toString());
    } on DioException catch (e) {
      return Failure(
        _parseServerError(e.response?.data, 'Could not revoke caregiver access'),
        statusCode: e.response?.statusCode,
      );
    } catch (e) {
      return Failure(e.toString());
    }
  }

  @override
  Future<Result<String>> getCaregiverWhatsappInvite(String name) async {
    try {
      final response = await _api.dio.post(
        '/method/hiraal_emr.api.get_caregiver_whatsapp_invite',
        data: {'name': name},
      );
      final message = _messageMap(response);
      return Success((message['whatsapp_url'] ?? '').toString());
    } on DioException catch (e) {
      return Failure(
        _parseServerError(e.response?.data, 'Could not get the WhatsApp invite'),
        statusCode: e.response?.statusCode,
      );
    } catch (e) {
      return Failure(e.toString());
    }
  }

  @override
  Future<Result<List<SponsorshipSummary>>> listMySponsorships() async {
    try {
      final response = await _api.dio.post('/method/hiraal_emr.api.list_my_sponsorships');
      final message = _messageMap(response);
      final raw = message['sponsorships'] ?? message['items'] ?? message['data'] ?? const [];
      final items = raw is List ? raw : const [];
      return Success(
        items
            .whereType<Map>()
            .map((e) => SponsorshipSummary.fromJson(Map<String, dynamic>.from(e)))
            .toList(),
      );
    } on DioException catch (e) {
      return Failure(
        _parseServerError(e.response?.data, 'Could not load sponsorships'),
        statusCode: e.response?.statusCode,
      );
    } catch (e) {
      return Failure(e.toString());
    }
  }

  @override
  Future<Result<SponsorshipDashboard>> getSponsorshipDashboard(String name) async {
    try {
      final response = await _api.dio.post(
        '/method/hiraal_emr.api.get_sponsorship_dashboard',
        data: {'name': name},
      );
      return Success(SponsorshipDashboard.fromJson(_messageMap(response)));
    } on DioException catch (e) {
      return Failure(
        _parseServerError(e.response?.data, 'Could not load sponsorship details'),
        statusCode: e.response?.statusCode,
      );
    } catch (e) {
      return Failure(e.toString());
    }
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
    try {
      final response = await _api.dio.post(
        '/method/hiraal_emr.api.sponsor_patient_subscription',
        data: {
          'patient': patient,
          'plan': plan,
          'provider': provider,
          'method': method,
          'phone': phone,
          if (familyMember != null && familyMember.isNotEmpty) 'family_member': familyMember,
        },
        options: Options(receiveTimeout: const Duration(seconds: 120)),
      );
      final message = _messageMap(response);
      final transaction = (message['transaction_log'] ?? '').toString();
      if (transaction.isEmpty) {
        return Failure((message['message'] ?? 'Could not start sponsorship payment').toString());
      }
      return Success(transaction);
    } on DioException catch (e) {
      if (e.type == DioExceptionType.receiveTimeout) {
        return const Failure(
          'The sponsorship payment is taking longer than usual. If you approved it, it should confirm shortly.',
        );
      }
      return Failure(
        _parseServerError(e.response?.data, 'Could not start sponsorship payment'),
        statusCode: e.response?.statusCode,
      );
    } catch (e) {
      return Failure(e.toString());
    }
  }

  @override
  Future<Result<String>> checkSponsorPayment(String transactionLog) async {
    try {
      final response = await _api.dio.post(
        '/method/hiraal_emr.api.check_sponsor_payment',
        data: {'transaction_log': transactionLog},
      );
      final message = _messageMap(response);
      return Success((message['status'] ?? 'Pending').toString());
    } on DioException catch (e) {
      return Failure(
        _parseServerError(e.response?.data, 'Could not check sponsorship payment'),
        statusCode: e.response?.statusCode,
      );
    } catch (e) {
      return Failure(e.toString());
    }
  }

  @override
  Future<Result<Map<String, dynamic>>> getSponsoredPatientData({
    required String patient,
    required String dataType,
  }) async {
    try {
      final response = await _api.dio.post(
        '/method/hiraal_emr.api.get_sponsored_patient_data',
        data: {'patient': patient, 'data_type': dataType},
      );
      return Success(_messageMap(response));
    } on DioException catch (e) {
      return Failure(
        _parseServerError(e.response?.data, 'Could not load sponsored patient data'),
        statusCode: e.response?.statusCode,
      );
    } catch (e) {
      return Failure(e.toString());
    }
  }
}
