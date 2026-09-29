import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:mobile_app/app.dart';
import 'package:mobile_app/providers/auth_provider.dart';
import 'package:mobile_app/providers/dashboard_provider.dart';
import 'package:mobile_app/providers/sensor_provider.dart';
import 'package:mobile_app/providers/trip_provider.dart';
import 'package:mobile_app/providers/theme_provider.dart';
import 'package:mobile_app/services/notification_service.dart';
import 'package:mobile_app/services/socket_service.dart';
import 'package:mobile_app/services/voice_service.dart';

import 'package:mobile_app/services/discovery_service.dart';
import 'package:mobile_app/services/api_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Pre-warm backend auto-discovery asynchronously so login is instant
  DiscoveryService.autoDiscoverHost().then((host) {
    if (host != null) {
      ApiService.setCustomHost(host);
    }
  }).catchError((_) {});

  // Silence verbose BLE characteristic notification logcat spam
  FlutterBluePlus.setLogLevel(LogLevel.none, color: false);

  try {
    await NotificationService.init();
    await VoiceService.init();
  } catch (_) {}

  // Initialize Providers and load local profiles/history
  final authProvider = AuthProvider();
  final tripProvider = TripProvider();
  final sensorProvider = SensorProvider();
  final dashboardProvider = DashboardProvider();

  // Scope and reload telemetry history when driver logs in, switches, or logs out
  authProvider.onDriverChanged = (driverId) {
    if (driverId != null && driverId.isNotEmpty) {
      tripProvider.loadForDriver(driverId);
    } else {
      tripProvider.resetDriverData();
    }
  };

  SocketService.onDriverCheckPingCallback = (msg) {
     tripProvider.handleAdminPing(msg);
  };

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider<ThemeProvider>(create: (_) => ThemeProvider()),
        ChangeNotifierProvider<AuthProvider>.value(value: authProvider),
        ChangeNotifierProvider<TripProvider>.value(value: tripProvider),
        ChangeNotifierProvider<SensorProvider>.value(value: sensorProvider),
        ChangeNotifierProvider<DashboardProvider>.value(value: dashboardProvider),
      ],
      child: const DriverSafetyApp(),
    ),
  );

  tripProvider.bindSensorProvider(sensorProvider);

  tripProvider.onShiftStateChanged = (active) {
    sensorProvider.setMonitoringActive(active);
  };

  // Trigger background routines asynchronously after UI mount
  authProvider.checkAuthStatus().then((_) {
    tripProvider.initHistory();
    tripProvider.checkShiftPersistence();
    sensorProvider.setMonitoringActive(tripProvider.isShiftActive);
  }).catchError((_) {});
}