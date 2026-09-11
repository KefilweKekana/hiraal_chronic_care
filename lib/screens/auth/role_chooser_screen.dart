import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_colors.dart';
import '../../l10n/app_localizations.dart';
import '../../providers/app_provider.dart';

class RoleChooserScreen extends StatelessWidget {
  const RoleChooserScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final provider = context.watch<AppProvider>();

    return Scaffold(
      backgroundColor: AppColors.scaffold(context),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 24),
              Text(
                l10n.roleChooserTitle,
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w700,
                  color: AppColors.text(context),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                l10n.roleChooserHint,
                style: TextStyle(
                  fontSize: 15,
                  height: 1.5,
                  color: AppColors.textMuted(context),
                ),
              ),
              const SizedBox(height: 32),
              _RoleCard(
                icon: Icons.monitor_heart_outlined,
                title: l10n.roleChooserPatientTitle,
                subtitle: l10n.roleChooserPatientHint,
                onTap: provider.isLoading ? null : () => provider.choosePatientApp(),
              ),
              const SizedBox(height: 16),
              _RoleCard(
                icon: Icons.favorite_outline,
                title: l10n.roleChooserCaregiverTitle,
                subtitle: l10n.roleChooserCaregiverHint,
                onTap: provider.isLoading ? null : () => provider.chooseCaregiverPortal(),
              ),
              const Spacer(),
              Center(
                child: TextButton(
                  onPressed: provider.isLoading ? null : () => provider.logout(),
                  child: Text(
                    l10n.logOut,
                    style: TextStyle(color: AppColors.of(context).textMuted),
                  ),
                ),
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }
}

class _RoleCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;

  const _RoleCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.card(context),
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.border(context)),
          ),
          child: Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: AppColors.primary, size: 28),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        color: AppColors.text(context),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 13,
                        height: 1.4,
                        color: AppColors.textMuted(context),
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: AppColors.textMuted(context)),
            ],
          ),
        ),
      ),
    );
  }
}
