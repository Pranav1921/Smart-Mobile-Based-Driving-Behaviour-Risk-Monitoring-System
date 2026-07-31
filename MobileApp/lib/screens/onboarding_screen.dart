import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/constants/app_colors.dart';
import '../core/constants/app_strings.dart';
import '../providers/auth_provider.dart';
import '../routes/app_routes.dart';
import '../widgets/glass_card.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _vehicleNameController = TextEditingController();
  final _plateController = TextEditingController();

  String _selectedIndustry = 'Logistics';
  String _selectedVehicleType = 'Van';

  final List<String> _industries = [
    'Food Delivery',
    'Courier',
    'Logistics',
    'Ride Sharing',
    'Enterprise Fleet'
  ];

  final List<String> _vehicles = [
    'Scooty',
    'Motorcycle',
    'Car',
    'Van',
    'Truck',
    'Pickup'
  ];

  @override
  void dispose() {
    _nameController.dispose();
    _vehicleNameController.dispose();
    _plateController.dispose();
    super.dispose();
  }

  void _handleSave() async {
    if (!_formKey.currentState!.validate()) return;

    final auth = Provider.of<AuthProvider>(context, listen: false);
    await auth.completeOnboarding(
      name: _nameController.text,
      industry: _selectedIndustry,
      vehicleType: _selectedVehicleType,
      vehicleName: _vehicleNameController.text,
      vehiclePlateNumber: _plateController.text,
    );

    if (mounted) {
      Navigator.pushReplacementNamed(context, AppRoutes.home);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text("INITIALIZATION"),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "REGISTRATION SETUP",
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 2.0,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  "Configure Profile",
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 24),
                
                // Onboarding Inputs Card
                GlassCard(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      TextFormField(
                        controller: _nameController,
                        style: const TextStyle(color: AppColors.textPrimary),
                        decoration: const InputDecoration(
                          labelText: "Driver Profile Name (e.g. John Doe)",
                          prefixIcon: Icon(Icons.person, color: AppColors.textSecondary),
                        ),
                        validator: (val) => val == null || val.isEmpty ? "Enter profile display name" : null,
                      ),
                      const SizedBox(height: 24),
                      
                      // Industry Selection Title
                      const Text(
                        "OPERATING INDUSTRY DOMAIN",
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.0,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      // Horizontal List of domains
                      SizedBox(
                        height: 48,
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          itemCount: _industries.length,
                          itemBuilder: (context, index) {
                            final ind = _industries[index];
                            final isSel = ind == _selectedIndustry;
                            return Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: ChoiceChip(
                                label: Text(ind),
                                selected: isSel,
                                onSelected: (sel) {
                                  if (sel) setState(() => _selectedIndustry = ind);
                                },
                                backgroundColor: AppColors.background,
                                selectedColor: AppColors.primary,
                                labelStyle: TextStyle(
                                  color: isSel ? Colors.black : AppColors.textPrimary,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                                side: BorderSide(
                                  color: isSel ? AppColors.primary : AppColors.border,
                                  width: 1,
                                ),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                            );
                          },
                        ),
                      ),
                      
                      const SizedBox(height: 24),
                      
                      // Vehicle Type Selection Title
                      const Text(
                        "ACTIVE VEHICLE CLASSIFICATION",
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.0,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      // Horizontal List of vehicle categories
                      SizedBox(
                        height: 48,
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          itemCount: _vehicles.length,
                          itemBuilder: (context, index) {
                            final veh = _vehicles[index];
                            final isSel = veh == _selectedVehicleType;
                            return Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: ChoiceChip(
                                label: Text(veh),
                                selected: isSel,
                                onSelected: (sel) {
                                  if (sel) setState(() => _selectedVehicleType = veh);
                                },
                                backgroundColor: AppColors.background,
                                selectedColor: AppColors.primary,
                                labelStyle: TextStyle(
                                  color: isSel ? Colors.black : AppColors.textPrimary,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                                side: BorderSide(
                                  color: isSel ? AppColors.primary : AppColors.border,
                                  width: 1,
                                ),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Vehicle Registration Card
                GlassCard(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: [
                      TextFormField(
                        controller: _vehicleNameController,
                        style: const TextStyle(color: AppColors.textPrimary),
                        decoration: const InputDecoration(
                          labelText: AppStrings.vehicleNameLabel,
                          prefixIcon: Icon(Icons.drive_eta, color: AppColors.textSecondary),
                        ),
                        validator: (val) => val == null || val.isEmpty ? "Enter vehicle name" : null,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _plateController,
                        style: const TextStyle(color: AppColors.textPrimary),
                        decoration: const InputDecoration(
                          labelText: AppStrings.vehicleNumberLabel,
                          prefixIcon: Icon(Icons.credit_card, color: AppColors.textSecondary),
                        ),
                        validator: (val) => val == null || val.isEmpty ? "Enter license plate number" : null,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),
                
                ElevatedButton(
                  onPressed: _handleSave,
                  child: const Text("INITIALIZE COMPANION"),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
