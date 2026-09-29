import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:sensors_plus/sensors_plus.dart';
import '../models/event_model.dart';
import '../services/sensor_service.dart';
import '../services/esp32_service.dart';
import '../services/haptic_service.dart';
import '../services/voice_service.dart';
import '../services/socket_service.dart';
import '../services/notification_service.dart';
import 'package:uuid/uuid.dart';

enum SensorDeviceStatus {
  healthy,
  defective,
  notConnected,
  unsupported,
  permissionDenied,
}

class SensorProvider extends ChangeNotifier {
  // ── SENSOR HEALTH & DEFECT DIAGNOSTICS ──────────────────────────────
  SensorDeviceStatus _phoneAccelStatus = SensorDeviceStatus.healthy;
  SensorDeviceStatus _phoneGyroStatus = SensorDeviceStatus.healthy;
  SensorDeviceStatus _gpsStatus = SensorDeviceStatus.healthy;
  SensorDeviceStatus _esp32HealthStatus = SensorDeviceStatus.notConnected;

  DateTime? _lastPhoneAccelTimestamp;
  DateTime? _lastPhoneGyroTimestamp;
  DateTime? _lastGpsTimestamp;
  DateTime? _lastEsp32Timestamp;
  Timer? _healthWatchdogTimer;

  // Smoothing buffers (Adaptive Exponential Moving Average) for fluid, responsive motion
  static const double _emaAlpha = 0.35;
  static const double _deadbandG = 0.06; // 0.06G deadband to eliminate resting/tabletop noise
  static const double _deadbandGyro = 0.04; // 0.04 rad/s sensitive deadband

  // Calibration zero-bias offsets (auto-tared at standstill)
  double _tareAccelX = 0.0;
  double _tareAccelY = 0.0;
  double _tareAccelZ = 0.0;
  int _stillSampleCount = 0;

  double _rawPhoneAccelX = 0.0;
  double _rawPhoneAccelY = 0.0;
  double _rawPhoneAccelZ = 0.0;
  double _rawPhoneGyroX = 0.0;
  double _rawPhoneGyroY = 0.0;
  double _rawPhoneGyroZ = 0.0;

  // -------------------------------------------------------------
  // DUAL SENSOR FUSION TELEMETRY (Phone Sensors + ESP32 Hardware Node)
  // -------------------------------------------------------------

  // Fused Combined Values (Mapped to Gs and rad/s)
  double _gForceX = 0.0;
  double _gForceY = 0.0;
  double _gForceZ = 0.0;
  double _gyroX = 0.0;
  double _gyroY = 0.0;
  double _gyroZ = 0.0;
  double _magX = 0.0;
  double _magY = 0.0;
  double _magZ = 0.0;
  double _vibrationRate = 0.0;
  double _rawSpeed = 0.0;

  // Discrete Phone Sensor Telemetry
  double _phoneGForceX = 0.0;
  double _phoneGForceY = 0.0;
  double _phoneGForceZ = 0.0;
  double _phoneGyroX = 0.0;
  double _phoneGyroY = 0.0;
  double _phoneGyroZ = 0.0;

  // Discrete ESP32 Hardware Node Telemetry
  double _esp32GForceX = 0.0;
  double _esp32GForceY = 0.0;
  double _esp32GForceZ = 0.0;
  double _esp32GyroX = 0.0;
  double _esp32GyroY = 0.0;
  double _esp32GyroZ = 0.0;

  // ESP32 Hardware Integration State
  bool _isEsp32Connected = false;
  bool _isScanningEsp32 = false;
  Esp32ConnectionType _connectionType = Esp32ConnectionType.none;
  Esp32DeviceStatus? _esp32Status;
  Timer? _esp32PollTimer;
  String _esp32Ip = Esp32Service.defaultNodeIp;
  int _wifiFailureCount = 0;

  // Active Monitoring State (Alerts active only when driver has started shift)
  bool _isMonitoringActive = false;
  bool get isMonitoringActive => _isMonitoringActive;

  void setMonitoringActive(bool active) {
    _isMonitoringActive = active;
    if (!active) {
      _currentAlert = null;
    }
    notifyListeners();
  }

  // Getters - Connection & Status
  bool get isEsp32Connected => _isEsp32Connected;
  bool get isScanningEsp32 => _isScanningEsp32;
  Esp32ConnectionType get connectionType => _connectionType;
  Esp32DeviceStatus? get esp32Status => _esp32Status;
  String get esp32Ip => _esp32Ip;
  bool get isBleConnected => _isEsp32Connected && _connectionType == Esp32ConnectionType.ble;
  bool get isWifiConnected => _isEsp32Connected && _connectionType == Esp32ConnectionType.wifi;
  bool get isDualSensorFused => _isEsp32Connected;

  // ── SENSOR HEALTH & DEFECT DIAGNOSTICS GETTERS ───────────────────
  SensorDeviceStatus get phoneAccelStatus => _phoneAccelStatus;
  SensorDeviceStatus get phoneGyroStatus => _phoneGyroStatus;
  SensorDeviceStatus get gpsStatus => _gpsStatus;
  SensorDeviceStatus get esp32HealthStatus => _isEsp32Connected ? _esp32HealthStatus : SensorDeviceStatus.notConnected;

