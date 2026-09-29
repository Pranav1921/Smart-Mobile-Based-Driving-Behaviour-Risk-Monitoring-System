import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../core/theme/hardware_theme.dart';
import '../services/haptic_service.dart';
import '../services/sound_effect_service.dart';

/// Tactile 2-Position Skeuomorphic Mechanical Lever Switch
class MechanicalLeverSwitch extends StatefulWidget {
  final bool value;
  final ValueChanged<bool> onChanged;
  final String label;
  final String activeLabel;
  final String inactiveLabel;
  final Color activeColor;

  const MechanicalLeverSwitch({
    super.key,
    required this.value,
    required this.onChanged,
    this.label = "POWER RELAY",
    this.activeLabel = "ARMED",
    this.inactiveLabel = "STANDBY",
    this.activeColor = HardwarePalette.signalEmerald,
  });

  @override
  State<MechanicalLeverSwitch> createState() => _MechanicalLeverSwitchState();
}

class _MechanicalLeverSwitchState extends State<MechanicalLeverSwitch> with SingleTickerProviderStateMixin {
  late AnimationController _animCtrl;
  late Animation<double> _leverAngle;

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 260),
    );
    _leverAngle = Tween<double>(
      begin: widget.value ? 0.35 : -0.35,
      end: widget.value ? 0.35 : -0.35,
    ).animate(CurvedAnimation(parent: _animCtrl, curve: Curves.elasticOut));
  }

  @override
  void didUpdateWidget(MechanicalLeverSwitch oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.value != widget.value) {
      _leverAngle = Tween<double>(
        begin: _leverAngle.value,
        end: widget.value ? 0.35 : -0.35,
      ).animate(CurvedAnimation(parent: _animCtrl, curve: Curves.easeOutBack));
      _animCtrl.forward(from: 0.0);
    }
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    super.dispose();
  }

  void _toggle() {
    HapticService.heavyImpact();
    SoundEffectService.playRelayLatch();
    widget.onChanged(!widget.value);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _toggle,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: HardwarePalette.milledSurface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: HardwarePalette.matrixBorderLight, width: 1.2),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Left Label & Engraved Plate
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.label.toUpperCase(),
                  style: GoogleFonts.jetBrainsMono(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.2,
                    color: HardwarePalette.silkscreenSubtle,
                  ),
                ),
                const SizedBox(height: 3),
                Row(
                  children: [
                    Container(
                      width: 7,
                      height: 7,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: widget.value ? widget.activeColor : const Color(0xFFCBD5E1),
                        boxShadow: widget.value
                            ? [
                                BoxShadow(
                                  color: widget.activeColor.withOpacity(0.6),
                                  blurRadius: 6,
                                  spreadRadius: 1,
                                ),
                              ]
                            : [],
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      widget.value ? widget.activeLabel : widget.inactiveLabel,
                      style: GoogleFonts.outfit(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: widget.value ? widget.activeColor : HardwarePalette.silkscreenDark,
                      ),
                    ),
                  ],
                ),
              ],
            ),

            // Right Mechanical Lever Assembly
            Container(
              width: 58,
              height: 32,
              decoration: BoxDecoration(
                color: HardwarePalette.debossedSlot,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: HardwarePalette.matrixBorderLight, width: 1.2),
              ),
              child: AnimatedBuilder(
                animation: _animCtrl,
                builder: (context, child) {
                  return Stack(
                    alignment: Alignment.center,
                    children: [
                      // Lever Slot Track
                      Positioned(
                        left: 4,
                        right: 4,
                        height: 6,
                        child: Container(
                          decoration: BoxDecoration(
                            color: const Color(0xFFD1D5DB),
                            borderRadius: BorderRadius.circular(3),
                          ),
                        ),
                      ),

                      // Sliding Milled Lever Handle
                      AnimatedAlign(
                        duration: const Duration(milliseconds: 200),
                        curve: Curves.easeInOut,
                        alignment: widget.value ? Alignment.centerRight : Alignment.centerLeft,
                        child: Container(
                          width: 26,
                          height: 26,
                          margin: const EdgeInsets.symmetric(horizontal: 3),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: widget.value ? widget.activeColor : Colors.white,
                            border: Border.all(
                              color: widget.value ? widget.activeColor : const Color(0xFF94A3B8),
                              width: 1.5,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.12),
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Center(
                            child: Container(
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: widget.value ? Colors.white : const Color(0xFF64748B),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
