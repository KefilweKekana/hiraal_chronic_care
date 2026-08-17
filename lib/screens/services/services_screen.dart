import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/result.dart';
import '../../l10n/app_localizations.dart';
import '../../providers/app_provider.dart';
import '../../services/service_locator.dart';
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
                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
              ),
              const SizedBox(height: 4),
              Text(
                l10n.chooseCareToday,
                style: const TextStyle(fontSize: 14, color: AppColors.textSecondary),
              ),
              const SizedBox(height: 12),
              // Search bar
              TextField(
                decoration: InputDecoration(
                  hintText: l10n.searchServicesHint,
                  prefixIcon: const Icon(Icons.search, color: AppColors.textTertiary),
                  contentPadding: const EdgeInsets.symmetric(vertical: 14),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.inputBorder)),
                ),
              ),
              const SizedBox(height: 20),
              // Service cards
              Row(
                children: [
                  Expanded(
                    child: _ServiceCard(
                      icon: Icons.medical_services,
                      iconColor: AppColors.primary,
                      title: l10n.bookDoctor,
                      subtitle: l10n.bookDoctorSubtitle,
                      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const BookDoctorScreen())),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _ServiceCard(
                      icon: Icons.local_pharmacy,
                      iconColor: AppColors.success,
                      title: l10n.hiraalPharma,
                      subtitle: l10n.uploadPrescription,
                      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const MedicineOrderScreen())),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _ServiceCard(
                      icon: Icons.science,
                      iconColor: AppColors.warning,
                      title: l10n.labTest,
                      subtitle: l10n.labTestSubtitle,
                      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const LabTestScreen())),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _ServiceCard(
                      icon: Icons.volunteer_activism_outlined,
                      iconColor: AppColors.chartPurple,
                      title: l10n.sponsorCareCard,
                      subtitle: l10n.sponsorCareCardSubtitle,
                      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SponsorCareScreen())),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.primarySurface,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.verified, size: 16, color: AppColors.primary),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        l10n.quickSecureHealthcare,
                        style: const TextStyle(fontSize: 12, color: AppColors.primary),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              // Recommended
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(l10n.recommendedForYou, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                  Text(l10n.viewAll, style: const TextStyle(fontSize: 13, color: AppColors.primary, fontWeight: FontWeight.w600)),
                ],
              ),
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
              _RecommendedCard(
                icon: Icons.local_pharmacy,
                iconColor: AppColors.success,
                title: l10n.orderFromHiraalPharma,
                subtitle: l10n.uploadRxForDelivery,
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const MedicineOrderScreen())),
              ),
              _RecommendedCard(
                icon: Icons.science,
                iconColor: AppColors.error,
                title: 'Complete Blood Count (CBC)',
                subtitle: 'Common test  •  Results in 24 hrs',
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const LabTestScreen())),
              ),
              const SizedBox(height: 24),
              // Popular Categories
              Text(l10n.popularCategories, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _CategoryChip(icon: Icons.favorite, label: l10n.categoryHeartCare, color: AppColors.error, onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => BookDoctorScreen(specialtyLabel: l10n.categoryHeartCare, specialtyKeywords: const ['cardio', 'heart'])))),
                  _CategoryChip(icon: Icons.air, label: l10n.categoryChestCare, color: AppColors.primary, onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => BookDoctorScreen(specialtyLabel: l10n.categoryChestCare, specialtyKeywords: const ['pulmo', 'chest', 'respir', 'thorax'])))),
                  _CategoryChip(icon: Icons.water_drop, label: l10n.categoryDiabetesCare, color: AppColors.warning, onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => BookDoctorScreen(specialtyLabel: l10n.categoryDiabetesCare, specialtyKeywords: const ['endocrin', 'diabet'])))),
                  _CategoryChip(icon: Icons.psychology, label: l10n.categoryMentalHealth, color: AppColors.chartPurple, onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => BookDoctorScreen(specialtyLabel: l10n.categoryMentalHealth, specialtyKeywords: const ['psych', 'mental', 'behavio'])))),
                ],
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}

class _ServiceCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _ServiceCard({
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
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.cardBorder),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: iconColor, size: 24),
            ),
            const SizedBox(height: 10),
            Text(
              title,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textPrimary, height: 1.25),
              textAlign: TextAlign.center,
              softWrap: true,
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: const TextStyle(fontSize: 10, color: AppColors.textTertiary, height: 1.25),
              textAlign: TextAlign.center,
              softWrap: true,
            ),
            const SizedBox(height: 6),
            const Icon(Icons.arrow_forward, size: 16, color: AppColors.primary),
          ],
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

class _CategoryChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _CategoryChip({required this.icon, required this.label, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: color, size: 26),
          ),
          const SizedBox(height: 6),
          SizedBox(
            width: 72,
            child: Text(
              label,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 10, color: AppColors.textSecondary, height: 1.2),
            ),
          ),
        ],
      ),
    );
  }
}
