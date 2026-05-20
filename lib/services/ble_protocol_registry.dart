import 'package:flutter_blue_plus/flutter_blue_plus.dart' as fbp;

import '../core/database/protocol_dao.dart';
import '../core/network/api_client.dart';
import '../core/utils/app_logger.dart';
import '../core/utils/result.dart';
import '../models/ble_protocol.dart';

/// Registry of BLE medical device protocols.
///
/// Loading priority:
/// 1. ERPNext server (via API) → cached locally
/// 2. Local SQLite cache (if server unavailable)
/// 3. Hardcoded built-in protocols (fallback)
class BleProtocolRegistry {
  BleProtocolRegistry._();
  static final BleProtocolRegistry instance = BleProtocolRegistry._();

  final ProtocolDao _dao = ProtocolDao();
  final List<BleDeviceProtocol> _protocols = [];
  bool _loaded = false;

  List<BleDeviceProtocol> get all => List.unmodifiable(_protocols);

  /// Load protocols from the best available source.
  Future<void> load({ApiClient? apiClient, bool forceRefresh = false}) async {
    if (_loaded && !forceRefresh) return;

    // 1. Try server if online and cache is stale
    final shouldFetchFromServer = forceRefresh ||
        (apiClient != null && await _dao.isStale(maxAgeHours: 24));

    if (shouldFetchFromServer) {
      try {
        final result = await apiClient!.getBleProtocols();
        result.onSuccess((protocolsJson) async {
          await _dao.replaceAll(protocolsJson);
          log.i('BLE protocols refreshed from server: ${protocolsJson.length}');
        });
        result.onFailure((msg) {
          log.w('Failed to fetch BLE protocols from server: $msg');
        });
      } catch (e) {
        log.w('Exception fetching BLE protocols', error: e);
      }
    }

    // 2. Try local cache
    final cached = await _dao.getAll();
    if (cached.isNotEmpty) {
      _protocols.clear();
      for (final json in cached) {
        final protocol = _tryBuildFromJson(json);
        if (protocol != null) _protocols.add(protocol);
      }
      log.i('Loaded ${_protocols.length} BLE protocols from local cache');
      _loaded = true;
      return;
    }

    // 3. Fall back to built-in protocols
    _protocols.clear();
    _protocols.addAll(_builtInProtocols);
    log.i('Loaded ${_protocols.length} built-in BLE protocols');
    _loaded = true;
  }

  /// Force reload from server on next access.
  void invalidate() {
    _loaded = false;
  }

  /// Find protocols that match advertised service UUIDs.
  List<BleDeviceProtocol> findByServices(List<fbp.Guid> advertisedUuids) {
    final matches = <BleDeviceProtocol>[];
    for (final protocol in _protocols) {
      for (final svc in protocol.serviceUuids) {
        if (advertisedUuids.any((u) => _uuidEq(u, svc))) {
          matches.add(protocol);
          break;
        }
      }
    }
    return matches;
  }

  /// Find protocols that match device name keywords.
  List<BleDeviceProtocol> findByName(String deviceName) {
    final lower = deviceName.toLowerCase();
    return _protocols
        .where((p) => p.nameKeywords.any((k) => lower.contains(k.toLowerCase())))
        .toList();
  }

  /// Best-effort auto-detect protocol for a device.
  BleDeviceProtocol? detect({
    String? deviceName,
    List<fbp.Guid>? advertisedServices,
  }) {
    if (deviceName != null && deviceName.isNotEmpty) {
      final nameMatches = findByName(deviceName);
      if (nameMatches.isNotEmpty) return nameMatches.first;
    }
    if (advertisedServices != null && advertisedServices.isNotEmpty) {
      final svcMatches = findByServices(advertisedServices);
      if (svcMatches.isNotEmpty) return svcMatches.first;
    }
    return null;
  }

