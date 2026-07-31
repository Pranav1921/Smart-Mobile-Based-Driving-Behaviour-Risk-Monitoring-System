import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/constants/app_colors.dart';
import '../core/constants/app_strings.dart';
import '../providers/auth_provider.dart';
import '../providers/sensor_provider.dart';
import '../providers/trip_provider.dart';
import '../widgets/glass_card.dart';
import '../widgets/safety_score_ring.dart';
import '../widgets/delivery_animation.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final tripProv = Provider.of<TripProvider>(context);
    final sensorProv = Provider.of<SensorProvider>(context, listen: false);

    final profile = auth.profile;
    final isLight = Theme.of(context).brightness == Brightness.light;
    
    // Dynamic vehicle icon mapper
    IconData getVehicleIcon(String type) {
      final t = type.toLowerCase();
      if (t.contains('scooter') || t.contains('motorcycle') || t.contains('bike')) {
        return Icons.motorcycle_outlined;
      } else if (t.contains('truck') || t.contains('van')) {
        return Icons.local_shipping_outlined;
      }
      return Icons.directions_car_outlined;
    }

    // Time tab selection helper widget
    Widget _buildTimeTab(String label, {required bool isSelected}) {
      return Container(
        margin: const EdgeInsets.only(right: 12),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
            color: isSelected ? Colors.white : AppColors.textSecondary,
          ),
        ),
      );
    }

    // Invoice list item style selector helper widget
    Widget _buildInvoiceLogItem(
      BuildContext context, {
      required String title,
      required String subtitle,
      required String value,
      required IconData icon,
      required bool isSelected,
    }) {
      final cardColor = isSelected ? AppColors.primary : Colors.white;
      final titleColor = isSelected ? Colors.white : AppColors.textPrimary;
      final subtitleColor = isSelected ? Colors.white.withOpacity(0.7) : AppColors.textSecondary;
      final valueColor = isSelected ? Colors.white : AppColors.primary;
      final iconColor = isSelected ? Colors.white : AppColors.primary;
      final iconBg = isSelected ? Colors.white.withOpacity(0.12) : AppColors.primary.withOpacity(0.08);

      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? Colors.transparent : AppColors.border,
            width: 1.0,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(isSelected ? 0.12 : 0.03),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: iconBg,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: iconColor, size: 20),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: titleColor,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 11,
                      color: subtitleColor,
                    ),
                  ),
                ],
              ),
            ),
            Text(
              value,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: valueColor,
              ),
            ),
          ],
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.only(left: 20, right: 20, top: 24, bottom: 110),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Figma Welcome Header ────────────────────────────────
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        AppStrings.appName.toUpperCase(),
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.5,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        "${profile.name.toUpperCase()}  •  ${profile.companyCode} FLEET",
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.65),
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 6),
                      // Glowing neon line
                      Container(
                        width: 60,
                        height: 2,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [AppColors.primary, AppColors.secondary],
                          ),
                        ),
                      ),
                    ],
                  ),
                  // Online/Offline status pill
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: tripProv.isShiftActive 
                          ? AppColors.success.withOpacity(0.08) 
                          : AppColors.divider,
                      borderRadius: BorderRadius.circular(30),
                      border: Border.all(
                        color: tripProv.isShiftActive 
                            ? AppColors.success.withOpacity(0.3) 
                            : AppColors.border,
                        width: 1.0,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _PulsingDot(active: tripProv.isShiftActive),
                        const SizedBox(width: 6),
                        Text(
                          tripProv.isShiftActive ? "ONLINE" : "STANDBY",
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.8,
                            color: tripProv.isShiftActive 
                                ? AppColors.success 
                                : AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // ── Active Vehicle Specs Card (With realistic Indian License Plate!) ──
              GlassCard(
                padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppColors.divider,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColors.border, width: 1.0),
                      ),
                      child: AnimatedRotation(
                        turns: tripProv.isShiftActive ? 1.0 : 0.0,
                        duration: const Duration(seconds: 1),
                        curve: Curves.elasticOut,
                        child: Icon(
                          getVehicleIcon(profile.vehicleType),
                          size: 28,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            profile.vehicleName.toUpperCase(),
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w900,
                              color: Theme.of(context).colorScheme.onSurface,
                            ),
                          ),
                          const SizedBox(height: 5),
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(4),
                                  border: Border.all(color: Colors.black87, width: 1.2),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 1),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF0038FF),
                                        borderRadius: BorderRadius.circular(2),
                                      ),
                                      child: const Text(
                                        "IND",
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 6,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 5),
                                    Text(
                                      profile.vehiclePlateNumber.toUpperCase(),
                                      style: const TextStyle(
                                        color: Colors.black,
                                        fontSize: 10,
                                        fontWeight: FontWeight.w900,
                                        letterSpacing: 0.5,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 10),
                              Text(
                                profile.industry.toUpperCase(),
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w800,
                                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.65),
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
              const SizedBox(height: 16),

              // ── Tabbed Safety Index Spline Graph (Spendings Style Card matching reference) ──
              GlassCard(
                padding: const EdgeInsets.all(18),
                borderRadius: 24,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          "SAFETY TELEMETRY INDEX",
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            border: Border.all(color: AppColors.border, width: 1.0),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Row(
                            children: [
                              Text(
                                "Safety Score",
                                style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.textSecondary),
                              ),
                              SizedBox(width: 4),
                              Icon(Icons.keyboard_arrow_down, size: 12, color: AppColors.textSecondary),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    
                    Row(
                      children: [
                        _buildTimeTab("Day", isSelected: true),
                        _buildTimeTab("Week", isSelected: false),
                        _buildTimeTab("Month", isSelected: false),
                        _buildTimeTab("Year", isSelected: false),
                      ],
                    ),
                    const SizedBox(height: 24),

                    Stack(
                      alignment: Alignment.topCenter,
                      children: [
                        SizedBox(
                          height: 120,
                          width: double.infinity,
                          child: CustomPaint(
                            painter: _TelemetrySplinePainter(),
                          ),
                        ),
                        Positioned(
                          left: 110,
                          top: 10,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: AppColors.primary, width: 1.0),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.04),
                                  blurRadius: 4,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: const Text(
                              "Score: 98",
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: AppColors.primary,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 10),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text("Mar", style: TextStyle(fontSize: 10, color: AppColors.textMuted)),
                          Text("Apr", style: TextStyle(fontSize: 10, color: AppColors.textMuted)),
                          Text("May", style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.primary)),
                          Text("Jun", style: TextStyle(fontSize: 10, color: AppColors.textMuted)),
                          Text("Jul", style: TextStyle(fontSize: 10, color: AppColors.textMuted)),
                          Text("Aug", style: TextStyle(fontSize: 10, color: AppColors.textMuted)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // ── Safe Driving Drive Logs List (Invoice List Style matching reference) ──
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 4),
                child: Text(
                  "RECENT SAFE DRIVE LOGS",
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.0,
                    color: AppColors.primary,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              
              _buildInvoiceLogItem(
                context,
                title: "Reliance Logistics",
                subtitle: "Trip ID: UKW 3929",
                value: "+ 95 Pts",
                icon: Icons.opacity,
                isSelected: false,
              ),
              const SizedBox(height: 12),

              _buildInvoiceLogItem(
                context,
                title: "Shell Oil Dispatch",
                subtitle: "Trip ID: UKW 8221",
                value: "+ 98 Pts",
                icon: Icons.local_gas_station_outlined,
                isSelected: true,
              ),
              const SizedBox(height: 12),

              _buildInvoiceLogItem(
                context,
                title: "Ford Motors Parts",
                subtitle: "Trip ID: UKW 3012",
                value: "+ 92 Pts",
                icon: Icons.build_circle_outlined,
                isSelected: false,
              ),
              const SizedBox(height: 24),

              // ── Control Trigger Action CTA ────────────────────────────────────
              Column(
                children: [
                  GestureDetector(
                    onTap: () {
                      if (tripProv.isShiftActive) {
                        tripProv.endShift();
                        sensorProv.stopSensorMonitoring();
                      } else {
                        tripProv.startShift();
                        sensorProv.startSensorMonitoring();
                      }
                    },
                    child: Container(
                      width: double.infinity,
                      height: 56,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(28),
                        gradient: LinearGradient(
                          colors: tripProv.isShiftActive 
                              ? [AppColors.error, const Color(0xFFFF7B00)] 
                              : [AppColors.primary, AppColors.secondary],
                          begin: Alignment.centerLeft,
                          end: Alignment.centerRight,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: (tripProv.isShiftActive ? AppColors.error : AppColors.primary).withOpacity(0.35),
                            offset: const Offset(0, 6),
                            blurRadius: 20,
                            spreadRadius: -2,
                          ),
                        ],
                      ),
                      child: Center(
                        child: Text(
                          (tripProv.isShiftActive ? AppStrings.goOffline : AppStrings.goOnline).toUpperCase(),
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.5,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    tripProv.isShiftActive 
                        ? "ACTIVE SHIFT SYNCED IN TELEMETRY GRID"
                        : "SYSTEM STANDBY. START SHIFT FOR TELEMETRY DISPATCH",
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.8,
                      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.65),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PulsingDot extends StatefulWidget {
  final bool active;
  const _PulsingDot({required this.active});

  @override
  State<_PulsingDot> createState() => _PulsingDotState();
}

class _PulsingDotState extends State<_PulsingDot> with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _glow;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1200))..repeat(reverse: true);
    _glow = Tween<double>(begin: 3.0, end: 12.0).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _glow,
      builder: (context, child) {
        return Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: widget.active ? AppColors.success : Colors.grey,
            shape: BoxShape.circle,
            boxShadow: widget.active ? [
              BoxShadow(
                color: AppColors.success.withOpacity(0.6),
                blurRadius: _glow.value,
                spreadRadius: _glow.value / 4.5,
              )
            ] : null,
          ),
        );
      },
    );
  }
}

