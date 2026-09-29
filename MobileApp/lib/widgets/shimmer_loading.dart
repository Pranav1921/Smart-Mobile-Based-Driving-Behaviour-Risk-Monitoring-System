import 'package:flutter/material.dart';
import '../core/theme/neon_theme.dart';

/// A high-performance, dark-theme shimmer effect that sweeps across placeholder widgets.
class TacticalShimmer extends StatefulWidget {
  final Widget child;
  final Duration duration;

  const TacticalShimmer({
    super.key,
    required this.child,
    this.duration = const Duration(milliseconds: 1400),
  });

  @override
  State<TacticalShimmer> createState() => _TacticalShimmerState();
}

class _TacticalShimmerState extends State<TacticalShimmer> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: widget.duration)..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return ShaderMask(
          blendMode: BlendMode.srcATop,
          shaderCallback: (bounds) {
            return LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.white.withOpacity(0.04),
                Colors.white.withOpacity(0.18),
                Colors.white.withOpacity(0.04),
              ],
              stops: const [0.0, 0.5, 1.0],
              transform: _SlidingGradientTransform(slidePercent: _controller.value),
            ).createShader(bounds);
          },
          child: child,
        );
      },
      child: widget.child,
    );
  }
}

class _SlidingGradientTransform extends GradientTransform {
  final double slidePercent;
  const _SlidingGradientTransform({required this.slidePercent});

  @override
  Matrix4? transform(Rect bounds, {TextDirection? textDirection}) {
    return Matrix4.translationValues(bounds.width * (2.0 * slidePercent - 1.0), 0.0, 0.0);
  }
}

/// Loading skeleton box with rounded corners
class ShimmerBox extends StatelessWidget {
  final double width;
  final double height;
  final double borderRadius;

  const ShimmerBox({
    super.key,
    required this.width,
    required this.height,
    this.borderRadius = 8,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: const Color(0xFF161F30),
        borderRadius: BorderRadius.circular(borderRadius),
      ),
    );
  }
}

/// Skeleton for order mission cards during loading/refreshing
class OrderCardSkeleton extends StatelessWidget {
  const OrderCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return TacticalShimmer(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: const Color(0xFF0F172A),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFF1E293B)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: const [
                ShimmerBox(width: 100, height: 16, borderRadius: 6),
                ShimmerBox(width: 70, height: 22, borderRadius: 12),
              ],
            ),
            const SizedBox(height: 14),
            Row(
              children: const [
                ShimmerBox(width: 16, height: 16, borderRadius: 8),
                SizedBox(width: 10),
                Expanded(child: ShimmerBox(width: double.infinity, height: 14, borderRadius: 6)),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: const [
                ShimmerBox(width: 16, height: 16, borderRadius: 8),
                SizedBox(width: 10),
                Expanded(child: ShimmerBox(width: double.infinity, height: 14, borderRadius: 6)),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: const [
                ShimmerBox(width: 120, height: 14, borderRadius: 6),
                ShimmerBox(width: 90, height: 36, borderRadius: 12),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Glowing neon loading spinner with pulse effect
class NeonLoadingIndicator extends StatefulWidget {
  final double size;
  final Color? color;
  final String? message;

  const NeonLoadingIndicator({
    super.key,
    this.size = 36,
    this.color,
    this.message,
  });

  @override
  State<NeonLoadingIndicator> createState() => _NeonLoadingIndicatorState();
}

class _NeonLoadingIndicatorState extends State<NeonLoadingIndicator> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final activeColor = widget.color ?? NeonColors.primaryGreen;

    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: widget.size,
            height: widget.size,
            child: CircularProgressIndicator(
              strokeWidth: 3.2,
              valueColor: AlwaysStoppedAnimation<Color>(activeColor),
              backgroundColor: activeColor.withOpacity(0.15),
            ),
          ),
          if (widget.message != null) ...[
            const SizedBox(height: 14),
            Text(
              widget.message!,
              style: TextStyle(
                color: NeonColors.subtext,
                fontSize: 12,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