  /// Attempt to build a BleDeviceProtocol from JSON. Returns null if parser unknown.
  BleDeviceProtocol? _tryBuildFromJson(Map<String, dynamic> json) {
    final parserType = json['parser_type'] as String?;
    final parser = _parserForType(parserType);
    if (parser == null) {
      log.w('Unknown parser type "$parserType", skipping protocol ${json['name']}');
      return null;
    }
    try {
      return BleDeviceProtocol.fromJson(json, parser);
    } catch (e) {
      log.e('Failed to build protocol from JSON', error: e);
      return null;
    }
  }

  /// Map parser type string → parser function.
  BleReadingParser? _parserForType(String? type) {
    switch (type) {
      case 'standard_bp':
        return _parseStandardBp;
      case 'standard_glucose':
        return _parseStandardGlucose;
      case 'standard_weight':
        return _parseStandardWeight;
      case 'omron_bp':
        return _parseOmronBp;
      case 'andesfit_b180':
        return _parseAndesfitB180;
      default:
        return null;
    }
  }

  static bool _uuidEq(fbp.Guid a, fbp.Guid b) {
    return a.str.toLowerCase() == b.str.toLowerCase();
  }
}

// ═══════════════════════════════════════════════════════════════
//  BUILT-IN FALLBACK PROTOCOLS
// ═══════════════════════════════════════════════════════════════

final List<BleDeviceProtocol> _builtInProtocols = [
  _genericBloodPressure,
  _genericGlucose,
  _genericWeightScale,
  _omronBloodPressure,
  _aAndDBloodPressure,
  _accuChekGlucose,
  _contourGlucose,
  _andesfitB180,
];

final _genericBloodPressure = BleDeviceProtocol(
  name: 'Generic Blood Pressure (SIG)',
  deviceTypes: const ['Blood Pressure'],
  serviceUuids: [fbp.Guid('1810')],
  measurementChars: [
    CharacteristicSpec(serviceUuid: fbp.Guid('1810'), charUuid: fbp.Guid('2A35')),
  ],
  deliveryMode: DeliveryMode.notify,
  parser: _parseStandardBp,
  nameKeywords: const ['bp', 'blood pressure', 'pressure', 'bpm'],
);

final _genericGlucose = BleDeviceProtocol(
  name: 'Generic Glucose (SIG)',
  deviceTypes: const ['Blood Sugar'],
  serviceUuids: [fbp.Guid('1808')],
  measurementChars: [
    CharacteristicSpec(serviceUuid: fbp.Guid('1808'), charUuid: fbp.Guid('2A18')),
  ],
  controlChars: [
    CharacteristicSpec(serviceUuid: fbp.Guid('1808'), charUuid: fbp.Guid('2A52')),
  ],
  deliveryMode: DeliveryMode.notify,
  parser: _parseStandardGlucose,
  nameKeywords: const ['glucose', 'gluco', 'sugar', 'bgm'],
);

final _genericWeightScale = BleDeviceProtocol(
  name: 'Generic Weight Scale (SIG)',
  deviceTypes: const ['Smart Scale'],
  serviceUuids: [fbp.Guid('181D')],
  measurementChars: [
    CharacteristicSpec(serviceUuid: fbp.Guid('181D'), charUuid: fbp.Guid('2A9D')),
  ],
  deliveryMode: DeliveryMode.notify,
  parser: _parseStandardWeight,
  nameKeywords: const ['scale', 'weight', 'body'],
);

final _omronBloodPressure = BleDeviceProtocol(
  name: 'Omron Blood Pressure',
  deviceTypes: const ['Blood Pressure'],
  serviceUuids: [fbp.Guid('1810'), fbp.Guid('181C')],
  measurementChars: [
    CharacteristicSpec(serviceUuid: fbp.Guid('1810'), charUuid: fbp.Guid('2A35')),
  ],
  deliveryMode: DeliveryMode.indicate,
  parser: _parseOmronBp,
  nameKeywords: const ['omron', 'heartguide', 'evolv'],
);

