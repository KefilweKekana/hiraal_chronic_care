/// Represents a paired medical device in the local SQLite database.
class DeviceModel {
  final int? localId;
  final String deviceId;
  final String deviceName;
  final String deviceType;
  final String? manufacturer;
  final String? model;
  final String? serialNumber;
  final String? patientId;
  final String status; // Online, Offline, Low Battery, Unassigned
  final int? batteryLevel;
  final DateTime? lastSync;
  final DateTime createdAt;
  final DateTime updatedAt;

  DeviceModel({
    this.localId,
    required this.deviceId,
    required this.deviceName,
    required this.deviceType,
    this.manufacturer,
    this.model,
    this.serialNumber,
    this.patientId,
    this.status = 'Unassigned',
    this.batteryLevel,
    this.lastSync,
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'local_id': localId,
      'device_id': deviceId,
      'device_name': deviceName,
      'device_type': deviceType,
      'manufacturer': manufacturer,
      'model': model,
      'serial_number': serialNumber,
      'patient_id': patientId,
      'status': status,
      'battery_level': batteryLevel,
      'last_sync': lastSync?.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  factory DeviceModel.fromMap(Map<String, dynamic> map) {
    return DeviceModel(
      localId: map['local_id'] as int?,
      deviceId: map['device_id'] as String,
      deviceName: map['device_name'] as String,
      deviceType: map['device_type'] as String,
      manufacturer: map['manufacturer'] as String?,
      model: map['model'] as String?,
      serialNumber: map['serial_number'] as String?,
      patientId: map['patient_id'] as String?,
      status: map['status'] as String? ?? 'Unassigned',
      batteryLevel: map['battery_level'] as int?,
      lastSync: map['last_sync'] != null
          ? DateTime.tryParse(map['last_sync'] as String)
          : null,
      createdAt: DateTime.tryParse(map['created_at'] as String) ?? DateTime.now(),
      updatedAt: DateTime.tryParse(map['updated_at'] as String) ?? DateTime.now(),
    );
  }

  DeviceModel copyWith({
    int? localId,
    String? deviceId,
    String? deviceName,
    String? deviceType,
    String? manufacturer,
    String? model,
    String? serialNumber,
    String? patientId,
    String? status,
    int? batteryLevel,
    DateTime? lastSync,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return DeviceModel(
      localId: localId ?? this.localId,
      deviceId: deviceId ?? this.deviceId,
      deviceName: deviceName ?? this.deviceName,
      deviceType: deviceType ?? this.deviceType,
      manufacturer: manufacturer ?? this.manufacturer,
      model: model ?? this.model,
      serialNumber: serialNumber ?? this.serialNumber,
      patientId: patientId ?? this.patientId,
      status: status ?? this.status,
      batteryLevel: batteryLevel ?? this.batteryLevel,
      lastSync: lastSync ?? this.lastSync,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  String toString() {
    return 'DeviceModel(id: $deviceId, name: $deviceName, type: $deviceType, status: $status)';
  }
}
