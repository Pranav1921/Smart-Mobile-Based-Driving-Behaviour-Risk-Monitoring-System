import 'package:flutter/material.dart';

/// Mechanical Motion & Spring Easing System (Zero-start, non-fluid physics)
class MechanicalEasing {
  MechanicalEasing._();

  /// Zero-start cubic curve for immediate non-linear trigger actuation
  static const Cubic snappyZeroStart = Cubic(0.0, 0.0, 0.15, 1.0);

  /// Spring-loaded mechanical switch toggle curve with overshoot
  static const Cubic springSwitch = Cubic(0.0, 0.95, 0.08, 1.18);

  /// Snappy elastic spring curve for mechanical return & detent release
  static const Curve elasticSnap = Curves.elasticOut;

  /// Fast mechanical duration
  static const Duration clickDuration = Duration(milliseconds: 70);
  static const Duration springReturn = Duration(milliseconds: 380);
}

/// A tactile spring-loaded mechanical pressable widget with zero-start displacement
class MechanicalPressable extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final double depressOffset;
  final Duration pressDuration;
  final Duration releaseDuration;

  const MechanicalPressable({
    super.key,
    required this.child,
    this.onTap,
    this.depressOffset = 2.0, // 2px tactile down-step
    this.pressDuration = MechanicalEasing.clickDuration,
    this.releaseDuration = const Duration(milliseconds: 180),
  });

  @override
  State<MechanicalPressable> createState() => _MechanicalPressableState();
}

class _MechanicalPressableState extends State<MechanicalPressable> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _offsetAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.pressDuration,
      reverseDuration: widget.releaseDuration,
    );
    _offsetAnimation = Tween<double>(begin: 0.0, end: widget.depressOffset).animate(
      CurvedAnimation(
        parent: _controller,
        curve: MechanicalEasing.snappyZeroStart,
        reverseCurve: MechanicalEasing.springSwitch,
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleTapDown(TapDownDetails _) {
    if (widget.onTap != null) _controller.forward();
  }

  void _handleTapUp(TapUpDetails _) {
    if (widget.onTap != null) {
      _controller.reverse();
      widget.onTap!();
    }
  }

  void _handleTapCancel() {
    if (widget.onTap != null) _controller.reverse();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: _handleTapDown,
      onTapUp: _handleTapUp,
      onTapCancel: _handleTapCancel,
      behavior: HitTestBehavior.opaque,
      child: AnimatedBuilder(
        animation: _offsetAnimation,
        builder: (context, child) => Transform.translate(
          offset: Offset(0, _offsetAnimation.value),
          child: child,
        ),
        child: widget.child,
      ),
    );
  }
}
