import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_colors.dart';
import '../../l10n/app_localizations.dart';
import '../../providers/app_provider.dart';
import '../../widgets/health_pin_gate.dart';
import 'health_info_screen.dart';
import 'medical_history_screen.dart';

class PersonalInfoScreen extends StatelessWidget {
  const PersonalInfoScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final patient = context.watch<AppProvider>().patient;
    final palette = AppColors.of(context);
    final age = patient?.ageYears;
    final memberId = (patient != null && patient.patientId.isNotEmpty)
        ? patient.patientId
        : '–';

    return Scaffold(
      backgroundColor: palette.scaffold,
      appBar: AppBar(
        title: Text(l10n.personalInformation),
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Center(
            child: CircleAvatar(
              radius: 44,
              backgroundColor: palette.primarySoft,
              child: Text(
                patient?.initials ?? '?',
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primary,
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),
          _InfoTile(label: l10n.fullName, value: patient?.name ?? '–'),
          _InfoTile(
            label: l10n.memberIdLabel,
            value: memberId,
            hint: l10n.memberIdUnchangeable,
          ),
          _InfoTile(
            label: l10n.phoneLabel,
            value: (patient?.phone.isNotEmpty == true) ? patient!.phone : '–',
          ),
          _InfoTile(
            label: l10n.age,
            value: age != null ? l10n.yearsOld(age) : '–',
          ),
          if (patient?.clinic.isNotEmpty == true)
            _InfoTile(label: l10n.clinicLabel, value: patient!.clinic),
          if (patient?.assignedNurse.isNotEmpty == true)
            _InfoTile(
              label: l10n.assignedNurseLabel,
              value: patient!.assignedNurse,
            ),
          const SizedBox(height: 12),
          Text(
            l10n.healthRecordsCard,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: palette.textMuted,
            ),
          ),
          const SizedBox(height: 8),
          _NavTile(
            title: l10n.healthInformation,
            subtitle: l10n.viewHealthSummary,
            onTap: () => pushAfterHealthPin(context, const HealthInfoScreen()),
          ),
          _NavTile(
            title: l10n.medicalHistory,
            subtitle: l10n.medicalRecordsHint,
            onTap: () =>
                pushAfterHealthPin(context, const MedicalHistoryScreen()),
          ),
        ],
      ),
    );
  }
}

class _InfoTile extends StatelessWidget {
  final String label;
  final String value;
  final String? hint;

  const _InfoTile({required this.label, required this.value, this.hint});

  @override
  Widget build(BuildContext context) {
    final palette = AppColors.of(context);
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: palette.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: palette.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: TextStyle(fontSize: 13, color: palette.textFaint)),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: palette.text,
            ),
          ),
          if (hint != null) ...[
            const SizedBox(height: 4),
            Text(hint!, style: TextStyle(fontSize: 13, color: palette.textMuted)),
          ],
        ],
      ),
    );
  }
}

class _NavTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _NavTile({
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final palette = AppColors.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: palette.card,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: palette.border),
            ),
            child: Row(
              children: [
                Icon(Icons.lock_outline, color: AppColors.primary, size: 22),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Text(
                        subtitle,
                        style: TextStyle(fontSize: 13, color: palette.textMuted),
                      ),
                    ],
                  ),
                ),
                Icon(Icons.chevron_right, color: palette.textFaint),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
