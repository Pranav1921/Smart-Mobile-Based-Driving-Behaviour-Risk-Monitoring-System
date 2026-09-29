import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../core/theme/hardware_theme.dart';
import '../core/theme/mechanical_motion.dart';
import '../services/sound_effect_service.dart';

/// Tactile Analog Rotary Dial Dialer with spring-loaded ratchet return
class AnalogRotaryDialer extends StatefulWidget {
  final double currentValue; // e.g. 70 km/h
  final ValueChanged<double> onValueChanged;
  final double size;
  final String label;

  // 10 Radial Speed Stops around the dial
  static const List<double> speedStops = [30, 40, 50, 60, 70, 80, 90, 100, 110, 120];

  const AnalogRotaryDialer({
    super.key,
    required this.currentValue,
    required this.onValueChanged,
    this.size = 220,
    this.label = "ROTARY GOVERNOR DIALER",
  });

  @override
  State<AnalogRotaryDialer> createState() => _AnalogRotaryDialerState();
}

class _AnalogRotaryDialerState extends State<AnalogRotaryDialer> with SingleTickerProviderStateMixin {
  late AnimationController _springController;
  late Animation<double> _springAnimation;
  double _currentRotationAngle = 0.0; // In radians
  double _dragStartAngle = 0.0;
  double _initialRotationAngle = 0.0;
  int? _activeHoleIndex;
  int _lastTickHole = -1;

