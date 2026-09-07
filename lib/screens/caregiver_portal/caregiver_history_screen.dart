import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_colors.dart';
import '../../core/utils/result.dart';
import '../../l10n/app_localizations.dart';
import '../../providers/app_provider.dart';
import '../../services/service_locator.dart';
import '../../widgets/active_patient_card.dart';
import '../../widgets/coverage_outcome.dart';

class CaregiverHistoryScreen extends StatefulWidget {
  const CaregiverHistoryScreen({super.key});

  @override
  State<CaregiverHistoryScreen> createState() => _CaregiverHistoryScreenState();
}

class _CaregiverHistoryScreenState extends State<CaregiverHistoryScreen> {
  String _filter = 'all';
  Map<String, dynamic>? _data;
  bool _loading = true;
  int _visible = 8;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    final patient = context.read<AppProvider>().activeCarePerson?.patient;
    if (patient == null) {
      setState(() => _loading = false);
      return;
    }
    final result = await ServiceLocator.instance.caregivers.getSponsoredPatientData(
      patient: patient,
      dataType: 'history',
    );
    if (!mounted) return;
    setState(() {
      _loading = false;
      if (result case Success(data: final data)) _data = data;
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final readings = (_data?['readings'] as List?) ?? const [];
    final appts = (_data?['appointments'] as List?) ?? const [];
    final labs = (_data?['labs'] as List?) ?? const [];
    final meds = (_data?['orders'] as List?) ?? const [];

    final items = <_HistItem>[];
    if (_filter == 'all' || _filter == 'readings') {
      for (final r in readings.whereType<Map>()) {
        items.add(_HistItem(
          type: 'readings',
          title: 'BP ${r['bp_systolic'] ?? '—'}/${r['bp_diastolic'] ?? '—'}',
          subtitle: '${r['reading_date'] ?? ''}  ${r['reading_time'] ?? ''}',
          status: (r['risk_level'] ?? '').toString(),
        ));
      }
    }
    if (_filter == 'all' || _filter == 'appointments') {
      for (final a in appts.whereType<Map>()) {
        items.add(_HistItem(
          type: 'appointments',
          title: (a['practitioner_name'] ?? l10n.filterAppointments).toString(),
          subtitle: '${a['appointment_date'] ?? ''}  ${a['appointment_time'] ?? ''}',
          status: (a['status'] ?? '').toString(),
        ));
      }
    }
    if (_filter == 'all' || _filter == 'labs') {
      for (final l in labs.whereType<Map>()) {
        items.add(_HistItem(
          type: 'labs',
          title: (l['template'] ?? l10n.filterLabs).toString(),
          subtitle: '${l['creation'] ?? ''}',
          status: (l['status'] ?? '').toString(),
          canViewResults: (l['result_date'] != null && '${l['result_date']}'.isNotEmpty) ||
              '${l['status']}'.toLowerCase().contains('complet'),
          resultDetail: '${l['status'] ?? ''}  ${l['result_date'] ?? l['creation'] ?? ''}',
        ));
      }
    }
    if (_filter == 'all' || _filter == 'medicines') {
      for (final m in meds.whereType<Map>()) {
        items.add(_HistItem(
          type: 'medicines',
          title: (m['name'] ?? l10n.filterMedicines).toString(),
          subtitle: '${m['modified'] ?? ''}',
          status: (m['status'] ?? '').toString(),
        ));
      }
    }

    return Scaffold(
      backgroundColor: AppColors.scaffold(context),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.caregiverHistoryTitle,
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                      color: AppColors.text(context),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(l10n.caregiverHistoryHint, style: TextStyle(color: AppColors.textMuted(context))),
                  const SizedBox(height: 12),
                  ActivePatientCard(onChange: _load),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      BigChoiceButton(
                        label: l10n.filterAll,
                        selected: _filter == 'all',
                        onTap: () => setState(() => _filter = 'all'),
                      ),
                      BigChoiceButton(
                        label: l10n.filterReadings,
                        selected: _filter == 'readings',
                        onTap: () => setState(() => _filter = 'readings'),
                      ),
                      BigChoiceButton(
                        label: l10n.filterAppointments,
                        selected: _filter == 'appointments',
                        onTap: () => setState(() => _filter = 'appointments'),
                      ),
                      BigChoiceButton(
                        label: l10n.filterLabs,
                        selected: _filter == 'labs',
                        onTap: () => setState(() => _filter = 'labs'),
                      ),
                      BigChoiceButton(
                        label: l10n.filterMedicines,
                        selected: _filter == 'medicines',
                        onTap: () => setState(() => _filter = 'medicines'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            if (!_loading) _summaryStrip(l10n, readings),
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: items.length > _visible ? _visible + 1 : items.length,
                      itemBuilder: (context, i) {
                        if (i == _visible) {
                          return SizedBox(
                            height: 52,
                            child: OutlinedButton(
                              onPressed: () => setState(() => _visible += 8),
                              child: Text(l10n.viewMoreHistory),
                            ),
                          );
                        }
                        final item = items[i];
                        return Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: AppColors.card(context),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: AppColors.border(context)),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(item.title, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
                                    Text(item.subtitle, style: TextStyle(color: AppColors.textMuted(context))),
                                  ],
                                ),
                              ),
                              if (item.canViewResults)
                                TextButton(
                                  onPressed: () {
                                    showDialog<void>(
                                      context: context,
                                      builder: (ctx) => AlertDialog(
                                        title: Text(l10n.viewResults),
                                        content: Text(item.resultDetail),
                                        actions: [
                                          TextButton(onPressed: () => Navigator.pop(ctx), child: Text(l10n.close)),
                                        ],
                                      ),
                                    );
                                  },
                                  child: Text(l10n.viewResults),
                                )
                              else if (item.type == 'labs')
                                Text(l10n.resultsNotReady, style: TextStyle(fontSize: 12, color: AppColors.textMuted(context))),
                              if (item.status.isNotEmpty)
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: AppColors.primaryLight,
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Text(item.status, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                                ),
                            ],
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _summaryStrip(AppLocalizations l10n, List readings) {
    var sys = 0.0, dia = 0.0, sugar = 0.0;
    var bpN = 0, sugarN = 0;
    for (final r in readings.whereType<Map>()) {
      final s = r['bp_systolic'];
      final d = r['bp_diastolic'];
      final g = r['blood_sugar'];
      if (s is num && d is num) {
        sys += s.toDouble();
        dia += d.toDouble();
        bpN++;
      }
      if (g is num) {
        sugar += g.toDouble();
        sugarN++;
      }
    }
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      child: Row(
        children: [
          Expanded(child: _statChip(l10n.totalReadings, '${readings.length}')),
          const SizedBox(width: 8),
          Expanded(
            child: _statChip(
              l10n.avgBp,
              bpN == 0 ? '—' : '${(sys / bpN).round()}/${(dia / bpN).round()}',
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _statChip(
              l10n.avgSugar,
              sugarN == 0 ? '—' : '${(sugar / sugarN).round()}',
            ),
          ),
        ],
      ),
    );
  }

  Widget _statChip(String label, String value) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppColors.card(context),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border(context)),
      ),
      child: Column(
        children: [
          Text(label, style: TextStyle(fontSize: 11, color: AppColors.textMuted(context))),
          const SizedBox(height: 4),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
        ],
      ),
    );
  }
}

class _HistItem {
  final String type;
  final String title;
  final String subtitle;
  final String status;
  final bool canViewResults;
  final String resultDetail;
  _HistItem({
    required this.type,
    required this.title,
    required this.subtitle,
    required this.status,
    this.canViewResults = false,
    this.resultDetail = '',
  });
}
