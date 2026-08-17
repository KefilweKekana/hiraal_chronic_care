import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/theme/app_colors.dart';
import '../../l10n/app_localizations.dart';
import '../../models/vital_reading.dart';
import 'contact_care_team_screen.dart';

class HighBpAlertScreen extends StatelessWidget {
  final VitalReading reading;

  const HighBpAlertScreen({super.key, required this.reading});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final emergencyNumber = const String.fromEnvironment(
      'EMERGENCY_NUMBER',
      defaultValue: '999',
    );
    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: AppBar(
        title: Text(l10n.alert),
        leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => Navigator.pop(context)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Container(
              width: 56, height: 56,
              decoration: BoxDecoration(
                color: AppColors.errorLight,
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Icon(Icons.warning_amber_rounded, color: AppColors.error, size: 32),
            ),
            const SizedBox(height: 16),
            Text(
              l10n.highBpDetected,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: AppColors.error),
            ),
            const SizedBox(height: 8),
            Text(
              l10n.highBpSubtitle,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 14, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 24),
            // Reading card
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
                  Text(l10n.yourLatestReading, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      const Icon(Icons.favorite, color: AppColors.error, size: 20),
                      const SizedBox(width: 8),
                      Text(l10n.bloodPressure, style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
                      const Spacer(),
                      Text(
                        '${reading.systolic}/${reading.diastolic}',
                        style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                      ),
                      const SizedBox(width: 4),
                      const Text('mmHg', style: TextStyle(fontSize: 13, color: AppColors.textSecondary)),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: AppColors.errorLight,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(l10n.highBadge, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.error)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.info_outline, size: 14, color: AppColors.textTertiary),
                      const SizedBox(width: 4),
                      Text(l10n.safeRangeBp, style: const TextStyle(fontSize: 12, color: AppColors.textTertiary)),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            // What you should do
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
                  Text(l10n.whatYouShouldDo, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 16),
                  _ActionStep(
                    number: '1',
                    icon: Icons.phone,
                    title: l10n.contactYourCareTeam,
                    subtitle: l10n.contactCareTeamHint,
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ContactCareTeamScreen())),
                  ),
                  const SizedBox(height: 12),
                  _ActionStep(
                    number: '2',
                    icon: Icons.self_improvement,
                    title: l10n.restAndRecheck,
                    subtitle: l10n.restAndRecheckHint,
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(l10n.restThenRecheckSnack), duration: const Duration(seconds: 2)),
                      );
                      Navigator.pop(context);
                    },
                  ),
                  const SizedBox(height: 12),
                  _ActionStep(
                    number: '3',
                    icon: Icons.local_hospital,
                    title: l10n.seekUrgentCare,
                    subtitle: l10n.seekUrgentCareHint,
                    onTap: () {
                      showDialog(
                        context: context,
                        builder: (_) => AlertDialog(
                          title: Text(l10n.seekUrgentCare),
                          content: Text(l10n.seekUrgentCareDialogBody),
                          actions: [TextButton(onPressed: () => Navigator.pop(context), child: Text(l10n.ok))],
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            // Emergency section
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.errorLight,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(Icons.emergency, size: 20, color: AppColors.error),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(l10n.getHelpNow, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.error)),
                        Text(l10n.getHelpNowHint, style: const TextStyle(fontSize: 11, color: AppColors.error)),
                      ],
                    ),
                  ),
                  ElevatedButton(
                    onPressed: () => _dialEmergency(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.error,
                      minimumSize: const Size(80, 36),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    child: Text(l10n.callEmergencyNumber(emergencyNumber), style: const TextStyle(fontSize: 13)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity, height: 56,
              child: ElevatedButton.icon(
                onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ContactCareTeamScreen())),
                icon: const Icon(Icons.chat, size: 18),
                label: Text(l10n.contactMyCareTeam),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity, height: 48,
              child: OutlinedButton.icon(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.favorite, size: 18),
                label: Text(l10n.recheckMyBloodPressure),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Future<void> _dialEmergency(BuildContext context) async {
    final l10n = AppLocalizations.of(context);
    final emergencyNumber = const String.fromEnvironment(
      'EMERGENCY_NUMBER',
      defaultValue: '999',
    );
    final uri = Uri.parse('tel:$emergencyNumber');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      if (context.mounted) {
        showDialog(
          context: context,
          builder: (_) => AlertDialog(
            title: Row(children: [const Icon(Icons.emergency, color: AppColors.error), const SizedBox(width: 8), Text(l10n.emergencyCallTitle)]),
            content: Text(l10n.unableToOpenDialer(emergencyNumber)),
            actions: [TextButton(onPressed: () => Navigator.pop(context), child: Text(l10n.ok))],
          ),
        );
      }
    }
  }
}

class _ActionStep extends StatelessWidget {
  final String number;
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _ActionStep({required this.number, required this.icon, required this.title, required this.subtitle, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36, height: 36,
            decoration: BoxDecoration(
              color: AppColors.primaryLight,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: AppColors.primary, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('$number. $title', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                Text(subtitle, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
              ],
            ),
          ),
          const Icon(Icons.chevron_right, color: AppColors.textTertiary),
        ],
      ),
    );
  }
}
