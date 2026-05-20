import 'package:workmanager/workmanager.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../core/database/database_helper.dart';
import '../core/database/readings_dao.dart';
import '../core/utils/app_logger.dart';
import '../core/utils/result.dart';
import 'service_locator.dart';

const String _syncTaskName = 'hiraal.chronic_care.background_sync';
const String _syncChannelId = 'hiraal_sync_channel';
const String _syncChannelName = 'Sync Notifications';
const String _syncChannelDesc = 'Notifications for background data sync';

/// Global callback dispatcher for WorkManager.
/// Must be a top-level or static function.
@pragma('vm:entry-point')
void _callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    log.i('Background sync task started: \$task');
    final helper = DatabaseHelper.instance;
    if (!helper.isSupported) {
      log.i('Database not supported on this platform; skipping background sync.');
      return true;
    }

    final readingsDao = ReadingsDao();
    final pending = await readingsDao.getPending();
    if (pending.isEmpty) {
      await _showNotification('Sync complete', 'No pending readings to sync.');
      return true;
    }

    try {
      ServiceLocator.instance.init();
      final result = await ServiceLocator.instance.readings.syncPendingReadings(pending);
      final syncedCount = result.dataOrNull ?? 0;

      if (syncedCount > 0) {
        await _showNotification(
          'Sync complete',
          '\$syncedCount reading(s) synced successfully.',
        );
      } else {
        await _showNotification(
          'Sync failed',
          'Could not sync \${pending.length} pending reading(s). Will retry later.',
        );
      }
      return syncedCount > 0;
    } catch (e, st) {
      log.e('Background sync error', error: e, stackTrace: st);
      await _showNotification('Sync error', 'An error occurred during background sync.');
      return false;
    }
  });
}

Future<void> _showNotification(String title, String body) async {
  final flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();
  const androidDetails = AndroidNotificationDetails(
    _syncChannelId,
    _syncChannelName,
    channelDescription: _syncChannelDesc,
    importance: Importance.low,
    priority: Priority.low,
  );
  const notificationDetails = NotificationDetails(android: androidDetails);
  await flutterLocalNotificationsPlugin.show(
    0,
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
      isInDebugMode: false,
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
