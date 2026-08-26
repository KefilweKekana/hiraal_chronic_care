import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_colors.dart';
import '../../l10n/app_localizations.dart';
import '../../providers/app_provider.dart';
import '../sponsor/my_sponsorship_screen.dart';
import '../sponsor/sponsor_care_screen.dart';
import 'caregiver_portal_account_screen.dart';

class CaregiverPortalShell extends StatelessWidget {
  const CaregiverPortalShell({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    final l10n = AppLocalizations.of(context);
    final screens = const [
      MySponsorshipScreen(showAppBar: false, showWelcome: true),
      SponsorCareScreen(showAppBar: false),
      CaregiverPortalAccountScreen(),
    ];

    return Scaffold(
      body: IndexedStack(
        index: provider.currentTab,
        children: screens,
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: AppColors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: BottomNavigationBar(
          currentIndex: provider.currentTab,
          onTap: provider.setTab,
          selectedFontSize: 11,
          unselectedFontSize: 10,
          items: [
            BottomNavigationBarItem(
              icon: const Icon(Icons.favorite_border),
              activeIcon: const Icon(Icons.favorite),
              label: l10n.caregiverPortalHome,
            ),
            BottomNavigationBarItem(
              icon: const Icon(Icons.person_search_outlined),
              activeIcon: const Icon(Icons.person_search),
              label: l10n.caregiverPortalConnect,
            ),
            BottomNavigationBarItem(
              icon: const Icon(Icons.account_circle_outlined),
              activeIcon: const Icon(Icons.account_circle),
              label: l10n.caregiverPortalAccount,
            ),
          ],
        ),
      ),
    );
  }
}
