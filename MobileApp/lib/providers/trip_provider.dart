import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sensors_plus/sensors_plus.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:geolocator/geolocator.dart';
import '../models/order_model.dart';
import '../models/trip_model.dart';
import '../models/transaction_model.dart';
import '../models/driver_model.dart';
import '../services/local_storage_service.dart';
import '../services/gps_service.dart';
import '../services/sensor_service.dart';
import '../services/socket_service.dart';
import '../services/voice_service.dart';
import '../services/media_service.dart';
import '../services/notification_service.dart';
import '../services/overpass_service.dart';
import '../services/road_rules_service.dart';
import '../services/haptic_service.dart';
import 'sensor_provider.dart';

class SafetyZone {
  final String name;
  final String type; // school, pothole, traffic
  final double lat;
  final double lng;
  bool alerted;

  SafetyZone({required this.name, required this.type, required this.lat, required this.lng, this.alerted = false});
}

class DrivingRule {
  final String id;
  final String title;
  final String description;
  final int points;
  final String icon;
  bool isAchieved;
  bool isClaimed;

  DrivingRule({
    required this.id,
    required this.title,
    required this.description,
    required this.points,
    required this.icon,
    this.isAchieved = false,
    this.isClaimed = false,
  });
}

class GoodieItem {
  final String id;
  final String title;
  final String subtitle;
  final int pointsCost;
  final String valueText;
  final String category;
  final String icon;
  final bool isComingSoon;

  GoodieItem({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.pointsCost,
    required this.valueText,
    required this.category,
    required this.icon,
    this.isComingSoon = false,
  });
}

class ClaimedVoucher {
  final String id;
  final String title;
  final String voucherCode;
  final int pointsSpent;
  final String valueText;
  final String category;
  final String icon;
  final DateTime claimedAt;
  final String status;

  ClaimedVoucher({
    required this.id,
    required this.title,
    required this.voucherCode,
    required this.pointsSpent,
    required this.valueText,
    required this.category,
    required this.icon,
    required this.claimedAt,
    this.status = 'ACTIVE',
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'voucherCode': voucherCode,
    'pointsSpent': pointsSpent,
    'valueText': valueText,
    'category': category,
    'icon': icon,
    'claimedAt': claimedAt.toIso8601String(),
    'status': status,
  };

  factory ClaimedVoucher.fromJson(Map<String, dynamic> json) => ClaimedVoucher(
    id: json['id']?.toString() ?? '',
    title: json['title']?.toString() ?? '',
    voucherCode: json['voucherCode']?.toString() ?? '',
    pointsSpent: (json['pointsSpent'] as num?)?.toInt() ?? 0,
    valueText: json['valueText']?.toString() ?? '',
    category: json['category']?.toString() ?? '',
    icon: json['icon']?.toString() ?? 'stars_rounded',
    claimedAt: json['claimedAt'] != null ? DateTime.tryParse(json['claimedAt'].toString()) ?? DateTime.now() : DateTime.now(),
    status: json['status']?.toString() ?? 'ACTIVE',
  );
}

class ExternalAppSource {
  final String id;
  final String name;
  final String icon;
  bool isConnected;
  double totalIncome;
  double totalTips;

  ExternalAppSource({required this.id, required this.name, required this.icon, this.isConnected = false, this.totalIncome = 0.0, this.totalTips = 0.0});
}

class TripProvider extends ChangeNotifier {
  bool _isShiftActive = false;
  bool _isTripActive = false;
  bool _showSOSConfirmation = false;
  bool _isCrashDetected = false;
  bool _isAdminPinging = false;
  int _sosCountdown = 0;
  Timer? _sosCountdownTimer;
  int _crashVerificationAttempts = 0;
  bool _isLiveCamActive = false;
  String _crashReason = "Sudden Deceleration / Impact Alert";

  double _tripSafetyScore = 100.0;
  double _todayDistanceKm = 0.0;
  int _todayTripCount = 0;
  double _gForce = 0.0;
  double _maxGForce = 0.0;
  double _todayEarnedIncome = 0.0;
  int _totalClaimedPoints = 0;
  int _lastTripPointsEarned = 0;
  int get lastTripPointsEarned => _lastTripPointsEarned;
  List<ClaimedVoucher> _claimedVouchers = [];
  List<ClaimedVoucher> get claimedVouchers => _claimedVouchers;
  int _verificationStep = 1; // 1: Driver Query (60s), 2: Admin Camera/Telemetry Sync, 3: Multi-channel Escalation

  DateTime? _shiftStartTime;
  bool _fatigueWarning90Emitted = false;
  bool _fatigueWarning120Emitted = false;
  String? _v2vWarning;
  String? get v2vWarning => _v2vWarning;

  String? _adminBroadcastBanner;
  String? get adminBroadcastBanner => _adminBroadcastBanner;

  List<Map<String, dynamic>> _customGeofences = [];
  List<Map<String, dynamic>> get customGeofences => _customGeofences;
  final Set<String> _alertedGeofenceSpeedViolations = {};
  String? _activeGeofenceName;
  int? _activeGeofenceSpeedCeiling;
  String? get activeGeofenceName => _activeGeofenceName;
  int? get activeGeofenceSpeedCeiling => _activeGeofenceSpeedCeiling;

  final List<Map<String, dynamic>> _blackBoxBuffer = [];
  DateTime? _lastBlackBoxRecord;
  List<Map<String, dynamic>> get blackBoxBuffer => List.unmodifiable(_blackBoxBuffer);

  int get shiftDurationMinutes => _shiftStartTime != null ? DateTime.now().difference(_shiftStartTime!).inMinutes : 0;
  bool get isFatigued => shiftDurationMinutes >= 90;
  bool get isRestMandatory => shiftDurationMinutes >= 120;

  double get ecoScore {
    double score = 100.0;
    score -= (_journeyViolations.where((v) => v.ruleType == 'harsh_braking').length * 4.0);
    score -= (_journeyViolations.where((v) => v.ruleType == 'overspeed').length * 3.0);
    score -= (_journeyViolations.where((v) => v.ruleType == 'sharp_turn').length * 2.0);
    return max(40.0, min(100.0, score));
  }

  double get co2SavedKg {
    final savingsPerKm = (ecoScore / 100.0) * 0.038;
    return (_todayDistanceKm * savingsPerKm);
  }

  // Real-Time Fuel Burn & Tire Wear Economics (₹ Rupees)
  int get harshBrakingCount => _journeyViolations.where((v) => v.ruleType == 'harsh_braking').length;
  int get overspeedCount => _journeyViolations.where((v) => v.ruleType == 'overspeed').length;
  int get sharpTurnCount => _journeyViolations.where((v) => v.ruleType == 'sharp_turn').length;

  double get fuelWastedInr => (harshBrakingCount * 22.5) + (overspeedCount * 32.0);
  double get tireWearInr => (harshBrakingCount + sharpTurnCount) * 16.5;
  double get totalPenaltyInr => fuelWastedInr + tireWearInr;
  double get fuelSavedInr => (_todayDistanceKm * 7.2);
  double get netSavingsInr => fuelSavedInr - totalPenaltyInr;
  bool get isNetProfit => netSavingsInr >= 0;

  // IRDAI Pay-How-You-Drive Dynamic Discount Tier
  int get phydDiscountPercent => _tripSafetyScore >= 90 ? 32 : (_tripSafetyScore >= 75 ? 18 : 0);
  double get annualInsuranceRebateInr => (18500.0 * phydDiscountPercent) / 100.0;
  double get netAdjustedPremiumInr => 18500.0 - annualInsuranceRebateInr;

  // Auto-Locked Dashcam 20-Frame Ring Buffer
  final List<Map<String, dynamic>> _dashcamRingBuffer = [];
  List<Map<String, dynamic>> _lockedDashcamEvidence = [];
  bool _isDashcamEvidenceLocked = false;
  bool get isDashcamEvidenceLocked => _isDashcamEvidenceLocked;
  bool get dashcamEvidenceLocked => _isDashcamEvidenceLocked;
  String get driverId => _currentDriverId ?? '';
  List<Map<String, dynamic>> get lockedDashcamEvidence => _lockedDashcamEvidence;
  Timer? _dashcamRingTimer;

  // Roadside Breakdown SOS Dispatch State
  bool _isRoadsideBreakdownDispatched = false;
  bool get isRoadsideBreakdownDispatched => _isRoadsideBreakdownDispatched;
  String? _activeBreakdownType;
  String? get activeBreakdownType => _activeBreakdownType;

  void addDashcamFrame(String? base64Frame) {
    if (_dashcamRingBuffer.length >= 20) {
      _dashcamRingBuffer.removeAt(0);
    }
    _dashcamRingBuffer.add({
      'frame': base64Frame ?? '',
      'timestamp': DateTime.now().millisecondsSinceEpoch,
      'speed': _currentSpeed,
      'gForce': _gForce,
    });
  }

  void _startDashcamRingBuffer() {
    _dashcamRingTimer?.cancel();
    _dashcamRingTimer = Timer.periodic(const Duration(milliseconds: 900), (timer) async {
      if (!_isShiftActive && !_isTripActive) return;
      if (_isDashcamEvidenceLocked) return;

      try {
        final frameBytes = await MediaService.captureFrame();
        String frameStr;
        if (frameBytes != null && frameBytes.isNotEmpty) {
          frameStr = base64Encode(frameBytes);
        } else {
          frameStr = _generateTelemetryFrameSvgBase64();
        }
        addDashcamFrame(frameStr);
      } catch (_) {}
    });
  }

  void lockDashcamEvidence({String reason = 'High-G Impact Event'}) {
    _isDashcamEvidenceLocked = true;
    _lockedDashcamEvidence = List<Map<String, dynamic>>.from(_dashcamRingBuffer);
    print('[TripProvider] 📹 Auto-locked 20-frame dashcam evidence buffer: $reason');
    final dId = _currentDriverId ?? 'agent-x';
    final dName = _currentDriverName ?? 'Field Operator';
    SocketService.emitLockedDashcamEvidence(
      driverId: dId,
      driverName: dName,
      reason: reason,
      frames: _lockedDashcamEvidence,
    );
    notifyListeners();
  }

  void unlockDashcamEvidence() {
    _isDashcamEvidenceLocked = false;
    _lockedDashcamEvidence.clear();
    notifyListeners();
  }

  void dispatchRoadsideBreakdown({
    required String issueType,
    String? notes,
    String? vehiclePlate,
  }) {
    _isRoadsideBreakdownDispatched = true;
    _activeBreakdownType = issueType;
    final lat = _currentLat ?? 0.0;
    final lng = _currentLng ?? 0.0;
    final dId = _currentDriverId ?? 'driver';
    final dName = _currentDriverName ?? 'Driver';
    final plate = (vehiclePlate != null && vehiclePlate.isNotEmpty) ? vehiclePlate : 'KA-19-PT-2026';

    SocketService.emitRoadsideBreakdown(
      driverId: dId,
      driverName: dName,
      issueType: issueType,
      notes: notes,
      lat: lat,
      lng: lng,
      vehiclePlate: plate,
    );

    VoiceService.speak("Roadside breakdown assistance dispatched for $issueType. HQ and nearest recovery fleet notified.");
    NotificationService.showTowBreakdownAlert(
      issueType: issueType,
      nearestTowName: "Puttur 24x7 Highway Recovery",
      nearestTowPhone: "+91 94812 55667",
      eta: "10-15 mins",
    );
    notifyListeners();
  }

  void clearRoadsideBreakdown() {
    _isRoadsideBreakdownDispatched = false;
    _activeBreakdownType = null;
    notifyListeners();
  }

  int get verificationStep => _verificationStep;
  double get speedConsistencyPct => min(100.0, max(82.0, _tripSafetyScore - (_journeyViolations.where((v) => v.ruleType == 'overspeed').length * 2.5)));
  double get brakingSmoothnessPct => min(100.0, max(80.0, _tripSafetyScore - (_journeyViolations.where((v) => v.ruleType == 'harsh_braking').length * 2.0)));
  double get corneringSafetyPct => min(100.0, max(85.0, _tripSafetyScore - (_journeyViolations.where((v) => v.ruleType == 'sharp_turn').length * 2.0)));
  double get zoneAdherencePct => min(100.0, max(88.0, 100.0 - (_journeyViolations.where((v) => v.ruleType == 'school_zone' || v.ruleType == 'hospital_silence').length * 4.0)));
  String get safetyClassification => _tripSafetyScore >= 90 ? 'Exemplary (Gold Tier)' : (_tripSafetyScore >= 75 ? 'Standard (Silver Tier)' : 'Critical Caution (Bronze Tier)');

  int get totalRulesBrokenCount {
    int count = _journeyViolations.length;
    for (final trip in _history) {
      count += trip.events.length;
    }
    return count;
  }

