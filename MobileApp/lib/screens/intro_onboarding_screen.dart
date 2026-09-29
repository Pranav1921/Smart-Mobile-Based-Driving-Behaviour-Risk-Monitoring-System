import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../routes/app_routes.dart';
import '../core/theme/hardware_theme.dart';
import '../services/haptic_service.dart';

class IntroOnboardingScreen extends StatefulWidget {
  const IntroOnboardingScreen({super.key});

  @override
  State<IntroOnboardingScreen> createState() => _IntroOnboardingScreenState();
}

class _IntroOnboardingScreenState extends State<IntroOnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  static const _slides = [
    _OnboardSlide(
      image: 'assets/images/onboard1.jpg',
      title: 'Ride Smart.',
      subtitle: 'Real-time behaviour monitoring for every km you ride.',
    ),
    _OnboardSlide(
      image: 'assets/images/onboard2.jpg',
      title: 'Your Phone\nis the Sensor.',
      subtitle: 'Gyroscope, GPS & accelerometer detect every move.',
    ),
    _OnboardSlide(
      image: 'assets/images/onboard3.jpg',
      title: 'Family\nAlways Safe.',
      subtitle: 'Instant crash SOS alert to your guardian\'s phone.',
    ),
    _OnboardSlide(
      image: 'assets/images/onboard4.jpg',
      title: 'Ride Well,\nEarn More.',
      subtitle: 'Safe driving unlocks career rewards & performance perks.',
    ),
  ];

  void _onNext() {
    HapticService.lightImpact();
    if (_currentPage < _slides.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 380),
        curve: Curves.easeInOutCubic,
      );
    } else {
      Navigator.pushNamed(context, AppRoutes.register);
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isLast = _currentPage == _slides.length - 1;

    return Scaffold(
      backgroundColor: const Color(0xFFFAF9F7),
      body: SafeArea(
        child: Column(
          children: [
            // ── TOP BAR ─────────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Dot indicator row
                  Row(
                    children: List.generate(_slides.length, (i) {
                      final isActive = i == _currentPage;
                      return AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeInOut,
                        margin: const EdgeInsets.only(right: 5),
                        width: isActive ? 20 : 6,
                        height: 6,
                        decoration: BoxDecoration(
                          color: isActive
                              ? const Color(0xFF1E293B)
                              : const Color(0xFF1E293B).withValues(alpha: 0.18),
                          borderRadius: BorderRadius.circular(3),
                        ),
                      );
                    }),
                  ),

                  // Skip button (hidden on last slide)
                  if (!isLast)
                    GestureDetector(
                      onTap: () {
                        HapticService.lightImpact();
                        _pageController.animateToPage(
                          _slides.length - 1,
                          duration: const Duration(milliseconds: 400),
                          curve: Curves.easeInOutCubic,
                        );
                      },
                      child: Text(
                        'Skip',
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF1E293B).withValues(alpha: 0.45),
                        ),
                      ),
                    ),
                ],
              ),
            ),

            // ── SLIDE PAGES ─────────────────────────────────────────────────
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                physics: const BouncingScrollPhysics(),
                onPageChanged: (i) {
                  setState(() => _currentPage = i);
                  HapticService.selectionClick();
                },
                itemCount: _slides.length,
                itemBuilder: (context, index) {
                  return _buildSlide(_slides[index], index);
                },
              ),
            ),

            // ── BOTTOM ACTIONS ───────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // CTA Button
                  SizedBox(
                    width: double.infinity,
                    height: 54,
                    child: ElevatedButton(
                      onPressed: _onNext,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1E293B),
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            isLast ? 'Get Started' : 'Next',
                            style: GoogleFonts.inter(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(width: 6),
                          const Icon(Icons.arrow_forward_rounded, size: 17),
                        ],
                      ),
                    ),
                  ).animate().fadeIn(duration: 300.ms).slideY(begin: 0.08, end: 0),

                  const SizedBox(height: 16),

                  // Sign in link
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Already registered? ',
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          color: const Color(0xFF1E293B).withValues(alpha: 0.5),
                        ),
                      ),
                      GestureDetector(
                        onTap: () {
                          HapticService.lightImpact();
                          Navigator.pushReplacementNamed(context, AppRoutes.login);
                        },
                        child: Text(
                          'Log In',
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF1E293B),
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
    );
  }

  Widget _buildSlide(_OnboardSlide slide, int index) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── ILLUSTRATION (edge-to-edge, no letterbox) ─────────────────
        Expanded(
          flex: 5,
          child: Container(
            width: double.infinity,
            // Exact same cream as the illustration background → zero seam
            color: const Color(0xFFFAF9F5),
            child: Image.asset(
              slide.image,
              fit: BoxFit.cover,
              alignment: Alignment.center,
            ),
          )
          .animate(key: ValueKey('img_$index'))
          .fadeIn(duration: 400.ms)
          .scale(
            begin: const Offset(0.97, 0.97),
            end: const Offset(1, 1),
            duration: 400.ms,
            curve: Curves.easeOut,
          ),
        ),

        // ── TEXT ────────────────────────────────────────────────────────
        Expanded(
          flex: 3,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  slide.title,
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: 30,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF1E293B),
                    height: 1.15,
                  ),
                )
                .animate(key: ValueKey('title_$index'))
                .fadeIn(duration: 350.ms, delay: 80.ms)
                .slideY(
                  begin: 0.12,
                  end: 0,
                  duration: 350.ms,
                  delay: 80.ms,
                  curve: Curves.easeOut,
                ),

                const SizedBox(height: 10),

                Text(
                  slide.subtitle,
                  style: GoogleFonts.inter(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w400,
                    color: const Color(0xFF1E293B).withValues(alpha: 0.55),
                    height: 1.5,
                  ),
                )
                .animate(key: ValueKey('sub_$index'))
                .fadeIn(duration: 350.ms, delay: 140.ms)
                .slideY(
                  begin: 0.12,
                  end: 0,
                  duration: 350.ms,
                  delay: 140.ms,
                  curve: Curves.easeOut,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

}

class _OnboardSlide {
  final String image;
  final String title;
  final String subtitle;

  const _OnboardSlide({
    required this.image,
    required this.title,
    required this.subtitle,
  });
}
