import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import 'package:mobile_app/providers/trip_provider.dart';
import 'package:mobile_app/providers/theme_provider.dart';
import 'package:mobile_app/core/theme/hardware_theme.dart';
import 'package:mobile_app/core/theme/neon_theme.dart';
import 'package:mobile_app/routes/app_routes.dart';
import 'package:mobile_app/services/chatbot_service.dart';
import 'package:mobile_app/services/gps_service.dart';
import 'package:mobile_app/providers/auth_provider.dart';
import 'package:mobile_app/services/socket_service.dart';
import '../widgets/floating_safety_alert_banner.dart';
import '../widgets/roadside_breakdown_modal.dart';
import '../widgets/guardian_share_modal.dart';
import '../widgets/server_connection_modal.dart';

class TripScreen extends StatefulWidget {
  final bool isEmbedded;
  const TripScreen({super.key, this.isEmbedded = false});

  @override
  State<TripScreen> createState() => _TripScreenState();
}

class _TripScreenState extends State<TripScreen> {
  final MapController _mapController = MapController();
  bool _isLocating = false;

  Future<void> _locateMe(TripProvider trip) async {
    setState(() => _isLocating = true);
    try {
      if (trip.routeCoordinates.isNotEmpty) {
        final last = trip.routeCoordinates.last;
        _mapController.move(LatLng(last[0], last[1]), 17);
        setState(() => _isLocating = false);
        return;
      }

      if (trip.currentLat != null && trip.currentLng != null) {
        _mapController.move(LatLng(trip.currentLat!, trip.currentLng!), 17);
        setState(() => _isLocating = false);
        return;
      }

      final pos = await GpsService.getCurrentLocation();
      if (pos != null) {
        _mapController.move(LatLng(pos.latitude, pos.longitude), 17);
      }
    } catch (_) {}
    setState(() => _isLocating = false);
  }

