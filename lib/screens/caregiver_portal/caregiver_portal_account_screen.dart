import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_colors.dart';
import '../../l10n/app_localizations.dart';
import '../../providers/app_provider.dart';
import '../notifications/notification_screen.dart';
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
    final palette = AppColors.of(context);
    final unread = provider.unreadNotificationCount;
    final hour = DateTime.now().hour;
    final greeting = hour < 12
        ? l10n.greetingMorning
        : hour < 17
            ? l10n.greetingAfternoon
            : l10n.greetingEvening;
    final initials = patient?.initials ??
        (patient?.name.isNotEmpty == true
            ? patient!.name[0].toUpperCase()
            : 'C');

    return Scaffold(
      backgroundColor: palette.scaffold,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
          children: [
            SizedBox(
              height: 48,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Text(
                    l10n.caregiverAccountTitle,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: palette.text,
                    ),
                  ),
                  Positioned(
                    right: 0,
                    child: IconButton(
                      tooltip: l10n.notifications,
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const NotificationScreen(),
                        ),
                      ),
                      icon: unread > 0
                          ? Badge.count(
                              count: unread,
                              backgroundColor: AppColors.error,
                              textColor: AppColors.white,
                              child: Icon(
                                Icons.notifications_outlined,
                                color: palette.text,
                                size: 26,
                              ),
                            )
                          : Icon(
                              Icons.notifications_outlined,
                              color: palette.text,
                              size: 26,
                            ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 4),
            Text(
              l10n.caregiverAccountHint,
              textAlign: TextAlign.center,
              style: TextStyle(color: palette.textMuted, fontSize: 14),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: palette.card,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: palette.border),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 30,
                    backgroundColor: palette.primarySoft,
                    child: Text(
                      initials,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '$greeting ${patient?.name ?? ''}'.trim(),
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: palette.text,
                          ),
                        ),
                        if (patient?.phone.isNotEmpty == true)
                          Text(
                            patient!.phone,
                            style: TextStyle(color: palette.textMuted),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            _RowTile(
              icon: Icons.favorite_outline,
              iconColor: AppColors.success,
              title: l10n.peopleICareFor,
              subtitle: l10n.peopleICareForHint,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const PeopleICareForScreen()),
              ),
            ),
            _RowTile(
              icon: Icons.receipt_long_outlined,
              iconColor: AppColors.success,
              title: l10n.plansAndPayments,
              subtitle: l10n.plansAndPaymentsHint,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const PlansPaymentsScreen()),
              ),
            ),
            _RowTile(
              icon: Icons.person_outline,
              iconColor: AppColors.primary,
              title: l10n.myDetails,
              subtitle: [
                if (patient?.name.isNotEmpty == true) patient!.name,
                if (patient?.phone.isNotEmpty == true) patient!.phone,
              ].join(' · '),
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const PersonalInfoScreen()),
              ),
            ),
            _RowTile(
              icon: Icons.group_add_outlined,
              iconColor: AppColors.info,
              title: l10n.familyAccess,
              subtitle: l10n.familyAccessHint,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const FamilyAccessScreen()),
              ),
            ),
            _RowTile(
              icon: Icons.settings_outlined,
              iconColor: palette.textMuted,
              title: l10n.settings,
              subtitle: l10n.settingsAccountSubtitle(
                provider.locale.languageCode == 'so'
                    ? l10n.languageSomali
                    : l10n.languageEnglish,
              ),
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const SettingsScreen()),
              ),
            ),
            if (patient != null)
              _RowTile(
                icon: Icons.monitor_heart_outlined,
                iconColor: AppColors.primary,
                title: l10n.roleChooserPatientTitle,
                subtitle: l10n.roleChooserPatientHint,
                onTap: () => provider.enterPatientApp(),
              ),
            _RowTile(
              icon: Icons.logout,
              iconColor: AppColors.error,
              title: l10n.logOut,
              subtitle: '',
              destructive: true,
              onTap: () => provider.logout(),
            ),
          ],
        ),
      ),
    );
  }
}

class _RowTile extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final bool destructive;

  const _RowTile({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.destructive = false,
  });

  @override
  Widget build(BuildContext context) {
    final palette = AppColors.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: destructive ? palette.errorSoft : palette.card,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: destructive
                    ? AppColors.error.withValues(alpha: 0.22)
                    : palette.border,
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: iconColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: iconColor, size: 24),
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
                          fontWeight: FontWeight.w700,
                          color: destructive ? AppColors.error : palette.text,
                        ),
                      ),
                      if (subtitle.isNotEmpty)
                        Text(
                          subtitle,
                          style: TextStyle(fontSize: 14, color: palette.textMuted),
                        ),
                    ],
                  ),
                ),
                Icon(
                  Icons.chevron_right,
                  color: destructive
                      ? AppColors.error.withValues(alpha: 0.7)
                      : palette.textFaint,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