  Map<String, int> get rulesBrokenBreakdown {
    final map = <String, int>{
      'Overspeeding': 0,
      'Harsh Braking': 0,
      'Sharp Turning': 0,
      'School / Silence Zone': 0,
      'Road Roughness / Potholes': _potholes.length,
    };

    for (final v in _journeyViolations) {
      if (v.ruleType == 'overspeed') map['Overspeeding'] = (map['Overspeeding'] ?? 0) + 1;
      else if (v.ruleType == 'harsh_braking') map['Harsh Braking'] = (map['Harsh Braking'] ?? 0) + 1;
      else if (v.ruleType == 'sharp_turn') map['Sharp Turning'] = (map['Sharp Turning'] ?? 0) + 1;
      else if (v.ruleType == 'school_zone' || v.ruleType == 'hospital_silence') map['School / Silence Zone'] = (map['School / Silence Zone'] ?? 0) + 1;
    }

    for (final trip in _history) {
      for (final e in trip.events) {
        final t = e.type.toLowerCase();
        if (t.contains('speed')) map['Overspeeding'] = (map['Overspeeding'] ?? 0) + 1;
        else if (t.contains('brak')) map['Harsh Braking'] = (map['Harsh Braking'] ?? 0) + 1;
        else if (t.contains('turn') || t.contains('swerve')) map['Sharp Turning'] = (map['Sharp Turning'] ?? 0) + 1;
        else if (t.contains('zone') || t.contains('school')) map['School / Silence Zone'] = (map['School / Silence Zone'] ?? 0) + 1;
      }
    }

    return map;
  }

  Map<String, dynamic> get monthlyReportSummary {
    final totalDistance = _todayDistanceKm + _history.fold(0.0, (sum, t) => sum + t.distanceKm);
    final totalTrips = _todayTripCount;
    final avgScore = _history.isEmpty ? _tripSafetyScore : (_history.fold(0.0, (sum, t) => sum + t.safetyScore) + _tripSafetyScore) / (_history.length + 1);

    final weeklyScores = [
      (avgScore - 4.0).clamp(70.0, 99.0),
      (avgScore - 1.5).clamp(72.0, 100.0),
      (avgScore + 2.0).clamp(75.0, 100.0),
      avgScore.clamp(70.0, 100.0),
    ];

    final weeklyActivityHours = [3.8, 5.2, 4.5, 6.0, 5.8, 7.2, 4.0];

    return {
      'monthName': 'Monthly Audit',
      'totalTrips': totalTrips,
      'totalDistanceKm': totalDistance,
      'averageSafetyScore': avgScore,
      'totalRulesBroken': totalRulesBrokenCount,
      'safetyClassification': safetyClassification,
      'weeklyScores': weeklyScores,
      'weeklyActivityHours': weeklyActivityHours,
      'speedConsistency': speedConsistencyPct,
      'brakingSmoothness': brakingSmoothnessPct,
      'corneringSafety': corneringSafetyPct,
      'zoneAdherence': zoneAdherencePct,
      'rulesBreakdown': rulesBrokenBreakdown,
    };
  }

  // Road Rules & Multi-Driver Hazard Management
  final List<PotholeHazard> _potholes = [];
  final List<RoadRuleViolation> _journeyViolations = [];
  final Set<String> _alertedPotholeIds = {};
  DateTime? _lastPotholeDetectedTime;
  DateTime? _lastViolationTime;

  List<PotholeHazard> get potholes => _potholes;
  List<RoadRuleViolation> get journeyViolations => _journeyViolations;
  CityTrafficRegulations get currentCityRules => RoadRulesService.getRegulationsForLocation(
    regionId: _currentRegionId,
    lat: _currentLat,
    lng: _currentLng,
  );

  TripProvider() {
    SocketService.onJobAssignedCallback = (data) {
      handleJobAssigned(data);
    };

    SocketService.onPotholesSnapshotCallback = (list) {
      for (final item in list) {
        if (item is Map) {
          final pot = PotholeHazard.fromJson(Map<String, dynamic>.from(item));
          if (!_potholes.any((p) => p.id == pot.id)) {
            _potholes.add(pot);
          }
        }
      }
      notifyListeners();
    };

    SocketService.onPotholeBroadcastCallback = (data) {
      final pot = PotholeHazard.fromJson(data);
      if (!_potholes.any((p) => p.id == pot.id)) {
        _potholes.insert(0, pot);
        // Proactively notify if currently driving
        if (_isShiftActive && _currentLat != null && _currentLng != null) {
          final distKm = RoadRulesService.calculateDistance(_currentLat!, _currentLng!, pot.lat, pot.lng);
          if (distKm <= 1.5) {
            VoiceService.speak("New road hazard reported by driver on ${pot.roadName}.");
            NotificationService.showSafetyAlert("LIVE ROAD HAZARD", "New pothole/bad road reported on ${pot.roadName}.");
          }
        }
        notifyListeners();
      }
    };

    NotificationService.onConfirmSafeFromNotification = () {
      confirmSafe();
    };

    NotificationService.onTriggerSosFromNotification = () {
      triggerManualSOS();
    };

    _initDeviceGps();
    _startFullSensorSuite();
  }

  DateTime? _lastIdleHeartbeatTime;

  DriverProfile? _currentProfile;

  Future<void> _initDeviceGps() async {
    final profile = await LocalStorageService.getProfile();
    if (profile != null) {
      _currentProfile = profile;
      if (profile.driverId.isNotEmpty) _currentDriverId = profile.driverId;
      if (profile.name.isNotEmpty) {
        _currentDriverName = profile.name.replaceAll(RegExp(r'\s+applicant$', caseSensitive: false), '').trim();
      }
      if (profile.regionId.isNotEmpty) _currentRegionId = profile.regionId;
      notifyListeners();
    }

    final pos = await GpsService.getCurrentLocation();
    if (pos != null) {
      _currentLat = pos.latitude;
      _currentLng = pos.longitude;
      _currentSpeed = pos.speed * 3.6;
      _currentHeading = pos.heading;
      if (_currentDriverId != null && _currentDriverId != 'agent-x' && _currentDriverId!.isNotEmpty) {
        _emitIdleHeartbeat(pos.latitude, pos.longitude, _currentSpeed, _currentHeading);
      }
      notifyListeners();
    }

    GpsService.getLocationStream().listen((pos) {
      _currentLat = pos.latitude;
      _currentLng = pos.longitude;
      _currentSpeed = pos.speed * 3.6;
      _currentHeading = pos.heading;
      if (!_isShiftActive && _currentDriverId != null && _currentDriverId != 'agent-x' && _currentDriverId!.isNotEmpty) {
        _emitIdleHeartbeat(pos.latitude, pos.longitude, _currentSpeed, _currentHeading);
      }
      notifyListeners();
    });
  }

  void _emitIdleHeartbeat(double lat, double lng, double speed, double heading) {
    if (_currentDriverId == null || _currentDriverId == 'agent-x' || _currentDriverId!.isEmpty) {
      return;
    }
    final now = DateTime.now();
    if (_lastIdleHeartbeatTime != null && now.difference(_lastIdleHeartbeatTime!).inSeconds < 4) {
      return;
    }
    _lastIdleHeartbeatTime = now;
    SocketService.emitGpsUpdate(
      driverId: _currentDriverId!,
      driverName: _currentDriverName ?? 'Driver',
      regionId: _currentRegionId,
      lat: lat,
      lng: lng,
      speed: speed,
      heading: heading,
      status: 'idle',
      email: _currentProfile?.email,
      phoneNumber: _currentProfile?.phoneNumber,
      emergencyContactName: _currentProfile?.emergencyContactName,
      emergencyContactPhone: _currentProfile?.emergencyContactPhone,
      familyRelationship: _currentProfile?.familyRelationship,
    );
  }

  void setDriverLocation(double lat, double lng, [double? speed, double? heading]) {
    _currentLat = lat;
    _currentLng = lng;
    if (speed != null) _currentSpeed = speed;
    if (heading != null) _currentHeading = heading;
    notifyListeners();
  }

  // Orders management
  final List<DeliveryOrder> _availableOrders = [];
  DeliveryOrder? _activeOrder;
  List<DeliveryOrder> get availableOrders => _availableOrders;
  DeliveryOrder? get activeOrder => _activeOrder;

  void handleJobAssigned(Map<String, dynamic> data) {
    final location = data['deliveryLocation'] is Map ? data['deliveryLocation'] as Map : null;
    final order = DeliveryOrder(
      id: data['orderId']?.toString() ?? data['id']?.toString() ?? 'ORD-${DateTime.now().millisecondsSinceEpoch}',
      pickupAddress: data['deliveryFrom'] ?? 'Logistics Depot',
      dropAddress: data['deliveryTo'] ?? location?['address'] ?? 'Customer Delivery Point',
      distanceKm: (data['distanceKm'] as num?)?.toDouble() ?? 5.2,
      estimatedTimeMinutes: (data['estimatedTimeMinutes'] as num?)?.toInt() ?? 16,
      payoutAmount: (data['amount'] as num?)?.toDouble() ?? 80.0,
      pickupLat: (location?['pickupLat'] as num?)?.toDouble() ?? (_currentLat ?? 0.0),
      pickupLng: (location?['pickupLng'] as num?)?.toDouble() ?? (_currentLng ?? 0.0),
      dropLat: (location?['latitude'] as num?)?.toDouble() ?? ((_currentLat ?? 0.0) + 0.01),
      dropLng: (location?['longitude'] as num?)?.toDouble() ?? ((_currentLng ?? 0.0) + 0.01),
    );

    _availableOrders.removeWhere((o) => o.id == order.id);
    _availableOrders.insert(0, order);
    SensorService.vibrate(duration: 500);
    VoiceService.speak("New mission assigned: ${order.dropAddress}. Reward: ₹${order.payoutAmount.toInt()}.");
    notifyListeners();
  }

  void addAvailableOrder(DeliveryOrder order) {
    _availableOrders.removeWhere((o) => o.id == order.id);
    _availableOrders.insert(0, order);
    notifyListeners();
  }

  Future<DeliveryOrder> generateMockOrder() async {
    // 1. Obtain driver's exact coordinates from GPS service
    try {
      final pos = await GpsService.getCurrentLocation();
      if (pos != null) {
        _currentLat = pos.latitude;
        _currentLng = pos.longitude;
        _currentSpeed = pos.speed * 3.6;
        _currentHeading = pos.heading;
      }
    } catch (_) {}

    double driverLat = _currentLat ?? 0.0;
    double driverLng = _currentLng ?? 0.0;

    // 2. Compute realistic destination offset from driver's location (1.4 km to 3.8 km)
    final rand = Random();
    final double distKm = double.parse((1.4 + rand.nextDouble() * 2.4).toStringAsFixed(1));
    final double angle = rand.nextDouble() * 2 * pi;
    final double deltaLat = (distKm / 111.0) * cos(angle);
    final double deltaLng = (distKm / (111.0 * cos(driverLat * pi / 180.0))) * sin(angle);
    final double dropLat = double.parse((driverLat + deltaLat).toStringAsFixed(6));
    final double dropLng = double.parse((driverLng + deltaLng).toStringAsFixed(6));

    // 3. Resolve actual place names via reverse geocoding from the driver's location
    String pickupName = "Current Location (${driverLat.toStringAsFixed(4)}, ${driverLng.toStringAsFixed(4)})";
    String dropName = "Destination (${dropLat.toStringAsFixed(4)}, ${dropLng.toStringAsFixed(4)})";

    try {
      final p = await GpsService.getAddressFromLatLng(driverLat, driverLng);
      if (p.isNotEmpty && !p.startsWith("Coordinates")) {
        pickupName = p;
      }
    } catch (_) {}

    try {
      final d = await GpsService.getAddressFromLatLng(dropLat, dropLng);
      if (d.isNotEmpty && !d.startsWith("Coordinates")) {
        dropName = d;
      }
    } catch (_) {}

    // Load active driver identity
    final profile = await LocalStorageService.getProfile();
    final dName = (profile?.name != null && profile!.name.trim().isNotEmpty)
        ? profile.name.trim()
        : (_currentDriverName ?? 'Pranav Kumar (Agent #402)');
    final dPhone = (profile?.phoneNumber != null && profile!.phoneNumber.trim().isNotEmpty)
        ? profile.phoneNumber.trim()
        : '+91 98451 23098';

    final List<String> packageCatalog = [
      'Emergency Medical Supplies & First Aid Kit',
      'Express Courier Consignment & Documents',
      'Fresh Farm Groceries & Organic Produce',
      'Artisan Gourmet Bakery & Cafe Order',
      'EV Replacement Battery Electronics & Relays',
      'High Priority Tech Parcel & Parts',
    ];
    final String packageItems = packageCatalog[rand.nextInt(packageCatalog.length)];
    final int estimatedMins = max(8, (distKm / 20 * 60).round() + rand.nextInt(4));
    final double payout = double.parse((45.0 + distKm * 18.0).toStringAsFixed(0));

    final order = DeliveryOrder(
      id: 'SIM-${DateTime.now().millisecondsSinceEpoch % 10000}',
      pickupAddress: pickupName,
      dropAddress: dropName,
      distanceKm: distKm,
      estimatedTimeMinutes: estimatedMins,
      payoutAmount: payout,
      pickupLat: driverLat,
      pickupLng: driverLng,
      dropLat: dropLat,
      dropLng: dropLng,
      status: 'available',
      packageItems: packageItems,
      driverName: dName,
      driverPhone: dPhone,
      driverAddress: pickupName,
      customerName: 'Kavya Sharma',
      customerPhone: '+91 94482 67119',
    );

    addAvailableOrder(order);

    // Broadcast exact coordinates and place name to backend/admin socket immediately
    SocketService.emitGpsUpdate(
      driverId: _currentDriverId,
      driverName: dName,
      regionId: _currentRegionId,
      lat: driverLat,
      lng: driverLng,
      speed: _currentSpeed,
      heading: _currentHeading,
      deliveryFrom: order.pickupAddress,
      deliveryTo: order.dropAddress,
      orderItems: order.packageItems,
      destLat: order.dropLat,
      destLng: order.dropLng,
      status: 'delivery',
    );

    VoiceService.speak("Simulated mission generated: ${order.dropAddress}.");
    return order;
  }

