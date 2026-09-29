import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../core/theme/neon_theme.dart';
import '../core/theme/framer_motion.dart';
import '../providers/trip_provider.dart';

class EarningsScreen extends StatefulWidget {
  const EarningsScreen({super.key});

  @override
  State<EarningsScreen> createState() => _EarningsScreenState();
}

class _EarningsScreenState extends State<EarningsScreen> {
  int _selectedWeek = 3;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: NeonColors.background,
      appBar: AppBar(
        backgroundColor: NeonColors.card,
        elevation: 0,
        toolbarHeight: 56,
        leading: IconButton(
          icon: Icon(Icons.chevron_left_rounded, color: NeonColors.text, size: 28),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          "Monthly Report & Analytics",
          style: GoogleFonts.outfit(color: NeonColors.text, fontSize: 16, fontWeight: FontWeight.w800),
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: NeonColors.primaryGreen.withOpacity(0.12),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: NeonColors.primaryGreen.withOpacity(0.3)),
            ),
            child: Row(
              children: [
                const Icon(Icons.calendar_month_rounded, color: NeonColors.primaryGreen, size: 13),
                const SizedBox(width: 4),
                Text(
                  "Monthly Audit",
                  style: GoogleFonts.spaceGrotesk(color: NeonColors.primaryGreen, fontSize: 11, fontWeight: FontWeight.w800),
                ),
              ],
            ),
          ),
        ],
      ),
      body: Consumer<TripProvider>(
        builder: (context, trip, child) {
          final summary = trip.monthlyReportSummary;
          final weeklyScores = List<double>.from(summary['weeklyScores'] ?? [85.0, 88.0, 92.0, 90.0]);
          final weeklyHours = List<double>.from(summary['weeklyActivityHours'] ?? [4.0, 5.0, 6.0, 5.5, 7.0, 6.5, 4.5]);
          final rulesBreakdown = Map<String, int>.from(summary['rulesBreakdown'] ?? {});
          final totalRulesBroken = summary['totalRulesBroken'] ?? 0;

          return ListView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(18, 16, 18, 120),
            children: [
              _buildMonthlyScorecard(trip, summary).framerSlideIn(delayMs: 20),
              const SizedBox(height: 16),
              _buildWeeklySafetyTrendChart(weeklyScores).framerSlideIn(delayMs: 40),
              const SizedBox(height: 16),
              _buildBehavioralCategoryMeters(trip).framerSlideIn(delayMs: 60),
              const SizedBox(height: 16),
              _buildRulesAuditSection(totalRulesBroken, rulesBreakdown).framerSlideIn(delayMs: 80),
              const SizedBox(height: 16),
              _buildActivityHistogram(weeklyHours).framerSlideIn(delayMs: 100),
              const SizedBox(height: 16),
              _buildMonthlyTripsList(trip).framerSlideIn(delayMs: 120),
            ],
          );
        },
      ),
    );
  }

  Widget _buildMonthlyScorecard(TripProvider trip, Map<String, dynamic> summary) {
    final double avgScore = summary['averageSafetyScore'] ?? 92.0;
    final int tripsCount = summary['totalTrips'] ?? 0;
    final double distanceKm = summary['totalDistanceKm'] ?? 0.0;
    final double earnings = trip.totalIncome;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF0F172A), Color(0xFF1E293B)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: NeonColors.primaryGreen.withOpacity(0.3), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.25),
            blurRadius: 16,
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
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Monthly Performance Rating", style: GoogleFonts.spaceGrotesk(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Text("${avgScore.toStringAsFixed(0)}%", style: GoogleFonts.outfit(color: NeonColors.primaryGreen, fontSize: 26, fontWeight: FontWeight.w900)),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: NeonColors.primaryGreen.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          summary['safetyClassification'] ?? "Gold Tier",
                          style: GoogleFonts.spaceGrotesk(color: NeonColors.primaryGreen, fontSize: 10.5, fontWeight: FontWeight.w800),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: NeonColors.primaryGreen.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: NeonColors.primaryGreen.withOpacity(0.3)),
                ),
                child: const Icon(Icons.analytics_rounded, color: NeonColors.primaryGreen, size: 28),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(height: 1, color: Colors.white10),
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _metricItem("Gross Payout", "₹${earnings.toStringAsFixed(0)}", NeonColors.primaryGreen),
              _metricItem("Total Distance", "${distanceKm.toStringAsFixed(1)} KM", const Color(0xFF38BDF8)),
              _metricItem("Missions", "$tripsCount Completed", const Color(0xFFA78BFA)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _metricItem(String label, String value, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: GoogleFonts.spaceGrotesk(color: Colors.white38, fontSize: 10, fontWeight: FontWeight.w700)),
        const SizedBox(height: 3),
        Text(value, style: GoogleFonts.outfit(color: color, fontSize: 14.5, fontWeight: FontWeight.w900)),
      ],
    );
  }

  Widget _buildWeeklySafetyTrendChart(List<double> scores) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: NeonColors.card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: NeonColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text("Weekly Safety Score Trend", style: GoogleFonts.outfit(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w800)),
              Text("Target: 85%+", style: GoogleFonts.spaceGrotesk(color: NeonColors.primaryGreen, fontSize: 11, fontWeight: FontWeight.w800)),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 140,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: List.generate(scores.length, (index) {
                final score = scores[index];
                final isSelected = _selectedWeek == index;
                final col = score >= 85 ? const Color(0xFFE05252) : (score >= 75 ? const Color(0xFFF59E0B) : const Color(0xFFEF4444));
                final barHeight = (score / 100) * 95;

                return GestureDetector(
                  onTap: () => setState(() => _selectedWeek = index),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Text(
                        "${score.toStringAsFixed(0)}%",
                        style: GoogleFonts.spaceGrotesk(
                          color: isSelected ? Colors.white : Colors.white54,
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 6),
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 350),
                        width: 44,
                        height: barHeight,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [col.withOpacity(isSelected ? 0.9 : 0.6), col],
                            begin: Alignment.bottomCenter,
                            end: Alignment.topCenter,
                          ),
                          borderRadius: BorderRadius.circular(10),
                          border: isSelected ? Border.all(color: Colors.white, width: 1.5) : null,
                          boxShadow: isSelected
                              ? [BoxShadow(color: col.withOpacity(0.4), blurRadius: 10, offset: const Offset(0, 2))]
                              : null,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        "Week ${index + 1}",
                        style: GoogleFonts.spaceGrotesk(
                          color: isSelected ? NeonColors.primaryGreen : Colors.white38,
                          fontSize: 11,
                          fontWeight: isSelected ? FontWeight.w900 : FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBehavioralCategoryMeters(TripProvider trip) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: NeonColors.card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: NeonColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("Behavioral Compliance Index", style: GoogleFonts.outfit(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w800)),
          const SizedBox(height: 14),
          _categoryBar("Speed Consistency", trip.speedConsistencyPct, const Color(0xFF38BDF8), Icons.speed_rounded),
          const SizedBox(height: 12),
          _categoryBar("Braking Smoothness", trip.brakingSmoothnessPct, const Color(0xFFE05252), Icons.pan_tool_rounded),
          const SizedBox(height: 12),
          _categoryBar("Cornering & Swerve Safety", trip.corneringSafetyPct, const Color(0xFFA78BFA), Icons.turn_right_rounded),
          const SizedBox(height: 12),
          _categoryBar("School & Hazard Zone Compliance", trip.zoneAdherencePct, const Color(0xFFF59E0B), Icons.school_rounded),
        ],
      ),
    );
  }

  Widget _categoryBar(String label, double pct, Color color, IconData icon) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Icon(icon, color: color, size: 14),
                const SizedBox(width: 6),
                Text(label, style: GoogleFonts.plusJakartaSans(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w600)),
              ],
            ),
            Text("${pct.toStringAsFixed(0)}%", style: GoogleFonts.spaceGrotesk(color: color, fontSize: 12, fontWeight: FontWeight.w800)),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: Stack(
            children: [
              Container(height: 7, color: Colors.white.withOpacity(0.06)),
              FractionallySizedBox(
                widthFactor: (pct / 100).clamp(0.0, 1.0),
                child: Container(
                  height: 7,
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildRulesAuditSection(int totalBroken, Map<String, int> breakdown) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: NeonColors.card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: totalBroken > 0 ? const Color(0xFFEF4444).withOpacity(0.3) : const Color(0xFF10B981).withOpacity(0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text("Rules & Road Safety Audit", style: GoogleFonts.outfit(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w800)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: (totalBroken > 0 ? const Color(0xFFEF4444) : const Color(0xFF10B981)).withOpacity(0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  "$totalBroken Broken Rules",
                  style: GoogleFonts.spaceGrotesk(
                    color: totalBroken > 0 ? const Color(0xFFEF4444) : const Color(0xFF10B981),
                    fontSize: 10.5,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: breakdown.entries.map((e) {
              final isZero = e.value == 0;
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                decoration: BoxDecoration(
                  color: isZero ? Colors.white.withOpacity(0.03) : const Color(0xFFEF4444).withOpacity(0.12),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: isZero ? Colors.white10 : const Color(0xFFEF4444).withOpacity(0.3)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(e.key, style: GoogleFonts.plusJakartaSans(color: Colors.white70, fontSize: 11.5, fontWeight: FontWeight.w600)),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: isZero ? Colors.white12 : const Color(0xFFEF4444),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        "${e.value}",
                        style: GoogleFonts.spaceGrotesk(color: Colors.white, fontSize: 10.5, fontWeight: FontWeight.w900),
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildActivityHistogram(List<double> hours) {
    const days = ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"];

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: NeonColors.card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: NeonColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text("Driving Activity Hours", style: GoogleFonts.outfit(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w800)),
              Text("Avg: 5.2 hrs/day", style: GoogleFonts.spaceGrotesk(color: const Color(0xFF38BDF8), fontSize: 11, fontWeight: FontWeight.w700)),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 110,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: List.generate(hours.length, (index) {
                final h = hours[index];
                const maxH = 8.0;
                final barHeight = (h / maxH) * 75;

                return Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Text("${h.toStringAsFixed(1)}h", style: GoogleFonts.spaceGrotesk(color: Colors.white38, fontSize: 9)),
                    const SizedBox(height: 4),
                    Container(
                      width: 24,
                      height: barHeight,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF38BDF8), Color(0xFF818CF8)],
                          begin: Alignment.bottomCenter,
                          end: Alignment.topCenter,
                        ),
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(days[index], style: GoogleFonts.spaceGrotesk(color: Colors.white60, fontSize: 10, fontWeight: FontWeight.w600)),
                  ],
                );
              }),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMonthlyTripsList(TripProvider trip) {
    if (trip.history.isEmpty) {
      return const SizedBox();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("Recent Month Missions", style: GoogleFonts.outfit(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w800)),
        const SizedBox(height: 10),
        ...trip.history.take(4).map((t) {
          final payout = t.distanceKm > 0 ? (t.distanceKm * 15.0) : 75.0;
          return Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: NeonColors.card,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: NeonColors.border),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF10B981).withOpacity(0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.check_circle_outline_rounded, color: Color(0xFF10B981), size: 18),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(t.deliveryTo ?? "Delivery Destination", style: GoogleFonts.plusJakartaSans(color: Colors.white, fontSize: 12.5, fontWeight: FontWeight.w700), maxLines: 1),
                      const SizedBox(height: 2),
                      Text("${t.distanceKm.toStringAsFixed(1)} KM · ${t.durationSeconds ~/ 60} mins", style: GoogleFonts.spaceGrotesk(color: Colors.white38, fontSize: 10.5)),
                    ],
                  ),
                ),
                Text("+ ₹${payout.toStringAsFixed(0)}", style: GoogleFonts.outfit(color: NeonColors.primaryGreen, fontSize: 14, fontWeight: FontWeight.w900)),
              ],
            ),
          );
        }),
      ],
    );
  }
}
