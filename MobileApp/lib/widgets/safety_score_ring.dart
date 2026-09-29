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
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        final currentVal = _animation.value;

        return Stack(
          alignment: Alignment.center,
          children: [
            // Soft Radial Background Glow
            Container(
              width: widget.size * 0.75,
              height: widget.size * 0.75,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    const Color(0xFF284A3B).withOpacity(0.08),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
            CustomPaint(
              size: Size(widget.size, widget.size),
              painter: _ScoreRingPainter(
                score: currentVal,
              ),
            ),
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  currentVal.toStringAsFixed(1),
                  style: TextStyle(
                    fontSize: widget.size * 0.25,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -1.5,
                    color: const Color(0xFF1C3B2B),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  "Safety Score",
                  style: TextStyle(
                    fontSize: widget.size * 0.07,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.2,
                    color: const Color(0xFF233229),
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

  _ScoreRingPainter({
    required this.score,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final startAngle = 135 * (pi / 180); // Bottom left (135 deg)
    final sweepAngle = 270 * (pi / 180); // 270 deg total arc

    // 1. Outer Neumorphic Beige Track Arc
    final outerRadius = (size.width - 24) / 2;
    final outerTrackPaint = Paint()
      ..color = const Color(0xFFE4DACB)
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 16.0;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: outerRadius),
      startAngle,
      sweepAngle,
      false,
      outerTrackPaint,
    );

    // 2. Outer Track Border Highlights (Bevel effect)
    final outerHighlightPaint = Paint()
      ..color = Colors.white.withOpacity(0.6)
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 2.0;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: outerRadius + 8),
      startAngle,
      sweepAngle,
      false,
      outerHighlightPaint,
    );

    // 3. Knob/Thumb indicator on Outer Track
    final knobProgressAngle = startAngle + (sweepAngle * 0.72); // ~45 deg position
    final knobX = center.dx + outerRadius * cos(knobProgressAngle);
    final knobY = center.dy + outerRadius * sin(knobProgressAngle);

    final knobOuterPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(knobX, knobY), 8.0, knobOuterPaint);

    final knobInnerPaint = Paint()
      ..color = const Color(0xFFE4DACB)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(knobX, knobY), 5.0, knobInnerPaint);

    // 4. Inner Dark Forest Green Score Arc
    final innerRadius = outerRadius - 16;
    final innerArcPaint = Paint()
      ..color = const Color(0xFF284A3B)
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 7.0;

    double activeSweepAngle = sweepAngle * (score / 100.0).clamp(0.0, 1.0);
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: innerRadius),
      startAngle,
      activeSweepAngle,
      false,
      innerArcPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _ScoreRingPainter oldDelegate) {
    return oldDelegate.score != score;
  }
}
