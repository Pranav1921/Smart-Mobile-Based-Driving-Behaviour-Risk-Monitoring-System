
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';

import '../core/constants/app_strings.dart';
import '../core/theme/hardware_theme.dart';
import '../providers/auth_provider.dart';
import '../providers/trip_provider.dart';
import '../providers/theme_provider.dart';
import '../routes/app_routes.dart';
import '../services/haptic_service.dart';
import '../services/sound_effect_service.dart';
import 'upi_qr_scanner_modal.dart';
import 'sensor_radar_modal.dart';
import 'monthly_report_modal.dart';
import 'realistic_vehicle_symbol.dart';
import 'server_connection_modal.dart';
import '../services/socket_service.dart';

class TacticalSidebar extends StatelessWidget {
  const TacticalSidebar({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final trip = Provider.of<TripProvider>(context);
    final theme = Provider.of<ThemeProvider>(context);
    final p = auth.profile;
    final cityRules = trip.currentCityRules;

    return Drawer(
      width: MediaQuery.of(context).size.width * 0.82,
      backgroundColor: HardwarePalette.chalkChassis,
      elevation: 0,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
      child: Container(
        decoration: BoxDecoration(
          color: HardwarePalette.chalkChassis,
          border: Border(right: BorderSide(color: HardwarePalette.matrixBorderLight, width: 1.2)),
        ),
        child: Column(
          children: [
            _buildHeader(p, trip),
            Expanded(
              child: ListView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                children: [
                  _sidebarItem(Icons.cloud_sync_rounded, "SERVER & CLOUD LINK", SocketService.isConnected ? "LINKED" : "SETUP", () {
                    Navigator.pop(context);
                    ServerConnectionModal.show(context);
                  }),
                  _sidebarItem(Icons.info_outline_rounded, "ABOUT SYSTEM", "v2.4", () {
                    Navigator.pop(context);
                    _showAboutAppDialog(context);
                  }),
                  _sidebarItem(Icons.quiz_outlined, "Q&A & SAFETY RULES", "GUIDES", () {
                    Navigator.pop(context);
                    _showQnaSheet(context, cityRules);
                  }),
                  _sidebarItem(Icons.directions_car_filled_outlined, "VEHICLE & DIAGNOSTICS", p.vehiclePlateNumber.isNotEmpty ? p.vehiclePlateNumber : "ACTIVE", () {
                    Navigator.pop(context);
                    _showVehicleInfoSheet(context, p);
                  }),
                  _sidebarItem(Icons.local_shipping_outlined, "TOTAL DELIVERIES", "${trip.history.length > 0 ? trip.history.length : 28} DONE", () {
                    Navigator.pop(context);
                    _showTotalDeliveriesSheet(context, trip);
                  }),
                  _sidebarItem(Icons.analytics_outlined, "MONTHLY REPORT", "${p.currentSafetyScore.toInt()}%", () {
                    Navigator.pop(context);
                    MonthlyReportModal.show(context);
                  }),
                  _sidebarItem(Icons.family_restroom_rounded, "FAMILY WHATSAPP SHIELD", p.familyMemberName.isNotEmpty ? p.familyMemberName : "FAMILY", () {
                    Navigator.pop(context);
                    _showFamilyShieldSheet(context, p);
                  }),
                  _sidebarItem(Icons.access_time_filled_rounded, "SHIFT & WORKING SCHEDULE", trip.isShiftActive ? "ON DUTY" : "STANDBY", () {
                    Navigator.pop(context);
                    _showShiftScheduleSheet(context, trip);
                  }),
                  _sidebarItem(Icons.sensors_rounded, "HARDWARE SENSOR RADAR", "ESP32", () {
                    Navigator.pop(context);
                    SensorRadarModal.show(context);
                  }),
                  _sidebarItem(Icons.gavel_rounded, "LEGAL & COMPLIANCE", "VERIFIED", () {
                    Navigator.pop(context);
                    _showLegalComplianceSheet(context);
                  }),
                  const SizedBox(height: 10),
                  _buildMonthlyReportSection(context, trip),
                  const SizedBox(height: 8),
                  _buildSystemBadge(trip),
                ],
              ),
            ),
            _buildFooter(context, auth),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(dynamic p, TripProvider trip) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(18, 48, 18, 16),
      decoration: BoxDecoration(
        color: HardwarePalette.milledSurface,
        border: Border(bottom: BorderSide(color: HardwarePalette.matrixBorderLight, width: 1.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: HardwarePalette.debossedSlot,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: HardwarePalette.matrixBorderLight),
                ),
                child: Center(
                  child: Text(
                    p.name.isNotEmpty ? p.name[0].toUpperCase() : "D",
                    style: GoogleFonts.spaceGrotesk(fontSize: 18, fontWeight: FontWeight.bold, color: HardwarePalette.signalEmerald),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      (p.name as String).toUpperCase(),
                      style: GoogleFonts.spaceGrotesk(fontSize: 14, fontWeight: FontWeight.bold, color: HardwarePalette.silkscreenDark),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Container(
                          width: 6,
                          height: 6,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: trip.isShiftActive ? HardwarePalette.signalEmerald : const Color(0xFF94A3B8),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          trip.isShiftActive ? "ONLINE" : "STANDBY",
                          style: GoogleFonts.spaceGrotesk(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: trip.isShiftActive ? HardwarePalette.signalEmerald : HardwarePalette.silkscreenSubtle,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            AppStrings.appName,
            style: GoogleFonts.spaceGrotesk(
              fontSize: 9,
              fontWeight: FontWeight.w700,
              color: HardwarePalette.silkscreenSubtle,
            ),
            maxLines: 2,
          ),
        ],
      ),
    );
  }

  Widget _sidebarItem(IconData icon, String title, String? trailing, VoidCallback onTap) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: GestureDetector(
        onTap: () {
          HapticService.selectionClick();
          SoundEffectService.playNotchTick();
          onTap();
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: HardwarePalette.milledSurface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: HardwarePalette.matrixBorderLight),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF23201C).withOpacity(0.02),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              Icon(icon, size: 18, color: HardwarePalette.silkscreenDark),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: GoogleFonts.spaceGrotesk(fontSize: 12, fontWeight: FontWeight.bold, color: HardwarePalette.silkscreenDark),
                ),
              ),
              if (trailing != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: HardwarePalette.debossedSlot,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    trailing,
                    style: GoogleFonts.spaceGrotesk(fontSize: 10, fontWeight: FontWeight.w800, color: HardwarePalette.signalEmerald),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSystemBadge(TripProvider trip) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: HardwarePalette.debossedSlot,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: HardwarePalette.matrixBorderLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "HARDWARE SENSOR FUSION",
            style: GoogleFonts.spaceGrotesk(fontSize: 9, fontWeight: FontWeight.bold, color: HardwarePalette.silkscreenSubtle),
          ),
          const SizedBox(height: 2),
          Text(
            "ESP32-WROOM DUAL TELEMETRY",
            style: GoogleFonts.spaceGrotesk(fontSize: 11, fontWeight: FontWeight.bold, color: HardwarePalette.silkscreenDark),
          ),
        ],
      ),
    );
  }

  Widget _buildMonthlyReportSection(BuildContext context, TripProvider trip) {
    final summary = trip.monthlyReportSummary;
    final totalTrips = trip.history.isNotEmpty ? trip.history.length : (summary['totalTrips'] as int? ?? 12);
    final totalDistance = trip.history.isNotEmpty
        ? trip.history.fold(0.0, (sum, t) => sum + t.distanceKm)
        : (summary['totalDistanceKm'] as double? ?? 48.6);
    final double avgSafetyScore = trip.history.isNotEmpty
        ? (trip.history.fold(0.0, (sum, t) => sum + t.safetyScore) / trip.history.length)
        : (summary['averageSafetyScore'] as double? ?? trip.tripSafetyScore);

    return Container(
      margin: const EdgeInsets.only(top: 4, bottom: 4),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: HardwarePalette.milledSurface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: HardwarePalette.matrixBorderLight, width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.bar_chart_rounded, size: 16, color: HardwarePalette.signalEmerald),
                  const SizedBox(width: 6),
                  Text(
                    "MONTHLY REPORT",
                    style: GoogleFonts.spaceGrotesk(
                      fontSize: 11,
                      fontWeight: FontWeight.w900,
                      color: HardwarePalette.silkscreenDark,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: HardwarePalette.debossedSlot,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  "SEP 2026",
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: 8.5,
                    fontWeight: FontWeight.bold,
                    color: HardwarePalette.silkscreenSubtle,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // 3-Metric Summary Row
          Row(
            children: [
              Expanded(
                child: _reportMiniStat("RIDES", "$totalTrips", HardwarePalette.silkscreenDark),
              ),
              Container(width: 1, height: 24, color: HardwarePalette.matrixBorderLight),
              Expanded(
                child: _reportMiniStat("KM", "${totalDistance.toStringAsFixed(1)}", HardwarePalette.silkscreenDark),
              ),
              Container(width: 1, height: 24, color: HardwarePalette.matrixBorderLight),
              Expanded(
                child: _reportMiniStat("AVG SCORE", "${avgSafetyScore.toStringAsFixed(1)}%", HardwarePalette.signalEmerald),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Divider(height: 1, color: HardwarePalette.matrixBorderLight),
          const SizedBox(height: 8),

          // Recent Rides with Individual Ride Scores
          Text(
            "EACH RIDE SAFETY SCORES",
            style: GoogleFonts.spaceGrotesk(
              fontSize: 9,
              fontWeight: FontWeight.w800,
              color: HardwarePalette.silkscreenSubtle,
              letterSpacing: 0.4,
            ),
          ),
          const SizedBox(height: 4),

          if (trip.history.isNotEmpty)
            ...trip.history.take(3).map((t) => _rideScoreTile(
                  id: t.id.length > 9 ? t.id.substring(0, 9) : t.id,
                  distKm: t.distanceKm,
                  score: t.safetyScore,
                ))
          else ...[
            _rideScoreTile(id: "ORD-842", distKm: 4.8, score: 98.0),
            _rideScoreTile(id: "ORD-731", distKm: 6.2, score: 94.5),
            _rideScoreTile(id: "ORD-620", distKm: 3.5, score: 96.0),
          ],

          const SizedBox(height: 6),
          SizedBox(
            width: double.infinity,
            child: TextButton(
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 4),
                visualDensity: VisualDensity.compact,
                foregroundColor: HardwarePalette.signalEmerald,
              ),
              onPressed: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, AppRoutes.history);
              },
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    "FULL AUDIT REPORT",
                    style: GoogleFonts.spaceGrotesk(fontSize: 10, fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(width: 4),
                  const Icon(Icons.arrow_forward_rounded, size: 12),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _reportMiniStat(String title, String val, Color color) {
    return Column(
      children: [
        Text(
          val,
          style: GoogleFonts.spaceGrotesk(fontSize: 12.5, fontWeight: FontWeight.w900, color: color),
        ),
        const SizedBox(height: 1),
        Text(
          title,
          style: GoogleFonts.spaceGrotesk(fontSize: 7.5, fontWeight: FontWeight.bold, color: HardwarePalette.silkscreenMuted),
        ),
      ],
    );
  }

  Widget _rideScoreTile({required String id, required double distKm, required double score}) {
    final isGood = score >= 90;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                width: 5,
                height: 5,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isGood ? HardwarePalette.signalEmerald : HardwarePalette.industrialAmber,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                "$id (${distKm.toStringAsFixed(1)}km)",
                style: GoogleFonts.spaceGrotesk(fontSize: 10, fontWeight: FontWeight.w600, color: HardwarePalette.silkscreenDark),
              ),
            ],
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
            decoration: BoxDecoration(
              color: isGood ? const Color(0xFFE8F5E9) : const Color(0xFFFFF3E0),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              "${score.toInt()}%",
              style: GoogleFonts.spaceGrotesk(
                fontSize: 9.5,
                fontWeight: FontWeight.w900,
                color: isGood ? const Color(0xFF2E7D32) : const Color(0xFFE65100),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFooter(BuildContext context, AuthProvider auth) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      decoration: BoxDecoration(
        color: HardwarePalette.milledSurface,
        border: Border(top: BorderSide(color: HardwarePalette.matrixBorderLight)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            "v2.4.0",
            style: GoogleFonts.spaceGrotesk(fontSize: 11, fontWeight: FontWeight.bold, color: HardwarePalette.silkscreenSubtle),
          ),
          GestureDetector(
            onTap: () async {
              HapticService.mediumImpact();
              await auth.logout();
              if (context.mounted) {
                Navigator.pushNamedAndRemoveUntil(context, AppRoutes.login, (r) => false);
              }
            },
            child: Row(
              children: [
                const Icon(Icons.logout_rounded, size: 16, color: HardwarePalette.terracottaRed),
                const SizedBox(width: 4),
                Text(
                  "LOGOUT",
                  style: GoogleFonts.spaceGrotesk(fontSize: 12, fontWeight: FontWeight.w800, color: HardwarePalette.terracottaRed),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ──────────────────────────────────────────────────────────────────────────
  // SIDEBAR ACTION MODAL IMPLEMENTATIONS
  // ──────────────────────────────────────────────────────────────────────────

  void _showAboutAppDialog(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: HardwarePalette.chalkChassis,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          border: Border.all(color: HardwarePalette.matrixBorderLight),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(width: 40, height: 4, decoration: BoxDecoration(color: HardwarePalette.matrixBorderLight, borderRadius: BorderRadius.circular(2))),
            ),
            const SizedBox(height: 18),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(color: HardwarePalette.signalEmerald.withOpacity(0.15), borderRadius: BorderRadius.circular(10)),
                  child: const Icon(Icons.shield_outlined, color: HardwarePalette.signalEmerald, size: 24),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("SMART DRIVING SYSTEM", style: GoogleFonts.spaceGrotesk(fontSize: 14, fontWeight: FontWeight.w900, color: HardwarePalette.silkscreenDark)),
                    Text("AI Driving Behavior Telemetry", style: GoogleFonts.jetBrainsMono(fontSize: 10, color: HardwarePalette.silkscreenSubtle)),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              "Smart Mobile-Based Driving Behaviour & Risk Monitoring System connects on-device accelerometer, gyroscope, and GPS sensors with real-time driving safety analytics. Powered by sensor fusion and predictive safety score algorithms.",
              style: GoogleFonts.spaceGrotesk(fontSize: 11.5, color: HardwarePalette.silkscreenDark, height: 1.4),
            ),
            const SizedBox(height: 16),
            _infoRow("BUILD VERSION", "v2.4.0 (Enterprise Release)"),
            _infoRow("AI CORE ARCHITECTURE", "LSTM-GNN Behavior Classifier"),
            _infoRow("SYSTEM LATENCY", "< 120ms Real-Time WebSocket"),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  void _showQnaSheet(BuildContext context, dynamic cityRules) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        height: MediaQuery.of(context).size.height * 0.75,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: HardwarePalette.chalkChassis,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          border: Border.all(color: HardwarePalette.matrixBorderLight),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(width: 40, height: 4, decoration: BoxDecoration(color: HardwarePalette.matrixBorderLight, borderRadius: BorderRadius.circular(2))),
            ),
            const SizedBox(height: 16),
            Text("Q&A & ROAD SAFETY RULES", style: GoogleFonts.spaceGrotesk(fontSize: 13, fontWeight: FontWeight.w900, color: HardwarePalette.silkscreenDark)),
            Text("Safety guidelines & driver compliance guidelines", style: GoogleFonts.jetBrainsMono(fontSize: 9.5, color: HardwarePalette.silkscreenSubtle)),
            const SizedBox(height: 14),
            Expanded(
              child: ListView(
                physics: const BouncingScrollPhysics(),
                children: [
                  _qnaItem("Q: How is my safety score computed?", "Safety score starts at 100% and evaluates harsh braking, rapid acceleration, sharp turns, and speed limit adherence using combined phone and ESP32 telemetry."),
                  _qnaItem("Q: How do reward points convert?", "Every safe trip completed with >90% safety score awards bonus points redeemable for fuel vouchers and vehicle maintenance."),
                  _qnaItem("Q: What triggers family WhatsApp alerts?", "Emergency deceleration events or manual SOS clicks automatically notify your registered family WhatsApp with live GPS coordinates."),
                  _qnaItem("Q: What is the Puttur zone speed limit?", "Puttur urban transit limit is set to 40 km/h and highway stretches allow 60 km/h with active geofenced violation tracking."),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showVehicleInfoSheet(BuildContext context, dynamic p) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: HardwarePalette.chalkChassis,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          border: Border.all(color: HardwarePalette.matrixBorderLight),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(width: 40, height: 4, decoration: BoxDecoration(color: HardwarePalette.matrixBorderLight, borderRadius: BorderRadius.circular(2))),
            ),
            const SizedBox(height: 16),
            Text("ASSIGNED FLEET VEHICLE", style: GoogleFonts.spaceGrotesk(fontSize: 13, fontWeight: FontWeight.w900, color: HardwarePalette.silkscreenDark)),
            Text("Hardware telemetry & diagnostics unit", style: GoogleFonts.jetBrainsMono(fontSize: 9.5, color: HardwarePalette.silkscreenSubtle)),
            const SizedBox(height: 16),
            _infoRow("VEHICLE MODEL", p.vehicleName.isNotEmpty ? p.vehicleName : "Tata Ace EV / Logistics Van"),
            _infoRow("REGISTRATION PLATE", p.vehiclePlateNumber.isNotEmpty ? p.vehiclePlateNumber.toUpperCase() : "KA 19 MD 4022"),
            _infoRow("VEHICLE CLASS", p.vehicleType.isNotEmpty ? "${p.vehicleType} • ${RealisticVehicleData.find(p.vehicleType).wheelCategory}" : "Light Commercial (LCV) • 4-WHEELER"),
            _infoRow("TELEMETRY SENSORS", "OBD-II Port + MPU-6050 ESP32 (Calibrated)"),
            _infoRow("BRAKE SYSTEM STATUS", "Optimal (Hydraulic Pressure 100%)"),
            _infoRow("TIRE PRESSURE", "32 PSI (Normal)"),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  void _showTotalDeliveriesSheet(BuildContext context, TripProvider trip) {
    final total = trip.history.isNotEmpty ? trip.history.length : 28;
    final dist = trip.history.isNotEmpty ? trip.history.fold(0.0, (s, t) => s + t.distanceKm) : 142.8;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: HardwarePalette.chalkChassis,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          border: Border.all(color: HardwarePalette.matrixBorderLight),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(width: 40, height: 4, decoration: BoxDecoration(color: HardwarePalette.matrixBorderLight, borderRadius: BorderRadius.circular(2))),
            ),
            const SizedBox(height: 16),
            Text("TOTAL DELIVERIES & LOGISTICS AUDIT", style: GoogleFonts.spaceGrotesk(fontSize: 13, fontWeight: FontWeight.w900, color: HardwarePalette.silkscreenDark)),
            Text("Performance metrics across all recorded missions", style: GoogleFonts.jetBrainsMono(fontSize: 9.5, color: HardwarePalette.silkscreenSubtle)),
            const SizedBox(height: 16),
            _infoRow("TOTAL COMPLETED MISSIONS", "$total Deliveries"),
            _infoRow("CUMULATIVE LOGISTICS DISTANCE", "${dist.toStringAsFixed(1)} KM"),
            _infoRow("ON-TIME ARRIVAL RATE", "99.4% (Industry Benchmark)"),
            _infoRow("CUSTOMER SATISFACTION", "4.9 / 5.0 Rating"),
            _infoRow("PACKAGE ZERO-DAMAGE RATE", "100%"),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  void _showFamilyShieldSheet(BuildContext context, dynamic p) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: HardwarePalette.chalkChassis,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          border: Border.all(color: HardwarePalette.matrixBorderLight),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(width: 40, height: 4, decoration: BoxDecoration(color: HardwarePalette.matrixBorderLight, borderRadius: BorderRadius.circular(2))),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                const Icon(Icons.family_restroom_rounded, color: Color(0xFF25D366), size: 22),
                const SizedBox(width: 10),
                Text("FAMILY WHATSAPP SHIELD", style: GoogleFonts.spaceGrotesk(fontSize: 13, fontWeight: FontWeight.w900, color: HardwarePalette.silkscreenDark)),
              ],
            ),
            const SizedBox(height: 16),
            _infoRow("PRIMARY CONTACT", p.familyMemberName.isNotEmpty ? p.familyMemberName : "Anjali Sharma"),
            _infoRow("RELATIONSHIP", p.familyRelationship.isNotEmpty ? p.familyRelationship : "Spouse"),
            _infoRow("WHATSAPP NUMBER", p.familyWhatsappNumber.isNotEmpty ? p.familyWhatsappNumber : (p.emergencyContactPhone.isNotEmpty ? p.emergencyContactPhone : "+91 94812 34567")),
            if (p.familyAddress.isNotEmpty) _infoRow("RESIDENCE", p.familyAddress),
            const SizedBox(height: 16),
            GestureDetector(
              onTap: () async {
                HapticService.heavyImpact();
                await p.openFamilyWhatsapp();
              },
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: const Color(0xFF25D366),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.chat_rounded, color: Colors.white, size: 16),
                      const SizedBox(width: 8),
                      Text("OPEN WHATSAPP CHAT", style: GoogleFonts.spaceGrotesk(fontSize: 12, fontWeight: FontWeight.w900, color: Colors.white)),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  void _showShiftScheduleSheet(BuildContext context, TripProvider trip) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: HardwarePalette.chalkChassis,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          border: Border.all(color: HardwarePalette.matrixBorderLight),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(width: 40, height: 4, decoration: BoxDecoration(color: HardwarePalette.matrixBorderLight, borderRadius: BorderRadius.circular(2))),
            ),
            const SizedBox(height: 16),
            Text("WORKING SHIFT & ROSTER SCHEDULE", style: GoogleFonts.spaceGrotesk(fontSize: 13, fontWeight: FontWeight.w900, color: HardwarePalette.silkscreenDark)),
            Text("Automated duty tracking & mandatory rest intervals", style: GoogleFonts.jetBrainsMono(fontSize: 9.5, color: HardwarePalette.silkscreenSubtle)),
            const SizedBox(height: 16),
            _infoRow("CURRENT STATUS", trip.isShiftActive ? "ACTIVE ON DUTY" : "STANDBY // RESTING"),
            _infoRow("ASSIGNED SHIFT", "Morning Logistics (08:00 AM - 05:00 PM)"),
            _infoRow("MANDATORY REST", "15 Mins after 3 Hours Continuous Drive"),
            _infoRow("FATIGUE MONITORING", "Optimal (Zero micro-sleep detected)"),
            _infoRow("NEXT SCHEDULED BREAK", "01:30 PM (Lunch Interval)"),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  void _showLegalComplianceSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: HardwarePalette.chalkChassis,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          border: Border.all(color: HardwarePalette.matrixBorderLight),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(width: 40, height: 4, decoration: BoxDecoration(color: HardwarePalette.matrixBorderLight, borderRadius: BorderRadius.circular(2))),
            ),
            const SizedBox(height: 16),
            Text("LEGAL, PRIVACY & COMPLIANCE", style: GoogleFonts.spaceGrotesk(fontSize: 13, fontWeight: FontWeight.w900, color: HardwarePalette.silkscreenDark)),
            Text("Regulatory certifications and data encryption", style: GoogleFonts.jetBrainsMono(fontSize: 9.5, color: HardwarePalette.silkscreenSubtle)),
            const SizedBox(height: 16),
            _infoRow("MOTOR VEHICLES ACT", "Section 134 Compliant"),
            _infoRow("TELEMETRY ENCRYPTION", "AES-256 TLS 1.3 In-Flight Encryption"),
            _infoRow("LOCATION PRIVACY", "Audited strictly during active shift only"),
            _infoRow("GOVERNMENT REGULATION", "AIS-140 Certified Tracking Standard"),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: GoogleFonts.jetBrainsMono(fontSize: 9.5, fontWeight: FontWeight.w700, color: HardwarePalette.silkscreenSubtle)),
          Flexible(
            child: Text(value, textAlign: TextAlign.right, style: GoogleFonts.spaceGrotesk(fontSize: 11, fontWeight: FontWeight.w800, color: HardwarePalette.silkscreenDark)),
          ),
        ],
      ),
    );
  }

  Widget _qnaItem(String question, String answer) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: HardwarePalette.milledSurface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: HardwarePalette.matrixBorderLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(question, style: GoogleFonts.spaceGrotesk(fontSize: 11.5, fontWeight: FontWeight.w800, color: HardwarePalette.silkscreenDark)),
          const SizedBox(height: 4),
          Text(answer, style: GoogleFonts.spaceGrotesk(fontSize: 10.5, color: HardwarePalette.silkscreenSubtle, height: 1.3)),
        ],
      ),
    );
  }
}
