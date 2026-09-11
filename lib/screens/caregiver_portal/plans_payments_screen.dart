import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_colors.dart';
import '../../core/utils/result.dart';
import '../../l10n/app_localizations.dart';
import '../../models/caregiver_link.dart';
import '../../providers/app_provider.dart';
import '../../services/service_locator.dart';
import '../../widgets/coverage_outcome.dart';
import '../alerts/contact_care_team_screen.dart';
import '../profile/subscription_screen.dart';
import '../sponsor/sponsorship_detail_screen.dart';

class PlansPaymentsScreen extends StatefulWidget {
  const PlansPaymentsScreen({super.key});

  @override
  State<PlansPaymentsScreen> createState() => _PlansPaymentsScreenState();
}

class _PlansPaymentsScreenState extends State<PlansPaymentsScreen> {
  String _tab = 'people';
  Map<String, dynamic>? _payload;
  SponsorshipSummary? _selected;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    final result = await ServiceLocator.instance.caregivers.plansAndPayments();
    if (!mounted) return;
    if (result case Success(data: final data)) {
      setState(() {
        _payload = data;
        final people = context.read<AppProvider>().peopleICareFor;
        _selected ??= people.isNotEmpty ? people.first : null;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final people = context.watch<AppProvider>().peopleICareFor;
    final receipts = (_payload?['receipts'] as List?) ?? const [];
    final person = _selected ?? (people.isNotEmpty ? people.first : null);

    return Scaffold(
      backgroundColor: AppColors.scaffold(context),
      appBar: AppBar(title: Text(l10n.plansAndPayments)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Row(
            children: [
              Expanded(
                child: BigChoiceButton(
                  label: l10n.peopleTab,
                  selected: _tab == 'people',
                  onTap: () => setState(() => _tab = 'people'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: BigChoiceButton(
                  label: l10n.paymentHistoryTab,
                  selected: _tab == 'history',
                  onTap: () => setState(() => _tab = 'history'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (_tab == 'history')
            ...receipts.whereType<Map>().map((r) {
              return ListTile(
                title: Text('${r['patient_name'] ?? ''}  ${r['amount'] ?? ''}'),
                subtitle: Text('${r['payment_date'] ?? ''}  ${r['payment_method'] ?? ''}'),
                trailing: Text('${r['status'] ?? ''}'),
              );
            })
          else ...[
            for (final p in people)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: BigChoiceButton(
                  label: p.patientName,
                  subtitle: p.plan,
                  selected: person?.patient == p.patient,
                  onTap: () => setState(() => _selected = p),
                ),
              ),
            if (person != null) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.card(context),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.border(context)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(l10n.currentPlan, style: TextStyle(fontWeight: FontWeight.w700)),
                    Text(person.plan ?? '—', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
                    Text('\$${person.monthlyAmount.toStringAsFixed(0)} / Month'),
                    if (person.nextPaymentDate != null)
                      Text('${l10n.nextPaymentLabel}: ${DateFormat('d MMM yyyy').format(person.nextPaymentDate!)}'),
                    const SizedBox(height: 12),
                    Text(l10n.whatsIncluded, style: TextStyle(fontWeight: FontWeight.w700)),
                    Text('• ${l10n.includedConsultations}'),
                    Text('• ${l10n.includedLabs}'),
                    Text('• ${l10n.includedMedicine}'),
                    Text('• ${l10n.includedPriority}'),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton(
                        onPressed: () => Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const SubscriptionScreen()),
                        ),
                        child: Text(l10n.viewPlanDetails),
                      ),
                    ),
                    if (person.canPayForCare) ...[
                      const SizedBox(height: 8),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => SponsorshipDetailScreen(summary: person),
                            ),
                          ),
                          child: Text(l10n.sponsorshipPayNow),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              if (person.nextPaymentDate != null) ...[
                const SizedBox(height: 12),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.card(context),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.border(context)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(l10n.upcomingPayment, style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
                      Text(DateFormat('d MMM yyyy').format(person.nextPaymentDate!)),
                      Text('\$${person.monthlyAmount.toStringAsFixed(0)}'),
                      Text(l10n.dueInDays(person.nextPaymentDate!.difference(DateTime.now()).inDays.clamp(0, 365))),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(l10n.wereHereToHelp, style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
                    const SizedBox(height: 8),
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: OutlinedButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const ContactCareTeamScreen()),
                          );
                        },
                        child: Text(l10n.contactSupport),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ],
      ),
    );
  }
}
