import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mobile_app/core/theme/neon_theme.dart';
import 'package:mobile_app/services/voice_service.dart';

class VehicleLaunchDialog extends StatefulWidget {
  final VoidCallback onComplete;
  final String driverName;
  final String vehicleName;

  const VehicleLaunchDialog({
    super.key,
    required this.onComplete,
    this.driverName = "Driver",
    this.vehicleName = "Fleet Vehicle",
  });

  static Future<void> show(BuildContext context, {required VoidCallback onComplete, String driverName = "Driver", String vehicleName = "Fleet Vehicle"}) {
    return showGeneralDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black.withOpacity(0.85),
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (ctx, anim1, anim2) => VehicleLaunchDialog(
        onComplete: onComplete,
        driverName: driverName,
        vehicleName: vehicleName,
      ),
    );
  }

  @override
  State<VehicleLaunchDialog> createState() => _VehicleLaunchDialogState();
}

class _VehicleLaunchDialogState extends State<VehicleLaunchDialog> with TickerProviderStateMixin {
  late AnimationController _mainCtrl;
  late AnimationController _roadCtrl;
  late AnimationController _pulseCtrl;

  late Animation<double> _carScaleAnim;
  late Animation<double> _carYAnim;
  late Animation<double> _rpmAnim;
  late Animation<double> _hudFadeAnim;

  int _currentStep = 0;
  final List<String> _statusMessages = [
    "INITIALIZING ENGINE...",
    "CALIBRATING 6-AXIS IMU SENSORS...",
    "CONNECTED TO GPS & DISPATCH...",
    "VEHICLE SYSTEMS ONLINE",
  ];

  @override
  void initState() {
    super.initState();

    _mainCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    );

