import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../core/theme/hardware_theme.dart';
import '../services/road_rules_service.dart';

class MunicipalRulesModal extends StatelessWidget {
  final String regionId;

  const MunicipalRulesModal({super.key, this.regionId = 'puttur_taluk'});

  static void show(BuildContext context, {String regionId = 'puttur_taluk'}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => MunicipalRulesModal(regionId: regionId),
    );
  }

  @override
  Widget build(BuildContext context) {
    final rules = RoadRulesService.getRegulationsForLocation(regionId: regionId);

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.85,
      ),
      decoration: BoxDecoration(
        color: HardwarePalette.chalkChassis,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          // Drag Handle
          const SizedBox(height: 12),
          Container(
            width: 36,
            height: 4,
            decoration: BoxDecoration(
              color: HardwarePalette.matrixBorderLight,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 14),

          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: Color(0xFFFF5722),
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          "MUNICIPAL RULES",
                          style: GoogleFonts.spaceGrotesk(
                            fontSize: 16,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1.0,
                            color: HardwarePalette.silkscreenDark,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      "${rules.cityName.toUpperCase()}, ${rules.district.toUpperCase()} • TRAFFIC BYLAWS",
                      style: GoogleFonts.spaceGrotesk(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: HardwarePalette.silkscreenSubtle,
                      ),
                    ),
                  ],
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: Icon(Icons.close_rounded, color: HardwarePalette.silkscreenDark),
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),
          Divider(height: 1, color: HardwarePalette.matrixBorderLight),

          // Scrollable Rules Body
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(18),
              children: [
                // 1. Core Speed Limits Card
                _buildSectionHeader("SPEED LIMIT REGULATIONS"),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: HardwarePalette.milledSurface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: HardwarePalette.matrixBorderLight),
                  ),
                  child: Column(
                    children: [
                      _buildSpeedRow(
                        icon: Icons.school_rounded,
                        label: "School & Academic Zone",
                        limit: "${rules.schoolZoneSpeedLimit.toInt()} KM/H",
                        color: const Color(0xFFFF5722),
                        fine: "₹1,000 Fine",
                      ),
                      const Divider(height: 18, color: Color(0xFFF1EFE9)),
                      _buildSpeedRow(
                        icon: Icons.local_hospital_rounded,
                        label: "Hospital Silence Zone",
                        limit: "${rules.hospitalZoneSpeedLimit.toInt()} KM/H",
                        color: const Color(0xFF0038FF),
                        fine: "No Honking",
                      ),
                      const Divider(height: 18, color: Color(0xFFF1EFE9)),
                      _buildSpeedRow(
                        icon: Icons.location_city_rounded,
                        label: "City Commercial & Arterial",
                        limit: "${rules.mainRoadSpeedLimit.toInt()} KM/H",
                        color: const Color(0xFF443F3C),
                        fine: "Standard",
                      ),
                      const Divider(height: 18, color: Color(0xFFF1EFE9)),
                      _buildSpeedRow(
                        icon: Icons.alt_route_rounded,
                        label: "Connecting State Highway",
                        limit: "${rules.highwaySpeedLimit.toInt()} KM/H",
                        color: const Color(0xFF059669),
                        fine: "Camera Monitored",
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 18),

                // 2. Mandatory Driver Bylaws
                _buildSectionHeader("MANDATORY SAFETY BYLAWS"),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: HardwarePalette.milledSurface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: HardwarePalette.matrixBorderLight),
                  ),
                  child: Column(
                    children: rules.mandatoryRules.map((rule) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 6),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(Icons.shield_outlined, size: 16, color: Color(0xFFFF5722)),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                rule,
                                style: GoogleFonts.spaceGrotesk(
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w600,
                                  color: HardwarePalette.silkscreenDark,
                                  height: 1.3,
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                ),

                const SizedBox(height: 18),

                // 3. Geofenced One-Way & Special Zones
                if (rules.oneWays.isNotEmpty) ...[
                  _buildSectionHeader("ACTIVE ONE-WAY CORRIDORS"),
                  const SizedBox(height: 8),
                  ...rules.oneWays.map((ow) {
                    return Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: HardwarePalette.milledSurface,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: HardwarePalette.matrixBorderLight),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFF5722).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(Icons.pan_tool_alt_rounded, size: 18, color: Color(0xFFFF5722)),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  ow.name,
                                  style: GoogleFonts.spaceGrotesk(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w800,
                                    color: HardwarePalette.silkscreenDark,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  "PERMITTED: ${ow.allowedDirection}",
                                  style: GoogleFonts.spaceGrotesk(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w700,
                                    color: const Color(0xFFFF5722),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                  const SizedBox(height: 10),
                ],

                // 4. Commercial Timing Notice
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF3E8FF),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFD8B4FE)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.local_shipping_outlined, size: 20, color: Color(0xFF7C3AED)),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          rules.heavyVehicleTimings,
                          style: GoogleFonts.spaceGrotesk(
                            fontSize: 10.5,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF5B21B6),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: GoogleFonts.spaceGrotesk(
        fontSize: 10.5,
        fontWeight: FontWeight.w900,
        letterSpacing: 0.8,
        color: HardwarePalette.silkscreenSubtle,
      ),
    );
  }

  Widget _buildSpeedRow({
    required IconData icon,
    required String label,
    required String limit,
    required Color color,
    required String fine,
  }) {
    return Row(
      children: [
        Icon(icon, size: 18, color: color),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: HardwarePalette.silkscreenDark,
                ),
              ),
              Text(
                fine,
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 9.5,
                  fontWeight: FontWeight.w600,
                  color: HardwarePalette.silkscreenSubtle,
                ),
              ),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: color.withOpacity(0.08),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: color.withOpacity(0.3)),
          ),
          child: Text(
            limit,
            style: GoogleFonts.spaceGrotesk(
              fontSize: 12,
              fontWeight: FontWeight.w900,
              color: color,
            ),
          ),
        ),
      ],
    );
  }
}
