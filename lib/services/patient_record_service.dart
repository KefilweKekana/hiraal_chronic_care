import '../core/utils/result.dart';

class MedicalRecord {
  final String id;
  final String date;
  final String title;
  final String subtitle;
  final String type; // diagnosis, enrollment, checkup, procedure

  MedicalRecord({
    required this.id,
    required this.date,
    required this.title,
    required this.subtitle,
    required this.type,
  });

  factory MedicalRecord.fromJson(Map<String, dynamic> json) => MedicalRecord(
    id: json['name'] ?? '',
    date: json['encounter_date'] ?? json['date'] ?? '',
    title: json['title'] ?? json['encounter_type'] ?? '',
    subtitle: json['description'] ?? '',
    type: json['type'] ?? 'checkup',
  );
}

/// Fetches patient medical history / encounters from ERPNext.
abstract class PatientRecordService {
  Future<Result<List<MedicalRecord>>> getRecords(String patientId);
}
