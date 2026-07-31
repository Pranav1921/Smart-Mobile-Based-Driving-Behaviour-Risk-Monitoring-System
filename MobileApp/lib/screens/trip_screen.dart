import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import '../services/gps_service.dart';
import '../core/constants/app_colors.dart';
import '../models/event_model.dart';
import '../providers/auth_provider.dart';
import '../providers/sensor_provider.dart';
import '../providers/trip_provider.dart';
import '../routes/app_routes.dart';
import '../widgets/gforce_meter.dart';
import '../widgets/glass_card.dart';

class TripScreen extends StatefulWidget {
  final bool isEmbedded;

  const TripScreen({super.key, this.isEmbedded = false});

  @override
  State<TripScreen> createState() => _TripScreenState();
}

class _TripScreenState extends State<TripScreen> with TickerProviderStateMixin {
  final MapController _mapController = MapController();
  late AnimationController _alertController;
  late Animation<Offset> _alertOffset;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnim;
  
  SafetyEvent? _cachedAlert;
  LatLng? _currentLocation;
  String _mapStyle = 'm'; // 'm' (roadmap), 'y' (hybrid), 's' (satellite), 't' (terrain)
  dynamic _gpsSub; // StreamSubscription

  @override
  void initState() {
    super.initState();
    _alertController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _alertOffset = Tween<Offset>(
      begin: const Offset(0, -1.5),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _alertController, curve: Curves.easeOutCubic));

