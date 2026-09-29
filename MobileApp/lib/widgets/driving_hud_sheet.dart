import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:mobile_app/providers/trip_provider.dart';
import 'package:mobile_app/providers/sensor_provider.dart';
import 'package:mobile_app/core/theme/hardware_theme.dart';
import 'package:mobile_app/core/theme/mechanical_motion.dart';
import 'package:mobile_app/services/sound_effect_service.dart';

class DrivingHudSheet extends StatelessWidget {
  const DrivingHudSheet({super.key});

  static void show(BuildContext context) {
    SoundEffectService.playRelayLatch();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const DrivingHudSheet(),
    );
  }

  Color _getSpeedColor(double speed, double limit) {
    if (speed > limit && limit > 0) return HardwarePalette.criticalRed;
    if (speed >= limit - 5.0 && limit > 0) return HardwarePalette.industrialAmber;
    return HardwarePalette.neonActiveGreen;
  }

  @override
  Widget build(BuildContext context) {
    final trip = Provider.of<TripProvider>(context);
    final sensor = Provider.of<SensorProvider>(context);
    final currentSpeed = trip.currentSpeed;
    final rules = trip.currentCityRules;
    final speedLimit = rules.mainRoadSpeedLimit;
    final speedColor = _getSpeedColor(currentSpeed, speedLimit);
    final gForce = sensor.totalGForce > 0 ? sensor.totalGForce : trip.gForce;
    final gyroDegZ = sensor.gyroDegZ.abs();

    return Container(
      height: MediaQuery.of(context).size.height * 0.74,
      decoration: const BoxDecoration(
        color: HardwarePalette.obsidianChassis,
        border: Border(top: BorderSide(color: HardwarePalette.matrixBorder, width: 1.0)),
      ),
      child: Column(
        children: [
          // Header Deck Bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: const BoxDecoration(
              color: HardwarePalette.charcoalSurface,
              border: Border(bottom: BorderSide(color: HardwarePalette.matrixBorder, width: 1.0)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        color: speedColor,
                        shape: BoxShape.rectangle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      "LIVE DRIVING HUD // COCKPIT TELEMETRY",
                      style: HardwareTypography.jetBrainsLabel(
                        fontSize: 10,
                        color: speedColor,
                      ),
                    ),
                  ],
                ),
                MechanicalPressable(
                  onTap: () {
                    SoundEffectService.playNotchTick();
                    Navigator.pop(context);
                  },
                  child: Container(
                    height: 28,
                    width: 28,
                    decoration: HardwareDeco.stampedCard(
                      backgroundColor: HardwarePalette.debossedChassis,
                      radius: 2,
                    ),
                    child: Icon(Icons.close_rounded, color: HardwarePalette.chassisLabelMid, size: 16),
                  ),
                ),
              ],
            ),
          ),

          // Main HUD Body
          Expanded(
            child: ListView(
              physics: const ClampingScrollPhysics(),
              padding: const EdgeInsets.all(14),
              children: [
                // 1. Minimal 3D Velocity Display (NDot 57)
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  decoration: HardwareDeco.stampedCard(
                    backgroundColor: HardwarePalette.charcoalSurface,
                    radius: 2,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        currentSpeed.toStringAsFixed(0).padLeft(3, '0'),
                        style: HardwareTypography.ndotNumber(
                          fontSize: 64,
                          color: speedColor,
                        ),
                      ),
                      Text(
                        "KM/H // RAW VELOCITY",
                        style: HardwareTypography.jetBrainsLabel(
                          fontSize: 11,
                          color: speedColor,
                          letterSpacing: 2.0,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: HardwareDeco.stampedCard(
                          backgroundColor: HardwarePalette.debossedChassis,
                          radius: 2,
                        ),
                        child: Text(
                          "GOVERNOR LIMIT: ${speedLimit.toInt()} KM/H",
                          style: HardwareTypography.jetBrainsLabel(
                            fontSize: 8.5,
                            color: HardwarePalette.chassisLabelLight,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),

                // 2. Overspeed warning block if applicable
                if (currentSpeed > speedLimit && speedLimit > 0)
                  Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    decoration: HardwareDeco.stampedCard(
                      backgroundColor: HardwarePalette.criticalRed.withValues(alpha: 0.12),
                      borderColor: HardwarePalette.criticalRed,
                      radius: 2,
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.warning_amber_rounded, color: HardwarePalette.criticalRed, size: 18),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            "SPEED LIMIT EXCEEDED // REDUCE SPEED TO ${speedLimit.toInt()} KM/H",
                            style: HardwareTypography.jetBrainsLabel(
                              fontSize: 9.5,
                              color: HardwarePalette.criticalRed,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                // 3. Dual Telemetry Strip (Gyroscope Yaw + G-Force)
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: HardwareDeco.stampedCard(
                          backgroundColor: HardwarePalette.charcoalSurface,
                          radius: 2,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text("GYRO YAW", style: HardwareTypography.jetBrainsLabel(fontSize: 8.5)),
                                const Icon(Icons.screen_rotation_rounded, size: 14, color: Color(0xFF38BDF8)),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              "${gyroDegZ.toStringAsFixed(1)}°/S",
                              style: HardwareTypography.ndotNumber(fontSize: 18, color: HardwarePalette.pureWhite),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              gyroDegZ > 45 ? "SHARP TURN" : "NOMINAL STEERING",
                              style: HardwareTypography.jetBrainsLabel(
                                fontSize: 8.0,
                                color: gyroDegZ > 45 ? HardwarePalette.industrialAmber : HardwarePalette.neonActiveGreen,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: HardwareDeco.stampedCard(
                          backgroundColor: HardwarePalette.charcoalSurface,
                          radius: 2,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text("G-FORCE", style: HardwareTypography.jetBrainsLabel(fontSize: 8.5)),
                                const Icon(Icons.speed_rounded, size: 14, color: HardwarePalette.neonActiveGreen),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              "${gForce.toStringAsFixed(2)} G",
                              style: HardwareTypography.ndotNumber(fontSize: 18, color: HardwarePalette.pureWhite),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              gForce > 1.2 ? "HIGH DYNAMIC LOAD" : "SAFE RANGE",
                              style: HardwareTypography.jetBrainsLabel(
                                fontSize: 8.0,
                                color: gForce > 1.2 ? HardwarePalette.criticalRed : HardwarePalette.neonActiveGreen,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // 4. Performance Consistency Metrics
                Row(
                  children: [
                    _hudMetricPill("SPEED CONS.", "${trip.speedConsistencyPct.toStringAsFixed(0)}%", HardwarePalette.neonActiveGreen),
                    const SizedBox(width: 6),
                    _hudMetricPill("SMOOTH BRAKE", "${trip.brakingSmoothnessPct.toStringAsFixed(0)}%", const Color(0xFF38BDF8)),
                    const SizedBox(width: 6),
                    _hudMetricPill("CORNERING", "${trip.corneringSafetyPct.toStringAsFixed(0)}%", HardwarePalette.industrialAmber),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _hudMetricPill(String label, String value, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
        decoration: HardwareDeco.stampedCard(
          backgroundColor: HardwarePalette.charcoalSurface,
          radius: 2,
        ),
        child: Column(
          children: [
            Text(
              value,
              style: HardwareTypography.ndotNumber(fontSize: 13, color: color),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: HardwareTypography.jetBrainsLabel(fontSize: 8.0, color: HardwarePalette.chassisLabelDim),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
