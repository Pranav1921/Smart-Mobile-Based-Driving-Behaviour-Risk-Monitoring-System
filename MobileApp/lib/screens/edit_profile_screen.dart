import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mobile_app/providers/auth_provider.dart';
import 'package:mobile_app/core/theme/hardware_theme.dart';
import 'package:mobile_app/routes/app_routes.dart';
import 'package:mobile_app/services/haptic_service.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  late TextEditingController _nameCtrl;
  late TextEditingController _phoneCtrl;
  late TextEditingController _vehicleCtrl;
  late TextEditingController _plateCtrl;
  late TextEditingController _vehicleTypeCtrl;
  late TextEditingController _licenseCtrl;
  late TextEditingController _bloodGroupCtrl;

  // Family Information & WhatsApp Shield
  late TextEditingController _familyMemberCtrl;
  late TextEditingController _relationshipCtrl;
  late TextEditingController _familyWhatsappCtrl;
  late TextEditingController _familyAddressCtrl;

  @override
  void initState() {
    super.initState();
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final p = auth.profile;
    _nameCtrl = TextEditingController(text: p.name);
    _phoneCtrl = TextEditingController(text: p.phoneNumber.isNotEmpty ? p.phoneNumber : "+91 98451 20491");
    _vehicleCtrl = TextEditingController(text: p.vehicleName.isNotEmpty ? p.vehicleName : "Tata Ace EV / Delivery Van");
    _plateCtrl = TextEditingController(text: p.vehiclePlateNumber.isNotEmpty ? p.vehiclePlateNumber : "KA 19 MD 4022");
    _vehicleTypeCtrl = TextEditingController(text: p.vehicleType.isNotEmpty ? p.vehicleType : "Van");
    _licenseCtrl = TextEditingController(text: p.licenseNumber.isNotEmpty ? p.licenseNumber : "KA-19-2023-009841");
    _bloodGroupCtrl = TextEditingController(text: p.bloodGroup.isNotEmpty ? p.bloodGroup : "O+");

    _familyMemberCtrl = TextEditingController(
      text: p.familyMemberName.isNotEmpty ? p.familyMemberName : (p.emergencyContactName.isNotEmpty ? p.emergencyContactName : "Anjali Sharma"),
    );
    _relationshipCtrl = TextEditingController(text: p.familyRelationship.isNotEmpty ? p.familyRelationship : "Spouse");
    _familyWhatsappCtrl = TextEditingController(
      text: p.familyWhatsappNumber.isNotEmpty ? p.familyWhatsappNumber : (p.emergencyContactPhone.isNotEmpty ? p.emergencyContactPhone : "+91 94812 34567"),
    );
    _familyAddressCtrl = TextEditingController(
      text: p.familyAddress.isNotEmpty ? p.familyAddress : "Bappalige, Main Road, Puttur, Karnataka 574201",
    );
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _vehicleCtrl.dispose();
    _plateCtrl.dispose();
    _vehicleTypeCtrl.dispose();
    _licenseCtrl.dispose();
    _bloodGroupCtrl.dispose();
    _familyMemberCtrl.dispose();
    _relationshipCtrl.dispose();
    _familyWhatsappCtrl.dispose();
    _familyAddressCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    HapticService.mediumImpact();
    final auth = Provider.of<AuthProvider>(context, listen: false);

    await auth.updateFullProfile(
      name: _nameCtrl.text.trim(),
      phoneNumber: _phoneCtrl.text.trim(),
      vehicleName: _vehicleCtrl.text.trim(),
      vehiclePlateNumber: _plateCtrl.text.trim().toUpperCase(),
      vehicleType: _vehicleTypeCtrl.text.trim(),
      bloodGroup: _bloodGroupCtrl.text.trim().toUpperCase(),
      licenseNumber: _licenseCtrl.text.trim().toUpperCase(),
      familyMemberName: _familyMemberCtrl.text.trim(),
      familyRelationship: _relationshipCtrl.text.trim(),
      familyWhatsappNumber: _familyWhatsappCtrl.text.trim(),
      familyAddress: _familyAddressCtrl.text.trim(),
    );

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle_rounded, color: Colors.white, size: 20),
              const SizedBox(width: 8),
              Text(
                "Profile & Family WhatsApp Shield Updated!",
                style: GoogleFonts.spaceGrotesk(fontWeight: FontWeight.bold, fontSize: 12),
              ),
            ],
          ),
          backgroundColor: HardwarePalette.signalEmerald,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: HardwarePalette.chalkChassis,
      appBar: AppBar(
        backgroundColor: HardwarePalette.milledSurface,
        elevation: 0,
        toolbarHeight: 56,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: HardwarePalette.silkscreenDark, size: 20),
          onPressed: () {
            if (Navigator.canPop(context)) {
              Navigator.pop(context);
            } else {
              Navigator.pushReplacementNamed(context, AppRoutes.home);
            }
          },
        ),
        title: Text(
          "EDIT OPERATOR PROFILE",
          style: GoogleFonts.spaceGrotesk(
            color: HardwarePalette.silkscreenDark,
            fontWeight: FontWeight.w900,
            fontSize: 14,
            letterSpacing: 0.8,
          ),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1.0),
          child: Container(color: HardwarePalette.matrixBorderLight, height: 1.0),
        ),
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Section 1: Operator Identity
            _buildSectionHeader("OPERATOR IDENTITY", Icons.badge_outlined),
            const SizedBox(height: 12),
            _buildInput(_nameCtrl, "CALLSIGN / FULL NAME", Icons.person_outline_rounded),
            const SizedBox(height: 10),
            _buildInput(_phoneCtrl, "MOBILE CONTACT NUMBER", Icons.phone_android_rounded),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  flex: 3,
                  child: _buildInput(_licenseCtrl, "DRIVING LICENSE #", Icons.credit_card_rounded),
                ),
                const SizedBox(width: 10),
                Expanded(
                  flex: 2,
                  child: _buildInput(_bloodGroupCtrl, "BLOOD GROUP", Icons.water_drop_outlined),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Section 2: Fleet Vehicle Assignment
            _buildSectionHeader("FLEET VEHICLE SPECIFICATIONS", Icons.local_shipping_outlined),
            const SizedBox(height: 12),
            _buildInput(_vehicleCtrl, "ASSIGNED VEHICLE MODEL", Icons.directions_car_filled_outlined),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: _buildInput(_plateCtrl, "PLATE / REGISTRATION", Icons.pin_outlined),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _buildInput(_vehicleTypeCtrl, "VEHICLE CLASS", Icons.category_outlined),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Section 3: Family Information & WhatsApp Shield
            _buildSectionHeader("FAMILY EMERGENCY & WHATSAPP SHIELD", Icons.family_restroom_rounded, isHighlight: true),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: HardwarePalette.debossedSlot,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: HardwarePalette.matrixBorderLight),
              ),
              child: Row(
                children: [
                  const Icon(Icons.shield_outlined, color: Color(0xFF25D366), size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      "Your family receives direct instant live updates, trip safety telemetry, and emergency SOS pings via WhatsApp.",
                      style: GoogleFonts.spaceGrotesk(fontSize: 10.5, color: HardwarePalette.silkscreenSubtle, height: 1.3),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            _buildInput(_familyMemberCtrl, "FAMILY MEMBER NAME", Icons.person_add_alt_1_outlined),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  flex: 2,
                  child: _buildInput(_relationshipCtrl, "RELATIONSHIP", Icons.people_outline_rounded),
                ),
                const SizedBox(width: 10),
                Expanded(
                  flex: 3,
                  child: _buildInput(_familyWhatsappCtrl, "WHATSAPP NUMBER", Icons.chat_rounded, prefixWidget: const Text("+  ", style: TextStyle(color: Color(0xFF25D366), fontWeight: FontWeight.bold))),
                ),
              ],
            ),
            const SizedBox(height: 10),
            _buildInput(_familyAddressCtrl, "FAMILY RESIDENTIAL ADDRESS", Icons.home_outlined, maxLines: 2),
            const SizedBox(height: 30),

            // Save Button
            GestureDetector(
              onTap: _save,
              child: Container(
                height: 52,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: HardwarePalette.signalEmerald,
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: HardwarePalette.signalEmerald.withOpacity(0.35),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Center(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.check_rounded, color: Colors.white, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        'SAVE & SYNCHRONIZE PROFILE',
                        style: GoogleFonts.spaceGrotesk(
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1.0,
                          fontSize: 13,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon, {bool isHighlight = false}) {
    return Row(
      children: [
        Icon(
          icon,
          size: 16,
          color: isHighlight ? const Color(0xFF25D366) : HardwarePalette.signalEmerald,
        ),
        const SizedBox(width: 8),
        Text(
          title,
          style: GoogleFonts.spaceGrotesk(
            color: HardwarePalette.silkscreenDark,
            fontSize: 11,
            fontWeight: FontWeight.w900,
            letterSpacing: 0.8,
          ),
        ),
      ],
    );
  }

  Widget _buildInput(
    TextEditingController ctrl,
    String label,
    IconData icon, {
    int maxLines = 1,
    Widget? prefixWidget,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: HardwarePalette.milledSurface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: HardwarePalette.matrixBorderLight, width: 1.1),
      ),
      child: TextFormField(
        controller: ctrl,
        maxLines: maxLines,
        style: GoogleFonts.spaceGrotesk(
          fontWeight: FontWeight.w700,
          color: HardwarePalette.silkscreenDark,
          fontSize: 12.5,
        ),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: GoogleFonts.jetBrainsMono(
            fontWeight: FontWeight.w700,
            fontSize: 9.5,
            color: HardwarePalette.silkscreenSubtle,
            letterSpacing: 0.6,
          ),
          prefixIcon: Icon(icon, color: HardwarePalette.signalEmerald, size: 18),
          prefix: prefixWidget,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        ),
      ),
    );
  }
}

