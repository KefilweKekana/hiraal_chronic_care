import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../l10n/app_localizations.dart';
import '../../models/caregiver_link.dart';
import 'my_sponsorship_screen.dart';
import 'sponsor_care_screen.dart';

class SponsorConnectionActiveScreen extends StatelessWidget {
  final CaregiverLink link;

  const SponsorConnectionActiveScreen({super.key, required this.link});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      backgroundColor: AppColors.of(context).scaffold,
      appBar: AppBar(
        title: Text(l10n.connectionActiveTitle),
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
                Icon(Icons.check_circle, size: 60, color: AppColors.success),
                const SizedBox(height: 16),
                Text(l10n.connectionActiveHeadline, style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
                const SizedBox(height: 8),
                Text(
                  l10n.connectionActiveBody(link.displayName),
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppColors.of(context).textMuted),
                ),
                const SizedBox(height: 18),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).pushAndRemoveUntil(
                        MaterialPageRoute(builder: (_) => const SponsorCareScreen()),
                        (route) => route.isFirst,
                      );
                    },
                    child: Text(l10n.sponsorCareTitle),
                  ),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const MySponsorshipScreen()),
                      );
                    },
                    child: Text(l10n.mySponsorshipTitle),
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
