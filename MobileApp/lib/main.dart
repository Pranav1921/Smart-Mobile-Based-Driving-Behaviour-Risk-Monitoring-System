import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'app.dart';
import 'providers/auth_provider.dart';
import 'providers/dashboard_provider.dart';
import 'providers/sensor_provider.dart';
import 'providers/trip_provider.dart';
import 'providers/theme_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Providers and load local profiles/history
  final authProvider = AuthProvider();
  final tripProvider = TripProvider();
  final sensorProvider = SensorProvider();
  final dashboardProvider = DashboardProvider();

  // Trigger check routines in background
  await authProvider.checkAuthStatus();
  await tripProvider.initHistory();

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
}