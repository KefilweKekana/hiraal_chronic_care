import '../../core/utils/result.dart';
import '../address_service.dart';

class MockAddressService implements AddressService {
  final List<PatientAddress> _addresses = [
    PatientAddress(
      id: 'ADDR-001',
      label: 'Home',
      address: 'Hodan District, Mogadishu, Somalia',
      isDefault: true,
      type: 'home',
    ),
    PatientAddress(
      id: 'ADDR-002',
      label: 'Clinic',
      address: 'Hiraal Health Center\nBondhere, Mogadishu',
      isDefault: false,
      type: 'clinic',
    ),
  ];

  @override
  Future<Result<List<PatientAddress>>> getAddresses(String patientId) async {
    await Future.delayed(const Duration(milliseconds: 300));
    return Success(List.from(_addresses));
  }

  @override
  Future<Result<PatientAddress>> addAddress(String patientId, PatientAddress address) async {
    await Future.delayed(const Duration(milliseconds: 300));
    // One past the highest existing numeric id, so ids stay unique after deletes.
    final next = _addresses.fold<int>(0, (max, a) {
          final n = int.tryParse(a.id.replaceFirst('ADDR-', '')) ?? 0;
          return n > max ? n : max;
        }) +
        1;
    final newAddr = PatientAddress(
      id: 'ADDR-${next.toString().padLeft(3, '0')}',
      label: address.label,
      address: address.address,
      isDefault: false,
      type: address.type,
    );
    _addresses.add(newAddr);
    return Success(newAddr);
  }

  @override
  Future<Result<void>> deleteAddress(String addressId) async {
    await Future.delayed(const Duration(milliseconds: 300));
    _addresses.removeWhere((a) => a.id == addressId);
    return Success(null);
  }
}