  @override
  Widget build(BuildContext context) {
    final trip = Provider.of<TripProvider>(context);
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDark = themeProvider.isDarkMode;

    final LatLng currentPos = trip.routeCoordinates.isNotEmpty
        ? LatLng(trip.routeCoordinates.last[0], trip.routeCoordinates.last[1])
        : (trip.currentLat != null && trip.currentLng != null
            ? LatLng(trip.currentLat!, trip.currentLng!)
            : const LatLng(12.7749, 75.2023));

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF181615) : HardwarePalette.chalkChassis,
      body: Stack(
        children: [
          // Styled Map (Dark/Light Carto/OSM Tiles)
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: currentPos,
              initialZoom: 17,
            ),
            children: [
              TileLayer(
                urlTemplate: isDark
                    ? 'https://cartodb-basemaps-a.global.ssl.fastly.net/dark_all/{z}/{x}/{y}.png'
                    : 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.example.driving_monitor',
                maxZoom: 19,
              ),
              CircleLayer(
                circles: [
                  CircleMarker(
                    point: currentPos,
                    radius: 35,
                    useRadiusInMeter: true,
                    color: const Color(0xFFFF5722).withOpacity(0.20),
                    borderColor: const Color(0xFFFF5722),
                    borderStrokeWidth: 1.5,
                  ),
                  ...trip.safetyZones.map((z) => CircleMarker(
                    point: LatLng(z.lat, z.lng),
                    radius: 400,
                    useRadiusInMeter: true,
                    color: z.type == 'school'
                        ? const Color(0xFF38BDF8).withOpacity(0.18)
                        : (z.type == 'traffic'
                            ? const Color(0xFFEF4444).withOpacity(0.18)
                            : const Color(0xFFF59E0B).withOpacity(0.18)),
                    borderColor: z.type == 'school'
                        ? const Color(0xFF38BDF8)
                        : (z.type == 'traffic' ? const Color(0xFFEF4444) : const Color(0xFFF59E0B)),
                    borderStrokeWidth: 2,
                  )),
                  // Dynamic Pothole / Bad Road Heatmap Circles
                  ...trip.potholes.expand((pot) => [
                    CircleMarker(
                      point: LatLng(pot.lat, pot.lng),
                      radius: 120,
                      useRadiusInMeter: true,
                      color: Colors.red.withOpacity(0.20 * pot.intensity),
                      borderColor: Colors.redAccent.withOpacity(0.4),
                      borderStrokeWidth: 1,
                    ),
                    CircleMarker(
                      point: LatLng(pot.lat, pot.lng),
                      radius: 45,
                      useRadiusInMeter: true,
                      color: Colors.orange.withOpacity(0.45 * pot.intensity),
                      borderColor: Colors.orangeAccent,
                      borderStrokeWidth: 1.5,
                    ),
                  ]),
                ],
              ),
              if (trip.routeCoordinates.length >= 2) ...[
                // Glowing route outer aura
                PolylineLayer(
                  polylines: [
                    Polyline(
                      points: trip.routeCoordinates.map<LatLng>((c) => LatLng(c[0], c[1])).toList(),
                      color: const Color(0xFFFF5722).withOpacity(0.35),
                      strokeWidth: 8,
                    ),
                    Polyline(
                      points: trip.routeCoordinates.map<LatLng>((c) => LatLng(c[0], c[1])).toList(),
                      color: const Color(0xFFFF5722),
                      strokeWidth: 4.5,
                    ),
                  ],
                ),
              ],
              MarkerLayer(
                markers: [
                  Marker(
                    point: currentPos,
                    width: 44,
                    height: 44,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: const Color(0xFFFF5722).withOpacity(0.25),
                          ),
                        ),
                        Container(
                          width: 22,
                          height: 22,
                          decoration: BoxDecoration(
                            color: const Color(0xFFFF5722),
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 2.5),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.25),
                                blurRadius: 6,
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.navigation_rounded,
                            color: Colors.white,
                            size: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                  ...trip.safetyZones.where((z) => z.type == 'school').map((z) => Marker(
                    point: LatLng(z.lat, z.lng),
                    width: 34,
                    height: 34,
                    child: Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFF10B981),
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.2),
                            blurRadius: 4,
                          ),
                        ],
                      ),
                      child: const Icon(Icons.school_rounded, color: Colors.white, size: 16),
                    ),
                  )),
                  // Dynamic Pothole Hazard Markers
                  ...trip.potholes.map((pot) => Marker(
                    point: LatLng(pot.lat, pot.lng),
                    width: 40,
                    height: 40,
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.redAccent,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.red.withOpacity(0.4),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: const Icon(Icons.sensors_rounded, color: Colors.white, size: 18),
                    ),
                  )),
                  ...trip.safetyZones.where((z) => z.type == 'traffic').map((z) => Marker(
                    point: LatLng(z.lat, z.lng),
                    width: 30,
                    height: 30,
                    child: const Icon(Icons.traffic_rounded, color: Colors.redAccent, size: 24),
                  )),
                  ...trip.safetyZones.where((z) => z.type == 'construction').map((z) => Marker(
                    point: LatLng(z.lat, z.lng),
                    width: 36,
                    height: 36,
                    child: Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFFF97316),
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.25),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: const Icon(Icons.construction_rounded, color: Colors.white, size: 18),
                    ),
                  )),
                  ...trip.safetyZones.where((z) => z.type == 'sharp_turn').map((z) => Marker(
                    point: LatLng(z.lat, z.lng),
                    width: 36,
                    height: 36,
                    child: Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFFEAB308),
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.25),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: const Icon(Icons.turn_sharp_right_rounded, color: Colors.white, size: 18),
                    ),
                  )),
                  ...trip.safetyZones.where((z) => z.type == 'hospital').map((z) => Marker(
                    point: LatLng(z.lat, z.lng),
                    width: 36,
                    height: 36,
                    child: Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFF06B6D4),
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.25),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: const Icon(Icons.local_hospital_rounded, color: Colors.white, size: 18),
                    ),
                  )),
                ],
              ),
            ],
          ),

          // Top Floating Navigation Bar
          Positioned(
            top: 52,
            left: 20,
            right: 20,
            child: Row(
              children: [
                if (!widget.isEmbedded) ...[
                  GestureDetector(
                    onTap: () {
                      if (Navigator.canPop(context)) {
                        Navigator.pop(context);
                      } else {
                        Navigator.pushReplacementNamed(context, AppRoutes.home);
                      }
                    },
                    child: Container(
                      height: 44,
                      width: 44,
                      decoration: BoxDecoration(
                        color: HardwarePalette.milledSurface,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: HardwarePalette.matrixBorderLight, width: 1.2),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF23201C).withOpacity(0.04),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Icon(Icons.chevron_left_rounded, color: HardwarePalette.silkscreenDark, size: 28),
                    ),
                  ),
                  const SizedBox(width: 8),
                ],
                Expanded(
                  child: Container(
                    height: 44,
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    decoration: BoxDecoration(
                      color: HardwarePalette.milledSurface,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: HardwarePalette.matrixBorderLight, width: 1.2),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF23201C).withOpacity(0.04),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: trip.isTripActive ? HardwarePalette.signalEmerald : HardwarePalette.cautionAmber,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            trip.isTripActive ? "MISSION NAV" : "TELEMETRY STANDBY",
                            style: GoogleFonts.spaceGrotesk(
                              color: HardwarePalette.silkscreenDark,
                              fontWeight: FontWeight.w800,
                              fontSize: 11,
                              letterSpacing: 0.5,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                // Guardian Public Tracking Live-Share
                GestureDetector(
                  onTap: () => GuardianShareModal.show(
                    context,
                    driverId: (auth.profile.driverId.isNotEmpty)
                        ? auth.profile.driverId
                        : (trip.driverId.isNotEmpty ? trip.driverId : 'agent-x'),
                    driverName: (auth.profile.name.isNotEmpty) ? auth.profile.name : 'Field Operator',
                  ),
                  child: Container(
                    height: 44,
                    width: 44,
                    decoration: BoxDecoration(
                      color: HardwarePalette.milledSurface,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: const Color(0xFF38BDF8), width: 1.2),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF38BDF8).withOpacity(0.15),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: const Icon(Icons.share_location_rounded, color: Color(0xFF0284C7), size: 20),
                  ),
                ),
                const SizedBox(width: 8),
                // 1-Click Roadside Breakdown / Tow SOS
                GestureDetector(
                  onTap: () => RoadsideBreakdownModal.show(context),
                  child: Container(
                    height: 44,
                    width: 44,
                    decoration: BoxDecoration(
                      color: const Color(0xFFDC2626),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: Colors.white, width: 1.2),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.red.withOpacity(0.35),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: const Icon(Icons.build_circle_rounded, color: Colors.white, size: 20),
                  ),
                ),
              ],
            ),
          ),

          // No Network / Dead Zone Offline Buffer Banner (Auto-syncs 500 points)
          if (SocketService.isGhatModeActive || !SocketService.isConnected)
            Positioned(
              top: 104,
              left: 20,
              right: 20,
              child: GestureDetector(
                onTap: () => ServerConnectionModal.show(context),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0F172A),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFF38BDF8), width: 1.2),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.35),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.wifi_off_rounded, color: Color(0xFF38BDF8), size: 18),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "OFFLINE DEAD ZONE: ${SocketService.offlineBufferedCount}/500 SAVED",
                              style: GoogleFonts.spaceGrotesk(
                                color: const Color(0xFF38BDF8),
                                fontWeight: FontWeight.w800,
                                fontSize: 10.5,
                                letterSpacing: 0.5,
                              ),
                            ),
                            Text(
                              "No cellular signal. Telemetry will burst-sync on reconnect.",
                              style: GoogleFonts.spaceGrotesk(fontSize: 9, color: Colors.white70),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                        decoration: BoxDecoration(
                          color: const Color(0xFF38BDF8).withOpacity(0.2),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          "CONFIG",
                          style: GoogleFonts.spaceGrotesk(
                            fontSize: 9,
                            fontWeight: FontWeight.w900,
                            color: const Color(0xFF38BDF8),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

          // Admin Tactical Voice Broadcast Banner
          if (trip.adminBroadcastBanner != null)
            Positioned(
              top: 104,
              left: 20,
              right: 20,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF8B5CF6), Color(0xFF6D28D9)],
                  ),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: Colors.white, width: 1.5),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.purple.withOpacity(0.5),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    const Icon(Icons.campaign_rounded, color: Colors.white, size: 24),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        trip.adminBroadcastBanner!,
                        style: GoogleFonts.spaceGrotesk(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            )
          else if (trip.activeGeofenceName != null)
            Positioned(
              top: 104,
              left: 20,
              right: 20,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E293B),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFF38BDF8), width: 1.2),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    const Icon(Icons.radar_rounded, color: Color(0xFF38BDF8), size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        "ZONE: ${trip.activeGeofenceName} (MAX ${trip.activeGeofenceSpeedCeiling ?? 30} KM/H)",
                        style: GoogleFonts.spaceGrotesk(
                          color: const Color(0xFF38BDF8),
                          fontWeight: FontWeight.w700,
                          fontSize: 11.5,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            )
          // V2V Cooperative Proximity Alert Banner
          else if (trip.v2vWarning != null)
            Positioned(
              top: 104,
              left: 20,
              right: 20,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: const Color(0xFFEF4444),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: Colors.white, width: 1.5),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.red.withOpacity(0.4),
                      blurRadius: 10,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    const Icon(Icons.warning_amber_rounded, color: Colors.white, size: 24),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        trip.v2vWarning!,
                        style: GoogleFonts.spaceGrotesk(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 12.5,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            )
          else if (trip.isFatigued)
            Positioned(
              top: 104,
              left: 20,
              right: 20,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: trip.isRestMandatory ? const Color(0xFFDC2626) : const Color(0xFFF59E0B),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.15),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Icon(trip.isRestMandatory ? Icons.hotel_rounded : Icons.timer_outlined, color: Colors.white, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        trip.isRestMandatory
                            ? "Mandatory Rest: Driving ${trip.shiftDurationMinutes}m continuously!"
                            : "Fatigue Warning: Continuous drive ${trip.shiftDurationMinutes}m. Take a break.",
                        style: GoogleFonts.spaceGrotesk(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 12),
                      ),
                    ),
                  ],
                ),
              ),
            ),

          // Dash Overlays (Speedometer & G-Force Meter)
          Positioned(
            bottom: widget.isEmbedded ? 115 : 45,
            left: 20,
            child: Row(
              children: [
                _buildSpeedometer(trip.currentSpeed),
                const SizedBox(width: 10),
                _buildGForceMeter(trip.gForce, trip.maxGForce),
              ],
            ),
          ),

          // MY LOCATION BUTTON - Elevated
          Positioned(
            right: 20,
            bottom: widget.isEmbedded ? 115 : 45,
            child: Tooltip(
              message: "Recenter on My Location",
              child: Material(
                color: Colors.transparent,
                shape: const CircleBorder(),
                elevation: 4,
                shadowColor: const Color(0xFF23201C).withOpacity(0.1),
                child: InkWell(
                  onTap: _isLocating ? null : () => _locateMe(trip),
                  customBorder: const CircleBorder(),
                  child: Container(
                    height: 52,
                    width: 52,
                    decoration: BoxDecoration(
                      color: HardwarePalette.milledSurface,
                      shape: BoxShape.circle,
                      border: Border.all(color: HardwarePalette.signalEmerald, width: 1.5),
                    ),
                    child: _isLocating
                        ? const Padding(
                            padding: EdgeInsets.all(14),
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: HardwarePalette.signalEmerald,
                            ),
                          )
                        : const Icon(
                            Icons.my_location_rounded,
                            color: HardwarePalette.signalEmerald,
                            size: 24,
                          ),
                  ),
                ),
              ),
            ),
          ),

          // CHATBOT BUBBLE - Elevated
          if (trip.isTripActive)
            Positioned(
              right: 20,
              bottom: widget.isEmbedded ? 175 : 105,
              child: GestureDetector(
                onTap: () => _showChatbot(context, trip),
                child: Container(
                  height: 48,
                  width: 48,
                  decoration: BoxDecoration(
                    color: HardwarePalette.silkscreenDark,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF23201C).withOpacity(0.2),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      )
                    ],
                    border: Border.all(color: HardwarePalette.matrixBorderLight, width: 1.5),
                  ),
                  child: const Icon(Icons.psychology_rounded, color: Colors.white, size: 24),
                ),
              ),
            ),

          const FloatingSafetyAlertBanner(),
        ],
      ),
    );
  }

  void _showChatbot(BuildContext context, TripProvider trip) {
    final TextEditingController chatCtrl = TextEditingController();
    final List<Map<String, dynamic>> messages = [
      {'text': "Hello, I am your mission assistant. How can I help with the current assignment?", 'isUser': false},
    ];

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Container(
          height: MediaQuery.of(context).size.height * 0.7,
          decoration: BoxDecoration(
            color: NeonColors.card,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
          ),
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(backgroundColor: NeonColors.primaryGreen, child: const Icon(Icons.psychology_rounded, color: Colors.white)),
                  const SizedBox(width: 14),
                  Text("MISSION ASSISTANT", style: TextStyle(fontWeight: FontWeight.w900, fontSize: 15, color: NeonColors.text)),
                  const Spacer(),
                  IconButton(icon: Icon(Icons.close_rounded, color: NeonColors.subtext), onPressed: () => Navigator.pop(context)),
                ],
              ),
              Divider(height: 32, color: NeonColors.border),
              Expanded(
                child: ListView.builder(
                  itemCount: messages.length,
                  itemBuilder: (context, i) => _chatMsg(messages[i]['text'], messages[i]['isUser']),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                decoration: BoxDecoration(
                  color: NeonColors.surfaceMuted,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: NeonColors.border),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: chatCtrl,
                        style: TextStyle(color: NeonColors.text, fontSize: 13),
                        onSubmitted: (v) async {
                          if (v.trim().isEmpty) return;
                          setModalState(() {
                            messages.add({'text': v, 'isUser': true});
                          });
                          chatCtrl.clear();
                          final response = await ChatbotService.processQuery(v, safetyScore: trip.tripSafetyScore);
                          setModalState(() {
                            messages.add({'text': response, 'isUser': false});
                          });
                        },
                        decoration: InputDecoration(
                          hintText: "Query telemetry assistant...",
                          border: InputBorder.none,
                          hintStyle: TextStyle(fontSize: 12, color: NeonColors.subtext),
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.send_rounded, color: NeonColors.primaryGreen),
                      onPressed: () async {
                        final v = chatCtrl.text;
                        if (v.trim().isEmpty) return;
                        setModalState(() {
                          messages.add({'text': v, 'isUser': true});
                        });
                        chatCtrl.clear();
                        final response = await ChatbotService.processQuery(v, safetyScore: trip.tripSafetyScore);
                        setModalState(() {
                          messages.add({'text': response, 'isUser': false});
                        });
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _chatMsg(String text, bool isUser) {
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isUser ? NeonColors.primaryGreen.withOpacity(0.12) : NeonColors.surfaceMuted,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: isUser ? NeonColors.primaryGreen.withOpacity(0.3) : NeonColors.border),
        ),
        child: Text(text, style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: NeonColors.text)),
      ),
    );
  }

  Widget _buildGForceMeter(double current, double maxG) {
    final bool isHighG = current > 1.2;
    return Container(
      height: 72,
      width: 72,
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        border: Border.all(
          color: isHighG ? const Color(0xFFFF1744) : HardwarePalette.matrixBorderLight,
          width: isHighG ? 2.0 : 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: isHighG
                ? const Color(0xFFFF1744).withOpacity(0.35)
                : const Color(0xFF23201C).withOpacity(0.06),
            blurRadius: isHighG ? 12 : 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              current.toStringAsFixed(1),
              style: GoogleFonts.spaceGrotesk(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: isHighG ? const Color(0xFFDC2626) : HardwarePalette.silkscreenDark,
              ),
            ),
            Text(
              "MAX ${maxG.toStringAsFixed(1)}G",
              style: GoogleFonts.jetBrainsMono(
                fontSize: 7.5,
                fontWeight: FontWeight.w800,
                color: isHighG ? const Color(0xFFEF4444) : HardwarePalette.silkscreenSubtle,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSpeedometer(double speed) {
    final bool isOverspeed = speed > 60;
    return Container(
      height: 72,
      width: 72,
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        border: Border.all(
          color: isOverspeed ? const Color(0xFFFF1744) : HardwarePalette.matrixBorderLight,
          width: isOverspeed ? 2.0 : 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: isOverspeed
                ? const Color(0xFFFF1744).withOpacity(0.35)
                : const Color(0xFF23201C).withOpacity(0.06),
            blurRadius: isOverspeed ? 12 : 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          SizedBox(
            width: 58,
            height: 58,
            child: CircularProgressIndicator(
              value: (speed / 120).clamp(0.0, 1.0),
              color: isOverspeed ? const Color(0xFFFF1744) : const Color(0xFFE53935),
              backgroundColor: HardwarePalette.debossedSlot,
              strokeWidth: 4.5,
            ),
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                speed.toInt().toString(),
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  color: isOverspeed ? const Color(0xFFDC2626) : HardwarePalette.silkscreenDark,
                ),
              ),
              Text(
                "KM/H",
                style: GoogleFonts.jetBrainsMono(
                  fontSize: 7.5,
                  fontWeight: FontWeight.w800,
                  color: isOverspeed ? const Color(0xFFEF4444) : HardwarePalette.silkscreenSubtle,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

