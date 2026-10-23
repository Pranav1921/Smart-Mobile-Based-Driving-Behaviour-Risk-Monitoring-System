import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class RealisticVehicleMapMarker extends StatelessWidget {
  final String? vehicleType;
  final String? vehicleName;
  final double heading;
  final String? driverName;
  final bool isDeadZone;
  final bool isEmergency;
  final double size;

  const RealisticVehicleMapMarker({
    super.key,
    this.vehicleType,
    this.vehicleName,
    this.heading = 0.0,
    this.driverName,
    this.isDeadZone = false,
    this.isEmergency = false,
    this.size = 54.0,
  });

  static String getAssetPath(String? type, String? name) {
    final text = "${type ?? ''} ${name ?? ''}".toLowerCase();
    // 1. Scooter (Activa, Jupiter, Dio, Electric Scooters)
    if (text.contains('scoot') ||
        text.contains('dio') ||
        text.contains('activa') ||
        text.contains('jupiter') ||
        text.contains('moped') ||
        text.contains('ather') ||
        text.contains('ola') ||
        text.contains('chetak') ||
        text.contains('pep') ||
        text.contains('burgman') ||
        text.contains('ntorq')) {
      return 'assets/images/vehicle_scooter.png';
    }
    // 2. Auto Rickshaw (Three-wheeler / Tuk-Tuk)
    if (text.contains('auto') ||
        text.contains('rickshaw') ||
        text.contains('3-wheel') ||
        text.contains('3_wheeler') ||
        text.contains('three-wheel') ||
        text.contains('tuk') ||
        text.contains('ape')) {
      return 'assets/images/vehicle_auto.png';
    }
    // 3. Motorcycle / Bike
    if (text.contains('bike') ||
        text.contains('motorcycle') ||
        text.contains('pulsar') ||
        text.contains('splendor') ||
        text.contains('bullet') ||
        text.contains('royal enfield') ||
        text.contains('apache') ||
        text.contains('ktm') ||
        text.contains('fz') ||
        text.contains('shine') ||
        text.contains('platina') ||
        text.contains('2-wheel')) {
      return 'assets/images/vehicle_bike.png';
    }
    // 4. Commercial Truck / Van / Cargo
    if (text.contains('truck') ||
        text.contains('ace') ||
        text.contains('lcv') ||
        text.contains('van') ||
        text.contains('delivery_van') ||
        text.contains('cargo') ||
        text.contains('pickup') ||
        text.contains('bolero') ||
        text.contains('lorry') ||
        text.contains('eicher') ||
        text.contains('dost')) {
      return 'assets/images/vehicle_truck.png';
    }
    // 5. Default Car / Cab / Taxi
    return 'assets/images/vehicle_car.png';
  }

  @override
  Widget build(BuildContext context) {
    final asset = getAssetPath(vehicleType, vehicleName);
    final glowColor = isEmergency
        ? const Color(0xFFEF4444)
        : (isDeadZone ? const Color(0xFF06B6D4) : const Color(0xFF10B981));

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Deadzone / SOS Tag
        if (isDeadZone || isEmergency)
          Container(
            margin: const EdgeInsets.only(bottom: 2),
            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
            decoration: BoxDecoration(
              color: isEmergency ? const Color(0xFFDC2626) : const Color(0xFF0891B2),
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: Colors.white, width: 1.0),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.4),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Text(
              isEmergency ? "🚨 SOS" : "📡 DEAD ZONE",
              style: GoogleFonts.spaceGrotesk(
                fontSize: 8,
                fontWeight: FontWeight.w900,
                color: Colors.white,
                letterSpacing: 0.5,
              ),
            ),
          )
        else if (driverName != null && driverName!.isNotEmpty)
          Container(
            margin: const EdgeInsets.only(bottom: 2),
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: const Color(0xFF0F172A).withValues(alpha: 0.92),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: glowColor, width: 1.0),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.3),
                  blurRadius: 4,
                  offset: const Offset(0, 1),
                ),
              ],
            ),
            child: Text(
              driverName!.split(' ')[0],
              style: GoogleFonts.spaceGrotesk(
                fontSize: 8.5,
                fontWeight: FontWeight.w800,
                color: Colors.white,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),

        // Realistic Vehicle Body with Rotation & Glow
        Stack(
          alignment: Alignment.center,
          children: [
            // Soft Radial Glow
            Container(
              width: size * 0.75,
              height: size * 0.75,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: glowColor.withValues(alpha: 0.45),
                    blurRadius: 14,
                    spreadRadius: 2,
                  ),
                ],
              ),
            ),

            // Top-View Vehicle Image Rotated along Heading
            Transform.rotate(
              angle: heading * (math.pi / 180.0),
              child: SizedBox(
                width: size * 0.55,
                height: size,
                child: Image.asset(
                  asset,
                  fit: BoxFit.contain,
                  errorBuilder: (ctx, err, stack) => Icon(
                    Icons.navigation_rounded,
                    color: glowColor,
                    size: 24,
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