  String get esp32ConnectionLabel => _isEsp32Connected
      ? (_connectionType == Esp32ConnectionType.ble ? "CONNECTED (BLE)" : "CONNECTED (Wi-Fi)")
      : "NOT CONNECTED";

  bool get hasAnyDefect =>
      _phoneAccelStatus == SensorDeviceStatus.defective ||
      _phoneGyroStatus == SensorDeviceStatus.defective ||
      _gpsStatus == SensorDeviceStatus.defective ||
      (_isEsp32Connected && _esp32HealthStatus == SensorDeviceStatus.defective);

  List<String> get defectDescriptions {
    final list = <String>[];
    if (_phoneAccelStatus == SensorDeviceStatus.defective) {
      list.add("Phone Accelerometer: Stream stalled / unresponsive");
    }
    if (_phoneGyroStatus == SensorDeviceStatus.defective) {
      list.add("Phone Gyroscope: Hardware unavailable or inactive");
    }
    if (_gpsStatus == SensorDeviceStatus.defective) {
      list.add("Phone GPS: Signal lost or location service disabled");
    }
    if (_isEsp32Connected && _esp32HealthStatus == SensorDeviceStatus.defective) {
      list.add("Chassis IMU Node: Wireless link lost / telemetry frozen");
    }
    return list;
  }

  void updateGpsStatus(bool hasSignal, double speedKph) {
    _rawSpeed = speedKph;
    if (hasSignal) {
      _lastGpsTimestamp = DateTime.now();
      if (_gpsStatus != SensorDeviceStatus.healthy) {
        _gpsStatus = SensorDeviceStatus.healthy;
        notifyListeners();
      }
    } else {
      if (_gpsStatus != SensorDeviceStatus.defective) {
        _gpsStatus = SensorDeviceStatus.defective;
        notifyListeners();
      }
    }
  }

  // Getters - Fused Telemetry
  double get gForceX => _gForceX;
  double get gForceY => _gForceY;
  double get gForceZ => _gForceZ;
  double get gyroX => _gyroX;
  double get gyroY => _gyroY;
  double get gyroZ => _gyroZ;
  double get magX => _magX;
  double get magY => _magY;
  double get magZ => _magZ;
  double get vibrationRate => _vibrationRate;
  double get rawSpeed => _rawSpeed;

  // Degrees / sec and Magnitude Computations
  double get gyroDegX => _gyroX * (180.0 / pi);
  double get gyroDegY => _gyroY * (180.0 / pi);
  double get gyroDegZ => _gyroZ * (180.0 / pi);
  double get totalAngularSpeed => sqrt(_gyroX * _gyroX + _gyroY * _gyroY + _gyroZ * _gyroZ);
  double get totalGForce => sqrt(_gForceX * _gForceX + _gForceY * _gForceY + _gForceZ * _gForceZ);

  // Getters - Phone-specific
  double get phoneGForceX => _phoneGForceX;
  double get phoneGForceY => _phoneGForceY;
  double get phoneGForceZ => _phoneGForceZ;
  double get phoneGyroX => _phoneGyroX;
  double get phoneGyroY => _phoneGyroY;
  double get phoneGyroZ => _phoneGyroZ;
  double get phoneGyroDegZ => _phoneGyroZ * (180.0 / pi);

  // Getters - ESP32-specific
  double get esp32GForceX => _esp32GForceX;
  double get esp32GForceY => _esp32GForceY;
  double get esp32GForceZ => _esp32GForceZ;
  double get esp32GyroX => _esp32GyroX;
  double get esp32GyroY => _esp32GyroY;
  double get esp32GyroZ => _esp32GyroZ;
  double get esp32GyroDegZ => _esp32GyroZ * (180.0 / pi);

  // Active Alert System
  SafetyEvent? _currentAlert;
  SafetyEvent? get currentAlert => _currentAlert;
  final List<SafetyEvent> _recentAlerts = [];
  List<SafetyEvent> get recentAlerts => List.unmodifiable(_recentAlerts);

  // Dynamic calibrated automotive thresholds (Driving conditions - Minute variations filtered out)
  static const double deadbandGForce = 0.40; // Gs below this are treated as baseline noise
  static const double thresholdBraking = -8.8; // m/s^2 deceleration (requires actual hard emergency braking)
  static const double thresholdAcceleration = 8.2; // m/s^2 launch
  static const double thresholdCornering = 9.2; // m/s^2 lateral acceleration (~0.94G - prevents normal turns from alerting)
  static const double thresholdGyroSwerve = 3.6; // rad/s (~206 deg/s violent swerve)
  static const double thresholdCrashG = 4.8; // High-G Crash Impact threshold (in motion)
  static const double thresholdStationaryCrashG = 7.0; // Stationary impact threshold (requires extreme violence to crash while stopped)

  // Crash & Road Hazard notification callbacks to TripProvider & Live Map
  void Function(String reason, double gForce, double speedBefore)? onCrashDetected;
  void Function(String type, double zForce, double lat, double lng, String roadName)? onRoadHazardDetected;
  final List<double> _recentZAxisReadings = [];

