import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/result.dart';
import '../../l10n/app_localizations.dart';
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
import 'language_screen.dart';
import 'subscription_screen.dart';
import 'payment_history_screen.dart';
import '../services/appointments_screen.dart';
import '../services/lab_tests_screen.dart';
import '../services/my_orders_screen.dart';
import '../caregivers/caregivers_screen.dart';
import '../sponsor/sponsor_care_screen.dart';
import '../sponsor/my_sponsorship_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  ActivityCounts? _counts;
  bool _loggingOut = false;

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

  Future<void> _logout(AppProvider provider) async {
    if (_loggingOut) return;
    setState(() => _loggingOut = true);
    try {
      await provider.logout();
    } catch (_) {
      if (mounted) {
        final l10n = AppLocalizations.of(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.couldNotLogOut)),
        );
      }
    } finally {
      if (mounted) setState(() => _loggingOut = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    final patient = provider.patient;
    final l10n = AppLocalizations.of(context);

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
                  Text(l10n.profileTitle, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w700)),
                  GestureDetector(
                    onTap: () => Navigator.pushNamed(context, '/notifications'),
                    child: Stack(
                      children: [
                        const Icon(Icons.notifications_outlined),
                        if (provider.unreadNotificationCount > 0)
                          Positioned(
                            right: 0, top: 0,
                            child: Container(width: 14, height: 14, decoration: const BoxDecoration(color: AppColors.error, shape: BoxShape.circle),
                              child: Center(child: Text('${provider.unreadNotificationCount}', style: const TextStyle(color: AppColors.white, fontSize: 8, fontWeight: FontWeight.w700))),
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
                        patient?.name.split(' ').where((n) => n.isNotEmpty).map((n) => n[0]).take(2).join() ?? 'AA',
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: AppColors.primary),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(patient?.name ?? l10n.patientFallback, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
                          Text(
                            l10n.memberId((patient != null && patient.patientId.isNotEmpty) ? patient.patientId : '—'),
                            style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
                          ),
                          Text(patient?.phone ?? '', style: const TextStyle(fontSize: 12, color: AppColors.textTertiary)),
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
                        children: [
                          const Icon(Icons.edit, size: 14, color: AppColors.primary),
                          const SizedBox(width: 4),
                          Text(l10n.edit, style: const TextStyle(color: AppColors.primary)),
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
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(l10n.yourProgram, style: const TextStyle(fontSize: 12, color: AppColors.textTertiary)),
                        const SizedBox(height: 2),
                        Text(l10n.programHypertensionCare, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                        Text(l10n.memberSinceMay2024, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                      ],
                    ),
                    const Spacer(),
                    StatusBadge(text: l10n.statusActive, color: AppColors.success, icon: Icons.check_circle),
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
              Text(l10n.myInformation, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
              const SizedBox(height: 10),
              _buildNavMenuItem(context, Icons.person, l10n.personalInformation, l10n.updatePersonalDetails, const PersonalInfoScreen()),
              _buildNavMenuItem(context, Icons.health_and_safety, l10n.healthInformation, l10n.viewHealthSummary, const HealthInfoScreen()),
              _buildNavMenuItem(context, Icons.medical_information, l10n.medicalHistory, l10n.viewPastRecords, const MedicalHistoryScreen()),
              _buildNavMenuItem(context, Icons.location_on, l10n.addresses, l10n.manageAddresses, const AddressesScreen()),
              const SizedBox(height: 20),
              // My Activity
              Text(l10n.myActivity, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(child: _ActivityCard(icon: Icons.calendar_today, value: l10n.countUpcoming('${_counts?.upcomingAppointments ?? '—'}'), label: l10n.appointments, onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AppointmentsScreen())))),
                  const SizedBox(width: 8),
                  Expanded(child: _ActivityCard(icon: Icons.science, value: l10n.countScheduled('${_counts?.scheduledLabTests ?? '—'}'), label: l10n.labTests, onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const MyLabTestsScreen())))),
                  const SizedBox(width: 8),
                  Expanded(child: _ActivityCard(icon: Icons.shopping_bag, value: l10n.countActive('${_counts?.activeOrders ?? '—'}'), label: l10n.orders, onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const MyOrdersScreen())))),
                ],
              ),
              const SizedBox(height: 20),
              // Account
              Text(l10n.account, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
              const SizedBox(height: 10),
              _buildNavMenuItem(context, Icons.card_membership, l10n.subscription, l10n.subscriptionSubtitle, const SubscriptionScreen()),
              _buildNavMenuItem(context, Icons.people_outline, l10n.caregiversMenu, l10n.caregiversMenuSubtitle, const CaregiversScreen()),
              _buildNavMenuItem(context, Icons.volunteer_activism_outlined, l10n.sponsorCareMenu, l10n.sponsorCareMenuSubtitle, const SponsorCareScreen()),
              _buildNavMenuItem(context, Icons.favorite_border, l10n.mySponsorshipMenu, l10n.mySponsorshipMenuSubtitle, const MySponsorshipScreen()),
              _buildNavMenuItem(context, Icons.receipt_long, l10n.payments, l10n.paymentsSubtitle, const PaymentHistoryScreen()),
              _buildNavMenuItem(context, Icons.lock, l10n.privacyAndSecurity, l10n.manageAccountSecurity, const PrivacySecurityScreen()),
              _buildNavMenuItem(context, Icons.language, l10n.language, l10n.languageSubtitle, const LanguageScreen()),
              _buildNavMenuItem(context, Icons.settings, l10n.settings, l10n.settingsSubtitle, const SettingsScreen()),
              GestureDetector(
                onTap: _loggingOut ? null : () => _logout(provider),
                child: _ProfileMenuItem(icon: Icons.logout, title: l10n.logOut, subtitle: '', iconColor: AppColors.error),
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
