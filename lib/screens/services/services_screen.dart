import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/result.dart';
import '../../providers/app_provider.dart';
import '../../services/service_locator.dart';
import 'book_doctor_screen.dart';
import 'lab_test_screen.dart';
import 'medicine_order_screen.dart';

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
    final provider = context.watch<AppProvider>();
    final patient = provider.patient;
    final now = DateTime.now();
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
                    child: Text(patient?.name.split(' ').map((n) => n[0]).take(2).join() ?? 'AA', style: const TextStyle(fontWeight: FontWeight.w600, color: AppColors.primary, fontSize: 12)),
                  ),
                  const SizedBox(width: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(now.hour < 12 ? 'Good morning,' : now.hour < 17 ? 'Good afternoon,' : 'Good evening,', style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                      Text(patient?.name ?? 'Patient', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
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
              const Text(
                'Services',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
              ),
              const SizedBox(height: 4),
              const Text(
                "Choose how you'd like to get care today.",
                style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
              ),
              const SizedBox(height: 12),
              // Search bar
              TextField(
                decoration: InputDecoration(
                  hintText: 'Search services, doctors, or medicines...',
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
                      title: 'Book Doctor',
                      subtitle: 'Consult with a\ndoctor online',
                      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const BookDoctorScreen())),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _ServiceCard(
                      icon: Icons.medication,
                      iconColor: AppColors.success,
                      title: 'Order Medicine',
                      subtitle: 'Get medicines\ndelivered',
                      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const MedicineOrderScreen())),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _ServiceCard(
                      icon: Icons.science,
                      iconColor: AppColors.warning,
                      title: 'Lab Test',
                      subtitle: 'Book tests near\nyou',
                      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const LabTestScreen())),
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
                child: const Row(
                  children: [
                    Icon(Icons.verified, size: 16, color: AppColors.primary),
                    SizedBox(width: 8),
                    Text(
                      'Quick, secure, and reliable healthcare at your fingertips.',
                      style: TextStyle(fontSize: 12, color: AppColors.primary),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              // Recommended
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: const [
                  Text('Recommended for You', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                  Text('View all', style: TextStyle(fontSize: 13, color: AppColors.primary, fontWeight: FontWeight.w600)),
                ],
              ),
              const SizedBox(height: 12),
              if (_loadingDoctors)
                const Center(child: Padding(padding: EdgeInsets.symmetric(vertical: 8), child: CircularProgressIndicator(strokeWidth: 2)))
              else
                ..._doctors.take(3).map((d) => _RecommendedCard(
                  icon: Icons.person,
                  iconColor: AppColors.primary,
                  title: d['practitioner_name'] ?? d['name'] ?? 'Doctor',
                  subtitle: d['department'] ?? 'General',
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const BookDoctorScreen())),
                )),
              _RecommendedCard(
                icon: Icons.medication,
                iconColor: AppColors.success,
                title: 'Refill Your Medicines',
                subtitle: 'Quickly order your regular\nprescriptions',
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
              const Text('Popular Categories', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _CategoryChip(icon: Icons.favorite, label: 'Heart Care', color: AppColors.error, onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const BookDoctorScreen()))),
                  _CategoryChip(icon: Icons.air, label: 'Chest Care', color: AppColors.primary, onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const BookDoctorScreen()))),
                  _CategoryChip(icon: Icons.water_drop, label: 'Diabetes Care', color: AppColors.warning, onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const BookDoctorScreen()))),
                  _CategoryChip(icon: Icons.psychology, label: 'Mental Health', color: AppColors.chartPurple, onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const BookDoctorScreen()))),
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
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: const TextStyle(fontSize: 10, color: AppColors.textTertiary),
              textAlign: TextAlign.center,
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
          Text(label, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
        ],
      ),
    );
  }
}