final _aAndDBloodPressure = BleDeviceProtocol(
  name: 'A&D Medical Blood Pressure',
  deviceTypes: const ['Blood Pressure'],
  serviceUuids: [fbp.Guid('1810')],
  measurementChars: [
    CharacteristicSpec(serviceUuid: fbp.Guid('1810'), charUuid: fbp.Guid('2A35')),
  ],
  deliveryMode: DeliveryMode.notify,
  parser: _parseStandardBp,
  nameKeywords: const ['a&d', 'and', 'ua-651', 'ua651'],
);

final _accuChekGlucose = BleDeviceProtocol(
  name: 'Accu-Chek Glucose',
  deviceTypes: const ['Blood Sugar'],
  serviceUuids: [fbp.Guid('1808')],
  measurementChars: [
    CharacteristicSpec(serviceUuid: fbp.Guid('1808'), charUuid: fbp.Guid('2A18')),
  ],
  controlChars: [
    CharacteristicSpec(serviceUuid: fbp.Guid('1808'), charUuid: fbp.Guid('2A52')),
  ],
  deliveryMode: DeliveryMode.notify,
  parser: _parseStandardGlucose,
  initSequence: [
    InitStep(
      target: CharacteristicSpec(serviceUuid: fbp.Guid('1808'), charUuid: fbp.Guid('2A52')),
      value: [0x01, 0x01],
    ),
  ],
  nameKeywords: const ['accu', 'accuchek', 'accu-chek', 'guide'],
);

final _contourGlucose = BleDeviceProtocol(
  name: 'Contour Glucose',
  deviceTypes: const ['Blood Sugar'],
  serviceUuids: [fbp.Guid('1808')],
  measurementChars: [
    CharacteristicSpec(serviceUuid: fbp.Guid('1808'), charUuid: fbp.Guid('2A18')),
  ],
  controlChars: [
    CharacteristicSpec(serviceUuid: fbp.Guid('1808'), charUuid: fbp.Guid('2A52')),
  ],
  deliveryMode: DeliveryMode.notify,
  parser: _parseStandardGlucose,
  initSequence: [
    InitStep(
      target: CharacteristicSpec(serviceUuid: fbp.Guid('1808'), charUuid: fbp.Guid('2A52')),
      value: [0x01, 0x01],
    ),
  ],
  nameKeywords: const ['contour', 'bayer', 'next one'],
);

final _andesfitB180 = BleDeviceProtocol(
  name: 'Andesfit B180',
  deviceTypes: const ['Blood Pressure'],
  serviceUuids: [fbp.Guid('fff0')],
  measurementChars: [
    CharacteristicSpec(serviceUuid: fbp.Guid('fff0'), charUuid: fbp.Guid('fff4')),
  ],
  controlChars: [
    CharacteristicSpec(serviceUuid: fbp.Guid('fff0'), charUuid: fbp.Guid('fff3')),
  ],
  deliveryMode: DeliveryMode.notify,
  parser: _parseAndesfitB180,
  nameKeywords: const ['bpm', 'andesfit', 'b180', 'adf-b180'],
);

// ═══════════════════════════════════════════════════════════════
//  PARSERS
// ═══════════════════════════════════════════════════════════════

BleParsedReading? _parseStandardBp(List<int> value) {
  if (value.length < 7) return null;
  final flags = value[0];
  final systolic = _parseSfloat(value[1], value[2])?.toInt();
  final diastolic = _parseSfloat(value[3], value[4])?.toInt();
  final map = _parseSfloat(value[5], value[6])?.toInt();

  int? pulse;
  int offset = 7;
  if ((flags & 0x01) != 0) offset += 7;
  if ((flags & 0x02) != 0 && value.length >= offset + 2) {
    pulse = _parseSfloat(value[offset], value[offset + 1])?.toInt();
  }

  if (systolic == null || diastolic == null) return null;
  return BleParsedReading(
    type: 'blood_pressure',
    systolic: systolic,
    diastolic: diastolic,
    pulse: pulse,
    raw: {'map': map, 'flags': flags},
  );
}

