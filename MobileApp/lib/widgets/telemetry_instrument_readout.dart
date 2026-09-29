import 'package:flutter/material.dart';
import '../core/theme/hardware_theme.dart';

/// Telemetry Readout (NDot 57 for Numbers/Timers + JetBrains Mono for Labels/Units)
class TelemetryInstrumentReadout extends StatelessWidget {
  final String label;
  final String value;
  final String unit;
  final Color activeColor;
  final double fontSize;
  final String? subLabel;

  const TelemetryInstrumentReadout({
    super.key,
    required this.label,
    required this.value,
    required this.unit,
    this.activeColor = HardwarePalette.neonActiveGreen,
    this.fontSize = 24.0,
    this.subLabel,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label.toUpperCase(),
              style: HardwareTypography.jetBrainsLabel(
                fontSize: 8.5,
                color: HardwarePalette.chassisLabelDim,
              ),
            ),
            if (subLabel != null)
              Text(
                subLabel!.toUpperCase(),
                style: HardwareTypography.jetBrainsLabel(
                  fontSize: 7.5,
                  color: HardwarePalette.chassisLabelMid,
                ),
              ),
          ],
        ),
        const SizedBox(height: 4),
        Row(
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Flexible(
              child: Text(
                value,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: HardwareTypography.ndotNumber(
                  fontSize: fontSize,
                  color: activeColor,
                ),
              ),
            ),
            const SizedBox(width: 5),
            Text(
              unit.toUpperCase(),
              style: HardwareTypography.jetBrainsLabel(
                fontSize: 9.0,
                color: HardwarePalette.chassisLabelLight,
                letterSpacing: 1.0,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
