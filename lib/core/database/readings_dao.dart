import 'package:sqflite/sqflite.dart';
import '../../models/vital_reading.dart';
import '../database/database_helper.dart';

/// Data Access Object for local vital readings storage.
/// On web, all methods are safe no-ops returning empty/zero.
class ReadingsDao {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  bool get _supported => _dbHelper.isSupported;

  /// Insert a reading locally. Returns the local_id (0 on web).
  Future<int> insert(VitalReading reading) async {
    if (!_supported) return 0;
    final db = await _dbHelper.database;
    final localId = await db.insert('readings', _toRow(reading));
    await db.insert('sync_queue', {
      'table_name': 'readings',
      'record_id': localId,
      'action': 'create',
    });
    return localId;
  }

  /// Get all readings, newest first.
  Future<List<VitalReading>> getAll({int? limit}) async {
    if (!_supported) return [];
    final db = await _dbHelper.database;
    final rows = await db.query(
      'readings',
      orderBy: 'date DESC',
      limit: limit,
    );
    return rows.map(_fromRow).toList();
  }

  /// Get readings that haven't been synced yet.
  Future<List<VitalReading>> getPending() async {
    if (!_supported) return [];
    final db = await _dbHelper.database;
    final rows = await db.query(
      'readings',
      where: 'sync_status = ?',
      whereArgs: ['Pending'],
      orderBy: 'date ASC',
    );
    return rows.map(_fromRow).toList();
  }

  /// Count of unsynced readings.
  Future<int> pendingCount() async {
    if (!_supported) return 0;
    final db = await _dbHelper.database;
    final result = await db.rawQuery(
      "SELECT COUNT(*) as cnt FROM readings WHERE sync_status = 'Pending'",
    );
    return Sqflite.firstIntValue(result) ?? 0;
  }

  /// Mark a reading as synced.
  Future<void> markSynced(int localId, {String? serverId}) async {
    if (!_supported) return;
    final db = await _dbHelper.database;
    await db.update(
      'readings',
      {
        'sync_status': 'Synced',
        'status': 'Sent',
        if (serverId != null) 'server_id': serverId,
        'updated_at': DateTime.now().toIso8601String(),
      },
      where: 'local_id = ?',
      whereArgs: [localId],
    );
  }

  /// Mark a batch of readings as synced by their local IDs.
  Future<void> markBatchSynced(List<int> localIds) async {
    if (!_supported) return;
    final db = await _dbHelper.database;
    await db.transaction((txn) async {
      for (final id in localIds) {
        await txn.update(
          'readings',
          {
            'sync_status': 'Synced',
            'status': 'Sent',
            'updated_at': DateTime.now().toIso8601String(),
          },
          where: 'local_id = ?',
          whereArgs: [id],
        );
      }
    });
  }

  /// Seed the database with mock readings (for first run / demo).
  Future<void> seedIfEmpty() async {
    if (!_supported) return;
    final db = await _dbHelper.database;
    final count = Sqflite.firstIntValue(
      await db.rawQuery('SELECT COUNT(*) FROM readings'),
    );
    if (count == 0) {
      final batch = db.batch();
      for (final r in VitalReading.mockReadings()) {
        batch.insert('readings', {
          ..._toRow(r),
          'sync_status': 'Synced',
          'status': 'Sent',
        });
      }
      await batch.commit(noResult: true);
    }
  }

  // ── Mapping helpers ───────────────────────────────────

  Map<String, dynamic> _toRow(VitalReading r) => {
        if (r.id != null) 'server_id': r.id,
        'reference_id': r.referenceId,
        'date': r.date.toIso8601String(),
        'systolic': r.systolic,
        'diastolic': r.diastolic,
        'blood_sugar': r.bloodSugar,
        'weight': r.weight,
        'medicine_taken': r.medicineTaken == true ? 1 : (r.medicineTaken == false ? 0 : null),
        'note': r.note,
        'source': r.source,
        'sync_status': r.syncStatus,
        'status': r.status,
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      };

  VitalReading _fromRow(Map<String, dynamic> row) => VitalReading(
        id: row['server_id'] as String?,
        referenceId: row['reference_id'] as String?,
        date: DateTime.parse(row['date'] as String),
        systolic: row['systolic'] as int?,
        diastolic: row['diastolic'] as int?,
        bloodSugar: (row['blood_sugar'] as num?)?.toDouble(),
        weight: (row['weight'] as num?)?.toDouble(),
        medicineTaken: row['medicine_taken'] == null
            ? null
            : row['medicine_taken'] == 1,
        note: row['note'] as String?,
        source: (row['source'] as String?) ?? 'App',
        syncStatus: (row['sync_status'] as String?) ?? 'Synced',
        status: row['status'] as String?,
      );
}
