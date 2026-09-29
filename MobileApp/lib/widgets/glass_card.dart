import 'package:flutter/material.dart';
import '../core/constants/app_colors.dart';

class GlassCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final double borderRadius;
  final Color? color;
  final Color? borderColor;
  final Color? shadowColor;
  final BorderSide? borderSide;
  final double? width;
  final double? height;
  final VoidCallback? onTap;

  const GlassCard({
    super.key,
    required this.child,
    this.padding,
    this.borderRadius = 24.0,
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
    final isLight = Theme.of(context).brightness == Brightness.light;
    final cardColor = color ?? (isLight ? AppColors.surface : const Color(0xFF1E293B));
    final strokeColor = borderColor ?? (isLight ? AppColors.border : const Color(0xFF334155));
    final strokeWidth = borderSide?.width ?? 1.0;
    final activeShadowColor = shadowColor ?? (isLight ? const Color(0xFFE5DFD3).withOpacity(0.7) : Colors.black.withOpacity(0.2));

    Widget cardContent = Container(
      width: width,
      height: height,
      padding: padding ?? const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(borderRadius),
        border: Border.all(
          color: strokeColor,
          width: strokeWidth,
        ),
        boxShadow: [
          BoxShadow(
            color: activeShadowColor,
            offset: const Offset(0, 4),
            blurRadius: 14,
            spreadRadius: 0,
          ),
        ],
      ),
      child: child,
    );

    if (onTap != null) {
      return Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(borderRadius),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(borderRadius),
          child: cardContent,
        ),
      );
    }

    return cardContent;
  }
}
