import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:mobile_app/providers/auth_provider.dart';
import 'package:mobile_app/routes/app_routes.dart';
import 'package:mobile_app/core/theme/neon_theme.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _nameController = TextEditingController();
  final _vehicleNameController = TextEditingController();
  final _plateController = TextEditingController();

  final String _selectedIndustry = 'Logistics';
  final String _selectedVehicleType = 'Van';

  void _handleSave() async {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    await auth.completeOnboarding(
      name: _nameController.text,
      industry: _selectedIndustry,
      vehicleType: _selectedVehicleType,
      vehicleName: _vehicleNameController.text,
      vehiclePlateNumber: _plateController.text,
    );
    if (mounted) Navigator.pushReplacementNamed(context, AppRoutes.home);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: NeonColors.background,
      appBar: AppBar(
        title: Text("PROFILE SETUP", style: TextStyle(color: NeonColors.text, fontSize: 13, fontWeight: FontWeight.w900, letterSpacing: 1.5)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('PROFILE CONFIGURATION', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: NeonColors.primaryGreen, letterSpacing: 1.5)),
            const SizedBox(height: 4),
            Text('Finalize Setup', style: TextStyle(color: NeonColors.text, fontSize: 24, fontWeight: FontWeight.w900)),
            const SizedBox(height: 6),
            Text('Enter vehicle and driver information to activate your unit link.', style: TextStyle(color: NeonColors.subtext, fontSize: 12)),
            const SizedBox(height: 28),

            _buildField(_nameController, "DRIVER NAME", Icons.person_outline_rounded),
            const SizedBox(height: 14),
            _buildField(_vehicleNameController, "VEHICLE MODEL", Icons.drive_eta_outlined),
            const SizedBox(height: 14),
            _buildField(_plateController, "VEHICLE PLATE NUMBER", Icons.badge_outlined),

            const SizedBox(height: 36),
            GestureDetector(
              onTap: _handleSave,
              child: Container(
                height: 54,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: NeonColors.primaryGreen,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: NeonColors.primaryGreen.withOpacity(0.3),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: const Center(
                  child: Text(
                    "ACTIVATE LINK",
                    style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1.5, fontSize: 13, color: Colors.white),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildField(TextEditingController ctrl, String label, IconData icon) {
    return Container(
      decoration: BoxDecoration(
        color: NeonColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: NeonColors.border),
      ),
      child: TextFormField(
        controller: ctrl,
        style: TextStyle(color: NeonColors.text, fontWeight: FontWeight.bold, fontSize: 13),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(fontWeight: FontWeight.w700, fontSize: 10, letterSpacing: 0.8, color: NeonColors.subtext),
          prefixIcon: Icon(icon, color: NeonColors.subtext, size: 18),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
      ),
    );
  }
}
