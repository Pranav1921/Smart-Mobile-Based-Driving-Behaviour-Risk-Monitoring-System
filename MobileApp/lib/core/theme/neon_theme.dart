import 'package:flutter/material.dart';
import 'dart:ui';
import 'package:google_fonts/google_fonts.dart';

class NeonColors {
  // Premium Automotive Palette
  static const Color pureWhite = Color(0xFFFFFFFF);
  static const Color pureBlack = Color(0xFF000000);
  static const Color primaryGreen = Color(0xFFE53935); // Vivid automotive red accent (Racing Red)
  static const Color accentCyan = Color(0xFF38BDF8);   // Electric Cyan
  static const Color accentOrange = Color(0xFFF59E0B); // Warm Amber
  static const Color danger = Color(0xFFDC2626);       // Deep Crimson
  static const Color racingRed = Color(0xFFEF4444);    // High-voltage Racing Red
  static const Color crimsonGlow = Color(0xFFFF1744);  // Pulsing Laser Red

  // Accents
  static const Color green = primaryGreen;
  static const Color purple = Color(0xFFA78BFA);
  static const Color warning = accentOrange;
  static const Color yellow = Color(0xFFFACC15);
  static const Color roseAccent = Color(0xFFF43F5E);

  // Modern Dark Mode Surfaces
  static const Color darkBackground = Color(0xFF0B0F17);
  static const Color lightBackground = Color(0xFFF8FAFC);
  static const Color darkCard = Color(0xFF131B26);
  static const Color lightCard = Color(0xFFFFFFFF);
  static const Color darkText = Color(0xFFFFFFFF);
  static const Color lightText = Color(0xFF0F172A);
  static const Color darkSubtext = Color(0xFF94A3B8);
  static const Color lightSubtext = Color(0xFF64748B);

  static bool isDark = false;

  static Color get background => isDark ? darkBackground : lightBackground;
  static Color get card => isDark ? darkCard : lightCard;
  static Color get text => isDark ? darkText : lightText;
  static Color get subtext => isDark ? darkSubtext : lightSubtext;
  static Color get border => isDark ? Colors.white.withOpacity(0.08) : const Color(0xFFE2E8F0);
  static Color get darkGrey => isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9);
  static Color get backgroundBlack => isDark ? const Color(0xFF0B0F17) : const Color(0xFFF8FAFC);
  static Color get bgGray => background;
  static Color get subtextGray => subtext;
  static Color get surfaceMuted => isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.04);

  // Compatibility Aliases
  static const Color accent = green;
  static const Color secondary = accentCyan;
  static Color get success => green;
  static Color get neonGreen => green;
  static Color get neonBlue => accentCyan;
  static Color get neonRed => danger;
  static Color get neonYellow => yellow;
  static Color get accentAlt => purple;
}

class AppTypography {
  AppTypography._();

  static TextStyle display({double size = 26, FontWeight weight = FontWeight.w800, Color? color, double letterSpacing = -0.5}) {
    return GoogleFonts.outfit(
      fontSize: size,
      fontWeight: weight,
      color: color ?? NeonColors.text,
      letterSpacing: letterSpacing,
    );
  }

  static TextStyle heading({double size = 18, FontWeight weight = FontWeight.w700, Color? color, double letterSpacing = -0.2}) {
    return GoogleFonts.outfit(
      fontSize: size,
      fontWeight: weight,
      color: color ?? NeonColors.text,
      letterSpacing: letterSpacing,
    );
  }

  static TextStyle body({double size = 13, FontWeight weight = FontWeight.w500, Color? color, double? height}) {
    return GoogleFonts.plusJakartaSans(
      fontSize: size,
      fontWeight: weight,
      color: color ?? NeonColors.text,
      height: height,
    );
  }

  static TextStyle bodySmall({double size = 11, FontWeight weight = FontWeight.w500, Color? color, double? height}) {
    return GoogleFonts.plusJakartaSans(
      fontSize: size,
      fontWeight: weight,
      color: color ?? NeonColors.text,
      height: height,
    );
  }