  StreamSubscription<UserAccelerometerEvent>? _sensorSub;
  StreamSubscription<GyroscopeEvent>? _gyroSub;
  StreamSubscription<MagnetometerEvent>? _magSub;
  DateTime _lastAlertTime = DateTime.fromMillisecondsSinceEpoch(0);
  DateTime _lastTurnAlertTime = DateTime.fromMillisecondsSinceEpoch(0);
  DateTime _lastPotholeAlertTime = DateTime.fromMillisecondsSinceEpoch(0);
  final _uuid = const Uuid();

  // Settings
  bool _simulationMode = false;
  bool get simulationMode => _simulationMode;

  double? _currentLat;
  double? _currentLng;
  void updateLocation(double lat, double lng) {
    _currentLat = lat;
    _currentLng = lng;
  }

  SensorProvider() {
    // Start sensor streams for visual radar meters
    startSensorMonitoring();
    _startHealthWatchdog();
  }

  void _startHealthWatchdog() {
    _healthWatchdogTimer?.cancel();
    _healthWatchdogTimer = Timer.periodic(const Duration(seconds: 2), (timer) {
      final now = DateTime.now();
      bool changed = false;

      // Check Phone Accelerometer with generous stillness margin and auto-revive
      if (_lastPhoneAccelTimestamp != null && now.difference(_lastPhoneAccelTimestamp!).inSeconds > 12) {
        if (_phoneAccelStatus != SensorDeviceStatus.defective) {
          _phoneAccelStatus = SensorDeviceStatus.defective;
          changed = true;
          // Auto-revive stream
          startSensorMonitoring();
        }
      }

      // Check Phone Gyroscope
      if (_lastPhoneGyroTimestamp != null && now.difference(_lastPhoneGyroTimestamp!).inSeconds > 12) {
        if (_phoneGyroStatus != SensorDeviceStatus.defective) {
          _phoneGyroStatus = SensorDeviceStatus.defective;
          changed = true;
        }
      }

      // Check ESP32 if connected
      if (_isEsp32Connected) {
        if (_lastEsp32Timestamp != null && now.difference(_lastEsp32Timestamp!).inSeconds > 5) {
          if (_esp32HealthStatus != SensorDeviceStatus.defective) {
            _esp32HealthStatus = SensorDeviceStatus.defective;
            changed = true;
          }
        } else if (_esp32HealthStatus != SensorDeviceStatus.healthy) {
          _esp32HealthStatus = SensorDeviceStatus.healthy;
          changed = true;
        }
      } else {
        if (_esp32HealthStatus != SensorDeviceStatus.notConnected) {
          _esp32HealthStatus = SensorDeviceStatus.notConnected;
          changed = true;
        }
      }

      if (changed) {
        notifyListeners();
      }
    });
  }

  void toggleSimulationMode(bool val) {
    _simulationMode = val;
    notifyListeners();
  }

  DateTime _lastNotifyTime = DateTime.fromMillisecondsSinceEpoch(0);

  void _throttledNotify() {
    final now = DateTime.now();
    if (now.difference(_lastNotifyTime).inMilliseconds >= 120) { // ~8.3Hz smooth UI updates
      _lastNotifyTime = now;
      notifyListeners();
    }
  }

  // -------------------------------------------------------------
  // DUAL SENSOR FUSION ENGINE
  // -------------------------------------------------------------
  void _fuseSensorData() {
    if (_isEsp32Connected) {
      // Complementary fusion filter: 60% ESP32 chassis IMU + 40% Phone IMU
      _gForceX = (0.60 * _esp32GForceX) + (0.40 * _phoneGForceX);
      _gForceY = (0.60 * _esp32GForceY) + (0.40 * _phoneGForceY);
      _gForceZ = (0.60 * _esp32GForceZ) + (0.40 * _phoneGForceZ);

      _gyroX = (0.60 * _esp32GyroX) + (0.40 * _phoneGyroX);
      _gyroY = (0.60 * _esp32GyroY) + (0.40 * _phoneGyroY);
      _gyroZ = (0.60 * _esp32GyroZ) + (0.40 * _phoneGyroZ);

      // ESP32 dynamic vibration rate in Gs (remove 1G gravity vector)
      final esp32TotalG = sqrt(_esp32GForceX * _esp32GForceX + _esp32GForceY * _esp32GForceY + _esp32GForceZ * _esp32GForceZ);
      final esp32DynG = (esp32TotalG - 1.0).abs();

      final phoneDynG = sqrt(_phoneGForceX * _phoneGForceX + _phoneGForceY * _phoneGForceY + _phoneGForceZ * _phoneGForceZ);

      final double combinedDynG = (0.60 * esp32DynG) + (0.40 * phoneDynG);
      _vibrationRate = combinedDynG < 0.25 ? 0.0 : combinedDynG;
    } else {
      // External ESP32 NOT connected: ensure chassis values remain strictly 0.0
      _esp32GForceX = 0.0;
      _esp32GForceY = 0.0;
      _esp32GForceZ = 0.0;
      _esp32GyroX = 0.0;
      _esp32GyroY = 0.0;
      _esp32GyroZ = 0.0;

      // Pure Phone Sensor Data: UserAccelerometerEvent is already linear acceleration (0G at rest)
      _gForceX = _phoneGForceX;
      _gForceY = _phoneGForceY;
      _gForceZ = _phoneGForceZ;
      _gyroX = _phoneGyroX;
      _gyroY = _phoneGyroY;
      _gyroZ = _phoneGyroZ;

      final phoneDynG = sqrt(_phoneGForceX * _phoneGForceX + _phoneGForceY * _phoneGForceY + _phoneGForceZ * _phoneGForceZ);
      _vibrationRate = phoneDynG < 0.25 ? 0.0 : phoneDynG;
    }

    _throttledNotify();
  }

