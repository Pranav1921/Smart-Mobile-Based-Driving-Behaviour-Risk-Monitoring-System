import 'package:flutter/material.dart';
import '../core/theme/hardware_theme.dart';
import '../core/theme/mechanical_motion.dart';
import '../services/sound_effect_service.dart';

/// Rigid, Flat, Boxy Grid Matrix Module Card (ZERO Drop Shadows)
class HardwareModuleCard extends StatelessWidget {
  final String title;
  final Widget child;
  final Color? statusLedColor;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry padding;
  final Widget? trailing;

  const HardwareModuleCard({
    super.key,
    required this.title,
    required this.child,
    this.statusLedColor,
    this.onTap,
    this.padding = const EdgeInsets.all(12.0),
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    final cardContent = Container(
      padding: padding,
      decoration: HardwareDeco.stampedCard(
        backgroundColor: HardwarePalette.moduleCard,
        borderColor: HardwarePalette.matrixBorder,
        radius: 2.0, // Strict flat boxy corners
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Module Header with Title, Rivet and Status Pip
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    width: 4,
                    height: 4,
                    margin: const EdgeInsets.only(right: 6),
                    decoration: const BoxDecoration(
                      color: HardwarePalette.mechanicalScrew,
                      shape: BoxShape.rectangle,
                    ),
                  ),
                  Text(
                    title.toUpperCase(),
                    style: HardwareTypography.jetBrainsLabel(fontSize: 9.0),
                  ),
                ],
              ),
              if (trailing != null)
                trailing!
              else if (statusLedColor != null)
                Container(
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: statusLedColor,
                    shape: BoxShape.rectangle, // Sharp boxy status pip
                  ),
                ),
            ],
          ),
          const SizedBox(height: 6),
          // Body Content
          Expanded(child: child),
        ],
      ),
    );

    if (onTap != null) {
      return MechanicalPressable(
        onTap: () {
          SoundEffectService.playRelayLatch();
          onTap!();
        },
        child: cardContent,
      );
    }

    return cardContent;
  }
}
