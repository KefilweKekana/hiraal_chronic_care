import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../l10n/app_localizations.dart';
import '../../providers/app_provider.dart';
import 'caregiver_home_screen.dart';
import 'caregiver_history_screen.dart';
import 'caregiver_portal_account_screen.dart';
import 'caregiver_services_screen.dart';
import '../../widgets/health_pin_gate.dart';

class CaregiverPortalShell extends StatelessWidget {
  const CaregiverPortalShell({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    final l10n = AppLocalizations.of(context);
    final screens = const [
      CaregiverHomeScreen(),
      CaregiverServicesScreen(),
      HealthPinLockedPane(child: CaregiverHistoryScreen()),
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
        onTap: (index) async {
          if (index == 2) {
            final ok = await ensureHealthPinUnlocked(context);
            if (!ok || !context.mounted) return;
          }
          provider.setTab(index);
        },
        type: BottomNavigationBarType.fixed,
        selectedFontSize: 11,
        unselectedFontSize: 10,
        items: [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            activeIcon: Icon(Icons.home),
            label: l10n.caregiverPortalHome,
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.medical_services_outlined),
            activeIcon: Icon(Icons.medical_services),
            label: l10n.caregiverServicesTitle,
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.history),
            activeIcon: Icon(Icons.history),
            label: l10n.caregiverHistoryTitle,
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.account_circle_outlined),
            activeIcon: Icon(Icons.account_circle),
            label: l10n.caregiverPortalAccount,
          ),
        ],
      ),
    );
  }
}
