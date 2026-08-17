import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/network/connectivity_service.dart';
import '../../core/network/sync_manager.dart';
import '../../core/theme/app_colors.dart';
import '../../l10n/app_localizations.dart';
import '../../providers/app_provider.dart';
import '../home/home_screen.dart';
import '../services/services_screen.dart';
import '../history/history_screen.dart';
import '../profile/profile_screen.dart';

class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  late final ConnectivityService _connectivity;
  late bool _wasOnline;

  @override
  void initState() {
    super.initState();
    _connectivity = context.read<ConnectivityService>();
    // Seed from the current state so the "back online" toast only fires on
    // an offline → online transition, not on first build.
    _wasOnline = _connectivity.isOnline;
    _connectivity.addListener(_onConnectivityChanged);
  }

  @override
  void dispose() {
    _connectivity.removeListener(_onConnectivityChanged);
    super.dispose();
  }

  void _onConnectivityChanged() {
    if (!mounted) return;
    final online = _connectivity.isOnline;
    if (online && !_wasOnline) {
      final l10n = AppLocalizations.of(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.backOnlineSyncing),
          duration: const Duration(seconds: 3),
        ),
      );
      // Drain any readings queued while offline. Safe to repeat: synced
      // readings are marked locally and the server dedupes by reference.
      unawaited(SyncManager().syncAll());
    }
    _wasOnline = online;
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    final l10n = AppLocalizations.of(context);
    final isOnline =
        context.select<ConnectivityService, bool>((c) => c.isOnline);

    final screens = [
      const HomeScreen(),
      const ServicesScreen(),
      const HistoryScreen(),
      const ProfileScreen(),
    ];

    return Scaffold(
      body: Column(
        children: [
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 250),
            child: isOnline
                ? const SizedBox.shrink(key: ValueKey('online'))
                : const _OfflineBanner(key: ValueKey('offline')),
          ),
          Expanded(
            child: IndexedStack(
              index: provider.currentTab,
              children: screens,
            ),
          ),
        ],
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
          onTap: (index) => provider.setTab(index),
          selectedFontSize: 11,
          unselectedFontSize: 10,
          items: [
            BottomNavigationBarItem(
              icon: const Icon(Icons.home_outlined),
              activeIcon: const Icon(Icons.home),
              label: l10n.navHome,
            ),
            BottomNavigationBarItem(
              icon: const Icon(Icons.medical_services_outlined),
              activeIcon: const Icon(Icons.medical_services),
              label: l10n.navServices,
            ),
            BottomNavigationBarItem(
              icon: const Icon(Icons.history_outlined),
              activeIcon: const Icon(Icons.history),
              label: l10n.navHistory,
            ),
            BottomNavigationBarItem(
              icon: const Icon(Icons.person_outline),
              activeIcon: const Icon(Icons.person),
              label: l10n.navProfile,
            ),
          ],
        ),
      ),
    );
  }
}

/// Slim warning strip shown above the tabs while the device is offline.
class _OfflineBanner extends StatelessWidget {
  const _OfflineBanner({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Container(
      width: double.infinity,
      color: AppColors.warningLight,
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.wifi_off, size: 14, color: AppColors.warning),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  l10n.offlineBanner,
                  style: const TextStyle(fontSize: 12, color: AppColors.warning),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
