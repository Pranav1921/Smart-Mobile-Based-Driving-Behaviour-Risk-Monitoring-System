import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'neon_theme.dart';

/// Warm Creamy Skeuomorphic Retro-Minimalist Theme Tokens (Light)
/// & Sleek Cybernetic Tactical Automotive Surfaces (Dark)
abstract class HardwarePalette {
  static bool get isDark => NeonColors.isDark;

  // ── Blockit Neutral Chassis & Surfaces ──────────────────────────────────
  static Color get chalkChassis      => isDark ? const Color(0xFF0B0F17) : const Color(0xFFECEAE6);
  static Color get creamyBackground  => isDark ? const Color(0xFF0B0F17) : const Color(0xFFECEAE6);
  static Color get milledSurface     => isDark ? const Color(0xFF131B26) : const Color(0xFFFFFFFF);
  static Color get debossedSlot      => isDark ? const Color(0xFF1E293B) : const Color(0xFFE2DFDC);
  static Color get recessedTrack     => isDark ? const Color(0xFF1A2332) : const Color(0xFFDCD8D3);
  static Color get metalBezel        => isDark ? const Color(0xFF263346) : const Color(0xFFD4CDC0);
  static Color get charcoalDark      => isDark ? const Color(0xFF243042) : const Color(0xFF443F3C);

  // ── Structural Borders & Mechanical Rivets ─────────────────────────────
  static Color get matrixBorderLight => isDark ? const Color(0xFF1F2D40) : const Color(0xFFDCD6CA);
  static Color get borderHighlight   => isDark ? const Color(0xFF283950) : const Color(0xFFEAE5DB);
  static Color get mechanicalScrew   => isDark ? const Color(0xFF475569) : const Color(0xFFA89F91);
  static Color get screwHeadDark     => isDark ? const Color(0xFF64748B) : const Color(0xFF786F62);

  // ── High-Contrast Silkscreen Espresso / Charcoal Ink ───────────────────
  static Color get silkscreenDark    => isDark ? const Color(0xFFF1F5F9) : const Color(0xFF3D3835);
  static Color get silkscreenMuted   => isDark ? const Color(0xFF94A3B8) : const Color(0xFF6B6661);
  static Color get silkscreenSubtle  => isDark ? const Color(0xFF64748B) : const Color(0xFF8E8883);
  static const Color pureWhite       = Color(0xFFFFFFFF);

  // ── Hardware Signal Accents (Automotive Racing Red, Laser Crimson, Amber) ──────────
  static const Color terracottaRed   = Color(0xFFE53935); // Signature racing red accent
  static const Color criticalCrimson = Color(0xFFDC2626); // Deep laser crimson
  static const Color criticalRed     = Color(0xFFEF4444); // High-voltage hazard red
  static const Color signalEmerald   = Color(0xFFE53935); // Vivid automotive red signal accent
  static const Color neonActiveGreen = Color(0xFFDC2626); // Laser red active indicator
  static const Color hazardGlow      = Color(0xFFFF1744); // Electric neon red glow
  static const Color industrialAmber = Color(0xFFD97706); // Caution amber
  static const Color cautionAmber    = Color(0xFFD97706);
  static const Color cobaltBlue      = Color(0xFF2563EB); // Data link blue
  static const Color blockitOrange   = Color(0xFFE53935); // Signature red chassis dot accent
  static const Color crimsonImpact   = criticalCrimson;
  static const Color amberCaution    = cautionAmber;

  // ── Compatibility Aliases ──────────────────────────────────────────────
  static Color get obsidianChassis   => chalkChassis;
  static Color get charcoalSurface   => milledSurface;
  static Color get moduleCard        => milledSurface;
  static Color get debossedChassis   => debossedSlot;
  static Color get matrixBorder      => matrixBorderLight;
  static Color get ghostSegment      => isDark ? const Color(0xFF1E293B) : const Color(0xFFE5DFD4);
  static Color get chassisLabelDim   => silkscreenSubtle;
  static Color get chassisLabelMid   => silkscreenMuted;
  static Color get chassisLabelLight => silkscreenDark;
  static Color get textMuted         => silkscreenMuted;
  static Color get textDim           => silkscreenSubtle;
}

