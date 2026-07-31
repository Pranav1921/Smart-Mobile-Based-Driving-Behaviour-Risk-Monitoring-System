import 'dart:ui';
import 'package:flutter/material.dart';
import '../core/constants/app_colors.dart';

class GlassCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final double borderRadius;
  final Color? color;
  final Color? borderColor;
  final Color? shadowColor;
  final BorderSide? borderSide; // Retained for backward compatibility
  final double? width;
  final double? height;
  final VoidCallback? onTap;

  const GlassCard({
    super.key,
    required this.child,
    this.padding,
    this.borderRadius = 16.0,
    this.color,
    this.borderColor,
    this.shadowColor,
    this.borderSide,
    this.width,
    this.height,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cardColor = color ?? AppColors.surface.withOpacity(0.55);
    final strokeColor = borderColor ?? Colors.white.withOpacity(0.08);
    final strokeWidth = borderSide?.width ?? 1.0;
    final activeShadowColor = shadowColor ?? Colors.black.withOpacity(0.25);

    Widget cardContent = Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(borderRadius),
        boxShadow: [
          BoxShadow(
            color: activeShadowColor,
            offset: const Offset(0, 10),
            blurRadius: 30,
            spreadRadius: -5,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 16.0, sigmaY: 16.0),
          child: Container(
            decoration: BoxDecoration(
              color: cardColor,
              borderRadius: BorderRadius.circular(borderRadius),
              border: Border.all(
                color: strokeColor,
                width: strokeWidth,
              ),
            ),
            child: Padding(
              padding: padding ?? const EdgeInsets.all(18.0),
              child: child,
            ),
          ),
        ),
      ),
    );

    if (onTap != null) {
      return GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: cardContent,
      );
    }
    
    return cardContent;
  }
}
