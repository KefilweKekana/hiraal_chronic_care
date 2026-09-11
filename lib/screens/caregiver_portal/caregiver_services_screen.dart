import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_colors.dart';
import '../../core/utils/result.dart';
import '../../l10n/app_localizations.dart';
import '../../providers/app_provider.dart';
import '../../services/service_locator.dart';
import '../../widgets/active_patient_card.dart';
import '../alerts/contact_care_team_screen.dart';
import '../profile/subscription_screen.dart';
import '../services/book_doctor_screen.dart';
import '../services/lab_test_screen.dart';
import '../services/medicine_order_screen.dart';
import '../summary/weekly_summary_screen.dart';
import '../../widgets/health_pin_gate.dart';

class CaregiverServicesScreen extends StatefulWidget {
  const CaregiverServicesScreen({super.key});

  @override
  State<CaregiverServicesScreen> createState() => _CaregiverServicesScreenState();
}

class _CaregiverServicesScreenState extends State<CaregiverServicesScreen> {
  Map<String, dynamic>? _home;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    final patient = context.read<AppProvider>().activeCarePerson?.patient;
    if (patient == null || patient.isEmpty) return;
    final result = await ServiceLocator.instance.caregivers.caregiverHome(patient);
    if (!mounted) return;
    if (result case Success(data: final data)) {
      setState(() => _home = data);
    }
  }

  int? _daysUntil(Object? raw) {
    final parsed = DateTime.tryParse('$raw');
    if (parsed == null) return null;
    return DateTime(parsed.year, parsed.month, parsed.day)
        .difference(DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day))
        .inDays;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final person = context.watch<AppProvider>().activeCarePerson;
    final plan = person?.plan ?? '';
    final fee = person?.monthlyAmount ?? 0;
    final refillDays = _daysUntil(_home?['refill'] is Map ? (_home!['refill'] as Map)['modified'] : null);
    final labDays = _daysUntil(_home?['next_lab'] is Map ? (_home!['next_lab'] as Map)['creation'] : null);

    return Scaffold(
      backgroundColor: AppColors.scaffold(context),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text(
              l10n.caregiverServicesTitle,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w800,
                color: AppColors.text(context),
              ),
            ),
            const SizedBox(height: 4),
            Text(l10n.caregiverServicesHint, style: TextStyle(color: AppColors.textMuted(context))),
            const SizedBox(height: 16),
            ActivePatientCard(onChange: _load),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          plan.isEmpty ? l10n.currentPlan : plan,
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                        ),
                        Text(
                          fee > 0 ? '\$${fee.toStringAsFixed(0)} / Month' : l10n.caregiverActive,
                          style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  ),
                  OutlinedButton(
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const SubscriptionScreen()),
                    ),
                    child: Text(l10n.changePlan),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Text(l10n.whatsDue, style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            _DueRow(
              title: l10n.filterMedicines,
              subtitle: refillDays == null ? null : l10n.dueInDays(refillDays.clamp(0, 365)),
              action: l10n.requestRefill,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const MedicineOrderScreen()),
              ),
            ),
            _DueRow(
              title: l10n.filterLabs,
              subtitle: labDays == null ? null : l10n.dueInDays(labDays.clamp(0, 365)),
              action: l10n.viewAction,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const LabTestScreen()),
              ),
            ),
            const SizedBox(height: 20),
            _ServiceTile(
              color: AppColors.info,
              icon: Icons.calendar_month,
              title: l10n.seeADoctor,
              subtitle: l10n.seeADoctorHint,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const BookDoctorScreen()),
              ),
            ),
            _ServiceTile(
              color: AppColors.success,
              icon: Icons.local_pharmacy,
              title: l10n.getMedicine,
              subtitle: l10n.getMedicineHint,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const MedicineOrderScreen()),
              ),
            ),
            _ServiceTile(
              color: AppColors.warning,
              icon: Icons.science,
              title: l10n.bloodTest,
              subtitle: l10n.bloodTestHint,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const LabTestScreen()),
              ),
            ),
            _ServiceTile(
              color: AppColors.chartPurple,
              icon: Icons.folder_shared_outlined,
              title: l10n.healthRecordsCard,
              onTap: () => pushAfterHealthPin(context, const WeeklySummaryScreen()),
            ),
            _ServiceTile(
              color: AppColors.primary,
              icon: Icons.headset_mic_outlined,
              title: l10n.talkToCareTeam,
              subtitle: l10n.talkToCareTeamHint,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ContactCareTeamScreen()),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DueRow extends StatelessWidget {
  final String title;
  final String? subtitle;
  final String action;
  final VoidCallback onTap;
  const _DueRow({required this.title, this.subtitle, required this.action, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.card(context),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border(context)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                if (subtitle != null)
                  Text(subtitle!, style: TextStyle(fontSize: 13, color: AppColors.textMuted(context))),
              ],
            ),
          ),
          TextButton(onPressed: onTap, child: Text(action)),
        ],
      ),
    );
  }
}

class _ServiceTile extends StatelessWidget {
  final Color color;
  final IconData icon;
  final String title;
  final String? subtitle;
  final VoidCallback onTap;
  const _ServiceTile({
    required this.color,
    required this.icon,
    required this.title,
    this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            child: Row(
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(color: AppColors.card(context), shape: BoxShape.circle),
                  child: Icon(icon, color: color, size: 26),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                          color: AppColors.text(context),
                        ),
                      ),
                      if (subtitle != null)
                        Text(
                          subtitle!,
                          style: TextStyle(fontSize: 13, color: AppColors.textMuted(context)),
                        ),
                    ],
                  ),
                ),
                Icon(Icons.chevron_right, color: color),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