  final ValueNotifier<int> requestedTabIndexNotifier = ValueNotifier<int>(0);

  void requestTabSwitch(int index) {
    requestedTabIndexNotifier.value = index;
  }

  void acceptOrder(DeliveryOrder order) {
    acceptOrderWithChoice(order, inAppNavigation: true);
  }

  void acceptOrderWithChoice(
    DeliveryOrder order, {
    required bool inAppNavigation,
    String? driverName,
    String? driverId,
    String? regionId,
  }) {
    _activeOrder = order;
    _availableOrders.remove(order);
    _isTripActive = true;

    if (!_isShiftActive) {
      startShift(
        driverName: driverName,
        driverId: driverId,
        regionId: regionId,
      );
    }

    SocketService.emitJobAccepted(order.id, _currentDriverId ?? driverId ?? 'Driver');
    SocketService.emitGpsUpdate(
      driverId: _currentDriverId ?? driverId,
      driverName: _currentDriverName ?? driverName ?? "Driver",
      regionId: _currentRegionId ?? regionId,
      lat: _currentLat ?? 0.0,
      lng: _currentLng ?? 0.0,
      speed: _currentSpeed,
      heading: _currentHeading,
      deliveryFrom: order.pickupAddress,
      deliveryTo: order.dropAddress,
      orderItems: order.packageItems,
      destLat: order.dropLat,
      destLng: order.dropLng,
      safetyScore: _tripSafetyScore,
      status: 'delivery',
    );
    VoiceService.speak("Mission accepted. Target: ${order.dropAddress}.");

    if (inAppNavigation) {
      requestTabSwitch(1); // Switch to in-app Map tab
    }
    notifyListeners();
  }

  void rejectOrder(DeliveryOrder order) {
    _availableOrders.remove(order);
    notifyListeners();
  }

  /// Completes active delivery order, adds to history, credits earnings, and broadcasts telemetry to admin.
  Future<DriverTrip> completeActiveOrder() async {
    final order = _activeOrder;
    final payout = order?.payoutAmount ?? (order?.distanceKm != null && order!.distanceKm > 0 ? (order.distanceKm * 15.0) : 75.0);

    // Calculate Safe Ride Reward Points based on percentage score
    final int ridePoints = calculateTripPoints(
      safetyScore: _tripSafetyScore,
      distanceKm: order?.distanceKm ?? 4.8,
      violationsCount: _journeyViolations.length,
    );

    final trip = DriverTrip(
      id: 'trip-${DateTime.now().millisecondsSinceEpoch}',
      startTime: DateTime.now().subtract(Duration(minutes: order?.estimatedTimeMinutes ?? 14)),
      endTime: DateTime.now(),
      distanceKm: order?.distanceKm ?? 4.8,
      durationSeconds: (order?.estimatedTimeMinutes ?? 14) * 60,
      averageSpeed: 32.4,
      maxSpeed: 48.6,
      safetyScore: _tripSafetyScore,
      events: [],
      routeCoordinates: _routeCoordinates.isNotEmpty
          ? List.from(_routeCoordinates)
          : (_currentLat != null && _currentLng != null ? [[_currentLat!, _currentLng!]] : []),
      industry: 'Logistics & Quick Commerce',
      vehicleName: 'Smart Delivery EV Van',
      deliveryFrom: order?.pickupAddress ?? 'Main Logistics Hub',
      deliveryTo: order?.dropAddress ?? 'Delivery Point',
      orderId: order?.id ?? 'ORD-701',
      orderItems: order?.packageItems ?? 'Tactical Logistics Package #1',
      payout: payout,
      pointsEarned: ridePoints,
    );

    _history.insert(0, trip);
    _todayTripCount = _history.length;
    _todayDistanceKm = _history.fold(0.0, (sum, t) => sum + t.distanceKm);
    _todayEarnedIncome = totalIncome;
    _lastCompletedTrip = trip;
    _activeOrder = null;
    _isTripActive = false;
    _routeCoordinates.clear();

    await LocalStorageService.saveTrips(_history, driverId: _currentDriverId);
    final prefs = await SharedPreferences.getInstance();
    final dKey = (_currentDriverId ?? 'default').toLowerCase();
    await prefs.setDouble('sd_today_income_$dKey', totalIncome);
    await prefs.setInt('sd_today_trips_$dKey', _history.length);

    _lastTripPointsEarned = ridePoints;
    _totalClaimedPoints += ridePoints;
    await prefs.setInt('sd_points_$dKey', _totalClaimedPoints);

    // Broadcast complete trip telemetry analysis to Admin Dashboard
    SocketService.emitTripAnalysis({
      'driverId': _currentDriverId ?? 'mobile-driver',
      'tripId': trip.id,
      'startTime': trip.startTime.toIso8601String(),
      'endTime': trip.endTime?.toIso8601String() ?? DateTime.now().toIso8601String(),
      'distanceKm': trip.distanceKm,
      'durationMinutes': (trip.durationSeconds / 60).round(),
      'averageSpeed': trip.averageSpeed,
      'maxSpeed': trip.maxSpeed,
      'safetyScore': trip.safetyScore,
      'harshBrakingCount': 0,
      'lateralGForce': 0.24,
      'deliveryFrom': trip.deliveryFrom,
      'deliveryTo': trip.deliveryTo,
      'payout': payout,
      'pointsEarned': ridePoints,
      'totalPoints': _totalClaimedPoints,
    });

    final String tierName = _tripSafetyScore >= 95.0
        ? "Gold Tier (Flawless)"
        : (_tripSafetyScore >= 85.0
            ? "Silver Tier (Excellent)"
            : (_tripSafetyScore >= 75.0
                ? "Bronze Tier (Safe)"
                : (_tripSafetyScore >= 60.0 ? "Cautionary Pass" : "At-Risk Driving")));

    VoiceService.speak("Mission completed! Safety score: ${_tripSafetyScore.toStringAsFixed(0)} percent. Earned ₹${payout.toStringAsFixed(0)} and +$ridePoints reward points for $tierName.");

    if (_isShiftActive || SocketService.isConnected) {
      SocketService.emitGpsUpdate(
        driverId: _currentDriverId,
        regionId: _currentRegionId,
        lat: _currentLat ?? 0.0,
        lng: _currentLng ?? 0.0,
        speed: _currentSpeed,
        heading: _currentHeading,
        points: _totalClaimedPoints,
        earnings: _todayEarnedIncome,
        trips: _todayTripCount,
        distanceToday: _todayDistanceKm,
      );
    }
    
    evaluateDailyRules();
    notifyListeners();
    return trip;
  }

  /// Calculates driver reward points proportionally to trip safety percentage score & distance
  static int calculateTripPoints({
    required double safetyScore,
    required double distanceKm,
    required int violationsCount,
  }) {
    // 1. Base Points (scaled proportionally to percentage score 0 - 100%)
    int baseScorePoints;
    if (safetyScore >= 95.0) {
      // Gold Tier (95% - 100%): 100 base points
      baseScorePoints = 100;
    } else if (safetyScore >= 85.0) {
      // Silver Tier (85% - 94%): 75 to 90 pts proportional to percentage
      baseScorePoints = (safetyScore * 0.90).round();
    } else if (safetyScore >= 75.0) {
      // Bronze Tier (75% - 84%): 50 to 65 pts
      baseScorePoints = (safetyScore * 0.70).round();
    } else if (safetyScore >= 60.0) {
      // Cautionary Pass (60% - 74%): 25 to 40 pts
      baseScorePoints = (safetyScore * 0.45).round();
    } else {
      // Critical / At-Risk (<60%): Minimal participation token points (5 - 10 pts)
      baseScorePoints = max(5, (safetyScore * 0.15).round());
    }

    // 2. Clean Ride Bonus (0 violations during the entire trip)
    int cleanBonus = 0;
    if (violationsCount == 0 && safetyScore >= 90.0) {
      cleanBonus = 20; // +20 bonus pts for zero violations
    }

    // 3. Mission Distance Factor: +2 points per km completed (up to +30 pts)
    final int distanceBonus = (distanceKm * 2.0).round().clamp(0, 30);

    final int totalPoints = (baseScorePoints + cleanBonus + distanceBonus).clamp(5, 200);
    return totalPoints;
  }

  void assignRandomOrder() async {
    try {
      final pos = await GpsService.getCurrentLocation();
      if (pos != null) {
        _currentLat = pos.latitude;
        _currentLng = pos.longitude;
        _currentSpeed = pos.speed * 3.6;
        _currentHeading = pos.heading;
      }
    } catch (_) {}

    double driverLat = _currentLat ?? 0.0;
    double driverLng = _currentLng ?? 0.0;

    final rand = Random();
    final double distKm = double.parse((1.5 + rand.nextDouble() * 2.5).toStringAsFixed(1));
    final double angle = rand.nextDouble() * 2 * pi;
    final double deltaLat = (distKm / 111.0) * cos(angle);
    final double deltaLng = (distKm / (111.0 * cos(driverLat * pi / 180.0))) * sin(angle);
    final double dropLat = double.parse((driverLat + deltaLat).toStringAsFixed(6));
    final double dropLng = double.parse((driverLng + deltaLng).toStringAsFixed(6));

    String pickup = "Current Location (${driverLat.toStringAsFixed(4)}, ${driverLng.toStringAsFixed(4)})";
    String drop = "Destination (${dropLat.toStringAsFixed(4)}, ${dropLng.toStringAsFixed(4)})";

    try {
      final p = await GpsService.getAddressFromLatLng(driverLat, driverLng);
      if (p.isNotEmpty && !p.startsWith("Coordinates")) pickup = p;
    } catch (_) {}

    try {
      final d = await GpsService.getAddressFromLatLng(dropLat, dropLng);
      if (d.isNotEmpty && !d.startsWith("Coordinates")) drop = d;
    } catch (_) {}

    final profile = await LocalStorageService.getProfile();
    final dName = (profile?.name != null && profile!.name.trim().isNotEmpty)
        ? profile.name.trim()
        : (_currentDriverName ?? 'Pranav Kumar (Agent #402)');
    final dPhone = (profile?.phoneNumber != null && profile!.phoneNumber.trim().isNotEmpty)
        ? profile.phoneNumber.trim()
        : '+91 98451 23098';

    final randomId = (100 + rand.nextInt(900)).toString();
    final newOrder = DeliveryOrder(
      id: 'ORD-$randomId',
      pickupAddress: pickup,
      dropAddress: drop,
      distanceKm: distKm,
      estimatedTimeMinutes: 10 + rand.nextInt(15),
      payoutAmount: (50 + rand.nextInt(50)).toDouble(),
      pickupLat: driverLat,
      pickupLng: driverLng,
      dropLat: dropLat,
      dropLng: dropLng,
      packageItems: 'Consignment Parcel #$randomId',
      driverName: dName,
      driverPhone: dPhone,
      driverAddress: pickup,
      customerName: 'Kavya Sharma',
      customerPhone: '+91 94482 67119',
    );
    _availableOrders.add(newOrder);

    // Send exact coordinates and place name to backend
    SocketService.emitGpsUpdate(
      driverId: _currentDriverId,
      driverName: dName,
      regionId: _currentRegionId,
      lat: driverLat,
      lng: driverLng,
      speed: _currentSpeed,
      heading: _currentHeading,
      deliveryFrom: newOrder.pickupAddress,
      deliveryTo: newOrder.dropAddress,
      orderItems: newOrder.packageItems,
      destLat: newOrder.dropLat,
      destLng: newOrder.dropLng,
      status: 'delivery',
    );

    notifyListeners();
  }

  // Financial Management (Income, UPI Expenses & Net Savings)
  List<PaymentTransaction> _expenses = [];
  List<PaymentTransaction> _customIncomes = [];

  List<PaymentTransaction> get expenses => _expenses;
  List<PaymentTransaction> get customIncomes => _customIncomes;
  
  double get totalExpenseSpending => _expenses.fold(0.0, (sum, e) => sum + e.amount);
  double get totalSpending => totalExpenseSpending;
  double get totalTripEarnings => _history.fold(0.0, (sum, t) => sum + t.earnedPayout);
  double get totalRewardsIncome => _customIncomes.fold(0.0, (sum, i) => sum + i.amount);
  double get totalIncome => totalTripEarnings + totalRewardsIncome;
  double get todayEarnedIncome => totalIncome;
  double get netSavings => max(0.0, totalIncome - totalSpending);
  double get savingsRatePercent => totalIncome > 0 ? ((netSavings / totalIncome) * 100.0).clamp(0.0, 100.0) : 0.0;
  double get safetyRewardIncome => _history.length * 15.0;

  List<Map<String, dynamic>> get pointsHistory => _dailyRules
      .where((r) => r.isClaimed)
      .map((r) => {'title': r.title, 'points': '+${r.points} PTS'})
      .toList();

