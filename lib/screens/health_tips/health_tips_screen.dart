import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';

class HealthTipsScreen extends StatelessWidget {
  const HealthTipsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Health Tips')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Hero banner
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppColors.primary, AppColors.primaryDark],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  Container(
                    width: 48, height: 48,
                    decoration: BoxDecoration(
                      color: AppColors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.tips_and_updates, color: AppColors.white, size: 28),
                  ),
                  const SizedBox(width: 14),
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Small Steps, Better Health', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.white)),
                      Text('Daily habits can help you feel better\nand stay in control.', style: TextStyle(fontSize: 12, color: AppColors.white)),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            // Today's Tip
            const Align(
              alignment: Alignment.centerLeft,
              child: Text("Today's Tip", style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            ),
            const SizedBox(height: 10),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.cardBorder),
              ),
              child: Row(
                children: [
                  Container(
                    width: 44, height: 44,
                    decoration: BoxDecoration(
                      color: AppColors.errorLight,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.favorite, color: AppColors.error, size: 22),
                  ),
                  const SizedBox(width: 14),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Keep Your Blood Pressure in Check', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                        SizedBox(height: 4),
                        Text('Take your medicine as prescribed, avoid\ntoo much salt, and try to relax.', style: TextStyle(fontSize: 12, color: AppColors.textSecondary, height: 1.4)),
                        SizedBox(height: 4),
                        Text('Your health, your future.', style: TextStyle(fontSize: 12, color: AppColors.primary, fontStyle: FontStyle.italic)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            const Align(
              alignment: Alignment.centerLeft,
              child: Text('More Tips', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            ),
            const SizedBox(height: 10),
            _TipItem(icon: Icons.restaurant, color: AppColors.warning, title: 'Eat Less Salt', subtitle: 'Too much salt can raise your blood pressure.'),
            _TipItem(icon: Icons.directions_walk, color: AppColors.success, title: 'Stay Active', subtitle: 'A short walk every day can make a big difference.'),
            _TipItem(icon: Icons.water, color: AppColors.primary, title: 'Drink Water', subtitle: 'Water helps your body and supports\nhealthy blood pressure.'),
            _TipItem(icon: Icons.self_improvement, color: AppColors.chartPurple, title: 'Manage Stress', subtitle: 'Take deep breaths, relax, and take care of\nyour mind.'),
            _TipItem(icon: Icons.medication, color: AppColors.success, title: 'Take Your Medicine', subtitle: 'Always take your medicine as your doctor\ntold you.'),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.infoLight,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Row(
                children: [
                  Icon(Icons.info_outline, size: 16, color: AppColors.info),
                  SizedBox(width: 8),
                  Text('These tips are here to support you.\nSmall changes, real results.', style: TextStyle(fontSize: 12, color: AppColors.info)),
                ],
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

class _TipItem extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;

  const _TipItem({required this.icon, required this.color, required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Container(
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
            width: 40, height: 40,
            decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
            child: Icon(icon, color: color, size: 22),
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
          const Icon(Icons.chevron_right, color: AppColors.textTertiary, size: 18),
        ],
      ),
    );
  }
}