class HardwareTypography {
  HardwareTypography._();

  // ---------------------------------------------------------------------------
  // FONT 1: 'Silkscreen' / Digital Pixel Block Typography (Hero Digital Displays & Logo)
  // ---------------------------------------------------------------------------

  /// Chunky Pixel Block Numbers & Digital Timer
  static TextStyle pixelBlockNumber({
    double fontSize = 34,
    Color? color,
    FontWeight fontWeight = FontWeight.w900,
    double letterSpacing = 2.0,
  }) {
    return GoogleFonts.silkscreen(
      fontSize: fontSize,
      fontWeight: fontWeight,
      color: color ?? HardwarePalette.silkscreenDark,
      letterSpacing: letterSpacing,
    );
  }

  /// Pixel Block Logo & Header
  static TextStyle pixelHeader({
    double fontSize = 18,
    Color? color,
    FontWeight fontWeight = FontWeight.bold,
    double letterSpacing = 1.0,
  }) {
    return GoogleFonts.silkscreen(
      fontSize: fontSize,
      fontWeight: fontWeight,
      color: color ?? HardwarePalette.silkscreenDark,
      letterSpacing: letterSpacing,
    );
  }

  // ---------------------------------------------------------------------------
  // FONT 2: 'Space Grotesk' / Block Typography (Primary Headers, Numbers & Values)
  // ---------------------------------------------------------------------------

  /// Bold Block Header
  static TextStyle blockHeader({
    double fontSize = 16,
    Color? color,
    FontWeight fontWeight = FontWeight.w800,
    double letterSpacing = 0.8,
  }) {
    return GoogleFonts.spaceGrotesk(
      fontSize: fontSize,
      fontWeight: fontWeight,
      color: color ?? HardwarePalette.silkscreenDark,
      letterSpacing: letterSpacing,
    );
  }

  /// Big Bold Block Telemetry Numbers
  static TextStyle blockNumber({
    double fontSize = 32,
    Color? color,
    FontWeight fontWeight = FontWeight.w900,
    double letterSpacing = -0.5,
  }) {
    return GoogleFonts.spaceGrotesk(
      fontSize: fontSize,
      fontWeight: fontWeight,
      color: color ?? HardwarePalette.silkscreenDark,
      letterSpacing: letterSpacing,
    );
  }

  // ---------------------------------------------------------------------------
  // FONT 3: 'JetBrains Mono' (Technical Labels, Units, Specifications)
  // ---------------------------------------------------------------------------

  /// Silkscreen Technical Body
  static TextStyle jetBrainsBody({
    double fontSize = 12,
    Color? color,
    FontWeight fontWeight = FontWeight.w600,
    double height = 1.35,
  }) {
    return GoogleFonts.jetBrainsMono(
      fontSize: fontSize,
      fontWeight: fontWeight,
      color: color ?? HardwarePalette.silkscreenMuted,
      height: height,
    );
  }

  /// Silkscreen Label / Metadata
  static TextStyle jetBrainsLabel({
    double fontSize = 9.5,
    Color? color,
    FontWeight fontWeight = FontWeight.w700,
    double letterSpacing = 1.0,
  }) {
    return GoogleFonts.jetBrainsMono(
      fontSize: fontSize,
      fontWeight: fontWeight,
      color: color ?? HardwarePalette.silkscreenSubtle,
      letterSpacing: letterSpacing,
    );
  }

  // ---------------------------------------------------------------------------
  // Aliases for compatibility
  // ---------------------------------------------------------------------------
  static TextStyle ndotHeader({double fontSize = 15, Color? color, FontWeight fontWeight = FontWeight.w800, double letterSpacing = 1.0}) =>
      blockHeader(fontSize: fontSize, color: color, fontWeight: fontWeight, letterSpacing: letterSpacing);

