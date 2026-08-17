/// A telemedicine (video) visit for the patient, mirroring the server
/// "Telemedicine Session" doctype. Carries the join URL for live calling.
class TelemedicineSession {
  final String id;
  final String? appointment;
  final String? practitioner;
  final String? practitionerName;
  final String status; // Scheduled / In Progress / Completed / Cancelled
  final DateTime? startTime;
  final DateTime? endTime;
  final String? meetingUrl;
  final int? durationMinutes;
  final String? notes;

  const TelemedicineSession({
    required this.id,
    this.appointment,
    this.practitioner,
    this.practitionerName,
    this.status = 'Scheduled',
    this.startTime,
    this.endTime,
    this.meetingUrl,
    this.durationMinutes,
    this.notes,
  });

  /// True when the patient can join: there's a link and the call isn't over.
  bool get isJoinable =>
      (meetingUrl?.isNotEmpty ?? false) &&
      status != 'Completed' &&
      status != 'Cancelled';

  bool get isCompleted => status == 'Completed';
  bool get isCancelled => status == 'Cancelled';

  String get doctorLabel =>
      (practitionerName?.isNotEmpty ?? false) ? practitionerName! : (practitioner ?? 'Your doctor');

  static DateTime? _dt(Object? v) => v == null ? null : DateTime.tryParse(v.toString());

  factory TelemedicineSession.fromJson(Map<String, dynamic> j) => TelemedicineSession(
        id: (j['name'] ?? '').toString(),
        appointment: (j['appointment'] as Object?)?.toString(),
        practitioner: (j['practitioner'] as Object?)?.toString(),
        practitionerName: (j['practitioner_name'] as Object?)?.toString(),
        status: (j['session_status'] ?? 'Scheduled').toString(),
        startTime: _dt(j['start_time']),
        endTime: _dt(j['end_time']),
        meetingUrl: (j['meeting_url'] as Object?)?.toString(),
        durationMinutes: int.tryParse('${j['duration_minutes'] ?? ''}'),
        notes: (j['notes'] as Object?)?.toString(),
      );
}
