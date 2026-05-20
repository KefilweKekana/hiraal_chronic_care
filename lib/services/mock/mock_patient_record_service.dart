import '../../core/utils/result.dart';
import '../patient_record_service.dart';

class MockPatientRecordService implements PatientRecordService {
  @override
  Future<Result<List<MedicalRecord>>> getRecords(String patientId) async {
    await Future.delayed(const Duration(milliseconds: 300));
    return Success([
      MedicalRecord(
        id: 'ENC-001',
        date: 'May 2024',
        title: 'Enrolled in Hypertension Care',
        subtitle: 'Hiraal Health Center — Started daily monitoring program',
        type: 'enrollment',
      ),
      MedicalRecord(
        id: 'ENC-002',
        date: 'Apr 2024',
        title: 'Diagnosed with Hypertension',
        subtitle: 'Stage 2 — BP 160/100 mmHg. Started Amlodipine 5mg',
        type: 'diagnosis',
      ),
      MedicalRecord(
        id: 'ENC-003',
        date: 'Mar 2024',
        title: 'Diabetes Type 2 Diagnosis',
        subtitle: 'Fasting blood sugar 210 mg/dL. Started Metformin 500mg',
        type: 'diagnosis',
      ),
      MedicalRecord(
        id: 'ENC-004',
        date: 'Jan 2024',
        title: 'General Health Check-up',
        subtitle: 'Annual screening — cholesterol, CBC, kidney function all within normal range',
        type: 'checkup',
      ),
      MedicalRecord(
        id: 'ENC-005',
        date: 'Nov 2023',
        title: 'Flu Vaccination',
        subtitle: 'Seasonal influenza vaccine administered',
        type: 'procedure',
      ),
    ]);
  }
}
