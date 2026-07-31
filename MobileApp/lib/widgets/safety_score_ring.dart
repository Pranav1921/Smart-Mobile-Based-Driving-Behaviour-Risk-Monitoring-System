import 'dart:math';
import 'package:flutter/material.dart';
import '../core/constants/app_colors.dart';

class SafetyScoreRing extends StatefulWidget {
  final double score;
  final double size;
  final double strokeWidth;

  const SafetyScoreRing({
    super.key,
    required this.score,
    this.size = 180.0,
    this.strokeWidth = 14.0,
  });

  @override
  State<SafetyScoreRing> createState() => _SafetyScoreRingState();
}

class _SafetyScoreRingState extends State<SafetyScoreRing> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    _animation = Tween<double>(begin: 0.0, end: widget.score).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
    );
    _controller.forward();
  }

  @override
  void didUpdateWidget(SafetyScoreRing oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.score != widget.score) {
      _animation = Tween<double>(begin: _animation.value, end: widget.score).animate(
        CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
      );
      _controller.reset();
      _controller.forward();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    Color getScoreColor(double score) {
      if (score >= 90) return AppColors.success;
      if (score >= 70) return AppColors.warning;
      return AppColors.error;
    }

    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        final currentVal = _animation.value;
        final color = getScoreColor(currentVal);

        return Stack(
          alignment: Alignment.center,
          children: [
            // Glowing Backdrop Glow
            Container(
              width: widget.size * 0.8,
              height: widget.size * 0.8,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: color.withOpacity(0.08),
                    blurRadius: 40,
                    spreadRadius: 10,
                  ),
                ],
              ),
            ),
            CustomPaint(
              size: Size(widget.size, widget.size),
              painter: _ScoreRingPainter(
                score: currentVal,
                strokeWidth: widget.strokeWidth,
                activeColor: color,
              ),
            ),
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  currentVal.toStringAsFixed(0),
                  style: TextStyle(
                    fontSize: widget.size * 0.26,
                    fontWeight: FontWeight.bold,
                    letterSpacing: -1.0,
                    color: AppColors.textPrimary,
                  ),
                ),
                Text(
                  "SAFETY RATING",
                  style: TextStyle(
                    fontSize: widget.size * 0.065,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.5,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  currentVal >= 90 ? "EXCELLENT" : (currentVal >= 70 ? "STABLE" : "RISKY"),
                  style: TextStyle(
                    fontSize: widget.size * 0.06,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.0,
                    color: color,
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }
}

class _ScoreRingPainter extends CustomPainter {
  final double score;
  final double strokeWidth;
  final Color activeColor;

  _ScoreRingPainter({
    required this.score,
    required this.strokeWidth,
    required this.activeColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - strokeWidth) / 2;

    // 1. Draw track circle
    final trackPaint = Paint()
      ..color = AppColors.border.withOpacity(0.1)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;
    canvas.drawCircle(center, radius, trackPaint);

    // 2. Draw progress arc (Starts from top -90 degrees or -pi/2)
    final progressPaint = Paint()
      ..shader = SweepGradient(
        colors: [
          activeColor.withOpacity(0.4),
          activeColor,
          activeColor,
        ],
        stops: const [0.0, 0.7, 1.0],
        transform: const GradientRotation(-pi / 2),
      ).createShader(Rect.fromCircle(center: center, radius: radius))
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = strokeWidth;

    double sweepAngle = (score / 100.0) * 2 * pi;
    // Limit small sweep angles to avoid rendering full circle when 0
    sweepAngle = sweepAngle.clamp(0.001, 2 * pi - 0.001);

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -pi / 2,
      sweepAngle,
      false,
      progressPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _ScoreRingPainter oldDelegate) {
    return oldDelegate.score != score || oldDelegate.activeColor != activeColor;
  }
}
