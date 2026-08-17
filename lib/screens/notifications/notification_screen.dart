import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/app_logger.dart';
import '../../core/utils/result.dart';
import '../../l10n/app_localizations.dart';
import '../../models/notification.dart';
import '../../providers/app_provider.dart';
import '../../services/service_locator.dart';
import '../services/order_tracking_screen.dart';

class NotificationScreen extends StatefulWidget {
  const NotificationScreen({super.key});

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<AppNotification> notifications = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _fetchNotifications();
  }

  Future<void> _fetchNotifications() async {
    setState(() { _isLoading = true; });
    final result = await ServiceLocator.instance.notifications.getNotifications();
    if (!mounted) return;
    switch (result) {
      case Success(data: final data):
        setState(() { notifications = data; _isLoading = false; });
      case Failure(message: final msg):
        // Never show fabricated notifications — on failure show the real
        // (empty) state so the patient only ever sees genuine alerts.
        log.w('Notifications fetch failed: $msg');
        setState(() { notifications = []; _isLoading = false; });
    }
  }

  Future<void> _markRead(AppNotification n) async {
    if (n.isRead) return;
    setState(() { n.isRead = true; });
    final provider = context.read<AppProvider>();
    provider.decrementUnreadNotifications();
    final result = await ServiceLocator.instance.notifications.markRead(n.id);
    // The update above was optimistic — if the server rejected it, revert so
    // the item and the unread badge match the server again.
    if (result is Failure) {
      if (!mounted) return;
      setState(() { n.isRead = false; });
      provider.fetchUnreadNotificationCount();
    }
  }

  /// Mark every visible unread notification read (optimistic), then tell the
  /// server one by one. Best-effort: the next fetch reconciles any failure.
  Future<void> _markAllRead() async {
    final unread = notifications.where((n) => !n.isRead).toList();
    if (unread.isEmpty) return;
    final provider = context.read<AppProvider>();
    setState(() {
      for (final n in unread) {
        n.isRead = true;
        provider.decrementUnreadNotifications();
      }
    });
    for (final n in unread) {
      await ServiceLocator.instance.notifications.markRead(n.id);
    }
    if (mounted) provider.fetchUnreadNotificationCount();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  bool get _hasUnread => notifications.any((n) => !n.isRead);

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(l10n.notifications),
        leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => Navigator.pop(context)),
        actions: [
          if (_hasUnread)
            TextButton(
              onPressed: _markAllRead,
              child: Text(l10n.markAllRead, style: const TextStyle(fontSize: 13)),
            ),
        ],
      ),
      body: Column(
        children: [
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.cardBorder),
            ),
            child: TabBar(
              controller: _tabController,
              indicator: BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.circular(10)),
              indicatorSize: TabBarIndicatorSize.tab,
              labelColor: AppColors.white,
              unselectedLabelColor: AppColors.textSecondary,
              labelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 11, height: 1.1),
              unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w500, fontSize: 11, height: 1.1),
              labelPadding: const EdgeInsets.symmetric(horizontal: 2),
              tabs: [
                Tab(height: 40, child: Text(l10n.tabAll, maxLines: 1, overflow: TextOverflow.ellipsis, textAlign: TextAlign.center)),
                Tab(height: 40, child: Text(l10n.tabMessages, maxLines: 1, overflow: TextOverflow.ellipsis, textAlign: TextAlign.center)),
                Tab(height: 40, child: Text(l10n.tabReminders, maxLines: 1, overflow: TextOverflow.ellipsis, textAlign: TextAlign.center)),
                Tab(height: 40, child: Text(l10n.tabAlerts, maxLines: 1, overflow: TextOverflow.ellipsis, textAlign: TextAlign.center)),
              ],
              dividerColor: Colors.transparent,
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : TabBarView(
              controller: _tabController,
              children: [
                _buildNotificationList(l10n, notifications),
                _buildNotificationList(l10n, notifications.where((n) => n.type == 'message').toList()),
                _buildNotificationList(l10n, notifications.where((n) => n.type == 'reminder').toList()),
                _buildNotificationList(l10n, notifications.where((n) => n.type == 'alert').toList()),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationList(AppLocalizations l10n, List<AppNotification> items) {
    if (items.isEmpty) {
      // Scrollable even when empty so pull-to-refresh still works.
      return RefreshIndicator(
        onRefresh: _fetchNotifications,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: [
            const SizedBox(height: 120),
            const Icon(Icons.notifications_none, size: 56, color: AppColors.textTertiary),
            const SizedBox(height: 12),
            Center(
              child: Text(l10n.noNotificationsYet,
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.textSecondary)),
            ),
            const SizedBox(height: 4),
            Center(
              child: Text(l10n.notificationsEmptyHint,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 12, color: AppColors.textTertiary, height: 1.5)),
            ),
          ],
        ),
      );
    }

    // The server sorts newest-first; insert a section header whenever the
    // date bucket changes.
    final children = <Widget>[];
    String? lastSection;
    for (final n in items) {
      final section = _sectionFor(l10n, n.date);
      if (section != lastSection) {
        children.add(Padding(
          padding: const EdgeInsets.only(top: 14, bottom: 6, left: 2),
          child: Text(section,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.textTertiary)),
        ));
        lastSection = section;
      }
      children.add(_buildTile(l10n, n));
    }

    return RefreshIndicator(
      onRefresh: _fetchNotifications,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 16),
        children: children,
      ),
    );
  }

  /// Date bucket for the section headers.
  String _sectionFor(AppLocalizations l10n, DateTime d) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final day = DateTime(d.year, d.month, d.day);
    final diff = today.difference(day).inDays;
    if (diff <= 0) return l10n.sectionToday;
    if (diff == 1) return l10n.sectionYesterday;
    if (diff < 7) return l10n.sectionThisWeek;
    return l10n.sectionOlder;
  }

  /// Icon + colors for a notification. The server hardcodes every entry's
  /// type to "Alert", so for linked documents the real meaning is derived
  /// from the document type and the title instead.
  ({IconData icon, Color color, Color bg}) _visualFor(AppNotification n) {
    if (n.documentType == 'Medicine Request') {
      final t = n.title.toLowerCase();
      if (t.contains('paid') || t.contains('delivered')) {
        return (icon: Icons.check_circle, color: AppColors.success, bg: AppColors.successLight);
      }
      if (t.contains('cancelled')) {
        return (icon: Icons.cancel, color: AppColors.error, bg: AppColors.errorLight);
      }
      if (t.contains('awaiting payment')) {
        return (icon: Icons.payments, color: AppColors.warning, bg: AppColors.warningLight);
      }
      return (icon: Icons.inventory_2, color: AppColors.primary, bg: AppColors.primaryLight);
    }
    switch (n.type) {
      case 'message':
        return (icon: Icons.mail, color: AppColors.primary, bg: AppColors.primaryLight);
      case 'reminder':
        return (icon: Icons.alarm, color: AppColors.warning, bg: AppColors.warningLight);
      case 'alert':
        return (icon: Icons.warning_amber, color: AppColors.error, bg: AppColors.errorLight);
      default:
        return (icon: Icons.info, color: AppColors.info, bg: AppColors.infoLight);
    }
  }

  Widget _buildTile(AppLocalizations l10n, AppNotification n) {
    final v = _visualFor(n);
    return GestureDetector(
      onTap: () {
        _markRead(n);
        // Deep-link to the linked record. A medicine order (e.g. one that's
        // "Awaiting Payment") opens its tracking screen, where the patient
        // can Confirm & Pay.
        if (n.documentType == 'Medicine Request' && (n.documentName ?? '').isNotEmpty) {
          Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => OrderTrackingScreen(orderId: n.documentName!)),
          );
          return;
        }
        showDialog(
          context: context,
          builder: (_) => AlertDialog(
            title: Text(n.title),
            content: Text(n.body),
            actions: [TextButton(onPressed: () => Navigator.pop(context), child: Text(l10n.close))],
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: n.isRead ? AppColors.inputBackground : AppColors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.cardBorder),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(color: v.bg, borderRadius: BorderRadius.circular(10)),
              child: Icon(v.icon, size: 19, color: v.color),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    n.title,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: n.isRead ? FontWeight.w500 : FontWeight.w700,
                      color: n.isRead ? AppColors.textSecondary : AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(n.body, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary, height: 1.4)),
                  const SizedBox(height: 4),
                  Text(_formatTime(l10n, n.date), style: const TextStyle(fontSize: 11, color: AppColors.textTertiary)),
                ],
              ),
            ),
            const SizedBox(width: 8),
            // Unread marker — only on unread rows, so it actually means something.
            Padding(
              padding: const EdgeInsets.only(top: 14),
              child: n.isRead
                  ? const Icon(Icons.chevron_right, color: AppColors.textTertiary, size: 18)
                  : Container(
                      width: 9,
                      height: 9,
                      decoration: BoxDecoration(color: v.color, shape: BoxShape.circle),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatTime(AppLocalizations l10n, DateTime date) {
    final diff = DateTime.now().difference(date);
    // Future timestamps (e.g. server time parsed as local) have no "ago".
    if (diff.isNegative || diff.inMinutes < 1) return l10n.justNow;
    if (diff.inMinutes < 60) return l10n.minutesAgo(diff.inMinutes);
    if (diff.inHours < 24) return l10n.hoursAgo(diff.inHours);
    return l10n.daysAgo(diff.inDays);
  }
}
