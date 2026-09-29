import 'dart:math';
import '../providers/trip_provider.dart';

enum RoadType {
  mainRoad,
  oneWay,
  schoolZone,
  hospitalZone,
  residential,
  highway,
}

class RoadRuleViolation {
  final String id;
  final String ruleType; // 'ONE_WAY_BREACH', 'SCHOOL_ZONE_SPEEDING', 'HOSPITAL_ZONE_NOISE', 'SPEED_LIMIT_EXCEEDED', 'HARSH_MANEUVER'
  final String ruleTitle;
  final String description;
  final String severity; // 'critical', 'high', 'medium', 'low'
  final double speed;
  final double speedLimit;
  final String roadType;
  final String roadName;
  final double lat;
  final double lng;
  final DateTime timestamp;

  RoadRuleViolation({
    required this.id,
    required this.ruleType,
    required this.ruleTitle,
    required this.description,
    required this.severity,
    required this.speed,
    required this.speedLimit,
    required this.roadType,
    required this.roadName,
    required this.lat,
    required this.lng,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();
}

class PotholeHazard {
  final String id;
  final double lat;
  final double lng;
  final double intensity; // 0.0 to 1.0
  final double vibrationRate;
  final String roadName;
  final String? reportedBy;
  final DateTime timestamp;

  PotholeHazard({
    required this.id,
    required this.lat,
    required this.lng,
    required this.intensity,
    required this.vibrationRate,
    required this.roadName,
    this.reportedBy,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();

  factory PotholeHazard.fromJson(Map<String, dynamic> json) {
    return PotholeHazard(
      id: json['id']?.toString() ?? 'pot-${DateTime.now().millisecondsSinceEpoch}',
      lat: (json['latitude'] ?? json['lat'] as num?)?.toDouble() ?? 12.7749,
      lng: (json['longitude'] ?? json['lng'] as num?)?.toDouble() ?? 75.2023,
      intensity: (json['intensity'] as num?)?.toDouble() ?? 0.85,
      vibrationRate: (json['vibrationRate'] as num?)?.toDouble() ?? 3.2,
      roadName: json['roadName']?.toString() ?? 'Transit Road Corridor',
      reportedBy: json['driverName']?.toString() ?? 'Fleet Telemetry',
      timestamp: json['timestamp'] != null ? DateTime.tryParse(json['timestamp'].toString()) ?? DateTime.now() : DateTime.now(),
    );
  }
}

class OneWaySegment {
  final String name;
  final double startLat;
  final double startLng;
  final double endLat;
  final double endLng;
  final double permittedHeading; // Allowed bearing in degrees (0 - 360)
  final String allowedDirection; // e.g. "Eastbound (090°)"

  const OneWaySegment({
    required this.name,
    required this.startLat,
    required this.startLng,
    required this.endLat,
    required this.endLng,
    required this.permittedHeading,
    required this.allowedDirection,
  });
}

class CityZoneItem {
  final String name;
  final String category; // 'school', 'hospital', 'silence', 'one_way'
  final double lat;
  final double lng;
  final double speedLimitKmH;
  final String cautionaryRule;

  const CityZoneItem({
    required this.name,
    required this.category,
    required this.lat,
    required this.lng,
    required this.speedLimitKmH,
    required this.cautionaryRule,
  });
}

class CityTrafficRegulations {
  final String cityId;
  final String cityName;
  final String state;
  final String district;
  final double mainRoadSpeedLimit;
  final double schoolZoneSpeedLimit;
  final double hospitalZoneSpeedLimit;
  final double residentialSpeedLimit;
  final double highwaySpeedLimit;
  final String heavyVehicleTimings;
  final List<String> mandatoryRules;
  final List<OneWaySegment> oneWays;
  final List<CityZoneItem> schools;
  final List<CityZoneItem> hospitals;
  final List<PotholeHazard> knownPotholes;

  CityTrafficRegulations({
    required this.cityId,
    required this.cityName,
    required this.state,
    required this.district,
    required this.mainRoadSpeedLimit,
    required this.schoolZoneSpeedLimit,
    required this.hospitalZoneSpeedLimit,
    required this.residentialSpeedLimit,
    required this.highwaySpeedLimit,
    required this.heavyVehicleTimings,
    required this.mandatoryRules,
    required this.oneWays,
    required this.schools,
    required this.hospitals,
    required this.knownPotholes,
  });
}

class RoadRulesService {
  RoadRulesService._();

  static final Map<String, CityTrafficRegulations> _cityDatabase = {
    'puttur_taluk': CityTrafficRegulations(
      cityId: 'puttur_taluk',
      cityName: 'Puttur',
      state: 'Karnataka',
      district: 'Dakshina Kannada',
      mainRoadSpeedLimit: 50.0,
      schoolZoneSpeedLimit: 25.0,
      hospitalZoneSpeedLimit: 30.0,
      residentialSpeedLimit: 30.0,
      highwaySpeedLimit: 70.0,
      heavyVehicleTimings: 'No Entry 08:30 AM - 11:00 AM & 04:30 PM - 07:30 PM in Main Market',
      mandatoryRules: [
        'Strict 25 km/h speed limit near all academic and school campuses.',
        'Mandatory ISI-certified helmet for 2-wheelers & seatbelts for 4-wheelers.',
        'Zero tolerance for wrong-way driving on Main Market & Bolwar One-Way Corridors.',
        '24x7 Silence Zone: Honking prohibited near Government Hospital Puttur.',
        'Maintain minimum 3-meter safe following distance on narrow ghat roads.',
      ],
      oneWays: const [
        OneWaySegment(
          name: 'Main Market Road (Old Bus Stand to Bolwar)',
          startLat: 12.7720,
          startLng: 75.1980,
          endLat: 12.7760,
          endLng: 75.2040,
          permittedHeading: 55.0,
          allowedDirection: 'North-Eastbound Only (055°)',
        ),
        OneWaySegment(
          name: 'Court Road One-Way Passage',
          startLat: 12.7680,
          startLng: 75.1950,
          endLat: 12.7700,
          endLng: 75.1990,
          permittedHeading: 65.0,
          allowedDirection: 'Eastbound Only (065°)',
        ),
      ],
      schools: const [
        CityZoneItem(
          name: 'Puttur Public School & PU College',
          category: 'school',
          lat: 12.7780,
          lng: 75.2050,
          speedLimitKmH: 25.0,
          cautionaryRule: 'School Crossing Zone: Maximum 25 km/h. Pedestrian priority.',
        ),
        CityZoneItem(
          name: 'St. Philomena College & Campus',
          category: 'school',
          lat: 12.7840,
          lng: 75.2120,
          speedLimitKmH: 25.0,
          cautionaryRule: 'High Student Density: 25 km/h. Watch for crossing buses.',
        ),
        CityZoneItem(
          name: 'Vivekananda College Campus',
          category: 'school',
          lat: 12.7660,
          lng: 75.2180,
          speedLimitKmH: 25.0,
          cautionaryRule: 'University Geofence: Speed limit 25 km/h. No overtake zone.',
        ),
        CityZoneItem(
          name: 'Mountain View English School',
          category: 'school',
          lat: 12.7730,
          lng: 75.2010,
          speedLimitKmH: 25.0,
          cautionaryRule: 'Primary School Gate: 20-25 km/h during drop & pickup hours.',
        ),
      ],
      hospitals: const [
        CityZoneItem(
          name: 'Government Taluk Hospital Puttur',
          category: 'hospital',
          lat: 12.7710,
          lng: 75.2020,
          speedLimitKmH: 30.0,
          cautionaryRule: 'Emergency Ambulance Corridor: Strictly No Honking (Silence Zone).',
        ),
        CityZoneItem(
          name: 'Pragathi Multi-Speciality Hospital',
          category: 'hospital',
          lat: 12.7750,
          lng: 75.2080,
          speedLimitKmH: 30.0,
          cautionaryRule: 'Hospital Zone: Max 30 km/h. Yield right of way to EMS units.',
        ),
      ],
      knownPotholes: [],
    ),

    'mangalore_city': CityTrafficRegulations(
      cityId: 'mangalore_city',
      cityName: 'Mangalore',
      state: 'Karnataka',
      district: 'Dakshina Kannada',
      mainRoadSpeedLimit: 50.0,
      schoolZoneSpeedLimit: 25.0,
      hospitalZoneSpeedLimit: 30.0,
      residentialSpeedLimit: 30.0,
      highwaySpeedLimit: 80.0,
      heavyVehicleTimings: 'No Entry 08:00 AM - 10:30 AM & 05:00 PM - 08:00 PM on K.S. Rao Rd & MG Rd',
      mandatoryRules: [
        'Strict speed enforcement on coastal highways and flyovers.',
        'Bus priority lane regulations strictly enforced on Hampankatta axis.',
        'Helmet & seatbelt checks at all major circles and junctions.',
        'Silence Zone: Wenlock & KMC Hospital areas (No Honking).',
      ],
      oneWays: const [
        OneWaySegment(
          name: 'K.S. Rao Road (Hampankatta to Navabharath Circle)',
          startLat: 12.8700,
          startLng: 74.8420,
          endLat: 12.8760,
          endLng: 74.8450,
          permittedHeading: 25.0,
          allowedDirection: 'Northbound Only (025°)',
        ),
      ],
      schools: const [
        CityZoneItem(name: 'St. Aloysius High School & College', category: 'school', lat: 12.8730, lng: 74.8440, speedLimitKmH: 25.0, cautionaryRule: 'School Zone: Max 25 km/h.'),
        CityZoneItem(name: 'Canara High School Urwa', category: 'school', lat: 12.8900, lng: 74.8350, speedLimitKmH: 25.0, cautionaryRule: 'Pedestrian Crossing: 25 km/h.'),
      ],
      hospitals: const [
        CityZoneItem(name: 'Wenlock District Hospital', category: 'hospital', lat: 12.8680, lng: 74.8430, speedLimitKmH: 30.0, cautionaryRule: 'Silence Zone: No Horn.'),
        CityZoneItem(name: 'KMC Hospital Mangalore', category: 'hospital', lat: 12.8780, lng: 74.8460, speedLimitKmH: 30.0, cautionaryRule: 'Silence Zone: Max 30 km/h.'),
      ],
      knownPotholes: [],
    ),

    'bengaluru_central': CityTrafficRegulations(
      cityId: 'bengaluru_central',
      cityName: 'Bengaluru',
      state: 'Karnataka',
      district: 'Bengaluru Urban',
      mainRoadSpeedLimit: 50.0,
      schoolZoneSpeedLimit: 25.0,
      hospitalZoneSpeedLimit: 30.0,
      residentialSpeedLimit: 30.0,
      highwaySpeedLimit: 80.0,
      heavyVehicleTimings: 'Heavy Commercial Ban 07:00 AM - 11:00 AM & 04:00 PM - 10:00 PM inside ORR',
      mandatoryRules: [
        'Bus Priority Lane violation carries automatic digital camera Challan.',
        'Strict 25 km/h speed limit within 200m of all educational institutions.',
        'High-density pedestrian zones on Church St, MG Rd, and Brigade Rd.',
        'Mandatory dual rearview mirrors and working indicator signals.',
      ],
      oneWays: const [
        OneWaySegment(name: 'Brigade Road (MG Rd to Hosur Rd)', startLat: 12.9730, startLng: 77.6070, endLat: 12.9680, endLng: 77.6090, permittedHeading: 160.0, allowedDirection: 'Southbound Only (160°)'),
        OneWaySegment(name: 'Residency Road One-Way', startLat: 12.9700, startLng: 77.6000, endLat: 12.9720, endLng: 77.6120, permittedHeading: 80.0, allowedDirection: 'Eastbound Only (080°)'),
      ],
      schools: const [
        CityZoneItem(name: 'Bishop Cotton Boys School', category: 'school', lat: 12.9690, lng: 77.6010, speedLimitKmH: 25.0, cautionaryRule: 'School Geofence: 25 km/h max.'),
        CityZoneItem(name: 'Baldwin Boys High School', category: 'school', lat: 12.9640, lng: 77.6030, speedLimitKmH: 25.0, cautionaryRule: 'School Zone: Watch for children.'),
      ],
      hospitals: const [
        CityZoneItem(name: 'Victoria Hospital & Medical College', category: 'hospital', lat: 12.9620, lng: 77.5740, speedLimitKmH: 30.0, cautionaryRule: 'Silence Zone: 24x7 No Horn.'),
        CityZoneItem(name: 'Manipal Hospital Hal Old Airport Rd', category: 'hospital', lat: 12.9580, lng: 77.6490, speedLimitKmH: 30.0, cautionaryRule: 'Emergency Corridor: 30 km/h.'),
      ],
      knownPotholes: [],
    ),
  };

  /// Fetches the city traffic regulations based on regionId or nearest GPS coordinates
  static CityTrafficRegulations getRegulationsForLocation({String? regionId, double? lat, double? lng}) {
    if (regionId != null && _cityDatabase.containsKey(regionId)) {
      return _cityDatabase[regionId]!;
    }

    if (lat != null && lng != null) {
      double minDistance = double.infinity;
      CityTrafficRegulations closest = _cityDatabase['puttur_taluk']!;

      _cityDatabase.forEach((key, city) {
        if (city.schools.isNotEmpty) {
          final first = city.schools.first;
          final d = calculateDistance(lat, lng, first.lat, first.lng);
          if (d < minDistance) {
            minDistance = d;
            closest = city;
          }
        }
      });

      if (minDistance < 50.0) {
        return closest;
      }
    }

    // Default fallback
    return _cityDatabase['puttur_taluk']!;
  }

  /// Calculates straight-line distance in km between two lat/lng points
  static double calculateDistance(double lat1, double lon1, double lat2, double lon2) {
    const double p = 0.017453292519943295;
    final a = 0.5 -
        cos((lat2 - lat1) * p) / 2 +
        cos(lat1 * p) * cos(lat2 * p) * (1 - cos((lon2 - lon1) * p)) / 2;
    return 12742 * asin(sqrt(a));
  }

  /// Evaluates driving context and flags traffic rule breaches in real-time
  static RoadRuleViolation? evaluateDrivingRules({
    required double speedKmH,
    required double headingDegrees,
    required double currentLat,
    required double currentLng,
    required CityTrafficRegulations cityRules,
    List<SafetyZone>? dynamicSchoolZones,
  }) {
    // 1. Check School Zones (dynamic from Overpass + city rules)
    final allSchools = <Map<String, dynamic>>[];
    for (final s in cityRules.schools) {
      allSchools.add({'name': s.name, 'lat': s.lat, 'lng': s.lng, 'limit': s.speedLimitKmH});
    }
    if (dynamicSchoolZones != null) {
      for (final z in dynamicSchoolZones) {
        if (z.type == 'school') {
          allSchools.add({'name': z.name, 'lat': z.lat, 'lng': z.lng, 'limit': 25.0});
        }
      }
    }

    for (final sch in allSchools) {
      final double distKm = calculateDistance(currentLat, currentLng, sch['lat'] as double, sch['lng'] as double);
      if (distKm <= 0.25) { // Within 250m of school
        final double limit = (sch['limit'] as num?)?.toDouble() ?? 25.0;
        if (speedKmH > (limit + 5.0)) { // 5 km/h grace threshold
          return RoadRuleViolation(
            id: 'viol-school-${DateTime.now().millisecondsSinceEpoch}',
            ruleType: 'SCHOOL_ZONE_SPEEDING',
            ruleTitle: 'School Zone Speed Limit Breach',
            description: 'Driving at ${speedKmH.toInt()} km/h inside ${sch['name']} geofence (Max: ${limit.toInt()} km/h).',
            severity: 'critical',
            speed: speedKmH,
            speedLimit: limit,
            roadType: 'School Safety Zone',
            roadName: sch['name'].toString(),
            lat: currentLat,
            lng: currentLng,
          );
        }
      }
    }

    // 2. Check One-Way Road Violations
    for (final ow in cityRules.oneWays) {
      final double distToStart = calculateDistance(currentLat, currentLng, ow.startLat, ow.startLng);
      final double distToEnd = calculateDistance(currentLat, currentLng, ow.endLat, ow.endLng);
      if (distToStart <= 0.4 || distToEnd <= 0.4) {
        // Driver is within this one-way segment. Check heading angle difference.
        double angleDiff = (headingDegrees - ow.permittedHeading).abs();
        if (angleDiff > 180) angleDiff = 360 - angleDiff;

        if (angleDiff > 125.0 && speedKmH > 8.0) {
          return RoadRuleViolation(
            id: 'viol-oneway-${DateTime.now().millisecondsSinceEpoch}',
            ruleType: 'ONE_WAY_BREACH',
            ruleTitle: 'One-Way Traffic Direction Breach',
            description: 'Wrong-way movement detected on ${ow.name}. Permitted: ${ow.allowedDirection}.',
            severity: 'critical',
            speed: speedKmH,
            speedLimit: cityRules.mainRoadSpeedLimit,
            roadType: 'One-Way Street',
            roadName: ow.name,
            lat: currentLat,
            lng: currentLng,
          );
        }
      }
    }

    // 3. Check Hospital Silence Zones
    for (final hosp in cityRules.hospitals) {
      final double distKm = calculateDistance(currentLat, currentLng, hosp.lat, hosp.lng);
      if (distKm <= 0.20) {
        if (speedKmH > (hosp.speedLimitKmH + 6.0)) {
          return RoadRuleViolation(
            id: 'viol-hosp-${DateTime.now().millisecondsSinceEpoch}',
            ruleType: 'HOSPITAL_ZONE_SPEEDING',
            ruleTitle: 'Hospital Zone Speeding & Silence Breach',
            description: 'Exceeding silence zone speed (${speedKmH.toInt()} km/h) near ${hosp.name}.',
            severity: 'high',
            speed: speedKmH,
            speedLimit: hosp.speedLimitKmH,
            roadType: 'Hospital Silence Zone',
            roadName: hosp.name,
            lat: currentLat,
            lng: currentLng,
          );
        }
      }
    }

    // 4. Check City Main Road General Speed Limit
    if (speedKmH > (cityRules.mainRoadSpeedLimit + 12.0)) {
      return RoadRuleViolation(
        id: 'viol-speed-${DateTime.now().millisecondsSinceEpoch}',
        ruleType: 'SPEED_LIMIT_EXCEEDED',
        ruleTitle: 'City Road Speed Limit Violation',
        description: 'Vehicle traveling at ${speedKmH.toInt()} km/h (City Limit: ${cityRules.mainRoadSpeedLimit.toInt()} km/h).',
        severity: speedKmH > (cityRules.mainRoadSpeedLimit + 25.0) ? 'critical' : 'high',
        speed: speedKmH,
        speedLimit: cityRules.mainRoadSpeedLimit,
        roadType: 'Main Arterial Road',
        roadName: '${cityRules.cityName} Transit Corridor',
        lat: currentLat,
        lng: currentLng,
      );
    }

    return null;
  }
}
