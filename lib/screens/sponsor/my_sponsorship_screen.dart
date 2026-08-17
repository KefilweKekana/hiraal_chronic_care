import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../core/constants/app_constants.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/result.dart';
import '../../l10n/app_localizations.dart';
import '../../models/caregiver_link.dart';
import '../../services/service_locator.dart';

class MySponsorshipScreen extends StatefulWidget {
  const MySponsorshipScreen({super.key});

  @override
  State<MySponsorshipScreen> createState() => _MySponsorshipScreenState();
}

class _MySponsorshipScreenState extends State<MySponsorshipScreen> {
  bool _loading = true;
  String? _error;
  List<SponsorshipSummary> _items = const [];
  SponsorshipDashboard? _dashboard;
  Map<String, dynamic>? _snapshot;
  String? _selectedName;

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
    final result = await ServiceLocator.instance.caregivers.listMySponsorships();
    if (!mounted) return;
    switch (result) {
      case Success(data: final data):
        setState(() {
          _items = data;
          _loading = false;
        });
        if (data.isNotEmpty) {
          await _select(data.first.name, data.first.patient);
        }
      case Failure(message: final message):
        setState(() {
          _error = message;
          _loading = false;
        });
    }
  }

  Future<void> _select(String name, String patient) async {
    setState(() => _selectedName = name);
    final dashboardResult = await ServiceLocator.instance.caregivers.getSponsorshipDashboard(name);
    final snapshotResult = await ServiceLocator.instance.caregivers.getSponsoredPatientData(
      patient: patient,
      dataType: 'summary',
    );
    if (!mounted) return;
    setState(() {
      if (dashboardResult case Success(data: final data)) {
        _dashboard = data;
      }
      if (snapshotResult case Success(data: final data)) {
        _snapshot = data;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(l10n.mySponsorshipTitle),
        backgroundColor: AppColors.white,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
      ),
      body: RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            if (_loading)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 100),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (_error != null)
              _ErrorCard(message: _error!, onRetry: _load)
            else if (_items.isEmpty)
              _EmptyCard(
                title: l10n.noSponsorshipsYet,
                subtitle: l10n.noSponsorshipsHint,
              )
            else ...[
              Text(l10n.activeSponsorships, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
              const SizedBox(height: 10),
              ..._items.map(
                (item) => GestureDetector(
                  onTap: () => _select(item.name, item.patient),
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: _selectedName == item.name ? AppColors.primary : AppColors.cardBorder,
                      ),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(item.patientName, style: const TextStyle(fontWeight: FontWeight.w700)),
                              const SizedBox(height: 4),
                              Text(item.plan ?? '', style: const TextStyle(color: AppColors.textSecondary)),
                              Text(
                                '${AppConstants.currencySymbol}${item.monthlyAmount.toStringAsFixed(2)} / month',
                                style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w600),
                              ),
                            ],
                          ),
                        ),
                        const Icon(Icons.chevron_right, color: AppColors.textTertiary),
                      ],
                    ),
                  ),
                ),
              ),
              if (_dashboard != null) ...[
                const SizedBox(height: 20),
                _DashboardCard(dashboard: _dashboard!, snapshot: _snapshot),
              ],
            ],
          ],
        ),
      ),
    );
  }
}

class _DashboardCard extends StatelessWidget {
  final SponsorshipDashboard dashboard;
  final Map<String, dynamic>? snapshot;

  const _DashboardCard({
    required this.dashboard,
    required this.snapshot,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final items = (snapshot?['items'] as List? ?? const []);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(dashboard.patientName, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          _row(l10n.status, dashboard.status),
          _row(l10n.planLabel, dashboard.plan ?? '—'),
          _row(
            l10n.nextPaymentLabel,
            dashboard.nextPaymentDate != null ? DateFormat('dd MMM yyyy').format(dashboard.nextPaymentDate!) : '—',
          ),
          const SizedBox(height: 16),
          Text(l10n.latestUpdates, style: const TextStyle(fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          ...dashboard.updates.map(
            (update) => Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.check_circle, size: 16, color: AppColors.success),
                  const SizedBox(width: 8),
                  Expanded(child: Text(update)),
                ],
              ),
            ),
          ),
          if (items.isNotEmpty) ...[
            const SizedBox(height: 16),
            Text(l10n.patientSnapshot, style: const TextStyle(fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            ...items.whereType<Map>().map(
              (entry) => Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: _row(
                  (entry['label'] ?? '').toString(),
                  (entry['value'] ?? '').toString(),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _row(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Expanded(child: Text(label, style: const TextStyle(color: AppColors.textSecondary))),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

class _ErrorCard extends StatelessWidget {
  final String message;
  final Future<void> Function() onRetry;

  const _ErrorCard({required this.message, required this.onRetry});

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
          Text(message, textAlign: TextAlign.center),
          const SizedBox(height: 10),
          ElevatedButton(onPressed: onRetry, child: Text(l10n.retry)),
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
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        children: [
          const Icon(Icons.volunteer_activism_outlined, size: 36, color: AppColors.textTertiary),
          const SizedBox(height: 10),
          Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
          const SizedBox(height: 4),
          Text(subtitle, textAlign: TextAlign.center, style: const TextStyle(color: AppColors.textSecondary)),
        ],
      ),
    );
  }
}
