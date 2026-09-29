import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'neon_theme.dart';

class AppTheme {
  AppTheme._();

  static ThemeData get lightTheme {
    NeonColors.isDark = false;
    return _buildTheme(Brightness.light);
  }

  static ThemeData get darkTheme {
    NeonColors.isDark = true;
    return _buildTheme(Brightness.dark);
  }

  static ThemeData _buildTheme(Brightness brightness) {
    final bool isDark = brightness == Brightness.dark;
    final Color bg = isDark ? NeonColors.darkBackground : NeonColors.lightBackground;
    final Color card = isDark ? NeonColors.darkCard : NeonColors.lightCard;
    final Color txt = isDark ? NeonColors.darkText : NeonColors.lightText;
    final Color sub = isDark ? NeonColors.darkSubtext : NeonColors.lightSubtext;

    final baseTextTheme = isDark
        ? GoogleFonts.plusJakartaSansTextTheme(ThemeData.dark().textTheme)
        : GoogleFonts.plusJakartaSansTextTheme(ThemeData.light().textTheme);

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      scaffoldBackgroundColor: bg,
      primaryColor: NeonColors.primaryGreen,

      colorScheme: ColorScheme(
        brightness: brightness,
        primary: NeonColors.primaryGreen,
        onPrimary: Colors.white,
        secondary: const Color(0xFF38BDF8),
        onSecondary: Colors.white,
        error: NeonColors.danger,
        onError: Colors.white,
        surface: card,
        onSurface: txt,
      ),

      textTheme: baseTextTheme.copyWith(
        displayLarge: GoogleFonts.outfit(color: txt, fontWeight: FontWeight.w900, letterSpacing: -1, fontSize: 32),
        displayMedium: GoogleFonts.outfit(color: txt, fontWeight: FontWeight.w800, letterSpacing: -0.5, fontSize: 26),
        displaySmall: GoogleFonts.outfit(color: txt, fontWeight: FontWeight.w800, fontSize: 22),
        headlineLarge: GoogleFonts.outfit(color: txt, fontWeight: FontWeight.w800, fontSize: 20),
        headlineMedium: GoogleFonts.outfit(color: txt, fontWeight: FontWeight.w700, fontSize: 18),
        titleLarge: GoogleFonts.plusJakartaSans(color: txt, fontWeight: FontWeight.w800, fontSize: 16),
        titleMedium: GoogleFonts.plusJakartaSans(color: txt, fontWeight: FontWeight.w700, fontSize: 14),
        titleSmall: GoogleFonts.plusJakartaSans(color: txt, fontWeight: FontWeight.w600, fontSize: 12),
        bodyLarge: GoogleFonts.plusJakartaSans(color: txt, fontSize: 15, fontWeight: FontWeight.w500),
        bodyMedium: GoogleFonts.plusJakartaSans(color: sub, fontSize: 13, fontWeight: FontWeight.w500),
        bodySmall: GoogleFonts.plusJakartaSans(color: sub, fontSize: 11, fontWeight: FontWeight.w500),
        labelLarge: GoogleFonts.spaceGrotesk(color: txt, fontWeight: FontWeight.w800, fontSize: 12, letterSpacing: 0.5),
      ),

      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        foregroundColor: txt,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: GoogleFonts.outfit(
          fontSize: 18,
          fontWeight: FontWeight.w800,
          color: txt,
          letterSpacing: -0.2,
        ),
      ),

      cardTheme: CardThemeData(
        color: card,
        elevation: 0,
        shape: RoundedRectangleBorder(
          side: BorderSide(color: txt.withOpacity(0.06), width: 1),
          borderRadius: BorderRadius.circular(20),
        ),
      ),

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: NeonColors.primaryGreen,
          foregroundColor: Colors.white,
          minimumSize: const Size(double.infinity, 50),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          textStyle: GoogleFonts.plusJakartaSans(
            fontSize: 14,
            fontWeight: FontWeight.w800,
          ),
          elevation: 0,
        ),
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: card,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: txt.withOpacity(0.1)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: txt.withOpacity(0.1)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: NeonColors.primaryGreen, width: 1.5),
        ),
      ),
    );
  }
}