    _roadCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    )..repeat();

    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);

    _carScaleAnim = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.5, end: 1.05).chain(CurveTween(curve: Curves.easeOutBack)), weight: 40),
      TweenSequenceItem(tween: Tween(begin: 1.05, end: 1.0).chain(CurveTween(curve: Curves.easeInOut)), weight: 20),
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.25).chain(CurveTween(curve: Curves.easeInCubic)), weight: 40),
    ]).animate(_mainCtrl);

    _carYAnim = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 40.0, end: 0.0).chain(CurveTween(curve: Curves.easeOutCubic)), weight: 40),
      TweenSequenceItem(tween: Tween(begin: 0.0, end: -6.0).chain(CurveTween(curve: Curves.easeInOut)), weight: 20),
      TweenSequenceItem(tween: Tween(begin: -6.0, end: -120.0).chain(CurveTween(curve: Curves.easeInCubic)), weight: 40),
    ]).animate(_mainCtrl);

    _rpmAnim = Tween<double>(begin: 0.0, end: 100.0).animate(
      CurvedAnimation(parent: _mainCtrl, curve: const Interval(0.1, 0.85, curve: Curves.easeOutExpo)),
    );

    _hudFadeAnim = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _mainCtrl, curve: const Interval(0.0, 0.3, curve: Curves.easeIn)),
    );

    _mainCtrl.addListener(() {
      final val = _mainCtrl.value;
      if (val < 0.25 && _currentStep != 0) {
        setState(() => _currentStep = 0);
      } else if (val >= 0.25 && val < 0.55 && _currentStep != 1) {
        setState(() => _currentStep = 1);
      } else if (val >= 0.55 && val < 0.80 && _currentStep != 2) {
        setState(() => _currentStep = 2);
      } else if (val >= 0.80 && _currentStep != 3) {
        setState(() => _currentStep = 3);
      }
    });

    _mainCtrl.forward().then((_) {
      VoiceService.speak("All systems active. Have a safe trip.");
      Future.delayed(const Duration(milliseconds: 300), () {
        if (mounted) {
          Navigator.of(context).pop();
          widget.onComplete();
        }
      });
    });
  }

  @override
  void dispose() {
    _mainCtrl.dispose();
    _roadCtrl.dispose();
    _pulseCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        alignment: Alignment.center,
        children: [
          // 1. Perspective Speed Road Grid Painter
          Positioned.fill(
            child: AnimatedBuilder(
              animation: _roadCtrl,
              builder: (context, child) {
                return CustomPaint(
                  painter: _PerspectiveRoadPainter(progress: _roadCtrl.value),
                );
              },
            ),
          ),

          // 2. HUD Circular Gauge & Telemetry Rings
          Positioned(
            top: MediaQuery.of(context).size.height * 0.16,
            child: FadeTransition(
              opacity: _hudFadeAnim,
              child: AnimatedBuilder(
                animation: _mainCtrl,
                builder: (context, child) {
                  return Stack(
                    alignment: Alignment.center,
                    children: [
                      // Outer Glowing Ring
                      Container(
                        width: 220,
                        height: 220,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: NeonColors.primaryGreen.withOpacity(0.25),
                            width: 1.5,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: NeonColors.primaryGreen.withOpacity(0.15),
                              blurRadius: 30,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                      ),

                      // Tachometer Arc
                      SizedBox(
                        width: 190,
                        height: 190,
                        child: CircularProgressIndicator(
                          value: _rpmAnim.value / 100.0,
                          strokeWidth: 4.5,
                          backgroundColor: Colors.white.withOpacity(0.06),
                          valueColor: const AlwaysStoppedAnimation<Color>(NeonColors.primaryGreen),
                        ),
                      ),

                      // Speed & Telemetry Center
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            "${(_rpmAnim.value * 0.8).toInt()}",
                            style: GoogleFonts.outfit(
                              fontSize: 54,
                              fontWeight: FontWeight.w900,
                              color: Colors.white,
                              letterSpacing: -1,
                            ),
                          ),
                          Text(
                            "KM/H",
                            style: GoogleFonts.spaceGrotesk(
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                              color: NeonColors.primaryGreen,
                              letterSpacing: 2,
                            ),
                          ),
                        ],
                      ),
                    ],
                  );
                },
              ),
            ),
          ),

          // 3. Dynamic Animated Vehicle Graphics with Volumetric Headlights
          Positioned(
            bottom: MediaQuery.of(context).size.height * 0.28,
            child: AnimatedBuilder(
              animation: _mainCtrl,
              builder: (context, child) {
                return Transform.translate(
                  offset: Offset(0, _carYAnim.value),
                  child: Transform.scale(
                    scale: _carScaleAnim.value,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        // Volumetric Light Cones
                        CustomPaint(
                          size: const Size(200, 140),
                          painter: _HeadlightsPainter(),
                        ),

                        // Vehicle Body & Chassis
                        Container(
                          width: 120,
                          height: 76,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFF1E293B), Color(0xFF0F172A)],
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                            ),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: NeonColors.primaryGreen.withOpacity(0.7),
                              width: 2.0,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: NeonColors.primaryGreen.withOpacity(0.4),
                                blurRadius: 20,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              // Windshield & Roof
                              Positioned(
                                top: 8,
                                child: Container(
                                  width: 74,
                                  height: 28,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF38BDF8).withOpacity(0.25),
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(color: const Color(0xFF38BDF8).withOpacity(0.5)),
                                  ),
                                  child: const Center(
                                    child: Icon(Icons.shield_rounded, color: Colors.white70, size: 16),
                                  ),
                                ),
                              ),

                              // Headlights Glowing Bulbs
                              Positioned(
                                top: 4,
                                left: 10,
                                child: Container(
                                  width: 14,
                                  height: 8,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFFDE047),
                                    borderRadius: BorderRadius.circular(4),
                                    boxShadow: const [BoxShadow(color: Color(0xFFFDE047), blurRadius: 10)],
                                  ),
                                ),
                              ),
                              Positioned(
                                top: 4,
                                right: 10,
                                child: Container(
                                  width: 14,
                                  height: 8,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFFDE047),
                                    borderRadius: BorderRadius.circular(4),
                                    boxShadow: const [BoxShadow(color: Color(0xFFFDE047), blurRadius: 10)],
                                  ),
                                ),
                              ),

                              // Grille / SmartDrive Emblem
                              Positioned(
                                bottom: 10,
                                child: Row(
                                  children: [
                                    Container(width: 8, height: 3, color: Colors.white54),
                                    const SizedBox(width: 4),
                                    Text(
                                      "SMARTDRIVE",
                                      style: GoogleFonts.spaceGrotesk(
                                        fontSize: 7.5,
                                        fontWeight: FontWeight.w900,
                                        color: NeonColors.primaryGreen,
                                        letterSpacing: 1,
                                      ),
                                    ),
                                    const SizedBox(width: 4),
                                    Container(width: 8, height: 3, color: Colors.white54),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),

          // 4. Bottom Telemetry HUD Status Stream
          Positioned(
            bottom: MediaQuery.of(context).size.height * 0.08,
            left: 32,
            right: 32,
            child: FadeTransition(
              opacity: _hudFadeAnim,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                decoration: BoxDecoration(
                  color: const Color(0xFF0D1117).withOpacity(0.9),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: NeonColors.primaryGreen.withOpacity(0.4), width: 1.2),
                  boxShadow: [
                    BoxShadow(
                      color: NeonColors.primaryGreen.withOpacity(0.12),
                      blurRadius: 16,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 8,
                              height: 8,
                              decoration: const BoxDecoration(
                                color: NeonColors.primaryGreen,
                                shape: BoxShape.circle,
                                boxShadow: [BoxShadow(color: NeonColors.primaryGreen, blurRadius: 6)],
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              "LAUNCH PROTOCOL ACTIVE",
                              style: GoogleFonts.spaceGrotesk(
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
                                color: NeonColors.primaryGreen,
                                letterSpacing: 0.8,
                              ),
                            ),
                          ],
                        ),
                        Text(
                          "STAGE ${_currentStep + 1}/4",
                          style: GoogleFonts.spaceGrotesk(
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            color: Colors.white70,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _statusMessages[_currentStep],
                      style: GoogleFonts.outfit(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                        letterSpacing: 0.2,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PerspectiveRoadPainter extends CustomPainter {
  final double progress;
  _PerspectiveRoadPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = NeonColors.primaryGreen.withOpacity(0.18)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    final horizonY = size.height * 0.45;
    final centerX = size.width / 2;

    // Road Outer Boundaries
    final path = Path();
    path.moveTo(centerX - 40, horizonY);
    path.lineTo(20, size.height);
    path.moveTo(centerX + 40, horizonY);
    path.lineTo(size.width - 20, size.height);
    canvas.drawPath(path, paint);

    // Center Speed Line Dashes (Zooming effect)
    final dashPaint = Paint()
      ..color = const Color(0xFFFDE047).withOpacity(0.6)
      ..strokeWidth = 3.0
      ..style = PaintingStyle.stroke;

    for (int i = 0; i < 6; i++) {
      final t = ((i / 6.0) + (progress * 0.2)) % 1.0;
      final startY = horizonY + math.pow(t, 2.2) * (size.height - horizonY);
      final endY = startY + 18.0 * (t + 0.3);
      if (startY < size.height) {
        canvas.drawLine(Offset(centerX, startY), Offset(centerX, math.min(endY, size.height)), dashPaint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _PerspectiveRoadPainter oldDelegate) => true;
}

class _HeadlightsPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final lightPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.bottomCenter,
        end: Alignment.topCenter,
        colors: [
          const Color(0xFFFDE047).withOpacity(0.35),
          const Color(0xFFFDE047).withOpacity(0.0),
        ],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    // Left Light Cone
    final leftBeam = Path()
      ..moveTo(size.width * 0.35, size.height * 0.5)
      ..lineTo(size.width * 0.15, 0)
      ..lineTo(size.width * 0.45, 0)
      ..close();
    canvas.drawPath(leftBeam, lightPaint);

    // Right Light Cone
    final rightBeam = Path()
      ..moveTo(size.width * 0.65, size.height * 0.5)
      ..lineTo(size.width * 0.55, 0)
      ..lineTo(size.width * 0.85, 0)
      ..close();
    canvas.drawPath(rightBeam, lightPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
