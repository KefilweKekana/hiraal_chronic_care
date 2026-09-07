import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/result.dart';
import '../../l10n/app_localizations.dart';
import '../../providers/app_provider.dart';
import '../../services/service_locator.dart';
import '../alerts/contact_care_team_screen.dart';
import 'book_doctor_screen.dart';
import 'lab_test_screen.dart';
import 'medicine_order_screen.dart';
import 'video_visits_screen.dart';
import '../sponsor/sponsor_care_screen.dart';

class ServicesScreen extends StatefulWidget {
  const ServicesScreen({super.key});

  @override
  State<ServicesScreen> createState() => _ServicesScreenState();
}

class _ServicesScreenState extends State<ServicesScreen> {
  List<Map<String, dynamic>> _doctors = [];
  bool _loadingDoctors = true;

  @override
  void initState() {
    super.initState();
    _fetchDoctors();
  }

  Future<void> _fetchDoctors() async {
    final result = await ServiceLocator.instance.bookings.getDoctors();
    if (!mounted) return;
    setState(() {
      _loadingDoctors = false;
      if (result case Success(data: final list)) {
        _doctors = list;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final provider = context.watch<AppProvider>();
    final patient = provider.patient;
    final now = DateTime.now();
    final greeting = now.hour < 12
        ? l10n.greetingMorning
        : now.hour < 17
            ? l10n.greetingAfternoon
            : l10n.greetingEvening;
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 8),
              // Greeting
              Row(
                children: [
                  CircleAvatar(
                    radius: 20,
                    backgroundColor: AppColors.primaryLight,
                    child: Text(patient?.name.split(' ').where((n) => n.isNotEmpty).map((n) => n[0]).take(2).join() ?? 'AA', style: const TextStyle(fontWeight: FontWeight.w600, color: AppColors.primary, fontSize: 12)),
                  ),
                  const SizedBox(width: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(greeting, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                      Text(patient?.name ?? l10n.patientFallback, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                    ],
                  ),
                  const Spacer(),
                  GestureDetector(
                    onTap: () => Navigator.pushNamed(context, '/notifications'),
                    child: Stack(
                      children: [
                        const Icon(Icons.notifications_outlined),
                        if (provider.unreadNotificationCount > 0)
                          Positioned(
                            right: 0, top: 0,
                            child: Container(
                              width: 14, height: 14,
                              decoration: const BoxDecoration(color: AppColors.error, shape: BoxShape.circle),
                              child: Center(child: Text('${provider.unreadNotificationCount}', style: const TextStyle(color: AppColors.white, fontSize: 8, fontWeight: FontWeight.w700))),
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Text(
                l10n.servicesTitle,
                style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
              ),
              const SizedBox(height: 14),
              _ServiceRow(
                icon: Icons.calendar_month,
                color: AppColors.info,
                title: l10n.seeADoctor,
                subtitle: l10n.seeADoctorHint,
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const BookDoctorScreen())),
              ),
              _ServiceRow(
                icon: Icons.local_pharmacy,
                color: AppColors.success,
                title: l10n.getMedicine,
                subtitle: l10n.getMedicineHint,
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const MedicineOrderScreen())),
              ),
              _ServiceRow(
                icon: Icons.science,
                color: AppColors.warning,
                title: l10n.bloodTest,
                subtitle: l10n.bloodTestHint,
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const LabTestScreen())),
              ),
              const SizedBox(height: 8),
              _ServiceRow(
                icon: Icons.headset_mic_outlined,
                color: AppColors.primary,
                title: l10n.talkToCareTeam,
                subtitle: l10n.talkToCareTeamHint,
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ContactCareTeamScreen())),
              ),
              _ServiceRow(
                icon: Icons.volunteer_activism_outlined,
                color: AppColors.chartPurple,
                title: l10n.sponsorCareCard,
                subtitle: l10n.sponsorCareCardSubtitle,
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SponsorCareScreen())),
              ),
              const SizedBox(height: 20),
              Text(l10n.upcomingShort, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
              const SizedBox(height: 8),
              const SizedBox(height: 12),
              if (_loadingDoctors)
                const Center(child: Padding(padding: EdgeInsets.symmetric(vertical: 8), child: CircularProgressIndicator(strokeWidth: 2)))
              else
                ..._doctors.take(3).map((d) => _RecommendedCard(
                  icon: Icons.person,
                  iconColor: AppColors.primary,
                  title: d['practitioner_name'] ?? d['name'] ?? l10n.doctorFallback,
                  subtitle: d['department'] ?? l10n.departmentGeneral,
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const BookDoctorScreen())),
                )),
              _RecommendedCard(
                icon: Icons.video_camera_front,
                iconColor: AppColors.primary,
                title: l10n.yourVideoVisits,
                subtitle: l10n.joinLiveVideo,
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const VideoVisitsScreen())),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}

class _ServiceRow extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _ServiceRow({
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
            child: Row(
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: AppColors.white,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, color: color, size: 28),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: const TextStyle(fontSize: 14, color: AppColors.textSecondary, height: 1.3),
                      ),
                    ],
                  ),
                ),
                Icon(Icons.arrow_forward, color: color, size: 22),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _RecommendedCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _RecommendedCard({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.cardBorder),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: iconColor, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                  Text(subtitle, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: AppColors.textTertiary),
          ],
        ),
      ),
    );
  }
}

