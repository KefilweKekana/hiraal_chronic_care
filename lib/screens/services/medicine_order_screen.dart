import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/theme/app_colors.dart';
import '../../core/utils/result.dart';
import '../../l10n/app_localizations.dart';
import '../../services/address_service.dart';
import '../../services/service_locator.dart';
import '../profile/addresses_screen.dart';
import 'my_orders_screen.dart';
import 'order_tracking_screen.dart';

/// Hiraal Pharma — upload a prescription image; the pharmacy reviews it, prices
/// it, and the patient pays in-app before it's prepared and delivered.
class MedicineOrderScreen extends StatefulWidget {
  const MedicineOrderScreen({super.key});

  @override
  State<MedicineOrderScreen> createState() => _MedicineOrderScreenState();
}

class _MedicineOrderScreenState extends State<MedicineOrderScreen> {
  final ImagePicker _picker = ImagePicker();
  final TextEditingController _note = TextEditingController();

  File? _prescription;
  List<PatientAddress> _addresses = [];
  PatientAddress? _selected;
  bool _loadingAddresses = true;
  bool _isLoading = false;

  // Sentinel for the address sheet's "Add new address" tile — a plain null
  // result means the sheet was dismissed and must not trigger navigation.
  static const Object _addNewAddress = Object();

  @override
  void initState() {
    super.initState();
    _loadAddresses();
  }

  @override
  void dispose() {
    _note.dispose();
    super.dispose();
  }

  Future<void> _loadAddresses() async {
    setState(() => _loadingAddresses = true);
    final result = await ServiceLocator.instance.addresses.getAddresses('');
    if (!mounted) return;
    setState(() {
      _loadingAddresses = false;
      if (result case Success(data: final list)) {
        _addresses = list;
        _selected = list.where((a) => a.isDefault).isNotEmpty
            ? list.firstWhere((a) => a.isDefault)
            : (list.isNotEmpty ? list.first : null);
      }
    });
  }

  Future<void> _pickImage(ImageSource source) async {
    final l10n = AppLocalizations.of(context);
    try {
      final XFile? file = await _picker.pickImage(
        source: source,
        imageQuality: 70,
        maxWidth: 2000,
      );
      if (file == null || !mounted) return;
      setState(() => _prescription = File(file.path));
    } catch (e) {
      if (!mounted) return;
      _snack(
        source == ImageSource.camera ? l10n.couldNotOpenCamera : l10n.couldNotOpenGallery,
        error: true,
      );
    }
  }