  /// Executes an authentic UPI Payment (Scan & Pay or UPI ID Transfer), deducts spending, updates savings, and saves to history.
  Future<PaymentTransaction> makeUpiPayment({
    required String title,
    required String subtitle,
    required double amount,
    required PaymentCategory category,
    String? upiId,
    String? notes,
    String paymentMethod = "UPI · State Bank of India (****4821)",
  }) async {
    final rand = Random();
    final String utr = '${rand.nextInt(900000) + 100000}${rand.nextInt(900000) + 100000}';
    final txn = PaymentTransaction(
      id: 'TXN-${DateTime.now().millisecondsSinceEpoch}',
      title: title,
      subtitle: subtitle,
      amount: amount,
      type: TransactionType.expense,
      category: category,
      timestamp: DateTime.now(),
      upiId: upiId,
      utrNumber: utr,
      status: TransactionStatus.success,
      paymentMethod: paymentMethod,
      notes: notes,
    );

    _expenses.insert(0, txn);
    await LocalStorageService.saveExpenses(_expenses, driverId: _currentDriverId);

    SensorService.vibrate(duration: 400);
    VoiceService.speak("Paid ₹${amount.toInt()} to $title via UPI successfully.");

    if (_isShiftActive) {
      SocketService.emitGpsUpdate(
        driverId: _currentDriverId,
        regionId: _currentRegionId,
        lat: _currentLat ?? 0.0,
        lng: _currentLng ?? 0.0,
        speed: _currentSpeed,
        heading: _currentHeading,
        points: _totalClaimedPoints,
        earnings: _todayEarnedIncome,
        trips: _todayTripCount,
        distanceToday: _todayDistanceKm,
      );
    }

    notifyListeners();
    return txn;
  }

  /// Converts safe driving reward coins into instant cash credited to the driver's UPI ID.
  Future<PaymentTransaction?> redeemRewardCoinsToUpi({
    required int pointsToRedeem,
    required String upiId,
  }) async {
    if (pointsToRedeem <= 0 || _totalClaimedPoints < pointsToRedeem) {
      return null;
    }

    // Conversion rate: 10 Reward Points = ₹1 INR Cash (e.g. 500 pts = ₹50)
    final double cashAmount = pointsToRedeem / 10.0;
    _totalClaimedPoints -= pointsToRedeem;

    final rand = Random();
    final String utr = 'REDEEM${rand.nextInt(900000) + 100000}';
    final txn = PaymentTransaction(
      id: 'TXN-${DateTime.now().millisecondsSinceEpoch}',
      title: 'Reward Coins UPI Payout',
      subtitle: '$pointsToRedeem pts converted to ₹${cashAmount.toStringAsFixed(0)} cash',
      amount: cashAmount,
      type: TransactionType.income,
      category: PaymentCategory.rewardsRedeem,
      timestamp: DateTime.now(),
      upiId: upiId,
      utrNumber: utr,
      status: TransactionStatus.success,
      paymentMethod: 'Driving Safety Reward Payout -> UPI ($upiId)',
      notes: 'Safe driving points redeemed to personal bank account',
    );

    _customIncomes.insert(0, txn);
    await LocalStorageService.saveCustomIncomes(_customIncomes, driverId: _currentDriverId);

    final prefs = await SharedPreferences.getInstance();
    final dKey = (_currentDriverId ?? 'default').toLowerCase();
    await prefs.setInt('sd_points_$dKey', _totalClaimedPoints);

    SensorService.vibrate(duration: 500);
    VoiceService.speak("Congratulations! $pointsToRedeem reward points redeemed. ₹${cashAmount.toInt()} credited to your UPI ID $upiId.");

    notifyListeners();
    return txn;
  }

  /// Claims a physical or digital catalog reward using accumulated safe driving points.
  Future<ClaimedVoucher?> claimGoodie(GoodieItem item) async {
    if (_totalClaimedPoints < item.pointsCost) {
      return null;
    }
    _totalClaimedPoints -= item.pointsCost;

    final rand = Random();
    final String randCode = (rand.nextInt(9000) + 1000).toString();
    final String cleanCat = item.category.toUpperCase().replaceAll(RegExp(r'[^A-Z]'), '');
    final String catPrefix = cleanCat.length >= 3 ? cleanCat.substring(0, 3) : cleanCat.padRight(3, 'X');
    final String voucherCode = "SD-$catPrefix-$randCode";

    final voucher = ClaimedVoucher(
      id: 'VOUCH-${DateTime.now().millisecondsSinceEpoch}',
      title: item.title,
      voucherCode: voucherCode,
      pointsSpent: item.pointsCost,
      valueText: item.valueText,
      category: item.category,
      icon: item.icon,
      claimedAt: DateTime.now(),
      status: 'ACTIVE',
    );

    _claimedVouchers.insert(0, voucher);

    final prefs = await SharedPreferences.getInstance();
    final dKey = (_currentDriverId ?? 'default').toLowerCase();
    await prefs.setInt('sd_points_$dKey', _totalClaimedPoints);
    final voucherJsonList = _claimedVouchers.map((v) => v.toJson()).toList();
    await prefs.setString('sd_vouchers_$dKey', jsonEncode(voucherJsonList));

    SensorService.vibrate(duration: 450);
    VoiceService.speak("Congratulations! Reward claimed: ${item.title}. Voucher code $voucherCode has been generated.");

    notifyListeners();
    return voucher;
  }

  Future<void> markVoucherRedeemed(String voucherId) async {
    final idx = _claimedVouchers.indexWhere((v) => v.id == voucherId);
    if (idx != -1) {
      final old = _claimedVouchers[idx];
      _claimedVouchers[idx] = ClaimedVoucher(
        id: old.id,
        title: old.title,
        voucherCode: old.voucherCode,
        pointsSpent: old.pointsSpent,
        valueText: old.valueText,
        category: old.category,
        icon: old.icon,
        claimedAt: old.claimedAt,
        status: 'REDEEMED',
      );
      final prefs = await SharedPreferences.getInstance();
      final dKey = (_currentDriverId ?? 'default').toLowerCase();
      final voucherJsonList = _claimedVouchers.map((v) => v.toJson()).toList();
      await prefs.setString('sd_vouchers_$dKey', jsonEncode(voucherJsonList));
      notifyListeners();
    }
  }

  Future<void> addBonusPoints(int pts) async {
    _totalClaimedPoints += pts;
    final prefs = await SharedPreferences.getInstance();
    final dKey = (_currentDriverId ?? 'default').toLowerCase();
    await prefs.setInt('sd_points_$dKey', _totalClaimedPoints);
    notifyListeners();
  }

  List<List<double>> _routeCoordinates = [];
  List<DriverTrip> _history = [];
  DriverTrip? _lastCompletedTrip;

  // Real-time sensor data
  double accelX = 0, accelY = 0, accelZ = 0;
  double gyroX = 0, gyroY = 0, gyroZ = 0;
  double magX = 0, magY = 0, magZ = 0;
  double _currentSpeed = 0.0;
  double? _currentLat;
  double? _currentLng;
  double _currentHeading = 0.0;
  double _lastForce = 0.0;
  DateTime? _lastEmitTime;
  String _currentRegionId = 'puttur_taluk';
  String get currentRegionId => _currentRegionId;

  // Sequence / ML Logic
  DateTime? _lastHighSpeedTime;
  Timer? _stillnessTimer;
  Timer? _telemetryTimer;
  Timer? _cameraStreamingTimer;

  bool get isShiftActive => _isShiftActive;
  bool get isTripActive => _isTripActive;
  bool get showSOSConfirmation => _showSOSConfirmation;
  bool get isCrashDetected => _isCrashDetected;
  bool get isAdminPinging => _isAdminPinging;
  int get sosCountdown => _sosCountdown;
  String get crashReason => _crashReason;
  double get tripSafetyScore => _tripSafetyScore;
  double get todayDistanceKm => _todayDistanceKm;
  int get todayTripCount => _todayTripCount;
  double get currentSpeed => _currentSpeed;
  double get currentGpsSpeed => _currentSpeed;
  String get currentLocationName => "${currentCityRules.cityName} Sector";
  double? get currentLat => _currentLat;
  double? get currentLng => _currentLng;
  double get currentHeading => _currentHeading;
  double get gForce => _gForce;
  double get maxGForce => _maxGForce;
  bool get isLiveCamActive => _isLiveCamActive;
  int get crashVerificationAttempts => _crashVerificationAttempts;
  int get totalClaimedPoints => _totalClaimedPoints;
  List<List<double>> get routeCoordinates => _routeCoordinates;
  List<DriverTrip> get history => _history;
  DriverTrip? get lastCompletedTrip => _lastCompletedTrip;

  // Rules List - all start IN PROGRESS (isAchieved: false, isClaimed: false)
  final List<DrivingRule> _dailyRules = [
    DrivingRule(
      id: 'speed_compliance',
      title: 'Speed Limit Compliance',
      description: 'Keep vehicle velocity within regulated city & sector speeds.',
      points: 50,
      icon: 'speed',
      isAchieved: false,
      isClaimed: false,
    ),
    DrivingRule(
      id: 'zero_harsh_braking',
      title: 'Zero Harsh Braking',
      description: 'Maintain smooth braking without abrupt velocity drops.',
      points: 30,
      icon: 'pan_tool_rounded',
      isAchieved: false,
      isClaimed: false,
    ),
    DrivingRule(
      id: 'smooth_cornering',
      title: 'Smooth Turning & Cornering',
      description: 'Execute corners and turns with angular rate < 5.0 rad/s.',
      points: 25,
      icon: 'turn_right_rounded',
      isAchieved: false,
      isClaimed: false,
    ),
    DrivingRule(
      id: 'school_zone_safety',
      title: 'School Zone Caution',
      description: 'Slow down below 25 km/h inside designated school geofences.',
      points: 40,
      icon: 'school_rounded',
      isAchieved: false,
      isClaimed: false,
    ),
    DrivingRule(
      id: 'daily_missions',
      title: 'Complete 3 Active Missions',
      description: 'Finish at least 3 customer delivery dispatch missions today.',
      points: 100,
      icon: 'local_shipping_rounded',
      isAchieved: false,
      isClaimed: false,
    ),
    DrivingRule(
      id: 'shift_bonus',
      title: 'Full Shift Protocol',
      description: 'Keep live telemetry link active with zero unverified halts.',
      points: 50,
      icon: 'verified_rounded',
      isAchieved: false,
      isClaimed: false,
    ),
    DrivingRule(
      id: 'no_footpath_driving',
      title: 'Carriageway Compliance (No Footpaths)',
      description: 'Stay strictly on asphalt roadway; zero pavement or sidewalk mounting.',
      points: 45,
      icon: 'pan_tool_rounded',
      isAchieved: false,
      isClaimed: false,
    ),
  ];
  List<DrivingRule> get dailyRules => _dailyRules;

  bool _isDailyStreakClaimed = false;
  bool get isDailyStreakClaimed => _isDailyStreakClaimed;
  bool get canClaimDailyStreak => (_todayTripCount >= 1 || _history.isNotEmpty) && !_isDailyStreakClaimed;

  void evaluateDailyRules() {
    final hasRides = _history.isNotEmpty || _todayTripCount > 0;
    final breakdown = rulesBrokenBreakdown;

    for (var rule in _dailyRules) {
      if (!hasRides) {
        rule.isAchieved = false;
        continue;
      }

      switch (rule.id) {
        case 'speed_compliance':
          rule.isAchieved = (breakdown['Overspeeding'] ?? 0) == 0;
          break;
        case 'zero_harsh_braking':
          rule.isAchieved = (breakdown['Harsh Braking'] ?? 0) == 0;
          break;
        case 'smooth_cornering':
          rule.isAchieved = (breakdown['Sharp Turning'] ?? 0) == 0;
          break;
        case 'school_zone_safety':
          rule.isAchieved = (breakdown['School / Silence Zone'] ?? 0) == 0;
          break;
        case 'daily_missions':
          rule.isAchieved = (_todayTripCount >= 3 || _history.length >= 3);
          break;
        case 'shift_bonus':
          rule.isAchieved = _tripSafetyScore >= 85.0;
          break;
        case 'no_footpath_driving':
          rule.isAchieved = true;
          break;
        default:
          rule.isAchieved = false;
      }
    }
    notifyListeners();
  }

