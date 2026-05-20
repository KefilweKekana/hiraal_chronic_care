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
      final response = await _api.dio.get(
        '/resource/Notification Log',
        queryParameters: {
          'fields': '["name","subject","email_content","type","creation","read"]',
          'order_by': 'creation desc',
          'limit_page_length': 50,
        },
      );

      final list = response.data?['data'] as List? ?? [];
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
      // Use frappe.client.set_value which has its own permission check
      // and works even when direct resource PUT is blocked.
      await _api.dio.post(
        '/method/frappe.client.set_value',
        data: {
          'doctype': 'Notification Log',
          'name': notificationId,
          'fieldname': 'read',
          'value': 1,
        },
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
    );
  }
}
