import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../core/theme/hardware_theme.dart';
import '../services/sound_effect_service.dart';

class AnalogRotaryKnob extends StatefulWidget {
  final double value; // 0.0 to 1.0
  final ValueChanged<double> onChanged;
  final int notches;
  final double size;
  final String label;
  final String unit;
  final double minDisplayVal;
  final double maxDisplayVal;

  const AnalogRotaryKnob({
    super.key,
    required this.value,
    required this.onChanged,
    this.notches = 24,
    this.size = 190,
    this.label = "GOVERNOR THRESHOLD LIMIT",
    this.unit = "KM/H",
    this.minDisplayVal = 20,
    this.maxDisplayVal = 140,
  });

  @override
  State<AnalogRotaryKnob> createState() => _AnalogRotaryKnobState();
}

class _AnalogRotaryKnobState extends State<AnalogRotaryKnob> {
  int _lastNotch = 0;

  void _processGesture(Offset localPos, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final dx = localPos.dx - center.dx;
    final dy = localPos.dy - center.dy;

    // Polar coordinates in radians
    double angle = math.atan2(dy, dx);
    
    // Normalize angle so 0 is at bottom-left start of arc (135 degrees = 3*PI/4)
    // Operational arc: 270 degrees (3*PI/2) from 135 deg to 405 deg (45 deg)
    double offsetAngle = angle + (math.pi * 0.75);
    while (offsetAngle < 0) {
      offsetAngle += 2 * math.pi;
    }
    while (offsetAngle >= 2 * math.pi) {
      offsetAngle -= 2 * math.pi;
    }

    const sweepRange = math.pi * 1.5; // 270 degrees
    double normalized = offsetAngle / sweepRange;
    normalized = normalized.clamp(0.0, 1.0);

    final currentNotch = (normalized * widget.notches).round();
    if (currentNotch != _lastNotch) {
      SoundEffectService.playNotchTick();
      _lastNotch = currentNotch;
    }

    widget.onChanged(normalized);
  }

  @override
  Widget build(BuildContext context) {
    final displayValue = widget.minDisplayVal +
        (widget.value * (widget.maxDisplayVal - widget.minDisplayVal));

    return RepaintBoundary(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Etched Chassis Header
          Text(
            widget.label.toUpperCase(),
            style: HardwareTypography.chassisLabel(fontSize: 10, letterSpacing: 2.2),
          ),
          const SizedBox(height: 14),

          // 3D Rotary Dial Gesture Canvas
          GestureDetector(
            onPanUpdate: (d) => _processGesture(d.localPosition, Size(widget.size, widget.size)),
            onPanDown: (d) => _processGesture(d.localPosition, Size(widget.size, widget.size)),
            child: Container(
              width: widget.size,
              height: widget.size,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: HardwarePalette.debossedChassis,
                boxShadow: [
                  // Stamped debossed chassis recess shadow
                  BoxShadow(
                    color: Colors.black,
                    offset: Offset(2, 2),
                    blurRadius: 0,
                  ),
                ],
              ),
              child: CustomPaint(
                size: Size(widget.size, widget.size),
                painter: _AnalogKnobPainter(
                  value: widget.value,
                  notches: widget.notches,
                ),
              ),
            ),
          ),
          const SizedBox(height: 14),

          // Live Metric Value Readout
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            decoration: HardwareDeco.stampedCard(
              backgroundColor: HardwarePalette.charcoalSurface,
              radius: 4,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text(
                  displayValue.toStringAsFixed(0).padLeft(3, '0'),
                  style: HardwareTypography.digitalSegment(
                    fontSize: 26,
                    color: HardwarePalette.neonActiveGreen,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  widget.unit,
                  style: HardwareTypography.chassisLabel(
                    fontSize: 10,
                    color: HardwarePalette.chassisLabelMid,
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

class _AnalogKnobPainter extends CustomPainter {
  final double value;
  final int notches;

  _AnalogKnobPainter({required this.value, required this.notches});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final outerRadius = size.width / 2;
    final knobRadius = outerRadius * 0.72;

    const startAngle = math.pi * 0.75; // 135 degrees
    const sweepAngle = math.pi * 1.5;  // 270 degrees

    // 1. Draw Notched Track Ring
    final notchPaint = Paint()
      ..strokeWidth = 1.8
      ..strokeCap = StrokeCap.square;

    for (int i = 0; i <= notches; i++) {
      final t = i / notches;
      final angle = startAngle + (t * sweepAngle);
      final isPassed = t <= value + 0.005;

      notchPaint.color = isPassed
          ? HardwarePalette.neonActiveGreen
          : HardwarePalette.matrixBorder;

      final p1 = Offset(
        center.dx + (outerRadius - 3) * math.cos(angle),
        center.dy + (outerRadius - 3) * math.sin(angle),
      );
      final p2 = Offset(
        center.dx + (outerRadius - 12) * math.cos(angle),
        center.dy + (outerRadius - 12) * math.sin(angle),
      );
      canvas.drawLine(p1, p2, notchPaint);
    }

    // 2. Physical Drop Shadow under the Dial Body
    final shadowPaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.9)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5.0);
    canvas.drawCircle(center.translate(2, 3), knobRadius, shadowPaint);

    // 3. Dial Physical Surface (Brushed Industrial Texture)
    final dialGradient = RadialGradient(
      center: const Alignment(-0.25, -0.3),
      radius: 0.88,
      colors: const [
        Color(0xFF3A3A3A), // Top-left specular highlight
        Color(0xFF242424), // Core body
        Color(0xFF161616), // Bottom-right shadow rim
      ],
      stops: const [0.0, 0.55, 1.0],
    );

    final dialPaint = Paint()
      ..shader = dialGradient.createShader(
        Rect.fromCircle(center: center, radius: knobRadius),
      );
    canvas.drawCircle(center, knobRadius, dialPaint);

    // 4. Dial Outer Mechanical Rim
    final rimPaint = Paint()
      ..color = HardwarePalette.matrixBorder
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    canvas.drawCircle(center, knobRadius, rimPaint);

    // Inner concentric precision groove
    final innerGroovePaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.6)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;
    canvas.drawCircle(center, knobRadius * 0.82, innerGroovePaint);

    // 5. Piercing #00FF66 Indicator Dot tracking radius
    final currentAngle = startAngle + (value * sweepAngle);
    final dotDistance = knobRadius * 0.68;
    final dotCenter = Offset(
      center.dx + dotDistance * math.cos(currentAngle),
      center.dy + dotDistance * math.sin(currentAngle),
    );

    // Neon Glow halo
    final dotGlow = Paint()
      ..color = HardwarePalette.neonActiveGreen.withValues(alpha: 0.5)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4.0);
    canvas.drawCircle(dotCenter, 5.0, dotGlow);

    // Sharp Core Pip
    final dotCore = Paint()
      ..color = HardwarePalette.neonActiveGreen
      ..style = PaintingStyle.fill;
    canvas.drawCircle(dotCenter, 3.2, dotCore);
  }

  @override
  bool shouldRepaint(covariant _AnalogKnobPainter oldDelegate) =>
      oldDelegate.value != value || oldDelegate.notches != notches;
}
