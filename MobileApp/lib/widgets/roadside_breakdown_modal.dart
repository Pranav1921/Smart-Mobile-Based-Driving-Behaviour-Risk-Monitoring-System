import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../core/theme/hardware_theme.dart';
import '../providers/auth_provider.dart';
import '../providers/trip_provider.dart';
import '../services/haptic_service.dart';

class RoadsideBreakdownModal {
  static void show(BuildContext context) {
    HapticService.selectionClick();
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => const _RoadsideBreakdownSheet(),
    );
  }
}

class _RoadsideBreakdownSheet extends StatefulWidget {
  const _RoadsideBreakdownSheet();

  @override
  State<_RoadsideBreakdownSheet> createState() => _RoadsideBreakdownSheetState();
}

class _RoadsideBreakdownSheetState extends State<_RoadsideBreakdownSheet> {
  final TextEditingController _notesCtrl = TextEditingController();
  String? _selectedIssue;

  final List<Map<String, dynamic>> _issueTypes = [
    {
      'id': 'Tire Puncture / Flat',
      'icon': Icons.tire_repair_rounded,
      'title': 'Tire Puncture / Flat',
      'subtitle': 'Need mechanic / spare wheel swap',
      'color': Color(0xFFF59E0B),
    },
    {
      'id': 'Battery Dead / Jumpstart',
      'icon': Icons.battery_alert_rounded,
      'title': 'Battery Dead / Electrical',
      'subtitle': 'Need 12V jumpstart or new battery',
      'color': Color(0xFFEAB308),
    },
    {
      'id': 'Engine Overheating',
      'icon': Icons.thermostat_rounded,
      'title': 'Engine Overheating / Steam',
      'subtitle': 'Coolant leakage, vehicle smoking',
      'color': Color(0xFFEF4444),
    },
    {
      'id': 'Mechanical Stall / Towing',
      'icon': Icons.car_crash_rounded,
      'title': 'Mechanical Stall / Towing',
      'subtitle': 'Transmission / engine failure, flatbed needed',
      'color': Color(0xFFDC2626),
    },
  ];

  final List<Map<String, dynamic>> _nearestTowOperators = [
    {
      'name': 'Puttur 24x7 Highway Recovery & Hydraulic Towing',
      'location': 'Puttur Bypass / NH-275',
      'distance': '2.4 km away',
      'phone': '+919481255667',
      'displayPhone': '+91 94812 55667',
      'rating': '4.9 ★ (120+ rescues)',
      'eta': '10-12 mins',
      'type': 'Flatbed Crane & Wheel Lift',
    },
    {
      'name': 'Balaji Commercial Crane & Breakdown Assistance',
      'location': 'Mani-Puttur Junction (NH-75)',
      'distance': '4.1 km away',
      'phone': '+918251234890',
      'displayPhone': '+91 8251 234890',
      'rating': '4.8 ★ (85+ rescues)',
      'eta': '15-20 mins',
      'type': 'Heavy Commercial & Winch',
    },
    {
      'name': 'Dakshina Mobile Mechanic & Puncture Van',
      'location': 'Bolwar / Darbe Market',
      'distance': '1.8 km away',
      'phone': '+919845077123',
      'displayPhone': '+91 98450 77123',
      'rating': '4.9 ★ (210+ assists)',
      'eta': '8-10 mins',
      'type': '12V Jumpstart & Tire Swap',
    },
    {
      'name': 'NHAI Highway Emergency Patrol & Helpline',
      'location': 'National Highway Toll Plaza',
      'distance': 'Highway Unit Patrol',
      'phone': '1033',
      'displayPhone': '1033 (Toll Free)',
      'rating': 'Govt. Verified',
      'eta': '5-8 mins',
      'type': 'Free Patrol & Route Clearing',
    },
  ];