  // -------------------------------------------------------------
  // ESP32 BLUETOOTH LOW ENERGY (BLE) METHODS
  // -------------------------------------------------------------
  Future<bool> connectBle(BluetoothDevice device) async {
    _isScanningEsp32 = true;
    notifyListeners();

    try {
      if (_connectionType == Esp32ConnectionType.wifi) {
        _esp32PollTimer?.cancel();
      }

      final success = await Esp32Service.connectBle(
        device: device,
        onTelemetry: (status) {
          _handleIncomingTelemetry(status);
        },
        onDisconnected: () {
          _isEsp32Connected = false;
          _connectionType = Esp32ConnectionType.none;
          _esp32Status = null;
          _esp32HealthStatus = SensorDeviceStatus.notConnected;
          _esp32GForceX = 0;
          _esp32GForceY = 0;
          _esp32GForceZ = 0;
          _esp32GyroX = 0;
          _esp32GyroY = 0;
          _esp32GyroZ = 0;
          HapticService.lightImpact();
          _fuseSensorData();
          notifyListeners();
        },
      );

      _isScanningEsp32 = false;

      if (success) {
        _isEsp32Connected = true;
        _connectionType = Esp32ConnectionType.ble;
        _esp32HealthStatus = SensorDeviceStatus.healthy;
        _lastEsp32Timestamp = DateTime.now();
        _esp32Status = Esp32DeviceStatus(
          isConnected: true,
          isBle: true,
          deviceId: device.platformName.isNotEmpty ? device.platformName : "SmartDrive-BLE",
          sensorConnected: true,
        );
        HapticService.success();
        notifyListeners();
        return true;
      } else {
        _isEsp32Connected = false;
        _connectionType = Esp32ConnectionType.none;
        _esp32Status = null;
        _esp32HealthStatus = SensorDeviceStatus.notConnected;
        _esp32GForceX = 0;
        _esp32GForceY = 0;
        _esp32GForceZ = 0;
        _esp32GyroX = 0;
        _esp32GyroY = 0;
        _esp32GyroZ = 0;
        HapticService.error();
        notifyListeners();
        return false;
      }
    } catch (_) {
      _isScanningEsp32 = false;
      _isEsp32Connected = false;
      _connectionType = Esp32ConnectionType.none;
      _esp32Status = null;
      HapticService.error();
      notifyListeners();
      return false;
    }
  }

  // -------------------------------------------------------------
  // ESP32 WI-FI SENSOR FUSION METHODS (Resilient Polling)
  // -------------------------------------------------------------
  Future<bool> scanAndConnectEsp32({String ip = Esp32Service.defaultNodeIp}) async {
    _isScanningEsp32 = true;
    _esp32Ip = ip;
    notifyListeners();

    try {
      if (_connectionType == Esp32ConnectionType.ble) {
        await Esp32Service.disconnectBle();
      }

      final discoveredIp = await Esp32Service.autoDiscoverEsp32(initialIp: ip);
      _isScanningEsp32 = false;

      if (discoveredIp != null) {
        _esp32Ip = discoveredIp;
        final status = await Esp32Service.probeNode(ip: discoveredIp);
        if (status.isConnected) {
          _isEsp32Connected = true;
          _connectionType = Esp32ConnectionType.wifi;
          _esp32Status = status;
          _wifiFailureCount = 0;
          _startEsp32WifiPolling();
          HapticService.success();
          notifyListeners();
          return true;
        }
      }

      _isEsp32Connected = false;
      _connectionType = Esp32ConnectionType.none;
      _esp32Status = null;
      HapticService.error();
      notifyListeners();
      return false;
    } catch (_) {
      _isScanningEsp32 = false;
      _isEsp32Connected = false;
      _connectionType = Esp32ConnectionType.none;
      _esp32Status = null;
      HapticService.error();
      notifyListeners();
      return false;
    }
  }

  Future<void> disconnectEsp32() async {
    _esp32PollTimer?.cancel();
    _esp32PollTimer = null;
    if (_connectionType == Esp32ConnectionType.ble) {
      await Esp32Service.disconnectBle();
    }
    _isEsp32Connected = false;
    _connectionType = Esp32ConnectionType.none;
    _esp32Status = null;
    _esp32HealthStatus = SensorDeviceStatus.notConnected;
    _wifiFailureCount = 0;
    _esp32GForceX = 0;
    _esp32GForceY = 0;
    _esp32GForceZ = 0;
    _esp32GyroX = 0;
    _esp32GyroY = 0;
    _esp32GyroZ = 0;
    HapticService.lightImpact();
    _fuseSensorData();
    notifyListeners();
  }