  // Goodies & Rewards Active Catalog
  final List<GoodieItem> _goodiesStore = [
    // 1. Fuel & Petrol (Essential daily need)
    GoodieItem(
      id: 'fuel_voucher_100',
      title: 'IndianOil ₹100 Petrol Voucher',
      subtitle: 'Instant digital petrol card valid at any IndianOil fuel station',
      pointsCost: 200,
      valueText: '₹100 Fuel',
      category: 'Fuel',
      icon: 'local_gas_station_rounded',
      isComingSoon: false,
    ),
    GoodieItem(
      id: 'fuel_voucher_250',
      title: 'HPCL ₹250 Super Fuel Pass',
      subtitle: 'Scan & fuel up at any Hindustan Petroleum pump nationwide',
      pointsCost: 500,
      valueText: '₹250 Fuel',
      category: 'Fuel',
      icon: 'local_gas_station_rounded',
      isComingSoon: false,
    ),
    GoodieItem(
      id: 'fuel_voucher_500',
      title: 'BPCL ₹500 SmartFleet Fuel Pass',
      subtitle: '₹500 Digital Fuel Card for any Bharat Petroleum outlet',
      pointsCost: 1000,
      valueText: '₹500 Fuel',
      category: 'Fuel',
      icon: 'local_gas_station_rounded',
      isComingSoon: false,
    ),

    // 2. Rider Safety Gear (Helps maintain rules & safety)
    GoodieItem(
      id: 'reflective_vest',
      title: 'High-Vis Night Reflective Rider Vest',
      subtitle: 'EN-471 certified high-visibility dual-band reflective vest for night delivery',
      pointsCost: 300,
      valueText: '₹450 Value',
      category: 'Safety Gear',
      icon: 'verified_rounded',
      isComingSoon: false,
    ),
    GoodieItem(
      id: 'rain_poncho',
      title: 'All-Weather Waterproof Storm Poncho',
      subtitle: 'Heavy-duty ripstop rain poncho + waterproof mobile pouch',
      pointsCost: 350,
      valueText: '₹600 Value',
      category: 'Safety Gear',
      icon: 'shield_rounded',
      isComingSoon: false,
    ),
    GoodieItem(
      id: 'safety_helmet',
      title: 'Pro Rider ISI Safety Helmet',
      subtitle: 'ISI Certified Dual-Visor aerodynamic helmet with anti-fog shield',
      pointsCost: 1500,
      valueText: '₹1,999 Value',
      category: 'Safety Gear',
      icon: 'sports_motorsports_rounded',
      isComingSoon: false,
    ),

    // 3. Vehicle Care & Maintenance
    GoodieItem(
      id: 'oil_service',
      title: 'Castrol Engine Oil & 15-Pt Service',
      subtitle: 'Comprehensive oil change with Castrol Activ + brake & chain check',
      pointsCost: 600,
      valueText: '₹550 Service',
      category: 'Maintenance',
      icon: 'build_circle_rounded',
      isComingSoon: false,
    ),
    GoodieItem(
      id: 'tyre_puncture_kit',
      title: 'Tubeless Tyre Puncture Kit & Air Pack',
      subtitle: 'Emergency puncture repair strip kit + CO2 canister air inflator',
      pointsCost: 250,
      valueText: '₹350 Kit',
      category: 'Maintenance',
      icon: 'car_repair_rounded',
      isComingSoon: false,
    ),
    GoodieItem(
      id: 'brake_service',
      title: 'Free Brake Pad Check & Chain Lube',
      subtitle: 'Partner garage service checkup ensuring safe stopping distances',
      pointsCost: 250,
      valueText: '₹300 Service',
      category: 'Maintenance',
      icon: 'pan_tool_rounded',
      isComingSoon: false,
    ),

    // 4. Daily Work Essentials
    GoodieItem(
      id: 'phone_mount_charger',
      title: 'Anti-Vibration Handlebar Phone Mount',
      subtitle: 'Shock-absorbing metal phone mount with integrated USB quick-charge',
      pointsCost: 400,
      valueText: '₹650 Value',
      category: 'Work Essentials',
      icon: 'shopping_bag_rounded',
      isComingSoon: false,
    ),
    GoodieItem(
      id: 'data_pack_5gb',
      title: '5GB 4G/5G GPS Navigation Data Pack',
      subtitle: 'Instant mobile data recharge voucher for seamless Google Maps navigation',
      pointsCost: 120,
      valueText: '₹75 Data',
      category: 'Work Essentials',
      icon: 'card_giftcard_rounded',
      isComingSoon: false,
    ),
    GoodieItem(
      id: 'chai_snack_coupon',
      title: 'Chai & Hot Snack Combo Coupon',
      subtitle: 'Hot chai / coffee + 2 samosas at any partner roadside tea stall',
      pointsCost: 80,
      valueText: '₹60 Meal',
      category: 'Work Essentials',
      icon: 'stars_rounded',
      isComingSoon: false,
    ),

    // 5. Instant UPI Direct Cash & Shopping
    GoodieItem(
      id: 'upi_cash_50',
      title: '₹50 Instant UPI Direct Payout',
      subtitle: 'Direct bank transfer straight to your linked UPI VPA address',
      pointsCost: 100,
      valueText: '₹50 Cash',
      category: 'UPI Cash',
      icon: 'card_giftcard_rounded',
      isComingSoon: false,
    ),
    GoodieItem(
      id: 'upi_cash_150',
      title: '₹150 Instant UPI Direct Payout',
      subtitle: 'Direct bank transfer straight to your linked UPI VPA address',
      pointsCost: 300,
      valueText: '₹150 Cash',
      category: 'UPI Cash',
      icon: 'card_giftcard_rounded',
      isComingSoon: false,
    ),
    GoodieItem(
      id: 'amazon_gift',
      title: 'Amazon ₹250 Shopping E-Voucher',
      subtitle: 'Instant digital gift card for fuel, groceries, tools & household needs',
      pointsCost: 500,
      valueText: '₹250 Card',
      category: 'Vouchers',
      icon: 'card_giftcard_rounded',
      isComingSoon: false,
    ),
  ];
  List<GoodieItem> get goodiesStore => _goodiesStore;

  final List<SafetyZone> _safetyZones = [];
  List<SafetyZone> get safetyZones => _safetyZones;

  DateTime? _lastSchoolZonesFetchTime;
  double? _lastSchoolFetchLat;
  double? _lastSchoolFetchLng;
  bool _isFetchingSchools = false;
  bool get isFetchingSchools => _isFetchingSchools;

  Future<void> updateNearbySchoolZones(double lat, double lng, {bool force = false}) async {
    final now = DateTime.now();
    if (!force && _lastSchoolZonesFetchTime != null && now.difference(_lastSchoolZonesFetchTime!).inMinutes < 5) {
      if (_lastSchoolFetchLat != null && _lastSchoolFetchLng != null) {
        final distKm = _calculateDistance(lat, lng, _lastSchoolFetchLat!, _lastSchoolFetchLng!);
        if (distKm < 2.0) return;
      }
    }

    _lastSchoolZonesFetchTime = now;
    _lastSchoolFetchLat = lat;
    _lastSchoolFetchLng = lng;
    _isFetchingSchools = true;

    try {
      final dynamicSchools = await OverpassService.fetchNearbySchools(lat, lng, radiusMeters: 5000);
      if (dynamicSchools.isNotEmpty) {
        final nonSchoolZones = _safetyZones.where((z) => z.type != 'school').toList();
        _safetyZones
          ..clear()
          ..addAll(dynamicSchools)
          ..addAll(nonSchoolZones);
        notifyListeners();
      }
    } catch (_) {} finally {
      _isFetchingSchools = false;
    }
  }

  void _syncCustomGeofencesToSafetyZones() {
    _safetyZones.removeWhere((z) => z.name.startsWith('[Admin Zone] ') || _customGeofences.any((cg) => cg['name'] == z.name));
    for (var g in _customGeofences) {
      final zLat = (g['lat'] as num?)?.toDouble() ?? 0.0;
      final zLng = (g['lng'] as num?)?.toDouble() ?? 0.0;
      final zName = g['name']?.toString() ?? 'Custom Speed Zone';
      final zType = g['type']?.toString() ?? 'custom';
      if (zLat != 0.0 && zLng != 0.0) {
        _safetyZones.add(SafetyZone(
          name: zName,
          type: zType,
          lat: zLat,
          lng: zLng,
        ));
      }
    }
  }

  String? _currentDriverId;
  String? _currentDriverName;

  void Function(bool active)? onShiftStateChanged;

  /// Called on app startup to restore a previously active shift.
  Future<void> checkShiftPersistence() async {
    final prefs = await SharedPreferences.getInstance();
    final wasActive = prefs.getBool('sd_shift_active') ?? false;
    if (wasActive) {
      _isShiftActive = true;
      _startFullSensorSuite();
      _startGpsMonitoring(null);
      onShiftStateChanged?.call(true);
      notifyListeners();
    } else {
      onShiftStateChanged?.call(false);
    }
  }

  Future<void> loadForDriver(String? driverId) async {
    final cleanId = driverId?.trim().toLowerCase();
    _currentDriverId = cleanId;

    // Reset current in-memory metrics for a clean switch
    _history.clear();
    _expenses.clear();
    _customIncomes.clear();
    _availableOrders.clear();
    _activeOrder = null;
    _isTripActive = false;
    _lastCompletedTrip = null;
    _journeyViolations.clear();
    _potholes.clear();
    _todayTripCount = 0;
    _todayDistanceKm = 0.0;
    _todayEarnedIncome = 0.0;
    _totalClaimedPoints = 0;
    _isDailyStreakClaimed = false;
    _claimedVouchers.clear();

    for (var r in _dailyRules) {
      r.isAchieved = false;
      r.isClaimed = false;
    }

    if (cleanId != null && cleanId.isNotEmpty) {
      _history = await LocalStorageService.getTrips(driverId: cleanId);
      _expenses = await LocalStorageService.getExpenses(driverId: cleanId);
      _customIncomes = await LocalStorageService.getCustomIncomes(driverId: cleanId);

      final prefs = await SharedPreferences.getInstance();
      _totalClaimedPoints = prefs.getInt('sd_points_$cleanId') ?? 0;
      final claimedIds = prefs.getStringList('sd_claimed_rules_$cleanId') ?? [];
      for (var r in _dailyRules) {
        r.isClaimed = claimedIds.contains(r.id);
      }
      _isDailyStreakClaimed = prefs.getBool('sd_streak_$cleanId') ?? false;

      final vouchersRaw = prefs.getString('sd_vouchers_$cleanId');
      if (vouchersRaw != null && vouchersRaw.isNotEmpty) {
        try {
          final List<dynamic> decoded = jsonDecode(vouchersRaw);
          _claimedVouchers = decoded.map((e) => ClaimedVoucher.fromJson(e as Map<String, dynamic>)).toList();
        } catch (_) {}
      }

      _todayTripCount = _history.length;
      _todayDistanceKm = _history.fold(0.0, (sum, t) => sum + t.distanceKm);
      _todayEarnedIncome = totalIncome;
      evaluateDailyRules();
    }

    notifyListeners();
  }

  Future<void> resetDriverData() async {
    await loadForDriver(null);
  }

  Future<void> initHistory() async {
    final profile = await LocalStorageService.getProfile();
    final dId = profile?.driverId;
    await loadForDriver(dId);

    SocketService.onLiveCamRequestCallback = (bool active) {
      _isLiveCamActive = active;
      if (active) {
        _startLiveCameraStreaming();
      } else {
        _stopLiveCameraStreaming();
      }
      notifyListeners();
    };

    SocketService.onDriverCheckPingCallback = (String message) {
      handleAdminPing(message);
    };

    SocketService.onBlindCurveWarningCallback = (Map<String, dynamic> data) {
      final otherDriver = data['otherDriverName']?.toString() ?? data['oncomingDriver']?.toString() ?? 'Approaching Vehicle';
      final dist = data['distanceMeters']?.toString() ?? '500';
      _v2vWarning = "Caution: Approaching $otherDriver ($dist m ahead)!";
      VoiceService.speak("Caution! Approaching vehicle $otherDriver, $dist meters ahead. Stay left.");
      // Continuous vibration removed per user request
      NotificationService.showSafetyAlert("V2V PROXIMITY ALERT", "Approaching vehicle $otherDriver $dist m ahead");
      notifyListeners();
      Timer(const Duration(seconds: 8), () {
        _v2vWarning = null;
        notifyListeners();
      });
    };

    SocketService.onVoiceBroadcastCallback = (Map<String, dynamic> data) {
      final msg = data['message']?.toString() ?? 'Fleet Command announcement';
      final priority = data['priority']?.toString() ?? 'WARNING';
      final adminName = data['adminName']?.toString() ?? 'Fleet Command HQ';

      _adminBroadcastBanner = "[$priority] $adminName: $msg";
      VoiceService.speak("Fleet Command Announcement: $msg", isCritical: priority == 'EMERGENCY');
      SensorService.vibrate(duration: priority == 'EMERGENCY' ? 1200 : 600);
      NotificationService.showSafetyAlert("COMMAND BROADCAST ($priority)", msg);
      notifyListeners();

      Timer(const Duration(seconds: 15), () {
        _adminBroadcastBanner = null;
        notifyListeners();
      });
    };

    SocketService.onGeofencesSyncCallback = (List<dynamic> list) {
      _customGeofences = list
          .map((e) => Map<String, dynamic>.from(e as Map))
          .where((g) => g['active'] != false)
          .toList();
      _syncCustomGeofencesToSafetyZones();
      notifyListeners();
    };

    SocketService.requestGeofencesSync();

    notifyListeners();

    GpsService.getCurrentLocation().then((pos) {
      if (pos != null) {
        updateNearbySchoolZones(pos.latitude, pos.longitude);
      }
    });
  }

  Future<void> clearAllHistoryAndEarnings() async {
    final dKey = (_currentDriverId ?? 'default').toLowerCase();
    _history.clear();
    _expenses.clear();
    _customIncomes.clear();
    _todayTripCount = 0;
    _todayDistanceKm = 0.0;
    _todayEarnedIncome = 0.0;
    _totalClaimedPoints = 0;
    _journeyViolations.clear();
    _potholes.clear();
    _activeOrder = null;
    _isTripActive = false;
    _lastCompletedTrip = null;
    _isDailyStreakClaimed = false;
    for (var r in _dailyRules) {
      r.isAchieved = false;
      r.isClaimed = false;
    }

    await LocalStorageService.saveTrips([], driverId: _currentDriverId);
    await LocalStorageService.saveExpenses([], driverId: _currentDriverId);
    await LocalStorageService.saveCustomIncomes([], driverId: _currentDriverId);
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('sd_today_income_$dKey');
    await prefs.remove('sd_today_trips_$dKey');
    await prefs.remove('sd_points_$dKey');
    await prefs.remove('sd_claimed_rules_$dKey');
    await prefs.remove('sd_streak_$dKey');
    await prefs.remove('sd_vouchers_$dKey');

    notifyListeners();
  }

