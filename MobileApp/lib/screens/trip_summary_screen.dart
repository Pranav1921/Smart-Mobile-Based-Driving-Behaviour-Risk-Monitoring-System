import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart' hide Path;
import 'package:latlong2/latlong.dart' hide Path;
import 'package:provider/provider.dart';
import '../core/constants/app_colors.dart';
import '../providers/trip_provider.dart';
import '../routes/app_routes.dart';
import '../widgets/glass_card.dart';

class TripSummaryScreen extends StatelessWidget {
  const TripSummaryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final tripProv = Provider.of<TripProvider>(context);
    final trip = tripProv.lastCompletedTrip;

    if (trip == null) {
      return Scaffold(
        backgroundColor: AppColors.background,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text("No active trip summary data found.", style: TextStyle(color: AppColors.textSecondary)),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () => Navigator.pushReplacementNamed(context, AppRoutes.home),
                child: const Text("Go Home"),
              ),
            ],
          ),
        ),
      );
    }

    final durationMin = (trip.durationSeconds / 60).toStringAsFixed(0);
    final brakingCount = trip.events.where((e) => e.type == 'Harsh Braking').length;
    final speedCount = trip.events.where((e) => e.type == 'Overspeed').length;
    final turnCount = trip.events.where((e) => e.type == 'Sharp Turn').length;

    List<LatLng> mapPoints = trip.routeCoordinates.map((c) => LatLng(c[0], c[1])).toList();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text("TRIP COMPLETED"),
        automaticallyImplyLeading: false,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.only(left: 20, right: 20, top: 10, bottom: 40),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Success Header Icon
              Center(
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.success.withOpacity(0.08),
                        shape: BoxShape.circle,
                        border: Border.all(color: AppColors.success, width: 1.5),
                      ),
                      child: const Icon(Icons.check, color: AppColors.success, size: 36),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      "Trip Completed Successfully",
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                    ),
                    Text(
                      "Shift ID: ${trip.id}",
                      style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 28),

              // Mini Route Replay Map
              if (mapPoints.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(bottom: 20),
                  child: GlassCard(
                    padding: EdgeInsets.zero,
                    height: 160,
                    child: Stack(
                      children: [
                        FlutterMap(
                          options: MapOptions(
                            initialCenter: mapPoints[mapPoints.length ~/ 2],
                            initialZoom: 12.5,
                            interactionOptions: const InteractionOptions(flags: InteractiveFlag.none),
                          ),
                          children: [
                            TileLayer(
                              urlTemplate: 'https://mt1.google.com/vt/lyrs=m&hl=en&x={x}&y={y}&z={z}',
                              subdomains: const ['a', 'b', 'c', 'd'],
                            ),
                            PolylineLayer(
                              polylines: [
                                Polyline(
                                  points: mapPoints,
                                  color: AppColors.secondary,
                                  strokeWidth: 3.5,
                                ),
                              ],
                            ),
                            MarkerLayer(
                              markers: [
                                Marker(
                                  point: mapPoints.first,
                                  width: 20,
                                  height: 20,
                                  child: const Icon(Icons.radio_button_checked, color: AppColors.secondary, size: 14),
                                ),
                                Marker(
                                  point: mapPoints.last,
                                  width: 20,
                                  height: 20,
                                  child: const Icon(Icons.location_on, color: AppColors.error, size: 14),
                                ),
                              ],
                            ),
                          ],
                        ),
                        // Light map gradient overlay to match our Swadeshi theme
                        Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [AppColors.primary.withOpacity(0.15), Colors.transparent],
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

              // Metrics Card Grid
              Row(
                children: [
                  Expanded(child: _buildSummaryMetric("DISTANCE", "${trip.distanceKm.toStringAsFixed(1)} KM")),
                  const SizedBox(width: 12),
                  Expanded(child: _buildSummaryMetric("TRIP TIME", "$durationMin MIN")),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(child: _buildSummaryMetric("MAX VELOCITY", "${trip.maxSpeed.toStringAsFixed(0)} MPH")),
                  const SizedBox(width: 12),
                  Expanded(child: _buildSummaryMetric("SAFETY SCORE", "${trip.safetyScore.toStringAsFixed(0)}%", isHighlight: true)),
                ],
              ),
              const SizedBox(height: 20),

              // Speed profile telemetry custom painted graph
              GlassCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "SPEED PROFILE TELEMETRY",
                      style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.textSecondary, letterSpacing: 1.0),
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      height: 100,
                      width: double.infinity,
                      child: CustomPaint(
                        painter: _SpeedGraphPainter(maxSpeed: trip.maxSpeed),
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text("Start of Trip", style: TextStyle(fontSize: 9, color: AppColors.textMuted)),
                        Text("Midpoint", style: TextStyle(fontSize: 9, color: AppColors.textMuted)),
                        Text("Destination", style: TextStyle(fontSize: 9, color: AppColors.textMuted)),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Safety Violations Breakdown list
              GlassCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "SAFETY telemetry VIOLATIONS",
                      style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.textSecondary, letterSpacing: 1.0),
                    ),
                    const SizedBox(height: 16),
                    _buildViolationCounterRow("Harsh Decelerations (Braking)", brakingCount),
                    const Divider(height: 12),
                    _buildViolationCounterRow("Overspeed Alert Warnings", speedCount),
                    const Divider(height: 12),
                    _buildViolationCounterRow("Cornering Peak G-Forces (Sharp Turns)", turnCount),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // AI Suggestion Coach Box
              GlassCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: const [
                        Icon(Icons.psychology, color: AppColors.secondary, size: 20),
                        SizedBox(width: 8),
                        Text(
                          "AI SMART COACH SUGGESTIONS",
                          style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: AppColors.secondary, letterSpacing: 0.5),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      brakingCount > 0 
                          ? "We detected $brakingCount points of abrupt deceleration. Try leaving a larger following gap behind cars in city zones."
                          : "Outstanding drive! Your deceleration curves are extremely clean and fuel-efficient. Keep doing what you're doing.",
                      style: TextStyle(
                        fontSize: 12.0,
                        color: AppColors.textPrimary.withOpacity(0.9),
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              // Finish summary action button (Styled Premium Tech Gradient)
              GestureDetector(
                onTap: () {
                  Navigator.pushReplacementNamed(context, AppRoutes.home);
                },
                child: Container(
                  height: 52,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(28),
                    gradient: const LinearGradient(
                      colors: [AppColors.primary, AppColors.secondary],
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withOpacity(0.3),
                        offset: const Offset(0, 6),
                        blurRadius: 20,
                        spreadRadius: -2,
                      ),
                    ],
                  ),
                  child: const Center(
                    child: Text(
                      "RETURN TO DASHBOARD",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.8,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryMetric(String label, String value, {bool isHighlight = false}) {
    return GlassCard(
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: AppColors.textSecondary)),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: isHighlight
                  ? (value.contains('9') || value.contains('10') ? AppColors.success : AppColors.warning)
                  : AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildViolationCounterRow(String eventName, int count) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          eventName,
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: count > 0 ? AppColors.error.withOpacity(0.12) : AppColors.card,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: count > 0 ? AppColors.error : AppColors.border),
          ),
          child: Text(
            "$count",
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: count > 0 ? AppColors.error : AppColors.textSecondary,
            ),
          ),
        ),
      ],
    );
  }
}

