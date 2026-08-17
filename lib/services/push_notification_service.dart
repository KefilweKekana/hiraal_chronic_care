import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../core/utils/app_logger.dart';

const String _alertChannelId = 'hiraal_alerts';
const String _alertChannelName = 'Health Alerts';
const String _reminderChannelId = 'hiraal_reminders';
const String _reminderChannelName = 'Reminders';

/// Top-level background message handler.
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  try {
    await Firebase.initializeApp();
  } catch (_) {}
  log.i('Background FCM message: ${message.messageId}');
  // When the message carries a `notification` payload, the OS already shows it
  // in the system tray while the app is backgrounded. Showing a local one here
  // too would display the notification twice — so only render data-only pushes.
  if (message.notification == null) {
    await PushNotificationService._showLocalNotificationFromMessage(message);
  }
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

  final _paymentCompleteController = StreamController<Map<String, String>>.broadcast();

  /// Emitted when the server reports a payment completion (order or subscription).
  Stream<Map<String, String>> get paymentCompleteStream => _paymentCompleteController.stream;

  String? get fcmToken => _fcmToken;

  /// Returns the FCM token, fetching it if it isn't cached yet.
  Future<String?> ensureToken() async {
    if (_fcmToken == null || _fcmToken!.isEmpty) {
      try {
        _fcmToken = await _messaging.getToken();
      } catch (_) {}
    }
    return _fcmToken;
  }

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
        log.i('Local notification tapped: ${response.payload}');
      },
    );

    // Create notification channels.
    await _createChannels();

    // Android 13+ requires an explicit runtime request for POST_NOTIFICATIONS.
    // FirebaseMessaging.requestPermission() does not reliably trigger it, so ask
    // through the local-notifications plugin (the dependable path on Android).
    final androidPlugin = _localNotifications.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    if (androidPlugin != null) {
      try {
        final granted = await androidPlugin.requestNotificationsPermission();
        log.i('Android notification permission granted: $granted');
      } catch (e) {
        log.w('requestNotificationsPermission failed', error: e);
      }
    }

    // Foreground handler.
    FirebaseMessaging.onMessage.listen((message) async {
      log.i('Foreground FCM message: ${message.notification?.title}');
      final data = message.data;
      final type = data['type'] ?? '';
      if (type == 'payment_complete' || type == 'subscription_payment_complete') {
        _paymentCompleteController.add(Map<String, String>.from(data));
      }
      await _showLocalNotificationFromMessage(message);
    });

    // Background & terminated handlers.
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    // Token refresh.
    _messaging.onTokenRefresh.listen((token) {
      _fcmToken = token;
      log.i('FCM token refreshed');
    });

    try {
      _fcmToken = await _messaging.getToken();
    } catch (e) {
      // Token fetch can fail (e.g. no Play Services); continue without it.
      log.w('Failed to fetch FCM token', error: e);
    }
    final token = _fcmToken;
    // Never log the full push token.
    log.i('FCM token: ${token == null ? 'null' : '${token.substring(0, token.length > 8 ? 8 : token.length)}…'}');

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

    final String title = notification?.title ?? data['title'] ?? 'Hiraal Lifecare';
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

    // Use the shared plugin instance. In the FCM background isolate it has
    // never been initialized (and the channels don't exist there), so data-only
    // pushes would be dropped — initialize it on first use in that isolate.
    final localPlugin = _instance._localNotifications;
    if (!_instance._initialized) {
      const initSettings = InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
        iOS: DarwinInitializationSettings(
          requestAlertPermission: false,
          requestBadgePermission: false,
          requestSoundPermission: false,
        ),
      );
      await localPlugin.initialize(initSettings);
      await _instance._createChannels();
      _instance._initialized = true;
    }
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
}