  bool _isPollingEsp32 = false;

  void _startEsp32WifiPolling() {
    _esp32PollTimer?.cancel();
    _wifiFailureCount = 0;

    _esp32PollTimer = Timer.periodic(const Duration(milliseconds: 200), (timer) async {
      if (!_isEsp32Connected || _connectionType != Esp32ConnectionType.wifi) {
        timer.cancel();
        return;
      }

      if (_isPollingEsp32) return;
      _isPollingEsp32 = true;

      try {
        final status = await Esp32Service.probeNode(ip: _esp32Ip);
        if (status.isConnected) {
          _wifiFailureCount = 0;
          _handleIncomingTelemetry(status);
        } else {
          _wifiFailureCount++;
          if (_wifiFailureCount >= 5) {
            _isEsp32Connected = false;
            _connectionType = Esp32ConnectionType.none;
            _esp32Status = null;
            _esp32HealthStatus = SensorDeviceStatus.notConnected;
            timer.cancel();
            _fuseSensorData();
            notifyListeners();
          }
        }
      } catch (_) {
        _wifiFailureCount++;
        if (_wifiFailureCount >= 5) {
          _isEsp32Connected = false;
          _connectionType = Esp32ConnectionType.none;
          _esp32Status = null;
          _esp32HealthStatus = SensorDeviceStatus.notConnected;
          timer.cancel();
          _fuseSensorData();
          notifyListeners();
        }
      } finally {
        _isPollingEsp32 = false;
      }
    });
  }

  void _handleIncomingTelemetry(Esp32DeviceStatus status) {
    _lastEsp32Timestamp = DateTime.now();
    _esp32Status = status;
    if (_esp32HealthStatus != SensorDeviceStatus.healthy) {
      _esp32HealthStatus = SensorDeviceStatus.healthy;
    }

    _esp32GForceX = _deadband(status.ax / 9.80665, _deadbandG);
    _esp32GForceY = _deadband(status.ay / 9.80665, _deadbandG);
    _esp32GForceZ = _deadband(status.az / 9.80665, _deadbandG);
    _esp32GyroX = _deadband(status.gx, _deadbandGyro);
    _esp32GyroY = _deadband(status.gy, _deadbandGyro);
    _esp32GyroZ = _deadband(status.gz, _deadbandGyro);

    // Run real-time detection on incoming ESP32 gyroscope and accelerometer data (only if driver started shift)
    if (_isMonitoringActive || _simulationMode) {
      _analyzeGyroscopeData(GyroscopeEvent(status.gx, status.gy, status.gz, DateTime.now()));
      _analyzeAccelerometerData(UserAccelerometerEvent(status.ax, status.ay, status.az, DateTime.now()));
    }

    // High-G collision shockwave reported by ESP32 node
    // CRITICAL: NEVER trigger false crashes when stationary or crawling (< 15 km/h)
    // A stationary vehicle requires severe high-impact force (>= 7.0 G) to be classified as a crash.
    final now = DateTime.now();
    final bool isCooldownActive = now.difference(_lastAlertTime).inMilliseconds < 4500;

    if ((_isMonitoringActive || _simulationMode) && !isCooldownActive) {
      final double totalG = sqrt(status.ax * status.ax + status.ay * status.ay + status.az * status.az) / 9.80665;
      final double effectiveG = status.gMagnitude > 1.0 ? status.gMagnitude : totalG;
      final double speedBefore = _rawSpeed;
      final bool isDrivingFast = speedBefore >= 15.0;

      // 1. Driving Collision: speed >= 15 km/h and high impact (>= 4.5 G)
      if (isDrivingFast && ((status.impactDetected && effectiveG >= 4.0) || effectiveG >= thresholdCrashG)) {
        final String reason = "Chassis Collision Impact (${effectiveG.toStringAsFixed(1)} G at ${speedBefore.toInt()} km/h)";
        triggerEvent("Crash / Severe Impact", effectiveG, "Emergency impact detected by chassis node! Verify vehicle safety.");
        onCrashDetected?.call(reason, effectiveG, speedBefore);
      } 
      // 2. Severe Stationary Collision: parked/stopped vehicle violently hit (requires >= 7.0 G)
      else if (!isDrivingFast && effectiveG >= thresholdStationaryCrashG && status.impactDetected) {
        final String reason = "Severe Stationary Collision Impact (${effectiveG.toStringAsFixed(1)} G)";
        triggerEvent("Crash / Severe Impact", effectiveG, "Stationary high-force impact detected! Verify vehicle safety.");
        onCrashDetected?.call(reason, effectiveG, speedBefore);
      }
    }

    _fuseSensorData();
  }

  double _deadband(double val, double threshold) {
    if (val.abs() < threshold) return 0.0;
    return val;
  }