  static TextStyle ndotTimer({double fontSize = 26, Color? color, FontWeight fontWeight = FontWeight.w900, double letterSpacing = 1.0}) =>
      blockNumber(fontSize: fontSize, color: color ?? HardwarePalette.signalEmerald, fontWeight: fontWeight, letterSpacing: letterSpacing);

  static TextStyle ndotNumber({double fontSize = 30, Color? color, FontWeight fontWeight = FontWeight.w900, double letterSpacing = -0.5}) =>
      blockNumber(fontSize: fontSize, color: color, fontWeight: fontWeight, letterSpacing: letterSpacing);

  static TextStyle outfitHeading({double fontSize = 16, Color? color, FontWeight fontWeight = FontWeight.bold, double letterSpacing = 0.5}) =>
      blockHeader(fontSize: fontSize, color: color, fontWeight: fontWeight, letterSpacing: letterSpacing);

  static TextStyle outfitSubheading({double fontSize = 13, Color? color, FontWeight fontWeight = FontWeight.w600}) =>
      jetBrainsBody(fontSize: fontSize, color: color, fontWeight: fontWeight);

  static TextStyle chassisLabel({double fontSize = 9.5, Color? color, FontWeight fontWeight = FontWeight.w700, double letterSpacing = 1.0}) =>
      jetBrainsLabel(fontSize: fontSize, color: color, fontWeight: fontWeight, letterSpacing: letterSpacing);

  static TextStyle telemetryMetric({double fontSize = 28, Color? color, FontWeight fontWeight = FontWeight.w800}) =>
      blockNumber(fontSize: fontSize, color: color ?? HardwarePalette.signalEmerald, fontWeight: fontWeight);

  static TextStyle digitalSegment({double fontSize = 30, Color? color}) =>
      blockNumber(fontSize: fontSize, color: color ?? HardwarePalette.signalEmerald);

  static TextStyle jetBrainsButton({double fontSize = 11, Color? color, FontWeight fontWeight = FontWeight.w800, double letterSpacing = 0.5}) =>
      GoogleFonts.spaceGrotesk(fontSize: fontSize, color: color ?? HardwarePalette.silkscreenDark, fontWeight: fontWeight, letterSpacing: letterSpacing);

  static TextStyle codeSpec({double fontSize = 11, Color? color}) =>
      jetBrainsBody(fontSize: fontSize, color: color);
}

class HardwareDeco {
  HardwareDeco._();

  /// Elevated Creamy Milled Card (Zero Drop Shadow, Clean Physical Borders)
  static BoxDecoration stampedCard({
    Color? backgroundColor,
    Color? borderColor,
    double radius = 16.0,
  }) {
    return BoxDecoration(
      color: backgroundColor ?? HardwarePalette.milledSurface,
      borderRadius: BorderRadius.circular(radius),
      border: Border.all(
        color: borderColor ?? HardwarePalette.matrixBorderLight,
        width: 1.2,
      ),
      boxShadow: [
        BoxShadow(
          color: HardwarePalette.isDark ? Colors.black.withOpacity(0.25) : const Color(0xFF23201C).withOpacity(0.04),
          blurRadius: 8,
          offset: const Offset(0, 3),
        ),
      ],
    );
  }

  /// Recessed Debossed Inset Groove
  static BoxDecoration debossedBezel({
    double radius = 12.0,
    Color? backgroundColor,
    Color? borderColor,
  }) {
    return BoxDecoration(
      color: backgroundColor ?? HardwarePalette.debossedSlot,
      borderRadius: BorderRadius.circular(radius),
      border: Border.all(
        color: borderColor ?? HardwarePalette.matrixBorderLight,
        width: 1.2,
      ),
    );
  }
}
