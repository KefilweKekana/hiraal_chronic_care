import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../l10n/app_localizations.dart';
import '../../providers/app_provider.dart';

class HealthInfoScreen extends StatelessWidget {
  const HealthInfoScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final patient = context.watch<AppProvider>().patient;
    final l10n = AppLocalizations.of(context);
    final conditions = patient?.conditions ?? const <String>[];

    return Scaffold(
      backgroundColor: AppColors.of(context).scaffold,
      appBar: AppBar(
        title: Text(l10n.healthInformation),
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _SectionCard(
            title: 'Current Conditions',
            child: conditions.isEmpty
                ? Text('–', style: TextStyle(color: AppColors.of(context).textMuted))
                : Wrap(
              spacing: 8,
              runSpacing: 8,
              children: conditions.map((c) => Chip(
                label: Text(c, style: TextStyle(fontSize: 13)),
                backgroundColor: AppColors.of(context).primaryMuted,
                side: BorderSide.none,
              )).toList(),
            ),
          ),
          _SectionCard(
            title: l10n.yourCarePlan,
            child: Text(
              (patient?.carePlan.isNotEmpty == true) ? patient!.carePlan : '–',
              style: TextStyle(fontSize: 14, color: AppColors.of(context).text),
            ),
          ),
          _SectionCard(
            title: 'Risk Level',
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: (patient?.riskLevel == 'Very High' || patient?.riskLevel == 'High')
                        ? AppColors.of(context).errorSoft
                        : AppColors.of(context).successSoft,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    patient?.riskLevel ?? 'Low',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: (patient?.riskLevel == 'Very High' || patient?.riskLevel == 'High')
                          ? AppColors.error
                          : AppColors.success,
                    ),
                  ),
                ),
              ],
            ),
          ),
          _SectionCard(
            title: 'Assigned Nurse',
            child: Row(
              children: [
                CircleAvatar(
                  radius: 18,
                  backgroundColor: AppColors.of(context).primarySoft,
                  child: const Icon(Icons.person, size: 18, color: AppColors.primary),
                ),
                const SizedBox(width: 10),
                Text(patient?.assignedNurse ?? '–', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
              ],
            ),
          ),
          _SectionCard(
            title: 'Next Check-in',
            child: Row(
              children: [
                Icon(Icons.calendar_today, size: 16, color: AppColors.primary),
                const SizedBox(width: 8),
                Text(patient?.nextCheckIn ?? '–', style: TextStyle(fontSize: 14)),
              ],
            ),
          ),
          _SectionCard(
            title: 'Device',
            child: Text(patient?.deviceAssigned ?? 'No device assigned', style: TextStyle(fontSize: 14, color: AppColors.of(context).text)),
          ),
        ],
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final String title;
  final Widget child;
  const _SectionCard({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.of(context).card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.of(context).border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: TextStyle(fontSize: 12, color: AppColors.of(context).textFaint, fontWeight: FontWeight.w500)),
          const SizedBox(height: 8),
          child,
        ],
      ),
    );
  }
}
