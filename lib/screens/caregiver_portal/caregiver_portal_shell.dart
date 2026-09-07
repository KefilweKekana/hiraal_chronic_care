import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../l10n/app_localizations.dart';
import '../../providers/app_provider.dart';
import 'caregiver_home_screen.dart';
import 'caregiver_history_screen.dart';
import 'caregiver_portal_account_screen.dart';
import 'caregiver_services_screen.dart';

class CaregiverPortalShell extends StatelessWidget {
  const CaregiverPortalShell({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    final l10n = AppLocalizations.of(context);
    final screens = const [
      CaregiverHomeScreen(),
      CaregiverServicesScreen(),
      CaregiverHistoryScreen(),
      CaregiverPortalAccountScreen(),
    ];
    final tab = provider.currentTab.clamp(0, screens.length - 1);

    return Scaffold(
      body: IndexedStack(
        index: tab,
        children: screens,
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: tab,
        onTap: provider.setTab,
        type: BottomNavigationBarType.fixed,
        selectedFontSize: 11,
        unselectedFontSize: 10,
        items: [
          BottomNavigationBarItem(
            icon: const Icon(Icons.home_outlined),
            activeIcon: const Icon(Icons.home),
            label: l10n.caregiverPortalHome,
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.medical_services_outlined),
            activeIcon: const Icon(Icons.medical_services),
            label: l10n.caregiverServicesTitle,
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.history),
            activeIcon: const Icon(Icons.history),
            label: l10n.caregiverHistoryTitle,
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.account_circle_outlined),
            activeIcon: const Icon(Icons.account_circle),
            label: l10n.caregiverPortalAccount,
          ),
        ],
      ),
    );
  }
}
