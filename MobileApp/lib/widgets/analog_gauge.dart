import 'dart:math';
import 'package:flutter/material.dart';
import 'package:mobile_app/core/theme/neon_theme.dart';

class AnalogGauge extends StatelessWidget {
  final double value;
  final double max;
  final String unit;
  final Color color;

  const AnalogGauge({super.key, required this.value, required this.max, required this.unit, this.color = NeonColors.accent});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 140,
      height: 140,
      decoration: NeonTheme.brutalCard(offset: 0, radius: 30),
      child: Stack(
        alignment: Alignment.center,
        children: [
          CustomPaint(
            size: const Size(110, 110),
            painter: _GaugePainter(value: value, max: max, color: color),
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                value.toStringAsFixed(0),
                style: TextStyle(fontSize: 32, fontWeight: FontWeight.w900, color: NeonColors.text, height: 1, fontStyle: FontStyle.italic),
              ),
              const SizedBox(height: 4),
              Text(
                unit,
                style: TextStyle(fontSize: 8, fontWeight: FontWeight.w900, color: NeonColors.subtext, letterSpacing: 1),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _GaugePainter extends CustomPainter {
  final double value;
  final double max;
  final Color color;

  _GaugePainter({required this.value, required this.max, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    // Background track
    final trackPaint = Paint()
      ..color = Colors.black.withOpacity(0.05)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 14
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(Rect.fromCircle(center: center, radius: radius), pi * 0.75, pi * 1.5, false, trackPaint);

    // Progress
    double progress = (value / max).clamp(0.0, 1.0);
    final activePaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 14
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(Rect.fromCircle(center: center, radius: radius), pi * 0.75, pi * 1.5 * progress, false, activePaint);

    // Decorative dots/ticks
    final dotPaint = Paint()..color = Colors.black.withOpacity(0.2);
    for (var i = 0; i <= 8; i++) {
      double angle = pi * 0.75 + (pi * 1.5 * (i / 8));
      Offset pos = Offset(center.dx + cos(angle) * (radius - 20), center.dy + sin(angle) * (radius - 20));
      canvas.drawCircle(pos, 2, dotPaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
