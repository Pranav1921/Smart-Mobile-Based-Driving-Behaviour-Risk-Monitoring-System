import 'package:flutter/material.dart';

class TacticalRouter {
  static Route createRoute(Widget page, {RouteSettings? settings}) {
    return PageRouteBuilder(
      settings: settings,
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionDuration: const Duration(milliseconds: 350),
      reverseTransitionDuration: const Duration(milliseconds: 300),
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        final curvedAnimation = CurvedAnimation(
          parent: animation,
          curve: Curves.easeOutCubic,
          reverseCurve: Curves.easeInCubic,
        );

        // Smooth Slide from right + Fade in
        const begin = Offset(0.08, 0.0);
        const end = Offset.zero;
        final slideTween = Tween(begin: begin, end: end);
        final fadeTween = Tween<double>(begin: 0.0, end: 1.0);

        return SlideTransition(
          position: slideTween.animate(curvedAnimation),
          child: FadeTransition(
            opacity: fadeTween.animate(curvedAnimation),
            child: child,
          ),
        );
      },
    );
  }
}

