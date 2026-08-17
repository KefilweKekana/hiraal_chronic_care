import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart' show TimeOfDay;
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

import '../core/utils/app_logger.dart';

const String _reminderChannelId = 'hiraal_reminders';
const String _reminderChannelName = 'Reminders';

// Notification IDs for the two reminder kinds. Chosen away from the IDs used
// by PushNotificationService (message hashCodes) to avoid collisions.
const int _medsReminderId = 1001;
const int _readingReminderId = 1002;

/// Schedules on-device daily reminders (medication, health readings) with the
/// local notifications plugin. Fully offline — no FCM or backend involved.
/// Every method no-ops safely on web and other unsupported platforms.
class LocalReminderService {
  LocalReminderService._();
  static final LocalReminderService _instance = LocalReminderService._();
  static LocalReminderService get instance => _instance;

  // Shared-preferences keys (also written by the settings screen).
  static const String medsEnabledKey = 'reminder_meds_enabled';
  static const String medsTimeKey = 'reminder_meds_time';
  static const String readingEnabledKey = 'reminder_reading_enabled';
  static const String readingTimeKey = 'reminder_reading_time';

  static const TimeOfDay defaultMedsTime = TimeOfDay(hour: 8, minute: 0);
  static const TimeOfDay defaultReadingTime = TimeOfDay(hour: 9, minute: 0);

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();
  bool _initialized = false;

  /// Parse an 'HH:mm' string; null when missing or malformed.
  static TimeOfDay? tryParseTime(String? raw) {
    if (raw == null) return null;
    final parts = raw.split(':');
    if (parts.length != 2) return null;
    final hour = int.tryParse(parts[0]);
    final minute = int.tryParse(parts[1]);
    if (hour == null || minute == null) return null;
    if (hour < 0 || hour > 23 || minute < 0 || minute > 59) return null;
    return TimeOfDay(hour: hour, minute: minute);
  }

  /// Format as 'HH:mm' (24-hour, zero-padded) for persistence.
  static String formatTime(TimeOfDay time) =>
      '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';

  /// Initialize the plugin and the reminder channel. Idempotent.
  Future<void> init() async {
    if (_initialized || kIsWeb) return;
    try {
      tzdata.initializeTimeZones();
      const androidSettings =
          AndroidInitializationSettings('@mipmap/ic_launcher');
      const iosSettings = DarwinInitializationSettings(
        requestAlertPermission: false,
        requestBadgePermission: false,
        requestSoundPermission: false,
      );
      await _plugin.initialize(
        const InitializationSettings(
          android: androidSettings,
          iOS: iosSettings,
        ),
      );
      final androidPlugin = _plugin.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
      await androidPlugin?.createNotificationChannel(
        const AndroidNotificationChannel(
          _reminderChannelId,
          _reminderChannelName,
          description: 'Medication and reading reminders',
          importance: Importance.defaultImportance,
        ),
      );
      _initialized = true;
    } catch (e) {
      log.w('LocalReminderService init failed', error: e);
    }
  }

  /// Schedule (or replace) a daily reminder at [time]. Uses inexact scheduling
  /// so no exact-alarm permission is required on Android 12+.
  Future<void> scheduleDaily({
    required int id,
    required String title,
    required String body,
    required TimeOfDay time,
  }) async {
    if (kIsWeb) return;
    try {
      await init();
      if (!_initialized) return;
      // Next occurrence of the chosen wall-clock time. There is no
      // device-timezone plugin in the app, so compute the instant from the
      // local DateTime and hand it to the plugin as an absolute TZDateTime.
      final now = DateTime.now();
      var next = DateTime(now.year, now.month, now.day, time.hour, time.minute);
      if (!next.isAfter(now)) {
        next = next.add(const Duration(days: 1));
      }
      final scheduled = tz.TZDateTime.from(next, tz.local);
      await _plugin.zonedSchedule(
        id,
        title,
        body,
        scheduled,
        const NotificationDetails(
          android: AndroidNotificationDetails(
            _reminderChannelId,
            _reminderChannelName,
            importance: Importance.defaultImportance,
            priority: Priority.defaultPriority,
          ),
          iOS: DarwinNotificationDetails(),
        ),
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: DateTimeComponents.time,
      );
    } catch (e) {
      log.w('LocalReminderService scheduleDaily failed', error: e);
    }
  }

  /// Cancel a scheduled reminder by ID.
  Future<void> cancel(int id) async {
    if (kIsWeb) return;
    try {
      await init();
      if (!_initialized) return;
      await _plugin.cancel(id);
    } catch (e) {
      log.w('LocalReminderService cancel failed', error: e);
    }
  }

  /// Re-apply the reminder prefs: schedule enabled reminders, cancel the rest.
  Future<void> syncFromPrefs() async {
    if (kIsWeb) return;
    try {
      final prefs = await SharedPreferences.getInstance();

      final medsEnabled = prefs.getBool(medsEnabledKey) ?? false;
      final medsTime =
          tryParseTime(prefs.getString(medsTimeKey)) ?? defaultMedsTime;
      if (medsEnabled) {
        await scheduleDaily(
          id: _medsReminderId,
          title: 'Medication reminder',
          body: 'Time to take your medication.',
          time: medsTime,
        );
      } else {
        await cancel(_medsReminderId);
      }

      final readingEnabled = prefs.getBool(readingEnabledKey) ?? false;
      final readingTime =
          tryParseTime(prefs.getString(readingTimeKey)) ?? defaultReadingTime;
      if (readingEnabled) {
        await scheduleDaily(
          id: _readingReminderId,
          title: 'Reading reminder',
          body: 'Time to log your daily health reading.',
          time: readingTime,
        );
      } else {
        await cancel(_readingReminderId);
      }
    } catch (e) {
      log.w('LocalReminderService syncFromPrefs failed', error: e);
    }
  }
}
