import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';

import '../core/theme/hardware_theme.dart';
import '../providers/trip_provider.dart';
import '../providers/theme_provider.dart';
import '../services/haptic_service.dart';
import '../services/sound_effect_service.dart';
import '../widgets/tactical_sidebar.dart';
import 'history_screen.dart';
import 'home_screen.dart';
import 'orders_screen.dart';
import 'profile_screen.dart';
import 'trip_screen.dart';

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _currentIndex = 0;
  late PageController _pageController;

  final List<Widget> _screens = const [
    HomeScreen(),
    OrdersScreen(),
    TripScreen(isEmbedded: true),
    HistoryScreen(),
    ProfileSheet(isEmbedded: true),
  ];

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: _currentIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tripProv = Provider.of<TripProvider>(context);
    final themeProv = Provider.of<ThemeProvider>(context);

    return Scaffold(
      backgroundColor: HardwarePalette.chalkChassis,
      drawer: const TacticalSidebar(),
      body: Stack(
        children: [
          PageView(
            controller: _pageController,
            onPageChanged: (index) {
              setState(() {
                _currentIndex = index;
              });
            },
            physics: const NeverScrollableScrollPhysics(),
            children: _screens,
          ),

          // ── COMPACT CRASH / SOS NOTIFICATION POPUP ───────────────
          if (tripProv.showSOSConfirmation || tripProv.isCrashDetected)
            Positioned(
              left: 16,
              right: 16,
              bottom: 90,
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E1B18),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFFFF5722), width: 1.5),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFFF5722).withOpacity(0.25),
                      blurRadius: 18,
                      offset: const Offset(0, 4),
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
                          width: 10,
                          height: 10,
                          decoration: const BoxDecoration(
                            color: Color(0xFFFF5722),
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          "IMPACT / CRASH DETECTED",
                          style: GoogleFonts.spaceGrotesk(
                            fontSize: 12,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0.8,
                            color: Colors.white,
                          ),
                        ),
                        const Spacer(),
                        if (tripProv.sosCountdown > 0)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFF5722).withOpacity(0.2),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              "SOS in ${tripProv.sosCountdown}s",
                              style: GoogleFonts.spaceGrotesk(
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                                color: const Color(0xFFFF5722),
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      tripProv.crashReason,
                      style: GoogleFonts.spaceGrotesk(
                        fontSize: 11.5,
                        color: const Color(0xFFD6D3D1),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: GestureDetector(
                            onTap: () {
                              HapticService.selectionClick();
                              tripProv.cancelSOS();
                            },
                            child: Container(
                              height: 38,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Center(
                                child: Text(
                                  "I'M OK (DISMISS)",
                                  style: GoogleFonts.spaceGrotesk(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w800,
                                    color: const Color(0xFF1E1B18),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: GestureDetector(
                            onTap: () {
                              HapticService.heavyImpact();
                              tripProv.triggerManualSOS();
                            },
                            child: Container(
                              height: 38,
                              decoration: BoxDecoration(
                                color: const Color(0xFFFF5722),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Center(
                                child: Text(
                                  "SEND SOS NOW",
                                  style: GoogleFonts.spaceGrotesk(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w800,
                                    color: Colors.white,
                                  ),
                                ),
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

          // ── BLOCKIT FLOATING CAPSULE BOTTOM NAVIGATION BAR ─────────
          Positioned(
            left: 20,
            right: 20,
            bottom: 22,
            child: Container(
              height: 58,
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
              decoration: BoxDecoration(
                color: HardwarePalette.milledSurface,
                borderRadius: BorderRadius.circular(34),
                border: Border.all(color: HardwarePalette.matrixBorderLight, width: 1.0),
                boxShadow: [
                  BoxShadow(
                    color: HardwarePalette.isDark ? Colors.black.withOpacity(0.35) : const Color(0xFF23201C).withOpacity(0.10),
                    blurRadius: 20,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildBubbleNavItem(0, Icons.home_outlined, Icons.home_rounded, 0),
                  _buildBubbleNavItem(1, Icons.local_shipping_outlined, Icons.local_shipping_rounded, tripProv.availableOrders.length),
                  _buildBubbleNavItem(2, Icons.map_outlined, Icons.map_rounded, 0),
                  _buildBubbleNavItem(3, Icons.receipt_long_outlined, Icons.receipt_long_rounded, 0),
                  _buildBubbleNavItem(4, Icons.person_outline_rounded, Icons.person_rounded, 0),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBubbleNavItem(int index, IconData outlineIcon, IconData filledIcon, int badgeCount) {
    final isSelected = _currentIndex == index;

    return Expanded(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () {
          if (_currentIndex != index) {
            HapticService.selectionClick();
            SoundEffectService.playNotchTick();
            _pageController.jumpToPage(index);
          }
        },
        child: Center(
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOutCubic,
            width: isSelected ? 48 : 40,
            height: 40,
            decoration: BoxDecoration(
              color: isSelected
                  ? const Color(0xFFE53935)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(20),
              boxShadow: isSelected
                  ? [
                      BoxShadow(
                        color: const Color(0xFFE53935).withOpacity(0.40),
                        blurRadius: 10,
                        offset: const Offset(0, 3),
                      ),
                    ]
                  : null,
            ),
            child: Stack(
              clipBehavior: Clip.none,
              alignment: Alignment.center,
              children: [
                Icon(
                  isSelected ? filledIcon : outlineIcon,
                  color: isSelected
                      ? Colors.white
                      : (HardwarePalette.isDark ? const Color(0xFF94A3B8) : const Color(0xFF5A5450)),
                  size: 21,
                ),
                if (badgeCount > 0)
                  Positioned(
                    top: -4,
                    right: -4,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 4.5, vertical: 1.5),
                      constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEF4444),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.white, width: 1.5),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFFEF4444).withOpacity(0.5),
                            blurRadius: 4,
                            offset: const Offset(0, 1),
                          ),
                        ],
                      ),
                      child: Center(
                        child: Text(
                          badgeCount > 9 ? "9+" : "$badgeCount",
                          style: GoogleFonts.spaceGrotesk(
                            fontSize: 9,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                            height: 1.0,
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
