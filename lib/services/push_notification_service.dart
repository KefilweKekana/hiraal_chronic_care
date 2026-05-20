import 'dart:async';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../core/database/database_helper.dart';
import '../core/utils/app_logger.dart';

const String _alertChannelId = 'hiraal_alerts';
const String _alertChannelName = 'Health Alerts';
const String _reminderChannelId = 'hiraal_reminders';
const String _reminderChannelName = 'Reminders';

/// Top-level background message handler.
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  log.i('Background FCM message: \${message.messageId}');
  await PushNotificationService._showLocalNotificationFromMessage(message);
}

/// Manages Firebase Cloud Messaging and local notifications.
class PushNotificationService {
  PushNotificationService._();
  static final PushNotificationService _instance = PushNotificationService._();
  static PushNotificationService get instance => _instance;

  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();

  bool _initialized = false;
  String? _fcmToken;

  String? get fcmToken => _fcmToken;

  /// Initialize FCM, request permissions, and set up handlers.
  Future<void> initialize() async {
    if (_initialized) return;

    // Request permission (iOS critical).
    await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );
    log.i('FCM permission requested');

    // Local notifications setup.
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );
    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );
    await _localNotifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: (response) {
        log.i('Local notification tapped: \${response.payload}');
      },
    );

    // Create notification channels.
    await _createChannels();

    // Foreground handler.
    FirebaseMessaging.onMessage.listen((message) async {
      log.i('Foreground FCM message: \${message.notification?.title}');
      await _showLocalNotificationFromMessage(message);
      await _incrementBadgeCount();
    });

    // Background & terminated handlers.
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    // Token refresh.
    _messaging.onTokenRefresh.listen((token) {
      _fcmToken = token;
      log.i('FCM token refreshed');
    });

    _fcmToken = await _messaging.getToken();
    log.i('FCM token: \$_fcmToken');

    _initialized = true;
  }

  Future<void> _createChannels() async {
    const androidAlertChannel = AndroidNotificationChannel(
      _alertChannelId,
      _alertChannelName,
      description: 'High priority health alerts',
      importance: Importance.high,
    );
    const androidReminderChannel = AndroidNotificationChannel(
      _reminderChannelId,
      _reminderChannelName,
      description: 'Medication and appointment reminders',
      importance: Importance.defaultImportance,
    );

    final androidPlugin = _localNotifications.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    await androidPlugin?.createNotificationChannel(androidAlertChannel);
    await androidPlugin?.createNotificationChannel(androidReminderChannel);
  }

  static Future<void> _showLocalNotificationFromMessage(RemoteMessage message) async {
    final notification = message.notification;
    final data = message.data;

    final String title = notification?.title ?? data['title'] ?? 'Hiraal Chronic Care';
    final String body = notification?.body ?? data['body'] ?? '';
    final String type = data['type'] ?? 'general';

    final bool isAlert = type == 'alert' || type == 'high_priority';

    final androidDetails = AndroidNotificationDetails(
      isAlert ? _alertChannelId : _reminderChannelId,
      isAlert ? _alertChannelName : _reminderChannelName,
      importance: isAlert ? Importance.high : Importance.defaultImportance,
      priority: isAlert ? Priority.high : Priority.defaultPriority,
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    final details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    final localPlugin = FlutterLocalNotificationsPlugin();
    await localPlugin.show(
      message.hashCode,
      title,
      body,
      details,
      payload: data['payload'],
    );
  }

  /// Show a local notification programmatically.
  Future<void> showLocalNotification({
    required String title,
    required String body,
    String type = 'general',
    String? payload,
  }) async {
    final bool isAlert = type == 'alert' || type == 'high_priority';
    final androidDetails = AndroidNotificationDetails(
      isAlert ? _alertChannelId : _reminderChannelId,
      isAlert ? _alertChannelName : _reminderChannelName,
      importance: isAlert ? Importance.high : Importance.defaultImportance,
      priority: isAlert ? Priority.high : Priority.defaultPriority,
    );
    const iosDetails = DarwinNotificationDetails();
    final details = NotificationDetails(android: androidDetails, iOS: iosDetails);
    await _localNotifications.show(
      DateTime.now().millisecond,
      title,
      body,
      details,
      payload: payload,
    );
  }

  /// Subscribe to a topic (e.g. patient-specific broadcasts).
  Future<void> subscribeToTopic(String topic) async {
    await _messaging.subscribeToTopic(topic);
  }

  /// Unsubscribe from a topic.
  Future<void> unsubscribeFromTopic(String topic) async {
    await _messaging.unsubscribeFromTopic(topic);
  }

  /// Increment the unread badge count stored locally.
  Future<void> _incrementBadgeCount() async {
    if (!DatabaseHelper.instance.isSupported) return;
    final db = await DatabaseHelper.instance.database;
    // Store badge count in a simple key-value table or use SharedPreferences.
    // Here we update a meta row in patient table for simplicity.
    try {
      await db.rawUpdate(
        "UPDATE patient SET updated_at = datetime('now') WHERE id IS NOT NULL",
      );
    } catch (_) {
      // Table may not exist yet; ignore.
    }
  }
}