  void _choosePrescriptionSource() {
    final l10n = AppLocalizations.of(context);
    showModalBottomSheet<void>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(l10n.addYourPrescription,
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            ),
            ListTile(
              leading: const Icon(Icons.photo_camera_outlined, color: AppColors.primary),
              title: Text(l10n.takeAPhoto),
              onTap: () {
                Navigator.pop(ctx);
                _pickImage(ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined, color: AppColors.primary),
              title: Text(l10n.chooseFromGallery),
              onTap: () {
                Navigator.pop(ctx);
                _pickImage(ImageSource.gallery);
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Future<void> _pickAddress() async {
    final l10n = AppLocalizations.of(context);
    final picked = await showModalBottomSheet<Object>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(l10n.selectDeliveryAddress,
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            ),
            ..._addresses.map((a) => ListTile(
                  leading: Icon(
                    a.id == _selected?.id ? Icons.radio_button_checked : Icons.radio_button_off,
                    color: AppColors.primary,
                  ),
                  title: Text(a.label),
                  subtitle: Text(a.address, maxLines: 2, overflow: TextOverflow.ellipsis),
                  onTap: () => Navigator.pop(ctx, a),
                )),
            const Divider(height: 1),
            ListTile(
              leading: const Icon(Icons.add, color: AppColors.primary),
              title: Text(l10n.addNewAddress),
              onTap: () => Navigator.pop(ctx, _addNewAddress),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
    if (!mounted) return;
    if (picked is PatientAddress) {
      setState(() => _selected = picked);
    } else if (identical(picked, _addNewAddress)) {
      await Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const AddressesScreen()),
      );
      if (!mounted) return;
      _loadAddresses();
    }
  }

  Future<void> _submit() async {
    final l10n = AppLocalizations.of(context);
    if (_prescription == null) {
      _snack(l10n.pleaseAttachPrescription);
      return;
    }
    if (_selected == null) {
      _snack(l10n.pleaseChooseDeliveryAddress);
      return;
    }

    setState(() => _isLoading = true);
    final result = await ServiceLocator.instance.bookings.orderWithPrescription(
      imagePath: _prescription!.path,
      deliveryAddress: _selected!.address,
      note: _note.text.trim().isEmpty ? null : _note.text.trim(),
    );
    if (!mounted) return;
    setState(() => _isLoading = false);

    switch (result) {
      case Success(data: final orderId):
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => OrderTrackingScreen(orderId: orderId)),
        );
      case Failure(message: final msg):
        _snack(msg, error: true);
    }
  }

  void _snack(String msg, {bool error = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: error ? AppColors.error : AppColors.textSecondary),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: AppBar(
        title: Text(l10n.hiraalPharma),
        leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => Navigator.pop(context)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const MyOrdersScreen()),
            ),
            child: Text(l10n.myOrders),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l10n.uploadYourPrescription,
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
            const SizedBox(height: 4),
            Text(
              l10n.uploadPrescriptionExplain,
              style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 16),
            _prescriptionPicker(l10n),
            const SizedBox(height: 20),
            Text(l10n.noteForPharmacistOptional,
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            TextField(
              controller: _note,
              maxLines: 3,
              decoration: InputDecoration(
                hintText: l10n.noteForPharmacistHint,
              ),
            ),
            const SizedBox(height: 20),
            Text(l10n.deliveryAddress, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            _addressTile(l10n),
            const SizedBox(height: 16),
            Row(
              children: [
                const Icon(Icons.verified_user, size: 14, color: AppColors.success),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(l10n.prescriptionPrivacyNote,
                      style: const TextStyle(fontSize: 12, color: AppColors.success)),
                ),
              ],
            ),
            const SizedBox(height: 28),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _submit,
                child: _isLoading
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.white))
                    : Text(l10n.submitPrescription),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _prescriptionPicker(AppLocalizations l10n) {
    if (_prescription != null) {
      return Stack(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.file(
              _prescription!,
              width: double.infinity,
              height: 220,
              fit: BoxFit.cover,
            ),
          ),
          Positioned(
            top: 8,
            right: 8,
            child: Material(
              color: Colors.black54,
              shape: const CircleBorder(),
              child: InkWell(
                customBorder: const CircleBorder(),
                onTap: _choosePrescriptionSource,
                child: const Padding(
                  padding: EdgeInsets.all(8),
                  child: Icon(Icons.edit, color: Colors.white, size: 18),
                ),
              ),
            ),
          ),
        ],
      );
    }
    return InkWell(
      onTap: _choosePrescriptionSource,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: double.infinity,
        height: 180,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.primary, width: 1.5, style: BorderStyle.solid),
          color: AppColors.primary.withValues(alpha: 0.04),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.add_a_photo_outlined, size: 40, color: AppColors.primary),
            const SizedBox(height: 12),
            Text(l10n.tapToAddPrescriptionPhoto,
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: AppColors.primary)),
            const SizedBox(height: 4),
            Text(l10n.cameraOrGallery, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
          ],
        ),
      ),
    );
  }

  Widget _addressTile(AppLocalizations l10n) {
    if (_loadingAddresses) {
      return const Padding(padding: EdgeInsets.all(12), child: Center(child: CircularProgressIndicator()));
    }
    if (_selected == null) {
      return OutlinedButton.icon(
        onPressed: _pickAddress,
        icon: const Icon(Icons.add_location_alt_outlined, size: 18),
        label: Text(l10n.addADeliveryAddress),
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primary,
          side: const BorderSide(color: AppColors.primary),
          padding: const EdgeInsets.symmetric(vertical: 14),
        ),
      );
    }
    return InkWell(
      onTap: _pickAddress,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.cardBorder),
        ),
        child: Row(
          children: [
            const Icon(Icons.location_on, size: 18, color: AppColors.primary),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(_selected!.label, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
                  const SizedBox(height: 2),
                  Text(_selected!.address,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                ],
              ),
            ),
            Text(l10n.change, style: const TextStyle(fontSize: 12, color: AppColors.primary)),
          ],
        ),
      ),
    );
  }
}
