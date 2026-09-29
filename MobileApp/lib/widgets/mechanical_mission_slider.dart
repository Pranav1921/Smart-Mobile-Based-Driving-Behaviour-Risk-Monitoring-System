import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../core/theme/hardware_theme.dart';
import '../services/haptic_service.dart';
import '../services/sound_effect_service.dart';

/// Smooth, modern swipe-to-accept button with effortless halfway (40%) trigger.
/// Replaces the old lever with a clean, centered, full-width swipeable slider.
class MechanicalMissionSlider extends StatefulWidget {
  final String label;
  final String completedLabel;
  final Future<void> Function() onAction;
  final Color accentColor;
  final IconData icon;
  final double? width;
  final double height;

  const MechanicalMissionSlider({
    super.key,
    this.label = "SWIPE TO ACCEPT",
    this.completedLabel = "ORDER ACCEPTED",
    required this.onAction,
    this.accentColor = const Color(0xFFFF5722),
    this.icon = Icons.arrow_forward_rounded,
    this.width,
    this.height = 48.0,
  });

  @override
  State<MechanicalMissionSlider> createState() => _MechanicalMissionSliderState();
}

class _MechanicalMissionSliderState extends State<MechanicalMissionSlider> with SingleTickerProviderStateMixin {
  double _dragPosition = 0.0;
  bool _isProcessing = false;
  bool _isCompleted = false;

  late AnimationController _animController;
  Animation<double>? _slideAnimation;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 240),
    );
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  void _animateToCompletion(double maxDrag) {
    if (_isProcessing || _isCompleted) return;

    _slideAnimation = Tween<double>(begin: _dragPosition, end: maxDrag).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeOutCubic),
    )..addListener(() {
        if (mounted) {
          setState(() {
            _dragPosition = _slideAnimation!.value;
          });
        }
      });

    _animController.reset();
    _animController.forward().then((_) async {
      if (!mounted) return;
      setState(() {
        _isProcessing = true;
      });

      SoundEffectService.playRelayLatch(isEngage: true);
      HapticService.heavyImpact();

      try {
        await widget.onAction();
      } finally {
        if (mounted) {
          setState(() {
            _isProcessing = false;
            _isCompleted = true;
          });
        }
      }
    });
  }

  void _animateToStart() {
    if (_isProcessing || _isCompleted) return;

    _slideAnimation = Tween<double>(begin: _dragPosition, end: 0.0).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeOutCubic),
    )..addListener(() {
        if (mounted) {
          setState(() {
            _dragPosition = _slideAnimation!.value;
          });
        }
      });

    _animController.reset();
    _animController.forward().then((_) {
      SoundEffectService.playNotchTick();
      HapticService.lightImpact();
    });
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final double totalWidth = widget.width ?? constraints.maxWidth;
        final double thumbSize = widget.height - 8.0;
        final double maxDrag = math.max(0.0, totalWidth - thumbSize - 8.0);
        final double progress = maxDrag > 0 ? (_dragPosition / maxDrag).clamp(0.0, 1.0) : 0.0;

        return GestureDetector(
          // Wrap the entire widget so drags/taps anywhere on the button work smoothly
          behavior: HitTestBehavior.opaque,
          onTap: () {
            if (!_isProcessing && !_isCompleted) {
              _animateToCompletion(maxDrag);
            }
          },
          onHorizontalDragStart: (details) {
            if (_isProcessing || _isCompleted) return;
            if (_animController.isAnimating) _animController.stop();
          },
          onHorizontalDragUpdate: (details) {
            if (_isProcessing || _isCompleted) return;
            setState(() {
              _dragPosition = (_dragPosition + details.delta.dx).clamp(0.0, maxDrag);
            });
            // Haptic tick at 40% milestone
            if ((progress >= 0.38 && progress <= 0.44)) {
              HapticService.selectionClick();
            }
          },
          onHorizontalDragEnd: (details) {
            if (_isProcessing || _isCompleted) return;
            final velocity = details.primaryVelocity ?? 0.0;

            // Trigger if dragged halfway (>= 40%) OR swiped with forward flick velocity
            if (_dragPosition >= (maxDrag * 0.40) || velocity > 100.0) {
              _animateToCompletion(maxDrag);
            } else {
              _animateToStart();
            }
          },
          child: Container(
            width: widget.width ?? double.infinity,
            height: widget.height,
            decoration: BoxDecoration(
              color: const Color(0xFF1E232A),
              borderRadius: BorderRadius.circular(widget.height / 2),
              border: Border.all(
                color: _isCompleted
                    ? widget.accentColor
                    : progress > 0.35
                        ? widget.accentColor.withOpacity(0.7)
                        : const Color(0xFF333B47),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.18),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
                if (progress > 0.1 || _isCompleted)
                  BoxShadow(
                    color: widget.accentColor.withOpacity(0.25 * progress),
                    blurRadius: 12,
                    spreadRadius: 1,
                  ),
              ],
            ),
            child: Stack(
              alignment: Alignment.centerLeft,
              children: [
                // 1. Color Fill following the thumb
                Positioned(
                  left: 0,
                  top: 0,
                  bottom: 0,
                  width: _isCompleted ? totalWidth : (_dragPosition + thumbSize + 4.0),
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          widget.accentColor.withOpacity(0.25),
                          widget.accentColor.withOpacity(0.65),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(widget.height / 2),
                    ),
                  ),
                ),

                // 2. Centered Text Prompt
                Center(
                  child: AnimatedOpacity(
                    duration: const Duration(milliseconds: 120),
                    opacity: _isCompleted
                        ? 1.0
                        : (1.0 - progress * 1.6).clamp(0.0, 1.0),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (!_isCompleted && !_isProcessing) ...[
                          Text(
                            progress > 0.35 ? "RELEASE TO ACCEPT" : widget.label.toUpperCase(),
                            style: GoogleFonts.outfit(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w700,
                              color: progress > 0.35 ? Colors.white : const Color(0xFF94A3B8),
                              letterSpacing: 1.2,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Icon(
                            Icons.keyboard_double_arrow_right_rounded,
                            color: progress > 0.35 ? widget.accentColor : const Color(0xFF64748B),
                            size: 16,
                          ),
                        ] else if (_isProcessing) ...[
                          SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: widget.accentColor,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            "ACCEPTING...",
                            style: GoogleFonts.outfit(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                              letterSpacing: 1.0,
                            ),
                          ),
                        ] else ...[
                          const Icon(Icons.check_circle_rounded, color: Colors.white, size: 18),
                          const SizedBox(width: 6),
                          Text(
                            widget.completedLabel.toUpperCase(),
                            style: GoogleFonts.outfit(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                              letterSpacing: 1.2,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),

                // 3. Modern Circular Swipe Thumb
                Positioned(
                  left: 4.0 + _dragPosition,
                  child: Container(
                    width: thumbSize,
                    height: thumbSize,
                    decoration: BoxDecoration(
                      color: _isCompleted ? widget.accentColor : Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.28),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                        if (progress > 0.2)
                          BoxShadow(
                            color: widget.accentColor.withOpacity(0.5),
                            blurRadius: 10,
                            spreadRadius: 1,
                          ),
                      ],
                    ),
                    child: Center(
                      child: Icon(
                        _isCompleted ? Icons.check_rounded : widget.icon,
                        color: _isCompleted ? Colors.white : widget.accentColor,
                        size: 22,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
