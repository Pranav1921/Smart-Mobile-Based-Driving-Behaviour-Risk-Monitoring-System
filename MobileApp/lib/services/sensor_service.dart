import 'dart:async';
import 'dart:math' as math;
import 'package:sensors_plus/sensors_plus.dart';
import 'package:vibration/vibration.dart';

class SensorTelemetryData {
  final double accelX;
  final double accelY;
  final double accelZ;
  final double gyroX; // in rad/s
  final double gyroY; // in rad/s
  final double gyroZ; // in rad/s
  final double magX;
  final double magY;
  final double magZ;
  final DateTime timestamp;

  SensorTelemetryData({
    required this.accelX,
    required this.accelY,
    required this.accelZ,
    required this.gyroX,
    required this.gyroY,
    required this.gyroZ,
    this.magX = 0.0,
    this.magY = 0.0,
    this.magZ = 0.0,
    required this.timestamp,
  });

  double get gMagnitude => math.sqrt(accelX * accelX + accelY * accelY + accelZ * accelZ) / 9.80665;
  double get gyroMagnitude => math.sqrt(gyroX * gyroX + gyroY * gyroY + gyroZ * gyroZ);
  double get gyroDegX => gyroX * (180.0 / math.pi);
  double get gyroDegY => gyroY * (180.0 / math.pi);
  double get gyroDegZ => gyroZ * (180.0 / math.pi);
}

class SensorService {
  SensorService._();

  static Stream<AccelerometerEvent> getRawAccelerometerStream() {
    try {
      return accelerometerEventStream(samplingPeriod: SensorInterval.uiInterval);
    } catch (_) {
      return accelerometerEvents;
    }
  }

  static Stream<UserAccelerometerEvent> getAccelerometerStream() {
    late StreamController<UserAccelerometerEvent> controller;
    StreamSubscription<UserAccelerometerEvent>? userAccelSub;
    StreamSubscription<AccelerometerEvent>? rawAccelSub;
    Timer? fallbackTimer;
    bool hasReceivedUserAccel = false;

    double gravX = 0.0;
    double gravY = 0.0;
    double gravZ = 9.80665;
    const double alpha = 0.82;

    void startRawFallback() {
      if (rawAccelSub != null || controller.isClosed) return;
      try {
        rawAccelSub = getRawAccelerometerStream().listen(
          (rawEvent) {
            gravX = alpha * gravX + (1.0 - alpha) * rawEvent.x;
            gravY = alpha * gravY + (1.0 - alpha) * rawEvent.y;
            gravZ = alpha * gravZ + (1.0 - alpha) * rawEvent.z;

            final linX = rawEvent.x - gravX;
            final linY = rawEvent.y - gravY;
            final linZ = rawEvent.z - gravZ;

            if (!controller.isClosed) {
              controller.add(UserAccelerometerEvent(linX, linY, linZ, rawEvent.timestamp));
            }
          },
          onError: (err) {
            print("[SensorService] Raw accelerometer fallback error: $err");
          },
          cancelOnError: false,
        );
      } catch (e) {
        print("[SensorService] Raw accelerometer fallback exception: $e");
      }
    }

    controller = StreamController<UserAccelerometerEvent>.broadcast(
      onListen: () {
        try {
          userAccelSub = userAccelerometerEventStream(samplingPeriod: SensorInterval.uiInterval).listen(
            (event) {
              hasReceivedUserAccel = true;
              fallbackTimer?.cancel();
              if (!controller.isClosed) {
                controller.add(event);
              }
            },
            onError: (err) {
              print("[SensorService] userAccelerometerEventStream error: $err, falling back to raw accelerometer");
              startRawFallback();
            },
            cancelOnError: false,
          );
        } catch (e) {
          print("[SensorService] userAccelerometerEventStream exception: $e, falling back to raw accelerometer");
          startRawFallback();
        }

        fallbackTimer = Timer(const Duration(milliseconds: 1200), () {
          if (!hasReceivedUserAccel) {
            print("[SensorService] No linear accel events received within 1.2s. Activating raw accelerometer fallback...");
            startRawFallback();
          }
        });
      },
      onCancel: () {
        fallbackTimer?.cancel();
        userAccelSub?.cancel();
        rawAccelSub?.cancel();
      },
    );

    return controller.stream;
  }

  static Stream<GyroscopeEvent> getGyroscopeStream() {
    try {
      return gyroscopeEventStream(samplingPeriod: SensorInterval.uiInterval);
    } catch (_) {
      return gyroscopeEvents;
    }
  }

  static Stream<MagnetometerEvent> getMagnetometerStream() {
    try {
      return magnetometerEventStream(samplingPeriod: SensorInterval.uiInterval);
    } catch (_) {
      return magnetometerEvents;
    }
  }

  static Future<void> vibrate({int duration = 500}) async {
    try {
      if (await Vibration.hasVibrator() ?? false) {
        Vibration.vibrate(duration: duration);
      }
    } catch (_) {}
  }

  // Combined real-time hardware sensor stream reading Accelerometer, Gyroscope & Magnetometer
  static Stream<SensorTelemetryData> getLiveSensorStream() {
    late StreamController<SensorTelemetryData> controller;
    StreamSubscription<UserAccelerometerEvent>? accelSub;
    StreamSubscription<GyroscopeEvent>? gyroSub;
    StreamSubscription<MagnetometerEvent>? magSub;

    double lastAccelX = 0.0;
    double lastAccelY = 0.0;
    double lastAccelZ = 0.0;
    double lastGyroX = 0.0;
    double lastGyroY = 0.0;
    double lastGyroZ = 0.0;
    double lastMagX = 0.0;
    double lastMagY = 0.0;
    double lastMagZ = 0.0;

    void emitCurrent() {
      if (!controller.isClosed) {
        controller.add(
          SensorTelemetryData(
            accelX: lastAccelX,
            accelY: lastAccelY,
            accelZ: lastAccelZ,
            gyroX: lastGyroX,
            gyroY: lastGyroY,
            gyroZ: lastGyroZ,
            magX: lastMagX,
            magY: lastMagY,
            magZ: lastMagZ,
            timestamp: DateTime.now(),
          ),
        );
      }
    }

    controller = StreamController<SensorTelemetryData>.broadcast(
      onListen: () {
        try {
          gyroSub = getGyroscopeStream().listen(
            (gEvent) {
              lastGyroX = gEvent.x;
              lastGyroY = gEvent.y;
              lastGyroZ = gEvent.z;
              emitCurrent();
            },
            onError: (err) {
              print("[SensorService] Gyro stream warning: $err");
            },
            cancelOnError: false,
          );
        } catch (e) {
          print("[SensorService] Could not initialize gyroscope: $e");
        }

        try {
          magSub = getMagnetometerStream().listen(
            (mEvent) {
              lastMagX = mEvent.x;
              lastMagY = mEvent.y;
              lastMagZ = mEvent.z;
            },
            onError: (err) {
              // Magnetometer is optional on some budget devices
            },
            cancelOnError: false,
          );
        } catch (_) {}

        try {
          accelSub = getAccelerometerStream().listen(
            (aEvent) {
              lastAccelX = aEvent.x;
              lastAccelY = aEvent.y;
              lastAccelZ = aEvent.z;
              emitCurrent();
            },
            onError: (err) {
              print("[SensorService] Accelerometer stream warning: $err");
            },
            cancelOnError: false,
          );
        } catch (e) {
          print("[SensorService] Could not initialize accelerometer: $e");
        }
      },
      onCancel: () {
        accelSub?.cancel();
        gyroSub?.cancel();
        magSub?.cancel();
      },
    );

    return controller.stream;
  }
}