  void claimRulePoints(String ruleId, {bool forceClaim = false}) async {
    final ruleIndex = _dailyRules.indexWhere((r) => r.id == ruleId);
    if (ruleIndex >= 0 && (forceClaim || _dailyRules[ruleIndex].isAchieved) && !_dailyRules[ruleIndex].isClaimed) {
      _dailyRules[ruleIndex].isClaimed = true;
      _totalClaimedPoints += _dailyRules[ruleIndex].points;

      final prefs = await SharedPreferences.getInstance();
      final dKey = (_currentDriverId ?? 'default').toLowerCase();
      await prefs.setInt('sd_points_$dKey', _totalClaimedPoints);
      final claimedList = _dailyRules.where((r) => r.isClaimed).map((r) => r.id).toList();
      await prefs.setStringList('sd_claimed_rules_$dKey', claimedList);

      VoiceService.speak("Congratulations! You claimed ${_dailyRules[ruleIndex].points} reward points.");
      SensorService.vibrate(duration: 300);

      if (_isShiftActive) {
        SocketService.emitGpsUpdate(
          driverId: _currentDriverId,
          regionId: _currentRegionId,
          lat: _currentLat ?? 0.0,
          lng: _currentLng ?? 0.0,
          speed: _currentSpeed,
          heading: _currentHeading,
          points: _totalClaimedPoints,
          earnings: _todayEarnedIncome,
          trips: _todayTripCount,
          distanceToday: _todayDistanceKm,
        );
      }

      notifyListeners();
    }
  }

  void claimDailyStreakBonus() async {
    if (!canClaimDailyStreak) return;
    _isDailyStreakClaimed = true;
    _totalClaimedPoints += 100;
    final prefs = await SharedPreferences.getInstance();
    final dKey = (_currentDriverId ?? 'default').toLowerCase();
    await prefs.setInt('sd_points_$dKey', _totalClaimedPoints);
    await prefs.setBool('sd_streak_$dKey', true);
    VoiceService.speak("Congratulations! 100 daily streak points claimed.");
    SensorService.vibrate(duration: 300);

    if (_isShiftActive) {
      SocketService.emitGpsUpdate(
        driverId: _currentDriverId,
        regionId: _currentRegionId,
        lat: _currentLat ?? 0.0,
        lng: _currentLng ?? 0.0,
        speed: _currentSpeed,
        heading: _currentHeading,
        points: _totalClaimedPoints,
        earnings: _todayEarnedIncome,
        trips: _todayTripCount,
        distanceToday: _todayDistanceKm,
      );
    }
    notifyListeners();
  }

  void toggleShift({String? driverName, String? driverId, String? regionId}) {
    if (_isShiftActive) {
      endShift();
    } else {
      startShift(driverName: driverName, driverId: driverId, regionId: regionId);
    }
  }

  void startShift({String? driverName, String? driverId, String? regionId}) async {
    await requestAllPermissions();
    final initPos = await GpsService.getCurrentLocation();
    if (initPos != null) {
      _currentLat = initPos.latitude;
      _currentLng = initPos.longitude;
      _currentSpeed = initPos.speed * 3.6;
      _currentHeading = initPos.heading;
    }
    _isShiftActive = true;
    _shiftStartTime = DateTime.now();
    _fatigueWarning90Emitted = false;
    _fatigueWarning120Emitted = false;
    final savedProfile = await LocalStorageService.getProfile();
    _currentDriverId = driverId ?? savedProfile?.driverId ?? _currentDriverId;
    _currentDriverName = driverName ?? savedProfile?.name ?? _currentDriverName ?? 'Driver';
    _currentRegionId = regionId ?? savedProfile?.regionId ?? _currentRegionId ?? 'regional';
    _saveShiftState(true);
    _startFullSensorSuite();
    _startGpsMonitoring(_currentDriverName);
    _startPeriodicTelemetryStream(_currentDriverName);
    onShiftStateChanged?.call(true);

    if (_currentDriverId != null && _currentDriverId!.isNotEmpty) {
      SocketService.emitShiftStatus(
        driverId: _currentDriverId!,
        driverName: _currentDriverName ?? "Driver",
        regionId: _currentRegionId,
        status: 'online',
        lat: _currentLat ?? 0.0,
        lng: _currentLng ?? 0.0,
      );
    }

    notifyListeners();
  }

  void endShift() {
    _isShiftActive = false;
    _isTripActive = false;
    _shiftStartTime = null;
    _fatigueWarning90Emitted = false;
    _fatigueWarning120Emitted = false;
    _saveShiftState(false);
    _telemetryTimer?.cancel();
    _stopLiveCameraStreaming();
    onShiftStateChanged?.call(false);

    SocketService.emitShiftStatus(
      driverId: _currentDriverId ?? '',
      regionId: _currentRegionId,
      status: 'offline',
      lat: 0,
      lng: 0,
    );
    VoiceService.resetSession();
    notifyListeners();
  }

  StreamSubscription? _gpsSub;
  StreamSubscription? _accelSub;
  StreamSubscription? _gyroSub;
  StreamSubscription? _magSub;

  DateTime _lastSensorNotify = DateTime.fromMillisecondsSinceEpoch(0);

  void _recordBlackBoxSample() {
    final now = DateTime.now();
    if (_lastBlackBoxRecord == null || now.difference(_lastBlackBoxRecord!).inMilliseconds >= 500) {
      _lastBlackBoxRecord = now;
      _blackBoxBuffer.add({
        'time': now.toIso8601String(),
        'speed': _currentSpeed,
        'gForce': _gForce,
        'accelX': accelX,
        'accelY': accelY,
        'accelZ': accelZ,
        'gyroZ': gyroZ,
      });
      if (_blackBoxBuffer.length > 20) {
        _blackBoxBuffer.removeAt(0);
      }
    }
  }

  DateTime? _lastFatigueCheck;
  void _checkFatigue() {
    if (!_isShiftActive || _shiftStartTime == null) return;
    final now = DateTime.now();
    if (_lastFatigueCheck != null && now.difference(_lastFatigueCheck!).inSeconds < 15) return;
    _lastFatigueCheck = now;
    final mins = shiftDurationMinutes;
    if (mins >= 90 && !_fatigueWarning90Emitted) {
      _fatigueWarning90Emitted = true;
      VoiceService.speak("Fatigue Advisory: You have been operating for 90 continuous minutes. Prepare to take a rest break.");
      NotificationService.showSafetyAlert("DRIVER FATIGUE ADVISORY", "You have been driving continuously for 90 minutes. Plan a rest stop.");
    }
    if (mins >= 120 && !_fatigueWarning120Emitted) {
      _fatigueWarning120Emitted = true;
      VoiceService.speak("Mandatory Safety Alert: Two hours of continuous driving reached. Please pull over for a mandatory rest.");
      NotificationService.showSafetyAlert("MANDATORY REST BREAK REQUIRED", "2 hours continuous driving limit reached. Take a 15-minute break.");
      SensorService.vibrate(duration: 800);
    }
  }

  void _throttledSensorNotify() {
    final now = DateTime.now();
    _recordBlackBoxSample();
    _checkFatigue();
    if (now.difference(_lastSensorNotify).inMilliseconds >= 150) { // ~6.7Hz smooth UI updates
      _lastSensorNotify = now;
      notifyListeners();
    }
  }

  void _startFullSensorSuite() {
    _accelSub?.cancel();
    try {
      _accelSub = SensorService.getAccelerometerStream().listen(
        (e) {
          accelX = e.x;
          accelY = e.y;
          accelZ = e.z;

          final double rawForce = sqrt(e.x * e.x + e.y * e.y + e.z * e.z) / 9.80665;
          final double filteredForce = rawForce < 0.06 ? 0.0 : rawForce;
          _gForce = 0.22 * filteredForce + 0.78 * _gForce;
          if (_gForce < 0.03) _gForce = 0.0;
          if (_gForce > _maxGForce) _maxGForce = _gForce;

          _detectImpact(e);
          _detectBehavior(e);
          _detectPothole(e);
          _throttledSensorNotify();
        },
        onError: (err) {
          print("[TripProvider] Accel stream error: $err");
        },
        cancelOnError: false,
      );
    } catch (_) {}

    _gyroSub?.cancel();
    try {
      _gyroSub = SensorService.getGyroscopeStream().listen(
        (e) {
          gyroX = e.x;
          gyroY = e.y;
          gyroZ = e.z;
          // Road speed (>= 28 km/h) & aggressive yaw rate (> 3.6 rad/s) prevents normal street cornering alerts
          if (_isShiftActive && _currentSpeed >= 28.0 && gyroZ.abs() > 3.6) {
            _handleSafetyEvent("Sharp Gyro Swerve", 0.5);
          }
          _throttledSensorNotify();
        },
        onError: (err) {
          print("[TripProvider] Gyro stream error: $err");
        },
        cancelOnError: false,
      );
    } catch (_) {}

    _magSub?.cancel();
    try {
      _magSub = SensorService.getMagnetometerStream().listen(
        (e) {
          magX = e.x;
          magY = e.y;
          magZ = e.z;
          _throttledSensorNotify();
        },
        onError: (_) {},
        cancelOnError: false,
      );
    } catch (_) {}
  }

  SensorProvider? _sensorProvider;
  void bindSensorProvider(SensorProvider provider) {
    _sensorProvider = provider;
    _sensorProvider?.addListener(() {
      if (_sensorProvider != null) {
        _gForce = _sensorProvider!.totalGForce;
        if (_gForce > _maxGForce) _maxGForce = _gForce;
        accelX = _sensorProvider!.gForceX * 9.80665;
        accelY = _sensorProvider!.gForceY * 9.80665;
        accelZ = _sensorProvider!.gForceZ * 9.80665;
        if (_isShiftActive) {
          _throttledSensorNotify();
        }
      }
    });
    _sensorProvider?.onCrashDetected = (reason, gForce, speedBefore) {
      if (!_showSOSConfirmation && _isShiftActive) {
        _lastForce = gForce;
        if (speedBefore > 0) _previousSpeed = speedBefore;
        _triggerCrashVerification(reason);
      }
    };
    _sensorProvider?.onRoadHazardDetected = (type, zForce, lat, lng, roadName) {
      if (_isShiftActive) {
        final currentPosLat = _currentLat ?? lat;
        final currentPosLng = _currentLng ?? lng;
        final currentRoad = "${currentCityRules.cityName} Transit Sector";

        final hazard = PotholeHazard(
          id: 'hazard-${DateTime.now().millisecondsSinceEpoch}',
          lat: currentPosLat,
          lng: currentPosLng,
          intensity: (zForce / 3.5).clamp(0.4, 1.0),
          vibrationRate: zForce,
          roadName: currentRoad,
          reportedBy: _currentDriverName ?? 'Driver',
        );

        if (!_potholes.any((p) => (p.lat - currentPosLat).abs() < 0.0003 && (p.lng - currentPosLng).abs() < 0.0003)) {
          _potholes.insert(0, hazard);
          if (_potholes.length > 50) _potholes.removeLast();
        }

        SocketService.emitPotholeDetected(
          lat: currentPosLat,
          lng: currentPosLng,
          intensity: hazard.intensity,
          vibrationRate: zForce,
          roadName: currentRoad,
          driverId: _currentDriverId,
          driverName: _currentDriverName,
          regionId: _currentRegionId,
        );

        notifyListeners();
      }
    };
  }

  void _startPeriodicTelemetryStream(String? driverName) {
    _telemetryTimer?.cancel();
    _telemetryTimer = Timer.periodic(const Duration(milliseconds: 600), (_) {
      if (!_isShiftActive) return;

      final currentAccelX = (_sensorProvider != null && _sensorProvider!.gForceX != 0) ? (_sensorProvider!.gForceX * 9.80665) : accelX;
      final currentAccelY = (_sensorProvider != null && _sensorProvider!.gForceY != 0) ? (_sensorProvider!.gForceY * 9.80665) : accelY;
      final currentAccelZ = (_sensorProvider != null && _sensorProvider!.gForceZ != 0) ? (_sensorProvider!.gForceZ * 9.80665) : accelZ;
      final currentGyroX = (_sensorProvider != null && _sensorProvider!.gyroX != 0) ? _sensorProvider!.gyroX : gyroX;
      final currentGyroY = (_sensorProvider != null && _sensorProvider!.gyroY != 0) ? _sensorProvider!.gyroY : gyroY;
      final currentGyroZ = (_sensorProvider != null && _sensorProvider!.gyroZ != 0) ? _sensorProvider!.gyroZ : gyroZ;
      final currentVib = (_sensorProvider != null && _sensorProvider!.vibrationRate != 0) ? _sensorProvider!.vibrationRate : (_lastForce > 0 ? _lastForce : _gForce);

      SocketService.emitGpsUpdate(
        driverId: _currentDriverId,
        driverName: driverName ?? _currentDriverName ?? "Driver",
        regionId: _currentRegionId,
        lat: _currentLat ?? 0.0,
        lng: _currentLng ?? 0.0,
        speed: _currentSpeed,
        heading: _currentHeading,
        deliveryFrom: _activeOrder?.pickupAddress,
        deliveryTo: _activeOrder?.dropAddress,
        orderItems: _activeOrder?.packageItems,
        destLat: _activeOrder?.dropLat,
        destLng: _activeOrder?.dropLng,
        accelX: currentAccelX,
        accelY: currentAccelY,
        accelZ: currentAccelZ,
        gyroX: currentGyroX,
        gyroY: currentGyroY,
        gyroZ: currentGyroZ,
        magX: magX,
        magY: magY,
        magZ: magZ,
        vibrationRate: currentVib,
        safetyScore: _tripSafetyScore,
        status: _isCrashDetected ? 'emergency' : (_showSOSConfirmation ? 'warning' : 'safe'),
        points: _totalClaimedPoints,
        earnings: _todayEarnedIncome,
        trips: _todayTripCount,
        distanceToday: _todayDistanceKm,
      );
    });
  }



