import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/sensor_provider.dart';
import '../models/event_model.dart';
import '../core/theme/hardware_theme.dart';
import '../core/theme/mechanical_motion.dart';
import '../services/sound_effect_service.dart';

class FloatingSafetyAlertBanner extends StatelessWidget {
  const FloatingSafetyAlertBanner({super.key});

  IconData _getIconForType(String type) {
    final lower = type.toLowerCase();
    if (lower.contains("gyro") || lower.contains("swerve") || lower.contains("rotation")) {
      return Icons.screen_rotation_rounded;
    } else if (lower.contains("vibration") || lower.contains("roughness")) {
      return Icons.vibration_rounded;
    } else if (lower.contains("pothole") || lower.contains("bump")) {
      return Icons.warning_amber_rounded;
    } else if (lower.contains("braking")) {
      return Icons.speed_rounded;
    } else if (lower.contains("acceleration")) {
      return Icons.bolt_rounded;
    } else if (lower.contains("turn")) {
      return Icons.turn_sharp_right_rounded;
    } else if (lower.contains("crash")) {
      return Icons.car_crash_rounded;
    }
    return Icons.sensors_rounded;
  }

  Color _getColorForType(String type, String severity) {
    final lower = type.toLowerCase();
    if (lower.contains("crash") || severity.toLowerCase() == "high") {
      return HardwarePalette.criticalRed;
    } else if (lower.contains("vibration") || lower.contains("pothole") || lower.contains("gyro") || lower.contains("swerve")) {
      return HardwarePalette.industrialAmber;
    }
    return HardwarePalette.neonActiveGreen;
  }

  String _formatTelemetryBadge(SafetyEvent alert) {
    final lower = alert.type.toLowerCase();
    if (lower.contains("gyro") || lower.contains("swerve")) {
      return "${alert.triggerValue.toStringAsFixed(2)} RAD/S";
    } else if (lower.contains("vibration")) {
      return "${alert.triggerValue.toStringAsFixed(2)} M/S²";
    } else if (lower.contains("pothole") || lower.contains("bump") || lower.contains("braking") || lower.contains("acceleration")) {
      return "${alert.triggerValue.toStringAsFixed(2)} G";
    }
    return "${alert.triggerValue.toStringAsFixed(1)} MAG";
  }

  @override
  Widget build(BuildContext context) {
    final sensor = Provider.of<SensorProvider>(context);
    final alert = sensor.currentAlert;

    if (alert == null) {
      return const SizedBox.shrink();
    }

    final color = _getColorForType(alert.type, alert.severity);
    final icon = _getIconForType(alert.type);
    final badgeText = _formatTelemetryBadge(alert);

    return Positioned(
      top: 48,
      left: 12,
      right: 12,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: HardwareDeco.stampedCard(
          backgroundColor: HardwarePalette.charcoalSurface,
          borderColor: color,
          radius: 2,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  height: 34,
                  width: 34,
                  decoration: HardwareDeco.stampedCard(
                    backgroundColor: HardwarePalette.debossedChassis,
                    borderColor: color,
                    radius: 2,
                  ),
                  child: Icon(icon, color: color, size: 18),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            "SENSOR TELEMETRY ALERT",
                            style: HardwareTypography.jetBrainsLabel(
                              color: color,
                              fontSize: 9.0,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                            decoration: BoxDecoration(
                              color: color.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(1),
                            ),
                            child: Text(
                              badgeText,
                              style: HardwareTypography.ndotNumber(
                                color: color,
                                fontSize: 9.0,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        alert.type.toUpperCase(),
                        style: HardwareTypography.ndotHeader(
                          color: HardwarePalette.pureWhite,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                MechanicalPressable(
                  onTap: () {
                    SoundEffectService.playNotchTick();
                    sensor.simulateSensorAlert("");
                  },
                  child: Container(
                    height: 30,
                    width: 30,
                    decoration: HardwareDeco.stampedCard(
                      backgroundColor: HardwarePalette.debossedChassis,
                      radius: 2,
                    ),
                    child: Icon(Icons.close_rounded, color: HardwarePalette.chassisLabelMid, size: 16),
                  ),
                ),
              ],
            ),
            if (alert.aiTip.isNotEmpty) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: HardwareDeco.stampedCard(
                  backgroundColor: HardwarePalette.debossedChassis,
                  radius: 2,
                ),
                child: Row(
                  children: [
                    Icon(Icons.lightbulb_outline_rounded, color: color, size: 13),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        alert.aiTip.toUpperCase(),
                        style: HardwareTypography.jetBrainsBody(
                          color: HardwarePalette.chassisLabelLight,
                          fontSize: 10,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
