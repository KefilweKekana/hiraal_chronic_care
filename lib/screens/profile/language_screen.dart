import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_colors.dart';
import '../../l10n/app_localizations.dart';
import '../../providers/app_provider.dart';

class LanguageScreen extends StatelessWidget {
  const LanguageScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final provider = context.watch<AppProvider>();
    final current = provider.locale.languageCode;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(l10n.chooseLanguage),
        backgroundColor: AppColors.white,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _LanguageTile(
            title: l10n.languageEnglish,
            selected: current == 'en',
            onTap: () => provider.setLocale(const Locale('en')),
          ),
          _LanguageTile(
            title: l10n.languageSomali,
            selected: current == 'so',
            onTap: () => provider.setLocale(const Locale('so')),
          ),
        ],
      ),
    );
  }
}

class _LanguageTile extends StatelessWidget {
  final String title;
  final bool selected;
  final VoidCallback onTap;

  const _LanguageTile({
    required this.title,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: selected ? AppColors.primary : AppColors.cardBorder,
          width: selected ? 1.5 : 1,
        ),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              if (selected)
                const Icon(Icons.check_circle, color: AppColors.primary, size: 22)
              else
                Icon(Icons.circle_outlined,
                    color: AppColors.textTertiary.withValues(alpha: 0.5), size: 22),
            ],
          ),
        ),
      ),
    );
  }
}
