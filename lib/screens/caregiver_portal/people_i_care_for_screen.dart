import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_colors.dart';
import '../../l10n/app_localizations.dart';
import '../../models/caregiver_link.dart';
import '../../providers/app_provider.dart';
import '../../widgets/coverage_outcome.dart';
import '../services/appointments_screen.dart';
import '../services/medicine_order_screen.dart';
import 'add_family_member_screen.dart';
import 'caregiver_history_screen.dart';

class PeopleICareForScreen extends StatefulWidget {
  const PeopleICareForScreen({super.key});

  @override
  State<PeopleICareForScreen> createState() => _PeopleICareForScreenState();
}

class _PeopleICareForScreenState extends State<PeopleICareForScreen> {
  final _search = TextEditingController();
  String _statusFilter = 'all';
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await context.read<AppProvider>().refreshPeopleICareFor();
      if (mounted) setState(() => _loading = false);
    });
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  bool _matchesFilter(SponsorshipSummary p) {
    if (_statusFilter == 'active') return p.isActive;
    if (_statusFilter == 'inactive') return !p.isActive;
    return true;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final provider = context.watch<AppProvider>();
    final needle = _search.text.trim().toLowerCase();
    final people = provider.peopleICareFor.where((p) {
      if (needle.isNotEmpty && !p.patientName.toLowerCase().contains(needle)) {
        return false;
      }
      return _matchesFilter(p);
    }).toList();

    return Scaffold(
      backgroundColor: AppColors.scaffold(context),
      appBar: AppBar(title: Text(l10n.peopleICareFor)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(l10n.peopleICareForHint, style: TextStyle(color: AppColors.textMuted(context), fontSize: 15)),
          const SizedBox(height: 12),
          TextField(
            controller: _search,
            onChanged: (_) => setState(() {}),
            decoration: InputDecoration(
              hintText: l10n.searchByName,
              prefixIcon: const Icon(Icons.search),
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              BigChoiceButton(
                label: l10n.filterAll,
                selected: _statusFilter == 'all',
                onTap: () => setState(() => _statusFilter = 'all'),
              ),
              BigChoiceButton(
                label: l10n.filterActiveStatus,
                selected: _statusFilter == 'active',
                onTap: () => setState(() => _statusFilter = 'active'),
              ),
              BigChoiceButton(
                label: l10n.filterInactiveStatus,
                selected: _statusFilter == 'inactive',
                onTap: () => setState(() => _statusFilter = 'inactive'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (_loading)
            const Center(child: Padding(padding: EdgeInsets.all(24), child: CircularProgressIndicator()))
          else if (people.isEmpty)
            Text(l10n.noPeopleYet, style: TextStyle(color: AppColors.textMuted(context)))
          else
            for (final p in people)
              Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.card(context),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.border(context)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        CircleAvatar(
                          backgroundColor: AppColors.primaryLight,
                          child: Text(
                            p.patientName.isEmpty ? '?' : p.patientName[0],
                            style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w800),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(p.patientName, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
                              Text(
                                [
                                  p.relationship,
                                  if (p.age != null) l10n.yearsOld(p.age!),
                                  p.plan,
                                ].where((e) => (e ?? '').toString().isNotEmpty).join(' • '),
                                style: TextStyle(color: AppColors.textMuted(context)),
                              ),
                              if (p.memberSince != null)
                                Text(
                                  '${l10n.memberSince} ${DateFormat.yMMMd().format(p.memberSince!)}',
                                  style: TextStyle(fontSize: 13, color: AppColors.textMuted(context)),
                                ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: p.isActive ? AppColors.successLight : AppColors.warningLight,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            p.isActive ? l10n.filterActiveStatus : l10n.filterInactiveStatus,
                            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        OutlinedButton(
                          onPressed: () {
                            provider.setActiveCarePerson(p);
                            provider.setTab(0);
                            Navigator.pop(context);
                          },
                          child: Text(l10n.viewHealth),
                        ),
                        OutlinedButton(
                          onPressed: () {
                            provider.setActiveCarePerson(p);
                            Navigator.push(context, MaterialPageRoute(builder: (_) => const AppointmentsScreen()));
                          },
                          child: Text(l10n.filterAppointments),
                        ),
                        OutlinedButton(
                          onPressed: () {
                            provider.setActiveCarePerson(p);
                            Navigator.push(context, MaterialPageRoute(builder: (_) => const MedicineOrderScreen()));
                          },
                          child: Text(l10n.filterMedicines),
                        ),
                        OutlinedButton(
                          onPressed: () {
                            provider.setActiveCarePerson(p);
                            Navigator.push(context, MaterialPageRoute(builder: (_) => const CaregiverHistoryScreen()));
                          },
                          child: Text(l10n.viewHistory),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton.icon(
              onPressed: () async {
                await Navigator.push(context, MaterialPageRoute(builder: (_) => const AddFamilyMemberScreen()));
                if (context.mounted) context.read<AppProvider>().refreshPeopleICareFor();
              },
              icon: const Icon(Icons.add),
              label: Text(l10n.addFamilyMember),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            l10n.safeHandsFooter,
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.textMuted(context), height: 1.4),
          ),
        ],
      ),
    );
  }
}
