import 'package:flutter/material.dart';

import '../screens/crash_screen.dart';
import '../screens/login_screen.dart';
import '../screens/main_navigation_screen.dart';
import '../screens/intro_onboarding_screen.dart';
import '../screens/orders_screen.dart';
import '../screens/register_screen.dart';
import '../screens/splash_screen.dart';
import '../screens/trip_screen.dart';
import '../screens/trip_summary_screen.dart';
import '../screens/settings_screen.dart';
import '../screens/notifications_screen.dart';
import '../screens/earnings_screen.dart';
import '../screens/history_screen.dart';
import '../screens/map_screen.dart';
import '../screens/edit_profile_screen.dart';
import '../screens/profile_screen.dart';
import '../screens/payments_screen.dart';
import '../screens/alerts_screen.dart';
import '../screens/rules_rewards_screen.dart';

class AppRoutes {
  AppRoutes._();

  static const splash = "/";
  static const alerts = "/alerts";
  static const login = "/login";
  static const register = "/register";
  static const onboarding = "/onboarding";
  static const home = "/home";
  static const trip = "/trip";
  static const summary = "/summary";
  static const crash = "/crash";
  static const orders = "/orders";
  static const settings = "/settings";
  static const notifications = "/notifications";
  static const earnings = "/earnings";
  static const rewards = "/rewards";
  static const history = "/history";
  static const payments = "/payments";
  static const map = "/map";
  static const profile = "/profile";
  static const editProfile = "/edit_profile";

  static Map<String, WidgetBuilder> routes = {
    splash: (context) => const SplashScreen(),
    login: (context) => const LoginScreen(),
    register: (context) => const RegisterScreen(),
    onboarding: (context) => const IntroOnboardingScreen(),
    home: (context) => const MainNavigationScreen(),
    trip: (context) => const TripScreen(),
    summary: (context) => const TripSummaryScreen(),
    crash: (context) => const CrashScreen(),
    orders: (context) => const OrdersScreen(),
    settings: (context) => const SettingsScreen(),
    notifications: (context) => const NotificationsScreen(),
    earnings: (context) => const EarningsScreen(),
    rewards: (context) => const RulesRewardsScreen(),
    history: (context) => const HistoryScreen(),
    payments: (context) => const PaymentsScreen(),
    map: (context) => const MapScreen(),
    profile: (context) => const ProfileSheet(isEmbedded: true),
    editProfile: (context) => const EditProfileScreen(),
    alerts: (context) => const AlertsScreen(),
  };
}