  static TextStyle caption({double size = 10.5, FontWeight weight = FontWeight.w600, Color? color, double letterSpacing = 0.1}) {
    return GoogleFonts.plusJakartaSans(
      fontSize: size,
      fontWeight: weight,
      color: color ?? NeonColors.subtext,
      letterSpacing: letterSpacing,
    );
  }

  static TextStyle title({double size = 14, FontWeight weight = FontWeight.w700, Color? color}) {
    return GoogleFonts.plusJakartaSans(
      fontSize: size,
      fontWeight: weight,
      color: color ?? NeonColors.text,
    );
  }

  static TextStyle mono({double size = 13, FontWeight weight = FontWeight.w700, Color? color, double letterSpacing = 0.3}) {
    return GoogleFonts.spaceGrotesk(
      fontSize: size,
      fontWeight: weight,
      color: color ?? NeonColors.text,
      letterSpacing: letterSpacing,
    );
  }
}

class NeonTheme {
  // Sleek automotive card
  static BoxDecoration tacticalCard({Color? color, double radius = 20, bool shadow = true}) {
    return BoxDecoration(
      color: color ?? NeonColors.card,
      borderRadius: BorderRadius.circular(radius),
      border: Border.all(color: NeonColors.border, width: 1.0),
      boxShadow: [
        if (shadow)
          BoxShadow(
            color: Colors.black.withOpacity(NeonColors.isDark ? 0.25 : 0.04),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
      ],
    );
  }

  static BoxDecoration glowCard({Color? glowColor, double radius = 20}) {
    final color = glowColor ?? NeonColors.primaryGreen;
    return BoxDecoration(
      color: NeonColors.card,
      borderRadius: BorderRadius.circular(radius),
      border: Border.all(color: color.withOpacity(0.3), width: 1.0),
      boxShadow: [
        BoxShadow(
          color: color.withOpacity(0.10),
          blurRadius: 16,
          offset: const Offset(0, 4),
        ),
      ],
    );
  }

  static BoxDecoration brutalCard({Color? color, double radius = 18, Color? borderColor, double offset = 0}) {
    return BoxDecoration(
      color: color ?? NeonColors.card,
      borderRadius: BorderRadius.circular(radius),
      border: Border.all(color: borderColor ?? NeonColors.border, width: 1.0),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.06),
          blurRadius: 10,
          offset: const Offset(0, 2),
        ),
      ],
    );
  }

  static BoxDecoration brutalBtn({Color? color, double radius = 16}) {
    return BoxDecoration(
      color: color ?? NeonColors.primaryGreen,
      borderRadius: BorderRadius.circular(radius),
      boxShadow: [
        BoxShadow(
          color: (color ?? NeonColors.primaryGreen).withOpacity(0.2),
          blurRadius: 10,
          offset: const Offset(0, 3),
        ),
      ],
    );
  }

  static BoxDecoration glassCard({double radius = 20, Color? color}) {
    final bool isDark = NeonColors.isDark;
    return BoxDecoration(
      color: (color ?? (isDark ? const Color(0xFF131B26) : Colors.white)).withOpacity(isDark ? 0.75 : 0.90),
      borderRadius: BorderRadius.circular(radius),
      border: Border.all(color: isDark ? Colors.white.withOpacity(0.08) : Colors.black.withOpacity(0.05), width: 1.0),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(isDark ? 0.2 : 0.04),
          blurRadius: 16,
          offset: const Offset(0, 4),
        ),
      ],
    );
  }

  static Widget glass({required Widget child, double blur = 12, double radius = 20, Color? color}) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
        child: Container(
          decoration: glassCard(radius: radius, color: color),
          child: child,
        ),
      ),
    );
  }

  static TextStyle get heading => GoogleFonts.outfit(
    fontSize: 16,
    fontWeight: FontWeight.w800,
    color: NeonColors.text,
    letterSpacing: -0.3,
  );

  static TextStyle get subHeading => GoogleFonts.plusJakartaSans(
    fontSize: 13,
    fontWeight: FontWeight.w700,
    color: NeonColors.text,
  );

  static TextStyle get caption => GoogleFonts.plusJakartaSans(
    fontSize: 10.5,
    fontWeight: FontWeight.w600,
    color: NeonColors.subtext,
    letterSpacing: 0.1,
  );
}
