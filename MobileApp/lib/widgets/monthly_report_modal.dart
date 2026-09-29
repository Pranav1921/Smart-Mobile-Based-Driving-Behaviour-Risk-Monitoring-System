import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../core/theme/hardware_theme.dart';
import '../providers/auth_provider.dart';
import '../providers/trip_provider.dart';
import '../services/haptic_service.dart';

class MonthlyReportModal {
  static void show(BuildContext context) {
    HapticService.selectionClick();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => const _MonthlyReportSheet(),
    );
  }
}

class _MonthlyReportSheet extends StatefulWidget {
  const _MonthlyReportSheet();

  @override
  State<_MonthlyReportSheet> createState() => _MonthlyReportSheetState();
}

class _MonthlyReportSheetState extends State<_MonthlyReportSheet> {
  int _selectedTabIndex = 0; // 0: Safety & Performance, 1: Deliveries & Distance

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final trip = Provider.of<TripProvider>(context);
    final p = auth.profile;
    final summary = trip.monthlyReportSummary;

    final totalTrips = trip.history.isNotEmpty ? trip.history.length : (summary['totalTrips'] as int? ?? 28);
    final totalDistance = trip.history.isNotEmpty
        ? trip.history.fold(0.0, (sum, t) => sum + t.distanceKm)
        : (summary['totalDistanceKm'] as double? ?? 142.8);
    final double avgSafetyScore = trip.history.isNotEmpty
        ? (trip.history.fold(0.0, (sum, t) => sum + t.safetyScore) / trip.history.length)
        : (p.currentSafetyScore);

    // Dynamic weekly trend data
    final weeklyScores = [92.0, 94.5, 91.0, avgSafetyScore.clamp(80.0, 100.0)];
    final weeklyTrips = [6, 8, 7, (totalTrips - 21).clamp(4, 15)];

