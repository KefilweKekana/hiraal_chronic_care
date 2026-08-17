import '../core/utils/result.dart';

class PatientAddress {
  final String id;
  final String label;
  final String address;
  final bool isDefault;
  final String type; // home, clinic, work, other

  PatientAddress({
    required this.id,
    required this.label,
    required this.address,
    required this.isDefault,
    required this.type,
  });

  factory PatientAddress.fromJson(Map<String, dynamic> json) => PatientAddress(
    id: json['name'] ?? '',
    label: json['address_title'] ?? json['label'] ?? '',
    address: json['address_line1'] ?? json['address'] ?? '',
    isDefault: json['is_primary_address'] == 1,
    type: _unmapAddressType(json['address_type']?.toString()),
  );
}

/// Reverse of the write-side mapping (Personal/Office/Other) so server-loaded
/// addresses get back the app's 'home'/'clinic'/'work' type keys.
String _unmapAddressType(String? serverType) {
  switch (serverType?.toLowerCase()) {
    case 'personal':
      return 'home';
    case 'office':
      return 'work';
    default:
      return serverType?.toLowerCase() ?? 'other';
  }
}

/// CRUD for patient addresses via ERPNext Address doctype.
abstract class AddressService {
  Future<Result<List<PatientAddress>>> getAddresses(String patientId);
  Future<Result<PatientAddress>> addAddress(String patientId, PatientAddress address);
  Future<Result<void>> deleteAddress(String addressId);
}
