import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/event_model.dart';
import '../models/order_model.dart';
import '../models/trip_model.dart';
import '../services/local_storage_service.dart';
import '../services/gps_service.dart';
import '../services/api_service.dart';
import '../services/socket_service.dart';

class TripProvider extends ChangeNotifier {
  bool _isShiftActive = false;
  bool _isTripActive = false;
  String? _backendTripId;
  
  bool get isShiftActive => _isShiftActive;
  bool get isTripActive => _isTripActive;

  // Active shifts metrics
  DateTime? _shiftStartTime;
  double _todayDistanceKm = 0.0;
  int _todayTripCount = 0;
  List<SafetyEvent> _todayEvents = [];

  DateTime? get shiftStartTime => _shiftStartTime;
  double get todayDistanceKm => _todayDistanceKm;
  int get todayTripCount => _todayTripCount;
  List<SafetyEvent> get todayEvents => _todayEvents;

  // Orders
  List<DeliveryOrder> _availableOrders = [];
  DeliveryOrder? _activeOrder;
  
  List<DeliveryOrder> get availableOrders => _availableOrders;
  DeliveryOrder? get activeOrder => _activeOrder;

  // GPS Route tracking
  List<List<double>> _routeCoordinates = [];
  List<List<double>> get routeCoordinates => _routeCoordinates;
  
  // Trip specific metrics
  DateTime? _tripStartTime;
  double _tripDistanceKm = 0.0;
  double _tripMaxSpeed = 0.0;
  double _tripAverageSpeed = 0.0;
  double _tripSafetyScore = 100.0;

  DateTime? get tripStartTime => _tripStartTime;
  double get tripDistanceKm => _tripDistanceKm;
  double get tripMaxSpeed => _tripMaxSpeed;
  double get tripAverageSpeed => _tripAverageSpeed;
  double get tripSafetyScore => _tripSafetyScore;

  // Crash / SOS Detection
  bool _isCrashDetected = false;
  int _sosCountdown = 5;
  Timer? _sosTimer;
  StreamSubscription? _gpsSub;

  bool get isCrashDetected => _isCrashDetected;
  int get sosCountdown => _sosCountdown;

  // Historical Shifts
  List<DriverTrip> _history = [];
  List<DriverTrip> get history => _history;

  // Completed trip cache for summary
  DriverTrip? _lastCompletedTrip;
  DriverTrip? get lastCompletedTrip => _lastCompletedTrip;

  Future<void> initHistory() async {
    _history = await LocalStorageService.getTrips();
    // Pre-populate with some premium mock past trips if empty so the history tab has content immediately
    if (_history.isEmpty) {
      _history = [
        DriverTrip(
          id: "TRIP-928",
          startTime: DateTime.now().subtract(const Duration(days: 1, hours: 4)),
          endTime: DateTime.now().subtract(const Duration(days: 1, hours: 3)),
          distanceKm: 24.8,
          durationSeconds: 3200,
          averageSpeed: 48.0,
          maxSpeed: 75.0,
          safetyScore: 94.0,
          industry: "Logistics",
          vehicleName: "Ford Transit",
          routeCoordinates: [[37.7749, -122.4194], [37.7849, -122.4294]],
          events: [
            SafetyEvent(
              id: "EV-01",
              type: "Harsh Braking",
              timestamp: DateTime.now().subtract(const Duration(days: 1, hours: 3, minutes: 40)),
              severity: "Medium",
              latitude: 37.7780,
              longitude: -122.4220,
              triggerValue: 0.42,
              aiTip: "Increase vehicle separation gap to allow smoother stops.",
            )
          ],
        ),
        DriverTrip(
          id: "TRIP-502",
          startTime: DateTime.now().subtract(const Duration(days: 3)),
          endTime: DateTime.now().subtract(const Duration(days: 3, hours: -1)),
          distanceKm: 12.3,
          durationSeconds: 1540,
          averageSpeed: 38.5,
          maxSpeed: 62.0,
          safetyScore: 98.0,
          industry: "Courier",
          vehicleName: "Ford Transit",
          routeCoordinates: [[37.7749, -122.4194], [37.7649, -122.4094]],
          events: [],
        ),
        DriverTrip(
          id: "TRIP-129",
          startTime: DateTime.now().subtract(const Duration(days: 5)),
          endTime: DateTime.now().subtract(const Duration(days: 5, hours: -2)),
          distanceKm: 42.1,
          durationSeconds: 5800,
          averageSpeed: 52.0,
          maxSpeed: 88.0,
          safetyScore: 82.0,
          industry: "Enterprise Fleet",
          vehicleName: "Ford Transit",
          routeCoordinates: [[37.7749, -122.4194], [37.8049, -122.4394]],
          events: [
            SafetyEvent(
              id: "EV-02",
              type: "Overspeed",
              timestamp: DateTime.now().subtract(const Duration(days: 5, hours: -1)),
              severity: "Medium",
              latitude: 37.7910,
              longitude: -122.4280,
              triggerValue: 88.0,
              aiTip: "Follow the posted speed limit signs.",
            ),
            SafetyEvent(
              id: "EV-03",
              type: "Sharp Turn",
              timestamp: DateTime.now().subtract(const Duration(days: 5, hours: -1, minutes: 15)),
              severity: "Medium",
              latitude: 37.7990,
              longitude: -122.4320,
              triggerValue: 0.48,
              aiTip: "Decelerate prior to steering adjustments.",
            )
          ],
        )
      ];
      await LocalStorageService.saveTrips(_history);
    }
    notifyListeners();
  }

