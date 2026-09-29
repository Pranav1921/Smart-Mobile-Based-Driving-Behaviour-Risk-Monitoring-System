import 'dart:async';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';

class GpsService {
  GpsService._();

  static Future<bool> requestPermission() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      print('[GpsService] Device GPS / Location services switch is OFF in Android quick settings.');
      return false;
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        print('[GpsService] Location permission was denied by user.');
        return false;
      }
    }
    
    if (permission == LocationPermission.deniedForever) {
      print('[GpsService] Location permission permanently denied. Enable in Settings -> Apps -> FleetGuard -> Permissions -> Location.');
      return false;
    }

    return true;
  }

  static Future<Position?> getCurrentLocation() async {
    try {
      final hasPerm = await requestPermission();
      if (!hasPerm) return null;
      Position? pos;
      try {
        pos = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high,
          timeLimit: const Duration(seconds: 8),
        );
      } catch (_) {
        try {
          pos = await Geolocator.getCurrentPosition(
            desiredAccuracy: LocationAccuracy.medium,
            timeLimit: const Duration(seconds: 4),
          );
        } catch (_) {}
      }
      pos ??= await Geolocator.getLastKnownPosition();
      return pos;
    } catch (_) {
      try {
        return await Geolocator.getLastKnownPosition();
      } catch (__) {
        return null;
      }
    }
  }

  /// Returns a GPS position stream, requesting permission first.
  /// If permission is denied, the stream closes cleanly (no unhandled exception).
  static Stream<Position> getLocationStream() async* {
    final hasPerm = await requestPermission();
    if (!hasPerm) {
      print('[GpsService] Location permission denied.');
      return;
    }

    yield* Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 0, // CRITICAL: Set to 0 for real-time indoor/simulated testing
        timeLimit: Duration(seconds: 10),
      ),
    ).handleError((err) {
      print('[GpsService] Location stream error: $err');
    });
  }

  static Future<String> getAddressFromLatLng(double lat, double lng) async {
    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(lat, lng)
          .timeout(const Duration(seconds: 4));
      if (placemarks.isNotEmpty) {
        Placemark place = placemarks[0];
        final parts = <String>[];

        final street = place.street ?? place.name;
        if (street != null && street.trim().isNotEmpty && !street.contains('+')) {
          parts.add(street.trim());
        }

        final subLoc = place.subLocality;
        if (subLoc != null && subLoc.trim().isNotEmpty && !parts.contains(subLoc.trim())) {
          parts.add(subLoc.trim());
        }

        final city = place.locality;
        if (city != null && city.trim().isNotEmpty && !parts.contains(city.trim())) {
          parts.add(city.trim());
        }

        if (parts.isNotEmpty) {
          return parts.join(', ');
        }
      }
    } catch (_) {}
    return "Coordinates (${lat.toStringAsFixed(4)}, ${lng.toStringAsFixed(4)})";
  }
}
