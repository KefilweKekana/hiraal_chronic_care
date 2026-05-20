import 'package:dio/dio.dart';

import '../../core/network/api_client.dart';
import '../../core/utils/app_logger.dart';
import '../../core/utils/result.dart';
import '../address_service.dart';

/// ERPNext implementation of [AddressService].
///
/// Uses Frappe's standard **Address** doctype linked to Patient via
/// Dynamic Link.
class ErpNextAddressService implements AddressService {
  final ApiClient _api;

  ErpNextAddressService(this._api);

  @override
  Future<Result<List<PatientAddress>>> getAddresses(String patientId) async {
    try {
      // Frappe stores addresses with Dynamic Links — query via REST
      final response = await _api.dio.get(
        '/resource/Dynamic Link',
        queryParameters: {
          'filters': '["link_doctype","=","Patient"],["link_name","=","$patientId"],["parenttype","=","Address"]',
          'fields': '["parent"]',
          'limit_page_length': 50,
        },
      );

      final links = response.data?['data'] as List? ?? [];
      final addresses = <PatientAddress>[];

      for (final link in links.cast<Map<String, dynamic>>()) {
        final addressName = link['parent']?.toString();
        if (addressName == null || addressName.isEmpty) continue;

        final addrResponse = await _api.dio.get(
          '/resource/Address/$addressName',
        );

        final data = addrResponse.data?['data'] as Map<String, dynamic>?;
        if (data != null) {
          addresses.add(PatientAddress.fromJson(data));
        }
      }

      return Success(addresses);
    } on DioException catch (e) {
      log.e('getAddresses failed', error: e);
      return Failure(e.response?.data?['message']?.toString() ??
            'Failed to fetch addresses',
        statusCode: e.response?.statusCode,
      );
    } catch (e) {
      return Failure(e.toString());
    }
  }

  @override
  Future<Result<PatientAddress>> addAddress(
      String patientId, PatientAddress address) async {
    try {
      final response = await _api.dio.post(
        '/resource/Address',
        data: {
          'address_title': address.label,
          'address_type': _mapAddressType(address.type),
          'address_line1': address.address,
          'is_primary_address': address.isDefault ? 1 : 0,
          'links': [
            {
              'link_doctype': 'Patient',
              'link_name': patientId,
            }
          ],
        },
      );

      final data = response.data?['data'] as Map<String, dynamic>?;
      if (data != null) {
        return Success(PatientAddress.fromJson(data));
      }
      return const Failure('Failed to add address');
    } on DioException catch (e) {
      log.e('addAddress failed', error: e);
      return Failure(e.response?.data?['message']?.toString() ??
            'Failed to add address',
        statusCode: e.response?.statusCode,
      );
    } catch (e) {
      return Failure(e.toString());
    }
  }

  @override
  Future<Result<void>> deleteAddress(String addressId) async {
    try {
      await _api.dio.delete(
        '/resource/Address/$addressId',
      );
      return const Success(null);
    } on DioException catch (e) {
      log.e('deleteAddress failed', error: e);
      return Failure(e.response?.data?['message']?.toString() ??
            'Failed to delete address',
        statusCode: e.response?.statusCode,
      );
    } catch (e) {
      return Failure(e.toString());
    }
  }

  String _mapAddressType(String type) {
    switch (type.toLowerCase()) {
      case 'home':
        return 'Personal';
      case 'clinic':
        return 'Office';
      case 'work':
        return 'Office';
      default:
        return 'Other';
    }
  }
}
