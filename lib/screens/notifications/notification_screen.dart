import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/app_logger.dart';
import '../../core/utils/result.dart';
import '../../models/notification.dart';
import '../../providers/app_provider.dart';
import '../../services/service_locator.dart';

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
        log.w('Notifications fetch failed, using mock: $msg');
        setState(() { notifications = AppNotification.mockNotifications(); _isLoading = false; });
    }
  }

  Future<void> _markRead(AppNotification n) async {
    if (n.isRead) return;
    setState(() { n.isRead = true; });
    final provider = context.read<AppProvider>();
    provider.decrementUnreadNotifications();
    await ServiceLocator.instance.notifications.markRead(n.id);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Notifications'),
        leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => Navigator.pop(context)),
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
              labelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
              unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13),
              labelPadding: const EdgeInsets.symmetric(horizontal: 4),
              tabs: const [
                Tab(height: 36, text: 'All'),
                Tab(height: 36, text: 'Messages'),
                Tab(height: 36, text: 'Reminders'),
                Tab(height: 36, text: 'Alerts'),
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
                _buildNotificationList(notifications),
                _buildNotificationList(notifications.where((n) => n.type == 'message').toList()),
                _buildNotificationList(notifications.where((n) => n.type == 'reminder').toList()),
                _buildNotificationList(notifications.where((n) => n.type == 'alert').toList()),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: AppColors.primarySurface, borderRadius: BorderRadius.circular(10)),
              child: Row(
                children: const [
                  Icon(Icons.verified, size: 16, color: AppColors.primary),
                  SizedBox(width: 8),
                  Expanded(child: Text('Your care team may send you messages, reminders, and important updates.\nCheck back often.', style: TextStyle(fontSize: 11, color: AppColors.primary))),
                  Icon(Icons.more_horiz, size: 18, color: AppColors.primary),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationList(List<AppNotification> items) {
    if (items.isEmpty) {
      return const Center(child: Text('No notifications', style: TextStyle(color: AppColors.textSecondary)));
    }
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: items.length,
      itemBuilder: (context, i) {
        final n = items[i];
        Color iconBg;
        IconData icon;
        Color dotColor;
        switch (n.type) {
          case 'message': icon = Icons.mail; iconBg = AppColors.primaryLight; dotColor = AppColors.primary; break;
          case 'reminder': icon = Icons.alarm; iconBg = AppColors.warningLight; dotColor = AppColors.warning; break;
          case 'alert': icon = Icons.warning; iconBg = AppColors.errorLight; dotColor = AppColors.error; break;
          default: icon = Icons.info; iconBg = AppColors.infoLight; dotColor = AppColors.info;
        }
        return GestureDetector(
          onTap: () {
            _markRead(n);
            showDialog(
              context: context,
              builder: (_) => AlertDialog(
                title: Text(n.title),
                content: Text(n.body),
                actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('Close'))],
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
              Container(width: 8, height: 8, margin: const EdgeInsets.only(top: 6), decoration: BoxDecoration(color: dotColor, shape: BoxShape.circle)),
              const SizedBox(width: 10),
              Container(
                width: 36, height: 36,
                decoration: BoxDecoration(color: iconBg, borderRadius: BorderRadius.circular(10)),
                child: Icon(icon, size: 18, color: dotColor),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(n.title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 2),
                    Text(n.body, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary, height: 1.4)),
                    const SizedBox(height: 4),
                    Text(_formatTime(n.date), style: const TextStyle(fontSize: 11, color: AppColors.textTertiary)),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: AppColors.textTertiary, size: 18),
            ],
          ),
        ),
        );
      },
    );
  }

  String _formatTime(DateTime date) {
    final diff = DateTime.now().difference(date);
    if (diff.inMinutes < 60) return '${diff.inMinutes} min ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }
}
