import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';

class ReminderScreen extends StatelessWidget {
  final VoidCallback onLogNow;

  const ReminderScreen({super.key, required this.onLogNow});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: AppBar(
        title: const Text('Reminder'),
        leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => Navigator.pop(context)),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const SizedBox(height: 20),
            Container(
              width: 64, height: 64,
              decoration: BoxDecoration(
                color: AppColors.warningLight,
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Icon(Icons.waving_hand, color: AppColors.warning, size: 32),
            ),
            const SizedBox(height: 20),
            const Text('No Data Logged Today', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            const Text(
              'Keeping your health data up to date\nhelps your care team support you better.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: AppColors.textSecondary, height: 1.5),
            ),
            const SizedBox(height: 24),
            const Text("You haven't logged your:", style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _MissingItem(icon: Icons.favorite, label: 'Blood Pressure', color: AppColors.error),
                const SizedBox(width: 24),
                _MissingItem(icon: Icons.water_drop, label: 'Blood Sugar', color: AppColors.primary),
                const SizedBox(width: 24),
                _MissingItem(icon: Icons.monitor_weight, label: 'Weight', color: AppColors.chartPurple),
              ],
            ),
            const SizedBox(height: 20),
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
                  Text(
                    'Regular logging helps us track your progress\nand adjust your care when needed.',
                    style: TextStyle(fontSize: 12, color: AppColors.info),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            const Align(
              alignment: Alignment.centerLeft,
              child: Text('Why it matters', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            ),
            const SizedBox(height: 12),
            _ReasonRow(icon: Icons.trending_up, text: 'Helps detect changes early'),
            _ReasonRow(icon: Icons.medical_services, text: 'Supports better treatment decisions'),
            _ReasonRow(icon: Icons.verified, text: 'Keeps your care plan on track'),
            const Spacer(),
            Row(
              children: const [
                Icon(Icons.favorite, size: 14, color: AppColors.error),
                SizedBox(width: 4),
                Text('Try to log your data daily.', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
              ],
            ),
            const Text('It only takes a minute and makes a big difference.', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity, height: 56,
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.pop(context);
                  onLogNow();
                },
                icon: const Icon(Icons.edit, size: 18),
                label: const Text('Log My Data Now'),
              ),
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Remind Me Later', style: TextStyle(color: AppColors.textSecondary)),
            ),
          ],
        ),
      ),
    );
  }
}

class _MissingItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  const _MissingItem({required this.icon, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 48, height: 48,
          decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
          child: Icon(icon, color: color, size: 24),
        ),
        const SizedBox(height: 6),
        Text(label, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
      ],
    );
  }
}

class _ReasonRow extends StatelessWidget {
  final IconData icon;
  final String text;
  const _ReasonRow({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 18, color: AppColors.success),
          const SizedBox(width: 10),
          Text(text, style: const TextStyle(fontSize: 14, color: AppColors.textPrimary)),
        ],
      ),
    );
  }
}
