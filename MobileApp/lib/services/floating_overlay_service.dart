import 'package:flutter/material.dart';
import '../models/order_model.dart';
import '../widgets/floating_delivery_bubble.dart';

/// Global manager to show and hide the Floating Delivery Bubble overlay.
class FloatingOverlayService {
  static OverlayEntry? _overlayEntry;
  static bool get isShowing => _overlayEntry != null;

  /// Displays the floating delivery bubble on top of the screen
  static void show({
    required BuildContext context,
    required DeliveryOrder order,
    VoidCallback? onReturnToApp,
    double currentSpeed = 0.0,
    double safetyScore = 95.0,
  }) {
    hide(); // Remove previous if active

    final overlayState = Overlay.of(context);

    _overlayEntry = OverlayEntry(
      builder: (ctx) => Stack(
        children: [
          FloatingDeliveryBubble(
            order: order,
            currentSpeed: currentSpeed,
            safetyScore: safetyScore,
            onClose: () => hide(),
            onReturnToApp: () {
              hide();
              onReturnToApp?.call();
            },
          ),
        ],
      ),
    );

    overlayState.insert(_overlayEntry!);
  }

  /// Hides the floating delivery bubble
  static void hide() {
    if (_overlayEntry != null) {
      _overlayEntry?.remove();
      _overlayEntry = null;
    }
  }
}
