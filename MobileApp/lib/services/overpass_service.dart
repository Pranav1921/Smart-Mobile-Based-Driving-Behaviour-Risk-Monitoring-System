import 'dart:convert';
import 'dart:io';
import 'dart:math';
import '../providers/trip_provider.dart';

class OverpassService {
  OverpassService._();

  static final HttpClient _client = HttpClient()..connectionTimeout = const Duration(seconds: 8);

  static final List<String> _endpoints = [
    'https://overpass-api.de/api/interpreter',
    'https://lz4.overpass-api.de/api/interpreter',
    'https://overpass.kumi.systems/api/interpreter',
  ];

  // In-memory cache
  static List<SafetyZone> _cachedZones = [];
  static double? _cachedLat;
  static double? _cachedLng;
  static DateTime? _lastFetchTime;

  /// Calculates straight-line distance in meters between two lat/lng pairs
  static double _distanceMeters(double lat1, double lon1, double lat2, double lon2) {
    const double p = 0.017453292519943295;
    final a = 0.5 -
        cos((lat2 - lat1) * p) / 2 +
        cos(lat1 * p) * cos(lat2 * p) * (1 - cos((lon2 - lon1) * p)) / 2;
    return 12742000 * asin(sqrt(a));
  }

  /// Fetches real-world schools, colleges, and kindergartens within [radiusMeters] around [lat], [lng]
  static Future<List<SafetyZone>> fetchNearbySchools(
    double lat,
    double lng, {
    double radiusMeters = 5000,
    bool forceRefresh = false,
  }) async {
    // Check cache (reuse if moved less than 2 km and fetched within 10 minutes)
    if (!forceRefresh && _cachedLat != null && _cachedLng != null && _lastFetchTime != null) {
      final elapsed = DateTime.now().difference(_lastFetchTime!);
      final dist = _distanceMeters(lat, lng, _cachedLat!, _cachedLng!);
      if (dist < 2000 && elapsed.inMinutes < 10 && _cachedZones.isNotEmpty) {
        return _cachedZones;
      }
    }

    final query = '''
[out:json][timeout:8];
(
  node["amenity"~"school|kindergarten|college|university"](around:${radiusMeters.toInt()},$lat,$lng);
  way["amenity"~"school|kindergarten|college|university"](around:${radiusMeters.toInt()},$lat,$lng);
);
out center 40;
''';

    for (final endpoint in _endpoints) {
      try {
        final uri = Uri.parse(endpoint);
        final request = await _client.postUrl(uri);
        request.headers.set(HttpHeaders.contentTypeHeader, 'application/x-www-form-urlencoded; charset=UTF-8');
        final postBody = 'data=${Uri.encodeComponent(query)}';
        request.write(postBody);

        final response = await request.close();
        if (response.statusCode == 200) {
          final responseBody = await response.transform(utf8.decoder).join();
          final data = jsonDecode(responseBody) as Map<String, dynamic>;
          final elements = data['elements'] as List<dynamic>? ?? [];

          final List<SafetyZone> zones = [];
          for (final el in elements) {
            final tags = el['tags'] as Map<String, dynamic>? ?? {};
            final String name = tags['name'] ?? tags['name:en'] ?? 'School Zone';
            final double? itemLat = (el['lat'] ?? el['center']?['lat'])?.toDouble();
            final double? itemLng = (el['lon'] ?? el['center']?['lon'])?.toDouble();

            if (itemLat != null && itemLng != null) {
              zones.add(SafetyZone(
                name: name,
                type: 'school',
                lat: itemLat,
                lng: itemLng,
              ));
            }
          }

          if (zones.isNotEmpty) {
            _cachedZones = zones;
            _cachedLat = lat;
            _cachedLng = lng;
            _lastFetchTime = DateTime.now();
            return zones;
          }
        }
      } catch (e) {
        // Try next endpoint on failure
        continue;
      }
    }

    // Return cached if available, or empty if network unreachable
    return _cachedZones;
  }
}