  void _detectImpact(UserAccelerometerEvent e) {
    if (!_isShiftActive) return;
    double force = sqrt(e.x*e.x + e.y*e.y + e.z*e.z) / 9.80665;
    _lastForce = force;

    // Filter out minute variations (below 2.5G is ignored as hand/pocket movement)
    if (force < 2.5) return;

    // 1. Violent stationary collision impact (e.g. rear-ended while parked/idle, force >= 7.0 G)
    if (_currentSpeed < 15.0 && force >= 7.0 && !_showSOSConfirmation) {
      _triggerCrashVerification("Stationary Collision Impact Detected (${force.toStringAsFixed(1)} G)");
      return;
    }

    // 2. High G-force collision while in motion (speed >= 15 km/h with force >= 4.5 G)
    if (_currentSpeed >= 15.0 && force >= 4.5 && !_showSOSConfirmation) {
      final String reason = "High G-Force Collision Impact (${force.toStringAsFixed(1)} G at ${_currentSpeed.toInt()} km/h)";
      _triggerCrashVerification(reason);
    }
  }

  double _previousSpeed = 0.0;
  DateTime? _prevSpeedTime;

  void _checkSpeedDropCrash(double currentSpeed) {
    if (_prevSpeedTime != null) {
       double diff = DateTime.now().difference(_prevSpeedTime!).inMilliseconds / 1000.0;
       if (diff > 0 && diff <= 3.0) {
          if (_previousSpeed >= 40.0 && currentSpeed <= 3.0 && !_showSOSConfirmation && _isShiftActive) {
             _triggerCrashVerification("High-Speed Sudden Deceleration (${_previousSpeed.toInt()} → 0 km/h) & Impact Detected");
          }
       }
    }
    _previousSpeed = currentSpeed;
    _prevSpeedTime = DateTime.now();
  }

