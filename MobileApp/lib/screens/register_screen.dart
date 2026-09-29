import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';

import '../providers/auth_provider.dart';
import '../routes/app_routes.dart';
import '../core/theme/hardware_theme.dart';
import '../services/haptic_service.dart';
import '../services/api_service.dart';
import '../widgets/realistic_vehicle_symbol.dart';
import 'package:flutter_animate/flutter_animate.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();

  // Personal Info
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();

  // Vehicle & License
  String _vehicleType = "Scooty";
  final _licenseNumberCtrl = TextEditingController(text: "KA1920210001234");
  String _selectedHub = "Puttur Hub";

  // Emergency Guardian
  String _emergencyRelationship = "Parent";
  final _emergencyNameCtrl = TextEditingController();
  final _emergencyPhoneCtrl = TextEditingController();
  String _selectedBloodGroup = "O+";

  bool _isSubmitting = false;
  Map<String, dynamic>? _submittedResult;
  Timer? _statusCheckTimer;
  bool _isApproved = false;
  String? _approvedDriverCode;
  String? _approvedTempPassword;

  List<VehicleOptionData> get _vehicles => RealisticVehicleData.allVehicles;

  // ── Cascading Location ──────────────────────────────────────────────
  static const Map<String, Map<String, List<String>>> _locationData = {
    "Karnataka": {
      "Dakshina Kannada": ["Mangaluru", "Puttur", "Kadaba", "Bantwal", "Sullia", "Belthangady", "Moodbidri"],
      "Udupi": ["Udupi", "Kundapur", "Karkala", "Brahmavar", "Byndoor"],
      "Bengaluru Urban": ["Bengaluru Central", "Bengaluru North", "Bengaluru South", "Bengaluru East", "Yelahanka"],
      "Bengaluru Rural": ["Doddaballapur", "Hoskote", "Devanahalli", "Nelamangala"],
      "Mysuru": ["Mysuru City", "Mandya", "K.R. Nagar", "Hunsur"],
      "Tumkuru": ["Tumkuru", "Tiptur", "Sira", "Madhugiri"],
      "Hassan": ["Hassan", "Sakleshpur", "Arsikere", "Channarayapatna"],
      "Shivamogga": ["Shivamogga", "Bhadravathi", "Sagar", "Tirthahalli"],
      "Uttara Kannada": ["Karwar", "Sirsi", "Kumta", "Honavar", "Ankola"],
    },
    "Maharashtra": {
      "Mumbai City": ["Fort", "Colaba", "Dharavi", "Kurla"],
      "Mumbai Suburban": ["Andheri", "Borivali", "Kandivali", "Goregaon", "Malad"],
      "Pune": ["Pune City", "Pimpri-Chinchwad", "Khadki", "Hadapsar", "Hinjewadi"],
      "Nashik": ["Nashik City", "Malegaon", "Nandgaon", "Sinnar"],
      "Nagpur": ["Nagpur City", "Wardha", "Kamptee", "Hingna"],
      "Aurangabad": ["Aurangabad City", "Jalna", "Paithan", "Gangapur"],
    },
    "Tamil Nadu": {
      "Chennai": ["Chennai Central", "Anna Nagar", "Adyar", "Tambaram", "Ambattur"],
      "Coimbatore": ["Coimbatore City", "Tiruppur", "Pollachi", "Mettupalayam"],
      "Madurai": ["Madurai City", "Dindigul", "Sivagangai", "Theni"],
      "Tiruchirappalli": ["Trichy City", "Karur", "Ariyalur", "Perambalur"],
      "Salem": ["Salem City", "Dharmapuri", "Namakkal", "Erode"],
    },
    "Kerala": {
      "Thiruvananthapuram": ["Thiruvananthapuram City", "Neyyattinkara", "Varkala", "Attingal"],
      "Ernakulam": ["Kochi City", "Aluva", "Angamaly", "Perumbavoor", "Muvattupuzha"],
      "Kozhikode": ["Kozhikode City", "Vadakara", "Koyilandy", "Feroke"],
      "Thrissur": ["Thrissur City", "Chalakudy", "Kunnamkulam", "Guruvayur"],
      "Palakkad": ["Palakkad City", "Ottapalam", "Shoranur", "Mannarkkad"],
      "Malappuram": ["Malappuram City", "Tirur", "Manjeri", "Perinthalmanna"],
      "Kasaragod": ["Kasaragod Town", "Hosdurg", "Kanhangad", "Uppala"],
    },
    "Telangana": {
      "Hyderabad": ["Secunderabad", "Banjara Hills", "Kukatpally", "LB Nagar", "Uppal"],
      "Rangareddy": ["Rajendranagar", "Shamshabad", "Chevella", "Maheshwaram"],
      "Medchal-Malkajgiri": ["Medchal", "Alwal", "Quthbullapur", "Malkajgiri"],
      "Warangal": ["Warangal City", "Hanamkonda", "Kazipet", "Jangaon"],
    },
    "Andhra Pradesh": {
      "Visakhapatnam": ["Vizag City", "Gajuwaka", "Bheemunipatnam", "Anakapalle"],
      "Krishna": ["Vijayawada", "Machilipatnam", "Gudivada", "Nuzvid"],
      "Guntur": ["Guntur City", "Tenali", "Narasaraopet", "Mangalagiri"],
      "Kurnool": ["Kurnool City", "Nandyal", "Adoni", "Yemmiganur"],
    },
    "Delhi": {
      "Central Delhi": ["Connaught Place", "Karol Bagh", "Paharganj"],
      "South Delhi": ["Saket", "Hauz Khas", "Lajpat Nagar", "Kalkaji"],
      "North Delhi": ["Civil Lines", "Model Town", "Mukherjee Nagar"],
      "East Delhi": ["Preet Vihar", "Mayur Vihar", "Laxmi Nagar"],
      "West Delhi": ["Rajouri Garden", "Janakpuri", "Dwarka", "Uttam Nagar"],
    },
    "Gujarat": {
      "Ahmedabad": ["Ahmedabad City", "Gandhinagar", "Sanand", "Dholka"],
      "Surat": ["Surat City", "Bardoli", "Olpad", "Kamrej"],
      "Vadodara": ["Vadodara City", "Padra", "Dabhoi", "Karjan"],
      "Rajkot": ["Rajkot City", "Gondal", "Jetpur", "Morbi"],
    },
  };

  String? _selectedState;
  String? _selectedDistrict;
  String? _selectedRegion;

  List<String> get _districts =>
      _selectedState != null ? _locationData[_selectedState]!.keys.toList() : [];

  List<String> get _regions =>
      (_selectedState != null && _selectedDistrict != null)
          ? _locationData[_selectedState]![_selectedDistrict]!
          : [];

  final List<String> _relationships = const [
    "Parent",
    "Spouse",
    "Sibling",
    "Guardian",
  ];

  final List<String> _bloodGroups = const ["O+", "A+", "B+", "AB+", "O-", "A-", "B-", "AB-"];

  @override
  void dispose() {
    _statusCheckTimer?.cancel();
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _phoneCtrl.dispose();
    _licenseNumberCtrl.dispose();
    _emergencyNameCtrl.dispose();
    _emergencyPhoneCtrl.dispose();
    super.dispose();
  }

  void _showToast(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg, style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600)),
        backgroundColor: HardwarePalette.criticalCrimson,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _startStatusPolling(String email, String trackingId) {
    _statusCheckTimer?.cancel();
    _statusCheckTimer = Timer.periodic(const Duration(seconds: 3), (timer) async {
      if (!mounted) {
        timer.cancel();
        return;
      }
      try {
        final statusRes = await ApiService.checkApplicationStatus(email, trackingId: trackingId);
        // Strictly require verified approval with assigned driver code from the administrator
        if (statusRes != null && statusRes['isApproved'] == true && statusRes['driverCode'] != null) {
          timer.cancel();
          if (mounted) {
            HapticService.success();
            setState(() {
              _isApproved = true;
              _approvedDriverCode = statusRes['driverCode'] as String? ?? 'DRV-PTR-2026-001';
              _approvedTempPassword = statusRes['tempPassword'] as String?;
            });
          }
        }
      } catch (_) {}
    });
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) {
      HapticService.error();
      return;
    }

    if (_nameCtrl.text.trim().isEmpty) {
      _showToast("Please enter your full name");
      return;
    }

    if (_emailCtrl.text.trim().isEmpty || !_emailCtrl.text.contains("@")) {
      _showToast("Please enter a valid email address to receive your credentials");
      return;
    }

    if (_phoneCtrl.text.trim().isEmpty) {
      _showToast("Please enter your phone number");
      return;
    }

    if (_licenseNumberCtrl.text.trim().length < 8) {
      _showToast("Please enter valid MoRTH Driving License (e.g. KA1920210001234)");
      return;
    }

    if (_emergencyPhoneCtrl.text.trim().isEmpty) {
      _showToast("Please enter emergency guardian phone number");
      return;
    }

    if (_selectedState == null) {
      _showToast("Please select your State");
      return;
    }

    if (_selectedDistrict == null) {
      _showToast("Please select your District");
      return;
    }

    if (_selectedRegion == null) {
      _showToast("Please select your Region / City");
      return;
    }

    HapticService.mediumImpact();
    setState(() => _isSubmitting = true);

    final auth = Provider.of<AuthProvider>(context, listen: false);

    final res = await auth.applyDriverApplication(
      name: _nameCtrl.text.trim(),
      email: _emailCtrl.text.trim(),
      phone: _phoneCtrl.text.trim(),
      zone: [_selectedState, _selectedDistrict, _selectedRegion]
          .whereType<String>()
          .join(', '),
      licenseNumber: _licenseNumberCtrl.text.trim().toUpperCase(),
      vehicleType: _vehicleType,
      emergencyName: _emergencyNameCtrl.text.trim().isNotEmpty ? _emergencyNameCtrl.text.trim() : "Parent / Family",
      emergencyPhone: _emergencyPhoneCtrl.text.trim(),
      familyRelationship: _emergencyRelationship,
    );

    if (!mounted) return;
    setState(() => _isSubmitting = false);

    final bool isHttpError = res != null && (res['__isHttpError'] == true || res['status'] == 'fail' || res['status'] == 'error');
    if (isHttpError) {
      HapticService.error();
      final errorMsg = res['message']?.toString() ?? "Registration failed. An account may already exist with this email.";
      _showToast(errorMsg);
      return;
    }

    if (res != null) {
      HapticService.success();
      final dataMap = (res['data'] is Map<String, dynamic>) ? (res['data'] as Map<String, dynamic>) : res;
      final tracking = dataMap['trackingId'] ?? dataMap['applicationId'] ?? "REQ-2026-${math.Random().nextInt(8999) + 1000}";
      setState(() {
        _isApproved = false; // Always starts in awaiting approval state
        _submittedResult = {
          "trackingId": tracking,
          "zone": [_selectedState, _selectedDistrict, _selectedRegion].whereType<String>().join(', '),
          "state": _selectedState ?? 'Karnataka',
          "district": _selectedDistrict ?? 'Dakshina Kannada',
          "region": _selectedRegion ?? 'Puttur',
          "email": _emailCtrl.text.trim(),
          "name": _nameCtrl.text.trim(),
          "phone": _phoneCtrl.text.trim(),
          "licenseNumber": _licenseNumberCtrl.text.trim().toUpperCase(),
          "vehicleType": _vehicleType,
        };
      });
      _startStatusPolling(_emailCtrl.text.trim(), tracking);
    } else {
      HapticService.error();
      _showToast("Submission failed. Please check network connection and try again.");
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_submittedResult != null) {
      return PopScope(
        canPop: Navigator.canPop(context),
        onPopInvokedWithResult: (didPop, result) {
          if (didPop) return;
          Navigator.pushReplacementNamed(context, AppRoutes.login);
        },
        child: _buildSuccessScreen(),
      );
    }

    return PopScope(
      canPop: Navigator.canPop(context),
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        Navigator.pushReplacementNamed(context, AppRoutes.login);
      },
      child: Scaffold(
        backgroundColor: HardwarePalette.chalkChassis,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: Icon(Icons.arrow_back_ios_new_rounded, color: HardwarePalette.silkscreenDark, size: 18),
            onPressed: () {
              HapticService.lightImpact();
              if (Navigator.canPop(context)) {
                Navigator.pop(context);
              } else {
                Navigator.pushReplacementNamed(context, AppRoutes.login);
              }
            },
          ),
        title: Text(
          "DRIVER REGISTRATION",
          style: GoogleFonts.jetBrainsMono(
            fontSize: 13,
            fontWeight: FontWeight.w800,
            color: HardwarePalette.silkscreenDark,
            letterSpacing: 1.2,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // ── HEADER CARD ──────────────────────────────────────────────
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: HardwarePalette.matrixBorderLight),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: HardwarePalette.signalEmerald.withValues(alpha: 0.12),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.badge_outlined,
                          color: HardwarePalette.signalEmerald,
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Parivahan Verification",
                              style: GoogleFonts.spaceGrotesk(
                                fontSize: 15,
                                fontWeight: FontWeight.w800,
                                color: HardwarePalette.silkscreenDark,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              "Enter your details. Upon authority approval, your Driver ID & password will be emailed to you.",
                              style: GoogleFonts.inter(
                                fontSize: 11,
                                color: HardwarePalette.silkscreenDark.withValues(alpha: 0.65),
                                height: 1.35,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // ── SECTION 1: PERSONAL DETAILS ──────────────────────────────
                _buildCardSection(
                  title: "1. Personal Information",
                  icon: Icons.person_outline_rounded,
                  children: [
                    _buildFieldLabel("FULL NAME (AS PER DL)"),
                    _buildTextField(
                      controller: _nameCtrl,
                      hint: "e.g. Rahul Sharma",
                      icon: Icons.person_outline_rounded,
                    ),
                    const SizedBox(height: 12),
                    _buildFieldLabel("EMAIL ADDRESS (FOR CREDENTIALS)"),
                    _buildTextField(
                      controller: _emailCtrl,
                      hint: "e.g. rahul.sharma@gmail.com",
                      icon: Icons.alternate_email_rounded,
                      keyboardType: TextInputType.emailAddress,
                    ),
                    Padding(
                      padding: const EdgeInsets.only(top: 4, left: 4),
                      child: Text(
                        "Important: Your Driver ID and password will be sent to this email.",
                        style: GoogleFonts.inter(
                          fontSize: 10.5,
                          color: HardwarePalette.silkscreenDark.withValues(alpha: 0.55),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    _buildFieldLabel("PHONE NUMBER"),
                    _buildTextField(
                      controller: _phoneCtrl,
                      hint: "e.g. 9876543210",
                      icon: Icons.phone_android_rounded,
                      keyboardType: TextInputType.phone,
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                // ── SECTION 2: VEHICLE & LICENSE ─────────────────────────────
                _buildCardSection(
                  title: "2. Vehicle & Driving License",
                  icon: Icons.two_wheeler_rounded,
                  children: [
                    _buildFieldLabel("VEHICLE TYPE & WHEEL CLASS"),
                    const SizedBox(height: 6),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      physics: const BouncingScrollPhysics(),
                      child: Row(
                        children: _vehicles.map((v) {
                          final isSelected = _vehicleType == v.type;
                          return GestureDetector(
                            onTap: () {
                              HapticService.selectionClick();
                              setState(() => _vehicleType = v.type);
                            },
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              width: 86,
                              margin: const EdgeInsets.only(right: 6),
                              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                              decoration: BoxDecoration(
                                color: isSelected ? HardwarePalette.silkscreenDark : HardwarePalette.debossedSlot,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: isSelected ? HardwarePalette.silkscreenDark : HardwarePalette.matrixBorderLight,
                                  width: isSelected ? 1.5 : 1.0,
                                ),
                                boxShadow: isSelected
                                    ? [
                                        BoxShadow(
                                          color: Colors.black.withValues(alpha: 0.12),
                                          blurRadius: 6,
                                          offset: const Offset(0, 2),
                                        )
                                      ]
                                    : null,
                              ),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  // Wheel Category Pill
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: isSelected
                                          ? Colors.white.withValues(alpha: 0.2)
                                          : HardwarePalette.matrixBorderLight.withValues(alpha: 0.6),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      "${v.wheelCount}-WHEEL",
                                      style: GoogleFonts.jetBrainsMono(
                                        fontSize: 8,
                                        fontWeight: FontWeight.w800,
                                        color: isSelected ? Colors.white : HardwarePalette.silkscreenSubtle,
                                        letterSpacing: 0.4,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  // Vehicle Name Label
                                  Text(
                                    v.label,
                                    textAlign: TextAlign.center,
                                    style: GoogleFonts.spaceGrotesk(
                                      fontSize: 11.5,
                                      fontWeight: FontWeight.w700,
                                      color: isSelected ? Colors.white : HardwarePalette.silkscreenDark,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                    const SizedBox(height: 14),

                    _buildFieldLabel("MORTH DRIVING LICENSE NUMBER"),
                    _buildTextField(
                      controller: _licenseNumberCtrl,
                      hint: "e.g. KA1920210001234",
                      icon: Icons.credit_card_rounded,
                      textCapitalization: TextCapitalization.characters,
                    ),
                    const SizedBox(height: 12),

                    // ── STATE ──────────────────────────────────────────────
                    _buildFieldLabel("STATE"),
                    _buildLocationDropdown(
                      hint: "Select State",
                      value: _selectedState,
                      items: _locationData.keys.toList(),
                      onChanged: (val) {
                        HapticService.selectionClick();
                        setState(() {
                          _selectedState = val;
                          _selectedDistrict = null;
                          _selectedRegion = null;
                        });
                      },
                    ),
                    const SizedBox(height: 12),

                    // ── DISTRICT ───────────────────────────────────────────
                    _buildFieldLabel("DISTRICT"),
                    _buildLocationDropdown(
                      hint: _selectedState == null ? "Select State first" : "Select District",
                      value: _selectedDistrict,
                      items: _districts,
                      enabled: _selectedState != null,
                      onChanged: (val) {
                        HapticService.selectionClick();
                        setState(() {
                          _selectedDistrict = val;
                          _selectedRegion = null;
                        });
                      },
                    ),
                    const SizedBox(height: 12),

                    // ── REGION / CITY ──────────────────────────────────────
                    _buildFieldLabel("REGION / CITY"),
                    _buildLocationDropdown(
                      hint: _selectedDistrict == null ? "Select District first" : "Select Region",
                      value: _selectedRegion,
                      items: _regions,
                      enabled: _selectedDistrict != null,
                      onChanged: (val) {
                        HapticService.selectionClick();
                        setState(() => _selectedRegion = val);
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                // ── SECTION 3: EMERGENCY GUARDIAN CONTACT ────────────────────
                _buildCardSection(
                  title: "3. Family Guardian SOS Contact",
                  icon: Icons.shield_outlined,
                  children: [
                    _buildFieldLabel("RELATIONSHIP"),
                    const SizedBox(height: 6),
                    Row(
                      children: _relationships.map((rel) {
                        final isSelected = _emergencyRelationship == rel;
                        return Expanded(
                          child: GestureDetector(
                            onTap: () {
                              HapticService.selectionClick();
                              setState(() => _emergencyRelationship = rel);
                            },
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              margin: const EdgeInsets.symmetric(horizontal: 2),
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              decoration: BoxDecoration(
                                color: isSelected ? HardwarePalette.silkscreenDark : HardwarePalette.debossedSlot,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: isSelected ? HardwarePalette.silkscreenDark : HardwarePalette.matrixBorderLight,
                                ),
                              ),
                              child: Center(
                                child: Text(
                                  rel,
                                  style: GoogleFonts.inter(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    color: isSelected ? Colors.white : HardwarePalette.silkscreenDark,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 12),

                    _buildFieldLabel("GUARDIAN / PARENT NAME"),
                    _buildTextField(
                      controller: _emergencyNameCtrl,
                      hint: "e.g. Suresh Sharma",
                      icon: Icons.family_restroom_rounded,
                    ),
                    const SizedBox(height: 12),

                    _buildFieldLabel("GUARDIAN EMERGENCY PHONE"),
                    _buildTextField(
                      controller: _emergencyPhoneCtrl,
                      hint: "e.g. 9845012345 (Receives Crash SOS)",
                      icon: Icons.phone_in_talk_rounded,
                      keyboardType: TextInputType.phone,
                    ),
                    const SizedBox(height: 12),

                    _buildFieldLabel("DRIVER BLOOD GROUP"),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: _bloodGroups.map((bg) {
                        final isSelected = _selectedBloodGroup == bg;
                        return GestureDetector(
                          onTap: () {
                            HapticService.selectionClick();
                            setState(() => _selectedBloodGroup = bg);
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: isSelected ? HardwarePalette.criticalCrimson : HardwarePalette.debossedSlot,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: isSelected ? HardwarePalette.criticalCrimson : HardwarePalette.matrixBorderLight,
                              ),
                            ),
                            child: Text(
                              bg,
                              style: GoogleFonts.jetBrainsMono(
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                                color: isSelected ? Colors.white : HardwarePalette.silkscreenDark,
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // ── SUBMIT BUTTON ────────────────────────────────────────────
                SizedBox(
                  height: 52,
                  child: ElevatedButton(
                    onPressed: _isSubmitting ? null : _handleSubmit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: HardwarePalette.silkscreenDark,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      elevation: 0,
                    ),
                    child: _isSubmitting
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                "SUBMIT APPLICATION",
                                style: GoogleFonts.jetBrainsMono(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 1.0,
                                ),
                              ),
                              const SizedBox(width: 8),
                              const Icon(Icons.arrow_forward_rounded, size: 16),
                            ],
                          ),
                  ),
                ),
                const SizedBox(height: 16),

                // ── LINK TO LOGIN ────────────────────────────────────────────
                Center(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        "Already have a Driver ID? ",
                        style: GoogleFonts.inter(
                          fontSize: 12.5,
                          color: HardwarePalette.silkscreenDark.withValues(alpha: 0.7),
                        ),
                      ),
                      GestureDetector(
                        onTap: () {
                          HapticService.lightImpact();
                          Navigator.pushReplacementNamed(context, AppRoutes.login);
                        },
                        child: Text(
                          "Sign In",
                          style: GoogleFonts.inter(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w800,
                            color: HardwarePalette.signalEmerald,
                            decoration: TextDecoration.underline,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}

  // ── REUSABLE HELPERS ───────────────────────────────────────────────────────
  Widget _buildCardSection({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: HardwarePalette.matrixBorderLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: HardwarePalette.signalEmerald),
              const SizedBox(width: 8),
              Text(
                title,
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: HardwarePalette.silkscreenDark,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          ...children,
        ],
      ),
    );
  }

  Widget _buildFieldLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4, left: 2),
      child: Text(
        label,
        style: GoogleFonts.jetBrainsMono(
          fontSize: 8.5,
          fontWeight: FontWeight.w700,
          color: HardwarePalette.silkscreenSubtle,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    TextCapitalization textCapitalization = TextCapitalization.none,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      textCapitalization: textCapitalization,
      style: GoogleFonts.spaceGrotesk(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: HardwarePalette.silkscreenDark,
      ),
      decoration: InputDecoration(
        filled: true,
        fillColor: HardwarePalette.debossedSlot,
        hintText: hint,
        hintStyle: GoogleFonts.spaceGrotesk(fontSize: 12, color: const Color(0xFF94A3B8)),
        prefixIcon: Icon(icon, color: HardwarePalette.silkscreenSubtle, size: 16),
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: HardwarePalette.matrixBorderLight),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: HardwarePalette.matrixBorderLight),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: HardwarePalette.silkscreenDark, width: 1.2),
        ),
      ),
    );
  }

  // ── SUCCESS CONFIRMATION VIEW ─────────────────────────────────────────────

  Widget _buildLocationDropdown({
    required String hint,
    required String? value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
    bool enabled = true,
  }) {
    return AnimatedOpacity(
      opacity: enabled ? 1.0 : 0.45,
      duration: const Duration(milliseconds: 200),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: enabled ? HardwarePalette.debossedSlot : HardwarePalette.debossedSlot.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: HardwarePalette.matrixBorderLight),
        ),
        child: DropdownButtonHideUnderline(
          child: DropdownButton<String>(
            value: value,
            isExpanded: true,
            dropdownColor: Colors.white,
            borderRadius: BorderRadius.circular(12),
            icon: Icon(
              Icons.keyboard_arrow_down_rounded,
              color: enabled ? HardwarePalette.silkscreenDark : HardwarePalette.silkscreenSubtle,
              size: 20,
            ),
            hint: Text(
              hint,
              style: GoogleFonts.spaceGrotesk(fontSize: 12, color: const Color(0xFF94A3B8)),
            ),
            items: items.map((item) {
              return DropdownMenuItem<String>(
                value: item,
                child: Text(
                  item,
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                    color: HardwarePalette.silkscreenDark,
                  ),
                ),
              );
            }).toList(),
            onChanged: enabled ? onChanged : null,
          ),
        ),
      ),
    );
  }

  Widget _buildSuccessScreen() {
    final trackingId = _submittedResult?['trackingId'] ?? '#REQ-2026';
    final hubName = _submittedResult?['zone'] ?? 'Regional Hub';
    final email = _submittedResult?['email'] ?? 'your email';
    final name = _submittedResult?['name'] ?? 'Driver';
    final licenseNumber = _submittedResult?['licenseNumber'] ?? '';
    final vehicleType = _submittedResult?['vehicleType'] ?? 'Scooty';
    final driverCode = _approvedDriverCode ?? 'DRV-PTR-2026-001';

    return Scaffold(
      backgroundColor: HardwarePalette.chalkChassis,
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: _isApproved ? const Color(0xFF10B981) : HardwarePalette.matrixBorderLight, 
                width: _isApproved ? 2.0 : 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: _isApproved ? const Color(0xFF10B981).withValues(alpha: 0.12) : Colors.black.withValues(alpha: 0.04),
                  blurRadius: 18,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: _isApproved 
              ? Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // ── APPROVED CELEBRATION ICON ─────────────────────────
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: const Color(0xFF10B981).withValues(alpha: 0.15),
                        border: Border.all(color: const Color(0xFF10B981), width: 3),
                      ),
                      child: const Center(
                        child: Icon(Icons.check_circle_rounded, size: 48, color: Color(0xFF059669)),
                      ),
                    )
                        .animate()
                        .scale(duration: 500.ms, curve: Curves.easeOutBack)
                        .shimmer(duration: 1200.ms, color: Colors.white70),
                    const SizedBox(height: 12),

                    // ── APPROVED STATUS BADGE ─────────────────────────────
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                      decoration: BoxDecoration(
                        color: const Color(0xFFD1FAE5),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: const Color(0xFF10B981)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.verified_rounded, size: 13, color: Color(0xFF059669)),
                          const SizedBox(width: 5),
                          Text(
                            "APPLICATION APPROVED & CONFIRMED! ✅",
                            style: GoogleFonts.jetBrainsMono(
                              fontSize: 9.5,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 0.5,
                              color: const Color(0xFF065F46),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 10),

                    // ── TITLE & SUBTITLE ─────────────────────────────────
                    Text(
                      "ACCOUNT ACTIVE & VERIFIED",
                      textAlign: TextAlign.center,
                      style: GoogleFonts.spaceGrotesk(
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -0.5,
                        color: const Color(0xFF065F46),
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      "Your regional administrator has verified your Parivahan DL records and granted active fleet access.",
                      textAlign: TextAlign.center,
                      style: GoogleFonts.inter(
                        fontSize: 11.5,
                        color: HardwarePalette.silkscreenDark.withValues(alpha: 0.72),
                        height: 1.35,
                      ),
                    ),
                    const SizedBox(height: 14),

                    // ── ASSIGNED DRIVER ID DISPLAY CARD ──────────────────
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF064E3B), Color(0xFF065F46)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF059669).withValues(alpha: 0.3),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          Text(
                            "YOUR ASSIGNED DRIVER ID",
                            style: GoogleFonts.jetBrainsMono(
                              fontSize: 9,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 1.5,
                              color: const Color(0xFF6EE7B7),
                            ),
                          ),
                          const SizedBox(height: 6),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                driverCode,
                                style: GoogleFonts.jetBrainsMono(
                                  fontSize: 19,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 1.0,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(width: 8),
                              IconButton(
                                constraints: const BoxConstraints(),
                                padding: EdgeInsets.zero,
                                icon: const Icon(Icons.copy_rounded, size: 18, color: Color(0xFF6EE7B7)),
                                onPressed: () {
                                  Clipboard.setData(ClipboardData(text: driverCode));
                                  HapticService.selectionClick();
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text("Driver ID $driverCode copied to clipboard!"),
                                      duration: const Duration(seconds: 2),
                                      backgroundColor: const Color(0xFF059669),
                                      behavior: SnackBarBehavior.floating,
                                    ),
                                  );
                                },
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            "Temporary access password dispatched to $email",
                            style: GoogleFonts.inter(
                              fontSize: 10,
                              color: const Color(0xFFA7F3D0),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),

                    // ── DRIVER PROFILE SUMMARY ───────────────────────────
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      decoration: BoxDecoration(
                        color: HardwarePalette.chalkChassis,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: HardwarePalette.matrixBorderLight),
                      ),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text("OPERATOR", style: GoogleFonts.jetBrainsMono(fontSize: 9, fontWeight: FontWeight.w700, color: HardwarePalette.silkscreenSubtle)),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  name, 
                                  textAlign: TextAlign.end,
                                  style: GoogleFonts.jetBrainsMono(fontSize: 11, fontWeight: FontWeight.w800, color: HardwarePalette.silkscreenDark),
                                  overflow: TextOverflow.ellipsis,
                                  maxLines: 1,
                                ),
                              ),
                            ],
                          ),
                          const Divider(height: 14, thickness: 0.8),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Padding(
                                padding: const EdgeInsets.only(top: 2),
                                child: Text("JURISDICTION", style: GoogleFonts.jetBrainsMono(fontSize: 9, fontWeight: FontWeight.w700, color: HardwarePalette.silkscreenSubtle)),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  hubName, 
                                  textAlign: TextAlign.end,
                                  style: GoogleFonts.jetBrainsMono(fontSize: 11, fontWeight: FontWeight.w800, color: HardwarePalette.silkscreenDark),
                                  overflow: TextOverflow.ellipsis,
                                  maxLines: 2,
                                ),
                              ),
                            ],
                          ),
                          const Divider(height: 14, thickness: 0.8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text("VEHICLE", style: GoogleFonts.jetBrainsMono(fontSize: 9, fontWeight: FontWeight.w700, color: HardwarePalette.silkscreenSubtle)),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  vehicleType, 
                                  textAlign: TextAlign.end,
                                  style: GoogleFonts.jetBrainsMono(fontSize: 11, fontWeight: FontWeight.w800, color: HardwarePalette.silkscreenDark),
                                  overflow: TextOverflow.ellipsis,
                                  maxLines: 1,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // ── PROCEED TO LOGIN BUTTON ──────────────────────────
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton(
                        onPressed: () {
                          HapticService.selectionClick();
                          Navigator.pushNamedAndRemoveUntil(
                            context, 
                            AppRoutes.login, 
                            (r) => false,
                            arguments: {
                              'driverId': driverCode,
                              'password': _approvedTempPassword ?? '',
                            },
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF059669),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          elevation: 3,
                          shadowColor: const Color(0xFF059669).withValues(alpha: 0.4),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              "PROCEED TO LOGIN",
                              style: GoogleFonts.jetBrainsMono(
                                fontSize: 12.5,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 1.0,
                              ),
                            ),
                            const SizedBox(width: 8),
                            const Icon(Icons.arrow_forward_rounded, size: 16),
                          ],
                        ),
                      ),
                    ),
                  ],
                )
              : Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // ── ANIMATED CLOCK WIDGET ────────────────────────────
                    const _AnimatedClock(),
                    const SizedBox(height: 12),

                    // ── LIVE STATUS BADGE ────────────────────────────────
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFEF3C7),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: const Color(0xFFF59E0B).withValues(alpha: 0.3)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 7,
                            height: 7,
                            decoration: const BoxDecoration(
                              color: Color(0xFFD97706),
                              shape: BoxShape.circle,
                            ),
                          )
                              .animate(onPlay: (c) => c.repeat(reverse: true))
                              .scale(begin: const Offset(0.7, 0.7), end: const Offset(1.3, 1.3), duration: 800.ms)
                              .fade(begin: 0.5, end: 1.0, duration: 800.ms),
                          const SizedBox(width: 6),
                          Text(
                            "PLEASE WAIT • UNDER REGIONAL REVIEW",
                            style: GoogleFonts.jetBrainsMono(
                              fontSize: 9,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.6,
                              color: const Color(0xFF92400E),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 10),

                    // ── TITLE & SUBTITLE ─────────────────────────────────
                    Text(
                      "EMPLOYEE REQUEST SENT",
                      textAlign: TextAlign.center,
                      style: GoogleFonts.spaceGrotesk(
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -0.5,
                        color: HardwarePalette.silkscreenDark,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      "Your onboarding request has been dispatched to your regional administrator for official Parivahan DL verification.",
                      textAlign: TextAlign.center,
                      style: GoogleFonts.inter(
                        fontSize: 11.5,
                        color: HardwarePalette.silkscreenDark.withValues(alpha: 0.72),
                        height: 1.35,
                      ),
                    ),
                    const SizedBox(height: 14),

                    // ── CREDENTIALS DISPATCH NOTICE ──────────────────────
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF0FDF4),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: const Color(0xFF86EFAC)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.mark_email_read_rounded, size: 16, color: Color(0xFF16A34A)),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  "CREDENTIALS DISPATCH DESTINATION",
                                  style: GoogleFonts.jetBrainsMono(
                                    fontSize: 8.5,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 0.5,
                                    color: const Color(0xFF166534),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            email,
                            style: GoogleFonts.jetBrainsMono(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF14532D),
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            "Once approved, your official Driver ID & temporary password will be emailed here.",
                            style: GoogleFonts.inter(
                              fontSize: 10.5,
                              color: const Color(0xFF166534).withValues(alpha: 0.85),
                              height: 1.25,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),

                    // ── APPLICATION SUMMARY CARD ─────────────────────────
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      decoration: BoxDecoration(
                        color: HardwarePalette.chalkChassis,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: HardwarePalette.matrixBorderLight),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // Ref & Vehicle Row
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    "APPLICATION REF",
                                    style: GoogleFonts.jetBrainsMono(
                                      fontSize: 8.5,
                                      fontWeight: FontWeight.w700,
                                      color: HardwarePalette.silkscreenSubtle,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    trackingId,
                                    style: GoogleFonts.jetBrainsMono(
                                      fontSize: 11.5,
                                      fontWeight: FontWeight.w800,
                                      color: HardwarePalette.silkscreenDark,
                                    ),
                                  ),
                                ],
                              ),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    "VEHICLE",
                                    style: GoogleFonts.jetBrainsMono(
                                      fontSize: 8.5,
                                      fontWeight: FontWeight.w700,
                                      color: HardwarePalette.silkscreenSubtle,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(color: HardwarePalette.matrixBorderLight),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(
                                          vehicleType,
                                          style: GoogleFonts.jetBrainsMono(
                                            fontSize: 11,
                                            fontWeight: FontWeight.w800,
                                            color: HardwarePalette.silkscreenDark,
                                          ),
                                        ),
                                        const SizedBox(width: 5),
                                        Text(
                                          "(${RealisticVehicleData.find(vehicleType).wheelCategory})",
                                          style: GoogleFonts.jetBrainsMono(
                                            fontSize: 8.5,
                                            fontWeight: FontWeight.w600,
                                            color: HardwarePalette.silkscreenSubtle,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          const Divider(height: 16, thickness: 0.8),

                          // Assigned Region
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "ASSIGNED REGION",
                                style: GoogleFonts.jetBrainsMono(
                                  fontSize: 8.5,
                                  fontWeight: FontWeight.w700,
                                  color: HardwarePalette.silkscreenSubtle,
                                ),
                              ),
                              const SizedBox(height: 3),
                              Row(
                                children: [
                                  const Icon(Icons.location_on_rounded, size: 14, color: Color(0xFF6366F1)),
                                  const SizedBox(width: 4),
                                  Expanded(
                                    child: Text(
                                      hubName,
                                      style: GoogleFonts.spaceGrotesk(
                                        fontSize: 11.5,
                                        fontWeight: FontWeight.w700,
                                        color: HardwarePalette.silkscreenDark,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),

                          if (licenseNumber.isNotEmpty) ...[
                            const Divider(height: 16, thickness: 0.8),
                            // Driving License
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  "DRIVING LICENSE",
                                  style: GoogleFonts.jetBrainsMono(
                                    fontSize: 8.5,
                                    fontWeight: FontWeight.w700,
                                    color: HardwarePalette.silkscreenSubtle,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    licenseNumber,
                                    textAlign: TextAlign.end,
                                    style: GoogleFonts.jetBrainsMono(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w800,
                                      color: HardwarePalette.silkscreenDark,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // ── RETURN TO SIGN IN BUTTON ─────────────────────────
                    SizedBox(
                      width: double.infinity,
                      height: 46,
                      child: ElevatedButton(
                        onPressed: () {
                          HapticService.selectionClick();
                          Navigator.pushNamedAndRemoveUntil(context, AppRoutes.login, (r) => false);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: HardwarePalette.silkscreenDark,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          elevation: 0,
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.arrow_back_rounded, size: 15),
                            const SizedBox(width: 6),
                            Text(
                              "RETURN TO SIGN IN",
                              style: GoogleFonts.jetBrainsMono(
                                fontSize: 11.5,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.8,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    GestureDetector(
                      onTap: () {
                        HapticService.selectionClick();
                        Navigator.pushNamedAndRemoveUntil(context, AppRoutes.login, (r) => false);
                      },
                      child: Padding(
                        padding: const EdgeInsets.all(4.0),
                        child: Text(
                          "Already received your email? Log In Now",
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: HardwarePalette.silkscreenSubtle,
                            decoration: TextDecoration.underline,
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

/// ── ANIMATED CLOCK WIDGET WITH CONTINUOUS ROTATING HANDS ───────────────────
class _AnimatedClock extends StatelessWidget {
  const _AnimatedClock();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 90,
      height: 90,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // ── Pulsing Outer Aura Halo
          Container(
            width: 86,
            height: 86,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xFFF59E0B).withValues(alpha: 0.12),
            ),
          )
              .animate(onPlay: (c) => c.repeat(reverse: true))
              .scaleXY(begin: 0.95, end: 1.15, duration: 1500.ms)
              .fade(begin: 0.4, end: 0.85, duration: 1500.ms),

          // ── Clock Dial Frame
          Container(
            width: 74,
            height: 74,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white,
              border: Border.all(
                color: const Color(0xFF0F172A),
                width: 3.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.08),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                // 12-Hour Tick Marks
                ...List.generate(12, (index) {
                  final angle = index * (math.pi / 6);
                  final isMajor = index % 3 == 0;
                  return Transform.rotate(
                    angle: angle,
                    child: Align(
                      alignment: Alignment.topCenter,
                      child: Container(
                        margin: const EdgeInsets.only(top: 3.5),
                        width: isMajor ? 2.5 : 1.5,
                        height: isMajor ? 5.5 : 3.5,
                        decoration: BoxDecoration(
                          color: isMajor ? const Color(0xFF0F172A) : const Color(0xFF94A3B8),
                          borderRadius: BorderRadius.circular(1),
                        ),
                      ),
                    ),
                  );
                }),

                // Rotating Hour Hand (Completes 1 full cycle in 12s)
                Container(
                  width: 70,
                  height: 70,
                  alignment: Alignment.center,
                  child: Transform.translate(
                    offset: const Offset(0, -9),
                    child: Container(
                      width: 3.2,
                      height: 18,
                      decoration: BoxDecoration(
                        color: const Color(0xFF0F172A),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                )
                    .animate(onPlay: (c) => c.repeat())
                    .rotate(duration: 12.seconds, begin: 0, end: 1),

                // Rotating Minute Hand (Completes 1 full cycle in 3s)
                Container(
                  width: 70,
                  height: 70,
                  alignment: Alignment.center,
                  child: Transform.translate(
                    offset: const Offset(0, -12),
                    child: Container(
                      width: 2.2,
                      height: 24,
                      decoration: BoxDecoration(
                        color: const Color(0xFFD97706), // Amber needle
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                )
                    .animate(onPlay: (c) => c.repeat())
                    .rotate(duration: 3.seconds, begin: 0, end: 1),

                // Second Ticking Dot / Pin (Rotates smoothly in 1.5s)
                Container(
                  width: 70,
                  height: 70,
                  alignment: Alignment.center,
                  child: Transform.translate(
                    offset: const Offset(0, -18),
                    child: Container(
                      width: 4.5,
                      height: 4.5,
                      decoration: const BoxDecoration(
                        color: Color(0xFFEF4444), // Red ticking tip
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                )
                    .animate(onPlay: (c) => c.repeat())
                    .rotate(duration: 1500.ms, begin: 0, end: 1),

                // Center Pin Cap
                Container(
                  width: 7,
                  height: 7,
                  decoration: BoxDecoration(
                    color: const Color(0xFF0F172A),
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 1.5),
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
