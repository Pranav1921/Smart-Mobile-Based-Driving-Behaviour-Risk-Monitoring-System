import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/constants/app_colors.dart';
import '../providers/trip_provider.dart';
import '../providers/auth_provider.dart';
import '../routes/app_routes.dart';
import '../widgets/glass_card.dart';
 
class CrashScreen extends StatefulWidget {
  const CrashScreen({super.key});
 
  @override
  State<CrashScreen> createState() => _CrashScreenState();
}
 
class _CrashScreenState extends State<CrashScreen> with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  bool _sosSent = false;
  bool _mockRecording = false;
 
  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..repeat(reverse: true);
 
    // After countdown completes in TripProvider (5s), update sent state
    final tripProv = Provider.of<TripProvider>(context, listen: false);
    Timer(const Duration(seconds: 5), () {
      if (mounted && tripProv.isCrashDetected && tripProv.sosCountdown == 0) {
        setState(() {
          _sosSent = true;
          _mockRecording = true;
        });
        // Automatically mock taking camera snapshots and saving telemetry logs
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text("SOS Broadcast completed. Sensor and video logs transmitted."),
            backgroundColor: AppColors.error,
            duration: const Duration(seconds: 3),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          ),
        );
      }
    });
  }
 
  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }
 
  void _handleCancel() {
    final tripProv = Provider.of<TripProvider>(context, listen: false);
    tripProv.cancelSOS();
    Navigator.pushReplacementNamed(context, AppRoutes.home);
  }
 
  @override
  Widget build(BuildContext context) {
    final tripProv = Provider.of<TripProvider>(context);
    final auth = Provider.of<AuthProvider>(context);
    final isCountingDown = tripProv.sosCountdown > 0;

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 30),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Header Warning State
              Column(
                children: [
                  const SizedBox(height: 20),
                  AnimatedBuilder(
                    animation: _pulseController,
                    builder: (context, child) {
                      return Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppColors.error.withOpacity(0.08 + (_pulseController.value * 0.12)),
                          border: Border.all(
                            color: AppColors.error,
                            width: 1.5 + (_pulseController.value * 2),
                          ),
                        ),
                        child: const Icon(
                          Icons.emergency_share,
                          color: AppColors.error,
                          size: 54,
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 24),
                  Text(
                    isCountingDown ? "SEVERE IMPACT DETECTED" : "SOS DISPATCH SENT",
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.0,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    isCountingDown
                        ? "Triggering automated emergency response protocols"
                        : "Emergency rescue services and dispatch have been notified",
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                  ),
                ],
              ),

              // Middle dynamic card (Countdown or SOS Summary)
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 24),
                  child: Center(
                    child: isCountingDown 
                        ? _buildCountdownCard(tripProv.sosCountdown)
                        : _buildSosDashboard(auth.profile),
                  ),
                ),
              ),

              // Bottom primary actions (Cancel or Contacts)
              isCountingDown
                  ? ElevatedButton(
                      onPressed: _handleCancel,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.textPrimary,
                        foregroundColor: Colors.black,
                        minimumSize: const Size(double.infinity, 60),
                      ),
                      child: const Text("CANCEL DISPATCH (FALSE ALARM)"),
                    )
                  : ElevatedButton(
                      onPressed: () {
                        tripProv.cancelSOS();
                        Navigator.pushReplacementNamed(context, AppRoutes.home);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.surface,
                        foregroundColor: Colors.white,
                        minimumSize: const Size(double.infinity, 60),
                        side: const BorderSide(color: AppColors.border),
                      ),
                      child: const Text("RETURN TO DASHBOARD"),
                    ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCountdownCard(int seconds) {
    return GlassCard(
      padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            "SOS BROADCAST COUNTDOWN",
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.5,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 24),
          Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: 110,
                height: 110,
                child: CircularProgressIndicator(
                  value: seconds / 5.0,
                  strokeWidth: 8,
                  backgroundColor: AppColors.border,
                  valueColor: const AlwaysStoppedAnimation<Color>(AppColors.error),
                ),
              ),
              Text(
                "$seconds",
                style: const TextStyle(fontSize: 44, fontWeight: FontWeight.bold, color: Colors.white),
              ),
            ],
          ),
          const SizedBox(height: 24),
          const Text(
            "Capturing environment, coordinates and sensor metrics...",
            style: TextStyle(fontSize: 11, color: AppColors.textMuted),
          ),
        ],
      ),
    );
  }

  Widget _buildSosDashboard(dynamic profile) {
    return SingleChildScrollView(
      child: Column(
        children: [
          // Dashboard Camera status overlay
          if (_mockRecording)
            Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: GlassCard(
                padding: const EdgeInsets.all(12),
                borderRadius: 16,
                child: Row(
                  children: [
                    Stack(
                      alignment: Alignment.center,
                      children: [
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: Colors.black,
                            shape: BoxShape.circle,
                            border: Border.all(color: AppColors.border),
                          ),
                          child: const Icon(Icons.videocam, color: AppColors.textSecondary, size: 20),
                        ),
                        Positioned(
                          top: 4,
                          right: 4,
                          child: Container(
                            width: 8,
                            height: 8,
                            decoration: const BoxDecoration(color: AppColors.error, shape: BoxShape.circle),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(width: 14),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "DASHCAM SOS STREAMING",
                            style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.error, letterSpacing: 0.5),
                          ),
                          SizedBox(height: 2),
                          Text(
                            "Secure blackbox file #FG-2026-SOS.mp4 archiving...",
                            style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

          // Vehicle Crash Data Report
          GlassCard(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.directions_car, color: AppColors.error, size: 18),
                    SizedBox(width: 8),
                    Text(
                      "VEHICLE CRASH REPORT",
                      style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.error, letterSpacing: 0.8),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                _buildReportRow("Vehicle Model", profile.vehicleName.isNotEmpty ? profile.vehicleName : "Tesla Model Y"),
                _buildReportRow("License Plate", profile.vehiclePlateNumber.isNotEmpty ? profile.vehiclePlateNumber : "FG-101-AI"),
                _buildReportRow("Airbags Status", "DEPLOYED"),
                _buildReportRow("Inertial G-force", "1.84G"),
                _buildReportRow("Speed at Impact", "42 mph"),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Core Hotlines Card
          GlassCard(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "SOS ACTIONS",
                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.textSecondary, letterSpacing: 1.0),
                ),
                const SizedBox(height: 16),
                _buildEmergencyContactItem(Icons.local_hospital, "CALL EMERGENCY AMBULANCE", "102", AppColors.success),
                const Divider(),
                _buildEmergencyContactItem(Icons.local_police, "CALL POLICE FORCE", "100", AppColors.primary),
                const Divider(),
                _buildEmergencyContactItem(Icons.support_agent, "FLEET LOGISTICS DISPATCHER", "Code FleetGuard", AppColors.warning),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // AI Accident Telemetry Report
          GlassCard(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.psychology, color: AppColors.primary, size: 18),
                    SizedBox(width: 8),
                    Text(
                      "AI EMERGENCY TELEMETRY REPORT",
                      style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.primary, letterSpacing: 0.8),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  "Impact detected at 37.7749N, 122.4194W.\nDashboard camera records, inertial force logs, and vehicle telemetry are encrypted and successfully transmitted to dispatch network.",
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.textPrimary.withOpacity(0.9),
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReportRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
          Text(value, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white)),
        ],
      ),
    );
  }

  Widget _buildEmergencyContactItem(IconData icon, String title, String phone, Color iconColor) {
    return InkWell(
      onTap: () {
        // Visual indicator that tap works
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Mock dialing: $phone ($title)"),
            backgroundColor: AppColors.surface,
            duration: const Duration(seconds: 1),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Icon(icon, color: iconColor, size: 20),
                const SizedBox(width: 16),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                    const SizedBox(height: 2),
                    Text(phone, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                  ],
                ),
              ],
            ),
            const Icon(Icons.phone, color: AppColors.textSecondary, size: 18),
          ],
        ),
      ),
    );
  }
}
