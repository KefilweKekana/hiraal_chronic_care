import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/result.dart';
import '../../providers/app_provider.dart';
import '../../services/activity_service.dart';
import '../../services/service_locator.dart';
import '../../widgets/shared_widgets.dart';
import 'personal_info_screen.dart';
import 'health_info_screen.dart';
import 'medical_history_screen.dart';
import 'addresses_screen.dart';
import 'privacy_security_screen.dart';
import 'settings_screen.dart';
import '../services/book_doctor_screen.dart';
import '../services/lab_test_screen.dart';
import '../services/medicine_order_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  ActivityCounts? _counts;

  @override
  void initState() {
    super.initState();
    _loadCounts();
  }

  Future<void> _loadCounts() async {
    final result = await ServiceLocator.instance.activity.getCounts('');
    if (mounted) {
      setState(() {
        if (result case Success(data: final data)) _counts = data;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    final patient = provider.patient;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Profile', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700)),
                  GestureDetector(
                    onTap: () => Navigator.pushNamed(context, '/notifications'),
                    child: Stack(
                      children: [
                        const Icon(Icons.notifications_outlined),
                        Positioned(
                          right: 0, top: 0,
                          child: Container(width: 14, height: 14, decoration: const BoxDecoration(color: AppColors.error, shape: BoxShape.circle),
                            child: const Center(child: Text('3', style: TextStyle(color: AppColors.white, fontSize: 8, fontWeight: FontWeight.w700))),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              // Patient info card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.cardBorder),
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 30,
                      backgroundColor: AppColors.primaryLight,
                      child: Text(
                        patient?.name.split(' ').map((n) => n[0]).take(2).join() ?? 'AA',
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: AppColors.primary),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(patient?.name ?? 'Amina Ahmed', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
                          Text('Member ID: ${patient?.patientId ?? 'PAT123456'}', style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
                          Text(patient?.phone ?? '', style: const TextStyle(fontSize: 12, color: AppColors.textTertiary)),
                          Text('${patient?.name.toLowerCase().replaceAll(' ', '.')}@hiraal.com', style: const TextStyle(fontSize: 12, color: AppColors.textTertiary)),
                        ],
                      ),
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => const PersonalInfoScreen()),
                        );
                      },
                      child: Row(
                        children: const [
                          Icon(Icons.edit, size: 14, color: AppColors.primary),
                          SizedBox(width: 4),
                          Text('Edit', style: TextStyle(color: AppColors.primary)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              // Program
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.cardBorder),
                ),
                child: Row(
                  children: [
                    const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Your Program', style: TextStyle(fontSize: 12, color: AppColors.textTertiary)),
                        SizedBox(height: 2),
                        Text('Hypertension Care', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                        Text('Member since May 2024', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                      ],
                    ),
                    const Spacer(),
                    const StatusBadge(text: 'Active', color: AppColors.success, icon: Icons.check_circle),
                    const SizedBox(width: 8),
                    Container(
                      width: 36, height: 36,
                      decoration: BoxDecoration(
                        color: AppColors.success.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.favorite, color: AppColors.success, size: 20),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              // My Information
              const Text('My Information', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
              const SizedBox(height: 10),
              _buildNavMenuItem(context, Icons.person, 'Personal Information', 'Update your personal details', const PersonalInfoScreen()),
              _buildNavMenuItem(context, Icons.health_and_safety, 'Health Information', 'View your health summary', const HealthInfoScreen()),
              _buildNavMenuItem(context, Icons.medical_information, 'Medical History', 'View your past records', const MedicalHistoryScreen()),
              _buildNavMenuItem(context, Icons.location_on, 'Addresses', 'Manage your addresses', const AddressesScreen()),
              const SizedBox(height: 20),
              // My Activity
              const Text('My Activity', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(child: _ActivityCard(icon: Icons.calendar_today, value: '${_counts?.upcomingAppointments ?? '—'} Upcoming', label: 'Appointments', onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const BookDoctorScreen())))),
                  const SizedBox(width: 8),
                  Expanded(child: _ActivityCard(icon: Icons.science, value: '${_counts?.scheduledLabTests ?? '—'} Scheduled', label: 'Lab Tests', onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const LabTestScreen())))),
                  const SizedBox(width: 8),
                  Expanded(child: _ActivityCard(icon: Icons.shopping_bag, value: '${_counts?.activeOrders ?? '—'} Active', label: 'Orders', onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const MedicineOrderScreen())))),
                ],
              ),
              const SizedBox(height: 20),
              // Account
              const Text('Account', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
              const SizedBox(height: 10),
              _buildNavMenuItem(context, Icons.lock, 'Privacy & Security', 'Manage your account security', const PrivacySecurityScreen()),
              _buildNavMenuItem(context, Icons.settings, 'Settings', 'Notifications, language, and more', const SettingsScreen()),
              GestureDetector(
                onTap: () => provider.logout(),
                child: _ProfileMenuItem(icon: Icons.logout, title: 'Log Out', subtitle: '', iconColor: AppColors.error),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
  Widget _buildNavMenuItem(BuildContext context, IconData icon, String title, String subtitle, Widget screen) {
    return GestureDetector(
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => screen)),
      child: _ProfileMenuItem(icon: icon, title: title, subtitle: subtitle),
    );
  }
}

class _ProfileMenuItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color? iconColor;

  const _ProfileMenuItem({required this.icon, required this.title, required this.subtitle, this.iconColor});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 3),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Row(
        children: [
          Container(
            width: 36, height: 36,
            decoration: BoxDecoration(
              color: (iconColor ?? AppColors.primary).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 18, color: iconColor ?? AppColors.primary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: iconColor ?? AppColors.textPrimary)),
                if (subtitle.isNotEmpty) Text(subtitle, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
              ],
            ),
          ),
          const Icon(Icons.chevron_right, color: AppColors.textTertiary, size: 20),
        ],
      ),
    );
  }
}

class _ActivityCard extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  final VoidCallback onTap;

  const _ActivityCard({required this.icon, required this.value, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        children: [
          Icon(icon, size: 20, color: AppColors.primary),
          const SizedBox(height: 6),
          Text(value, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
          Text(label, style: const TextStyle(fontSize: 10, color: AppColors.textTertiary)),
        ],
      ),
    ),
    );
  }
}
