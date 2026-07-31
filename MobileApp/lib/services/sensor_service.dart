import 'dart:async';
import 'package:sensors_plus/sensors_plus.dart';

class SensorService {
  SensorService._();

  static Stream<UserAccelerometerEvent> getAccelerometerStream() {
    return userAccelerometerEvents;
  }

  static Stream<GyroscopeEvent> getGyroscopeStream() {
    return gyroscopeEvents;
  }
}
