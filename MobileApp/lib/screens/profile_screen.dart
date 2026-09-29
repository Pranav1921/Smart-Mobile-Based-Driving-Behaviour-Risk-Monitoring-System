import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../providers/auth_provider.dart';
import '../providers/trip_provider.dart';
import '../providers/theme_provider.dart';
import '../core/theme/hardware_theme.dart';
import '../routes/app_routes.dart';
import '../services/haptic_service.dart';
import '../services/sound_effect_service.dart';
import '../services/voice_service.dart';
import '../widgets/mechanical_lever_switch.dart';

class ProfileSheet extends StatefulWidget {
  final bool isEmbedded;
  const ProfileSheet({super.key, this.isEmbedded = false});

  @override
  State<ProfileSheet> createState() => _ProfileSheetState();
}

class _ProfileSheetState extends State<ProfileSheet> {
  bool _bgUsage = false;
  bool _biometricAuth = true;
  bool _emergencyOnlyVoice = true;
  bool _isOnLeave = false;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  void _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _bgUsage = prefs.getBool('sd_driver_bg_mode') ?? false;
      _isOnLeave = prefs.getBool('sd_driver_on_leave') ?? false;
      _emergencyOnlyVoice = VoiceService.emergencyOnlyMode;
    });
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final trip = Provider.of<TripProvider>(context);
    final theme = Provider.of<ThemeProvider>(context);
    final p = auth.profile;

    return Scaffold(
      backgroundColor: HardwarePalette.chalkChassis,
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 110),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ── 1. HARDWARE PASSPORT CARD ────────────────────────────
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: HardwarePalette.milledSurface,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: HardwarePalette.matrixBorderLight, width: 1.2),
                  boxShadow: [
                    BoxShadow(
                      color: HardwarePalette.isDark ? Colors.black.withOpacity(0.2) : Colors.black.withOpacity(0.04),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _buildScrewRivet(),
                        Text(
                          "DRIVER PASSPORT // CREDENTIAL SPEC",
                          style: GoogleFonts.jetBrainsMono(fontSize: 9.5, fontWeight: FontWeight.bold, color: HardwarePalette.silkscreenSubtle),
                        ),
                        _buildScrewRivet(),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Container(
                          width: 64,
                          height: 64,
                          decoration: BoxDecoration(
                            color: HardwarePalette.debossedSlot,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: HardwarePalette.matrixBorderLight),
                          ),
                          child: Center(
                            child: Text(
                              p.name.isNotEmpty ? p.name[0].toUpperCase() : "D",
                              style: HardwareTypography.ndotHeader(fontSize: 26, color: HardwarePalette.signalEmerald),
                            ),
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                p.name.isNotEmpty ? p.name.toUpperCase() : "DRIVER",
                                style: GoogleFonts.outfit(
                                  fontSize: 17,
                                  fontWeight: FontWeight.bold,
                                  color: HardwarePalette.silkscreenDark,
                                  letterSpacing: 0.3,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 3),
                              // Driver ID in small letters (lowercase)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                                decoration: BoxDecoration(
                                  color: HardwarePalette.isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(
                                    color: HardwarePalette.matrixBorderLight,
                                    width: 0.8,
                                  ),
                                ),
                                child: Text(
                                  (auth.driverCode ?? p.driverId).toLowerCase(),
                                  style: GoogleFonts.jetBrainsMono(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: HardwarePalette.signalEmerald,
                                    letterSpacing: 0.4,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              if (p.email.isNotEmpty) ...[
                                const SizedBox(height: 3),
                                Text(
                                  p.email.toLowerCase(),
                                  style: GoogleFonts.jetBrainsMono(
                                    fontSize: 10,
                                    color: HardwarePalette.silkscreenMuted,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                              const SizedBox(height: 6),
                              Row(
                                children: [
                                  Flexible(
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: HardwarePalette.debossedSlot,
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Text(
                                        p.companyCode.isNotEmpty ? p.companyCode : "FLEET-01",
                                        style: GoogleFonts.jetBrainsMono(
                                          fontSize: 9,
                                          fontWeight: FontWeight.bold,
                                          color: HardwarePalette.silkscreenDark,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Flexible(
                                    child: Text(
                                      p.vehiclePlateNumber.isNotEmpty ? p.vehiclePlateNumber.toUpperCase() : "KA 19 MD 4022",
                                      style: GoogleFonts.jetBrainsMono(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w900,
                                        color: HardwarePalette.signalEmerald,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Divider(height: 1, color: HardwarePalette.matrixBorderLight),
                    const SizedBox(height: 10),

                    // Quick Edit Profile Action Button
                    GestureDetector(
                      onTap: () {
                        HapticService.selectionClick();
                        Navigator.pushNamed(context, AppRoutes.editProfile);
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                        decoration: BoxDecoration(
                          color: HardwarePalette.debossedSlot,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: HardwarePalette.matrixBorderLight),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.edit_outlined, size: 14, color: HardwarePalette.signalEmerald),
                            const SizedBox(width: 6),
                            Text(
                              "EDIT PROFILE & VEHICLE SPECS",
                              style: GoogleFonts.spaceGrotesk(
                                fontSize: 10.5,
                                fontWeight: FontWeight.w800,
                                color: HardwarePalette.silkscreenDark,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),

              // ── 1.5 FAMILY INFORMATION & WHATSAPP SHIELD CARD ───────────
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: HardwarePalette.milledSurface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: HardwarePalette.matrixBorderLight, width: 1.2),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: const Color(0xFF25D366).withOpacity(0.12),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(Icons.family_restroom_rounded, color: Color(0xFF25D366), size: 16),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              "FAMILY WHATSAPP SHIELD",
                              style: GoogleFonts.spaceGrotesk(
                                fontSize: 11,
                                fontWeight: FontWeight.w900,
                                color: HardwarePalette.silkscreenDark,
                                letterSpacing: 0.6,
                              ),
                            ),
                          ],
                        ),
                        GestureDetector(
                          onTap: () {
                            HapticService.selectionClick();
                            Navigator.pushNamed(context, AppRoutes.editProfile);
                          },
                          child: Text(
                            "UPDATE",
                            style: GoogleFonts.spaceGrotesk(
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              color: HardwarePalette.signalEmerald,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                (p.familyMemberName.isNotEmpty ? p.familyMemberName : (p.emergencyContactName.isNotEmpty ? p.emergencyContactName : "Anjali Sharma")).toUpperCase(),
                                style: GoogleFonts.spaceGrotesk(fontSize: 13, fontWeight: FontWeight.w800, color: HardwarePalette.silkscreenDark),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                "${p.familyRelationship.isNotEmpty ? p.familyRelationship : 'Spouse'} • ${p.familyWhatsappNumber.isNotEmpty ? p.familyWhatsappNumber : (p.emergencyContactPhone.isNotEmpty ? p.emergencyContactPhone : '+91 94812 34567')}",
                                style: GoogleFonts.jetBrainsMono(fontSize: 10.5, color: HardwarePalette.silkscreenSubtle),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    if (p.familyAddress.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Text(
                        p.familyAddress,
                        style: GoogleFonts.spaceGrotesk(fontSize: 10, color: HardwarePalette.silkscreenMuted),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                    const SizedBox(height: 12),

                    // Direct WhatsApp Action Trigger
                    GestureDetector(
                      onTap: () async {
                        HapticService.heavyImpact();
                        final opened = await p.openFamilyWhatsapp();
                        if (!opened && context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                "Could not launch WhatsApp. Please check the WhatsApp number in Profile.",
                                style: GoogleFonts.spaceGrotesk(fontSize: 11),
                              ),
                              backgroundColor: HardwarePalette.terracottaRed,
                            ),
                          );
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        decoration: BoxDecoration(
                          color: const Color(0xFF25D366),
                          borderRadius: BorderRadius.circular(10),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF25D366).withOpacity(0.3),
                              blurRadius: 8,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.chat_rounded, color: Colors.white, size: 16),
                            const SizedBox(width: 8),
                            Text(
                              "MESSAGE FAMILY ON WHATSAPP",
                              style: GoogleFonts.spaceGrotesk(
                                fontSize: 11,
                                fontWeight: FontWeight.w900,
                                color: Colors.white,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // ── 2. MECHANICAL CONTROLS LEVERS ─────────────────────────
              Text(
                "HARDWARE & TELEMETRY LEVERS",
                style: GoogleFonts.jetBrainsMono(fontSize: 10.5, fontWeight: FontWeight.w800, color: HardwarePalette.silkscreenSubtle),
              ),
              const SizedBox(height: 10),

              MechanicalLeverSwitch(
                value: _bgUsage,
                label: "BACKGROUND SENSOR STREAMING",
                activeLabel: "ALWAYS ON (WAKE LOCK)",
                inactiveLabel: "FOREGROUND ONLY",
                onChanged: (v) async {
                  setState(() => _bgUsage = v);
                  final prefs = await SharedPreferences.getInstance();
                  await prefs.setBool('sd_driver_bg_mode', v);
                  auth.setAppUsageMode(v);
                },
              ),
              const SizedBox(height: 10),

              MechanicalLeverSwitch(
                value: _emergencyOnlyVoice,
                label: "VOICE ALERTS MODE",
                activeLabel: "EMERGENCY ONLY (SILENT DRIVE)",
                inactiveLabel: "ALL AUDIO ANNOUNCEMENTS",
                onChanged: (v) async {
                  setState(() => _emergencyOnlyVoice = v);
                  await VoiceService.setEmergencyOnlyMode(v);
                },
              ),
              const SizedBox(height: 10),

              MechanicalLeverSwitch(
                value: _biometricAuth,
                label: "BIOMETRIC AUTH SECURITY",
                activeLabel: "FINGERPRINT ARMED",
                inactiveLabel: "PIN ONLY",
                onChanged: (v) => setState(() => _biometricAuth = v),
              ),
              const SizedBox(height: 10),

              MechanicalLeverSwitch(
                value: _isOnLeave,
                label: "DUTY AVAILABILITY RELAY",
                activeLabel: "ON LEAVE // OFFLINE",
                inactiveLabel: "ACTIVE ON FLEET DUTY",
                activeColor: HardwarePalette.cautionAmber,
                onChanged: (v) async {
                  setState(() => _isOnLeave = v);
                  final prefs = await SharedPreferences.getInstance();
                  await prefs.setBool('sd_driver_on_leave', v);
                },
              ),
              const SizedBox(height: 20),

              // ── 3. SIGN OUT TACTILE BUTTON ───────────────────────────
              GestureDetector(
                onTap: () async {
                  HapticService.heavyImpact();
                  SoundEffectService.playRelayLatch();
                  await auth.logout();
                  if (context.mounted) {
                    Navigator.pushNamedAndRemoveUntil(context, AppRoutes.login, (route) => false);
                  }
                },
                child: Container(
                  height: 52,
                  decoration: BoxDecoration(
                    color: HardwarePalette.isDark ? const Color(0xFF2A1515) : const Color(0xFFFEF2F2),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: HardwarePalette.isDark ? const Color(0xFF7F1D1D) : const Color(0xFFFCA5A5),
                      width: 1.2,
                    ),
                  ),
                  child: Center(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.logout_rounded, color: Color(0xFFDC2626), size: 18),
                        const SizedBox(width: 8),
                        Text(
                          "LOGOUT",
                          style: GoogleFonts.spaceGrotesk(
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1.0,
                            color: const Color(0xFFDC2626),
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
      ),
    );
  }

  Widget _buildScrewRivet() {
    return Container(
      width: 10,
      height: 10,
      decoration: BoxDecoration(
        color: const Color(0xFFE2E8F0),
        shape: BoxShape.circle,
        border: Border.all(color: const Color(0xFFCBD5E1), width: 1.0),
      ),
      child: Center(
        child: Container(
          width: 4,
          height: 1,
          color: const Color(0xFF94A3B8),
        ),
      ),
    );
  }
}