class _TelemetrySplinePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.primary
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round;

    final fillPaint = Paint()
      ..shader = LinearGradient(
        colors: [AppColors.primary.withOpacity(0.12), Colors.transparent],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height))
      ..style = PaintingStyle.fill;

    final path = Path();
    final fillPath = Path();

    // Spline curve coordinates
    final points = [
      Offset(0, size.height * 0.7),
      Offset(size.width * 0.2, size.height * 0.75),
      Offset(size.width * 0.4, size.height * 0.45),
      Offset(size.width * 0.52, size.height * 0.22), // Peak
      Offset(size.width * 0.7, size.height * 0.65),
      Offset(size.width * 0.85, size.height * 0.5),
      Offset(size.width, size.height * 0.4),
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
    fillPath.lineTo(0, size.height);
    fillPath.close();

    canvas.drawPath(fillPath, fillPaint);
    canvas.drawPath(path, paint);

    // Draw active dot at the peak
    final peakDot = points[3];
    final activeDotOuter = Paint()
      ..color = AppColors.primary.withOpacity(0.2)
      ..style = PaintingStyle.fill;
    final activeDotInner = Paint()
      ..color = AppColors.primary
      ..style = PaintingStyle.fill;

    canvas.drawCircle(peakDot, 12, activeDotOuter);
    canvas.drawCircle(peakDot, 5, activeDotInner);

    // Draw a dashed vertical lines under peak dot
    final dashPaint = Paint()
      ..color = AppColors.textMuted.withOpacity(0.5)
      ..strokeWidth = 1.0;

    double startY = peakDot.dy + 12;
    double endY = size.height;
    while (startY < endY) {
      canvas.drawLine(Offset(peakDot.dx, startY), Offset(peakDot.dx, startY + 4), dashPaint);
      startY += 8;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}