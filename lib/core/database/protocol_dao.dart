import 'dart:convert';

import 'package:sqflite/sqflite.dart';
import 'database_helper.dart';

/// Data access object for cached BLE protocol definitions from ERPNext.
class ProtocolDao {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  Future<Database> get _db async => _dbHelper.database;

  /// Insert or replace a protocol JSON blob.
  Future<int> upsert(String protocolName, Map<String, dynamic> json) async {
    final db = await _db;
    return db.insert(
      'ble_protocols',
      {
        'protocol_name': protocolName,
        'json_data': jsonEncode(json),
        'synced_at': DateTime.now().toIso8601String(),
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// Get all cached protocols.
  Future<List<Map<String, dynamic>>> getAll() async {
    final db = await _db;
    final rows = await db.query('ble_protocols', orderBy: 'protocol_name ASC');
    return rows.map((r) {
      final data = jsonDecode(r['json_data'] as String) as Map<String, dynamic>;
      data['_synced_at'] = r['synced_at'];
      return data;
    }).toList();
  }

  /// Get a single protocol by name.
  Future<Map<String, dynamic>?> getByName(String name) async {
    final db = await _db;
    final rows = await db.query(
      'ble_protocols',
      where: 'protocol_name = ?',
      whereArgs: [name],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return jsonDecode(rows.first['json_data'] as String) as Map<String, dynamic>;
  }

  /// Check if cache is older than N hours.
  Future<bool> isStale({int maxAgeHours = 24}) async {
    final db = await _db;
    final result = await db.rawQuery(
      "SELECT MAX(synced_at) as last_sync FROM ble_protocols",
    );
    final lastSyncStr = result.first['last_sync'] as String?;
    if (lastSyncStr == null) return true;

    final lastSync = DateTime.tryParse(lastSyncStr);
    if (lastSync == null) return true;

    return DateTime.now().difference(lastSync).inHours > maxAgeHours;
  }

  /// Count cached protocols.
  Future<int> count() async {
    final db = await _db;
    final result = await db.rawQuery('SELECT COUNT(*) as cnt FROM ble_protocols');
    return (result.first['cnt'] as int?) ?? 0;
  }

  /// Clear all cached protocols.
  Future<void> clear() async {
    final db = await _db;
    await db.delete('ble_protocols');
  }

  /// Batch replace all protocols (used after fetch from server).
  Future<void> replaceAll(List<Map<String, dynamic>> protocols) async {
    final db = await _db;
    await db.transaction((txn) async {
      await txn.delete('ble_protocols');
      for (final p in protocols) {
        final name = p['name'] as String? ?? p['protocol_name'] as String?;
        if (name == null) continue;
        await txn.insert('ble_protocols', {
          'protocol_name': name,
          'json_data': jsonEncode(p),
          'synced_at': DateTime.now().toIso8601String(),
        });
      }
    });
  }
}
