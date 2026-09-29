import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mobile_app/core/theme/neon_theme.dart';
import 'package:mobile_app/core/theme/framer_motion.dart';

class LiveVehicleCruiser extends StatefulWidget {
  final bool isLive;
  final Duration elapsed;
  final double currentSpeed;
  final VoidCallback onToggle;

  const LiveVehicleCruiser({
    super.key,
    required this.isLive,
    required this.elapsed,
    required this.currentSpeed,
    required this.onToggle,
  });

  @override
  State<LiveVehicleCruiser> createState() => _LiveVehicleCruiserState();
}

class _LiveVehicleCruiserState extends State<LiveVehicleCruiser> with SingleTickerProviderStateMixin {
  late AnimationController _roadCtrl;

  @override
  void initState() {
    super.initState();
    _roadCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    )..repeat();
  }

  @override
  void dispose() {
    _roadCtrl.dispose();
    super.dispose();
  }

  String _formatDuration(Duration d) {
    final hours = d.inHours;
    final minutes = d.inMinutes.remainder(60);
    final seconds = d.inSeconds.remainder(60);
    if (hours > 0) {
      return "${hours}h ${minutes}m ${seconds}s";
    }
    return "${minutes}m ${seconds}s";
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.isLive) {
      // Offline / Standby State with Start CTA
      return Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: NeonColors.primaryGreen,
          borderRadius: BorderRadius.circular(22),
          boxShadow: [
            BoxShadow(
              color: NeonColors.primaryGreen.withOpacity(0.3),
              blurRadius: 18,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(22),
            onTap: widget.onToggle,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.power_settings_new_rounded, color: Colors.white, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Go Online",
                          style: GoogleFonts.outfit(
                            fontSize: 17,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          "Start vehicle live telemetry",
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                            color: Colors.white.withOpacity(0.85),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          "START",
                          style: GoogleFonts.spaceGrotesk(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w900,
                            color: Colors.black,
                          ),
                        ),
                        const SizedBox(width: 4),
                        const Icon(Icons.arrow_forward_rounded, color: Colors.black, size: 13),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    // Live Active Cruising Vehicle View
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: const Color(0xFF0D1117),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: NeonColors.primaryGreen.withOpacity(0.4), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: NeonColors.primaryGreen.withOpacity(0.12),
            blurRadius: 20,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          // Live Vehicle Simulation Viewport
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            child: SizedBox(
              height: 110,
              width: double.infinity,
              child: Stack(
                children: [
                  // Animated Road & Passing Dashes
                  Positioned.fill(
                    child: AnimatedBuilder(
                      animation: _roadCtrl,
                      builder: (context, child) {
                        return CustomPaint(
                          painter: _LiveRoadPainter(progress: _roadCtrl.value),
                        );
                      },
                    ),
                  ),

                  // Cruising Animated Vehicle
                  Positioned(
                    left: 24,
                    top: 20,
                    child: AnimatedBuilder(
                      animation: _roadCtrl,
                      builder: (context, child) {
                        // Subtle vertical bobbing to simulate driving suspension
                        final bob = math.sin(_roadCtrl.value * 2 * math.pi) * 1.5;
                        return Transform.translate(
                          offset: Offset(0, bob),
                          child: Stack(
                            alignment: Alignment.centerLeft,
                            children: [
                              // Headlight Beams
                              CustomPaint(
                                size: const Size(180, 50),
                                painter: _CruiserHeadlightPainter(),
                              ),

                              // Vehicle Body
                              Container(
                                width: 72,
                                height: 38,
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    colors: [Color(0xFF1E293B), Color(0xFF0F172A)],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(
                                    color: NeonColors.primaryGreen.withOpacity(0.8),
                                    width: 1.5,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: NeonColors.primaryGreen.withOpacity(0.3),
                                      blurRadius: 10,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: Stack(
                                  children: [
                                    // Windshield
                                    Positioned(
                                      top: 6,
                                      right: 12,
                                      child: Container(
                                        width: 22,
                                        height: 14,
                                        decoration: BoxDecoration(
                                          color: const Color(0xFF38BDF8).withOpacity(0.3),
                                          borderRadius: BorderRadius.circular(4),
                                          border: Border.all(color: const Color(0xFF38BDF8).withOpacity(0.6)),
                                        ),
                                      ),
                                    ),
                                    // Front Headlight Bulb
                                    Positioned(
                                      right: 2,
                                      top: 14,
                                      child: Container(
                                        width: 4,
                                        height: 8,
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFFDE047),
                                          borderRadius: BorderRadius.circular(2),
                                          boxShadow: const [BoxShadow(color: Color(0xFFFDE047), blurRadius: 6)],
                                        ),
                                      ),
                                    ),
                                    // Tail Light Bulb
                                    Positioned(
                                      left: 2,
                                      top: 14,
                                      child: Container(
                                        width: 3,
                                        height: 8,
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFEF4444),
                                          borderRadius: BorderRadius.circular(2),
                                          boxShadow: const [BoxShadow(color: Color(0xFFEF4444), blurRadius: 6)],
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),

                  // Floating Speed Pill
                  Positioned(
                    right: 20,
                    top: 20,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0F172A).withOpacity(0.85),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: NeonColors.primaryGreen.withOpacity(0.3)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 6,
                            height: 6,
                            decoration: const BoxDecoration(
                              color: NeonColors.primaryGreen,
                              shape: BoxShape.circle,
                              boxShadow: [BoxShadow(color: NeonColors.primaryGreen, blurRadius: 4)],
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            "${widget.currentSpeed.toStringAsFixed(0)} KM/H",
                            style: GoogleFonts.spaceGrotesk(
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                              color: NeonColors.primaryGreen,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Bottom Control & Duration Bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
            decoration: BoxDecoration(
              color: const Color(0xFF161B22),
              borderRadius: const BorderRadius.vertical(bottom: Radius.circular(24)),
              border: Border(top: BorderSide(color: Colors.white.withOpacity(0.06))),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.sensors_rounded, color: NeonColors.primaryGreen, size: 14),
                          const SizedBox(width: 4),
                          Text(
                            "LIVE ON DUTY",
                            style: GoogleFonts.spaceGrotesk(
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              color: NeonColors.primaryGreen,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        "Duration: ${_formatDuration(widget.elapsed)}",
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: NeonColors.subtext,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                FramerPressable(
                  onTap: widget.onToggle,
                  scaleFactor: 0.94,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEF4444).withOpacity(0.15),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0xFFEF4444).withOpacity(0.4)),
                    ),
                    child: Text(
                      "END SHIFT",
                      style: GoogleFonts.spaceGrotesk(
                        fontSize: 11,
                        fontWeight: FontWeight.w900,
                        color: const Color(0xFFEF4444),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _LiveRoadPainter extends CustomPainter {
  final double progress;
  _LiveRoadPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    // Road surface
    final roadPaint = Paint()..color = const Color(0xFF0F172A);
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), roadPaint);

    // Grid lines (horizontal moving towards left to simulate forward speed)
    final linePaint = Paint()
      ..color = NeonColors.primaryGreen.withOpacity(0.15)
      ..strokeWidth = 1.0;

    // Top & Bottom Road Borders
    canvas.drawLine(Offset(0, size.height * 0.15), Offset(size.width, size.height * 0.15), linePaint);
    canvas.drawLine(Offset(0, size.height * 0.85), Offset(size.width, size.height * 0.85), linePaint);

    // Moving Center Lane Dashes
    final dashPaint = Paint()
      ..color = const Color(0xFFFDE047).withOpacity(0.5)
      ..strokeWidth = 2.5;

    const dashWidth = 24.0;
    const dashGap = 20.0;
    final totalSpan = dashWidth + dashGap;
    final offset = (progress * totalSpan);

    for (double x = -totalSpan; x < size.width + totalSpan; x += totalSpan) {
      final startX = x - offset;
      canvas.drawLine(
        Offset(startX, size.height * 0.5),
        Offset(startX + dashWidth, size.height * 0.5),
        dashPaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _LiveRoadPainter oldDelegate) => true;
}

class _CruiserHeadlightPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final lightPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.centerLeft,
        end: Alignment.centerRight,
        colors: [
          const Color(0xFFFDE047).withOpacity(0.35),
          const Color(0xFFFDE047).withOpacity(0.0),
        ],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    final beam = Path()
      ..moveTo(68, size.height * 0.5)
      ..lineTo(size.width, size.height * 0.15)
      ..lineTo(size.width, size.height * 0.85)
      ..close();

    canvas.drawPath(beam, lightPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
