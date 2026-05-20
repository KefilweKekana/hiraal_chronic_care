import 'package:flutter_blue_plus/flutter_blue_plus.dart' as fbp;

/// Represents a known BLE protocol for a medical device family.
class BleDeviceProtocol {
  /// Manufacturer or device family name (e.g. "Omron", "A&D", "Generic BP")
  final String name;

  /// Device types this protocol handles.
  final List<String> deviceTypes;

  /// GATT Service UUIDs this protocol uses.
  final List<fbp.Guid> serviceUuids;

  /// Characteristic UUIDs for reading measurements.
  final List<CharacteristicSpec> measurementChars;

  /// Characteristic UUIDs for control/init (e.g. RACP).
  final List<CharacteristicSpec>? controlChars;

  /// How the characteristic delivers data.
  final DeliveryMode deliveryMode;

  /// Parser function for raw BLE bytes → structured reading.
  final BleReadingParser parser;

  /// Optional initialization sequence to run after connection.
  final List<InitStep>? initSequence;

  /// Heuristic keywords in device advertisement name.
  final List<String> nameKeywords;

  BleDeviceProtocol({
    required this.name,
    required this.deviceTypes,
    required this.serviceUuids,
    required this.measurementChars,
    this.controlChars,
    this.deliveryMode = DeliveryMode.notify,
    required this.parser,
    this.initSequence,
    this.nameKeywords = const [],
  });

  /// Build from a JSON map (e.g. from ERPNext API).
  factory BleDeviceProtocol.fromJson(Map<String, dynamic> json, BleReadingParser parserFn) {
    return BleDeviceProtocol(
      name: json['name'] as String,
      deviceTypes: (json['device_types'] as List).cast<String>(),
      serviceUuids: (json['service_uuids'] as List)
          .map((u) => fbp.Guid(u as String))
          .toList(),
      measurementChars: (json['measurement_chars'] as List)
          .map((c) => CharacteristicSpec.fromJson(c as Map<String, dynamic>))
          .toList(),
      controlChars: json['control_chars'] != null
          ? (json['control_chars'] as List)
              .map((c) => CharacteristicSpec.fromJson(c as Map<String, dynamic>))
              .toList()
          : null,
      deliveryMode: _parseDeliveryMode(json['delivery_mode'] as String),
      parser: parserFn,
      initSequence: json['init_sequence'] != null
          ? (json['init_sequence'] as List)
              .map((s) => InitStep.fromJson(s as Map<String, dynamic>))
              .toList()
          : null,
      nameKeywords: (json['name_keywords'] as List).cast<String>(),
    );
  }

  static DeliveryMode _parseDeliveryMode(String mode) {
    switch (mode) {
      case 'indicate':
        return DeliveryMode.indicate;
      case 'read':
        return DeliveryMode.read;
      case 'notify':
      default:
        return DeliveryMode.notify;
    }
  }
}

/// Specification for a GATT characteristic.
class CharacteristicSpec {
  final fbp.Guid serviceUuid;
  final fbp.Guid charUuid;

  CharacteristicSpec({
    required this.serviceUuid,
    required this.charUuid,
  });

  factory CharacteristicSpec.fromJson(Map<String, dynamic> json) {
    return CharacteristicSpec(
      serviceUuid: fbp.Guid(json['service_uuid'] as String),
      charUuid: fbp.Guid(json['char_uuid'] as String),
    );
  }
}

/// How the device delivers measurement data.
enum DeliveryMode {
  /// Standard BLE notification.
  notify,

  /// Indication (requires ACK from client).
  indicate,

  /// Must read characteristic explicitly.
  read,
}

/// A single initialization step after connection.
class InitStep {
  final CharacteristicSpec target;
  final List<int> value;

  InitStep({
    required this.target,
    required this.value,
  });

  factory InitStep.fromJson(Map<String, dynamic> json) {
    return InitStep(
      target: CharacteristicSpec.fromJson({
        'service_uuid': json['service_uuid'],
        'char_uuid': json['char_uuid'],
      }),
      value: (json['value'] as List).cast<int>(),
    );
  }
}

/// Result of parsing raw BLE bytes.
class BleParsedReading {
  final String type; // 'blood_pressure', 'blood_sugar', 'weight', 'pulse'
  final int? systolic;
  final int? diastolic;
  final int? pulse;
  final double? glucose;
  final String? glucoseUnit;
  final double? weight;
  final DateTime? timestamp;
  final Map<String, dynamic> raw;

  const BleParsedReading({
    required this.type,
    this.systolic,
    this.diastolic,
    this.pulse,
    this.glucose,
    this.glucoseUnit,
    this.weight,
    this.timestamp,
    this.raw = const {},
  });

  bool get isValid {
    if (type == 'blood_pressure') {
      return systolic != null && diastolic != null;
    }
    if (type == 'blood_sugar') {
      return glucose != null;
    }
    if (type == 'weight') {
      return weight != null;
    }
    return false;
  }
}

/// Parser function signature.
typedef BleReadingParser = BleParsedReading? Function(List<int> value);