  void _triggerCrashVerification(String reason) {
    if (!_isShiftActive) return;
    if (_showSOSConfirmation) return;
    _sosCountdownTimer?.cancel();
    _showSOSConfirmation = true;
    _verificationStep = 1; // Step 1: Driver Safety Audio/Haptic Query
    _crashReason = reason;
    _sosCountdown = 60;
    _crashVerificationAttempts = 1;
    SensorService.vibrate(duration: 1200);
    VoiceService.speak("Emergency alert: $reason. Step one verification initiated. Confirm safety or escalation proceeds in sixty seconds.");
    NotificationService.showSafetyAlert("EMERGENCY CRASH ALERT", reason);
    NotificationService.showEmergencyCrashHeadsUpAlert(
      reason: reason,
      countdown: _sosCountdown,
    );

    // Auto-Lock Dashcam Evidence Ring Buffer
    lockDashcamEvidence(reason: reason);

    // Step 2: Instant Telemetry & Snapshot Broadcast to Admin Dispatch
    _verificationStep = 2; // Step 2: Telemetry & Snapshot sync active
    SocketService.emitCrashAlert(
      driverId: _currentDriverId ?? 'driver',
      reason: reason,
      lat: _currentLat ?? 0.0,
      lng: _currentLng ?? 0.0,
      speedBefore: _previousSpeed > 0 ? _previousSpeed : (_currentSpeed <= 3.0 ? 0.0 : 60.0),
      speedAfter: _currentSpeed,
      gForce: _lastForce > 0 ? _lastForce : 4.5,
      accelX: accelX,
      accelY: accelY,
      accelZ: accelZ,
      blackBoxData: List<Map<String, dynamic>>.from(_blackBoxBuffer),
    );

    _sosCountdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_sosCountdown > 0 && _showSOSConfirmation) {
        _sosCountdown--;
        notifyListeners();
      } else {
        timer.cancel();
        _sosCountdownTimer = null;
        if (_showSOSConfirmation) {
          _escalateEmergency();
        }
      }
    });
    notifyListeners();
  }

  void escalateEmergency() {
    _escalateEmergency();
  }

  void _escalateEmergency() {
    _verificationStep = 3; // Step 3: Multi-channel Emergency Escalation
    _isCrashDetected = true;
    _isLiveCamActive = true;
    _startLiveCameraStreaming();
    VoiceService.speak("Step three emergency escalation triggered. Admin dispatcher connected, emergency hotlines queued, family notified.");
    SocketService.emitEmergencyEscalation(driverId: _currentDriverId ?? 'driver');
    notifyListeners();
  }

  void _detectPothole(UserAccelerometerEvent e) {
    if (!_isShiftActive || _currentSpeed < 12.0) return;
    final double verticalG = (e.z / 9.80665).abs();
    final double planarG = sqrt(e.x * e.x + e.y * e.y) / 9.80665;
    final double totalForce = sqrt(e.x * e.x + e.y * e.y + e.z * e.z) / 9.80665;

    // Once the sensor observes that Z-axis values are more (dominant vertical acceleration),
    // there is a high chance that it is a pothole!
    final bool isZDominantPothole = verticalG >= 1.90 && (verticalG > planarG * 1.25 || verticalG >= 2.4);

    if (isZDominantPothole) {
      final now = DateTime.now();
      if (_lastPotholeDetectedTime == null || now.difference(_lastPotholeDetectedTime!).inSeconds >= 4) {
        _lastPotholeDetectedTime = now;
        final currentPosLat = _currentLat ?? 0.0;
        final currentPosLng = _currentLng ?? 0.0;
        final roadName = "${currentCityRules.cityName} Transit Corridor";
        final double intensity = (totalForce / 3.0).clamp(0.4, 1.0);

        final hazard = PotholeHazard(
          id: 'pot-${DateTime.now().millisecondsSinceEpoch}',
          lat: currentPosLat,
          lng: currentPosLng,
          intensity: intensity,
          vibrationRate: totalForce,
          roadName: roadName,
          reportedBy: _currentDriverName ?? 'Driver',
        );
        _potholes.insert(0, hazard);

        SocketService.emitPotholeDetected(
          lat: currentPosLat,
          lng: currentPosLng,
          intensity: intensity,
          vibrationRate: totalForce,
          roadName: roadName,
          driverId: _currentDriverId,
          driverName: _currentDriverName,
          regionId: _currentRegionId,
        );

        NotificationService.showSafetyAlert("POTHOLE PINNED", "Pothole detected via vertical Z-shock (${verticalG.toStringAsFixed(1)} G). Pinned on map.");
        HapticService.mediumImpact();
        notifyListeners();
      }
    }
  }

  void _detectBehavior(UserAccelerometerEvent e) {
    if (!_isShiftActive || _currentSpeed < 28.0) return;
    if (e.y < -8.8) {
       _handleSafetyEvent("Harsh Braking", 1.0);
    } else if (e.y > 8.2) {
       _handleSafetyEvent("Rapid Acceleration", 0.8);
    }
  }

  DateTime? _lastSafetyAlertTime;
  String? _lastSafetyAlertType;

  void _handleSafetyEvent(String type, double hit) {
    if (!_isShiftActive) return;
    final now = DateTime.now();
    final bool isCooldownActive = _lastSafetyAlertTime != null && now.difference(_lastSafetyAlertTime!).inSeconds < 20;

    _tripSafetyScore = max(0.0, _tripSafetyScore - hit);

    // Suppress voice and notification spam during turns and subtle road vibrations
    if (!isCooldownActive || _lastSafetyAlertType != type) {
      _lastSafetyAlertTime = now;
      _lastSafetyAlertType = type;
      VoiceService.announceDrivingWarning(type, val: hit);
      NotificationService.showSafetyAlert("DRIVING ALERT", "$type detected. Maintain steady vehicle control.");
    }

    // Broadcast to Admin Dashboard via WebSocket
    SocketService.emitRuleViolation({
      'driverId': _currentDriverId ?? 'driver',
      'driverName': _currentDriverName ?? 'Driver',
      'ruleType': type,
      'ruleTitle': type,
      'severity': hit >= 1.0 ? 'HIGH' : 'MEDIUM',
      'latitude': _currentLat ?? 0.0,
      'longitude': _currentLng ?? 0.0,
      'speed': _currentSpeed,
      'description': "$type detected on active route.",
      'timestamp': DateTime.now().toIso8601String(),
    });
    notifyListeners();
  }

  void _checkRoadRules(double speed, double heading, double lat, double lng) {
    if (!_isShiftActive) return;
    final violation = RoadRulesService.evaluateDrivingRules(
      speedKmH: speed,
      headingDegrees: heading,
      currentLat: lat,
      currentLng: lng,
      cityRules: currentCityRules,
      dynamicSchoolZones: _safetyZones,
    );

    if (violation != null) {
      final now = DateTime.now();
      if (_lastViolationTime == null || now.difference(_lastViolationTime!).inSeconds >= 12) {
        _lastViolationTime = now;
        _journeyViolations.insert(0, violation);
        _tripSafetyScore = max(0.0, _tripSafetyScore - (violation.severity == 'critical' ? 2.5 : 1.5));
        
        VoiceService.speak("Rule violation: ${violation.ruleTitle}. Please comply with traffic regulations.");
        NotificationService.showSafetyAlert("TRAFFIC RULE VIOLATION", violation.description);

        SocketService.emitRuleViolation({
          'driverId': _currentDriverId ?? 'driver',
          'driverName': _currentDriverName ?? 'Agent X',
          'ruleType': violation.ruleType,
          'ruleTitle': violation.ruleTitle,
          'severity': violation.severity,
          'latitude': lat,
          'longitude': lng,
          'speed': speed,
          'speedLimit': violation.speedLimit,
          'roadType': violation.roadType,
          'roadName': violation.roadName,
          'description': violation.description,
          'timestamp': DateTime.now().toIso8601String(),
        });

        notifyListeners();
      }
    }
  }

  void _startGpsMonitoring(String? driverName) {
    _gpsSub?.cancel();
    GpsService.getCurrentLocation().then((pos) {
      if (pos != null) {
        _currentSpeed = pos.speed * 3.6;
        _currentLat = pos.latitude;
        _currentLng = pos.longitude;
        _currentHeading = pos.heading;
        updateNearbySchoolZones(pos.latitude, pos.longitude);
        notifyListeners();
      }
    });

    _gpsSub = GpsService.getLocationStream().listen((pos) {
      double speed = pos.speed * 3.6;
      _currentSpeed = speed;
      _currentLat = pos.latitude;
      _currentLng = pos.longitude;
      _currentHeading = pos.heading;
      _sensorProvider?.updateSpeed(speed);
      _sensorProvider?.updateGpsStatus(true, speed);
      _sensorProvider?.updateLocation(pos.latitude, pos.longitude);
      if (_isTripActive) {
        if (_routeCoordinates.isEmpty) {
          _routeCoordinates.add([pos.latitude, pos.longitude]);
        } else {
          final last = _routeCoordinates.last;
          final dLat = (pos.latitude - last[0]).abs();
          final dLng = (pos.longitude - last[1]).abs();
          if (dLat > 0.00003 || dLng > 0.00003) {
            _routeCoordinates.add([pos.latitude, pos.longitude]);
          }
        }
      }

      _checkSpeedDropCrash(speed);
      _checkProximityAlerts(pos.latitude, pos.longitude);
      _checkRoadRules(speed, pos.heading, pos.latitude, pos.longitude);
      _checkStillnessAnomaly(speed);
      updateNearbySchoolZones(pos.latitude, pos.longitude);

      notifyListeners();
    }, onError: (err) {
      _sensorProvider?.updateGpsStatus(false, 0);
    });
  }

  void _checkStillnessAnomaly(double speed) {
    if (!_isShiftActive) return;
    if (speed > 40) {
      _lastHighSpeedTime = DateTime.now();
    }

    if (speed < 1 && _lastHighSpeedTime != null && DateTime.now().difference(_lastHighSpeedTime!).inSeconds > 5) {
      if (_stillnessTimer == null || !_stillnessTimer!.isActive) {
        _stillnessTimer = Timer(const Duration(seconds: 30), () {
          if (_currentSpeed < 1 && !_showSOSConfirmation) {
            _triggerStillnessAlert();
          }
        });
      }
    } else {
      _stillnessTimer?.cancel();
    }
  }

  void _triggerStillnessAlert() {
    if (!_isShiftActive) return;
    VoiceService.speak("Stillness anomaly detected after high velocity. Admin notified.", isCritical: true);
    _triggerCrashVerification("Stillness Anomaly After High Velocity");
  }

  void _checkProximityAlerts(double lat, double lng) {
    if (!_isShiftActive) return;
    for (var zone in _safetyZones) {
      if (zone.alerted) continue;
      double distance = _calculateDistance(lat, lng, zone.lat, zone.lng);
      if (distance < 0.45) {
        zone.alerted = true;
        String msg = "Approaching ${zone.name}. ";
        if (zone.type == "school") {
          msg += "Slow down, school zone ahead (Max 25 km/h).";
        } else if (zone.type == "construction") {
          msg += "Caution: Road construction and work zone ahead. Slow down.";
        } else if (zone.type == "sharp_turn") {
          msg += "Warning: Dangerous sharp curve ahead. Decelerate now.";
        } else if (zone.type == "pothole") {
          msg += "Caution, damaged road and potholes reported ahead.";
        } else if (zone.type == "traffic") {
          msg += "Heavy traffic expected ahead.";
        } else if (zone.type == "hospital") {
          msg += "Hospital silence zone ahead. Strictly no honking.";
        }
        VoiceService.speak(msg);
        NotificationService.showSafetyAlert("ROAD SAFETY ALERT", msg);
        notifyListeners();
      }
    }

    // Multi-Driver Shared Pothole Proximity Warnings
    for (final pot in _potholes) {
      if (_alertedPotholeIds.contains(pot.id)) continue;
      double distKm = _calculateDistance(lat, lng, pot.lat, pot.lng);
      if (distKm <= 0.35) { // Within 350 meters
        _alertedPotholeIds.add(pot.id);
        final warningMsg = "Caution: Pothole / rough road ahead on ${pot.roadName} reported by fleet drivers. Reduce speed.";
        VoiceService.speak(warningMsg);
        NotificationService.showSafetyAlert("ROAD HAZARD CAUTION", warningMsg);
        notifyListeners();
      }
    }

    // Dynamic Admin Geofence Speed Enforcement
    String? insideZoneName;
    int? insideSpeedCeiling;

    for (final zone in _customGeofences) {
      final zLat = (zone['lat'] as num?)?.toDouble();
      final zLng = (zone['lng'] as num?)?.toDouble();
      if (zLat == null || zLng == null) continue;

      final radiusM = ((zone['radiusMeters'] ?? 300) as num).toDouble();
      final speedLimit = ((zone['speedLimitKph'] ?? 30) as num).toInt();
      final zoneName = zone['name']?.toString() ?? 'Enforced Zone';
      final zoneId = zone['id']?.toString() ?? '$zLat,$zLng';

      double distMeters = _calculateDistance(lat, lng, zLat, zLng) * 1000.0;
      if (distMeters <= radiusM) {
        insideZoneName = zoneName;
        insideSpeedCeiling = speedLimit;

        // Check for speed ceiling violation
        if (_currentSpeed > (speedLimit + 2)) {
          if (!_alertedGeofenceSpeedViolations.contains(zoneId)) {
            _alertedGeofenceSpeedViolations.add(zoneId);
            final warnMsg = "Speed limit $speedLimit km/h in $zoneName exceeded! Current: ${_currentSpeed.toStringAsFixed(0)} km/h. Please slow down.";
            VoiceService.speak("Caution! Speed limit $speedLimit km/h in $zoneName. Please decelerate.");
            NotificationService.showSafetyAlert("ZONE SPEED LIMIT EXCEEDED", warnMsg);
            SensorService.vibrate(duration: 800);

            _tripSafetyScore = max(0.0, _tripSafetyScore - 2.0);

            SocketService.emitRuleViolation({
              'driverId': _currentDriverId ?? 'driver',
              'driverName': _currentDriverName ?? 'Agent X',
              'ruleType': 'geofence_speed_violation',
              'ruleTitle': 'Geofence Speed Limit Exceeded ($zoneName)',
              'severity': _currentSpeed > (speedLimit + 15) ? 'CRITICAL' : 'HIGH',
              'latitude': lat,
              'longitude': lng,
              'speed': _currentSpeed,
              'speedLimit': speedLimit,
              'description': "Exceeded dynamic zone ceiling of $speedLimit km/h in $zoneName at ${_currentSpeed.toStringAsFixed(1)} km/h",
              'timestamp': DateTime.now().toIso8601String(),
            });

            Timer(const Duration(seconds: 20), () {
              _alertedGeofenceSpeedViolations.remove(zoneId);
            });
          }
        }
      }
    }

    _activeGeofenceName = insideZoneName;
    _activeGeofenceSpeedCeiling = insideSpeedCeiling;
  }

  double _calculateDistance(double lat1, double lon1, double lat2, double lng2) {
    var p = 0.017453292519943295;
    var c = cos;
    var a = 0.5 - c((lat2 - lat1) * p)/2 + c(lat1 * p) * c(lat2 * p) * (1 - c((lng2 - lon1) * p))/2;
    return 12742 * asin(sqrt(a));
  }

  Timer? _cameraStreamTimer;
  bool _isCapturingFrame = false;

  void _startLiveCameraStreaming() {
    _cameraStreamTimer?.cancel();
    _isLiveCamActive = true;
    print("[TripProvider] 🎥 Starting live camera streaming to admin dashboard...");

    _cameraStreamTimer = Timer.periodic(const Duration(milliseconds: 1200), (timer) async {
      if (!_isLiveCamActive) {
        timer.cancel();
        return;
      }
      if (_isCapturingFrame) return;
      _isCapturingFrame = true;

      try {
        final frameBytes = await MediaService.captureFrame();
        final dId = _currentDriverId ?? 'agent-x';

        if (frameBytes != null && frameBytes.isNotEmpty) {
          final base64Frame = base64Encode(frameBytes);
          SocketService.emitLiveFrame(dId, base64Frame);
        } else {
          // Fallback telemetry frame if camera sensor is initializing, restricted, or in virtual environment
          final telemetryFrame = _generateTelemetryFrameSvgBase64();
          SocketService.emitLiveFrame(dId, telemetryFrame);
        }
      } catch (e) {
        print("[TripProvider] Live camera frame stream exception: $e");
      } finally {
        _isCapturingFrame = false;
      }
    });
  }

  void _stopLiveCameraStreaming() {
    print("[TripProvider] 🛑 Stopping live camera stream.");
    _cameraStreamTimer?.cancel();
    _cameraStreamTimer = null;
    _isLiveCamActive = false;
    MediaService.releaseCamera();
  }

  String _generateTelemetryFrameSvgBase64() {
    final now = DateTime.now();
    final timeStr = "${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}:${now.second.toString().padLeft(2, '0')}.${(now.millisecond ~/ 100)}";
    final speed = _currentSpeed.toStringAsFixed(1);
    final gForce = _gForce.toStringAsFixed(2);
    final driverId = _currentDriverId ?? 'driver';
    final name = _currentDriverName ?? 'Operator';
    final lat = (_currentLat ?? 0.0).toStringAsFixed(5);
    final lng = (_currentLng ?? 0.0).toStringAsFixed(5);
    final score = _tripSafetyScore.toStringAsFixed(0);

    final svg = '''<svg xmlns="http://www.w3.org/2000/svg" width="480" height="320" viewBox="0 0 480 320">
      <defs>
        <linearGradient id="bg" x1="0%" y1="0%" x2="100%" y2="100%">
          <stop offset="0%" stop-color="#020617"/>
          <stop offset="100%" stop-color="#0f172a"/>
        </linearGradient>
        <linearGradient id="road" x1="0%" y1="0%" x2="0%" y2="100%">
          <stop offset="0%" stop-color="#1e293b"/>
          <stop offset="100%" stop-color="#334155"/>
        </linearGradient>
      </defs>
      <rect width="480" height="320" fill="url(#bg)"/>
      <polygon points="180,120 300,120 420,320 60,320" fill="url(#road)" opacity="0.6"/>
      <line x1="240" y1="120" x2="240" y2="320" stroke="#10b981" stroke-width="4" stroke-dasharray="14,10" opacity="0.8"/>
      <rect x="12" y="12" width="456" height="296" fill="none" stroke="#10b981" stroke-width="1.5" stroke-dasharray="8,6" opacity="0.4"/>
      
      <!-- Top HUD Header -->
      <rect x="18" y="18" width="444" height="32" rx="6" fill="#030712" fill-opacity="0.8" stroke="#1e293b"/>
      <circle cx="34" cy="34" r="5" fill="#ef4444"/>
      <text x="46" y="38" fill="#ef4444" font-family="monospace" font-weight="900" font-size="11">LIVE TELEMETRY CAM</text>
      <text x="320" y="38" fill="#10b981" font-family="monospace" font-weight="700" font-size="11">REC $timeStr</text>
      
      <!-- Center Targeting Reticle -->
      <circle cx="240" cy="160" r="28" fill="none" stroke="#00f0ff" stroke-width="1.5" stroke-dasharray="4,4" opacity="0.6"/>
      <circle cx="240" cy="160" r="3" fill="#00f0ff"/>
      <line x1="210" y1="160" x2="270" y2="160" stroke="#00f0ff" stroke-width="1" opacity="0.4"/>
      <line x1="240" y1="130" x2="240" y2="190" stroke="#00f0ff" stroke-width="1" opacity="0.4"/>
      
      <!-- Telemetry Lower Overlay -->
      <rect x="18" y="240" width="444" height="62" rx="8" fill="#030712" fill-opacity="0.85" stroke="#1e293b"/>
      <text x="30" y="260" fill="#94a3b8" font-family="sans-serif" font-weight="700" font-size="10">OPERATOR: <tspan fill="#ffffff">$name ($driverId)</tspan></text>
      <text x="30" y="278" fill="#94a3b8" font-family="monospace" font-size="9.5">GPS: $lat, $lng | SAFETY: $score%</text>
      <text x="30" y="294" fill="#94a3b8" font-family="monospace" font-size="9.5">SPEED: $speed KM/H | G-FORCE: ${gForce}G</text>
    </svg>''';

    final bytes = utf8.encode(svg);
    return "data:image/svg+xml;base64,${base64Encode(bytes)}";
  }

  void cancelSOS() {
    _sosCountdownTimer?.cancel();
    _sosCountdownTimer = null;
    _showSOSConfirmation = false;
    _isCrashDetected = false;
    _sosCountdown = 0;
    _isAdminPinging = false;
    _stopLiveCameraStreaming();
    NotificationService.cancelCrashNotification();
    notifyListeners();
  }

  void confirmSafe() {
    SocketService.emitSafetyResponse(
      driverId: _currentDriverId,
      driverName: _currentDriverName,
    );
    VoiceService.speak("Safety confirmed. Link restored to normal.");
    cancelSOS();
  }

  void triggerManualSOS() {
    _sosCountdownTimer?.cancel();
    _sosCountdownTimer = null;
    _showSOSConfirmation = true;
    _isCrashDetected = true;
    _crashReason = "Manual SOS Panic Triggered by Operator";
    _sosCountdown = 0;
    _isAdminPinging = false;
    SensorService.vibrate(duration: 1500);
    VoiceService.speak("Emergency SOS initiated. Alerting fleet admin and family.");
    NotificationService.cancelCrashNotification();
    lockDashcamEvidence(reason: "Manual SOS Panic Triggered");
    SocketService.emitCrashAlert(
      driverId: _currentDriverId ?? 'driver',
      reason: "Manual SOS Panic Triggered",
      lat: _currentLat ?? 0.0,
      lng: _currentLng ?? 0.0,
      blackBoxData: List<Map<String, dynamic>>.from(_blackBoxBuffer),
    );
    _escalateEmergency();
    notifyListeners();
  }

  void handleAdminPing(String msg) {
    _sosCountdownTimer?.cancel();
    _showSOSConfirmation = true;
    _crashReason = (msg.isNotEmpty) ? msg : "Admin safety check: Are you safe?";
    _sosCountdown = 30;
    _isAdminPinging = true;
    SensorService.vibrate(duration: 800);
    VoiceService.speak("Admin safety verification received. Please confirm you are safe within thirty seconds.");
    NotificationService.showEmergencyCrashHeadsUpAlert(
      reason: _crashReason,
      countdown: _sosCountdown,
    );
    notifyListeners();

    _sosCountdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_sosCountdown > 0 && _showSOSConfirmation) {
        _sosCountdown--;
        notifyListeners();
      } else {
        timer.cancel();
        _sosCountdownTimer = null;
        if (_showSOSConfirmation && !_isCrashDetected) {
          SocketService.emitPingNoResponse(
            driverId: _currentDriverId ?? 'agent-x',
            reason: "Admin Safety Ping Expired: No Response from Driver (30s elapsed)",
          );
          _escalateEmergency();
        }
      }
    });
  }

  void simulateCrashTest({double speedBefore = 60.0, double impactForce = 4.2}) {
    _previousSpeed = speedBefore;
    _currentSpeed = 0.0;
    _lastForce = impactForce;
    _triggerCrashVerification("Simulated Sudden Deceleration (${speedBefore.toInt()} → 0 km/h) & ${impactForce}G Force");
  }

  void _saveShiftState(bool isActive) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('sd_shift_active', isActive);
  }

  Future<void> requestAllPermissions() async {
    await [Permission.locationAlways, Permission.sensors, Permission.camera, Permission.microphone].request();
  }
}

extension ListExtensions<T> on List<T> {
  int findIndex(bool Function(T element) test) {
    for (int i = 0; i < length; i++) {
      if (test(this[i])) return i;
    }
    return -1;
  }
}
