import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/result.dart';
import '../../services/address_service.dart';
import '../../services/location_service.dart';
import '../../services/service_locator.dart';

class AddressesScreen extends StatefulWidget {
  const AddressesScreen({super.key});

  @override
  State<AddressesScreen> createState() => _AddressesScreenState();
}

class _AddressesScreenState extends State<AddressesScreen> {
  List<PatientAddress> _addresses = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    final result = await ServiceLocator.instance.addresses.getAddresses('');
    if (!mounted) return;
    setState(() {
      _loading = false;
      switch (result) {
        case Success(data: final data):
          _addresses = data;
        case Failure(message: final msg):
          _error = msg;
      }
    });
  }

  IconData _iconFor(String type) => switch (type) {
    'home' => Icons.home,
    'clinic' => Icons.local_hospital,
    'work' => Icons.work,
    _ => Icons.location_on,
  };

  void _showAddDialog() {
    final labelCtrl = TextEditingController();
    final addressCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) {
        bool locating = false;
        return StatefulBuilder(
          builder: (ctx, setLocal) => AlertDialog(
            title: const Text('Add Address'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(controller: labelCtrl, decoration: const InputDecoration(labelText: 'Label (e.g. Home, Work)')),
                const SizedBox(height: 8),
                TextField(controller: addressCtrl, decoration: const InputDecoration(labelText: 'Address'), maxLines: 2),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: locating
                        ? null
                        : () async {
                            setLocal(() => locating = true);
                            final loc = await LocationService.instance.getCurrentLocation();
                            setLocal(() => locating = false);
                            if (loc == null) {
                              if (ctx.mounted) {
                                ScaffoldMessenger.of(ctx).showSnackBar(const SnackBar(
                                  content: Text('Could not get your location. Turn on GPS and allow location access.'),
                                ));
                              }
                              return;
                            }
                            addressCtrl.text = loc.address;
                            if (labelCtrl.text.trim().isEmpty && (loc.city?.isNotEmpty ?? false)) {
                              labelCtrl.text = loc.city!;
                            }
                          },
                    icon: locating
                        ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                        : const Icon(Icons.my_location, size: 18),
                    label: Text(locating ? 'Getting location…' : 'Use my current location'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.primary,
                      side: const BorderSide(color: AppColors.primary),
                    ),
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
              TextButton(
                onPressed: () async {
                  if (labelCtrl.text.isEmpty || addressCtrl.text.isEmpty) return;
                  final addr = PatientAddress(
                    id: '',
                    label: labelCtrl.text,
                    address: addressCtrl.text,
                    isDefault: false,
                    type: 'other',
                  );
                  Navigator.pop(ctx);
                  final result = await ServiceLocator.instance.addresses.addAddress('', addr);
                  if (!mounted) return;
                  switch (result) {
                    case Success():
                      _load();
                    case Failure(message: final msg):
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
                  }
                },
                child: const Text('Add'),
              ),
            ],
          ),
        );
      },
    ).whenComplete(() {
      labelCtrl.dispose();
      addressCtrl.dispose();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Addresses'),
        backgroundColor: AppColors.white,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(_error!, style: const TextStyle(color: AppColors.error)),
                    const SizedBox(height: 8),
                    TextButton(onPressed: _load, child: const Text('Retry')),
                  ],
                ))
              : RefreshIndicator(
                  onRefresh: _load,
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      ..._addresses.map((a) => _AddressCard(
                        label: a.label,
                        address: a.address,
                        isDefault: a.isDefault,
                        icon: _iconFor(a.type),
                        onDelete: () async {
                          await ServiceLocator.instance.addresses.deleteAddress(a.id);
                          _load();
                        },
                      )),
                      const SizedBox(height: 16),
                      OutlinedButton.icon(
                        onPressed: _showAddDialog,
                        icon: const Icon(Icons.add),
                        label: const Text('Add New Address'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.primary,
                          side: const BorderSide(color: AppColors.primary),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ],
                  ),
                ),
    );
  }
}

class _AddressCard extends StatelessWidget {
  final String label;
  final String address;
  final bool isDefault;
  final IconData icon;
  final VoidCallback onDelete;

  const _AddressCard({
    required this.label,
    required this.address,
    required this.isDefault,
    required this.icon,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: isDefault ? AppColors.primary.withValues(alpha: 0.3) : AppColors.cardBorder),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 18, color: AppColors.primary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(label, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                    if (isDefault) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.primarySurface,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Text('Default', style: TextStyle(fontSize: 10, color: AppColors.primary, fontWeight: FontWeight.w600)),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 4),
                Text(address, style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
              ],
            ),
          ),
          if (!isDefault)
            GestureDetector(
              onTap: onDelete,
              child: const Icon(Icons.delete_outline, size: 18, color: AppColors.textTertiary),
            ),
        ],
      ),
    );
  }
}
