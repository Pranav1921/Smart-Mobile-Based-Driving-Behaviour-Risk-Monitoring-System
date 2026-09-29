import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../providers/auth_provider.dart';
import '../core/theme/hardware_theme.dart';
import '../services/haptic_service.dart';

class ChangePasswordDialog extends StatefulWidget {
  final String tempPasswordUsed;
  final VoidCallback onSuccess;

  const ChangePasswordDialog({
    super.key,
    required this.tempPasswordUsed,
    required this.onSuccess,
  });

  @override
  State<ChangePasswordDialog> createState() => _ChangePasswordDialogState();
}

class _ChangePasswordDialogState extends State<ChangePasswordDialog> {
  final _formKey = GlobalKey<FormState>();
  final _newPwCtrl = TextEditingController();
  final _confirmPwCtrl = TextEditingController();
  bool _obscureNew = true;
  bool _obscureConfirm = true;
  bool _submitting = false;
  String? _errorMessage;

  @override
  void dispose() {
    _newPwCtrl.dispose();
    _confirmPwCtrl.dispose();
    super.dispose();
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) {
      HapticService.error();
      return;
    }

    if (_newPwCtrl.text != _confirmPwCtrl.text) {
      setState(() => _errorMessage = 'Passwords do not match');
      HapticService.error();
      return;
    }

    setState(() {
      _submitting = true;
      _errorMessage = null;
    });
    HapticService.mediumImpact();

    final auth = Provider.of<AuthProvider>(context, listen: false);
    final success = await auth.changeInitialPassword(
      widget.tempPasswordUsed,
      _newPwCtrl.text.trim(),
    );

    if (!mounted) return;
    setState(() => _submitting = false);

    if (success) {
      HapticService.success();
      Navigator.of(context).pop();
      widget.onSuccess();
    } else {
      HapticService.error();
      setState(() => _errorMessage = auth.lastErrorMessage ?? 'Failed to update password. Please try again.');
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false, // Force user to set their password on first sign-in
      child: Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 20),
        child: Container(
          decoration: BoxDecoration(
            color: HardwarePalette.chalkChassis,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: HardwarePalette.matrixBorderLight, width: 1.5),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.15),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Header Icon
                Center(
                  child: Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      color: HardwarePalette.cautionAmber.withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                      border: Border.all(color: HardwarePalette.cautionAmber.withValues(alpha: 0.3)),
                    ),
                    child: const Center(
                      child: Icon(
                        Icons.lock_reset_rounded,
                        color: HardwarePalette.cautionAmber,
                        size: 26,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Title
                Text(
                  "FIRST-TIME SIGN IN",
                  textAlign: TextAlign.center,
                  style: GoogleFonts.jetBrainsMono(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.5,
                    color: HardwarePalette.cautionAmber,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  "Set Permanent Password",
                  textAlign: TextAlign.center,
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: HardwarePalette.silkscreenDark,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  "Your temporary default password was verified. Please choose a new secure permanent password to access the telemetry dashboard.",
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: HardwarePalette.silkscreenDark.withValues(alpha: 0.65),
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 20),

                if (_errorMessage != null) ...[
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: HardwarePalette.criticalCrimson.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: HardwarePalette.criticalCrimson.withValues(alpha: 0.25)),
                    ),
                    child: Text(
                      _errorMessage!,
                      textAlign: TextAlign.center,
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        color: HardwarePalette.criticalCrimson,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                ],

                // New Password Field
                Text(
                  "NEW PERMANENT PASSWORD",
                  style: GoogleFonts.jetBrainsMono(
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.8,
                    color: HardwarePalette.silkscreenDark.withValues(alpha: 0.6),
                  ),
                ),
                const SizedBox(height: 6),
                TextFormField(
                  controller: _newPwCtrl,
                  obscureText: _obscureNew,
                  style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600),
                  decoration: InputDecoration(
                    hintText: "Enter at least 6 characters",
                    hintStyle: GoogleFonts.inter(fontSize: 12, color: Colors.grey.shade400),
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: HardwarePalette.matrixBorderLight),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: HardwarePalette.matrixBorderLight),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: HardwarePalette.signalEmerald, width: 1.5),
                    ),
                    suffixIcon: IconButton(
                      icon: Icon(_obscureNew ? Icons.visibility_off : Icons.visibility, size: 18),
                      onPressed: () => setState(() => _obscureNew = !_obscureNew),
                    ),
                  ),
                  validator: (v) {
                    if (v == null || v.length < 6) return "Minimum 6 characters required";
                    return null;
                  },
                ),
                const SizedBox(height: 14),

                // Confirm Password Field
                Text(
                  "CONFIRM NEW PASSWORD",
                  style: GoogleFonts.jetBrainsMono(
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.8,
                    color: HardwarePalette.silkscreenDark.withValues(alpha: 0.6),
                  ),
                ),
                const SizedBox(height: 6),
                TextFormField(
                  controller: _confirmPwCtrl,
                  obscureText: _obscureConfirm,
                  style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600),
                  decoration: InputDecoration(
                    hintText: "Re-enter new password",
                    hintStyle: GoogleFonts.inter(fontSize: 12, color: Colors.grey.shade400),
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: HardwarePalette.matrixBorderLight),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: HardwarePalette.matrixBorderLight),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: HardwarePalette.signalEmerald, width: 1.5),
                    ),
                    suffixIcon: IconButton(
                      icon: Icon(_obscureConfirm ? Icons.visibility_off : Icons.visibility, size: 18),
                      onPressed: () => setState(() => _obscureConfirm = !_obscureConfirm),
                    ),
                  ),
                  validator: (v) {
                    if (v == null || v.isEmpty) return "Please confirm password";
                    return null;
                  },
                ),
                const SizedBox(height: 24),

                // Save Button
                ElevatedButton(
                  onPressed: _submitting ? null : _handleSubmit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: HardwarePalette.signalEmerald,
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    elevation: 0,
                  ),
                  child: _submitting
                      ? const SizedBox(
                          height: 18,
                          width: 18,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black),
                        )
                      : Text(
                          "SAVE & ENTER DASHBOARD",
                          style: GoogleFonts.jetBrainsMono(
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1.0,
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
