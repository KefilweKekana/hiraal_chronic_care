import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../l10n/app_localizations.dart';

class SponsorConnectionSentScreen extends StatelessWidget {
  final String whatsappNumber;

  const SponsorConnectionSentScreen({super.key, required this.whatsappNumber});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      backgroundColor: AppColors.of(context).scaffold,
      appBar: AppBar(
        title: Text(l10n.connectionRequestTitle),
        elevation: 0,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppColors.of(context).card,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.of(context).border),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.mark_email_read_outlined, size: 60, color: AppColors.primary),
                const SizedBox(height: 16),
                Text(l10n.connectionSentHeadline, style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
                const SizedBox(height: 8),
                Text(
                  l10n.connectionSentBody(whatsappNumber),
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppColors.of(context).textMuted),
                ),
                const SizedBox(height: 18),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text(l10n.doneLabel),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
