import 'package:shared_preferences/shared_preferences.dart';
import 'package:workmanager/workmanager.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../core/database/database_helper.dart';
import '../core/database/readings_dao.dart';
import '../core/utils/app_logger.dart';
import '../core/utils/result.dart';
import 'service_locator.dart';

const String _syncTaskName = 'hiraal.chronic_care.background_sync';
const String _syncChannelId = 'hiraal_sync_background';
const String _syncChannelName = 'Background sync';
const String _syncChannelDesc =
    'Low-priority sync status. Disable this channel to keep health alerts on.';
const String _lastFailSignatureKey = 'hiraal_sync_last_fail_signature';
const int _syncFailNotificationId = 1002;
const int _syncSuccessNotificationId = 1001;

/// Global callback dispatcher for WorkManager.
/// Must be a top-level or static function.
@pragma('vm:entry-point')
void _callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    log.i('Background sync task started: $task');
    final helper = DatabaseHelper.instance;
    if (!helper.isSupported) {
      log.i('Database not supported on this platform; skipping background sync.');
      return true;
    }

    final readingsDao = ReadingsDao();
    final pending = await readingsDao.getPending();
    if (pending.isEmpty) {
      // Silent success: never notify when nothing is pending.
      log.i('Background sync: nothing pending; skipping notification.');
      return true;
    }

    try {
      ServiceLocator.instance.init();
      final result = await ServiceLocator.instance.readings.syncPendingReadings(pending);
      final syncedCount = result.dataOrNull ?? 0;

      if (syncedCount > 0) {
        await _showNotification(
          id: _syncSuccessNotificationId,
          title: 'Readings synced',
          body: '$syncedCount reading(s) saved to your care record.',
        );
      } else {
        final signature =
            'fail:${pending.length}:${pending.first.id}:${pending.last.id}';
        if (await _alreadyNotified(signature)) {
          log.i('Background sync failed but notification already shown; not repeating.');
        } else {
          await _showNotification(
            id: _syncFailNotificationId,
            title: 'Sync failed',
            body:
                'Could not sync ${pending.length} pending reading(s). Will retry later.',
          );
          await _rememberSignature(signature);
        }
      }
      return syncedCount > 0;
    } catch (e, st) {
      log.e('Background sync error', error: e, stackTrace: st);
      final signature = 'error:${pending.length}';
      if (!await _alreadyNotified(signature)) {
        await _showNotification(
          id: _syncFailNotificationId,
          title: 'Sync error',
          body: 'An error occurred while saving your readings. Will retry later.',
        );
        await _rememberSignature(signature);
      }
      return false;
    }
  });
}

Future<bool> _alreadyNotified(String signature) async {
  try {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_lastFailSignatureKey) == signature;
  } catch (_) {
    return false;
  }
}

Future<void> _rememberSignature(String signature) async {
  try {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_lastFailSignatureKey, signature);
  } catch (_) {}
}

Future<void> _showNotification({
  required int id,
  required String title,
  required String body,
}) async {
  final flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();
  // This runs in the WorkManager background isolate, which never initializes
  // the plugin — Android 8+ silently drops notifications shown without an
  // initialized plugin and an existing channel.
  const initSettings = InitializationSettings(
    android: AndroidInitializationSettings('@mipmap/ic_launcher'),
  );
  await flutterLocalNotificationsPlugin.initialize(initSettings);
  const channel = AndroidNotificationChannel(
    _syncChannelId,
    _syncChannelName,
    description: _syncChannelDesc,
    importance: Importance.min,
    playSound: false,
    enableVibration: false,
    showBadge: false,
  );
  final androidPlugin = flutterLocalNotificationsPlugin
      .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
  await androidPlugin?.createNotificationChannel(channel);
  const androidDetails = AndroidNotificationDetails(
    _syncChannelId,
    _syncChannelName,
    channelDescription: _syncChannelDesc,
    importance: Importance.min,
    priority: Priority.min,
    playSound: false,
    enableVibration: false,
    channelShowBadge: false,
  );
  const notificationDetails = NotificationDetails(android: androidDetails);
  await flutterLocalNotificationsPlugin.show(
    id,
    title,
    body,
    notificationDetails,
  );
}

/// Initializes and manages background periodic sync using [WorkManager].
class BackgroundSyncService {
  BackgroundSyncService._();
  static final BackgroundSyncService instance = BackgroundSyncService._();

  bool _initialized = false;

  /// Initialize the WorkManager callback dispatcher.
  Future<void> initialize() async {
    if (_initialized) return;
    await Workmanager().initialize(
      _callbackDispatcher,
    );
    _initialized = true;
    log.i('WorkManager initialized');
  }

  /// Register a periodic sync task that runs every 15 minutes.
  Future<void> registerPeriodicSync() async {
    if (!_initialized) await initialize();
    await Workmanager().registerPeriodicTask(
      _syncTaskName,
      _syncTaskName,
      frequency: const Duration(minutes: 15),
      constraints: Constraints(
        networkType: NetworkType.connected,
        requiresBatteryNotLow: true,
      ),
      existingWorkPolicy: ExistingPeriodicWorkPolicy.keep,
    );
    log.i('Periodic sync registered (15 min)');
  }

  /// Cancel the periodic sync task.
  Future<void> cancelPeriodicSync() async {
    await Workmanager().cancelByUniqueName(_syncTaskName);
    log.i('Periodic sync cancelled');
  }
}
