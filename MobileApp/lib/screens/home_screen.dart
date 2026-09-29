import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../core/theme/hardware_theme.dart';
import '../models/order_model.dart';
import '../providers/auth_provider.dart';
import '../providers/sensor_provider.dart';
import '../providers/trip_provider.dart';
import '../providers/theme_provider.dart';
import '../routes/app_routes.dart';
import '../services/haptic_service.dart';
import '../services/map_navigation_service.dart';
import '../services/road_rules_service.dart';
import '../widgets/mechanical_lever_switch.dart';
import '../widgets/sensor_radar_modal.dart';
import '../widgets/upi_qr_scanner_modal.dart';
import '../widgets/municipal_rules_modal.dart';
import '../widgets/tactical_sidebar.dart';
import '../widgets/mechanical_mission_slider.dart';
import '../widgets/roadside_breakdown_modal.dart';
import '../widgets/guardian_share_modal.dart';
import '../widgets/server_connection_modal.dart';
import '../services/socket_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _isHardwareDefectDismissed = false;

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final trip = Provider.of<TripProvider>(context);
    final sensor = Provider.of<SensorProvider>(context, listen: false);
    final theme = Provider.of<ThemeProvider>(context);
    final p = auth.profile;

    final double safetyScore = p.currentSafetyScore;
    final bool isEsp32 = context.select<SensorProvider, bool>((s) => s.isEsp32Connected);

    return Scaffold(
      backgroundColor: HardwarePalette.chalkChassis,
      drawer: const TacticalSidebar(),
      body: SafeArea(
        bottom: false,
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 90),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ── 1. HEADER ─────────────────────────────────────────────
              _buildSkeuomorphicHeader(p, trip, sensor),
              const SizedBox(height: 12),

              // ── NO NETWORK / DEAD ZONE OFFLINE TELEMETRY BANNER ──
              if (SocketService.isGhatModeActive || !SocketService.isConnected) ...[
                GestureDetector(
                  onTap: () => ServerConnectionModal.show(context),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0F172A),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: const Color(0xFF38BDF8), width: 1.2),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF38BDF8).withOpacity(0.15),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.wifi_off_rounded, color: Color(0xFF38BDF8), size: 20),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "NO NETWORK / DEAD ZONE ACTIVE",
                                style: GoogleFonts.spaceGrotesk(
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.w800,
                                  color: const Color(0xFF38BDF8),
                                  letterSpacing: 0.5,
                                ),
                              ),
                              const SizedBox(height: 1),
                              Text(
                                "${SocketService.offlineBufferedCount} points saved locally. Auto-syncs to server upon reconnect.",
                                style: GoogleFonts.spaceGrotesk(fontSize: 9.5, color: Colors.white70),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFF38BDF8).withOpacity(0.2),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            "${SocketService.offlineBufferedCount}/500",
                            style: GoogleFonts.spaceGrotesk(
                              fontSize: 10,
                              fontWeight: FontWeight.w900,
                              color: const Color(0xFF38BDF8),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
              ],

              if (trip.adminBroadcastBanner != null) ...[
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF8B5CF6), Color(0xFF6D28D9)],
                    ),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: Colors.white.withOpacity(0.9), width: 1.5),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.purple.withOpacity(0.35),
                        blurRadius: 10,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.campaign_rounded, color: Colors.white, size: 22),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          trip.adminBroadcastBanner!,
                          style: GoogleFonts.spaceGrotesk(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            fontSize: 12.5,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
              ],

              // ── 2. SHIFT DUTY MECHANICAL LEVER CONTROLLER ─────────────
              _buildShiftLeverController(trip, sensor),
              const SizedBox(height: 14),

              // ── 3. DEDICATED ORDERS SECTION (PLACED BEFORE REVENUE) ──
              if (trip.activeOrder != null) ...[
                _buildActiveMissionCard(context, trip.activeOrder!, trip),
                const SizedBox(height: 14),
              ],
              _buildOrderDispatchSection(context, trip, sensor),
              const SizedBox(height: 14),

              // ── 4. EARNINGS DECK ──────────────────────────────────────
              _buildEarningsCollectionDeck(context, trip, safetyScore, isEsp32),
              const SizedBox(height: 14),

              // ── 5. TACTILE ACTION BUTTONS ─────────────────────────────
              _buildTactileActionGrid(context, trip, sensor, p),
              const SizedBox(height: 12),

              // ── 7. TELEMETRY STATUS ───────────────────────────────────
              Consumer<SensorProvider>(
                builder: (context, liveSensor, _) => _buildSensorTelemetryBar(context, liveSensor),
              ),
              const SizedBox(height: 16),

              // ── 8. MUNICIPAL ROAD RULES CARD ────────────────────────
              _buildMunicipalRulesCard(context),
            ],
          ),
        ),
      ),
    );
  }

  // ──────────────────────────────────────────────────────────────────────────
  // 1. HARDWARE CHASSIS HEADER (BLOCKIT STYLE)
  // ──────────────────────────────────────────────────────────────────────────
  Widget _buildSkeuomorphicHeader(dynamic profile, TripProvider trip, SensorProvider sensor) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Left: Clean Hamburger / Tactical Drawer Button
            Builder(
              builder: (innerContext) => GestureDetector(
                onTap: () {
                  HapticService.selectionClick();
                  Scaffold.of(innerContext).openDrawer();
                },
                child: Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: HardwarePalette.milledSurface,
                    shape: BoxShape.circle,
                    border: Border.all(color: HardwarePalette.matrixBorderLight, width: 1.0),
                    boxShadow: [
                      BoxShadow(
                        color: HardwarePalette.isDark ? Colors.black.withOpacity(0.2) : const Color(0xFF23201C).withOpacity(0.06),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Center(
                    child: Icon(
                      Icons.menu_rounded,
                      color: HardwarePalette.silkscreenDark,
                      size: 20,
                    ),
                  ),
                ),
              ),
            ),

            // Center Logo: Pixel block title with signature orange dot
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  "SMART",
                  style: GoogleFonts.silkscreen(
                    fontSize: 13,
                    fontWeight: FontWeight.w900,
                    color: HardwarePalette.silkscreenDark,
                    letterSpacing: 1.2,
                  ),
                ),
                Container(
                  width: 5,
                  height: 5,
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE53935),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFE53935).withOpacity(0.5),
                        blurRadius: 4,
                      ),
                    ],
                  ),
                ),
                Text(
                  "DRIVING",
                  style: GoogleFonts.silkscreen(
                    fontSize: 13,
                    fontWeight: FontWeight.w900,
                    color: HardwarePalette.silkscreenDark,
                    letterSpacing: 1.2,
                  ),
                ),
              ],
            ),

            // Right: Order symbol with live bubble badge & Safety Profile Pill
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                GestureDetector(
                  onTap: () {
                    HapticService.selectionClick();
                    Navigator.pushNamed(context, AppRoutes.orders);
                  },
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: HardwarePalette.milledSurface,
                          shape: BoxShape.circle,
                          border: Border.all(color: HardwarePalette.matrixBorderLight, width: 1.0),
                          boxShadow: [
                            BoxShadow(
                              color: HardwarePalette.isDark ? Colors.black.withOpacity(0.2) : const Color(0xFF23201C).withOpacity(0.04),
                              blurRadius: 6,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: const Center(
                          child: Icon(
                            Icons.local_shipping_outlined,
                            color: Color(0xFFFF5722),
                            size: 19,
                          ),
                        ),
                      ),
                      if (trip.availableOrders.isNotEmpty)
                        Positioned(
                          top: -3,
                          right: -3,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 4.5, vertical: 1.5),
                            constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                            decoration: BoxDecoration(
                              color: const Color(0xFFEF4444),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: Colors.white, width: 1.5),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFFEF4444).withOpacity(0.5),
                                  blurRadius: 4,
                                  offset: const Offset(0, 1),
                                ),
                              ],
                            ),
                            child: Center(
                              child: Text(
                                trip.availableOrders.length > 9 ? "9+" : "${trip.availableOrders.length}",
                                style: GoogleFonts.spaceGrotesk(
                                  fontSize: 8.5,
                                  fontWeight: FontWeight.w900,
                                  color: Colors.white,
                                  height: 1.0,
                                ),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),

                // Safety & Driver Profile Pill
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: HardwarePalette.milledSurface,
                    borderRadius: BorderRadius.circular(22),
                    border: Border.all(color: HardwarePalette.matrixBorderLight, width: 1.0),
                    boxShadow: [
                      BoxShadow(
                        color: HardwarePalette.isDark ? Colors.black.withOpacity(0.2) : const Color(0xFF23201C).withOpacity(0.04),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.shield_rounded, size: 14, color: HardwarePalette.silkscreenDark),
                      const SizedBox(width: 5),
                      Text(
                        "${profile.currentSafetyScore.toInt()}",
                        style: GoogleFonts.spaceGrotesk(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          color: HardwarePalette.silkscreenDark,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        width: 20,
                        height: 20,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: HardwarePalette.debossedSlot,
                        ),
                        child: Icon(Icons.person_rounded, size: 14, color: HardwarePalette.silkscreenDark),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: HardwarePalette.debossedSlot.withOpacity(0.6),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                "SMART MOBILE-BASED DRIVING BEHAVIOUR & RISK MONITORING",
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 8.5,
                  fontWeight: FontWeight.w700,
                  color: HardwarePalette.silkscreenSubtle,
                  letterSpacing: 0.3,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ──────────────────────────────────────────────────────────────────────────
  // 2. SHIFT DUTY MECHANICAL LEVER CONTROLLER
  // ──────────────────────────────────────────────────────────────────────────
  Widget _buildShiftLeverController(TripProvider trip, SensorProvider sensor) {
    return MechanicalLeverSwitch(
      value: trip.isShiftActive,
      label: "DUTY",
      activeLabel: "ONLINE",
      inactiveLabel: "STANDBY",
      activeColor: const Color(0xFFE53935),
      onChanged: (v) {
        if (v) {
          trip.startShift();
          sensor.startSensorMonitoring();
        } else {
          trip.endShift();
          sensor.stopSensorMonitoring();
        }
      },
    );
  }

  // ──────────────────────────────────────────────────────────────────────────
  // 3. TOTAL MONEY COLLECTION & EARNINGS DECK (BLOCKIT HERO CARD)
  // ──────────────────────────────────────────────────────────────────────────
  Widget _buildEarningsCollectionDeck(BuildContext context, TripProvider trip, double safetyScore, bool isEsp32) {
    return Column(
      children: [
        // Main Hero Card (Large 28px White Rounded Container)
        GestureDetector(
          onTap: () {
            HapticService.selectionClick();
            Navigator.pushNamed(context, AppRoutes.history);
          },
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 22),
            decoration: BoxDecoration(
              color: HardwarePalette.milledSurface,
              borderRadius: BorderRadius.circular(28),
              border: Border.all(color: HardwarePalette.matrixBorderLight, width: 1.2),
              boxShadow: [
                BoxShadow(
                  color: HardwarePalette.isDark ? Colors.black.withOpacity(0.25) : const Color(0xFF23201C).withOpacity(0.04),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "REVENUE",
                      style: GoogleFonts.spaceGrotesk(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: HardwarePalette.silkscreenSubtle,
                        letterSpacing: 1.0,
                      ),
                    ),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: HardwarePalette.debossedSlot,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            "TODAY",
                            style: GoogleFonts.spaceGrotesk(
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              color: HardwarePalette.silkscreenDark,
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Icon(Icons.chevron_right_rounded, size: 16, color: HardwarePalette.silkscreenSubtle),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text(
                      "₹${trip.totalIncome.toInt()}",
                      style: GoogleFonts.spaceGrotesk(
                        fontSize: 40,
                        fontWeight: FontWeight.w900,
                        color: HardwarePalette.silkscreenDark,
                        letterSpacing: -1.0,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      "${trip.todayTripCount} TRIPS",
                      style: GoogleFonts.spaceGrotesk(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: HardwarePalette.silkscreenSubtle,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: (trip.totalIncome / 2000.0).clamp(0.0, 1.0),
                    backgroundColor: HardwarePalette.debossedSlot,
                    valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFFE53935)),
                    minHeight: 6,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 10),

        // Secondary Metrics Deck
        Row(
          children: [
            _buildStatBox("DISTANCE", "${trip.todayDistanceKm.toStringAsFixed(1)} KM", Icons.navigation_outlined),
            const SizedBox(width: 10),
            _buildStatBox("SAFETY", "${safetyScore.toInt()}%", Icons.shield_outlined),
            const SizedBox(width: 10),
            _buildStatBox("ESP32", isEsp32 ? "ACTIVE" : "STANDBY", isEsp32 ? Icons.bluetooth_connected : Icons.bluetooth_disabled),
          ],
        ),
      ],
    );
  }

  Widget _buildStatBox(String title, String value, IconData icon) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        decoration: BoxDecoration(
          color: HardwarePalette.milledSurface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: HardwarePalette.matrixBorderLight, width: 1.0),
          boxShadow: [
            BoxShadow(
              color: HardwarePalette.isDark ? Colors.black.withOpacity(0.2) : const Color(0xFF23201C).withOpacity(0.04),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 18, color: HardwarePalette.silkscreenDark),
            const SizedBox(height: 10),
            Text(
              title,
              style: GoogleFonts.spaceGrotesk(
                fontSize: 8.5,
                color: HardwarePalette.silkscreenSubtle,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.5,
              ),
              maxLines: 1,
            ),
            const SizedBox(height: 2),
            Text(
              value,
              style: GoogleFonts.spaceGrotesk(
                fontSize: 14,
                fontWeight: FontWeight.w800,
                color: HardwarePalette.silkscreenDark,
              ),
              maxLines: 1,
            ),
          ],
        ),
      ),
    );
  }

  // ──────────────────────────────────────────────────────────────────────────
  // 4. QUICK ACTION BUTTONS (REWARDS, SCAN, RADAR, RULES, TOW, GUARDIAN, BURN)
  // ──────────────────────────────────────────────────────────────────────────
  Widget _buildTactileActionGrid(BuildContext context, TripProvider trip, SensorProvider sensor, dynamic profile) {
    return Column(
      children: [
        Row(
          children: [
            _buildActionKey(
              icon: Icons.local_shipping_rounded,
              label: "ORDERS",
              sub: trip.availableOrders.isEmpty ? "STANDBY" : "${trip.availableOrders.length} READY",
              badgeCount: trip.availableOrders.length,
              onTap: () => Navigator.pushNamed(context, AppRoutes.orders),
            ),
            const SizedBox(width: 8),
            _buildActionKey(
              icon: Icons.card_giftcard_rounded,
              label: "REWARDS",
              sub: "${trip.totalClaimedPoints} PTS",
              onTap: () => Navigator.pushNamed(context, AppRoutes.rewards),
            ),
            const SizedBox(width: 8),
            _buildActionKey(
              icon: Icons.qr_code_scanner_rounded,
              label: "SCAN",
              sub: "UPI PAY",
              onTap: () => UpiQrScannerModal.show(context),
            ),
            const SizedBox(width: 8),
            _buildActionKey(
              icon: Icons.sensors_rounded,
              label: "RADAR",
              sub: "DIAGNOSE",
              onTap: () => SensorRadarModal.show(context),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            _buildActionKey(
              icon: Icons.build_circle_rounded,
              label: "TOW SOS",
              sub: "BREAKDOWN",
              onTap: () => RoadsideBreakdownModal.show(context),
            ),
            const SizedBox(width: 8),
            _buildActionKey(
              icon: Icons.share_location_rounded,
              label: "GUARDIAN",
              sub: "LIVE SHARE",
              onTap: () => GuardianShareModal.show(
                context,
                driverId: (profile.driverId != null && profile.driverId.isNotEmpty) ? profile.driverId : 'agent-x',
                driverName: (profile.name != null && profile.name.isNotEmpty) ? profile.name : 'Field Operator',
              ),
            ),
            const SizedBox(width: 8),
            _buildActionKey(
              icon: Icons.wifi_off_rounded,
              label: "DEAD ZONE",
              sub: SocketService.isConnected ? "LIVE LINK" : "${SocketService.offlineBufferedCount} SAVED",
              onTap: () => ServerConnectionModal.show(context),
            ),
            const SizedBox(width: 8),
            _buildActionKey(
              icon: Icons.receipt_long_rounded,
              label: "LEDGER",
              sub: "AUDIT & UPI",
              onTap: () => Navigator.pushNamed(context, AppRoutes.history),
            ),
          ],
        ),
      ],
    );
  }

  void _launchFakeDeliverySimulation(BuildContext context, TripProvider trip, SensorProvider sensor) async {
    HapticService.heavyImpact();
    if (!trip.isShiftActive) trip.startShift();
    sensor.startSensorMonitoring();

    final newOrder = await trip.generateMockOrder();

    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle_rounded, color: Colors.white, size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                "SIMULATED MISSION ADDED (${newOrder.id})\nTo: ${newOrder.dropAddress}",
                style: GoogleFonts.spaceGrotesk(fontWeight: FontWeight.w700, fontSize: 11),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        backgroundColor: const Color(0xFFE53935),
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  Widget _buildActionKey({
    required IconData icon,
    required String label,
    required String sub,
    required VoidCallback onTap,
    int badgeCount = 0,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: () {
          HapticService.selectionClick();
          onTap();
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 6),
          decoration: BoxDecoration(
            color: HardwarePalette.milledSurface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: HardwarePalette.matrixBorderLight, width: 1.0),
            boxShadow: [
              BoxShadow(
                color: HardwarePalette.isDark ? Colors.black.withOpacity(0.2) : const Color(0xFF23201C).withOpacity(0.04),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Column(
            children: [
              Stack(
                clipBehavior: Clip.none,
                children: [
                  Icon(icon, color: HardwarePalette.silkscreenDark, size: 22),
                  if (badgeCount > 0)
                    Positioned(
                      top: -4,
                      right: -8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 4.5, vertical: 1.5),
                        constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEF4444),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: Colors.white, width: 1.5),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFFEF4444).withOpacity(0.5),
                              blurRadius: 4,
                              offset: const Offset(0, 1),
                            ),
                          ],
                        ),
                        child: Center(
                          child: Text(
                            badgeCount > 9 ? "9+" : "$badgeCount",
                            style: GoogleFonts.spaceGrotesk(
                              fontSize: 9,
                              fontWeight: FontWeight.w900,
                              color: Colors.white,
                              height: 1.0,
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                label,
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 10.5,
                  fontWeight: FontWeight.w800,
                  color: HardwarePalette.silkscreenDark,
                ),
              ),
              Text(
                sub,
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 8.5,
                  fontWeight: FontWeight.w600,
                  color: HardwarePalette.silkscreenSubtle,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ──────────────────────────────────────────────────────────────────────────
  // 5. LIVE SENSOR TELEMETRY BAR
  // ──────────────────────────────────────────────────────────────────────────
  Widget _buildSensorTelemetryBar(BuildContext context, SensorProvider sensor) {
    final double gForce = sensor.totalGForce;
    final double vib = sensor.vibrationRate;
    final double degX = sensor.gyroDegX;
    final double degY = sensor.gyroDegY;
    final bool hasDefect = sensor.hasAnyDefect;
    final List<String> defects = sensor.defectDescriptions;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // ── SENSOR DEFECT WARNING BANNER (Shows if any sensor is defective/lost) ──
        if (hasDefect && !_isHardwareDefectDismissed) ...[
          Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: const Color(0xFFFEF2F2),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFEF4444), width: 1.2),
            ),
            child: Row(
              children: [
                GestureDetector(
                  onTap: () {
                    HapticService.selectionClick();
                    SensorRadarModal.show(context);
                  },
                  child: const Icon(Icons.warning_amber_rounded, color: Color(0xFFDC2626), size: 20),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: GestureDetector(
                    onTap: () {
                      HapticService.selectionClick();
                      SensorRadarModal.show(context);
                    },
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "HARDWARE SENSOR DEFECT DETECTED",
                          style: GoogleFonts.spaceGrotesk(
                            fontSize: 10.5,
                            fontWeight: FontWeight.w800,
                            color: const Color(0xFFDC2626),
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          defects.isNotEmpty ? defects.first : "One or more telemetry sensors are unresponsive.",
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF991B1B),
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                GestureDetector(
                  onTap: () {
                    HapticService.selectionClick();
                    SensorRadarModal.show(context);
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFDC2626),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      "FIX",
                      style: GoogleFonts.spaceGrotesk(
                        fontSize: 9.5,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: () {
                    HapticService.lightImpact();
                    setState(() {
                      _isHardwareDefectDismissed = true;
                    });
                  },
                  behavior: HitTestBehavior.opaque,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFEE2E2),
                      shape: BoxShape.circle,
                      border: Border.all(color: const Color(0xFFFCA5A5), width: 1),
                    ),
                    child: const Icon(
                      Icons.close_rounded,
                      size: 14,
                      color: Color(0xFFDC2626),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],

        // ── MAIN TELEMETRY & ATTRIBUTION CARD ──
        GestureDetector(
          onTap: () {
            HapticService.selectionClick();
            SensorRadarModal.show(context);
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: HardwarePalette.milledSurface,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: HardwarePalette.matrixBorderLight, width: 1.0),
              boxShadow: [
                BoxShadow(
                  color: HardwarePalette.isDark ? Colors.black.withOpacity(0.2) : const Color(0xFF23201C).withOpacity(0.03),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Row: Explicit Hardware Status Badges
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // External Chassis IMU Pill (Explicitly Not Connected when not paired)
                    Flexible(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3.5),
                        decoration: BoxDecoration(
                          color: sensor.isEsp32Connected
                              ? const Color(0xFFECFDF5)
                              : HardwarePalette.debossedSlot,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: sensor.isEsp32Connected
                                ? HardwarePalette.signalEmerald
                                : HardwarePalette.matrixBorderLight,
                            width: 0.8,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 6,
                              height: 6,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: sensor.isEsp32Connected
                                    ? HardwarePalette.signalEmerald
                                    : HardwarePalette.silkscreenSubtle,
                              ),
                            ),
                            const SizedBox(width: 5),
                            Flexible(
                              child: Text(
                                sensor.isEsp32Connected ? "CHASSIS IMU: CONNECTED" : "CHASSIS IMU: NOT CONNECTED",
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.jetBrainsMono(
                                  fontSize: 8.5,
                                  fontWeight: FontWeight.w800,
                                  color: sensor.isEsp32Connected
                                      ? HardwarePalette.signalEmerald
                                      : HardwarePalette.silkscreenSubtle,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),

                    // Phone Motion Badge
                    Flexible(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3.5),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF0F9FF),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: const Color(0xFFBAE6FD), width: 0.8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 6,
                              height: 6,
                              decoration: const BoxDecoration(
                                shape: BoxShape.circle,
                                color: Color(0xFF0284C7),
                              ),
                            ),
                            const SizedBox(width: 5),
                            Flexible(
                              child: Text(
                                "PHONE 6-AXIS: ACTIVE",
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.jetBrainsMono(
                                  fontSize: 8.5,
                                  fontWeight: FontWeight.w800,
                                  color: const Color(0xFF0284C7),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Middle Row: Telemetry Values with Explicit Attribution
                Row(
                  children: [
                    // G-Force with Attribution
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "G-FORCE",
                            style: GoogleFonts.jetBrainsMono(fontSize: 8, color: HardwarePalette.silkscreenSubtle, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            "${gForce.toStringAsFixed(2)} G",
                            style: GoogleFonts.jetBrainsMono(
                              fontSize: 13,
                              fontWeight: FontWeight.w900,
                              color: gForce > 1.8 ? HardwarePalette.terracottaRed : HardwarePalette.silkscreenDark,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            sensor.isEsp32Connected ? "[ESP32 Accel]" : "[Phone Accel]",
                            style: GoogleFonts.spaceGrotesk(
                              fontSize: 8.5,
                              fontWeight: FontWeight.w700,
                              color: sensor.isEsp32Connected ? HardwarePalette.signalEmerald : const Color(0xFF0284C7),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Rotation Angles with Attribution
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "ANGLES (P/R)",
                            style: GoogleFonts.jetBrainsMono(fontSize: 8, color: HardwarePalette.silkscreenSubtle, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            "${degX.toStringAsFixed(1)}° / ${degY.toStringAsFixed(1)}°",
                            style: GoogleFonts.jetBrainsMono(fontSize: 12, fontWeight: FontWeight.bold, color: HardwarePalette.silkscreenDark),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            sensor.isEsp32Connected ? "[ESP32 Gyro]" : "[Phone Gyro]",
                            style: GoogleFonts.spaceGrotesk(
                              fontSize: 8.5,
                              fontWeight: FontWeight.w700,
                              color: sensor.isEsp32Connected ? HardwarePalette.signalEmerald : const Color(0xFF0284C7),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Vibration with Filter status
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "VIBRATION",
                            style: GoogleFonts.jetBrainsMono(fontSize: 8, color: HardwarePalette.silkscreenSubtle, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            "${vib.toStringAsFixed(1)} m/s²",
                            style: GoogleFonts.jetBrainsMono(fontSize: 12, fontWeight: FontWeight.bold, color: HardwarePalette.silkscreenDark),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            vib > 0.0 ? "[Significant]" : "[Filtered Zero]",
                            style: GoogleFonts.spaceGrotesk(
                              fontSize: 8.5,
                              fontWeight: FontWeight.w700,
                              color: HardwarePalette.silkscreenSubtle,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Divider(height: 1, color: HardwarePalette.matrixBorderLight),
                const SizedBox(height: 6),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "NOISE SUPPRESSION: ACTIVE (DEADBAND ON)",
                      style: GoogleFonts.jetBrainsMono(
                        fontSize: 7.5,
                        fontWeight: FontWeight.w600,
                        color: HardwarePalette.silkscreenSubtle,
                      ),
                    ),
                    Row(
                      children: [
                        Text(
                          "HARDWARE MATRIX",
                          style: GoogleFonts.spaceGrotesk(
                            fontSize: 8.5,
                            fontWeight: FontWeight.w800,
                            color: HardwarePalette.silkscreenDark,
                          ),
                        ),
                        const SizedBox(width: 2),
                        Icon(Icons.chevron_right_rounded, size: 12, color: HardwarePalette.silkscreenDark),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ──────────────────────────────────────────────────────────────────────────
  // 6. ACTIVE MISSION CARD
  // ──────────────────────────────────────────────────────────────────────────
  Widget _buildActiveMissionCard(BuildContext context, DeliveryOrder order, TripProvider trip) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: HardwarePalette.milledSurface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: HardwarePalette.matrixBorderLight, width: 1.2),
        boxShadow: [
          BoxShadow(
            color: HardwarePalette.isDark ? Colors.black.withOpacity(0.2) : const Color(0xFF23201C).withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "ACTIVE DISPATCH MISSION // ${order.id}",
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: HardwarePalette.silkscreenSubtle,
                ),
              ),
              Text(
                "₹${order.payoutAmount.toInt()}",
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                  color: HardwarePalette.signalEmerald,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Delivery Driver Details Card with direct Call Button
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: HardwarePalette.debossedSlot,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: HardwarePalette.matrixBorderLight),
            ),
            child: Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: HardwarePalette.signalEmerald.withOpacity(0.15),
                    border: Border.all(color: HardwarePalette.signalEmerald, width: 1.5),
                  ),
                  child: Center(
                    child: Icon(Icons.delivery_dining_rounded, color: HardwarePalette.signalEmerald, size: 22),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        order.driverName,
                        style: GoogleFonts.spaceGrotesk(
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          color: HardwarePalette.silkscreenDark,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        "${order.driverPhone} • ${order.driverAddress}",
                        style: GoogleFonts.spaceGrotesk(
                          fontSize: 10.5,
                          color: HardwarePalette.silkscreenMuted,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),

                // Call Driver Button
                GestureDetector(
                  onTap: () async {
                    final dialed = await order.callDriver();
                    if (!dialed && context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text("Calling driver at ${order.driverPhone}..."),
                          duration: const Duration(seconds: 2),
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: HardwarePalette.signalEmerald,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.call_rounded, color: Colors.white, size: 14),
                        const SizedBox(width: 4),
                        Text(
                          "CALL",
                          style: GoogleFonts.spaceGrotesk(
                            fontSize: 11,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),

          Text(
            order.dropAddress,
            style: GoogleFonts.spaceGrotesk(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: HardwarePalette.silkscreenDark,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            "FROM: ${order.pickupAddress} • ${order.distanceKm} KM",
            style: GoogleFonts.spaceGrotesk(
              fontSize: 11,
              color: HardwarePalette.silkscreenMuted,
            ),
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Expanded(
                child: Text(
                  "📦 ${order.packageItems} • Cust: ${order.customerName}",
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: 10.5,
                    color: HardwarePalette.silkscreenSubtle,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.phone_in_talk_rounded, color: Color(0xFF1A73E8), size: 16),
                constraints: const BoxConstraints(),
                padding: const EdgeInsets.all(4),
                tooltip: "Call Customer (${order.customerPhone})",
                onPressed: () => order.callCustomer(),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () => MapNavigationService.openGoogleMaps(
                    order: order,
                    originLat: trip.currentLat,
                    originLng: trip.currentLng,
                    destLat: order.dropLat,
                    destLng: order.dropLng,
                    address: order.dropAddress,
                    context: context,
                  ),
                  child: Container(
                    height: 44,
                    decoration: BoxDecoration(
                      color: const Color(0xFF4285F4).withOpacity(0.12),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0xFF4285F4).withOpacity(0.4)),
                    ),
                    child: Center(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.directions_rounded, size: 16, color: Color(0xFF1A73E8)),
                          const SizedBox(width: 5),
                          Flexible(
                            child: FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Text(
                                "GOOGLE MAPS",
                                style: GoogleFonts.spaceGrotesk(
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w800,
                                  color: const Color(0xFF1A73E8),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: () => Navigator.pushNamed(context, AppRoutes.map),
                child: Container(
                  height: 44,
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  decoration: BoxDecoration(
                    color: HardwarePalette.debossedSlot,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: HardwarePalette.matrixBorderLight),
                  ),
                  child: Center(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.map_outlined, size: 16, color: HardwarePalette.silkscreenDark),
                        const SizedBox(width: 4),
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            "IN-APP",
                            style: GoogleFonts.spaceGrotesk(
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              color: HardwarePalette.silkscreenDark,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: GestureDetector(
                  onTap: () async {
                    final completedTrip = await trip.completeActiveOrder();
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Row(
                            children: [
                              const Icon(Icons.stars_rounded, color: Colors.amberAccent, size: 20),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  "Delivered! +₹${(completedTrip.payout ?? 0.0).toInt()} & +${completedTrip.pointsEarned} PTS Added",
                                  style: const TextStyle(fontWeight: FontWeight.w700),
                                ),
                              ),
                            ],
                          ),
                          backgroundColor: const Color(0xFF065F46),
                          behavior: SnackBarBehavior.floating,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                      );
                    }
                  },
                  child: Container(
                    height: 44,
                    decoration: BoxDecoration(
                      color: HardwarePalette.signalEmerald,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Center(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.check_circle_outline_rounded, size: 16, color: Colors.white),
                          const SizedBox(width: 5),
                          Flexible(
                            child: FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Text(
                                "DELIVERED",
                                style: GoogleFonts.spaceGrotesk(
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ──────────────────────────────────────────────────────────────────────────
  // 7. ORDER DISPATCH SECTION
  // ──────────────────────────────────────────────────────────────────────────
  Widget _buildOrderDispatchSection(BuildContext context, TripProvider trip, SensorProvider sensor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Row(
                children: [
                  Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFF5722).withOpacity(0.12),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(
                          Icons.local_shipping_rounded,
                          size: 18,
                          color: Color(0xFFFF5722),
                        ),
                      ),
                      if (trip.availableOrders.isNotEmpty)
                        Positioned(
                          top: -4,
                          right: -4,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                            constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                            decoration: BoxDecoration(
                              color: const Color(0xFFEF4444),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: Colors.white, width: 1.5),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFFEF4444).withOpacity(0.5),
                                  blurRadius: 4,
                                  offset: const Offset(0, 1),
                                ),
                              ],
                            ),
                            child: Center(
                              child: Text(
                                "${trip.availableOrders.length}",
                                style: GoogleFonts.spaceGrotesk(
                                  fontSize: 9,
                                  fontWeight: FontWeight.w900,
                                  color: Colors.white,
                                  height: 1.0,
                                ),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      "DISPATCH ORDERS",
                      style: GoogleFonts.spaceGrotesk(
                        fontSize: 12,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.8,
                        color: HardwarePalette.silkscreenSubtle,
                      ),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                GestureDetector(
                  onTap: () {
                    HapticService.heavyImpact();
                    _launchFakeDeliverySimulation(context, trip, sensor);
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFF5722),
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFFFF5722).withOpacity(0.3),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.add_circle_outline_rounded, size: 12, color: Colors.white),
                        const SizedBox(width: 3),
                        Text(
                          "SIMULATE",
                          style: GoogleFonts.spaceGrotesk(
                            fontSize: 10,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                            letterSpacing: 0.4,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: () => Navigator.pushNamed(context, AppRoutes.orders),
                  child: Text(
                    "VIEW ALL →",
                    style: GoogleFonts.spaceGrotesk(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w800,
                      color: const Color(0xFFFF5722),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 10),
        if (trip.availableOrders.isEmpty)
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: HardwarePalette.milledSurface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: HardwarePalette.matrixBorderLight),
            ),
            child: Center(
              child: Column(
                children: [
                  Icon(Icons.local_shipping_outlined, color: HardwarePalette.silkscreenSubtle, size: 28),
                  const SizedBox(height: 6),
                  Text(
                    "No dispatch orders pending in this sector",
                    style: GoogleFonts.spaceGrotesk(
                      fontSize: 12,
                      color: HardwarePalette.silkscreenSubtle,
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextButton.icon(
                    onPressed: () => _launchFakeDeliverySimulation(context, trip, sensor),
                    icon: const Icon(Icons.rocket_launch_rounded, size: 16, color: Color(0xFFFF5722)),
                    label: Text(
                      "Generate Simulated Mission",
                      style: GoogleFonts.spaceGrotesk(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFFFF5722),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          )
        else
          ...trip.availableOrders.take(3).map((order) {
            return Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: HardwarePalette.milledSurface,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: HardwarePalette.matrixBorderLight),
                boxShadow: [
                  BoxShadow(
                    color: HardwarePalette.isDark ? Colors.black.withOpacity(0.2) : const Color(0xFF23201C).withOpacity(0.02),
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
                      Text(
                        order.id,
                        style: GoogleFonts.spaceGrotesk(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: HardwarePalette.silkscreenSubtle,
                        ),
                      ),
                      Text(
                        "₹${order.payoutAmount.toInt()}",
                        style: GoogleFonts.spaceGrotesk(
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                          color: const Color(0xFFFF5722),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    order.dropAddress,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.spaceGrotesk(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: HardwarePalette.silkscreenDark,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    "PICKUP: ${order.pickupAddress} • ${order.distanceKm} KM",
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.spaceGrotesk(
                      fontSize: 10.5,
                      color: HardwarePalette.silkscreenMuted,
                    ),
                  ),
                  const SizedBox(height: 12),
                  MechanicalMissionSlider(
                    height: 48,
                    label: "SWIPE TO ACCEPT",
                    completedLabel: "ACCEPTED",
                    accentColor: const Color(0xFFFF5722),
                    onAction: () async {
                      _promptAcceptOrderChoice(context, trip, order);
                    },
                  ),
                ],
              ),
            );
          }),
      ],
    );
  }

  void _promptAcceptOrderChoice(BuildContext context, TripProvider trip, DeliveryOrder order) {
    HapticService.selectionClick();
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: HardwarePalette.chalkChassis,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: HardwarePalette.matrixBorderLight,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                "SELECT NAVIGATION MODE",
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 14,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0.8,
                  color: HardwarePalette.silkscreenDark,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                "Mission: ${order.dropAddress} • ₹${order.payoutAmount.toInt()}",
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 11,
                  color: HardwarePalette.silkscreenSubtle,
                ),
              ),
              const SizedBox(height: 16),
              ListTile(
                tileColor: HardwarePalette.milledSurface,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                leading: const Icon(Icons.radar_rounded, color: Color(0xFFFF5722)),
                title: Text(
                  "In-App Live Radar & Map",
                  style: GoogleFonts.spaceGrotesk(fontWeight: FontWeight.w800, fontSize: 13, color: HardwarePalette.silkscreenDark),
                ),
                subtitle: Text(
                  "Includes live hazard detection, telemetry & risk audit",
                  style: GoogleFonts.spaceGrotesk(fontSize: 10.5, color: HardwarePalette.silkscreenSubtle),
                ),
                trailing: Icon(Icons.arrow_forward_ios_rounded, size: 14, color: HardwarePalette.silkscreenSubtle),
                onTap: () {
                  Navigator.pop(ctx);
                  trip.acceptOrderWithChoice(order, inAppNavigation: true);
                  Navigator.pushNamed(context, AppRoutes.map);
                },
              ),
              const SizedBox(height: 8),
              ListTile(
                tileColor: HardwarePalette.milledSurface,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                leading: const Icon(Icons.map_rounded, color: Color(0xFF0038FF)),
                title: Text(
                  "Google Maps Navigation",
                  style: GoogleFonts.spaceGrotesk(fontWeight: FontWeight.w800, fontSize: 13, color: HardwarePalette.silkscreenDark),
                ),
                subtitle: Text(
                  "Turn-by-turn routing with background risk monitoring",
                  style: GoogleFonts.spaceGrotesk(fontSize: 10.5, color: HardwarePalette.silkscreenSubtle),
                ),
                trailing: Icon(Icons.arrow_forward_ios_rounded, size: 14, color: HardwarePalette.silkscreenSubtle),
                onTap: () {
                  Navigator.pop(ctx);
                  trip.acceptOrderWithChoice(order, inAppNavigation: false);
                  MapNavigationService.openGoogleMaps(
                    originLat: trip.currentLat,
                    originLng: trip.currentLng,
                    destLat: order.dropLat,
                    destLng: order.dropLng,
                    address: order.dropAddress,
                    context: context,
                  );
                },
              ),
              const SizedBox(height: 12),
            ],
          ),
        );
      },
    );
  }

  // ──────────────────────────────────────────────────────────────────────────
  // 8. MUNICIPAL ROAD RULES CARD
  // ──────────────────────────────────────────────────────────────────────────
  Widget _buildMunicipalRulesCard(BuildContext context) {
    final rules = RoadRulesService.getRegulationsForLocation();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: HardwarePalette.milledSurface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: HardwarePalette.matrixBorderLight, width: 1.2),
        boxShadow: [
          BoxShadow(
            color: HardwarePalette.isDark ? Colors.black.withOpacity(0.2) : const Color(0xFF23201C).withOpacity(0.03),
            blurRadius: 6,
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
                  Container(
                    width: 7,
                    height: 7,
                    decoration: const BoxDecoration(
                      color: Color(0xFFFF5722),
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    "MUNICIPAL RULES // ${rules.cityName.toUpperCase()}",
                    style: GoogleFonts.spaceGrotesk(
                      fontSize: 11,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.8,
                      color: HardwarePalette.silkscreenDark,
                    ),
                  ),
                ],
              ),
              GestureDetector(
                onTap: () => MunicipalRulesModal.show(context),
                child: Text(
                  "VIEW ALL →",
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFFFF5722),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _buildRuleChip("SCHOOL", "${rules.schoolZoneSpeedLimit.toInt()} KM/H", const Color(0xFFFF5722)),
              const SizedBox(width: 8),
              _buildRuleChip("SILENCE", "NO HORN", const Color(0xFF0038FF)),
              const SizedBox(width: 8),
              _buildRuleChip("CITY", "${rules.mainRoadSpeedLimit.toInt()} KM/H", const Color(0xFF443F3C)),
              const SizedBox(width: 8),
              _buildRuleChip("HIGHWAY", "${rules.highwaySpeedLimit.toInt()} KM/H", const Color(0xFF059669)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRuleChip(String label, String value, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
        decoration: BoxDecoration(
          color: color.withOpacity(0.06),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withOpacity(0.2)),
        ),
        child: Column(
          children: [
            Text(
              label,
              style: GoogleFonts.spaceGrotesk(
                fontSize: 8.5,
                fontWeight: FontWeight.w800,
                color: color,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              value,
              style: GoogleFonts.spaceGrotesk(
                fontSize: 9.5,
                fontWeight: FontWeight.w900,
                color: HardwarePalette.silkscreenDark,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildScrewRivet() {
    return Container(
      width: 10,
      height: 10,
      decoration: BoxDecoration(
        color: const Color(0xFFE2E8F0),
        shape: BoxShape.circle,
        border: Border.all(color: const Color(0xFFCBD5E1), width: 1.0),
      ),
      child: Center(
        child: Container(
          width: 4,
          height: 1,
          color: const Color(0xFF94A3B8),
        ),
      ),
    );
  }
}

class _SkeuoSplinePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = HardwarePalette.silkscreenDark
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0
      ..strokeCap = StrokeCap.round;

    final path = Path();
    final points = [
      Offset(0, size.height * 0.7),
      Offset(size.width * 0.2, size.height * 0.72),
      Offset(size.width * 0.38, size.height * 0.42),
      Offset(size.width * 0.55, size.height * 0.2),
      Offset(size.width * 0.72, size.height * 0.55),
      Offset(size.width * 0.88, size.height * 0.4),
      Offset(size.width, size.height * 0.35),
    ];

    path.moveTo(points.first.dx, points.first.dy);
    for (int i = 0; i < points.length - 1; i++) {
      final p1 = points[i];
      final p2 = points[i + 1];
      final controlX = p1.dx + (p2.dx - p1.dx) / 2;
      path.cubicTo(controlX, p1.dy, controlX, p2.dy, p2.dx, p2.dy);
    }

    canvas.drawPath(path, paint);

    // Peak dot
    final peak = points[3];
    canvas.drawCircle(peak, 5, Paint()..color = HardwarePalette.signalEmerald);
    canvas.drawCircle(peak, 2, Paint()..color = Colors.white);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}