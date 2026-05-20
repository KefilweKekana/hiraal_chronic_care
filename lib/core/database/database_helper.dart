import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../utils/app_logger.dart';

/// Singleton database helper. Manages SQLite lifecycle and migrations.
/// On web, database operations are no-ops (falls back to in-memory via provider).
class DatabaseHelper {
  DatabaseHelper._();
  static final DatabaseHelper instance = DatabaseHelper._();

  static const _dbName = 'hiraal_chronic_care.db';
  static const _dbVersion = 4;

  Database? _database;

  /// True when running on a platform that supports sqflite.
  bool get isSupported => !kIsWeb;

  Future<Database> get database async {
    if (kIsWeb) throw UnsupportedError('sqflite is not supported on web');
    _database ??= await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, _dbName);
    log.i('Opening database at $path');
    return openDatabase(
      path,
      version: _dbVersion,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE readings (
        local_id INTEGER PRIMARY KEY AUTOINCREMENT,
        server_id TEXT,
        reference_id TEXT,
        date TEXT NOT NULL,
        systolic INTEGER,
        diastolic INTEGER,
        blood_sugar REAL,
        weight REAL,
        medicine_taken INTEGER,
        note TEXT,
        source TEXT NOT NULL DEFAULT 'App',
        sync_status TEXT NOT NULL DEFAULT 'Pending',
        status TEXT,
        created_at TEXT NOT NULL DEFAULT (datetime('now')),
        updated_at TEXT NOT NULL DEFAULT (datetime('now'))
      )
    ''');

    await db.execute('''
      CREATE TABLE patient (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        patient_id TEXT NOT NULL,
        phone TEXT NOT NULL,
        photo_url TEXT,
        conditions TEXT,
        clinic TEXT,
        care_plan TEXT,
        next_check_in TEXT,
        assigned_nurse TEXT,
        subscription_status TEXT,
        risk_level TEXT,
        device_assigned TEXT,
        updated_at TEXT NOT NULL DEFAULT (datetime('now'))
      )
    ''');

    await db.execute('''
      CREATE TABLE sync_queue (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        table_name TEXT NOT NULL,
        record_id INTEGER NOT NULL,
        action TEXT NOT NULL DEFAULT 'create',
        attempts INTEGER NOT NULL DEFAULT 0,
        last_attempt TEXT,
        created_at TEXT NOT NULL DEFAULT (datetime('now'))
      )
    ''');

    await db.execute('''
      CREATE TABLE devices (
        local_id INTEGER PRIMARY KEY AUTOINCREMENT,
        device_id TEXT NOT NULL UNIQUE,
        device_name TEXT NOT NULL,
        device_type TEXT NOT NULL,
        manufacturer TEXT,
        model TEXT,
        serial_number TEXT,
        patient_id TEXT,
        status TEXT NOT NULL DEFAULT 'Unassigned',
        battery_level INTEGER,
        last_sync TEXT,
        created_at TEXT NOT NULL DEFAULT (datetime('now')),
        updated_at TEXT NOT NULL DEFAULT (datetime('now'))
      )
    ''');

    await db.execute(
        'CREATE INDEX idx_readings_sync ON readings(sync_status)');
    await db.execute(
        'CREATE INDEX idx_readings_date ON readings(date DESC)');
    await db.execute(
        'CREATE INDEX idx_sync_queue_status ON sync_queue(attempts)');
    await db.execute(
        'CREATE INDEX idx_devices_patient ON devices(patient_id)');

    await db.execute('''
      CREATE TABLE ble_protocols (
        protocol_name TEXT PRIMARY KEY,
        json_data TEXT NOT NULL,
        synced_at TEXT NOT NULL DEFAULT (datetime('now'))
      )
    ''');

    log.i('Database tables created (v$version)');
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    log.i('Database upgrade from v$oldVersion to v$newVersion');
    if (oldVersion < 2) {
      await db.execute('ALTER TABLE readings ADD COLUMN weight REAL');
    }
    if (oldVersion < 3) {
      await db.execute('''
        CREATE TABLE devices (
          local_id INTEGER PRIMARY KEY AUTOINCREMENT,
          device_id TEXT NOT NULL UNIQUE,
          device_name TEXT NOT NULL,
          device_type TEXT NOT NULL,
          manufacturer TEXT,
          model TEXT,
          serial_number TEXT,
          patient_id TEXT,
          status TEXT NOT NULL DEFAULT 'Unassigned',
          battery_level INTEGER,
          last_sync TEXT,
          created_at TEXT NOT NULL DEFAULT (datetime('now')),
          updated_at TEXT NOT NULL DEFAULT (datetime('now'))
        )
      ''');
      await db.execute(
          'CREATE INDEX idx_devices_patient ON devices(patient_id)');
    }
    if (oldVersion < 4) {
      await db.execute('''
        CREATE TABLE ble_protocols (
          protocol_name TEXT PRIMARY KEY,
          json_data TEXT NOT NULL,
          synced_at TEXT NOT NULL DEFAULT (datetime('now'))
        )
      ''');
    }
  }

  /// Delete all data (for logout).
  Future<void> clearAll() async {
    if (!isSupported) return;
    final db = await database;
    await db.delete('readings');
    await db.delete('patient');
    await db.delete('sync_queue');
    await db.delete('devices');
    await db.delete('ble_protocols');
    log.i('All local data cleared');
  }

  /// Close the database connection.
  Future<void> close() async {
    if (!isSupported) return;
    final db = _database;
    if (db != null && db.isOpen) {
      await db.close();
      _database = null;
    }
  }
}
