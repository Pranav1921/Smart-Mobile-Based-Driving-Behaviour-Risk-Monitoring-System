import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';

import '../providers/auth_provider.dart';
import '../routes/app_routes.dart';
import '../core/theme/hardware_theme.dart';
import '../services/haptic_service.dart';
import '../widgets/change_password_dialog.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _idCtrl = TextEditingController(text: 'driver@smartdriving.ai');
  final _pwCtrl = TextEditingController(text: 'admin123');
  bool _obscureText = true;
  bool _rememberTerminal = true;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args = ModalRoute.of(context)?.settings.arguments;
    if (args is Map<String, dynamic>) {
      if (args['driverId'] != null && (args['driverId'] as String).isNotEmpty) {
        _idCtrl.text = args['driverId'] as String;
      }
      if (args['password'] != null && (args['password'] as String).isNotEmpty) {
        _pwCtrl.text = args['password'] as String;
      }
    } else if (args is String && args.isNotEmpty) {
      _idCtrl.text = args;
    }
  }

  @override
  void dispose() {
    _idCtrl.dispose();
    _pwCtrl.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) {
      HapticService.error();
      return;
    }
    HapticService.mediumImpact();
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final success = await auth.login(
      driverId: _idCtrl.text.trim(),
      password: _pwCtrl.text,
    );
    if (success && mounted) {
      HapticService.success();
      if (auth.mustChangePassword) {
        // Show mandatory permanent password setup dialog for first-time login
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (ctx) => ChangePasswordDialog(
            tempPasswordUsed: _pwCtrl.text,
            onSuccess: () {
              Navigator.pushReplacementNamed(context, AppRoutes.home);
            },
          ),
        );
      } else {
        Navigator.pushReplacementNamed(context, AppRoutes.home);
      }
    } else {
      HapticService.error();
      if (mounted) {
        final errorMsg = auth.lastErrorMessage ?? "Invalid Driver ID or Password. If you just registered, please await Parivahan Admin approval.";
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error_outline_rounded, color: Colors.white, size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    errorMsg,
                    style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
            backgroundColor: HardwarePalette.criticalCrimson,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);

    return Scaffold(
      backgroundColor: HardwarePalette.chalkChassis,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 20),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // ── MINIMAL LOGO & TITLE ─────────────
                  Center(
                    child: Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: HardwarePalette.matrixBorderLight, width: 1.0),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.04),
                            blurRadius: 10,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: const Center(
                        child: Icon(
                          Icons.two_wheeler_rounded,
                          color: HardwarePalette.signalEmerald,
                          size: 28,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),

                  Text(
                    "SMARTDRIVE",
                    textAlign: TextAlign.center,
                    style: HardwareTypography.ndotHeader(
                      fontSize: 16,
                      color: HardwarePalette.silkscreenDark,
                      letterSpacing: 2.0,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "DRIVING BEHAVIOUR & RISK MONITORING",
                    textAlign: TextAlign.center,
                    style: GoogleFonts.jetBrainsMono(
                      fontSize: 8.5,
                      fontWeight: FontWeight.bold,
                      color: HardwarePalette.silkscreenSubtle,
                      letterSpacing: 1.0,
                    ),
                  ),
                  const SizedBox(height: 24),

                  // ── AUTHENTICATION CARD ────────────────────────
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: HardwarePalette.matrixBorderLight, width: 1.0),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.03),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Driver ID / Email Field
                        _buildMicroLabel("DRIVER ID / REGISTERED EMAIL"),
                        _buildInputField(
                          controller: _idCtrl,
                          hint: "e.g. DRV-PTR-2026-842 or email",
                          icon: Icons.badge_outlined,
                          validator: (v) => v == null || v.trim().isEmpty ? "Driver ID or Email required" : null,
                        ),
                        const SizedBox(height: 16),

                        // Password Field
                        _buildMicroLabel("PASSWORD / ACCESS PIN"),
                        _buildInputField(
                          controller: _pwCtrl,
                          hint: "••••••••",
                          icon: Icons.lock_outline_rounded,
                          obscure: _obscureText,
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscureText ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                              color: HardwarePalette.silkscreenSubtle,
                              size: 16,
                            ),
                            onPressed: () => setState(() => _obscureText = !_obscureText),
                          ),
                          validator: (v) => v == null || v.length < 4 ? "Min 4 characters" : null,
                        ),
                        const SizedBox(height: 14),

                        // Remember Device Toggle
                        Row(
                          children: [
                            SizedBox(
                              height: 24,
                              width: 24,
                              child: Checkbox(
                                value: _rememberTerminal,
                                activeColor: HardwarePalette.signalEmerald,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                                onChanged: (v) => setState(() => _rememberTerminal = v ?? true),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              "Remember this device",
                              style: GoogleFonts.spaceGrotesk(
                                fontSize: 11.5,
                                fontWeight: FontWeight.w600,
                                color: HardwarePalette.silkscreenSubtle,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),

                  // ── SIGN IN BUTTON ──────────────────────────────────────
                  GestureDetector(
                    onTap: auth.isLoading ? null : _handleLogin,
                    child: Container(
                      height: 50,
                      decoration: BoxDecoration(
                        color: HardwarePalette.silkscreenDark,
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.12),
                            blurRadius: 8,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Center(
                        child: auth.isLoading
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                              )
                            : Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    "SIGN IN TO HUD",
                                    style: GoogleFonts.spaceGrotesk(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w700,
                                      letterSpacing: 1.0,
                                      color: Colors.white,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  const Icon(Icons.arrow_forward_rounded, size: 16, color: Colors.white),
                                ],
                              ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Apply for Registration Link
                  Center(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          "New User? ",
                          style: GoogleFonts.inter(
                            fontSize: 12.5,
                            color: HardwarePalette.silkscreenDark.withValues(alpha: 0.7),
                          ),
                        ),
                        GestureDetector(
                          onTap: () => Navigator.pushNamed(context, AppRoutes.register),
                          child: Text(
                            "Apply for Registration →",
                            style: GoogleFonts.spaceGrotesk(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w700,
                              color: HardwarePalette.signalEmerald,
                              decoration: TextDecoration.underline,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // App Motto & Intro Guide Link
                  Center(
                    child: TextButton.icon(
                      onPressed: () => Navigator.pushNamed(context, AppRoutes.onboarding),
                      icon: Icon(Icons.lightbulb_outline_rounded, size: 14, color: HardwarePalette.silkscreenSubtle),
                      label: Text(
                        "View App Motto & Interactive Walkthrough",
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: HardwarePalette.silkscreenSubtle,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMicroLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 5),
      child: Text(
        text,
        style: GoogleFonts.jetBrainsMono(
          fontSize: 8.5,
          fontWeight: FontWeight.w700,
          color: HardwarePalette.silkscreenSubtle,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _buildInputField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    bool obscure = false,
    Widget? suffixIcon,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscure,
      validator: validator,
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
        prefixIcon: Icon(icon, color: HardwarePalette.silkscreenSubtle, size: 17),
        suffixIcon: suffixIcon,
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
          borderSide: const BorderSide(color: HardwarePalette.signalEmerald, width: 1.5),
        ),
      ),
    );
  }
}