    // Pulsing ring for the driver position marker
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);
    _pulseAnim = Tween<double>(begin: 0.5, end: 1.0)
        .animate(CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut));

    _loadCurrentLocation();
    
    // Subscribe to live location updates to auto-center the map camera
    _gpsSub = GpsService.getLocationStream().listen((pos) {
      if (mounted) {
        setState(() {
          _currentLocation = LatLng(pos.latitude, pos.longitude);
        });
        _mapController.move(LatLng(pos.latitude, pos.longitude), _mapController.camera.zoom);
      }
    });
  }

  Future<void> _loadCurrentLocation() async {
    final pos = await GpsService.getCurrentLocation();
    if (pos != null && mounted) {
      setState(() {
        _currentLocation = LatLng(pos.latitude, pos.longitude);
      });
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          try {
            _mapController.move(LatLng(pos.latitude, pos.longitude), 14.5);
          } catch (_) {}
        }
      });
    }
  }

  @override
  void dispose() {
    _gpsSub?.cancel();
    _mapController.dispose();
    _alertController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tripProv = Provider.of<TripProvider>(context);
    final sensorProv = Provider.of<SensorProvider>(context);
    final authProv = Provider.of<AuthProvider>(context);
    final mapUrlTemplate = _mapStyle == 'm'
        ? 'https://a.basemaps.cartocdn.com/light_all/{z}/{x}/{y}.png'
        : 'https://mt1.google.com/vt/lyrs=$_mapStyle&hl=en&x={x}&y={y}&z={z}';

    // Watch sensor warnings to animate top overlay popup
    if (sensorProv.currentAlert != null && _cachedAlert?.id != sensorProv.currentAlert!.id) {
      _cachedAlert = sensorProv.currentAlert;
      _alertController.forward();
      // Record this event in trip telemetry list
      tripProv.simulateSafetyEvent(sensorProv.currentAlert!);
      
      // Deduct driver rating
      authProv.updateSafetyScore((sensorProv.currentAlert!.type == "Crash") ? -25.0 : -3.0);
    } else if (sensorProv.currentAlert == null && _cachedAlert != null) {
      _alertController.reverse().then((_) => _cachedAlert = null);
    }

    // Direct routing to crash overlay if triggered
    if (tripProv.isCrashDetected) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.pushReplacementNamed(context, AppRoutes.crash);
      });
    }

    final isTripActive = tripProv.isTripActive;

    // Default standby coordinate (use real GPS coordinates if available)
    final LatLng driverLoc = _currentLocation ?? const LatLng(28.6139, 77.2090);
    LatLng centerLoc = driverLoc;
    List<LatLng> mapPoints = [];
    List<Marker> markers = [];

    // ── Driver marker (always visible, pulsing) ──────────────────────────────
    final driverMarker = AnimatedBuilder(
      animation: _pulseAnim,
      builder: (_, __) => Stack(
        alignment: Alignment.center,
        children: [
          // Outer pulse ring
          Container(
            width: 52 * _pulseAnim.value,
            height: 52 * _pulseAnim.value,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.primary.withOpacity(0.15 * _pulseAnim.value),
            ),
          ),
          // Inner glow dot
          Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.primary.withOpacity(0.25),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withOpacity(0.55),
                  blurRadius: 10,
                  spreadRadius: 1,
                ),
              ],
            ),
          ),
          // Motorcycle icon
          const Icon(Icons.two_wheeler, color: Colors.white, size: 18),
        ],
      ),
    );

    if (isTripActive && tripProv.routeCoordinates.isNotEmpty) {
      mapPoints = tripProv.routeCoordinates.map((c) => LatLng(c[0], c[1])).toList();
      centerLoc = mapPoints.last;
    }

    markers = [
      // Only driver marker at current GPS position is shown
      Marker(
        point: driverLoc,
        width: 56,
        height: 56,
        child: driverMarker,
      ),
    ];

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Stack(
        children: [
          // 1. OpenStreetMap/GoogleMaps Layer
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: centerLoc,
              initialZoom: 14.5,
              maxZoom: 18.0,
              minZoom: 11.0,
            ),
            children: [
              ColorFiltered(
                colorFilter: ColorFilter.mode(
                  const Color(0xFF135B50).withOpacity(0.14),
                  BlendMode.color,
                ),
                child: TileLayer(
                  urlTemplate: mapUrlTemplate,
                  subdomains: const ['a', 'b', 'c', 'd'],
                  userAgentPackageName: 'com.fleetguard.driver',
                ),
              ),
              if (isTripActive && mapPoints.length > 1)
                PolylineLayer(
                  polylines: [
                    // Outer glow line
                    Polyline(
                      points: mapPoints,
                      color: AppColors.primary.withOpacity(0.25),
                      strokeWidth: 9.0,
                    ),
                    // Mid soft line
                    Polyline(
                      points: mapPoints,
                      color: AppColors.primary.withOpacity(0.55),
                      strokeWidth: 5.5,
                    ),
                    // Core sharp route
                    Polyline(
                      points: mapPoints,
                      color: AppColors.primary,
                      strokeWidth: 3.0,
                    ),
                  ],
                ),
              MarkerLayer(markers: markers),
            ],
          ),

          // 2. Floating Top Info Panel (Turn directions or standby state)
          Positioned(
            top: MediaQuery.of(context).padding.top + 16,
            left: 20,
            right: 20,
            child: Column(
              children: [
                if (isTripActive)
                  GlassCard(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withOpacity(0.08),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(Icons.turn_right, color: AppColors.primary, size: 24),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                "In 800 ft, take Exit 12B towards Silicon Valley",
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                tripProv.activeOrder != null
                                    ? "To: ${tripProv.activeOrder!.dropAddress}  •  ETA ~${tripProv.activeOrder!.estimatedTimeMinutes} min"
                                    : "ETA 10:48 AM  •  2.4 mi remaining",
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  )
                else
                  GlassCard(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        AnimatedBuilder(
                          animation: _pulseAnim,
                          builder: (_, __) => Icon(
                            Icons.my_location,
                            color: AppColors.primary.withOpacity(0.5 + 0.5 * _pulseAnim.value),
                            size: 16,
                          ),
                        ),
                        const SizedBox(width: 10),
                        const Text(
                          "GPS TELEMETRY ACTIVE • AWAITING DISPATCH",
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.0,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),

          // Map Style Toggle FAB
          Positioned(
            right: 16,
            bottom: widget.isEmbedded ? 250 : 210,
            child: GestureDetector(
              onTap: () {
                setState(() {
                  if (_mapStyle == 'm') {
                    _mapStyle = 'y'; // Hybrid
                  } else if (_mapStyle == 'y') {
                    _mapStyle = 's'; // Satellite
                  } else if (_mapStyle == 's') {
                    _mapStyle = 't'; // Terrain
                  } else {
                    _mapStyle = 'm'; // Roadmap
                  }
                });
              },
              child: Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.border),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.25),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Icon(
                  _mapStyle == 'm'
                      ? Icons.map
                      : _mapStyle == 'y'
                          ? Icons.layers
                          : _mapStyle == 's'
                              ? Icons.satellite_outlined
                              : Icons.terrain,
                  color: AppColors.primary,
                  size: 20,
                ),
              ),
            ),
          ),

          // Recenter FAB
          Positioned(
            right: 16,
            bottom: widget.isEmbedded ? 200 : 160,
            child: GestureDetector(
              onTap: () {
                _mapController.move(driverLoc, 15.0);
              },
              child: Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.border),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.25),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: const Icon(Icons.my_location, color: AppColors.primary, size: 20),
              ),
            ),
          ),

          // 3. Sliding Top Real-time Safety alert notifications (does NOT block map)
          Positioned(
            top: MediaQuery.of(context).padding.top + 16,
            left: 20,
            right: 20,
            child: SlideTransition(
              position: _alertOffset,
              child: _cachedAlert != null
                  ? GlassCard(
                      color: AppColors.surface.withOpacity(0.95),
                      borderSide: const BorderSide(color: AppColors.error, width: 1.5),
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: AppColors.error.withOpacity(0.12),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              _cachedAlert!.type == "Crash" ? Icons.error : Icons.warning_amber_rounded,
                              color: AppColors.error,
                              size: 24,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      _cachedAlert!.type.toUpperCase(),
                                      style: const TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.error,
                                        letterSpacing: 1.0,
                                      ),
                                    ),
                                    Text(
                                      _cachedAlert!.severity.toUpperCase(),
                                      style: const TextStyle(
                                        fontSize: 9,
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.textSecondary,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  "Sensor Reading: ${(_cachedAlert!.triggerValue * 9.8).toStringAsFixed(1)} m/s²",
                                  style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  "AI COACH: ${_cachedAlert!.aiTip}",
                                  style: const TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.primary,
                                    height: 1.3,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    )
                  : const SizedBox.shrink(),
            ),
          ),

          // 4. Immersive Driving HUD bottom overlay panels
          Positioned(
            left: 20,
            right: 20,
            bottom: widget.isEmbedded ? 104 : 24,
            child: Column(
              children: [
                // Live G-Force target grid & Speedometer floating cards
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // HUD Speedometer
                    GlassCard(
                      padding: const EdgeInsets.all(16),
                      borderRadius: 20,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            sensorProv.rawSpeed.toStringAsFixed(0),
                            style: TextStyle(
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                              color: sensorProv.rawSpeed > 65 ? AppColors.error : AppColors.textPrimary,
                            ),
                          ),
                          const Text(
                            "MPH",
                            style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.textSecondary),
                          ),
                        ],
                      ),
                    ),
                    
                    // Live Radar G-force Bubble
                    GlassCard(
                      padding: const EdgeInsets.all(10),
                      borderRadius: 20,
                      child: GForceMeter(
                        gx: sensorProv.gForceX,
                        gy: sensorProv.gForceY,
                        size: 90,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Core driving details block
                // Core driving details block (Styled matching reference)
                GlassCard(
                  padding: const EdgeInsets.all(18),
                  borderRadius: 24,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withOpacity(0.08),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: const Icon(
                              Icons.local_shipping_outlined,
                              color: AppColors.primary,
                              size: 24,
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  tripProv.activeOrder != null
                                      ? "Cargo Shipment ${tripProv.activeOrder!.id}"
                                      : "Active Standby Shift",
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  tripProv.activeOrder != null
                                      ? tripProv.activeOrder!.dropAddress
                                      : "Tracking G-forces and location streams",
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: AppColors.textSecondary,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      
                      // Reference design stats tags row
                      Row(
                        children: [
                          // Green Rating Pill
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(
                              color: const Color(0xFF10B981).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Row(
                              children: [
                                Icon(Icons.star, color: Color(0xFF10B981), size: 12),
                                SizedBox(width: 4),
                                Text(
                                  "4.9",
                                  style: TextStyle(
                                    color: Color(0xFF10B981),
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          // Distance Pill
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withOpacity(0.08),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.navigation, color: AppColors.primary, size: 12),
                                const SizedBox(width: 4),
                                Text(
                                  tripProv.activeOrder != null
                                      ? "${tripProv.activeOrder!.distanceKm} KM"
                                      : "1.8 KM",
                                  style: const TextStyle(
                                    color: AppColors.primary,
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          // Time Pill
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(
                              color: Colors.amber.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.timer_outlined, color: Colors.amber, size: 12),
                                const SizedBox(width: 4),
                                Text(
                                  tripProv.activeOrder != null
                                      ? "${tripProv.activeOrder!.estimatedTimeMinutes} MIN"
                                      : "12 MIN",
                                  style: const TextStyle(
                                    color: Colors.amber,
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const Divider(height: 28),

                      // Emergency SOS and Action Complete Buttons
                      Row(
                        children: [
                          // Clean Outline Red SOS
                          Expanded(
                            flex: 5,
                            child: OutlinedButton(
                              onPressed: () {
                                tripProv.triggerCrashSimulation();
                              },
                              style: OutlinedButton.styleFrom(
                                foregroundColor: AppColors.error,
                                side: const BorderSide(color: AppColors.error, width: 1.0),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(28),
                                ),
                                minimumSize: const Size(double.infinity, 52),
                              ),
                              child: const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.warning_amber_rounded, size: 16),
                                  SizedBox(width: 6),
                                  Text(
                                    "SOS ALERT",
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),

                          // Complete Trip/Exit HUD Button
                          Expanded(
                            flex: 5,
                            child: ElevatedButton(
                              onPressed: () {
                                if (isTripActive && !widget.isEmbedded) {
                                  tripProv.endTrip();
                                  Navigator.pushReplacementNamed(context, AppRoutes.summary);
                                } else if (!isTripActive && !widget.isEmbedded) {
                                  Navigator.pop(context);
                                }
                              },
                              style: ElevatedButton.styleFrom(
                                minimumSize: const Size(double.infinity, 52),
                              ),
                              child: Text(
                                (isTripActive ? "END TRIP" : "EXIT HUD"),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHudMetric(String label, String value, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 14, color: AppColors.primary),
        const SizedBox(width: 6),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: const TextStyle(fontSize: 8, fontWeight: FontWeight.bold, color: AppColors.textSecondary)),
            const SizedBox(height: 1),
            Text(value, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
          ],
        ),
      ],
    );
  }
}