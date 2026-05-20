import 'package:sqflite/sqflite.dart';
import '../../models/device.dart';
import 'database_helper.dart';

/// Data access object for paired medical devices.
class DeviceDao {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  Future<Database> get _db async => _dbHelper.database;

  /// Insert a new device. Returns the local row id.
  Future<int> insert(DeviceModel device) async {
    final db = await _db;
    return db.insert('devices', device.toMap()..remove('local_id'));
  }

  /// Update an existing device by local_id.
  Future<int> update(DeviceModel device) async {
    final db = await _db;
    return db.update(
      'devices',
      device.toMap(),
      where: 'local_id = ?',
      whereArgs: [device.localId],
    );
  }

  /// Delete a device by local_id.
  Future<int> delete(int localId) async {
    final db = await _db;
    return db.delete('devices', where: 'local_id = ?', whereArgs: [localId]);
  }

  /// Get all paired devices, ordered by most recently updated.
  Future<List<DeviceModel>> getAll() async {
    final db = await _db;
    final maps = await db.query('devices', orderBy: 'updated_at DESC');
    return maps.map((m) => DeviceModel.fromMap(m)).toList();
  }

  /// Get a device by its local id.
  Future<DeviceModel?> getByLocalId(int localId) async {
    final db = await _db;
    final maps = await db.query(
      'devices',
      where: 'local_id = ?',
      whereArgs: [localId],
      limit: 1,
    );
    if (maps.isEmpty) return null;
    return DeviceModel.fromMap(maps.first);
  }

  /// Get a device by its BLE device id (e.g. MAC address or remoteId).
  Future<DeviceModel?> getByDeviceId(String deviceId) async {
    final db = await _db;
    final maps = await db.query(
      'devices',
      where: 'device_id = ?',
      whereArgs: [deviceId],
      limit: 1,
    );
    if (maps.isEmpty) return null;
    return DeviceModel.fromMap(maps.first);
  }

  /// Get devices filtered by patient id.
  Future<List<DeviceModel>> getByPatient(String patientId) async {
    final db = await _db;
    final maps = await db.query(
      'devices',
      where: 'patient_id = ?',
      whereArgs: [patientId],
      orderBy: 'updated_at DESC',
    );
    return maps.map((m) => DeviceModel.fromMap(m)).toList();
  }

  /// Update the status and lastSync of a device.
  Future<int> updateSyncStatus(String deviceId, String status, DateTime lastSync) async {
    final db = await _db;
    return db.update(
      'devices',
      {
        'status': status,
        'last_sync': lastSync.toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      },
      where: 'device_id = ?',
      whereArgs: [deviceId],
    );
  }

  /// Count total devices.
  Future<int> count() async {
    final db = await _db;
    final result = await db.rawQuery('SELECT COUNT(*) as count FROM devices');
    return (result.first['count'] as int?) ?? 0;
  }

  /// Delete all devices (e.g. on logout).
  Future<void> deleteAll() async {
    final db = await _db;
    await db.delete('devices');
  }
}
