import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../core/theme/hardware_theme.dart';
import '../core/theme/mechanical_motion.dart';
import '../services/sound_effect_service.dart';
import 'telemetry_instrument_readout.dart';

/// Distraction-Free OLED Burn-In Protected Running Interface (NDot 57 + JetBrains Mono)
class BurnInProtectedHUD extends StatefulWidget {
  final double currentSpeed;
  final double speedLimit;
  final double riskScore;
  final double gForce;
  final String locationName;
  final bool isEsp32Connected;
  final VoidCallback onExit;

  const BurnInProtectedHUD({
    super.key,
    required this.currentSpeed,
    required this.speedLimit,
    required this.riskScore,
    required this.gForce,
    required this.locationName,
    required this.isEsp32Connected,
    required this.onExit,
  });

  @override
  State<BurnInProtectedHUD> createState() => _BurnInProtectedHUDState();
}

class _BurnInProtectedHUDState extends State<BurnInProtectedHUD> {
  late Timer _pixelShiftTimer;
  Offset _shiftOffset = Offset.zero;
  final math.Random _random = math.Random();
  int _shiftCounter = 0;

  @override
  void initState() {
    super.initState();
    // 60-second periodic micro pixel-shifting drift to prevent OLED burn-in
    _pixelShiftTimer = Timer.periodic(const Duration(seconds: 60), (_) {
      if (mounted) {
        setState(() {
          _shiftCounter++;
          _shiftOffset = Offset(
            (_random.nextDouble() * 6) - 3, // -3px to +3px
            (_random.nextDouble() * 6) - 3,
          );
        });
      }
    });
  }

  @override
  void dispose() {
    _pixelShiftTimer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool isSpeedExceeded = widget.currentSpeed > widget.speedLimit && widget.speedLimit > 0;
    final bool isHighRisk = widget.riskScore > 60;

    final Color mainTelemetryColor = (isSpeedExceeded || isHighRisk)
        ? HardwarePalette.criticalRed
        : HardwarePalette.neonActiveGreen;

    return Scaffold(
      backgroundColor: HardwarePalette.obsidianChassis,
      body: SafeArea(
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 350),
          curve: MechanicalEasing.snappyZeroStart,
          transform: Matrix4.translationValues(_shiftOffset.dx, _shiftOffset.dy, 0),
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 14.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 1. Hardware Header Strip
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 6,
                        height: 6,
                        decoration: const BoxDecoration(
                          color: HardwarePalette.neonActiveGreen,
                          shape: BoxShape.rectangle,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        "AMOLED RUNNING LOCK // SHIFT #$_shiftCounter",
                        style: HardwareTypography.jetBrainsLabel(
                          fontSize: 9.5,
                          color: HardwarePalette.neonActiveGreen,
                        ),
                      ),
                    ],
                  ),
                  MechanicalPressable(
                    onTap: () {
                      SoundEffectService.playRelayLatch(isEngage: false);
                      widget.onExit();
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: HardwareDeco.stampedCard(
                        backgroundColor: HardwarePalette.charcoalSurface,
                        radius: 2,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.arrow_back_ios_new_rounded,
                            color: HardwarePalette.chassisLabelMid,
                            size: 11,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            "DECK",
                            style: HardwareTypography.jetBrainsButton(fontSize: 9.5),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),

              const Spacer(flex: 1),

              // 2. Primary Raw Velocity Readout in 'NDot 57'
              Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      widget.currentSpeed.toStringAsFixed(0).padLeft(3, '0'),
                      style: HardwareTypography.ndotNumber(
                        fontSize: 96,
                        color: mainTelemetryColor,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "KM/H // LIVE GPS VELOCITY",
                      style: HardwareTypography.jetBrainsLabel(
                        fontSize: 11,
                        color: HardwarePalette.chassisLabelLight,
                        letterSpacing: 2.0,
                      ),
                    ),
                    if (isSpeedExceeded)
                      Container(
                        margin: const EdgeInsets.only(top: 8),
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: HardwarePalette.criticalRed.withValues(alpha: 0.15),
                          border: Border.all(color: HardwarePalette.criticalRed),
                          borderRadius: BorderRadius.circular(2),
                        ),
                        child: Text(
                          "OVERSPEED WARNING (${widget.speedLimit.toInt()} LIMIT)",
                          style: HardwareTypography.jetBrainsLabel(
                            fontSize: 9,
                            color: HardwarePalette.criticalRed,
                          ),
                        ),
                      ),
                  ],
                ),
              ),

              const Spacer(flex: 2),

              // 3. Bottom Flat Boxy Matrix Strip (ZERO Drop Shadows)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: HardwareDeco.stampedCard(
                  backgroundColor: HardwarePalette.charcoalSurface,
                  radius: 2,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    TelemetryInstrumentReadout(
                      label: "SYS RISK",
                      value: widget.riskScore.toStringAsFixed(0),
                      unit: "IDX",
                      fontSize: 22,
                      activeColor: isHighRisk
                          ? HardwarePalette.criticalRed
                          : (widget.riskScore > 35
                              ? HardwarePalette.industrialAmber
                              : HardwarePalette.neonActiveGreen),
                    ),
                    Container(
                      width: 1,
                      height: 32,
                      color: HardwarePalette.matrixBorder,
                    ),
                    TelemetryInstrumentReadout(
                      label: "G-FORCE",
                      value: widget.gForce.toStringAsFixed(2),
                      unit: "G",
                      fontSize: 22,
                      activeColor: widget.gForce > 0.4
                          ? HardwarePalette.industrialAmber
                          : HardwarePalette.neonActiveGreen,
                    ),
                    Container(
                      width: 1,
                      height: 32,
                      color: HardwarePalette.matrixBorder,
                    ),
                    TelemetryInstrumentReadout(
                      label: "FUSED HW",
                      value: widget.isEsp32Connected ? "ESP32" : "PHONE",
                      unit: "IMU",
                      fontSize: 18,
                      activeColor: widget.isEsp32Connected
                          ? HardwarePalette.neonActiveGreen
                          : HardwarePalette.chassisLabelLight,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 10),

              // Sub-footer Location Track
              Center(
                child: Text(
                  "GEO: ${widget.locationName.toUpperCase()}",
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: HardwareTypography.jetBrainsLabel(
                    fontSize: 8.5,
                    color: HardwarePalette.chassisLabelDim,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
