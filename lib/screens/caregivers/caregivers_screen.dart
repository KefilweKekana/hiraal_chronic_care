import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/utils/result.dart';
import '../../l10n/app_localizations.dart';
import '../../models/caregiver_link.dart';
import '../../services/service_locator.dart';
import 'add_caregiver_screen.dart';
import 'caregiver_detail_screen.dart';

class CaregiversScreen extends StatefulWidget {
  const CaregiversScreen({super.key});

  @override
  State<CaregiversScreen> createState() => _CaregiversScreenState();
}

class _CaregiversScreenState extends State<CaregiversScreen> {
  bool _loading = true;
  String? _error;
  CaregiverListData _data = const CaregiverListData();
  String? _busyName;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    final result = await ServiceLocator.instance.caregivers.listMyCaregivers();
    if (!mounted) return;
    setState(() {
      _loading = false;
      switch (result) {
        case Success(data: final data):
          _data = data;
        case Failure(message: final message):
          _error = message;
      }
    });
  }

  Future<void> _respond(CaregiverLink link, String action) async {
    setState(() => _busyName = link.name);
    final result = await ServiceLocator.instance.caregivers.respondCaregiverRequest(
      name: link.name,
      action: action,
    );
    if (!mounted) return;
    setState(() => _busyName = null);
    switch (result) {
      case Success(data: final message):
        _snack(message);
        _load();
      case Failure(message: final message):
        _snack(message, error: true);
    }
  }

  void _snack(String message, {bool error = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: error ? AppColors.error : AppColors.textSecondary,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(l10n.caregiversTitle),
        backgroundColor: AppColors.white,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final refreshed = await Navigator.of(context).push<bool>(
            MaterialPageRoute(builder: (_) => const AddCaregiverScreen()),
          );
          if (refreshed == true) _load();
        },
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.white,
        icon: const Icon(Icons.person_add_alt_1),
        label: Text(l10n.addCaregiver),
      ),
      body: RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _InfoBanner(text: l10n.caregiversInfoBanner),
            const SizedBox(height: 16),
            if (_loading)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 80),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (_error != null)
              _ErrorState(message: _error!, onRetry: _load)
            else ...[
              _SectionTitle(title: l10n.myCaregivers),
              const SizedBox(height: 10),
              if (_data.caregivers.isEmpty)
                _EmptyCard(
                  title: l10n.noCaregiversYet,
                  subtitle: l10n.caregiversEmptyHint,
                )
              else
                ..._data.caregivers.map(
                  (link) => _CaregiverCard(
                    link: link,
                    permissionSummary: _permissionSummary(context, link.permissions),
                    onTap: () async {
                      final changed = await Navigator.of(context).push<bool>(
                        MaterialPageRoute(
                          builder: (_) => CaregiverDetailScreen(link: link),
                        ),
                      );
                      if (changed == true) _load();
                    },
                  ),
                ),
              const SizedBox(height: 24),
              _SectionTitle(title: l10n.pendingRequests),
              const SizedBox(height: 10),
              if (_data.pending.isEmpty)
                _EmptyCard(
                  title: l10n.noPendingRequests,
                  subtitle: l10n.pendingRequestsHint,
                )
              else
                ..._data.pending.map(
                  (link) => _PendingCard(
                    link: link,
                    busy: _busyName == link.name,
                    permissionSummary: _permissionSummary(context, link.permissions),
                    onAccept: () => _respond(link, 'accept'),
                    onReject: () => _respond(link, 'reject'),
                  ),
                ),
            ],
          ],
        ),
      ),
    );
  }

  String _permissionSummary(BuildContext context, Map<String, bool> permissions) {
    final l10n = AppLocalizations.of(context);
    final labels = <String>[];
    if (permissions['view_readings'] == true) labels.add(l10n.viewReadings);
    if (permissions['view_medicines'] == true) labels.add(l10n.viewMedicines);
    if (permissions['view_appointments'] == true) labels.add(l10n.viewAppointments);
    if (permissions['view_subscription'] == true) labels.add(l10n.viewSubscription);
    return labels.join(' • ');
  }
}

class _InfoBanner extends StatelessWidget {
  final String text;

  const _InfoBanner({required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.primarySurface,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          const Icon(Icons.shield_outlined, color: AppColors.primary),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(fontSize: 13, color: AppColors.primary),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;

  const _SectionTitle({required this.title});

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
    );
  }
}

class _CaregiverCard extends StatelessWidget {
  final CaregiverLink link;
  final String permissionSummary;
  final VoidCallback onTap;

  const _CaregiverCard({
    required this.link,
    required this.permissionSummary,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.cardBorder),
        ),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: AppColors.primaryLight,
              child: Text(
                link.displayName.isNotEmpty ? link.displayName[0] : 'C',
                style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w700),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(link.displayName, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 4),
                  Text(
                    '${link.relationship} • ${link.fullWhatsappNumber}',
                    style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                  ),
                  if (permissionSummary.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(permissionSummary, style: const TextStyle(fontSize: 12, color: AppColors.textTertiary)),
                  ],
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.success.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                l10n.caregiverActive,
                style: const TextStyle(color: AppColors.success, fontWeight: FontWeight.w600, fontSize: 12),
              ),
            ),
            const SizedBox(width: 6),
            const Icon(Icons.chevron_right, color: AppColors.textTertiary),
          ],
        ),
      ),
    );
  }
}

class _PendingCard extends StatelessWidget {
  final CaregiverLink link;
  final String permissionSummary;
  final bool busy;
  final VoidCallback onAccept;
  final VoidCallback onReject;

  const _PendingCard({
    required this.link,
    required this.permissionSummary,
    required this.busy,
    required this.onAccept,
    required this.onReject,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                backgroundColor: AppColors.warning.withValues(alpha: 0.15),
                child: Text(
                  link.displayName.isNotEmpty ? link.displayName[0] : 'P',
                  style: const TextStyle(color: AppColors.warning, fontWeight: FontWeight.w700),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(link.displayName, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
                    Text(
                      '${link.relationship} • ${link.fullWhatsappNumber}',
                      style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.warning.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  l10n.statusPending,
                  style: const TextStyle(color: AppColors.warning, fontWeight: FontWeight.w600, fontSize: 12),
                ),
              ),
            ],
          ),
          if (permissionSummary.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(permissionSummary, style: const TextStyle(fontSize: 12, color: AppColors.textTertiary)),
          ],
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: busy ? null : onReject,
                  child: Text(l10n.rejectCaregiver),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ElevatedButton(
                  onPressed: busy ? null : onAccept,
                  child: busy
                      ? const SizedBox(
                          height: 18,
                          width: 18,
                          child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.white),
                        )
                      : Text(l10n.acceptCaregiver),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _EmptyCard extends StatelessWidget {
  final String title;
  final String subtitle;

  const _EmptyCard({required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        children: [
          const Icon(Icons.people_outline, size: 36, color: AppColors.textTertiary),
          const SizedBox(height: 10),
          Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
          const SizedBox(height: 4),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: const TextStyle(color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  final String message;
  final Future<void> Function() onRetry;

  const _ErrorState({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        children: [
          const Icon(Icons.error_outline, size: 36, color: AppColors.error),
          const SizedBox(height: 10),
          Text(message, textAlign: TextAlign.center),
          const SizedBox(height: 10),
          ElevatedButton(
            onPressed: onRetry,
            child: Text(l10n.retry),
          ),
        ],
      ),
    );
  }
}
