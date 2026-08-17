import '../../core/utils/result.dart';
import '../../models/notification.dart';
import '../notification_service.dart';

/// Mock notification service.
class MockNotificationService implements NotificationService {
  final List<AppNotification> _store = AppNotification.mockNotifications();

  @override
  Future<Result<List<AppNotification>>> getNotifications() async {
    await Future.delayed(const Duration(milliseconds: 400));
    return Success(List.of(_store));
  }

  @override
  Future<Result<void>> markRead(String notificationId) async {
    final idx = _store.indexWhere((n) => n.id == notificationId);
    if (idx != -1) _store[idx].isRead = true;
    return const Success(null);
  }
}
