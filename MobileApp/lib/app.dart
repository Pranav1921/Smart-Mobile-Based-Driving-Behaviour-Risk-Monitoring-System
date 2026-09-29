import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'core/constants/app_strings.dart';
import 'core/navigation/tactical_router.dart';
import 'core/theme/neon_theme.dart';
import 'routes/app_routes.dart';
import 'providers/theme_provider.dart';

import 'screens/splash_screen.dart';
import 'screens/intro_onboarding_screen.dart';
import 'screens/login_screen.dart';
import 'screens/register_screen.dart';
import 'screens/main_navigation_screen.dart';
import 'screens/trip_screen.dart';
import 'screens/orders_screen.dart';
import 'screens/history_screen.dart';
import 'screens/map_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/edit_profile_screen.dart';

import 'screens/settings_screen.dart';
import 'screens/notifications_screen.dart';

import 'screens/earnings_screen.dart';
import 'screens/rules_rewards_screen.dart';
import 'screens/payments_screen.dart';
import 'screens/alerts_screen.dart';
import 'screens/trip_summary_screen.dart';
import 'screens/crash_screen.dart';

class DriverSafetyApp extends StatelessWidget {
  const DriverSafetyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);

    return MaterialApp(
      key: const ValueKey('driver_safety_app_v4'),
      title: AppStrings.appName,
      debugShowCheckedModeBanner: false,
      initialRoute: AppRoutes.splash,
      routes: AppRoutes.routes,
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.light,
        scaffoldBackgroundColor: const Color(0xFFECEAE6),
      ),
      darkTheme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF181615),
      ),
      themeMode: themeProvider.themeMode,
      onUnknownRoute: (settings) {
        return MaterialPageRoute(
          builder: (_) => const MainNavigationScreen(),
          settings: settings,
        );
      },

      builder: (context, child) {
        NeonColors.isDark = themeProvider.isDarkMode;
        return child!;
      },
    );
  }
}
