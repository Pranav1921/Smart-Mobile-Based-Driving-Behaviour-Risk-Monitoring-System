import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:mobile_app/core/theme/neon_theme.dart';
import 'package:mobile_app/providers/trip_provider.dart';
import 'package:mobile_app/routes/app_routes.dart';

class TripSummaryScreen extends StatelessWidget {
  const TripSummaryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final tripProv = Provider.of<TripProvider>(context);
    final trip = tripProv.lastCompletedTrip;

    if (trip == null) {
      return Scaffold(
        backgroundColor: NeonColors.background,
        body: Center(child: Text("No mission telemetry available", style: TextStyle(color: NeonColors.subtext))),
      );
    }

    final int score = trip.safetyScore.toInt();
    final Color scoreCol = score >= 85 ? const Color(0xFF10B981) : (score >= 65 ? Colors.amber : Colors.redAccent);

    return Scaffold(
      backgroundColor: NeonColors.background,
      appBar: AppBar(
        backgroundColor: NeonColors.green,
        elevation: 0,
        toolbarHeight: 56,
        leading: IconButton(
          icon: const Icon(Icons.chevron_left_rounded, color: Colors.white, size: 28),
          onPressed: () => Navigator.pushReplacementNamed(context, AppRoutes.home),
        ),
        title: const Text(
          'Mission Summary Report',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w900,
            fontSize: 15,
          ),
        ),
      ),
      body: SafeArea(
        child: ListView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.all(24),
          children: [
            // Scorecard Hero Card
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: NeonColors.card,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: scoreCol.withOpacity(0.3), width: 1.5),
                boxShadow: [
                  BoxShadow(
                    color: scoreCol.withOpacity(0.08),
                    blurRadius: 16,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Container(
                    height: 80,
                    width: 80,
                    decoration: BoxDecoration(
                      color: scoreCol.withOpacity(0.12),
                      shape: BoxShape.circle,
                      border: Border.all(color: scoreCol, width: 3),
                    ),
                    child: Center(
                      child: Text(
                        "$score%",
                        style: TextStyle(color: scoreCol, fontSize: 24, fontWeight: FontWeight.w900),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    score >= 85 ? "EXCELLENT DRIVING RECORD" : "MODERATE SAFETY PROFILE",
                    style: TextStyle(color: scoreCol, fontSize: 12, fontWeight: FontWeight.w900, letterSpacing: 1),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "All telemetry logged & audited with cloud dispatch servers.",
                    style: TextStyle(color: NeonColors.subtext, fontSize: 11),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Statistics Grid
            Text("MISSION TELEMETRY AUDIT", style: TextStyle(color: NeonColors.subtext, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1.2)),
            const SizedBox(height: 10),
            _buildStatCard("Distance Traveled", "${trip.distanceKm.toStringAsFixed(1)} KM", Icons.route_rounded),
            const SizedBox(height: 10),
            _buildStatCard("Trip Duration", "${(trip.durationSeconds / 60).toStringAsFixed(0)} Minutes", Icons.timer_outlined),
            const SizedBox(height: 10),
            _buildStatCard("Average Velocity", "${trip.averageSpeed.toStringAsFixed(1)} KM/H", Icons.speed_rounded),
            const SizedBox(height: 10),
            _buildStatCard("Delivery Payout", "₹ ${(trip.distanceKm * 15.0).toStringAsFixed(0)} INR", Icons.payments_rounded, isHighlight: true),

            const SizedBox(height: 32),
            GestureDetector(
              onTap: () => Navigator.pushReplacementNamed(context, AppRoutes.home),
              child: Container(
                height: 54,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: NeonColors.primaryGreen,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: NeonColors.primaryGreen.withOpacity(0.3),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: const Center(
                  child: Text(
                    "RETURN TO HUB",
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, letterSpacing: 1.2, fontSize: 13),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(String label, String val, IconData icon, {bool isHighlight = false}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: NeonColors.card,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: isHighlight ? const Color(0xFF10B981).withOpacity(0.4) : NeonColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(NeonColors.isDark ? 0.2 : 0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: isHighlight ? const Color(0xFF10B981).withOpacity(0.12) : NeonColors.surfaceMuted,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: isHighlight ? const Color(0xFF10B981) : NeonColors.primaryGreen, size: 20),
          ),
          const SizedBox(width: 14),
          Text(label, style: TextStyle(fontWeight: FontWeight.w800, fontSize: 12, color: NeonColors.subtext)),
          const Spacer(),
          Text(
            val,
            style: TextStyle(
              fontWeight: FontWeight.w900,
              fontSize: 13.5,
              color: isHighlight ? const Color(0xFF10B981) : NeonColors.text,
            ),
          ),
        ],
      ),
    );
  }
}
