import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../providers/app_provider.dart';

class HealthInfoScreen extends StatelessWidget {
  const HealthInfoScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final patient = context.watch<AppProvider>().patient;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Health Information'),
        backgroundColor: AppColors.white,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _SectionCard(
            title: 'Current Conditions',
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: (patient?.conditions ?? ['Hypertension', 'Diabetes']).map((c) => Chip(
                label: Text(c, style: const TextStyle(fontSize: 13)),
                backgroundColor: AppColors.primarySurface,
                side: BorderSide.none,
              )).toList(),
            ),
          ),
          _SectionCard(
            title: 'Care Plan',
            child: Text(patient?.carePlan ?? 'Daily monitoring & follow-up', style: const TextStyle(fontSize: 14, color: AppColors.textPrimary)),
          ),
          _SectionCard(
            title: 'Risk Level',
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: (patient?.riskLevel == 'Very High' || patient?.riskLevel == 'High')
                        ? AppColors.errorLight
                        : AppColors.successLight,
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
                const CircleAvatar(
                  radius: 18,
                  backgroundColor: AppColors.primaryLight,
                  child: Icon(Icons.person, size: 18, color: AppColors.primary),
                ),
                const SizedBox(width: 10),
                Text(patient?.assignedNurse ?? '—', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
              ],
            ),
          ),
          _SectionCard(
            title: 'Next Check-in',
            child: Row(
              children: [
                const Icon(Icons.calendar_today, size: 16, color: AppColors.primary),
                const SizedBox(width: 8),
                Text(patient?.nextCheckIn ?? '—', style: const TextStyle(fontSize: 14)),
              ],
            ),
          ),
          _SectionCard(
            title: 'Device',
            child: Text(patient?.deviceAssigned ?? 'No device assigned', style: const TextStyle(fontSize: 14, color: AppColors.textPrimary)),
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
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontSize: 12, color: AppColors.textTertiary, fontWeight: FontWeight.w500)),
          const SizedBox(height: 8),
          child,
        ],
      ),
    );
  }
}
