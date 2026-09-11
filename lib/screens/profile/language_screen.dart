import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_colors.dart';
import '../../l10n/app_localizations.dart';
import '../../providers/app_provider.dart';
import '../../widgets/coverage_outcome.dart';

class LanguageScreen extends StatelessWidget {
  const LanguageScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final provider = context.watch<AppProvider>();
    final current = provider.locale.languageCode;
    String previewDate;
    String previewNumber;
    try {
      previewDate = DateFormat.yMMMMd(current).format(DateTime(2025, 5, 24));
      previewNumber = NumberFormat.decimalPattern(current).format(1234.56);
    } catch (_) {
      previewDate = DateFormat('MMMM d, yyyy').format(DateTime(2025, 5, 24));
      previewNumber = '1,234.56';
    }

    return Scaffold(
      backgroundColor: AppColors.scaffold(context),
      appBar: AppBar(
        title: Text(l10n.language),
        backgroundColor: AppColors.card(context),
        foregroundColor: AppColors.text(context),
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            l10n.languageScreenHint,
            style: TextStyle(fontSize: 16, color: AppColors.textMuted(context), height: 1.4),
          ),
          const SizedBox(height: 16),
          BigChoiceButton(
            label: l10n.languageEnglish,
            subtitle: current == 'en' ? l10n.selectedBadge : null,
            selected: current == 'en',
            onTap: () => provider.setLocale(const Locale('en')),
          ),
          const SizedBox(height: 10),
          BigChoiceButton(
            label: l10n.languageSomali,
            subtitle: current == 'so' ? l10n.selectedBadge : null,
            selected: current == 'so',
            onTap: () => provider.setLocale(const Locale('so')),
          ),
          const SizedBox(height: 16),
          Text(l10n.languageHelper, style: TextStyle(color: AppColors.textMuted(context))),
          const SizedBox(height: 20),
          Text(l10n.languagePreviewTitle, style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
          const SizedBox(height: 8),
          Text('$previewDate    $previewNumber', style: TextStyle(fontSize: 16)),
          const SizedBox(height: 20),
          Text(l10n.languageGoodToKnow, style: TextStyle(height: 1.4, color: AppColors.textMuted(context))),
        ],
      ),
    );
  }
}
