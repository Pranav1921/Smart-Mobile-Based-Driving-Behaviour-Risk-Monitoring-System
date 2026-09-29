import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../core/theme/hardware_theme.dart';
import '../services/haptic_service.dart';
import '../services/sound_effect_service.dart';

/// Mechanical Throw Lever that physically scrolls the screen when pulled down or pushed up
class InteractiveScrollLever extends StatefulWidget {
  final ScrollController scrollController;
  final String label;

  const InteractiveScrollLever({
    super.key,
    required this.scrollController,
    this.label = "SCROLL LEVER",
  });

  @override
  State<InteractiveScrollLever> createState() => _InteractiveScrollLeverState();
}

class _InteractiveScrollLeverState extends State<InteractiveScrollLever> {
  double _leverPosition = 0.0; // 0.0 to 1.0
  int _lastDetent = 0;

  @override
  Widget build(BuildContext context) {
    const double trackHeight = 80.0;
    const double handleHeight = 28.0;
    final double maxTravel = trackHeight - handleHeight - 6.0;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: HardwarePalette.milledSurface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: HardwarePalette.matrixBorderLight, width: 1.2),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF23201C).withOpacity(0.04),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.label,
                style: GoogleFonts.jetBrainsMono(
                  fontSize: 9,
                  fontWeight: FontWeight.w800,
                  color: HardwarePalette.silkscreenSubtle,
                  letterSpacing: 1.0,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                _leverPosition > 0.6 ? "PULL: BOTTOM" : (_leverPosition < 0.3 ? "PULL: TOP" : "PULL: MID"),
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: HardwarePalette.silkscreenDark,
                ),
              ),
            ],
          ),
          const SizedBox(width: 14),

          // Vertical Mechanical Lever Slot Track
          GestureDetector(
            onVerticalDragUpdate: (details) {
              setState(() {
                final double currentOffset = _leverPosition * maxTravel;
                final double newOffset = (currentOffset + details.delta.dy).clamp(0.0, maxTravel);
                _leverPosition = newOffset / maxTravel;

                // Ratchet audio feedback
                final int detent = (_leverPosition * 10).floor();
                if (detent != _lastDetent) {
                  _lastDetent = detent;
                  SoundEffectService.playNotchTick();
                  HapticService.lightImpact();
                }

                // Smoothly drive the connected scroll controller
                if (widget.scrollController.hasClients) {
                  final maxScroll = widget.scrollController.position.maxScrollExtent;
                  final targetScroll = _leverPosition * maxScroll;
                  widget.scrollController.jumpTo(targetScroll);
                }
              });
            },
            onVerticalDragEnd: (details) {
              SoundEffectService.playRelayLatch();
              HapticService.mediumImpact();
            },
            child: Container(
              width: 32,
              height: trackHeight,
              decoration: BoxDecoration(
                color: HardwarePalette.debossedSlot,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: HardwarePalette.matrixBorderLight, width: 1.2),
              ),
              child: Stack(
                alignment: Alignment.topCenter,
                children: [
                  // Center recessed slot groove
                  Positioned(
                    top: 6,
                    bottom: 6,
                    width: 6,
                    child: Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFFD4CDC0),
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                  ),

                  // Tactile Knurled Lever Handle
                  Positioned(
                    top: 3 + (_leverPosition * maxTravel),
                    child: Container(
                      width: 26,
                      height: handleHeight,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: HardwarePalette.terracottaRed, width: 1.5),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.12),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              width: 12,
                              height: 2,
                              color: HardwarePalette.terracottaRed,
                            ),
                            const SizedBox(height: 2),
                            Container(
                              width: 12,
                              height: 2,
                              color: HardwarePalette.terracottaRed,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
