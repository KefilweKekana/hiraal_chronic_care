import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/result.dart';
import '../../providers/app_provider.dart';
import '../../services/service_locator.dart';
import '../profile/addresses_screen.dart';

class MedicineOrderScreen extends StatefulWidget {
  const MedicineOrderScreen({super.key});

  @override
  State<MedicineOrderScreen> createState() => _MedicineOrderScreenState();
}

class _MedicineOrderScreenState extends State<MedicineOrderScreen> {
  bool _isRequested = false;
  bool _isLoading = false;

  Future<void> _orderMedicine() async {
    setState(() { _isLoading = true; });
    final result = await ServiceLocator.instance.bookings.orderMedicine(
      medications: ['Amlodipine 5mg', 'Metformin 500mg', 'Vitamin D3'],
      deliveryAddress: '123 Health Ave, City, Country - 12345',
    );
    if (!mounted) return;
    setState(() { _isLoading = false; });
    switch (result) {
      case Success():
        setState(() { _isRequested = true; });
      case Failure(message: final msg):
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(msg), backgroundColor: AppColors.error),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isRequested) return _buildConfirmation(context);

    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: AppBar(
        title: const Text('Medicine Order'),
        leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => Navigator.pop(context)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Your Prescriptions', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
            const SizedBox(height: 12),
            _MedicineItem(name: 'Amlodipine 5mg', dosage: 'Once daily', icon: Icons.medication),
            _MedicineItem(name: 'Metformin 500mg', dosage: 'Twice daily', icon: Icons.medication),
            _MedicineItem(name: 'Vitamin D3', dosage: 'Once daily', icon: Icons.medication),
            const SizedBox(height: 20),
            const Text('Delivery Details', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.cardBorder),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      const Icon(Icons.home, size: 18, color: AppColors.primary),
                      const SizedBox(width: 10),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Home', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
                            Text('123 Health Ave, City, Country - 12345', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                          ],
                        ),
                      ),
                      GestureDetector(
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(builder: (_) => const AddressesScreen()),
                          );
                        },
                        child: const Text('Change >', style: TextStyle(fontSize: 12, color: AppColors.primary)),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: const [
                Icon(Icons.verified_user, size: 14, color: AppColors.success),
                SizedBox(width: 4),
                Text('Your medicines will be handled with care\nand delivered safely to you.', style: TextStyle(fontSize: 12, color: AppColors.success)),
              ],
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity, height: 56,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _orderMedicine,
                child: _isLoading
                    ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.white))
                    : const Text('Request Medicine'),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildConfirmation(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: AppBar(title: const Text('Medicine Order')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Container(
              width: 72, height: 72,
              decoration: const BoxDecoration(color: AppColors.success, shape: BoxShape.circle),
              child: const Icon(Icons.check, color: AppColors.white, size: 40),
            ),
            const SizedBox(height: 16),
            const Text('Request Sent!', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            const Text('We have received your medicine request.\nOur team will prepare it and notify you shortly.', textAlign: TextAlign.center, style: TextStyle(color: AppColors.textSecondary)),
            const SizedBox(height: 24),
            // Progress steps
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _StepCircle(label: 'Requested', isActive: true, isDone: true),
                _StepLine(isActive: false),
                _StepCircle(label: 'Preparing', isActive: false, isDone: false),
                _StepLine(isActive: false),
                _StepCircle(label: 'Ready for Delivery', isActive: false, isDone: false),
              ],
            ),
            const SizedBox(height: 24),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.cardBorder),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Request Details', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 12),
                  _DetailRow(label: 'Patient', value: context.read<AppProvider>().patient?.name ?? 'Patient'),
                  const _DetailRow(label: 'Requested Medicines', value: 'Blood Pressure Medicine'),
                  _DetailRow(label: 'Requested On', value: DateFormat('MMM dd, yyyy').format(DateTime.now())),
                  const _DetailRow(label: 'Delivery To', value: 'Home\n123 Health Ave, City, Country - 12345'),
                ],
              ),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity, height: 56,
              child: ElevatedButton.icon(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.home, size: 18),
                label: const Text('Back to Home'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MedicineItem extends StatelessWidget {
  final String name;
  final String dosage;
  final IconData icon;

  const _MedicineItem({required this.name, required this.dosage, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Row(
        children: [
          Container(
            width: 36, height: 36,
            decoration: BoxDecoration(color: AppColors.primaryLight, borderRadius: BorderRadius.circular(8)),
            child: Icon(icon, size: 20, color: AppColors.primary),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(name, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
              Text(dosage, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
            ],
          ),
          const Spacer(),
          const Icon(Icons.check_circle, size: 20, color: AppColors.success),
        ],
      ),
    );
  }
}

class _StepCircle extends StatelessWidget {
  final String label;
  final bool isActive;
  final bool isDone;

  const _StepCircle({required this.label, required this.isActive, required this.isDone});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 28, height: 28,
          decoration: BoxDecoration(
            color: isDone ? AppColors.success : (isActive ? AppColors.primary : AppColors.inputBackground),
            shape: BoxShape.circle,
            border: Border.all(color: isDone ? AppColors.success : AppColors.cardBorder),
          ),
          child: isDone ? const Icon(Icons.check, color: AppColors.white, size: 16) : null,
        ),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(fontSize: 9, color: AppColors.textSecondary)),
      ],
    );
  }
}

class _StepLine extends StatelessWidget {
  final bool isActive;
  const _StepLine({required this.isActive});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 40, height: 2,
      margin: const EdgeInsets.only(bottom: 16),
      color: isActive ? AppColors.success : AppColors.cardBorder,
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;
  const _DetailRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 120, child: Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textSecondary))),
          Expanded(child: Text(value, style: const TextStyle(fontSize: 13))),
        ],
      ),
    );
  }
}
