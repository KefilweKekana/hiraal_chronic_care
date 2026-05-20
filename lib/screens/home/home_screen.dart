import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/validators.dart';
import '../../models/vital_reading.dart';
import '../../providers/app_provider.dart';
import '../../widgets/shared_widgets.dart';
import '../alerts/high_bp_alert_screen.dart';
import '../devices/device_pairing_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _formKey = GlobalKey<FormState>();
  final _systolicController = TextEditingController();
  final _diastolicController = TextEditingController();
  final _sugarController = TextEditingController();
  final _weightController = TextEditingController();
  final _noteController = TextEditingController();
  bool? _medicineTaken;
  bool _isSending = false;
  bool _isSent = false;

  @override
  void dispose() {
    _systolicController.dispose();
    _diastolicController.dispose();
    _sugarController.dispose();
    _weightController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  bool get _isFormValid =>
      _systolicController.text.isNotEmpty &&
      _diastolicController.text.isNotEmpty &&
      _sugarController.text.isNotEmpty &&
      _weightController.text.isNotEmpty;

  Future<void> _submitReading() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() => _isSending = true);
    
    final systolic = int.tryParse(_systolicController.text) ?? 0;
    final diastolic = int.tryParse(_diastolicController.text) ?? 0;
    final sugar = double.tryParse(_sugarController.text) ?? 0;
    final weight = double.tryParse(_weightController.text) ?? 0;
    
    final reading = VitalReading(
      referenceId: 'SUB-${DateFormat('yyyy-MMdd-HHmm').format(DateTime.now())}',
      date: DateTime.now(),
      systolic: systolic,
      diastolic: diastolic,
      bloodSugar: sugar,
      weight: weight,
      medicineTaken: _medicineTaken,
      note: _noteController.text.isEmpty ? null : _noteController.text,
      status: 'Sent',
    );

    if (mounted) {
      final success = await context.read<AppProvider>().submitReading(reading);
      if (!mounted) return;

      setState(() {
        _isSending = false;
        _isSent = success;
      });

      if (!success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(context.read<AppProvider>().errorMessage ?? 'Failed to submit reading'),
            backgroundColor: AppColors.error,
          ),
        );
        return;
      }

      // Check if alert needed
      if (systolic >= 160 || diastolic >= 100) {
        if (mounted) {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => HighBpAlertScreen(reading: reading),
            ),
          );
        }
      }
    }
  }

  void _resetForm() {
    setState(() {
      _isSent = false;
      _systolicController.clear();
      _diastolicController.clear();
      _sugarController.clear();
      _weightController.clear();
      _noteController.clear();
      _medicineTaken = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    final patient = provider.patient;
    final now = DateTime.now();

    if (_isSent) {
      return _buildSuccessView(provider);
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Stack(
          children: [
            Form(
            key: _formKey,
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 16),
                  // Greeting header
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 22,
                        backgroundColor: AppColors.primaryLight,
                        child: Text(
                          patient?.name.split(' ').map((n) => n[0]).take(2).join() ?? 'AA',
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            now.hour < 12 ? 'Good morning,' : now.hour < 17 ? 'Good afternoon,' : 'Good evening,',
                            style: TextStyle(
                              fontSize: 13,
                              color: AppColors.textSecondary,
                            ),
                          ),
                          Text(
                            patient?.name ?? 'Patient',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ],
                      ),
                      const Spacer(),
                      Stack(
                        children: [
                          IconButton(
                            onPressed: () => Navigator.pushNamed(context, '/notifications'),
                            icon: const Icon(
                              Icons.notifications_outlined,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          if (provider.unreadNotificationCount > 0)
                            Positioned(
                              right: 8,
                              top: 8,
                              child: Container(
                                width: 18,
                                height: 18,
                                decoration: const BoxDecoration(
                                  color: AppColors.error,
                                  shape: BoxShape.circle,
                                ),
                                child: Center(
                                  child: Text(
                                    '${provider.unreadNotificationCount}',
                                    style: const TextStyle(
                                      color: AppColors.white,
                                      fontSize: 10,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  // Date and last submitted
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.cardBorder),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.calendar_today, size: 16, color: AppColors.primary),
                        const SizedBox(width: 8),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              "Today's Date",
                              style: TextStyle(fontSize: 11, color: AppColors.textTertiary),
                            ),
                            Text(
                              DateFormat('MMM dd, yyyy').format(now),
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            Text(
                              DateFormat('EEEE').format(now),
                              style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                            ),
                          ],
                        ),
                        const Spacer(),
                        const Icon(Icons.access_time, size: 16, color: AppColors.textTertiary),
                        const SizedBox(width: 8),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Last Submitted',
                              style: TextStyle(fontSize: 11, color: AppColors.textTertiary),
                            ),
                            Text(
                              provider.readings.isNotEmpty
                                  ? DateFormat('MMM dd, yyyy').format(provider.readings.first.date)
                                  : '—',
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            Text(
                              provider.readings.isNotEmpty
                                  ? DateFormat('h:mm a').format(provider.readings.first.date)
                                  : 'No reading yet today',
                              style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Info banner
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.primarySurface,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      children: const [
                        Icon(Icons.info_outline, size: 16, color: AppColors.primary),
                        SizedBox(width: 8),
                        Text(
                          'Please enter your readings and send to your care team.',
                          style: TextStyle(fontSize: 12, color: AppColors.primary),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  // Today's Reading header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: const [
                      Text(
                        "Today's Reading",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      StatusBadge(text: 'Required', color: AppColors.primary),
                    ],
                  ),
                  const SizedBox(height: 16),
                  // Blood Pressure
                  _buildVitalSection(
                    icon: Icons.favorite,
                    iconColor: AppColors.error,
                    title: 'Blood Pressure',
                    subtitle: 'mmHg',
                    child: Row(
                      children: [
                        Expanded(
                          child: _buildInputField(
                            label: 'Systolic (Top)',
                            hint: 'e.g. 120',
                            controller: _systolicController,
                            validator: Validators.systolic,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildInputField(
                            label: 'Diastolic (Bottom)',
                            hint: 'e.g. 80',
                            controller: _diastolicController,
                            validator: Validators.diastolic,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Blood Sugar
                  _buildVitalSection(
                    icon: Icons.water_drop,
                    iconColor: AppColors.primary,
                    title: 'Blood Sugar',
                    subtitle: 'mg/dL',
                    child: _buildInputField(
                      label: '',
                      hint: 'e.g. 140',
                      controller: _sugarController,
                      validator: Validators.bloodSugar,
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Weight
                  _buildVitalSection(
                    icon: Icons.monitor_weight,
                    iconColor: AppColors.chartPurple,
                    title: 'Weight',
                    subtitle: 'kg',
                    child: _buildInputField(
                      label: '',
                      hint: 'e.g. 72',
                      controller: _weightController,
                      validator: Validators.weight,
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Medicine Taken
                  _buildVitalSection(
                    icon: Icons.medication,
                    iconColor: AppColors.success,
                    title: 'Medicine Taken',
                    subtitle: 'Did you take your medicine as prescribed?',
                    child: Row(
                      children: [
                        Expanded(
                          child: _buildMedicineButton(
                            label: 'Yes, taken',
                            icon: Icons.check_circle_outline,
                            isSelected: _medicineTaken == true,
                            color: AppColors.success,
                            onTap: () => setState(() => _medicineTaken = true),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildMedicineButton(
                            label: 'No, missed',
                            icon: Icons.cancel_outlined,
                            isSelected: _medicineTaken == false,
                            color: AppColors.error,
                            onTap: () => setState(() => _medicineTaken = false),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Add Note
                  const Text(
                    'Add Note (optional)',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _noteController,
                    maxLines: 2,
                    decoration: const InputDecoration(
                      hintText: 'How are you feeling today?',
                      prefixIcon: Icon(Icons.edit_note, size: 20),
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Connect Device
                  GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const DevicePairingScreen()),
                      );
                    },
                    child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppColors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.cardBorder),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.bluetooth,
                          color: provider.isDeviceConnected
                              ? AppColors.primary
                              : AppColors.textTertiary,
                        ),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Connect Device',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            Text(
                              'Import readings from your device',
                              style: TextStyle(
                                fontSize: 12,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                        const Spacer(),
                        if (provider.isDeviceConnected) ...[
                          Container(
                            width: 8,
                            height: 8,
                            decoration: const BoxDecoration(
                              color: AppColors.success,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 4),
                          const Text(
                            'Connected',
                            style: TextStyle(
                              fontSize: 12,
                              color: AppColors.success,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                        const SizedBox(width: 4),
                        const Icon(Icons.chevron_right, color: AppColors.textTertiary),
                      ],
                    ),
                  ),
                  ),
                  const SizedBox(height: 20),
                  // Save & Send button
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton.icon(
                      onPressed: _isFormValid ? _submitReading : null,
                      icon: const Icon(Icons.send, size: 20),
                      label: const Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text('Save & Send', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                          Text('Send reading to care team', style: TextStyle(fontSize: 11)),
                        ],
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _isFormValid
                            ? AppColors.primary
                            : AppColors.primary.withValues(alpha: 0.5),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
            ),
            // Sending overlay
            if (_isSending)
              Container(
                color: Colors.black.withValues(alpha: 0.3),
                child: Center(
                  child: Container(
                    margin: const EdgeInsets.all(40),
                    padding: const EdgeInsets.all(32),
                    decoration: BoxDecoration(
                      color: AppColors.white,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const CircularProgressIndicator(color: AppColors.primary),
                        const SizedBox(height: 20),
                        const Text(
                          'Submitting Your Reading...',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          "Please don't close the app while we send your data.",
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: const [
                            Icon(Icons.verified_user, size: 14, color: AppColors.success),
                            SizedBox(width: 4),
                            Text(
                              'Your data is secure and protected.',
                              style: TextStyle(fontSize: 12, color: AppColors.success),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildSuccessView(AppProvider provider) {
    final lastReading = provider.readings.first;
    return Scaffold(
      backgroundColor: AppColors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            children: [
              const SizedBox(height: 16),
              Row(
                children: [
                  CircleAvatar(
                    radius: 20,
                    backgroundColor: AppColors.primaryLight,
                    child: Text(
                      provider.patient?.name.split(' ').map((n) => n[0]).take(2).join() ?? '',
                      style: const TextStyle(fontWeight: FontWeight.w600, color: AppColors.primary, fontSize: 12),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                  const Text('Good morning,', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                      Text(provider.patient?.name ?? '', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 40),
              Container(
                width: 72,
                height: 72,
                decoration: const BoxDecoration(
                  color: AppColors.success,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.check, color: AppColors.white, size: 40),
              ),
              const SizedBox(height: 20),
              const Text(
                'All Set!',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
              ),
              const SizedBox(height: 8),
              const Text(
                'Your reading from today has been\nsaved and sent to your care team.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14, color: AppColors.textSecondary, height: 1.5),
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  Icon(Icons.verified_user, size: 14, color: AppColors.success),
                  SizedBox(width: 4),
                  Text(
                    'Your data is secure and your care team\nhas been notified.',
                    style: TextStyle(fontSize: 12, color: AppColors.success),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.cardBorder),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Submission Summary',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 16),
                    _summaryRow(Icons.calendar_today, 'Date', DateFormat('MMM dd, yyyy (EEEE)').format(lastReading.date)),
                    _summaryRow(Icons.access_time, 'Time', DateFormat('h:mm a').format(lastReading.date)),
                    _summaryRow(Icons.people, 'Sent To', 'Hiraal Health Center Care Team'),
                    _summaryRow(Icons.tag, 'Reference ID', lastReading.referenceId ?? 'N/A'),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.infoLight,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.info_outline, size: 16, color: AppColors.info),
                    SizedBox(width: 8),
                    Text(
                      'You will be notified when your care team\nreviews your reading.',
                      style: TextStyle(fontSize: 12, color: AppColors.info),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton.icon(
                  onPressed: _resetForm,
                  icon: const Icon(Icons.home, size: 20),
                  label: const Text('Go to Home'),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: OutlinedButton.icon(
                  onPressed: () {
                    _resetForm();
                    context.read<AppProvider>().setTab(2);
                  },
                  icon: const Icon(Icons.history, size: 18),
                  label: const Text('View History'),
                ),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _summaryRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: AppColors.textTertiary),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(fontSize: 12, color: AppColors.textTertiary)),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildVitalSection({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required Widget child,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 18, color: iconColor),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                Text(
                  subtitle,
                  style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 10),
        child,
      ],
    );
  }

  Widget _buildInputField({
    required String label,
    required String hint,
    required TextEditingController controller,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (label.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Text(
              label,
              style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
            ),
          ),
        TextFormField(
          controller: controller,
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          onChanged: (_) => setState(() {}),
          validator: validator,
          autovalidateMode: AutovalidateMode.onUserInteraction,
          decoration: InputDecoration(
            hintText: hint,
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          ),
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
        ),
      ],
    );
  }

  Widget _buildMedicineButton({
    required String label,
    required IconData icon,
    required bool isSelected,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: isSelected ? color.withValues(alpha: 0.1) : AppColors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? color : AppColors.cardBorder,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 18, color: isSelected ? color : AppColors.textTertiary),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: isSelected ? color : AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
