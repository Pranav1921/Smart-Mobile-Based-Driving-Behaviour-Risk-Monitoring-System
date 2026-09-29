import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../core/theme/hardware_theme.dart';
import '../services/haptic_service.dart';
import '../services/discovery_service.dart';

class GuardianShareModal {
  static void show(BuildContext context, {required String driverId, required String driverName}) {
    HapticService.selectionClick();
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => _GuardianShareSheet(driverId: driverId, driverName: driverName),
    );
  }
}

class _GuardianShareSheet extends StatelessWidget {
  final String driverId;
  final String driverName;

  const _GuardianShareSheet({required this.driverId, required this.driverName});

  @override
  Widget build(BuildContext context) {
    // Determine public tracking link host
    final host = DiscoveryService.currentHost.isNotEmpty
        ? DiscoveryService.currentHost
        : 'http://localhost:3000';
    // Replace port 3000 with dashboard port 5173 for client browser
    final dashboardHost = host.replaceAll(':3000', ':5173');
    final shareUrl = "$dashboardHost/track/$driverId";

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
      decoration: BoxDecoration(
        color: HardwarePalette.milledSurface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        border: Border.all(color: HardwarePalette.matrixBorderLight, width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Container(
              width: 44,
              height: 4,
              decoration: BoxDecoration(
                color: HardwarePalette.silkscreenSubtle.withOpacity(0.4),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Header
          Row(
            children: [
              Container(
                height: 44,
                width: 44,
                decoration: BoxDecoration(
                  color: const Color(0xFFECFDF5),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFF10B981).withOpacity(0.4)),
                ),
                child: const Icon(Icons.shield_rounded, color: Color(0xFF059669), size: 24),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "GUARDIAN ANGEL LIVE SHARE",
                      style: GoogleFonts.spaceGrotesk(
                        fontSize: 13,
                        fontWeight: FontWeight.w900,
                        color: HardwarePalette.silkscreenDark,
                        letterSpacing: 0.5,
                      ),
                    ),
                    Text(
                      "Allow family & clients to track trip safely",
                      style: GoogleFonts.spaceGrotesk(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: HardwarePalette.silkscreenSubtle,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: Icon(Icons.close_rounded, color: HardwarePalette.silkscreenSubtle),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Card with share URL
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: HardwarePalette.chalkChassis,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: HardwarePalette.matrixBorderLight),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "PUBLIC TELEMETRY TRACKING LINK",
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: 9,
                    fontWeight: FontWeight.w800,
                    color: HardwarePalette.silkscreenSubtle,
                  ),
                ),
                const SizedBox(height: 6),
                SelectableText(
                  shareUrl,
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF0284C7),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  "• No login required for family or clients\n• Real-time map breadcrumbs & speed\n• Automated safe arrival interlock\n• Emergency 112 / ambulance hotline links",
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: 10,
                    color: HardwarePalette.silkscreenDark,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Action Buttons
          ElevatedButton(
            onPressed: () {
              HapticService.selectionClick();
              Clipboard.setData(ClipboardData(text: shareUrl));
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Row(
                    children: [
                      const Icon(Icons.check_circle_rounded, color: Colors.white, size: 20),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          "LINK COPIED TO CLIPBOARD\nShare with family or customer via WhatsApp / SMS",
                          style: GoogleFonts.spaceGrotesk(fontWeight: FontWeight.w700, fontSize: 11),
                        ),
                      ),
                    ],
                  ),
                  backgroundColor: const Color(0xFF059669),
                  duration: const Duration(seconds: 3),
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF059669),
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              elevation: 4,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.copy_rounded, color: Colors.white, size: 16),
                const SizedBox(width: 8),
                Text(
                  "COPY TRACKING LINK",
                  style: GoogleFonts.spaceGrotesk(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    fontSize: 12,
                    letterSpacing: 1.0,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