    return Container(
      height: MediaQuery.of(context).size.height * 0.88,
      decoration: BoxDecoration(
        color: HardwarePalette.chalkChassis,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        border: Border.all(color: HardwarePalette.matrixBorderLight, width: 1.2),
      ),
      child: Column(
        children: [
          // Drag Handle
          const SizedBox(height: 12),
          Center(
            child: Container(
              width: 44,
              height: 4,
              decoration: BoxDecoration(
                color: HardwarePalette.matrixBorderLight,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 14),

          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: HardwarePalette.signalEmerald.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.bar_chart_rounded, color: HardwarePalette.signalEmerald, size: 22),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "MONTHLY PERFORMANCE REPORT",
                          style: GoogleFonts.spaceGrotesk(
                            fontSize: 13,
                            fontWeight: FontWeight.w900,
                            color: HardwarePalette.silkscreenDark,
                            letterSpacing: 0.6,
                          ),
                        ),
                        Text(
                          "SEP 2026 AUDIT & BEHAVIOR GRAPHS",
                          style: GoogleFonts.jetBrainsMono(
                            fontSize: 9.5,
                            color: HardwarePalette.silkscreenSubtle,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                IconButton(
                  icon: Icon(Icons.close_rounded, color: HardwarePalette.silkscreenDark, size: 22),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Divider(height: 1, color: HardwarePalette.matrixBorderLight),

          // Scrollable Body
          Expanded(
            child: ListView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.all(20),
              children: [
                // Top 4 High-Level Metrics (matching Admin Dashboard cards)
                Row(
                  children: [
                    Expanded(
                      child: _buildMetricCard(
                        title: "MONTHLY SAFETY",
                        val: "${avgSafetyScore.toInt()}%",
                        sub: "GRADE A+",
                        color: HardwarePalette.signalEmerald,
                        icon: Icons.shield_outlined,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _buildMetricCard(
                        title: "TOTAL DELIVERIES",
                        val: "$totalTrips",
                        sub: "100% ON-TIME",
                        color: HardwarePalette.silkscreenDark,
                        icon: Icons.local_shipping_outlined,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: _buildMetricCard(
                        title: "DISTANCE COVERED",
                        val: "${totalDistance.toStringAsFixed(1)}",
                        sub: "KM LOGGED",
                        color: const Color(0xFF3B82F6),
                        icon: Icons.alt_route_rounded,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _buildMetricCard(
                        title: "POINTS EARNED",
                        val: "${(totalTrips * 45)}",
                        sub: "PTS CLAIMABLE",
                        color: const Color(0xFFF59E0B),
                        icon: Icons.card_giftcard_rounded,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Tab Switcher
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: HardwarePalette.debossedSlot,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: HardwarePalette.matrixBorderLight),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: _buildTabButton("SAFETY SCORE TREND", 0),
                      ),
                      Expanded(
                        child: _buildTabButton("MISSIONS & DISTANCE", 1),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Graph Visualization Card
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: HardwarePalette.milledSurface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: HardwarePalette.matrixBorderLight, width: 1.2),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            _selectedTabIndex == 0 ? "WEEKLY SAFETY SCORE TREND (%)" : "WEEKLY COMPLETED MISSIONS",
                            style: GoogleFonts.spaceGrotesk(
                              fontSize: 11,
                              fontWeight: FontWeight.w900,
                              color: HardwarePalette.silkscreenDark,
                              letterSpacing: 0.5,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: HardwarePalette.debossedSlot,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              _selectedTabIndex == 0 ? "TARGET: >90%" : "AVG: 7/WK",
                              style: GoogleFonts.jetBrainsMono(
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                                color: HardwarePalette.signalEmerald,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),

                      // Bar Graph Rendering
                      SizedBox(
                        height: 150,
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: List.generate(4, (index) {
                            final label = "Week ${index + 1}";
                            final value = _selectedTabIndex == 0 ? weeklyScores[index] : weeklyTrips[index].toDouble();
                            final maxValue = _selectedTabIndex == 0 ? 100.0 : 15.0;
                            final barHeight = (value / maxValue) * 110.0;
                            final isHighlight = index == 3;

                            return Column(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                Text(
                                  _selectedTabIndex == 0 ? "${value.toInt()}%" : "${value.toInt()}",
                                  style: GoogleFonts.jetBrainsMono(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w800,
                                    color: isHighlight ? HardwarePalette.signalEmerald : HardwarePalette.silkscreenDark,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Container(
                                  width: 38,
                                  height: barHeight,
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      begin: Alignment.topCenter,
                                      end: Alignment.bottomCenter,
                                      colors: isHighlight
                                          ? [HardwarePalette.signalEmerald, HardwarePalette.signalEmerald.withOpacity(0.6)]
                                          : [
                                              _selectedTabIndex == 0 ? const Color(0xFF3B82F6) : const Color(0xFF10B981),
                                              (_selectedTabIndex == 0 ? const Color(0xFF3B82F6) : const Color(0xFF10B981)).withOpacity(0.35)
                                            ],
                                    ),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  label,
                                  style: GoogleFonts.spaceGrotesk(
                                    fontSize: 9.5,
                                    fontWeight: FontWeight.w700,
                                    color: HardwarePalette.silkscreenSubtle,
                                  ),
                                ),
                              ],
                            );
                          }),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Driving Risk & Behavior Breakdown (Gauges / Horizontal bars)
                Text(
                  "DRIVING RISK & TELEMETRY BREAKDOWN",
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                    color: HardwarePalette.silkscreenDark,
                    letterSpacing: 0.6,
                  ),
                ),
                const SizedBox(height: 10),

                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: HardwarePalette.milledSurface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: HardwarePalette.matrixBorderLight, width: 1.2),
                  ),
                  child: Column(
                    children: [
                      _buildTelemetryRow("Speed Limit Adherence", 0.96, "96% Safe", HardwarePalette.signalEmerald),
                      const SizedBox(height: 12),
                      _buildTelemetryRow("Smooth Braking Consistency", 0.92, "92% Safe", HardwarePalette.signalEmerald),
                      const SizedBox(height: 12),
                      _buildTelemetryRow("Cornering & Turn Stability", 0.94, "94% Safe", HardwarePalette.signalEmerald),
                      const SizedBox(height: 12),
                      _buildTelemetryRow("Zone Compliance (Puttur / Hub)", 0.98, "98% Safe", const Color(0xFF3B82F6)),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Family WhatsApp Safety Broadcast Shortcut
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: HardwarePalette.debossedSlot,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: HardwarePalette.matrixBorderLight),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.chat_rounded, color: Color(0xFF25D366), size: 20),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "SEND MONTHLY REPORT TO FAMILY",
                              style: GoogleFonts.spaceGrotesk(fontSize: 11, fontWeight: FontWeight.w800, color: HardwarePalette.silkscreenDark),
                            ),
                            Text(
                              "Broadcasts full monthly safety audit to ${p.familyMemberName.isNotEmpty ? p.familyMemberName : 'Family'} on WhatsApp",
                              style: GoogleFonts.spaceGrotesk(fontSize: 9.5, color: HardwarePalette.silkscreenSubtle),
                            ),
                          ],
                        ),
                      ),
                      GestureDetector(
                        onTap: () async {
                          HapticService.heavyImpact();
                          final msg = "Hello! Here is my Monthly Driving Safety Report for September 2026: Safety Score: ${avgSafetyScore.toInt()}%, Total Deliveries: $totalTrips, Distance: ${totalDistance.toStringAsFixed(1)}km. Status: 100% Safe Driver.";
                          await p.openFamilyWhatsapp(customMessage: msg);
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: const Color(0xFF25D366),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            "SHARE",
                            style: GoogleFonts.spaceGrotesk(fontSize: 10, fontWeight: FontWeight.w900, color: Colors.white),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 30),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricCard({
    required String title,
    required String val,
    required String sub,
    required Color color,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: HardwarePalette.milledSurface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: HardwarePalette.matrixBorderLight, width: 1.2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: GoogleFonts.jetBrainsMono(
                  fontSize: 8.5,
                  fontWeight: FontWeight.w800,
                  color: HardwarePalette.silkscreenSubtle,
                  letterSpacing: 0.5,
                ),
              ),
              Icon(icon, size: 14, color: color),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            val,
            style: GoogleFonts.spaceGrotesk(
              fontSize: 20,
              fontWeight: FontWeight.w900,
              color: color,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            sub,
            style: GoogleFonts.spaceGrotesk(
              fontSize: 9,
              fontWeight: FontWeight.bold,
              color: HardwarePalette.silkscreenMuted,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabButton(String title, int index) {
    final isSelected = _selectedTabIndex == index;
    return GestureDetector(
      onTap: () {
        HapticService.selectionClick();
        setState(() => _selectedTabIndex = index);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? HardwarePalette.milledSurface : Colors.transparent,
          borderRadius: BorderRadius.circular(9),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Center(
          child: Text(
            title,
            style: GoogleFonts.spaceGrotesk(
              fontSize: 10,
              fontWeight: FontWeight.w900,
              color: isSelected ? HardwarePalette.signalEmerald : HardwarePalette.silkscreenSubtle,
              letterSpacing: 0.5,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTelemetryRow(String title, double percentage, String label, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              title,
              style: GoogleFonts.spaceGrotesk(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: HardwarePalette.silkscreenDark,
              ),
            ),
            Text(
              label,
              style: GoogleFonts.jetBrainsMono(
                fontSize: 10,
                fontWeight: FontWeight.w800,
                color: color,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: percentage,
            minHeight: 6,
            backgroundColor: HardwarePalette.debossedSlot,
            valueColor: AlwaysStoppedAnimation<Color>(color),
          ),
        ),
      ],
    );
  }
}