  @override
  void initState() {
    super.initState();
    _springController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 450),
    );
    _springAnimation = Tween<double>(begin: 0.0, end: 0.0).animate(
      CurvedAnimation(parent: _springController, curve: MechanicalEasing.elasticSnap),
    )..addListener(() {
        setState(() {
          _currentRotationAngle = _springAnimation.value;
        });
      });
  }

  @override
  void dispose() {
    _springController.dispose();
    super.dispose();
  }

  double _getAngleFromPosition(Offset localPos, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final dx = localPos.dx - center.dx;
    final dy = localPos.dy - center.dy;
    double angle = math.atan2(dy, dx);
    if (angle < 0) angle += 2 * math.pi;
    return angle;
  }

  void _onPanDown(DragDownDetails details, Size size) {
    _springController.stop();
    final angle = _getAngleFromPosition(details.localPosition, size);
    _dragStartAngle = angle;
    _initialRotationAngle = _currentRotationAngle;

    // Detect if finger touched near one of the 10 holes
    _activeHoleIndex = _findNearestHole(details.localPosition, size);
    if (_activeHoleIndex != null) {
      SoundEffectService.playNotchTick();
    }
  }

  void _onPanUpdate(DragUpdateDetails details, Size size) {
    final currentTouchAngle = _getAngleFromPosition(details.localPosition, size);
    double delta = currentTouchAngle - _dragStartAngle;

    // Normalize delta wrapping
    if (delta > math.pi) delta -= 2 * math.pi;
    if (delta < -math.pi) delta += 2 * math.pi;

    // Only allow clockwise rotation (0 to ~3.8 rad max stop)
    double newAngle = (_initialRotationAngle + delta).clamp(0.0, math.pi * 1.35);

    // Audio ratchet tick when crossing holes
    final currentDetent = (newAngle / (math.pi / 6)).floor();
    if (currentDetent != _lastTickHole && newAngle > 0.05) {
      SoundEffectService.playNotchTick();
      _lastTickHole = currentDetent;
    }

    setState(() {
      _currentRotationAngle = newAngle;
    });
  }

  void _onPanEnd(DragEndDetails details) {
    // If dialed far enough with an active hole, commit that speed stop
    if (_activeHoleIndex != null && _currentRotationAngle > 0.35) {
      final selectedVal = AnalogRotaryDialer.speedStops[_activeHoleIndex!];
      SoundEffectService.playRelayLatch();
      widget.onValueChanged(selectedVal);
    }

    // Spring-loaded mechanical return animation to rest position (0 rad)
    _springAnimation = Tween<double>(
      begin: _currentRotationAngle,
      end: 0.0,
    ).animate(
      CurvedAnimation(parent: _springController, curve: MechanicalEasing.elasticSnap),
    );

    _springController.forward(from: 0.0);
    _activeHoleIndex = null;
    _lastTickHole = -1;
  }

  int? _findNearestHole(Offset localPos, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final outerRadius = size.width / 2;
    final holesRadius = outerRadius * 0.68;
    const holeRadius = 16.0;

    for (int i = 0; i < AnalogRotaryDialer.speedStops.length; i++) {
      // Holes mapped around arc (from 0.85 rad to 3.85 rad)
      final baseAngle = (math.pi * 0.35) + (i * (math.pi / 6.5));
      final holeCenter = Offset(
        center.dx + holesRadius * math.cos(baseAngle + _currentRotationAngle),
        center.dy + holesRadius * math.sin(baseAngle + _currentRotationAngle),
      );

      if ((localPos - holeCenter).distance <= holeRadius * 1.5) {
        return i;
      }
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // NDot 57 Main Header
        Text(
          widget.label.toUpperCase(),
          style: HardwareTypography.ndotHeader(fontSize: 13, color: HardwarePalette.pureWhite),
        ),
        const SizedBox(height: 6),
        Text(
          "DIAL HOLE CLOCKWISE TO FINGER STOP // RELEASE TO ENGAGE",
          style: HardwareTypography.jetBrainsLabel(fontSize: 8.5, color: HardwarePalette.chassisLabelDim),
        ),
        const SizedBox(height: 14),

        // Rotary Dialer Canvas
        GestureDetector(
          onPanDown: (d) => _onPanDown(d, Size(widget.size, widget.size)),
          onPanUpdate: (d) => _onPanUpdate(d, Size(widget.size, widget.size)),
          onPanEnd: _onPanEnd,
          child: Container(
            width: widget.size,
            height: widget.size,
            decoration: HardwareDeco.stampedCard(
              backgroundColor: HardwarePalette.debossedChassis,
              borderColor: HardwarePalette.matrixBorder,
              radius: widget.size / 2,
            ),
            child: CustomPaint(
              size: Size(widget.size, widget.size),
              painter: _RotaryDialerPainter(
                rotationAngle: _currentRotationAngle,
                currentValue: widget.currentValue,
                activeHoleIndex: _activeHoleIndex,
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),

        // Selected Governor Readout in NDot 57
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          decoration: HardwareDeco.stampedCard(
            backgroundColor: HardwarePalette.charcoalSurface,
            borderColor: HardwarePalette.matrixBorder,
            radius: 2,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                widget.currentValue.toStringAsFixed(0).padLeft(3, '0'),
                style: HardwareTypography.ndotNumber(
                  fontSize: 24,
                  color: HardwarePalette.neonActiveGreen,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                "KM/H GOVERNOR",
                style: HardwareTypography.jetBrainsLabel(
                  fontSize: 9.5,
                  color: HardwarePalette.chassisLabelLight,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _RotaryDialerPainter extends CustomPainter {
  final double rotationAngle;
  final double currentValue;
  final int? activeHoleIndex;

  _RotaryDialerPainter({
    required this.rotationAngle,
    required this.currentValue,
    required this.activeHoleIndex,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final outerRadius = size.width / 2;
    final dialWheelRadius = outerRadius * 0.94;
    final holesRadius = dialWheelRadius * 0.72;
    const holeRadius = 14.0;

    // 1. Static Base Chassis Number Markings (Under the clear rotary wheel)
    final textPainter = TextPainter(textDirection: TextDirection.ltr);

    for (int i = 0; i < AnalogRotaryDialer.speedStops.length; i++) {
      final baseAngle = (math.pi * 0.35) + (i * (math.pi / 6.5));
      final stopVal = AnalogRotaryDialer.speedStops[i].toInt().toString();

      final textPos = Offset(
        center.dx + holesRadius * math.cos(baseAngle) - 10,
        center.dy + holesRadius * math.sin(baseAngle) - 6,
      );

      textPainter.text = TextSpan(
        text: stopVal,
        style: HardwareTypography.jetBrainsLabel(
          fontSize: 8.5,
          color: HardwarePalette.chassisLabelMid,
        ),
      );
      textPainter.layout();
      textPainter.paint(canvas, textPos);
    }

    // 2. Rotating Wheel Body
    final wheelPaint = Paint()
      ..color = const Color(0xFF1F1F1F)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, dialWheelRadius, wheelPaint);

    final wheelBorder = Paint()
      ..color = HardwarePalette.matrixBorder
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;
    canvas.drawCircle(center, dialWheelRadius, wheelBorder);

    // 3. Draw 10 Circular Finger Holes on Rotating Dial
    for (int i = 0; i < AnalogRotaryDialer.speedStops.length; i++) {
      final baseAngle = (math.pi * 0.35) + (i * (math.pi / 6.5));
      final holeAngle = baseAngle + rotationAngle;

      final holeCenter = Offset(
        center.dx + holesRadius * math.cos(holeAngle),
        center.dy + holesRadius * math.sin(holeAngle),
      );

      // Hole Cavity
      final holePaint = Paint()
        ..color = (activeHoleIndex == i)
            ? HardwarePalette.neonActiveGreen.withValues(alpha: 0.25)
            : const Color(0xFF0C0C0C)
        ..style = PaintingStyle.fill;
      canvas.drawCircle(holeCenter, holeRadius, holePaint);

      // High-Contrast Hole Rim
      final holeRim = Paint()
        ..color = (activeHoleIndex == i)
            ? HardwarePalette.neonActiveGreen
            : HardwarePalette.matrixBorder
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2;
      canvas.drawCircle(holeCenter, holeRadius, holeRim);
    }

    // 4. Fixed Rigid Mechanical Finger Stop (at ~4 o'clock / 1.75 rad)
    const stopAngle = math.pi * 0.28;
    final stopOuter = Offset(
      center.dx + (dialWheelRadius + 2) * math.cos(stopAngle),
      center.dy + (dialWheelRadius + 2) * math.sin(stopAngle),
    );
    final stopInner = Offset(
      center.dx + (holesRadius - 12) * math.cos(stopAngle),
      center.dy + (holesRadius - 12) * math.sin(stopAngle),
    );

    final stopBarPaint = Paint()
      ..color = HardwarePalette.pureWhite
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.square;
    canvas.drawLine(stopOuter, stopInner, stopBarPaint);

    // Stop Rivet Head
    final stopRivet = Paint()
      ..color = HardwarePalette.matrixBorder
      ..style = PaintingStyle.fill;
    canvas.drawCircle(stopOuter, 3.5, stopRivet);

    // 5. Central Hub Center Cap (Stationary Center)
    final hubRadius = dialWheelRadius * 0.38;
    final hubPaint = Paint()
      ..color = HardwarePalette.charcoalSurface
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, hubRadius, hubPaint);

    final hubRim = Paint()
      ..color = HardwarePalette.matrixBorder
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;
    canvas.drawCircle(center, hubRadius, hubRim);

    // NDot Indicator in Hub Center
    final hubCenterPip = Paint()
      ..color = HardwarePalette.neonActiveGreen
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, 4.0, hubCenterPip);
  }

  @override
  bool shouldRepaint(covariant _RotaryDialerPainter oldDelegate) =>
      oldDelegate.rotationAngle != rotationAngle ||
      oldDelegate.currentValue != currentValue ||
      oldDelegate.activeHoleIndex != activeHoleIndex;
}
