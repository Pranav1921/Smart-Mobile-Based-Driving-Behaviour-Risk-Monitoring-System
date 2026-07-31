import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:sensors_plus/sensors_plus.dart';
import '../models/event_model.dart';
import '../services/sensor_service.dart';
import 'package:uuid/uuid.dart';

class SensorProvider extends ChangeNotifier {
  // Real-time sensor values mapped to Gs
  double _gForceX = 0.0;
  double _gForceY = 0.0;
  double _gForceZ = 0.0;
  double _rawSpeed = 0.0; // Current velocity (simulated/GPS)

  double get gForceX => _gForceX;
  double get gForceY => _gForceY;
  double get gForceZ => _gForceZ;
  double get rawSpeed => _rawSpeed;

  // Active Alert System
  SafetyEvent? _currentAlert;
  SafetyEvent? get currentAlert => _currentAlert;

  // Threshold configurations
  static const double thresholdBraking = -3.2; // m/s^2 deceleration
  static const double thresholdAcceleration = 3.0; // m/s^2 acceleration
  static const double thresholdCornering = 3.8; // m/s^2 lateral acceleration

  StreamSubscription<UserAccelerometerEvent>? _sensorSub;
  DateTime _lastAlertTime = DateTime.fromMillisecondsSinceEpoch(0);
  final _uuid = const Uuid();

  // Settings
  bool _simulationMode = false; // Disabled by default so actual phone hardware sensors are read immediately
  bool get simulationMode => _simulationMode;

  void toggleSimulationMode(bool val) {
    _simulationMode = val;
    notifyListeners();
  }

  void startSensorMonitoring() {
    _sensorSub?.cancel();
    _sensorSub = SensorService.getAccelerometerStream().listen((event) {
      if (_simulationMode) return; // Ignore physical hardware during active simulation demos

      // Convert m/s^2 to G-Force values
      _gForceX = event.x / 9.80665;
      _gForceY = event.y / 9.80665;
      _gForceZ = event.z / 9.80665;

      _analyzeSensorData(event);
      notifyListeners();
    });
  }

  void stopSensorMonitoring() {
    _sensorSub?.cancel();
  }

  void updateSpeed(double speedKph) {
    _rawSpeed = speedKph;
    notifyListeners();
  }

  void _analyzeSensorData(UserAccelerometerEvent event) {
    final now = DateTime.now();
    if (now.difference(_lastAlertTime).inSeconds < 4) return; // Prevent alert flooding

    // Check acceleration peaks
    if (event.y < thresholdBraking) {
      triggerEvent("Harsh Braking", event.y.abs() / 9.8, "Maintain a 3-second spacing with vehicles ahead to allow gradual braking.");
    } else if (event.y > thresholdAcceleration) {
      triggerEvent("Rapid Acceleration", event.y / 9.8, "Squeeze the accelerator gently to save up to 15% fuel economy.");
    } else if (event.x.abs() > thresholdCornering) {
      triggerEvent("Sharp Turn", event.x.abs() / 9.8, "Reduce speed prior to entering curves to reduce cargo weight shifting.");
    }
  }

  // Visual Triggers / Simulation Methods
  void triggerEvent(String type, double forceValue, String aiTip) {
    final now = DateTime.now();
    _lastAlertTime = now;

    // Temporarily update G-Force to visually match the simulation event in dashboard radar
    if (_simulationMode) {
      final rand = Random();
      switch (type) {
        case "Harsh Braking":
          _gForceX = 0.05 * (rand.nextDouble() - 0.5);
          _gForceY = -0.5 - rand.nextDouble() * 0.4;
          break;
        case "Rapid Acceleration":
          _gForceX = 0.05 * (rand.nextDouble() - 0.5);
          _gForceY = 0.5 + rand.nextDouble() * 0.4;
          break;
        case "Sharp Turn":
          _gForceX = rand.nextBool() ? (0.6 + rand.nextDouble() * 0.3) : (-0.6 - rand.nextDouble() * 0.3);
          _gForceY = 0.1 * (rand.nextDouble() - 0.5);
          break;
        case "Crash":
          _gForceX = rand.nextBool() ? 1.5 : -1.5;
          _gForceY = rand.nextBool() ? 1.8 : -1.8;
          break;
        default:
          _gForceX = 0.0;
          _gForceY = 0.0;
      }
    }

    _currentAlert = SafetyEvent(
      id: _uuid.v4(),
      type: type,
      timestamp: now,
      severity: (type == "Crash") ? "High" : "Medium",
      latitude: 37.7749, // Mock default GPS positions
      longitude: -122.4194,
      triggerValue: forceValue,
      aiTip: aiTip,
    );

    notifyListeners();

    // Auto-clear alert popup banner after 3.5 seconds
    Timer(const Duration(milliseconds: 3500), () {
      _currentAlert = null;
      if (_simulationMode) {
        _gForceX = 0.0;
        _gForceY = 0.0;
      }
      notifyListeners();
    });
  }

  @override
  void dispose() {
    _sensorSub?.cancel();
    super.dispose();
  }
}