BleParsedReading? _parseOmronBp(List<int> value) {
  final standard = _parseStandardBp(value);
  if (standard != null) return standard;

  if (value.length >= 6) {
    final sys = _parseSfloat(value[0], value[1])?.toInt();
    final dia = _parseSfloat(value[2], value[3])?.toInt();
    final pul = _parseSfloat(value[4], value[5])?.toInt();
    if (sys != null && dia != null) {
      return BleParsedReading(
        type: 'blood_pressure',
        systolic: sys,
        diastolic: dia,
        pulse: pul,
        raw: {'omron_fallback': true},
      );
    }
  }
  return null;
}

BleParsedReading? _parseStandardGlucose(List<int> value) {
  if (value.length < 10) return null;
  final flags = value[0];
  int offset = 2 + 7;

  if ((flags & 0x01) != 0) offset += 2;
  if (value.length < offset + 2) return null;

  final glucose = _parseSfloat(value[offset], value[offset + 1]);
  offset += 2;

  final unit = (flags & 0x02) != 0 ? 'mol/L' : 'mg/dL';

  if (glucose == null) return null;
  return BleParsedReading(
    type: 'blood_sugar',
    glucose: glucose,
    glucoseUnit: unit,
    raw: {'flags': flags},
  );
}

BleParsedReading? _parseStandardWeight(List<int> value) {
  if (value.length < 3) return null;
  final flags = value[0];
  final weight = _parseSfloat(value[1], value[2]);
  if (weight == null) return null;

  final isLb = (flags & 0x01) != 0;
  return BleParsedReading(
    type: 'weight',
    weight: isLb ? weight * 0.453592 : weight,
    raw: {'unit': isLb ? 'lb' : 'kg', 'flags': flags},
  );
}

BleParsedReading? _parseAndesfitB180(List<int> value) {
  // Live pressure feedback during inflation: [0x20, current_pressure]
  if (value.length == 2 && value[0] == 0x20) {
    // Not a final reading – could be surfaced to UI as live feedback
    return null;
  }

  // Final measurement: exactly 12 bytes per Andesfit spec
  if (value.length < 12) return null;

  final flags = value[0];

  // The spec lists bytes as "High / Low" pairs; we treat them as 16-bit BE
  // but fall back to the low byte if the high byte is zero (common case).
  int systolic = (value[1] << 8) | value[2];
  int diastolic = (value[3] << 8) | value[4];
  int map = (value[5] << 8) | value[6];
  int pulse = (value[7] << 8) | value[8];

  // Sanity fallback to single-byte when high byte is unused
  if (systolic > 300 || systolic == 0) systolic = value[2];
  if (diastolic > 300 || diastolic == 0) diastolic = value[4];
  if (pulse > 300) pulse = value[8];

  if (systolic == 0 || diastolic == 0) return null;

  return BleParsedReading(
    type: 'blood_pressure',
    systolic: systolic,
    diastolic: diastolic,
    pulse: pulse == 0 ? null : pulse,
    raw: {
      'flags': flags,
      'map': map,
      'user_id': value[9],
      'pad': value[10],
      'meas_status': value[11],
    },
  );
}

// ═══════════════════════════════════════════════════════════════
//  UTILS
// ═══════════════════════════════════════════════════════════════

double? _parseSfloat(int low, int high) {
  final raw = (high << 8) | low;
  if (raw == 0x07FF || raw == 0x0800) return null;
  if (raw == 0x07FE) return double.infinity;
  if (raw == 0x0802) return double.negativeInfinity;
  final mantissa = raw & 0x0FFF;
  final exponent = raw >> 12;
  final signedMantissa = mantissa >= 0x0800 ? mantissa - 0x1000 : mantissa;
  final signedExponent = exponent >= 0x08 ? exponent - 0x10 : exponent;
  return signedMantissa * _pow10(signedExponent);
}

double _pow10(int exp) {
  double result = 1.0;
  int e = exp.abs();
  for (int i = 0; i < e; i++) {
    result *= 10.0;
  }
  return exp < 0 ? 1.0 / result : result;
}
