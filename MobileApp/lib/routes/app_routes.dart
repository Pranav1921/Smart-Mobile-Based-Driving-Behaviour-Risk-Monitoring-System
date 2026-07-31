import 'package:flutter/material.dart';

import '../screens/crash_screen.dart';
import '../screens/login_screen.dart';
import '../screens/main_navigation_screen.dart';
import '../screens/onboarding_screen.dart';
import '../screens/register_screen.dart';
import '../screens/splash_screen.dart';
import '../screens/trip_screen.dart';
import '../screens/trip_summary_screen.dart';
import '../screens/settings_screen.dart';

class AppRoutes {
  AppRoutes._();

  static const splash = "/";
  static const login = "/login";
  static const register = "/register";
  static const onboarding = "/onboarding";
  static const home = "/home"; // Houses MainNavigationScreen (bottom tabs)
  static const trip = "/trip"; // Active immersive driving navigation map
  static const summary = "/summary"; // Post-trip stats
  static const crash = "/crash"; // Active SOS screen
  static const settings = "/settings";

  static Map<String, WidgetBuilder> routes = {
    splash: (context) => const SplashScreen(),
    login: (context) => const LoginScreen(),
    register: (context) => const RegisterScreen(),
    onboarding: (context) => const OnboardingScreen(),
    home: (context) => const MainNavigationScreen(),
    trip: (context) => const TripScreen(),
    summary: (context) => const TripSummaryScreen(),
    crash: (context) => const CrashScreen(),
    settings: (context) => const SettingsScreen(),
  };
}