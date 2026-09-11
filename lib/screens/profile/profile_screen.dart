import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_constants.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/result.dart';
import '../../l10n/app_localizations.dart';
import '../../models/patient.dart';
import '../../models/subscription.dart';
import '../../providers/app_provider.dart';
import '../../services/service_locator.dart';
import '../caregivers/caregivers_screen.dart';
import 'personal_info_screen.dart';
import 'settings_screen.dart';
import 'subscription_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  SubscriptionInfo? _subscriptionInfo;
  int _activeCaregivers = 0;
  int _pendingCaregivers = 0;
  bool _loggingOut = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final payments = ServiceLocator.instance.payments.getSubscription();
    final caregivers = ServiceLocator.instance.caregivers.listMyCaregivers();
    final payResult = await payments;
    final careResult = await caregivers;
    if (!mounted) return;
    setState(() {
      if (payResult case Success(data: final info)) {
        _subscriptionInfo = info;
      }
      if (careResult case Success(data: final data)) {
        _activeCaregivers = data.caregivers.length;
        _pendingCaregivers = data.pending.length;
      }
    });
  }

  Future<void> _logout(AppProvider provider) async {
    if (_loggingOut) return;
    setState(() => _loggingOut = true);
    try {
      await provider.logout();
    } catch (_) {
      if (mounted) {
        final l10n = AppLocalizations.of(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.couldNotLogOut)),
        );
      }
    } finally {
      if (mounted) setState(() => _loggingOut = false);
    }
  }

  void _open(Widget screen) {
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => screen));
  }

  String _languageName(AppLocalizations l10n, String code) {
    return code == 'so' ? l10n.languageSomali : l10n.languageEnglish;
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    final patient = provider.patient;
    final l10n = AppLocalizations.of(context);
    final palette = AppColors.of(context);
    final unread = provider.unreadNotificationCount;

    return Scaffold(
      backgroundColor: palette.scaffold,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _load,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
            children: [
              SizedBox(
                height: 48,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Text(
                      l10n.profileTitle,
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: palette.text,
                      ),
                    ),
                    Positioned(
                      right: 0,
                      child: IconButton(
                        tooltip: l10n.notifications,
                        onPressed: () =>
                            Navigator.pushNamed(context, '/notifications'),
                        icon: unread > 0
                            ? Badge.count(
                                count: unread,
                                backgroundColor: AppColors.error,
                                textColor: AppColors.white,
                                child: Icon(
                                  Icons.notifications_outlined,
                                  color: palette.text,
                                  size: 26,
                                ),
                              )
                            : Icon(
                                Icons.notifications_outlined,
                                color: palette.text,
                                size: 26,
                              ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              _ProfileHeroCard(
                patient: patient,
                fallbackName: l10n.patientFallback,
                memberIdLabel: l10n.memberId(
                  (patient != null && patient.patientId.isNotEmpty)
                      ? patient.patientId
                      : '–',
                ),
                editLabel: l10n.edit,
                subscription: _subscriptionInfo?.subscription,
                catalogPlans: _subscriptionInfo?.plans ?? const [],
                l10n: l10n,
                onEdit: () => _open(const PersonalInfoScreen()),
                onCarePlan: () => _open(const SubscriptionScreen()),
              ),
              const SizedBox(height: 20),
              _AccountRow(
                icon: Icons.person_outline,
                iconColor: AppColors.primary,
                title: l10n.personalInformation,
                subtitle: l10n.personalInfoSubtitle,
                onTap: () => _open(const PersonalInfoScreen()),
              ),
              _AccountRow(
                icon: Icons.favorite_outline,
                iconColor: AppColors.success,
                title: l10n.myCarePlan,
                subtitle: l10n.myCarePlanSubtitle,
                onTap: () => _open(const SubscriptionScreen()),
              ),
              _AccountRow(
                icon: Icons.groups_outlined,
                iconColor: AppColors.info,
                title: l10n.caregiverAndFamily,
                subtitle: l10n.caregiverFamilySubtitle(
                  _activeCaregivers,
                  _pendingCaregivers,
                ),
                onTap: () => _open(const CaregiversScreen()),
              ),
              _AccountRow(
                icon: Icons.settings_outlined,
                iconColor: palette.textMuted,
                title: l10n.settings,
                subtitle: l10n.settingsAccountSubtitle(
                  _languageName(l10n, provider.locale.languageCode),
                ),
                onTap: () => _open(const SettingsScreen()),
              ),
              if (provider.isDualRoleUser)
                _AccountRow(
                  icon: Icons.favorite_outline,
                  iconColor: AppColors.primary,
                  title: l10n.switchToFamilyCare,
                  subtitle: l10n.switchToFamilyCareHint,
                  onTap: () => provider.enterCaregiverPortal(),
                ),
              _AccountRow(
                icon: Icons.logout,
                iconColor: AppColors.error,
                title: l10n.logOut,
                subtitle: '',
                destructive: true,
                showChevron: !_loggingOut,
                trailing: _loggingOut
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : null,
                onTap: _loggingOut ? null : () => _logout(provider),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ProfileHeroCard extends StatelessWidget {
  final Patient? patient;
  final String fallbackName;
  final String memberIdLabel;
  final String editLabel;
  final Subscription? subscription;
  final List<SubscriptionPlan> catalogPlans;
  final AppLocalizations l10n;
  final VoidCallback onEdit;
  final VoidCallback onCarePlan;

  const _ProfileHeroCard({
    required this.patient,
    required this.fallbackName,
    required this.memberIdLabel,
    required this.editLabel,
    required this.subscription,
    required this.catalogPlans,
    required this.l10n,
    required this.onEdit,
    required this.onCarePlan,
  });

  String? _planName() {
    final plan = subscription?.plan;
    if (plan == null || plan.isEmpty) return null;
    for (final p in catalogPlans) {
      if (p.name == plan || p.planName == plan) return p.displayName;
    }
    return plan;
  }

  double _monthlyFee() {
    final sub = subscription;
    if (sub == null) return 0;
    if (sub.monthlyFee > 0) return sub.monthlyFee;
    final plan = sub.plan;
    if (plan == null || plan.isEmpty) return 0;
    for (final p in catalogPlans) {
      if (p.name == plan || p.planName == plan) return p.monthlyFee;
    }
    return 0;
  }

  String _money(double fee) {
    final symbol = AppConstants.currencySymbol;
    if (fee == fee.roundToDouble()) return '$symbol${fee.toInt()}';
    return '$symbol${fee.toStringAsFixed(2)}';
  }

  String _shortDate(BuildContext context, DateTime date) {
    return DateFormat('d MMM', Localizations.localeOf(context).toString())
        .format(date);
  }

  ({String text, Color fg, Color bg}) _statusChip(BuildContext context) {
    final palette = AppColors.of(context);
    final sub = subscription;
    if (sub == null) {
      return (text: '', fg: palette.textFaint, bg: palette.card);
    }
    if (sub.isOnTrial) {
      final end = sub.trialEndDate;
      final text = end != null
          ? l10n.trialUntil(_shortDate(context, end))
          : sub.statusLabel;
      return (text: text, fg: AppColors.primary, bg: palette.primaryMuted);
    }
    if (sub.isAwaitingFirstPayment ||
        sub.status == 'Overdue' ||
        sub.status == 'Past Due') {
      return (
        text: l10n.paymentDueShort,
        fg: AppColors.error,
        bg: palette.errorSoft,
      );
    }
    final until = sub.nextBillingDate;
    if (until != null) {
      final today = DateTime.now();
      final endDay = DateTime(until.year, until.month, until.day);
      final startDay = DateTime(today.year, today.month, today.day);
      final days = endDay.difference(startDay).inDays;
      if (days < 0) {
        return (
          text: l10n.paymentDueShort,
          fg: AppColors.error,
          bg: palette.errorSoft,
        );
      }
      if (days <= 3) {
        return (
          text: l10n.dueInDays(days),
          fg: AppColors.warning,
          bg: palette.warningSoft,
        );
      }
      return (
        text: l10n.paidUntil(_shortDate(context, until)),
        fg: AppColors.success,
        bg: palette.successSoft,
      );
    }
    if (sub.isActive || patient?.subscriptionActive == true) {
      return (
        text: l10n.statusActive,
        fg: AppColors.success,
        bg: palette.successSoft,
      );
    }
    final raw = sub.statusLabel;
    if (raw.isNotEmpty) {
      return (text: raw, fg: palette.textMuted, bg: palette.primaryMuted);
    }
    return (text: '', fg: palette.textFaint, bg: palette.card);
  }

  @override
  Widget build(BuildContext context) {
    final palette = AppColors.of(context);
    final planName = _planName();
    final fee = _monthlyFee();
    final chip = _statusChip(context);
    final planLine = planName == null
        ? l10n.noCarePlanYet
        : fee <= 0
            ? '$planName · ${l10n.freePlanLabel}'
            : l10n.planPriceAMonth(planName, _money(fee));

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(18, 18, 14, 16),
      decoration: BoxDecoration(
        color: palette.card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: palette.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                radius: 32,
                backgroundColor: palette.primarySoft,
                child: Text(
                  patient?.initials ?? '?',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primary,
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      patient?.name.isNotEmpty == true
                          ? patient!.name
                          : fallbackName,
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: palette.text,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      memberIdLabel,
                      style: TextStyle(fontSize: 14, color: palette.textMuted),
                    ),
                    if (patient?.phone.isNotEmpty == true)
                      Text(
                        patient!.phone,
                        style: TextStyle(fontSize: 14, color: palette.textFaint),
                      ),
                  ],
                ),
              ),
              TextButton(
                onPressed: onEdit,
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.primary,
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  minimumSize: const Size(0, 40),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.edit_outlined, size: 18),
                    const SizedBox(width: 4),
                    Text(
                      editLabel,
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Divider(height: 1, color: palette.divider),
          const SizedBox(height: 14),
          InkWell(
            onTap: onCarePlan,
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10n.yourCarePlan,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: palette.textFaint,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          planLine,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: palette.text,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (chip.text.isNotEmpty) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: chip.bg,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        chip.text,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: chip.fg,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AccountRow extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;
  final bool destructive;
  final bool showChevron;
  final Widget? trailing;

  const _AccountRow({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.destructive = false,
    this.showChevron = true,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    final palette = AppColors.of(context);
    final titleColor = destructive ? AppColors.error : palette.text;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: destructive ? palette.errorSoft : palette.card,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: destructive
                    ? AppColors.error.withValues(alpha: 0.22)
                    : palette.border,
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: iconColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: iconColor, size: 24),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                          color: titleColor,
                        ),
                      ),
                      if (subtitle.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(
                          subtitle,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 14,
                            color: palette.textMuted,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                trailing ??
                    (showChevron
                        ? Icon(
                            Icons.chevron_right,
                            color: destructive
                                ? AppColors.error.withValues(alpha: 0.7)
                                : palette.textFaint,
                            size: 24,
                          )
                        : const SizedBox.shrink()),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
