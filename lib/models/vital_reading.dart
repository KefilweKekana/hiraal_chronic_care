class VitalReading {
  final String? id;
  final String? referenceId;
  final DateTime date;
  final int? systolic;
  final int? diastolic;
  final double? bloodSugar;
  final double? weight;
  final bool? medicineTaken;
  final String? note;
  final String source;
  final String syncStatus;
  final String? status;

  VitalReading({
    this.id,
    this.referenceId,
    required this.date,
    this.systolic,
    this.diastolic,
    this.bloodSugar,
    this.weight,
    this.medicineTaken,
    this.note,
    this.source = 'App',
    this.syncStatus = 'Synced',
    this.status,
  });

  String get bpString {
    if (systolic == null || diastolic == null) return '--/--';
    return '$systolic/$diastolic';
  }

  String get sugarString {
    if (bloodSugar == null) return '--';
    return bloodSugar!.toStringAsFixed(0);
  }

  String get bpStatus {
    if (systolic == null) return 'Normal';
    if (systolic! >= 180 || (diastolic ?? 0) >= 120) return 'Very High';
    if (systolic! >= 160 || (diastolic ?? 0) >= 100) return 'High';
    if (systolic! >= 140 || (diastolic ?? 0) >= 90) return 'Medium';
    return 'Normal';
  }

  String get sugarStatus {
    if (bloodSugar == null) return 'Normal';
    if (bloodSugar! >= 300) return 'Very High';
    if (bloodSugar! >= 250) return 'High';
    if (bloodSugar! >= 200) return 'Medium';
    return 'Normal';
  }

  factory VitalReading.fromJson(Map<String, dynamic> json) => VitalReading(
    id: json['name'],
    referenceId: json['reference_id'],
    date: DateTime.parse(json['date'] ?? DateTime.now().toIso8601String()),
    systolic: json['systolic'],
    diastolic: json['diastolic'],
    bloodSugar: json['blood_sugar']?.toDouble(),
    weight: json['weight']?.toDouble(),
    medicineTaken: json['medicine_taken'] == 1,
    note: json['note'],
    source: json['source'] ?? 'App',
    syncStatus: json['sync_status'] ?? 'Synced',
    status: json['status'],
  );

  Map<String, dynamic> toJson() => {
    'date': date.toIso8601String(),
    'systolic': systolic,
    'diastolic': diastolic,
    'blood_sugar': bloodSugar,
    'weight': weight,
    'medicine_taken': medicineTaken == true ? 1 : 0,
    'note': note,
    'source': source,
  };

  static List<VitalReading> mockReadings() => [
    VitalReading(
      referenceId: 'SUB-2024-0520-0941',
      date: DateTime.now(),
      systolic: 128,
      diastolic: 82,
      bloodSugar: 145,
      weight: 72.5,
      medicineTaken: true,
      note: 'Slight headache in the morning, feeling better now.',
      status: 'Sent',
    ),
    VitalReading(
      referenceId: 'SUB-2024-0519-0815',
      date: DateTime.now().subtract(const Duration(days: 1)),
      systolic: 121,
      diastolic: 79,
      bloodSugar: 138,
      weight: 71.0,
      medicineTaken: true,
      status: 'Sent',
    ),
    VitalReading(
      referenceId: 'SUB-2024-0518-0905',
      date: DateTime.now().subtract(const Duration(days: 2)),
      systolic: 130,
      diastolic: 81,
      bloodSugar: 152,
      weight: 73.0,
      medicineTaken: true,
      status: 'Sent',
    ),
    VitalReading(
      referenceId: 'SUB-2024-0517-0730',
      date: DateTime.now().subtract(const Duration(days: 3)),
      systolic: null,
      diastolic: null,
      bloodSugar: null,
      medicineTaken: false,
      status: 'Pending',
    ),
    VitalReading(
      referenceId: 'SUB-2024-0516-0800',
      date: DateTime.now().subtract(const Duration(days: 4)),
      systolic: 115,
      diastolic: 76,
      bloodSugar: 130,
      weight: 71.5,
      medicineTaken: true,
      status: 'Sent',
    ),
  ];
}
