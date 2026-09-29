import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/constants/app_strings.dart';
import '../providers/auth_provider.dart';
import '../routes/app_routes.dart';
import '../core/theme/neon_theme.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer(const Duration(seconds: 2), () {
      if (!mounted) return;
      final auth = Provider.of<AuthProvider>(context, listen: false);
      String route = auth.isAuthenticated ? AppRoutes.home : AppRoutes.onboarding;
      if (mounted) {
        Navigator.of(context).pushReplacementNamed(route);
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: NeonColors.backgroundBlack,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 40),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
               const Text(
                 "Smart Mobile-Based Driving Behaviour and Risk Monitoring System",
                 textAlign: TextAlign.center,
                 style: TextStyle(
                   color: Colors.white,
                   fontSize: 14,
                   fontWeight: FontWeight.w900,
                   letterSpacing: 0.5,
                 ),
               ),
            ],
          ),
        ),
      ),
    );
  }
}