  // -------------------------------------------------------------
  // CONTINUOUS SENSOR MONITORING & REAL-TIME ANALYSIS
  // -------------------------------------------------------------
  void startSensorMonitoring() {
    _sensorSub?.cancel();
    try {
      _sensorSub = SensorService.getAccelerometerStream().listen(
        (event) {
          _lastPhoneAccelTimestamp = DateTime.now();
          if (_phoneAccelStatus != SensorDeviceStatus.healthy) {
            _phoneAccelStatus = SensorDeviceStatus.healthy;
          }

          final rawGX = (event.x / 9.80665) - _tareAccelX;
          final rawGY = (event.y / 9.80665) - _tareAccelY;
          final rawGZ = (event.z / 9.80665) - _tareAccelZ;

          // Auto-tare zero offset calibration when vehicle is stationary (< 2.0 km/h)
          if (_rawSpeed < 2.0) {
            _stillSampleCount++;
            if (_stillSampleCount > 10) {
              _tareAccelX = 0.96 * _tareAccelX + 0.04 * (event.x / 9.80665);
              _tareAccelY = 0.96 * _tareAccelY + 0.04 * (event.y / 9.80665);
              _tareAccelZ = 0.96 * _tareAccelZ + 0.04 * (event.z / 9.80665);
            }
          } else {
            _stillSampleCount = 0;
          }

          // Adaptive low-pass filter (high alpha on real spikes, smooth alpha on jitter)
          final double deltaMag = ((rawGX - _rawPhoneAccelX).abs() + (rawGY - _rawPhoneAccelY).abs() + (rawGZ - _rawPhoneAccelZ).abs());
          final double alpha = deltaMag > 0.5 ? 0.65 : 0.22;

          _rawPhoneAccelX = (alpha * rawGX) + ((1.0 - alpha) * _rawPhoneAccelX);
          _rawPhoneAccelY = (alpha * rawGY) + ((1.0 - alpha) * _rawPhoneAccelY);
          _rawPhoneAccelZ = (alpha * rawGZ) + ((1.0 - alpha) * _rawPhoneAccelZ);

          // Apply deadband filter to eliminate noise when resting / tabletop
          _phoneGForceX = _deadband(_rawPhoneAccelX, _deadbandG);
          _phoneGForceY = _deadband(_rawPhoneAccelY, _deadbandG);
          _phoneGForceZ = _deadband(_rawPhoneAccelZ, _deadbandG);

          if (_isMonitoringActive || _simulationMode) {
            _analyzeAccelerometerData(event);
          }
          _fuseSensorData();
        },
        onError: (err) {
          print("[SensorProvider] Accelerometer error: $err");
          _phoneAccelStatus = SensorDeviceStatus.defective;
          notifyListeners();
        },
        cancelOnError: false,
      );
    } catch (e) {
      print("[SensorProvider] Accelerometer setup exception: $e");
      _phoneAccelStatus = SensorDeviceStatus.unsupported;
    }

    _gyroSub?.cancel();
    try {
      _gyroSub = SensorService.getGyroscopeStream().listen(
        (event) {
          _lastPhoneGyroTimestamp = DateTime.now();
          if (_phoneGyroStatus != SensorDeviceStatus.healthy) {
            _phoneGyroStatus = SensorDeviceStatus.healthy;
          }

          // Low-pass filter (Exponential Moving Average) to eliminate micro-jitters
          _rawPhoneGyroX = (_emaAlpha * event.x) + ((1.0 - _emaAlpha) * _rawPhoneGyroX);
          _rawPhoneGyroY = (_emaAlpha * event.y) + ((1.0 - _emaAlpha) * _rawPhoneGyroY);
          _rawPhoneGyroZ = (_emaAlpha * event.z) + ((1.0 - _emaAlpha) * _rawPhoneGyroZ);

          _phoneGyroX = _deadband(_rawPhoneGyroX, _deadbandGyro);
          _phoneGyroY = _deadband(_rawPhoneGyroY, _deadbandGyro);
          _phoneGyroZ = _deadband(_rawPhoneGyroZ, _deadbandGyro);

          if (_isMonitoringActive || _simulationMode) {
            _analyzeGyroscopeData(event);
          }
          _fuseSensorData();
        },
        onError: (err) {
          print("[SensorProvider] Gyroscope error: $err");
          _phoneGyroStatus = SensorDeviceStatus.defective;
          notifyListeners();
        },
        cancelOnError: false,
      );
    } catch (e) {
      print("[SensorProvider] Gyroscope setup exception: $e");
      _phoneGyroStatus = SensorDeviceStatus.unsupported;
    }

    _magSub?.cancel();
    try {
      _magSub = SensorService.getMagnetometerStream().listen(
        (event) {
          _magX = event.x;
          _magY = event.y;
          _magZ = event.z;
          _fuseSensorData();
        },
        onError: (err) {},
        cancelOnError: false,
      );
    } catch (_) {}
  }

  void stopSensorMonitoring() {
    _sensorSub?.cancel();
    _gyroSub?.cancel();
    _magSub?.cancel();
    _esp32PollTimer?.cancel();
  }

  void updateSpeed(double speedKph) {
    _rawSpeed = speedKph;
    notifyListeners();
  }

