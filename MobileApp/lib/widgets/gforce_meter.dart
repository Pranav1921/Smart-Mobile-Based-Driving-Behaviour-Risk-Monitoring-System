import 'dart:math';
import 'package:flutter/material.dart';
import '../core/constants/app_colors.dart';

class GForceMeter extends StatelessWidget {
  final double gx;
  final double gy;
  final double maxRange; // maximum G range on radar grid
  final double size;

  const GForceMeter({
    super.key,
    required this.gx,
    required this.gy,
    this.maxRange = 1.5,
    this.size = 130.0,
  });

  @override
  Widget build(BuildContext context) {
    // Determine status color based on force levels
    final totalForce = sqrt(gx * gx + gy * gy);
    Color pointColor = AppColors.primary;
    if (totalForce > 0.8) {
      pointColor = AppColors.error;
    } else if (totalForce > 0.5) {
      pointColor = AppColors.warning;
    }

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: AppColors.background.withAlpha((0.4 * 255).round()),
        shape: BoxShape.circle,
        border: Border.all(color: AppColors.border, width: 1.0),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          CustomPaint(
            size: Size(size, size),
            painter: _GForceRadarPainter(
              maxRange: maxRange,
              gx: gx,
              gy: gy,
              pointColor: pointColor,
            ),
          ),
          Positioned(
            bottom: 6,
            child: Text(
              "${totalForce.toStringAsFixed(2)} G",
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.5,
                color: AppColors.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _GForceRadarPainter extends CustomPainter {
  final double maxRange;
  final double gx;
  final double gy;
  final Color pointColor;

  _GForceRadarPainter({
    required this.maxRange,
    required this.gx,
    required this.gy,
    required this.pointColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    final gridPaint = Paint()
      ..color = AppColors.border.withAlpha((0.12 * 255).round())
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    // Draw concentric grids (0.5G, 1.0G, 1.5G)
    canvas.drawCircle(center, radius * (0.5 / maxRange), gridPaint);
    canvas.drawCircle(center, radius * (1.0 / maxRange), gridPaint);
    
    // Draw cross hairs
    canvas.drawLine(Offset(0, center.dy), Offset(size.width, center.dy), gridPaint);
    canvas.drawLine(Offset(center.dx, 0), Offset(center.dx, size.height), gridPaint);

    // Map X, Y G-force coordinates to screen pixels
    // Note: Gy is negative for braking, positive for acceleration
    // In Flutter coordinates:
    // positive X is right, negative X is left
    // positive Y is down, negative Y is up
    double screenX = center.dx + (gx / maxRange) * radius;
    double screenY = center.dy - (gy / maxRange) * radius; // inverted so acceleration pushes up, braking pulls down

    // Clamp coordinates to circle boundary
    double dx = screenX - center.dx;
    double dy = screenY - center.dy;
    double dist = sqrt(dx * dx + dy * dy);
    if (dist > radius - 6) {
      double angle = atan2(dy, dx);
      screenX = center.dx + cos(angle) * (radius - 6);
      screenY = center.dy + sin(angle) * (radius - 6);
    }

    final targetOffset = Offset(screenX, screenY);

    // Draw glowing trace trail towards center
    final trailPaint = Paint()
      ..color = pointColor.withAlpha((0.15 * 255).round())
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0;
    canvas.drawLine(center, targetOffset, trailPaint);

    // Draw G-Force Dot Shadow
    final dotShadow = Paint()
      ..color = pointColor.withAlpha((0.4 * 255).round())
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(targetOffset, 8, dotShadow);

    // Draw G-Force Dot
    final dotPaint = Paint()
      ..color = pointColor
      ..style = PaintingStyle.fill;
    canvas.drawCircle(targetOffset, 5, dotPaint);

    // Draw center point indicator
    final centerPaint = Paint()
      ..color = AppColors.textSecondary.withAlpha((0.5 * 255).round())
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, 2, centerPaint);
  }

  @override
  bool shouldRepaint(covariant _GForceRadarPainter oldDelegate) {
    return oldDelegate.gx != gx || oldDelegate.gy != gy || oldDelegate.pointColor != pointColor;
  }
}