class _SpeedGraphPainter extends CustomPainter {
  final double maxSpeed;

  _SpeedGraphPainter({required this.maxSpeed});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.primary
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round;

    final fillPaint = Paint()
      ..shader = LinearGradient(
        colors: [AppColors.primary.withOpacity(0.18), Colors.transparent],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height))
      ..style = PaintingStyle.fill;

    final path = Path();
    final fillPath = Path();

    // Map speed points coordinates (simulate a driving wave profile)
    final points = [
      Offset(0, size.height),
      Offset(size.width * 0.15, size.height * 0.45),
      Offset(size.width * 0.35, size.height * 0.35),
      Offset(size.width * 0.5, size.height * 0.65),
      Offset(size.width * 0.7, size.height * 0.25),
      Offset(size.width * 0.85, size.height * 0.5),
      Offset(size.width, size.height * 0.85),
    ];

    path.moveTo(points.first.dx, points.first.dy);
    fillPath.moveTo(points.first.dx, points.first.dy);

    for (int i = 0; i < points.length - 1; i++) {
      final p1 = points[i];
      final p2 = points[i + 1];
      final controlX = p1.dx + (p2.dx - p1.dx) / 2;
      
      path.cubicTo(controlX, p1.dy, controlX, p2.dy, p2.dx, p2.dy);
      fillPath.cubicTo(controlX, p1.dy, controlX, p2.dy, p2.dx, p2.dy);
    }

    fillPath.lineTo(size.width, size.height);
    fillPath.close();

    canvas.drawPath(fillPath, fillPaint);
    canvas.drawPath(path, paint);

    // Draw baseline
    final linePaint = Paint()
      ..color = AppColors.border
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;
    canvas.drawLine(Offset(0, size.height), Offset(size.width, size.height), linePaint);
  }

  @override
  bool shouldRepaint(covariant _SpeedGraphPainter oldDelegate) {
    return oldDelegate.maxSpeed != maxSpeed;
  }
}