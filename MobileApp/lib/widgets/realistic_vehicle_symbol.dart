import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mobile_app/core/theme/hardware_theme.dart';

/// Vehicle options categorized by wheel count (2-Wheeler, 3-Wheeler, 4-Wheeler)
class VehicleOptionData {
  final String type;
  final String label;
  final String wheelCategory; // "2-WHEELER", "3-WHEELER", "4-WHEELER"
  final int wheelCount;
  final String key; // "scooter", "motorcycle", "auto", "cab", "van"

  const VehicleOptionData({
    required this.type,
    required this.label,
    required this.wheelCategory,
    required this.wheelCount,
    required this.key,
  });
}

class RealisticVehicleData {
  static const List<VehicleOptionData> allVehicles = [
    VehicleOptionData(
      type: "Scooty",
      label: "Scooter",
      wheelCategory: "2-WHEELER",
      wheelCount: 2,
      key: "scooter",
    ),
    VehicleOptionData(
      type: "Motorcycle",
      label: "Bike",
      wheelCategory: "2-WHEELER",
      wheelCount: 2,
      key: "motorcycle",
    ),
    VehicleOptionData(
      type: "Auto Rickshaw",
      label: "3-Wheeler",
      wheelCategory: "3-WHEELER",
      wheelCount: 3,
      key: "auto",
    ),
    VehicleOptionData(
      type: "Cab",
      label: "Cab / Taxi",
      wheelCategory: "4-WHEELER",
      wheelCount: 4,
      key: "cab",
    ),
    VehicleOptionData(
      type: "Delivery Van",
      label: "Van / LCV",
      wheelCategory: "4-WHEELER",
      wheelCount: 4,
      key: "van",
    ),
  ];

  static VehicleOptionData find(String? rawType) {
    if (rawType == null || rawType.isEmpty) {
      return allVehicles[0];
    }
    final clean = rawType.trim().toLowerCase();
    if (clean.contains("scoot") || clean.contains("activa") || clean.contains("jupiter") || clean.contains("vespa") || clean.contains("moped")) {
      return allVehicles[0]; // Scooter
    }
    if (clean.contains("bike") || clean.contains("motorcycle") || clean.contains("pulsar") || clean.contains("splendor") || clean.contains("royal")) {
      return allVehicles[1]; // Bike
    }
    if (clean.contains("3-wheel") || clean.contains("auto") || clean.contains("rickshaw") || clean.contains("tuk") || clean.contains("three")) {
      return allVehicles[2]; // Auto Rickshaw
    }
    if (clean.contains("cab") || clean.contains("taxi") || clean.contains("car") || clean.contains("sedan") || clean.contains("dzire") || clean.contains("etios")) {
      return allVehicles[3]; // Cab
    }
    if (clean.contains("van") || clean.contains("truck") || clean.contains("lcv") || clean.contains("ace") || clean.contains("delivery") || clean.contains("cargo")) {
      return allVehicles[4]; // Van
    }
    return allVehicles[0];
  }
}

/// Standalone vehicle name badge (no visual symbol/drawing - pure typography)
class RealisticVehicleSymbol extends StatelessWidget {
  final String? type;
  final double size;
  final Color? color;
  final bool showWheelBadge;
  final bool isSelected;

  const RealisticVehicleSymbol({
    super.key,
    required this.type,
    this.size = 28.0,
    this.color,
    this.showWheelBadge = false,
    this.isSelected = false,
  });

  @override
  Widget build(BuildContext context) {
    final vehicle = RealisticVehicleData.find(type);
    final paintColor = color ?? (isSelected ? Colors.white : HardwarePalette.silkscreenDark);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: paintColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: paintColor.withValues(alpha: 0.3)),
      ),
      child: Text(
        "${vehicle.label} (${vehicle.wheelCount}W)",
        style: GoogleFonts.jetBrainsMono(
          fontSize: 9,
          fontWeight: FontWeight.w800,
          color: paintColor,
        ),
      ),
    );
  }
}
