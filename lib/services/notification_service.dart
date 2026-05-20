import '../../core/utils/result.dart';
import '../../models/notification.dart';

/// Contract for notification operations.
abstract class NotificationService {
  /// Fetch notifications for the logged-in patient.
  Future<Result<List<AppNotification>>> getNotifications();

  /// Mark a notification as read.
  Future<Result<void>> markRead(String notificationId);
}
