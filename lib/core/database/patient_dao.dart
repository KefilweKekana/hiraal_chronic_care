import 'package:sqflite/sqflite.dart';
import '../../models/patient.dart';
import '../database/database_helper.dart';

/// Data Access Object for local patient storage.
/// On web, all methods are safe no-ops.
class PatientDao {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  bool get _supported => _dbHelper.isSupported;

  /// Save or update the logged-in patient.
  Future<void> save(Patient patient) async {
    if (!_supported) return;
    final db = await _dbHelper.database;
    await db.insert(
      'patient',
      _toRow(patient),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// Get the stored patient (null if not logged in / cleared).
  Future<Patient?> get() async {
    if (!_supported) return null;
    final db = await _dbHelper.database;
    final rows = await db.query('patient', limit: 1);
    if (rows.isEmpty) return null;
    return _fromRow(rows.first);
  }

  /// Clear patient data (on logout).
  Future<void> clear() async {
    if (!_supported) return;
    final db = await _dbHelper.database;
    await db.delete('patient');
  }

  // ── Mapping helpers ───────────────────────────────────

  Map<String, dynamic> _toRow(Patient p) => {
        'id': p.id,
        'name': p.name,
        'patient_id': p.patientId,
        'phone': p.phone,
        'photo_url': p.photoUrl,
        'conditions': p.conditions.join(','),
        'clinic': p.clinic,
        'care_plan': p.carePlan,
        'next_check_in': p.nextCheckIn,
        'assigned_nurse': p.assignedNurse,
        'subscription_status': p.subscriptionStatus,
        'risk_level': p.riskLevel,
        'device_assigned': p.deviceAssigned,
        'updated_at': DateTime.now().toIso8601String(),
      };

  Patient _fromRow(Map<String, dynamic> row) => Patient(
        id: row['id'] as String,
        name: row['name'] as String,
        patientId: row['patient_id'] as String,
        phone: row['phone'] as String,
        photoUrl: row['photo_url'] as String?,
        conditions: (row['conditions'] as String?)?.split(',').where((s) => s.isNotEmpty).toList() ?? [],
        clinic: (row['clinic'] as String?) ?? '',
        carePlan: (row['care_plan'] as String?) ?? '',
        nextCheckIn: (row['next_check_in'] as String?) ?? '',
        assignedNurse: (row['assigned_nurse'] as String?) ?? '',
        subscriptionStatus: (row['subscription_status'] as String?) ?? 'Active',
        riskLevel: (row['risk_level'] as String?) ?? 'Low',
        deviceAssigned: row['device_assigned'] as String?,
      );
}
