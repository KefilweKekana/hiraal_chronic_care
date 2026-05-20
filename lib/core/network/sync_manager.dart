import '../database/database_helper.dart';
import '../database/readings_dao.dart';
import '../utils/app_logger.dart';
import '../utils/result.dart';
import '../../services/service_locator.dart';

/// Processes the sync queue — pushes pending local readings to the server.
class SyncManager {
  final ReadingsDao _readingsDao = ReadingsDao();
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  /// Attempt to sync all pending readings.
  /// Returns the number of successfully synced items.
  Future<int> syncAll() async {
    final pending = await _readingsDao.getPending();
    if (pending.isEmpty) return 0;

    log.i('Syncing ${pending.length} pending readings...');

    final result = await ServiceLocator.instance.readings.syncPendingReadings(pending);

    return result.dataOrNull ?? 0;
  }

  /// Clear processed items from the sync queue.
  Future<void> clearCompleted() async {
    final db = await _dbHelper.database;
    await db.delete(
      'sync_queue',
      where: 'attempts > 0',
    );
  }

  /// Get count of items waiting to sync.
  Future<int> pendingCount() async {
    return _readingsDao.pendingCount();
  }
}