  // 1. Accelerometer & High-G Crash Impact Analysis
  void _analyzeAccelerometerData(UserAccelerometerEvent event) {
    if (!_isMonitoringActive && !_simulationMode) return;

    final now = DateTime.now();

    // Linear motion acceleration checks
    final double ax = _isEsp32Connected ? (_esp32GForceX * 9.80665) : event.x;
    final double ay = _isEsp32Connected ? (_esp32GForceY * 9.80665) : event.y;
    final double az = _isEsp32Connected ? (_esp32GForceZ * 9.80665) : event.z;

    final double currentTotalForce = sqrt(ax * ax + ay * ay + az * az);
    final double rawGForce = currentTotalForce / 9.80665;
    final double dynamicGForce = _isEsp32Connected ? (rawGForce - 1.0).abs() : rawGForce;

    // ── HIGH-G IMPACT & CRASH DETECTION ──────────────────────────────────
    if (dynamicGForce >= thresholdCrashG) {
      if (now.difference(_lastAlertTime).inMilliseconds < 5000) return;
      final double speedBefore = _rawSpeed;
      final bool isMoving = speedBefore >= 15.0;
      final bool isStationarySevere = (!isMoving && dynamicGForce >= thresholdStationaryCrashG);

      if (isMoving || isStationarySevere || _simulationMode) {
        final String severityTag = dynamicGForce >= 6.5 ? "Severe Collision" : "High-Impact Collision";
        final String reason = isMoving
            ? "$severityTag (${dynamicGForce.toStringAsFixed(1)} G at ${speedBefore.toInt()} km/h)"
            : "Stationary Impact Shockwave (${dynamicGForce.toStringAsFixed(1)} G)";

        triggerEvent("Crash / Collision", dynamicGForce, "Massive impact shockwave registered! Escalating emergency safety protocol.");
        onCrashDetected?.call(reason, dynamicGForce, speedBefore);
        return;
      }
    }

    // ── Z-AXIS ROAD HAZARD & POTHOLE DETECTION ───────────────────────────
    // When the sensor observes that Z-axis values are more (dominant vertical acceleration),
    // there is a high chance that it is a pothole!
    final double zForce = (az / 9.80665).abs();
    final double planarForce = sqrt(ax * ax + ay * ay) / 9.80665;
    final bool isMovingForPothole = (_rawSpeed >= 12.0 || _simulationMode);
    final bool isZDominantPothole = isMovingForPothole && zForce >= 1.90 && (zForce > (planarForce * 1.25) || zForce >= 2.4);

    if (isZDominantPothole) {
      if (now.difference(_lastPotholeAlertTime).inSeconds >= 4) {
        _lastPotholeAlertTime = now;
        onRoadHazardDetected?.call("pothole", zForce, _currentLat ?? 0.0, _currentLng ?? 0.0, "Active Transit Corridor");
        NotificationService.showSafetyAlert(
          "POTHOLE DETECTED",
          "Vertical shock (${zForce.toStringAsFixed(1)} G) registered. Pothole location pinned on live map.",
        );
        HapticService.mediumImpact();
      }
      return;
    }

    // ── MINUTE VIBRATION SUPPRESSION ──────────────────────────────────────
    // Normal road surface texture & subtle vibrations (< 2.2G) are tracked in telemetry
    // but NEVER trigger loud driver notifications or audio prompts.
    if (dynamicGForce < 2.2 && !_simulationMode) {
      return;
    }

    // ── DRIVING BEHAVIOR ANOMALIES (Requires genuine road speed >= 28 km/h) ─
    final bool isRealDrivingMotion = (_rawSpeed >= 28.0 || _simulationMode);
    if (!isRealDrivingMotion) return;

    if (now.difference(_lastAlertTime).inMilliseconds < 15000) return;

    if (ay < thresholdBraking) {
      triggerEvent(
        "Harsh Braking",
        ay.abs() / 9.80665,
        "Emergency deceleration detected. Increase following distance.",
      );
    } else if (ay > thresholdAcceleration) {
      triggerEvent(
        "Rapid Acceleration",
        ay / 9.80665,
        "Heavy launch throttle detected. Apply smooth acceleration.",
      );
    } else if (ax.abs() > thresholdCornering) {
      // Cooldown for sharp turns to avoid alert spam on winding roads
      if (now.difference(_lastTurnAlertTime).inSeconds >= 25) {
        _lastTurnAlertTime = now;
        triggerEvent(
          "Sharp Turn",
          ax.abs() / 9.80665,
          "High lateral G-force in corner. Reduce speed prior to turn.",
        );
      }
    }
  }

