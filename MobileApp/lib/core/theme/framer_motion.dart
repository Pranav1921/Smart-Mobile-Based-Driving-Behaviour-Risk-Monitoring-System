import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

/// Framer Motion UI Helper for rich, fluid micro-interactions
class FramerMotion {
  FramerMotion._();

  /// Standard Framer spring curve for natural gesture and entry feel
  static const Curve springCurve = Curves.easeOutCubic;
  static const Duration fast = Duration(milliseconds: 250);
  static const Duration normal = Duration(milliseconds: 400);
  static const Duration slow = Duration(milliseconds: 600);
}

/// A pressable widget that scales down smoothly on tap and springs back (like Framer Motion `whileTap={{ scale: 0.97 }}`)
class FramerPressable extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final double scaleFactor;
  final Duration duration;
  final BorderRadius? borderRadius;

  const FramerPressable({
    super.key,
    required this.child,
    this.onTap,
    this.scaleFactor = 0.96,
    this.duration = const Duration(milliseconds: 140),
    this.borderRadius,
  });

  @override
  State<FramerPressable> createState() => _FramerPressableState();
}

class _FramerPressableState extends State<FramerPressable> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
      reverseDuration: widget.duration,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: widget.scaleFactor).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOutCubic),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onTapDown(TapDownDetails details) {
    if (widget.onTap != null) _controller.forward();
  }

  void _onTapUp(TapUpDetails details) {
    if (widget.onTap != null) _controller.reverse();
  }

  void _onTapCancel() {
    if (widget.onTap != null) _controller.reverse();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: _onTapDown,
      onTapUp: _onTapUp,
      onTapCancel: _onTapCancel,
      onTap: widget.onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) => Transform.scale(
          scale: _scaleAnimation.value,
          child: child,
        ),
        child: widget.child,
      ),
    );
  }
}

/// Extension for easy Framer-style animations on any widget
extension FramerAnimationExtensions on Widget {
  /// Framer-style staggered fade in + slide up
  Widget framerSlideIn({int delayMs = 0, double offsetY = 0.15, Duration duration = const Duration(milliseconds: 450)}) {
    return animate(delay: delayMs.ms)
        .fadeIn(duration: duration, curve: Curves.easeOutCubic)
        .slideY(begin: offsetY, end: 0, duration: duration, curve: Curves.easeOutCubic);
  }

  /// Framer-style pop entry (scale + fade)
  Widget framerPop({int delayMs = 0, Duration duration = const Duration(milliseconds: 350)}) {
    return animate(delay: delayMs.ms)
        .fadeIn(duration: duration, curve: Curves.easeOut)
        .scale(begin: const Offset(0.92, 0.92), end: const Offset(1, 1), duration: duration, curve: Curves.easeOutBack);
  }

  /// Framer pulse / breathing effect
  Widget framerPulse({Duration duration = const Duration(seconds: 2)}) {
    return animate(onPlay: (controller) => controller.repeat(reverse: true))
        .scale(begin: const Offset(0.98, 0.98), end: const Offset(1.02, 1.02), duration: duration, curve: Curves.easeInOut);
  }

  /// Subtle glowing shimmer pulse
  Widget framerGlow({Duration duration = const Duration(milliseconds: 1800)}) {
    return animate(onPlay: (controller) => controller.repeat(reverse: true))
        .fade(begin: 0.85, end: 1.0, duration: duration, curve: Curves.easeInOut);
  }
}

