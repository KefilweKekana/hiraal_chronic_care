import '../../core/utils/result.dart';
import '../../models/vital_reading.dart';

/// Contract for vital readings operations.
abstract class ReadingsService {
  /// Submit a new vital reading.
  Future<Result<VitalReading>> submitReading(VitalReading reading);

  /// Fetch readings for the logged-in patient.
  Future<Result<List<VitalReading>>> getReadings({int? limit});

  /// Sync pending readings in batch.
  Future<Result<int>> syncPendingReadings(List<VitalReading> readings);
}
