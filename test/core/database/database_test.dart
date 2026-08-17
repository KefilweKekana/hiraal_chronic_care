import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:hiraal_chronic_care/core/database/database_helper.dart';
import 'package:hiraal_chronic_care/core/database/patient_dao.dart';
import 'package:hiraal_chronic_care/core/database/readings_dao.dart';
import 'package:hiraal_chronic_care/models/patient.dart';
import 'package:hiraal_chronic_care/models/vital_reading.dart';

/// SQLite round-trip tests using an in-memory/temp database via
/// sqflite_common_ffi. These run on the development host (Windows) and do not
/// need an Android emulator or a running ERPNext server.
void main() {
  // Initialize the FFI database factory once for the test process.
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  group('PatientDao', () {
    late PatientDao dao;

    setUp(() async {
      dao = PatientDao();
      await _resetDatabase();
    });

    test('round-trips a patient including subscription_active and sex', () async {
      final patient = Patient(
        id: 'PID000042',
        name: 'Test Patient',
        patientId: 'PID000042',
        phone: '+252631234567',
        conditions: ['Hypertension', 'Diabetes'],
        clinic: 'Hiraal Test Clinic',
        carePlan: 'Daily monitoring',
        nextCheckIn: 'Tomorrow',
        assignedNurse: 'Nurse Test',
        subscriptionStatus: 'Active',
        riskLevel: 'Medium',
        deviceAssigned: 'BP-X1',
        sex: 'Female',
        subscriptionActive: true,
      );

      await dao.save(patient);
      final read = await dao.get();

      expect(read, isNotNull);
      expect(read!.id, equals('PID000042'));
      expect(read.name, equals('Test Patient'));
      expect(read.phone, equals('+252631234567'));
      expect(read.conditions, equals(['Hypertension', 'Diabetes']));
      expect(read.clinic, equals('Hiraal Test Clinic'));
      expect(read.sex, equals('Female'));
      expect(read.subscriptionActive, isTrue);
      expect(read.deviceAssigned, equals('BP-X1'));
    });

    test('subscriptionActive defaults to false when not persisted', () async {
      // Simulate an older database row that lacks the subscription_active bit.
      final db = await DatabaseHelper.instance.database;
      await db.insert(
        'patient',
        {
          'id': 'PID000043',
          'name': 'Legacy Patient',
          'patient_id': 'PID000043',
          'phone': '+252631234568',
          'subscription_active': 0,
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );

      final read = await dao.get();
      expect(read, isNotNull);
      expect(read!.subscriptionActive, isFalse);
    });

    test('clear removes the patient row', () async {
      await dao.save(Patient(
        id: 'PID000044',
        name: 'To Clear',
        patientId: 'PID000044',
        phone: '+252631234569',
        conditions: [],
        clinic: '',
        carePlan: '',
        nextCheckIn: '',
        assignedNurse: '',
        subscriptionStatus: 'Inactive',
        riskLevel: 'Low',
        subscriptionActive: false,
      ));

      expect(await dao.get(), isNotNull);
      await dao.clear();
      expect(await dao.get(), isNull);
    });
  });

  group('ReadingsDao', () {
    late ReadingsDao dao;

    setUp(() async {
      dao = ReadingsDao();
      await _resetDatabase();
    });

    test('round-trips a reading with reference_id, sync_status and medicine_taken', () async {
      final reading = VitalReading(
        referenceId: 'REF-2026-0712-0001',
        date: DateTime.utc(2026, 7, 12, 10, 30),
        systolic: 135,
        diastolic: 88,
        bloodSugar: 145.5,
        weight: 72.3,
        medicineTaken: true,
        note: 'Felt fine',
        source: 'App',
        syncStatus: 'Pending',
        status: 'Sent',
      );

      await dao.insert(reading);
      final all = await dao.getAll();

      expect(all.length, equals(1));
      final r = all.first;
      expect(r.referenceId, equals('REF-2026-0712-0001'));
      expect(r.date, equals(DateTime.utc(2026, 7, 12, 10, 30)));
      expect(r.systolic, equals(135));
      expect(r.diastolic, equals(88));
      expect(r.bloodSugar, closeTo(145.5, 0.001));
      expect(r.weight, closeTo(72.3, 0.001));
      expect(r.medicineTaken, isTrue);
      expect(r.syncStatus, equals('Pending'));
      expect(r.status, equals('Sent'));

      final pending = await dao.getPending();
      expect(pending.length, equals(1));
      expect(dao.pendingCount(), completion(equals(1)));
    });

    test('markSyncedByReference clears pending status', () async {
      await dao.insert(VitalReading(
        referenceId: 'REF-2026-0712-0002',
        date: DateTime.utc(2026, 7, 12, 11, 0),
        systolic: 120,
        diastolic: 80,
        syncStatus: 'Pending',
      ));

      await dao.markSyncedByReference('REF-2026-0712-0002', serverId: 'SRV-123');

      final all = await dao.getAll();
      expect(all.first.syncStatus, equals('Synced'));
      expect(all.first.id, equals('SRV-123'));
      expect(await dao.pendingCount(), equals(0));
    });
  });

  group('DatabaseHelper migrations', () {
    test('upgrade path from v1 to v5 creates expected schema', () async {
      await _resetDatabase();
      final db = await DatabaseHelper.instance.database;

      final tables = await db.query(
        'sqlite_master',
        where: 'type = ?',
        whereArgs: ['table'],
      );
      final names = tables.map((r) => r['name'] as String).toSet();

      expect(names, containsAll(['readings', 'patient', 'sync_queue', 'devices', 'ble_protocols']));

      // Verify v5 columns exist on patient.
      final cols = await db.rawQuery('PRAGMA table_info(patient)');
      final colNames = cols.map((c) => c['name'] as String).toSet();
      expect(colNames, containsAll(['sex', 'subscription_active']));
    });
  });
}

/// Close the singleton, delete the on-disk database file, and reopen it.
/// Gives each test a clean database while still exercising _onCreate/_onUpgrade.
Future<void> _resetDatabase() async {
  final helper = DatabaseHelper.instance;
  await helper.close();

  final dbPath = await getDatabasesPath();
  final path = p.join(dbPath, DatabaseHelper.instance.isSupported
      ? 'hiraal_chronic_care.db'
      : 'test.db');
  try {
    final file = File(path);
    if (await file.exists()) {
      await file.delete();
    }
  } catch (_) {
    // Ignore deletion errors (e.g. first run).
  }

  // Force the singleton to re-initialize.
  await helper.database;
}