  // 2. Gyroscope Angular Velocity & Swerve Analysis (Requires actual driving speed)
  void _analyzeGyroscopeData(GyroscopeEvent event) {
    if (!_isMonitoringActive && !_simulationMode) return;

    final now = DateTime.now();
    // Requires real vehicle road speed (>= 28 km/h) to avoid false alerts on residential turns/parking
    final bool isRealDrivingMotion = (_rawSpeed >= 28.0 || _simulationMode);
    if (!isRealDrivingMotion) return;

    if (now.difference(_lastAlertTime).inMilliseconds < 15000) return;

    final double gz = _isEsp32Connected ? _esp32GyroZ : event.z;

    // Phone Pick-up / Unmount Distraction Detection:
    if ((_rawSpeed >= 20.0 || _simulationMode) && (event.x.abs() > 2.8 || event.y.abs() > 2.8) && gz.abs() < 1.0) {
      triggerEvent(
        "Phone Pick-up Distraction",
        max(event.x.abs(), event.y.abs()),
        "Phone unmounted or manipulated while in transit. Keep eyes on road and hands on wheel.",
      );
      return;
    }

    // Severe swerve check with 25s debounce
    if (gz.abs() > thresholdGyroSwerve) {
      if (now.difference(_lastTurnAlertTime).inSeconds >= 25) {
        _lastTurnAlertTime = now;
        triggerEvent(
          "Sharp Gyro Swerve",
          gz.abs(),
          "Violent yaw rotation detected. Maintain smooth, controlled steering.",
        );
      }
    }
  }

  // Visual Triggers, Audio Prompt & Alert History Dispatch
  void triggerEvent(String type, double forceValue, String aiTip) {
    // Only dispatch alerts if the driver has started the shift / monitoring is active
    if (!_isMonitoringActive && !_simulationMode) return;

    final now = DateTime.now();
    _lastAlertTime = now;

    final alert = SafetyEvent(
      id: _uuid.v4(),
      type: type,
      timestamp: now,
      severity: (type == "Crash" || type.contains("Crash") || type == "Sharp Gyro Swerve" || type.contains("Phone")) ? "High" : "Medium",
      latitude: _currentLat ?? 0.0,
      longitude: _currentLng ?? 0.0,
      triggerValue: forceValue,
      aiTip: aiTip,
    );

    // 1. Dispatch Alert to DRIVER (In-App floating banner, notification banner, sensory haptic & audio)
    _currentAlert = alert;
    _recentAlerts.insert(0, alert);
    if (_recentAlerts.length > 20) {
      _recentAlerts.removeLast();
    }

    HapticService.heavyImpact();
    SensorService.vibrate(duration: 350);
    VoiceService.speak("Caution: $type detected.");
    NotificationService.showSafetyAlert("DRIVER SAFETY ALERT", "$type: $aiTip");

    // 2. Dispatch Alert to ADMIN (Real-time WebSocket event)
    try {
      SocketService.emitRuleViolation({
        'ruleType': type,
        'ruleTitle': type,
        'severity': alert.severity.toUpperCase(),
        'value': forceValue,
        'aiTip': aiTip,
        'description': "$type detected ($forceValue G): $aiTip",
        'latitude': _currentLat ?? 0.0,
        'longitude': _currentLng ?? 0.0,
        'timestamp': now.toIso8601String(),
      });
    } catch (_) {}

    notifyListeners();

    // Auto-dismiss floating banner after 4.2 seconds
    Timer(const Duration(milliseconds: 4200), () {
      if (_currentAlert?.id == alert.id) {
        _currentAlert = null;
        notifyListeners();
      }
    });
  }

  /// Manually triggers a test sensor alert for demonstration (only when driver shift is active)
  void simulateSensorAlert(String type) {
    if (!_isMonitoringActive && !_simulationMode) {
      VoiceService.speak("Please start your shift to activate live safety monitoring.");
      NotificationService.showSafetyAlert("SHIFT INACTIVE", "Start your shift to enable live monitoring and alert dispatch to both Driver & Admin.");
      return;
    }

    switch (type) {
      case "gyro":
        triggerEvent("Sharp Gyro Swerve", 2.35, "Sudden yaw rotation detected (2.35 rad/s). Steer steadily through curves.");
        break;
      case "distraction":
      case "phone_pickup":
        triggerEvent("Phone Pick-up Distraction", 2.45, "Phone unmounted while vehicle in motion. Keep hands on wheel.");
        break;
      case "vibration":
      case "bad_road":
        triggerEvent("Bad Road Section", 3.80, "High chassis oscillation (3.80 m/s²). Slow down on uneven road surfaces.");
        onRoadHazardDetected?.call("bad_road", 3.80, _currentLat ?? 0.0, _currentLng ?? 0.0, "Transit Corridor");
        break;
      case "pothole":
        triggerEvent("Pothole Impact", 4.20, "Sudden vertical shock detected (4.20 G). Pothole location pinned on live map.");
        onRoadHazardDetected?.call("pothole", 4.20, _currentLat ?? 0.0, _currentLng ?? 0.0, "Transit Corridor");
        break;
      case "braking":
        triggerEvent("Harsh Braking", 0.75, "Hard deceleration detected. Increase vehicle spacing ahead.");
        break;
      default:
        triggerEvent("Motion Alert", 1.5, "Sensor anomaly detected. Drive with caution.");
    }
  }

  @override
  void dispose() {
    _healthWatchdogTimer?.cancel();
    _sensorSub?.cancel();
    _gyroSub?.cancel();
    _magSub?.cancel();
    _esp32PollTimer?.cancel();
    super.dispose();
  }
}