  void startShift() {
    _isShiftActive = true;
    _shiftStartTime = DateTime.now();
    _todayDistanceKm = 0.0;
    _todayTripCount = 0;
    _todayEvents = [];
    _availableOrders.clear();
    notifyListeners();
  }

  Future<void> fetchBackendOrders() async {
    if (!_isShiftActive || _isTripActive) return;
    final orders = await ApiService.fetchOrders();
    // Only include orders that are still pending or available
    _availableOrders = orders;
    notifyListeners();
  }

  void endShift() {
    _isShiftActive = false;
    _isTripActive = false;
    _activeOrder = null;
    _shiftStartTime = null;
    _availableOrders.clear();
    _gpsSub?.cancel();
    notifyListeners();
  }

  void _generateMockOrders() {
    _availableOrders = [
      DeliveryOrder(
        id: "ORD-${1000 + Random().nextInt(9000)}",
        pickupAddress: "Amazon Logistics Fulfillment Hub C4",
        dropAddress: "2948 Silicon Valley Boulevard, Suite 10",
        distanceKm: 8.4,
        estimatedTimeMinutes: 16,
        payoutAmount: 24.50,
        pickupLat: 37.7749,
        pickupLng: -122.4194,
        dropLat: 37.7894,
        dropLng: -122.4014,
      ),
      DeliveryOrder(
        id: "ORD-${1000 + Random().nextInt(9000)}",
        pickupAddress: "Port Logistics Yard 12, Terminal A",
        dropAddress: "Oakland Distribution Depot B",
        distanceKm: 14.2,
        estimatedTimeMinutes: 28,
        payoutAmount: 48.75,
        pickupLat: 37.7749,
        pickupLng: -122.4194,
        dropLat: 37.8049,
        dropLng: -122.2711,
      ),
    ];
  }

  void receiveNewSimulatedOrder() {
    if (!_isShiftActive || _activeOrder != null) return;
    
    final newOrder = DeliveryOrder(
      id: "ORD-${1000 + Random().nextInt(9000)}",
      pickupAddress: "Fulfillment Depot Center X",
      dropAddress: "742 Evergreen Drive, Springfield",
      distanceKm: 6.2,
      estimatedTimeMinutes: 14,
      payoutAmount: 19.80,
      pickupLat: 37.7749,
      pickupLng: -122.4194,
      dropLat: 37.7659,
      dropLng: -122.4497,
    );
    
    _availableOrders.insert(0, newOrder);
    notifyListeners();
  }

