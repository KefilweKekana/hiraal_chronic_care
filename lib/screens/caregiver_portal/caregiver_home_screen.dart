import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_colors.dart';
import '../../core/utils/result.dart';
import '../../l10n/app_localizations.dart';
import '../../providers/app_provider.dart';
import '../../services/service_locator.dart';
import '../../widgets/active_patient_card.dart';
import '../notifications/notification_screen.dart';
import '../services/appointments_screen.dart';
import '../services/lab_test_screen.dart';
import '../services/medicine_order_screen.dart';

class CaregiverHomeScreen extends StatefulWidget {
  const CaregiverHomeScreen({super.key});

  @override
  State<CaregiverHomeScreen> createState() => _CaregiverHomeScreenState();
}

class _CaregiverHomeScreenState extends State<CaregiverHomeScreen> {
  Map<String, dynamic>? _home;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    final provider = context.read<AppProvider>();
    if (provider.peopleICareFor.isEmpty) {
      await provider.refreshPeopleICareFor();
    }
    final patient = provider.activeCarePerson?.patient;
    if (patient == null || patient.isEmpty) {
      if (mounted) setState(() => _loading = false);
      return;
    }
    final result = await ServiceLocator.instance.caregivers.caregiverHome(patient);
    if (!mounted) return;
    setState(() {
      _loading = false;
      if (result case Success(data: final data)) _home = data;
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final provider = context.watch<AppProvider>();
    final hour = DateTime.now().hour;
    final greeting = hour < 12
        ? l10n.greetingMorning
        : hour < 17
            ? l10n.greetingAfternoon
            : l10n.greetingEvening;
    final name = provider.patient?.name.split(' ').first ?? '';
    final reading = _home?['latest_reading'] as Map?;
    final appt = _home?['next_appointment'] as Map?;
    final lab = _home?['next_lab'] as Map?;
    final refill = _home?['refill'] as Map?;

    return Scaffold(
      backgroundColor: AppColors.scaffold(context),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _load,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      name.isEmpty ? greeting : '$greeting $name',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                        color: AppColors.text(context),
                      ),
                    ),
                  ),
                  IconButton(
                    icon: Stack(
                      children: [
                        const Icon(Icons.notifications_outlined, size: 28),
                        if (provider.unreadNotificationCount > 0)
                          Positioned(
                            right: 0,
                            top: 0,
                            child: Container(
                              width: 14,
                              height: 14,
                              decoration: const BoxDecoration(
                                color: AppColors.error,
                                shape: BoxShape.circle,
                              ),
                            ),
                          ),
                      ],
                    ),
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const NotificationScreen()),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              ActivePatientCard(onChange: () async {
                await _load();
              }),
              const SizedBox(height: 20),
              if (_loading)
                const Padding(
                  padding: EdgeInsets.all(24),
                  child: Center(child: CircularProgressIndicator()),
                )
              else ...[
                Row(
                  children: [
                    Text(
                      l10n.todaysReadings,
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                    ),
                    const Spacer(),
                    TextButton(onPressed: () => provider.setTab(2), child: Text(l10n.seeAll)),
                  ],
                ),
                Row(
                  children: [
                    Expanded(
                      child: _ReadingTile(
                        color: AppColors.chartBlue,
                        title: l10n.bloodPressure,
                        value: reading == null
                            ? '—'
                            : '${reading['bp_systolic'] ?? '—'}/${reading['bp_diastolic'] ?? '—'}',
                        status: l10n.goodStatus,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _ReadingTile(
                        color: AppColors.warning,
                        title: l10n.bloodSugar,
                        value: '${reading?['blood_sugar'] ?? '—'}',
                        status: l10n.noIssues,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _ReadingTile(
                        color: AppColors.success,
                        title: l10n.filterMedicines,
                        value: (reading?['medicine_taken'] == 1) ? '✓' : '—',
                        status: l10n.noIssues,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Text(l10n.upNext, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
                const SizedBox(height: 8),
                _NextCard(
                  color: AppColors.info,
                  title: l10n.filterAppointments,
                  body: appt == null
                      ? '—'
                      : '${appt['practitioner_name'] ?? ''}  ${appt['appointment_date'] ?? ''}',
                  onView: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const AppointmentsScreen()),
                  ),
                ),
                _NextCard(
                  color: AppColors.warning,
                  title: l10n.filterLabs,
                  body: lab == null ? '—' : '${lab['template'] ?? lab['status'] ?? ''}',
                  onView: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const LabTestScreen()),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  l10n.needsYourAttention,
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 8),
                if (refill != null)
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const MedicineOrderScreen()),
                      ),
                      child: Text(l10n.requestRefill),
                    ),
                  ),
                if (appt != null) ...[
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: OutlinedButton(
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const AppointmentsScreen()),
                      ),
                      child: Text(l10n.prepareNow),
                    ),
                  ),
                ],
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _ReadingTile extends StatelessWidget {
  final Color color;
  final String title;
  final String value;
  final String status;
  const _ReadingTile({
    required this.color,
    required this.title,
    required this.value,
    required this.status,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: TextStyle(fontSize: 13, color: color, fontWeight: FontWeight.w700)),
          const SizedBox(height: 6),
          Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
          Text(status, style: TextStyle(fontSize: 12, color: AppColors.textMuted(context))),
        ],
      ),
    );
  }
}

class _NextCard extends StatelessWidget {
  final Color color;
  final String title;
  final String body;
  final VoidCallback onView;
  const _NextCard({
    required this.color,
    required this.title,
    required this.body,
    required this.onView,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.card(context),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Row(
        children: [
          Container(
            width: 10,
            height: 48,
            decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(8)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
                Text(body, style: TextStyle(color: AppColors.textMuted(context))),
              ],
            ),
          ),
          TextButton(onPressed: onView, child: Text(l10n.viewAction)),
        ],
      ),
    );
  }
}
