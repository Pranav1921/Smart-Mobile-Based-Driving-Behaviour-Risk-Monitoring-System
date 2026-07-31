import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../core/constants/app_colors.dart';

class DeliveryAnimation extends StatefulWidget {
  const DeliveryAnimation({super.key});

  @override
  State<DeliveryAnimation> createState() => _DeliveryAnimationState();
}

class _DeliveryAnimationState extends State<DeliveryAnimation> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isLight = Theme.of(context).brightness == Brightness.light;
    final strokeColor = isLight ? Colors.black : Colors.white;

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        // Bounce up/down slightly to simulate movement
        final bounce = math.sin(_controller.value * 2 * math.pi) * 2.0;
        final tilt = math.cos(_controller.value * 2 * math.pi) * 0.03;

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: isLight ? Colors.white : const Color(0xFF101010),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: strokeColor,
              width: 2.0,
            ),
            boxShadow: [
              BoxShadow(
                color: isLight ? Colors.black : AppColors.primary,
                offset: const Offset(2, 2),
                blurRadius: 0,
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Bouncing delivery bike icon
              Transform.translate(
                offset: Offset(0, bounce),
                child: Transform.rotate(
                  angle: tilt,
                  child: Icon(
                    Icons.motorcycle,
                    color: isLight ? Colors.black : AppColors.primary,
                    size: 24,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              // Moving dots to show speed lines
              Row(
                mainAxisSize: MainAxisSize.min,
                children: List.generate(3, (index) {
                  // Phase delay shift
                  final progress = (_controller.value + (index * 0.33)) % 1.0;
                  final opacity = 1.0 - progress;
                  final offset = (1.0 - progress) * 12.0;

                  return Transform.translate(
                    offset: Offset(-offset, 0),
                    child: Opacity(
                      opacity: opacity.clamp(0.0, 1.0),
                      child: Container(
                        width: 3,
                        height: 3,
                        margin: const EdgeInsets.only(right: 2),
                        decoration: BoxDecoration(
                          color: isLight ? Colors.black45 : AppColors.primary.withOpacity(0.7),
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                  );
                }),
              ),
              const SizedBox(width: 8),
              // Delivery status texts
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 6,
                        height: 6,
                        decoration: const BoxDecoration(
                          color: Colors.green,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Text(
                        "DISPATCHED",
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w900,
                          color: Colors.green,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 1),
                  Text(
                    "DELIVERY SERVICE",
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w900,
                      color: isLight ? Colors.black : Colors.white,
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}
