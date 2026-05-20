import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/theme/app_colors.dart';
import '../../models/vital_reading.dart';
import 'contact_care_team_screen.dart';

class HighBpAlertScreen extends StatelessWidget {
  final VitalReading reading;

  const HighBpAlertScreen({super.key, required this.reading});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: AppBar(
        title: const Text('Alert'),
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
            const Text(
              'High Blood Pressure Detected',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: AppColors.error),
            ),
            const SizedBox(height: 8),
            const Text(
              'Your reading is higher than your safe range.\nPlease follow the steps below.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
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
                  const Text('Your Latest Reading', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      const Icon(Icons.favorite, color: AppColors.error, size: 20),
                      const SizedBox(width: 8),
                      const Text('Blood Pressure', style: TextStyle(fontSize: 13, color: AppColors.textSecondary)),
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
                        child: const Text('High', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.error)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: const [
                      Icon(Icons.info_outline, size: 14, color: AppColors.textTertiary),
                      SizedBox(width: 4),
                      Text('Safe range: Below 140/90 mmHg', style: TextStyle(fontSize: 12, color: AppColors.textTertiary)),
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
                  const Text('What You Should Do', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 16),
                  _ActionStep(
                    number: '1',
                    icon: Icons.phone,
                    title: 'Contact Your Care Team',
                    subtitle: 'We recommend speaking with your care team today.',
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ContactCareTeamScreen())),
                  ),
                  const SizedBox(height: 12),
                  _ActionStep(
                    number: '2',
                    icon: Icons.self_improvement,
                    title: 'Rest and Recheck',
                    subtitle: 'Sit quietly for 5 minutes and check your\nblood pressure again.',
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Rest for 5 minutes, then recheck'), duration: Duration(seconds: 2)),
                      );
                      Navigator.pop(context);
                    },
                  ),
                  const SizedBox(height: 12),
                  _ActionStep(
                    number: '3',
                    icon: Icons.local_hospital,
                    title: 'Seek Urgent Care if Needed',
                    subtitle: 'If you have chest pain, shortness of breath,\nor severe headache, get help right away.',
                    onTap: () {
                      showDialog(
                        context: context,
                        builder: (_) => AlertDialog(
                          title: const Text('Seek Urgent Care'),
                          content: const Text('If you experience chest pain, shortness of breath, severe headache, or vision changes, please go to your nearest emergency room or call emergency services immediately.'),
                          actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('OK'))],
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
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Get Help Now', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.error)),
                        Text("If you're experiencing any severe symptoms,\ncall emergency services.", style: TextStyle(fontSize: 11, color: AppColors.error)),
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
                    child: const Text('Call 999', style: TextStyle(fontSize: 13)),
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
                label: const Text('Contact My Care Team'),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity, height: 48,
              child: OutlinedButton.icon(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.favorite, size: 18),
                label: const Text('Recheck My Blood Pressure'),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Future<void> _dialEmergency(BuildContext context) async {
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
            title: const Row(children: [Icon(Icons.emergency, color: AppColors.error), SizedBox(width: 8), Text('Emergency Call')]),
            content: Text('Unable to open dialer. Please call emergency services at $emergencyNumber immediately.'),
            actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('OK'))],
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
