import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../providers/app_provider.dart';

class OfflineScreen extends StatelessWidget {
  const OfflineScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final pending = context.watch<AppProvider>().readings.where((r) => r.status == 'Pending').length;
    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: AppBar(title: const Text('Offline Mode'), leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => Navigator.pop(context))),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const SizedBox(height: 20),
            Container(
              width: 64, height: 64,
              decoration: BoxDecoration(color: AppColors.warningLight, borderRadius: BorderRadius.circular(16)),
              child: const Icon(Icons.wifi_off, color: AppColors.warning, size: 32),
            ),
            const SizedBox(height: 16),
            const Text("You're Offline", style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: AppColors.warning)),
            const SizedBox(height: 8),
            const Text('No internet connection detected.\nDon\'t worry — your data is safe.', textAlign: TextAlign.center, style: TextStyle(color: AppColors.textSecondary)),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: AppColors.infoLight, borderRadius: BorderRadius.circular(10)),
              child: const Row(
                children: [
                  Icon(Icons.info_outline, size: 16, color: AppColors.info),
                  SizedBox(width: 8),
                  Text("We've saved your recent readings locally.\nThey will sync automatically when you're back online.", style: TextStyle(fontSize: 12, color: AppColors.info)),
                ],
              ),
            ),
            const SizedBox(height: 24),
            const Align(alignment: Alignment.centerLeft, child: Text('What You Can Do', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600))),
            const SizedBox(height: 12),
            _OfflineAction(icon: Icons.edit, title: 'Log Your Readings', subtitle: 'You can still add your blood pressure\nand blood sugar.'),
            _OfflineAction(icon: Icons.history, title: 'View Saved Data', subtitle: 'See your last synced readings\nand notes.'),
            _OfflineAction(icon: Icons.apps, title: 'Use App Features', subtitle: "Many features are available offline.\nWe'll sync later."),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: AppColors.warningLight,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(Icons.sync, size: 18, color: AppColors.warning),
                  const SizedBox(width: 8),
                  const Expanded(child: Text('Pending Sync\nReadings will be sent when you\'re back online.', style: TextStyle(fontSize: 12, color: AppColors.warning))),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    child: Text('$pending items', style: const TextStyle(fontSize: 12, color: AppColors.warning, fontWeight: FontWeight.w600)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: AppColors.primarySurface, borderRadius: BorderRadius.circular(10)),
              child: Row(
                children: const [
                  Icon(Icons.lightbulb, size: 16, color: AppColors.primary),
                  SizedBox(width: 8),
                  Text("Tip: You can keep using the app normally.\nWe'll sync everything automatically\nwhen your connection returns.", style: TextStyle(fontSize: 11, color: AppColors.primary)),
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

class _OfflineAction extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  const _OfflineAction({required this.icon, required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: AppColors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.cardBorder)),
      child: Row(
        children: [
          Icon(icon, size: 20, color: AppColors.primary),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
              Text(subtitle, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
            ]),
          ),
          const Icon(Icons.chevron_right, color: AppColors.textTertiary, size: 18),
        ],
      ),
    );
  }
}
