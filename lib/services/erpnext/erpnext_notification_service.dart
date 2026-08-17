import 'package:dio/dio.dart';

import '../../core/network/api_client.dart';
import '../../core/utils/app_logger.dart';
import '../../core/utils/result.dart';
import '../../models/notification.dart';
import '../notification_service.dart';

/// ERPNext implementation of [NotificationService].
///
/// Reads from Frappe's built-in **Notification Log** doctype.
class ErpNextNotificationService implements NotificationService {
  final ApiClient _api;

  ErpNextNotificationService(this._api);

  @override
  Future<Result<List<AppNotification>>> getNotifications() async {
    try {
      final response =
          await _api.dio.post('/method/hiraal_emr.api.get_my_notifications');

      final list = response.data?['message'] as List? ?? [];
      final notifications = list
          .cast<Map<String, dynamic>>()
          .map(_fromNotificationLog)
          .toList();
      return Success(notifications);
    } on DioException catch (e) {
      log.e('getNotifications failed', error: e);
      return Failure(e.response?.data?['message']?.toString() ??
            'Failed to fetch notifications',
        statusCode: e.response?.statusCode,
      );
    } catch (e) {
      return Failure(e.toString());
    }
  }

  @override
  Future<Result<void>> markRead(String notificationId) async {
    try {
      // Scoped server endpoint marks only the caller's own notification.
      await _api.dio.post(
        '/method/hiraal_emr.api.mark_my_notification_read',
        data: {'name': notificationId},
      );
      return const Success(null);
    } on DioException catch (e) {
      log.e('markRead failed', error: e);
      return Failure(e.response?.data?['message']?.toString() ??
            'Failed to mark notification as read',
        statusCode: e.response?.statusCode,
      );
    } catch (e) {
      return Failure(e.toString());
    }
  }

  static final _htmlTagRegExp = RegExp(r'<[^>]*>', multiLine: true);
  static final _multiNewlineRegExp = RegExp(r'\n{3,}');

  /// Strip HTML tags and decode common entities.
  String _stripHtml(String html) {
    var text = html
        .replaceAll(RegExp(r'<br\s*/?>'), '\n')
        .replaceAll('</p>', '\n')
        .replaceAll(_htmlTagRegExp, '')
        .replaceAll('&amp;', '&')
        .replaceAll('&lt;', '<')
        .replaceAll('&gt;', '>')
        .replaceAll('&quot;', '"')
        .replaceAll('&#39;', "'")
        .replaceAll('&nbsp;', ' ');
    text = _multiNewlineRegExp.hasMatch(text) ? text.replaceAll(_multiNewlineRegExp, '\n\n') : text;
    return text.trim();
  }

  AppNotification _fromNotificationLog(Map<String, dynamic> json) {
    DateTime date;
    try {
      date = DateTime.parse(json['creation'] ?? '');
    } catch (_) {
      date = DateTime.now();
    }

    final rawType = (json['type'] ?? 'system').toString().toLowerCase();
    String type;
    if (rawType.contains('alert')) {
      type = 'alert';
    } else if (rawType.contains('mention') || rawType.contains('message')) {
      type = 'message';
    } else if (rawType.contains('reminder') || rawType.contains('event')) {
      type = 'reminder';
    } else {
      type = 'system';
    }

    return AppNotification(
      id: json['name']?.toString() ?? '',
      title: _stripHtml(json['subject']?.toString() ?? 'Notification'),
      body: _stripHtml(json['email_content']?.toString() ?? ''),
      type: type,
      date: date,
      isRead: json['read'] == 1,
      documentType: (json['document_type'] as Object?)?.toString(),
      documentName: (json['document_name'] as Object?)?.toString(),
    );
  }
}
