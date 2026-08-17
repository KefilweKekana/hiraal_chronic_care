import 'dart:async';

import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';

import '../core/utils/app_logger.dart';

/// A captured GPS location with a human-readable address.
class CapturedLocation {
  final double latitude;
  final double longitude;
  final String address;
  final String? city;

  const CapturedLocation({
    required this.latitude,
    required this.longitude,
    required this.address,
    this.city,
  });
}

/// Captures the device's current GPS position and reverse-geocodes it to a
/// real street address. Used when adding a delivery/home address.
///
/// Every step is time-limited so a slow GPS fix or geocoder can never hang the
/// UI (which would otherwise trigger an ANR).
class LocationService {
  LocationService._();
  static final LocationService instance = LocationService._();

  Future<CapturedLocation?> getCurrentLocation() async {
    try {
      if (!await Geolocator.isLocationServiceEnabled()) return null;

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        return null;
      }

      // Last-known is instant; fall back to a time-limited fresh fix so we
      // never block waiting for GPS.
      Position? pos = await Geolocator.getLastKnownPosition();
      if (pos == null) {
        try {
          pos = await Geolocator.getCurrentPosition(
            locationSettings: const LocationSettings(
              accuracy: LocationAccuracy.medium,
              timeLimit: Duration(seconds: 12),
            ),
          ).timeout(const Duration(seconds: 14));
        } on TimeoutException {
          log.w('getCurrentPosition timed out');
        } catch (e) {
          log.w('getCurrentPosition failed', error: e);
        }
      }
      if (pos == null) return null;

      String address = '';
      String? city;
      try {
        final placemarks =
            await placemarkFromCoordinates(pos.latitude, pos.longitude)
                .timeout(const Duration(seconds: 8));
        if (placemarks.isNotEmpty) {
          final p = placemarks.first;
          city = (p.locality?.isNotEmpty ?? false)
              ? p.locality
              : p.subAdministrativeArea;
          address = [
            p.name,
            p.thoroughfare,
            p.subLocality,
            p.locality,
            p.administrativeArea,
            p.country,
          ]
              .where((s) => s != null && s.trim().isNotEmpty)
              .map((s) => s!.trim())
              .toSet()
              .join(', ');
        }
      } on TimeoutException {
        log.w('Reverse geocode timed out');
      } catch (e) {
        log.w('Reverse geocode failed', error: e);
      }

      if (address.isEmpty) {
        address =
            '${pos.latitude.toStringAsFixed(5)}, ${pos.longitude.toStringAsFixed(5)}';
      }

      return CapturedLocation(
        latitude: pos.latitude,
        longitude: pos.longitude,
        address: address,
        city: city,
      );
    } catch (e) {
      log.e('getCurrentLocation failed', error: e);
      return null;
    }
  }
}