  void acceptOrder(DeliveryOrder order) {
    _availableOrders.removeWhere((o) => o.id == order.id);
    _activeOrder = order.copyWith(status: 'accepted');
    _startTrip();
    notifyListeners();
  }

  void rejectOrder(DeliveryOrder order) {
    _availableOrders.removeWhere((o) => o.id == order.id);
    notifyListeners();
  }

  Future<void> _startTrip() async {
    if (_activeOrder == null) return;
    _isTripActive = true;
    _tripStartTime = DateTime.now();
    _tripDistanceKm = 0.0;
    _tripMaxSpeed = 0.0;
    _tripAverageSpeed = 0.0;
    _tripSafetyScore = 100.0;
    _routeCoordinates = [
      [_activeOrder!.pickupLat, _activeOrder!.pickupLng]
    ];
    
    // Retrieve backend vehicle UUID
    final prefs = await SharedPreferences.getInstance();
    final vehicleId = prefs.getString('fg_active_vehicle_id') ?? "00000000-0000-0000-0000-000000000000";

    // Request start trip registration on Node.js backend
    _backendTripId = await ApiService.startTrip(vehicleId);
    print("Backend Trip initialized with ID: $_backendTripId");

    // Generate simulated driving route polyline coordinates
    final startLat = _activeOrder!.pickupLat;
    final startLng = _activeOrder!.pickupLng;
    final endLat = _activeOrder!.dropLat;
    final endLng = _activeOrder!.dropLng;
    
    // Create 15 points linearly between start and end with small offsets to look like real roads
    for (int i = 1; i <= 15; i++) {
      double pct = i / 15.0;
      double currentLat = startLat + (endLat - startLat) * pct;
      double currentLng = startLng + (endLng - startLng) * pct;
      
      // Add slight organic offsets
      if (i < 15) {
        currentLat += 0.001 * sin(i * 1.5);
        currentLng += 0.001 * cos(i * 1.5);
      }
      _routeCoordinates.add([currentLat, currentLng]);
    }

    _gpsSub = GpsService.getLocationStream().listen((pos) async {
      // Append coordinates dynamically if moved
      _routeCoordinates.add([pos.latitude, pos.longitude]);
      // Update speedometer speed
      double spdKph = pos.speed * 3.6;
      if (spdKph > _tripMaxSpeed) _tripMaxSpeed = spdKph;

      // Sync coordinate packet to Node.js database
      if (_backendTripId != null) {
        await ApiService.sendLocation(
          _backendTripId!,
          pos.latitude,
          pos.longitude,
          spdKph,
          pos.heading,
        );
      }
      
      // Emit live telemetry over WebSockets
      SocketService.emitGpsUpdate(
        tripId: _backendTripId,
        lat: pos.latitude,
        lng: pos.longitude,
        speed: spdKph,
        heading: pos.heading,
      );
      
      notifyListeners();
    });

    notifyListeners();
  }

  void simulateSafetyEvent(SafetyEvent event) {
    if (!_isTripActive) return;
    _todayEvents.add(event);
    
    // Sync telemetry warning to Node.js backend
    if (_backendTripId != null) {
      String apiType = "OVERSPEED";
      if (event.type.toLowerCase().contains("brak")) apiType = "HARSH_BRAKING";
      else if (event.type.toLowerCase().contains("accel")) apiType = "RAPID_ACCELERATION";
      else if (event.type.toLowerCase().contains("turn")) apiType = "SHARP_TURN";
      else if (event.type.toLowerCase().contains("phone")) apiType = "PHONE_USAGE";
      else if (event.type.toLowerCase().contains("crash")) apiType = "CRASH";
      else if (event.type.toLowerCase().contains("batt")) apiType = "LOW_BATTERY";
      else if (event.type.toLowerCase().contains("netw")) apiType = "LOW_NETWORK";
      else if (event.type.toLowerCase().contains("gps")) apiType = "GPS_LOST";

      String apiSev = event.severity.toUpperCase();
      if (apiSev == "CRITICAL" || apiSev == "CRASH") apiSev = "CRITICAL";
      if (apiSev != "LOW" && apiSev != "MEDIUM" && apiSev != "HIGH" && apiSev != "CRITICAL") {
        apiSev = "LOW";
      }

      ApiService.logEvent(
        tripId: _backendTripId,
        eventType: apiType,
        severity: apiSev,
        latitude: event.latitude,
        longitude: event.longitude,
        sensorValues: {
          "triggerValue": event.triggerValue,
          "aiTip": event.aiTip,
        }
      );
    }

    // Deduct safety score based on severity
    double deduction = 5.0;
    if (event.type == "Crash") deduction = 50.0;
    else if (event.severity == "High") deduction = 15.0;
    else if (event.severity == "Medium") deduction = 8.0;
    
    _tripSafetyScore = max(0.0, _tripSafetyScore - deduction);
    notifyListeners();
  }

