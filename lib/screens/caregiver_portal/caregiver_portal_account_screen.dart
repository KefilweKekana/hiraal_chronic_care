import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_colors.dart';
import '../../l10n/app_localizations.dart';
import '../../providers/app_provider.dart';
import '../profile/language_screen.dart';
import '../profile/personal_info_screen.dart';
import '../profile/settings_screen.dart';
import 'family_access_screen.dart';
import 'people_i_care_for_screen.dart';
import 'plans_payments_screen.dart';

class CaregiverPortalAccountScreen extends StatelessWidget {
  const CaregiverPortalAccountScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final provider = context.watch<AppProvider>();
    final patient = provider.patient;
    final hour = DateTime.now().hour;
    final greeting = hour < 12
        ? l10n.greetingMorning
        : hour < 17
            ? l10n.greetingAfternoon
            : l10n.greetingEvening;

    return Scaffold(
      backgroundColor: AppColors.scaffold(context),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text(
              l10n.caregiverAccountTitle,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w800,
                color: AppColors.text(context),
              ),
            ),
            const SizedBox(height: 4),
            Text(l10n.caregiverAccountHint, style: TextStyle(color: AppColors.textMuted(context))),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 28,
                    backgroundColor: AppColors.primaryLight,
                    child: Text(
                      (patient?.name ?? 'C').substring(0, 1).toUpperCase(),
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '$greeting ${patient?.name ?? ''}',
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                        ),
                        Text(patient?.phone ?? '', style: TextStyle(color: AppColors.textMuted(context))),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            _RowTile(
              icon: Icons.person_outline,
              title: l10n.myAccountRow,
              subtitle: l10n.myAccountRowHint,
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PersonalInfoScreen())),
            ),
            _RowTile(
              icon: Icons.favorite_outline,
              title: l10n.peopleICareFor,
              subtitle: l10n.peopleICareForHint,
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PeopleICareForScreen())),
            ),
            _RowTile(
              icon: Icons.receipt_long_outlined,
              title: l10n.plansAndPayments,
              subtitle: l10n.plansAndPaymentsHint,
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PlansPaymentsScreen())),
            ),
            _RowTile(
              icon: Icons.group_add_outlined,
              title: l10n.familyAccess,
              subtitle: l10n.familyAccessHint,
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const FamilyAccessScreen())),
            ),
            _RowTile(
              icon: Icons.language,
              title: l10n.language,
              subtitle: l10n.languageSubtitle,
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const LanguageScreen())),
            ),
            _RowTile(
              icon: Icons.settings_outlined,
              title: l10n.settings,
              subtitle: l10n.settingsSubtitle,
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SettingsScreen())),
            ),
            const SizedBox(height: 8),
            if (patient != null)
              _RowTile(
                icon: Icons.monitor_heart_outlined,
                title: l10n.roleChooserPatientTitle,
                subtitle: l10n.roleChooserPatientHint,
                onTap: () => provider.enterPatientApp(),
              ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: OutlinedButton(
                onPressed: () => provider.logout(),
                style: OutlinedButton.styleFrom(foregroundColor: AppColors.error),
                child: Text(l10n.logOut, style: const TextStyle(color: AppColors.error, fontWeight: FontWeight.w700)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RowTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  const _RowTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: AppColors.card(context),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border(context)),
      ),
      child: ListTile(
        minVerticalPadding: 16,
        leading: Icon(icon, color: AppColors.primary, size: 28),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }
}