  Future<void> _makeCall(String phoneNumber) async {
    final clean = phoneNumber.replaceAll(RegExp(r'\s+'), '');
    final uri = Uri.parse('tel:$clean');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  Future<void> _openWhatsApp(String phoneNumber, String operatorName, TripProvider trip) async {
    final clean = phoneNumber.replaceAll(RegExp(r'\D'), '');
    final lat = trip.currentLat ?? 12.7749;
    final lng = trip.currentLng ?? 75.2023;
    final msg = "🚨 VEHICLE BREAKDOWN ASSISTANCE REQUIRED:\n"
        "Operator: $operatorName\n"
        "Issue: ${_selectedIssue ?? 'Vehicle Breakdown / Towing'}\n"
        "Location: https://maps.google.com/?q=$lat,$lng\n"
        "Please dispatch assistance immediately.";
    final uri = Uri.parse("https://wa.me/$clean?text=${Uri.encodeComponent(msg)}");
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    final trip = Provider.of<TripProvider>(context);

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.90,
      ),
      padding: EdgeInsets.fromLTRB(20, 16, 20, MediaQuery.of(context).viewInsets.bottom + 24),
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
          // Drag handle
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
          const SizedBox(height: 14),

          // Header
          Row(
            children: [
              Container(
                height: 44,
                width: 44,
                decoration: BoxDecoration(
                  color: const Color(0xFFFEF2F2),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFFEF4444).withOpacity(0.4)),
                ),
                child: const Icon(Icons.build_circle_rounded, color: Color(0xFFDC2626), size: 24),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "ROADSIDE BREAKDOWN & TOW SOS",
                      style: GoogleFonts.spaceGrotesk(
                        fontSize: 13,
                        fontWeight: FontWeight.w900,
                        color: HardwarePalette.silkscreenDark,
                        letterSpacing: 0.5,
                      ),
                    ),
                    Text(
                      "Instant Tow Truck, Crane & Mobile Mechanic Dispatch",
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
          const SizedBox(height: 14),

          Expanded(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "1. SELECT BREAKDOWN NATURE",
                    style: GoogleFonts.jetBrainsMono(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: HardwarePalette.silkscreenSubtle,
                      letterSpacing: 1.0,
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Issue Options
                  ...List.generate(_issueTypes.length, (idx) {
                    final item = _issueTypes[idx];
                    final isSelected = _selectedIssue == item['id'];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: InkWell(
                        onTap: () {
                          HapticService.selectionClick();
                          setState(() => _selectedIssue = item['id']);
                        },
                        borderRadius: BorderRadius.circular(16),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? (item['color'] as Color).withOpacity(0.12)
                                : HardwarePalette.chalkChassis,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: isSelected
                                  ? (item['color'] as Color)
                                  : HardwarePalette.matrixBorderLight,
                              width: isSelected ? 1.8 : 1.0,
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(item['icon'] as IconData, color: item['color'] as Color, size: 22),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      item['title'] as String,
                                      style: GoogleFonts.spaceGrotesk(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w800,
                                        color: HardwarePalette.silkscreenDark,
                                      ),
                                    ),
                                    Text(
                                      item['subtitle'] as String,
                                      style: GoogleFonts.spaceGrotesk(
                                        fontSize: 9.5,
                                        fontWeight: FontWeight.w500,
                                        color: HardwarePalette.silkscreenSubtle,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              if (isSelected)
                                Icon(Icons.check_circle_rounded, color: item['color'] as Color, size: 20),
                            ],
                          ),
                        ),
                      ),
                    );
                  }),
                  const SizedBox(height: 12),

                  // Additional Notes Field
                  Text(
                    "2. DETAILS / LANDMARK",
                    style: GoogleFonts.jetBrainsMono(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: HardwarePalette.silkscreenSubtle,
                      letterSpacing: 1.0,
                    ),
                  ),
                  const SizedBox(height: 6),
                  TextField(
                    controller: _notesCtrl,
                    style: GoogleFonts.spaceGrotesk(fontSize: 12, color: HardwarePalette.silkscreenDark),
                    decoration: InputDecoration(
                      hintText: "Landmark / additional breakdown details (optional)...",
                      hintStyle: GoogleFonts.spaceGrotesk(fontSize: 11, color: HardwarePalette.silkscreenSubtle),
                      filled: true,
                      fillColor: HardwarePalette.chalkChassis,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide(color: HardwarePalette.matrixBorderLight),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide(color: HardwarePalette.matrixBorderLight),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: const BorderSide(color: Color(0xFFDC2626), width: 1.5),
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),

                  // NEAREST TOW OPERATORS DIRECT CONTACT DIRECTORY
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "3. NEAREST TOW & CRANE SERVICES",
                        style: GoogleFonts.jetBrainsMono(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: HardwarePalette.silkscreenSubtle,
                          letterSpacing: 1.0,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFF10B981).withOpacity(0.12),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          "GPS VERIFIED",
                          style: GoogleFonts.jetBrainsMono(
                            fontSize: 8,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF10B981),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  ...List.generate(_nearestTowOperators.length, (i) {
                    final op = _nearestTowOperators[i];
                    return Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: HardwarePalette.chalkChassis,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: HardwarePalette.matrixBorderLight),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFEF4444).withOpacity(0.12),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: const Icon(Icons.car_repair_rounded, color: Color(0xFFDC2626), size: 18),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      op['name'] as String,
                                      style: GoogleFonts.spaceGrotesk(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w800,
                                        color: HardwarePalette.silkscreenDark,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Row(
                                      children: [
                                        Text(
                                          "${op['distance']} • ${op['eta']}",
                                          style: GoogleFonts.jetBrainsMono(
                                            fontSize: 9.5,
                                            fontWeight: FontWeight.bold,
                                            color: const Color(0xFFDC2626),
                                          ),
                                        ),
                                        const SizedBox(width: 6),
                                        Text(
                                          "(${op['type']})",
                                          style: GoogleFonts.spaceGrotesk(
                                            fontSize: 9,
                                            color: HardwarePalette.silkscreenSubtle,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              Expanded(
                                flex: 6,
                                child: InkWell(
                                  onTap: () {
                                    HapticService.selectionClick();
                                    _makeCall(op['phone'] as String);
                                  },
                                  borderRadius: BorderRadius.circular(10),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF10B981),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: FittedBox(
                                      fit: BoxFit.scaleDown,
                                      child: Row(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          const Icon(Icons.phone_in_talk_rounded, color: Colors.white, size: 13),
                                          const SizedBox(width: 4),
                                          Text(
                                            "Call: ${op['displayPhone']}",
                                            style: GoogleFonts.spaceGrotesk(
                                              fontSize: 10,
                                              fontWeight: FontWeight.w800,
                                              color: Colors.white,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              if ((op['phone'] as String).startsWith('+')) ...[
                                const SizedBox(width: 6),
                                Expanded(
                                  flex: 4,
                                  child: InkWell(
                                    onTap: () {
                                      HapticService.selectionClick();
                                      _openWhatsApp(op['phone'] as String, op['name'] as String, trip);
                                    },
                                    borderRadius: BorderRadius.circular(10),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF25D366),
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: FittedBox(
                                        fit: BoxFit.scaleDown,
                                        child: Row(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            const Icon(Icons.chat_rounded, color: Colors.white, size: 13),
                                            const SizedBox(width: 4),
                                            Text(
                                              "WhatsApp",
                                              style: GoogleFonts.spaceGrotesk(
                                                fontSize: 10,
                                                fontWeight: FontWeight.w800,
                                                color: Colors.white,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ],
                      ),
                    );
                  }),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Central Fleet HQ Dispatch Action Button
          ElevatedButton(
            onPressed: _selectedIssue == null
                ? null
                : () {
                    HapticService.heavyImpact();
                    final auth = Provider.of<AuthProvider>(context, listen: false);
                    final plate = auth.profile.vehiclePlateNumber.isNotEmpty ? auth.profile.vehiclePlateNumber : null;
                    trip.dispatchRoadsideBreakdown(
                      issueType: _selectedIssue!,
                      notes: _notesCtrl.text.trim().isNotEmpty ? _notesCtrl.text.trim() : null,
                      vehiclePlate: plate,
                    );
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Row(
                          children: [
                            const Icon(Icons.car_crash_rounded, color: Colors.white, size: 20),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                "TOW SOS DISPATCHED TO FLEET & LOCAL RECOVERY\nAssistance alerted for $_selectedIssue",
                                style: GoogleFonts.spaceGrotesk(fontWeight: FontWeight.w700, fontSize: 11),
                              ),
                            ),
                          ],
                        ),
                        backgroundColor: const Color(0xFFDC2626),
                        duration: const Duration(seconds: 4),
                        behavior: SnackBarBehavior.floating,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    );
                  },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFDC2626),
              disabledBackgroundColor: HardwarePalette.silkscreenSubtle.withOpacity(0.3),
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              elevation: 4,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.send_rounded, color: Colors.white, size: 16),
                const SizedBox(width: 8),
                Text(
                  "TRANSMIT TOW SOS TO FLEET HQ",
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