  Future<void> endTrip() async {
    if (!_isTripActive || _activeOrder == null) return;
    _isTripActive = false;
    _gpsSub?.cancel();

    // Call backend API to close and score the trip
    if (_backendTripId != null) {
      await ApiService.endTrip(_backendTripId!);
    }
    
    final endTime = DateTime.now();
    final durationSec = endTime.difference(_tripStartTime!).inSeconds;
    
    // Finalize statistics
    final tripId = _backendTripId ?? "TRIP-${100 + Random().nextInt(900)}";
    _backendTripId = null;
    
    final finalTrip = DriverTrip(
      id: tripId,
      startTime: _tripStartTime!,
      endTime: endTime,
      distanceKm: _activeOrder!.distanceKm,
      durationSeconds: durationSec == 0 ? 60 : durationSec,
      averageSpeed: _tripMaxSpeed * 0.65, // simulated math
      maxSpeed: _tripMaxSpeed == 0 ? 55.0 : _tripMaxSpeed,
      safetyScore: _tripSafetyScore,
      industry: _activeOrder!.pickupAddress.contains("Amazon") ? "Logistics" : "Courier",
      vehicleName: "Ford Transit",
      routeCoordinates: _routeCoordinates,
      events: _todayEvents,
    );

    _lastCompletedTrip = finalTrip;
    _history.insert(0, finalTrip);
    LocalStorageService.saveTrips(_history);

    // Update cumulative metrics
    _todayDistanceKm += _activeOrder!.distanceKm;
    _todayTripCount += 1;
    _activeOrder = null;
    
    // Queue another order in the background for continuous workflow simulation
    Timer(const Duration(seconds: 4), () {
      _generateMockOrders();
      notifyListeners();
    });

    notifyListeners();
  }

  // Crash Detection SOS Routine
  void triggerCrashSimulation() {
    _isCrashDetected = true;
    _sosCountdown = 5;
    notifyListeners();

    _sosTimer = Timer.periodic(const Duration(seconds: 1), (timer) async {
      if (_sosCountdown > 1) {
        _sosCountdown--;
        notifyListeners();
      } else {
        _sosTimer?.cancel();
        // Go straight to active emergency screen
        _sosCountdown = 0;
        
        // Report crash to Node.js backend to notify all supervisors
        try {
          final pos = await GpsService.getCurrentLocation();
          final lat = pos?.latitude ?? 12.9716;
          final lng = pos?.longitude ?? 77.5946;

          await ApiService.reportCrash(
            tripId: _backendTripId,
            latitude: lat,
            longitude: lng,
            severity: "CRITICAL",
            sensorValues: {
              "accel_x": 48.6,
              "accel_y": 14.8,
              "accel_z": -9.81
            }
          );
          
          SocketService.emitCrashEvent(
            tripId: _backendTripId,
            lat: lat,
            lng: lng,
            sensorData: {
              "accel_x": 48.6,
              "accel_y": 14.8,
              "accel_z": -9.81
            }
          );
        } catch (e) {
          print("Crash report send error: $e");
        }

        notifyListeners();
      }
    });
  }

  void cancelSOS() {
    _sosTimer?.cancel();
    _isCrashDetected = false;
    _sosCountdown = 5;
    notifyListeners();
  }

  @override
  void dispose() {
    _gpsSub?.cancel();
    _sosTimer?.cancel();
    super.dispose();
  }
}