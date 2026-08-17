import '../../core/utils/result.dart';
import '../../models/vital_reading.dart';
import '../readings_service.dart';

/// Mock readings service backed by in-memory list.
class MockReadingsService implements ReadingsService {
  final List<VitalReading> _store = VitalReading.mockReadings();

  List<VitalReading> get readings => List.unmodifiable(_store);

  @override
  Future<Result<VitalReading>> submitReading(VitalReading reading) async {
    await Future.delayed(const Duration(seconds: 1));
    _store.insert(0, reading);
    return Success(reading);
  }

  @override
  Future<Result<List<VitalReading>>> getReadings({int? limit}) async {
    await Future.delayed(const Duration(milliseconds: 500));
    final list = limit != null ? _store.take(limit).toList() : List.of(_store);
    return Success(list);
  }

  @override
  Future<Result<int>> syncPendingReadings(List<VitalReading> readings) async {
    await Future.delayed(const Duration(seconds: 2));
    return Success(readings.length);
  }
}
