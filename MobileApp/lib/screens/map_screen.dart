import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import 'package:mobile_app/core/theme/neon_theme.dart';
import 'package:mobile_app/models/order_model.dart';
import 'package:mobile_app/providers/trip_provider.dart';
import 'package:mobile_app/services/chatbot_service.dart';
import 'package:mobile_app/services/gps_service.dart';
import 'package:mobile_app/services/map_navigation_service.dart';
import 'package:mobile_app/screens/rules_rewards_screen.dart';
import 'package:url_launcher/url_launcher.dart' as url_launcher;

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  final MapController _mapController = MapController();
  LatLng? _myExactLocation;
  bool _isLocating = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _locateMe(showToast: false);
    });
  }

  Future<void> _locateMe({bool showToast = true}) async {
    setState(() => _isLocating = true);
    try {
      final pos = await GpsService.getCurrentLocation();
      if (pos != null) {
        final loc = LatLng(pos.latitude, pos.longitude);
        final trip = Provider.of<TripProvider>(context, listen: false);
        trip.setDriverLocation(pos.latitude, pos.longitude, pos.speed * 3.6, pos.heading);
        setState(() {
          _myExactLocation = loc;
          _isLocating = false;
        });
        _mapController.move(loc, 16.5);
        if (showToast && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('📍 Exact Location: ${loc.latitude.toStringAsFixed(5)}, ${loc.longitude.toStringAsFixed(5)}'),
              backgroundColor: NeonColors.primaryGreen,
              duration: const Duration(seconds: 2),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
        return;
      }

      final trip = Provider.of<TripProvider>(context, listen: false);
      if (trip.currentLat != null && trip.currentLng != null) {
        final loc = LatLng(trip.currentLat!, trip.currentLng!);
        setState(() {
          _myExactLocation = loc;
          _isLocating = false;
        });
        _mapController.move(loc, 16.5);
        return;
      }
    } catch (_) {}

    setState(() => _isLocating = false);
    if (showToast && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not fetch exact GPS location. Please check location permissions.'),
          backgroundColor: Colors.redAccent,
          duration: Duration(seconds: 3),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final trip = Provider.of<TripProvider>(context);
    final activeOrder = trip.activeOrder;

    final LatLng activePos = _myExactLocation ??
        (trip.currentLat != null && trip.currentLng != null
            ? LatLng(trip.currentLat!, trip.currentLng!)
            : const LatLng(12.7749, 75.2023));

    final LatLng? dropPos = activeOrder != null
        ? LatLng(activeOrder.dropLat, activeOrder.dropLng)
        : null;

    final LatLng? pickupPos = activeOrder != null
        ? LatLng(activeOrder.pickupLat, activeOrder.pickupLng)
        : null;

    final List<LatLng> navRoute = dropPos != null
        ? [
            activePos,
            LatLng(
              activePos.latitude + (dropPos.latitude - activePos.latitude) * 0.35 + 0.0008,
              activePos.longitude + (dropPos.longitude - activePos.longitude) * 0.3 - 0.0008,
            ),
            LatLng(
              activePos.latitude + (dropPos.latitude - activePos.latitude) * 0.7 - 0.0004,
              activePos.longitude + (dropPos.longitude - activePos.longitude) * 0.75 + 0.0006,
            ),
            dropPos,
          ]
        : [];

    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // Light Styled OpenStreetMap
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: activePos,
              initialZoom: 15,
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.example.smartdrive',
                maxZoom: 19,
              ),

              // Active Delivery Mission Route Polyline
              if (navRoute.isNotEmpty)
                PolylineLayer(
                  polylines: [
                    Polyline(
                      points: navRoute,
                      strokeWidth: 8.0,
                      color: const Color(0xFF047857).withOpacity(0.7),
                    ),
                    Polyline(
                      points: navRoute,
                      strokeWidth: 5.0,
                      color: const Color(0xFF00FF9D),
                    ),
                  ],
                ),

              CircleLayer(
                circles: [
                  CircleMarker(
                    point: activePos,
                    radius: 35,
                    useRadiusInMeter: true,
                    color: const Color(0xFF10B981).withOpacity(0.20),
                    borderColor: const Color(0xFF10B981),
                    borderStrokeWidth: 1.5,
                  ),
                  ...trip.safetyZones.map((z) => CircleMarker(
                    point: LatLng(z.lat, z.lng),
                    radius: 500,
                    useRadiusInMeter: true,
                    color: z.type == 'school'
                        ? Colors.green.withOpacity(0.15)
                        : (z.type == 'traffic'
                            ? Colors.red.withOpacity(0.15)
                            : Colors.orange.withOpacity(0.15)),
                    borderColor: z.type == 'school'
                        ? Colors.green
                        : (z.type == 'traffic' ? Colors.red : Colors.orange),
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
              MarkerLayer(
                markers: [
                  // Active Driver Location Marker (with driver name badge)
                  Marker(
                    point: activePos,
                    width: activeOrder != null ? 150 : 50,
                    height: activeOrder != null ? 76 : 50,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (activeOrder != null)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                            margin: const EdgeInsets.only(bottom: 2),
                            decoration: BoxDecoration(
                              color: const Color(0xFF0F172A),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: const Color(0xFF10B981), width: 1.5),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.3),
                                  blurRadius: 6,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.delivery_dining_rounded, color: Color(0xFF10B981), size: 12),
                                const SizedBox(width: 4),
                                ConstrainedBox(
                                  constraints: const BoxConstraints(maxWidth: 110),
                                  child: Text(
                                    activeOrder.driverName,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 9.5,
                                      fontWeight: FontWeight.w900,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        Stack(
                          alignment: Alignment.center,
                          children: [
                            Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: const Color(0xFF10B981).withOpacity(0.25),
                              ),
                            ),
                            Container(
                              width: 28,
                              height: 28,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.white,
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.2),
                                    blurRadius: 6,
                                    offset: const Offset(0, 2),
                                  )
                                ],
                              ),
                              child: Center(
                                child: Container(
                                  width: 18,
                                  height: 18,
                                  decoration: const BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: Color(0xFF10B981),
                                  ),
                                  child: const Icon(
                                    Icons.navigation_rounded,
                                    color: Colors.white,
                                    size: 12,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // Destination Flag Marker (Tapping opens Google Maps navigation)
                  if (dropPos != null)
                    Marker(
                      point: dropPos,
                      width: 160,
                      height: 78,
                      child: GestureDetector(
                        onTap: () {
                          MapNavigationService.openGoogleMaps(
                            order: activeOrder,
                            originLat: activePos.latitude,
                            originLng: activePos.longitude,
                            destLat: activeOrder?.dropLat,
                            destLng: activeOrder?.dropLng,
                            address: activeOrder?.dropAddress,
                            context: context,
                          );
                        },
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                              margin: const EdgeInsets.only(bottom: 2),
                              decoration: BoxDecoration(
                                color: const Color(0xFFE11D48),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: Colors.white, width: 1.2),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.35),
                                    blurRadius: 6,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.location_on_rounded, color: Colors.white, size: 11),
                                  const SizedBox(width: 3),
                                  ConstrainedBox(
                                    constraints: const BoxConstraints(maxWidth: 120),
                                    child: Text(
                                      activeOrder?.dropAddress ?? "Customer",
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 9,
                                        fontWeight: FontWeight.w900,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Stack(
                              alignment: Alignment.center,
                              children: [
                                Container(
                                  width: 44,
                                  height: 44,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFE11D48).withOpacity(0.25),
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                Container(
                                  width: 32,
                                  height: 32,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFE11D48),
                                    shape: BoxShape.circle,
                                    border: Border.all(color: Colors.white, width: 2.5),
                                    boxShadow: [
                                      BoxShadow(
                                        color: const Color(0xFFF43F5E).withOpacity(0.5),
                                        blurRadius: 10,
                                        offset: const Offset(0, 3),
                                      ),
                                    ],
                                  ),
                                  child: const Icon(Icons.flag_rounded, color: Colors.white, size: 16),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),

                  // Pickup Hub Marker
                  if (pickupPos != null && (pickupPos.latitude - activePos.latitude).abs() > 0.001)
                    Marker(
                      point: pickupPos,
                      width: 140,
                      height: 68,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2.5),
                            margin: const EdgeInsets.only(bottom: 2),
                            decoration: BoxDecoration(
                              color: const Color(0xFF1E3A8A),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.white, width: 1),
                            ),
                            child: const Text(
                              "DEPOT / HUB",
                              style: TextStyle(color: Colors.white, fontSize: 8.5, fontWeight: FontWeight.bold),
                            ),
                          ),
                          Container(
                            width: 30,
                            height: 30,
                            decoration: BoxDecoration(
                              color: const Color(0xFF3B82F6),
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 2),
                            ),
                            child: const Icon(Icons.store_rounded, color: Colors.white, size: 16),
                          ),
                        ],
                      ),
                    ),

                  ...trip.safetyZones.where((z) => z.type == 'school').map((z) => Marker(
                    point: LatLng(z.lat, z.lng),
                    width: 36,
                    height: 36,
                    child: Tooltip(
                      message: "School Zone: ${z.name}",
                      child: Container(
                        decoration: BoxDecoration(
                          color: const Color(0xFF10B981),
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.2),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: const Icon(Icons.school_rounded, color: Colors.white, size: 18),
                      ),
                    ),
                  )),
                  // Dynamic Pothole & Bad Road Hazard Markers (Z-Axis Detection)
                  ...trip.potholes.map((pot) {
                    final bool isSeverePothole = pot.vibrationRate >= 2.8 || pot.intensity >= 0.8;
                    final Color hazardColor = isSeverePothole ? const Color(0xFFEF4444) : const Color(0xFFF59E0B);
                    final IconData hazardIcon = isSeverePothole ? Icons.warning_rounded : Icons.texture_rounded;
                    final String hazardLabel = isSeverePothole ? "POTHOLE" : "BAD ROAD";

                    return Marker(
                      point: LatLng(pot.lat, pot.lng),
                      width: 50,
                      height: 50,
                      child: Tooltip(
                        message: "$hazardLabel: ${pot.roadName} (${pot.vibrationRate.toStringAsFixed(1)}G)",
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                color: hazardColor.withOpacity(0.25),
                                shape: BoxShape.circle,
                              ),
                            ),
                            Container(
                              width: 32,
                              height: 32,
                              decoration: BoxDecoration(
                                color: hazardColor,
                                shape: BoxShape.circle,
                                border: Border.all(color: Colors.white, width: 2),
                                boxShadow: [
                                  BoxShadow(
                                    color: hazardColor.withOpacity(0.5),
                                    blurRadius: 8,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Icon(hazardIcon, color: Colors.white, size: 16),
                            ),
                          ],
                        ),
                      ),
                    );
                  }),
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
                    child: Tooltip(
                      message: "Road Construction: ${z.name}",
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
                    ),
                  )),
                  ...trip.safetyZones.where((z) => z.type == 'sharp_turn').map((z) => Marker(
                    point: LatLng(z.lat, z.lng),
                    width: 36,
                    height: 36,
                    child: Tooltip(
                      message: "Sharp Curve Ahead: ${z.name}",
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
                    ),
                  )),
                  ...trip.safetyZones.where((z) => z.type == 'hospital').map((z) => Marker(
                    point: LatLng(z.lat, z.lng),
                    width: 36,
                    height: 36,
                    child: Tooltip(
                      message: "Hospital Silence Corridor: ${z.name}",
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
                    ),
                  )),
                ],
              ),
            ],
          ),

          // Top Header Overlay with Status & In-App Navigation HUD
          Positioned(
            top: 52,
            left: 68,
            right: 16,
            child: activeOrder != null
                ? Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0F172A).withOpacity(0.96),
                      borderRadius: BorderRadius.circular(18),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.25),
                          blurRadius: 20,
                          offset: const Offset(0, 4),
                        ),
                      ],
                      border: Border.all(color: const Color(0xFF10B981).withOpacity(0.4), width: 1.5),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(7),
                          decoration: BoxDecoration(
                            color: const Color(0xFF10B981).withOpacity(0.15),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(Icons.turn_right_rounded, color: Color(0xFF10B981), size: 20),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Row(
                                children: [
                                  Text(
                                    "EN ROUTE · ${activeOrder.distanceKm} KM",
                                    style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: Color(0xFF10B981), letterSpacing: 0.8),
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    "ETA ${activeOrder.estimatedTimeMinutes}m",
                                    style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: Colors.grey.shade400),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 2),
                              Text(
                                activeOrder.dropAddress,
                                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: Colors.white),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),

                        // Switch to Google Maps action
                        GestureDetector(
                          onTap: () {
                            MapNavigationService.openGoogleMaps(
                              order: activeOrder,
                              originLat: activePos.latitude,
                              originLng: activePos.longitude,
                              lat: activeOrder.dropLat,
                              lng: activeOrder.dropLng,
                              address: activeOrder.dropAddress,
                              context: context,
                            );
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
                            decoration: BoxDecoration(
                              color: const Color(0xFF4285F4),
                              borderRadius: BorderRadius.circular(10),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFF4285F4).withOpacity(0.4),
                                  blurRadius: 6,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: const [
                                Icon(Icons.directions_rounded, color: Colors.white, size: 15),
                                SizedBox(width: 4),
                                Text(
                                  "MAPS",
                                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: Colors.white),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  )
                : Row(
                    children: [
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.95),
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.08),
                                blurRadius: 15,
                                offset: const Offset(0, 4),
                              ),
                            ],
                            border: Border.all(color: Colors.grey.shade200),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 8,
                                height: 8,
                                decoration: const BoxDecoration(
                                  color: Color(0xFF10B981),
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  "Live Map · ${trip.currentCityRules.cityName}",
                                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: Colors.black87),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),

                      // Google Maps Launcher Button
                      GestureDetector(
                        onTap: () {
                          final targetOrder = activeOrder ?? (trip.availableOrders.isNotEmpty ? trip.availableOrders.first : null);
                          final destLat = targetOrder?.dropLat ?? (activePos.latitude + 0.015);
                          final destLng = targetOrder?.dropLng ?? (activePos.longitude + 0.015);
                          final destAddr = targetOrder?.dropAddress;

                          MapNavigationService.openGoogleMaps(
                            originLat: activePos.latitude,
                            originLng: activePos.longitude,
                            destLat: destLat,
                            destLng: destLng,
                            address: destAddr,
                            context: context,
                          );
                        },
                        child: Container(
                          height: 42,
                          padding: const EdgeInsets.symmetric(horizontal: 10),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.12),
                                blurRadius: 10,
                                offset: const Offset(0, 3),
                              ),
                            ],
                            border: Border.all(color: const Color(0xFF4285F4).withOpacity(0.5), width: 1.5),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: const [
                              Icon(Icons.map_rounded, color: Color(0xFF1A73E8), size: 16),
                              SizedBox(width: 4),
                              Text(
                                "MAPS",
                                style: TextStyle(
                                  color: Color(0xFF1A73E8),
                                  fontSize: 10,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),

                      // Direction Compass to Realign & Straighten Map
                      GestureDetector(
                        onTap: () {
                          _mapController.rotate(0.0);
                          _mapController.move(activePos, 16.5);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Row(
                                children: const [
                                  Icon(Icons.explore_rounded, color: Color(0xFF00FF9D), size: 18),
                                  SizedBox(width: 8),
                                  Text("Map Re-aligned straight North (0°)"),
                                ],
                              ),
                              backgroundColor: const Color(0xFF0F172A),
                              duration: const Duration(seconds: 1),
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        },
                        child: Container(
                          height: 42,
                          width: 42,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.12),
                                blurRadius: 10,
                                offset: const Offset(0, 3),
                              ),
                            ],
                            border: Border.all(color: const Color(0xFF10B981).withOpacity(0.5), width: 1.5),
                          ),
                          child: Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: const [
                                Icon(Icons.navigation_rounded, color: Color(0xFFEF4444), size: 16),
                                Text(
                                  "N",
                                  style: TextStyle(
                                    color: Color(0xFFEF4444),
                                    fontSize: 8.5,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
          ),

          // Floating Google Maps Quick Navigation FAB
          Positioned(
            bottom: activeOrder != null ? 445 : 305,
            right: 24,
            child: Tooltip(
              message: activeOrder != null ? "Navigate in Google Maps" : "Open in Google Maps",
              child: Material(
                color: Colors.transparent,
                shape: const CircleBorder(),
                elevation: 6,
                shadowColor: const Color(0xFF4285F4).withOpacity(0.4),
                child: InkWell(
                  onTap: () {
                    final targetOrder = activeOrder ?? (trip.availableOrders.isNotEmpty ? trip.availableOrders.first : null);
                    final destLat = targetOrder?.dropLat ?? (activePos.latitude + 0.015);
                    final destLng = targetOrder?.dropLng ?? (activePos.longitude + 0.015);
                    final destAddr = targetOrder?.dropAddress;

                    MapNavigationService.openGoogleMaps(
                      order: activeOrder,
                      originLat: activePos.latitude,
                      originLng: activePos.longitude,
                      destLat: destLat,
                      destLng: destLng,
                      address: destAddr,
                      context: context,
                    );
                  },
                  customBorder: const CircleBorder(),
                  child: Container(
                    height: 48,
                    width: 48,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      border: Border.all(color: const Color(0xFF1A73E8), width: 2),
                    ),
                    child: const Center(
                      child: Icon(
                        Icons.directions_rounded,
                        color: Color(0xFF1A73E8),
                        size: 24,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),

          // Center Recenter Floating Button
          Positioned(
            bottom: activeOrder != null ? 385 : 240,
            right: 24,
            child: Tooltip(
              message: "Center to My Exact Location",
              child: Material(
                color: Colors.transparent,
                shape: const CircleBorder(),
                elevation: 6,
                shadowColor: const Color(0xFF10B981).withOpacity(0.4),
                child: InkWell(
                  onTap: _isLocating ? null : () => _locateMe(showToast: true),
                  customBorder: const CircleBorder(),
                  child: Container(
                    height: 48,
                    width: 48,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      border: Border.all(color: const Color(0xFF10B981), width: 2),
                    ),
                    child: _isLocating
                        ? const Padding(
                            padding: EdgeInsets.all(12),
                            child: CircularProgressIndicator(
                              strokeWidth: 2.5,
                              color: Color(0xFF10B981),
                            ),
                          )
                        : const Icon(
                            Icons.my_location_rounded,
                            color: Color(0xFF10B981),
                            size: 24,
                          ),
                  ),
                ),
              ),
            ),
          ),

          // ── PROMINENT SOS PANIC BUTTON ──
          Positioned(
            bottom: activeOrder != null ? 320 : 170,
            right: 24,
            child: GestureDetector(
              onTap: () => trip.triggerManualSOS(),
              child: Container(
                height: 56,
                width: 56,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFFF2D55), Color(0xFFB91C1C)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.redAccent.withOpacity(0.45),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    ),
                  ],
                  border: Border.all(color: Colors.white, width: 2),
                ),
                child: const Center(
                  child: Text(
                    "SOS",
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                      fontSize: 14,
                      letterSpacing: 1.2,
                    ),
                  ),
                ),
              ),
            ),
          ),

          // Dash Overlays (Speedometer & G-Force Meter)
          Positioned(
            bottom: activeOrder != null ? 315 : 160,
            left: 24,
            child: Row(
              children: [
                _buildSpeedometer(trip.currentSpeed),
                const SizedBox(width: 12),
                _buildGForceMeter(trip.gForce, trip.maxGForce),
              ],
            ),
          ),

          // Active Mission Bottom Action Card with Driver Details and Direct Call Button
          if (activeOrder != null)
            Positioned(
              bottom: 84,
              left: 14,
              right: 14,
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFF0F172A).withOpacity(0.96),
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(color: const Color(0xFF10B981).withOpacity(0.4), width: 1.5),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.4),
                      blurRadius: 24,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Top Status & Payout Header
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFF10B981).withOpacity(0.2),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            "MISSION #${activeOrder.id} • IN PROGRESS",
                            style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: Color(0xFF10B981), letterSpacing: 0.5),
                          ),
                        ),
                        const Spacer(),
                        Text(
                          "₹${activeOrder.payoutAmount.toInt()}",
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Color(0xFF10B981)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),

                    // Delivery Guy Profile Row & Direct CALL Button
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.06),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: Colors.white12),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 38,
                            height: 38,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: const Color(0xFF10B981).withOpacity(0.2),
                              border: Border.all(color: const Color(0xFF10B981), width: 1.5),
                            ),
                            child: const Center(
                              child: Icon(Icons.delivery_dining_rounded, color: Color(0xFF10B981), size: 22),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  activeOrder.driverName,
                                  style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w800, color: Colors.white),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  "${activeOrder.driverPhone} • ${activeOrder.driverAddress}",
                                  style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w500, color: Colors.white70),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),

                          // Dedicated CALL DRIVER Button
                          GestureDetector(
                            onTap: () async {
                              final dialed = await activeOrder.callDriver();
                              if (!dialed && context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text("Calling driver at ${activeOrder.driverPhone}..."),
                                    duration: const Duration(seconds: 2),
                                    behavior: SnackBarBehavior.floating,
                                  ),
                                );
                              }
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                              decoration: BoxDecoration(
                                color: const Color(0xFF10B981),
                                borderRadius: BorderRadius.circular(10),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(0xFF10B981).withOpacity(0.4),
                                    blurRadius: 8,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: const [
                                  Icon(Icons.call_rounded, color: Colors.white, size: 14),
                                  SizedBox(width: 4),
                                  Text(
                                    "CALL",
                                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: Colors.white),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),

                    // Destination Address & Consignment Info
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Padding(
                          padding: EdgeInsets.only(top: 2),
                          child: Icon(Icons.location_on_rounded, color: Color(0xFFF43F5E), size: 15),
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                activeOrder.dropAddress,
                                style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700, color: Colors.white),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 1),
                              Text(
                                "📦 ${activeOrder.packageItems} • Cust: ${activeOrder.customerName}",
                                style: TextStyle(fontSize: 10, fontWeight: FontWeight.w500, color: Colors.grey.shade400),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                        // Call Customer icon button
                        IconButton(
                          icon: const Icon(Icons.phone_in_talk_rounded, color: Color(0xFF60A5FA), size: 16),
                          constraints: const BoxConstraints(),
                          padding: const EdgeInsets.all(4),
                          tooltip: "Call Customer (${activeOrder.customerPhone})",
                          onPressed: () => activeOrder.callCustomer(),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),

                    // Navigation and Complete Action Buttons
                    Row(
                      children: [
                        Expanded(
                          child: SizedBox(
                            height: 42,
                            child: OutlinedButton.icon(
                              style: OutlinedButton.styleFrom(
                                foregroundColor: const Color(0xFF60A5FA),
                                side: const BorderSide(color: Color(0xFF3B82F6), width: 1.5),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                              onPressed: () => MapNavigationService.openGoogleMaps(
                                order: activeOrder,
                                originLat: activePos.latitude,
                                originLng: activePos.longitude,
                                destLat: activeOrder.dropLat,
                                destLng: activeOrder.dropLng,
                                address: activeOrder.dropAddress,
                                context: context,
                              ),
                              icon: const Icon(Icons.directions_rounded, size: 16),
                              label: const Text(
                                "GOOGLE MAPS",
                                style: TextStyle(fontWeight: FontWeight.w900, fontSize: 11, letterSpacing: 0.5),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: SizedBox(
                            height: 42,
                            child: ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF10B981),
                                foregroundColor: Colors.white,
                                elevation: 0,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                              onPressed: () async {
                                final completedTrip = await trip.completeActiveOrder();
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Row(
                                        children: [
                                          const Icon(Icons.stars_rounded, color: Colors.amberAccent, size: 20),
                                          const SizedBox(width: 8),
                                          Expanded(
                                            child: Text(
                                              "Delivered! +₹${(completedTrip.payout ?? 0.0).toInt()} & +${completedTrip.pointsEarned} PTS Added",
                                              style: const TextStyle(fontWeight: FontWeight.w700),
                                            ),
                                          ),
                                        ],
                                      ),
                                      backgroundColor: const Color(0xFF0F172A),
                                      duration: const Duration(seconds: 3),
                                      behavior: SnackBarBehavior.floating,
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                    ),
                                  );
                                }
                              },
                              icon: const Icon(Icons.check_circle_outline_rounded, size: 16),
                              label: const Text(
                                "DELIVERED",
                                style: TextStyle(fontWeight: FontWeight.w900, fontSize: 11, letterSpacing: 0.5),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          // ── IN-APP MAP ON-SCREEN CRASH / SOS VERIFICATION CARD ─────────
          if (trip.showSOSConfirmation || trip.isCrashDetected)
            Positioned(
              left: 16,
              right: 16,
              bottom: 24,
              child: Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: const Color(0xFF0F172A),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: const Color(0xFFEF4444), width: 2),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFEF4444).withOpacity(0.4),
                      blurRadius: 24,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 12,
                          height: 12,
                          decoration: const BoxDecoration(
                            color: Color(0xFFEF4444),
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 10),
                        const Expanded(
                          child: Text(
                            "CRITICAL CRASH ALERT",
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 1.0,
                              color: Colors.white,
                            ),
                          ),
                        ),
                        if (trip.sosCountdown > 0)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: const Color(0xFFEF4444).withOpacity(0.2),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: const Color(0xFFEF4444).withOpacity(0.4)),
                            ),
                            child: Text(
                              "SOS in ${trip.sosCountdown}s",
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w900,
                                color: Color(0xFFEF4444),
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(
                      trip.crashReason,
                      style: const TextStyle(
                        fontSize: 12.5,
                        color: Color(0xFFE2E8F0),
                        height: 1.3,
                      ),
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Expanded(
                          flex: 3,
                          child: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF10B981),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                              elevation: 0,
                            ),
                            onPressed: () {
                              trip.confirmSafe();
                            },
                            icon: const Icon(Icons.check_circle_rounded, size: 18),
                            label: const Text(
                              "I AM SAFE (DISMISS)",
                              style: TextStyle(fontWeight: FontWeight.w900, fontSize: 11, letterSpacing: 0.5),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          flex: 2,
                          child: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFEF4444),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                              elevation: 0,
                            ),
                            onPressed: () {
                              trip.triggerManualSOS();
                            },
                            icon: const Icon(Icons.emergency_rounded, size: 18),
                            label: const Text(
                              "SEND SOS",
                              style: TextStyle(fontWeight: FontWeight.w900, fontSize: 11, letterSpacing: 0.5),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildGForceMeter(double current, double maxG) {
    return Container(
      height: 74,
      width: 74,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.92),
        shape: BoxShape.circle,
        border: Border.all(color: Colors.black12, width: 1.5),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
      ),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(current.toStringAsFixed(1), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Colors.black87)),
            Text("MAX ${maxG.toStringAsFixed(1)}G", style: const TextStyle(fontSize: 7, fontWeight: FontWeight.w900, color: Colors.grey)),
          ],
        ),
      ),
    );
  }

  Widget _buildSpeedometer(double speed) {
    return Container(
      height: 74,
      width: 74,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.92),
        shape: BoxShape.circle,
        border: Border.all(color: Colors.black12, width: 1.5),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          CircularProgressIndicator(
            value: (speed / 120).clamp(0.0, 1.0),
            color: NeonColors.primaryGreen,
            backgroundColor: Colors.black.withOpacity(0.05),
            strokeWidth: 5,
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(speed.toInt().toString(), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Colors.black87)),
              const Text("KM/H", style: TextStyle(fontSize: 7, fontWeight: FontWeight.w900, color: Colors.grey, letterSpacing: 0.5)),
            ],
          ),
        ],
      ),
    );
  }
}
