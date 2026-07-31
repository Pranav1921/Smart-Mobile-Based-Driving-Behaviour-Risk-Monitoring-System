import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/constants/app_colors.dart';
import '../providers/auth_provider.dart';
import '../routes/app_routes.dart';
import '../widgets/glass_card.dart';

class ProfilePreset {
  final String type;
  final String brandModel;
  final String plate;
  final IconData icon;

  ProfilePreset({
    required this.type,
    required this.brandModel,
    required this.plate,
    required this.icon,
  });
}

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  // Vehicle Preset Catalog
  final List<ProfilePreset> _vehiclePresets = [
    ProfilePreset(type: "Scooter", brandModel: "Ola S1 Pro EV", plate: "MH-12-EV-1024", icon: Icons.electric_scooter),
    ProfilePreset(type: "Motorcycle", brandModel: "Revolt RV400", plate: "DL-3C-EV-8899", icon: Icons.motorcycle),
    ProfilePreset(type: "Delivery Bike", brandModel: "Lectrix Cargo EV", plate: "KA-01-EE-3241", icon: Icons.directions_bike),
    ProfilePreset(type: "Sedan", brandModel: "Tesla Model 3", plate: "FG-101-AI", icon: Icons.directions_car),
    ProfilePreset(type: "SUV", brandModel: "Tesla Model Y", plate: "FG-202-AI", icon: Icons.electric_car),
    ProfilePreset(type: "Pickup Truck", brandModel: "Tesla Cybertruck", plate: "FG-303-AI", icon: Icons.airport_shuttle),
    ProfilePreset(type: "Delivery Van", brandModel: "Rivian EDV 500", plate: "FG-404-AI", icon: Icons.local_shipping),
    ProfilePreset(type: "Mini Truck", brandModel: "Tata Ace EV", plate: "DL-1L-EV-9001", icon: Icons.local_shipping_outlined),
    ProfilePreset(type: "Heavy Truck", brandModel: "Volvo FH Electric", plate: "FG-909-AI", icon: Icons.local_shipping),
  ];



  void _showVehicleSelectorSheet(BuildContext context, AuthProvider auth) {
    final isLight = Theme.of(context).brightness == Brightness.light;
    final primaryTextColor = isLight ? Colors.black : Colors.white;
    final secondaryTextColor = isLight ? const Color(0xFF666666) : const Color(0xFF90A4AE);

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return Container(
          decoration: BoxDecoration(
            color: isLight ? Colors.white : const Color(0xFF16181C),
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(28),
              topRight: Radius.circular(28),
            ),
            border: Border.all(
              color: isLight ? const Color(0xFFE5E5E5) : AppColors.border,
              width: 1.5,
            ),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Align(
                alignment: Alignment.center,
                child: Container(
                  width: 38,
                  height: 4,
                  decoration: BoxDecoration(
                    color: isLight ? const Color(0xFFCCCCCC) : AppColors.border,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Text(
                "SELECT ACTIVE VEHICLE",
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: secondaryTextColor,
                  letterSpacing: 1.5,
                ),
              ),
              const SizedBox(height: 14),
              ConstrainedBox(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(context).size.height * 0.5,
                ),
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: _vehiclePresets.length,
                  separatorBuilder: (context, index) => const Divider(),
                  itemBuilder: (context, index) {
                    final preset = _vehiclePresets[index];
                    final isCurrent = auth.profile.vehicleType.toLowerCase() == preset.type.toLowerCase();

                    return ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: isCurrent 
                              ? (isLight ? Colors.black.withOpacity(0.06) : AppColors.primary.withOpacity(0.1))
                              : (isLight ? const Color(0xFFF2F3F5) : const Color(0xFF22242B)),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          preset.icon,
                          color: isCurrent ? (isLight ? Colors.black : AppColors.primary) : secondaryTextColor,
                          size: 20,
                        ),
                      ),
                      title: Text(
                        preset.brandModel,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: primaryTextColor,
                        ),
                      ),
                      subtitle: Text(
                        "${preset.type.toUpperCase()}  •  ${preset.plate}",
                        style: TextStyle(fontSize: 10, color: secondaryTextColor),
                      ),
                      trailing: isCurrent
                          ? Icon(Icons.check_circle, color: isLight ? Colors.black : AppColors.primary, size: 20)
                          : const Icon(Icons.arrow_forward_ios, size: 12),
                      onTap: () async {
                        await auth.updateVehicle(
                          type: preset.type,
                          name: preset.brandModel,
                          plate: preset.plate,
                        );
                        if (context.mounted) {
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text("Active vehicle updated to ${preset.brandModel}"),
                              backgroundColor: isLight ? Colors.black : AppColors.primary,
                              behavior: SnackBarBehavior.floating,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                          );
                        }
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final profile = auth.profile;
    final isLight = Theme.of(context).brightness == Brightness.light;
    final primaryTextColor = isLight ? Colors.black : Colors.white;
    final secondaryTextColor = isLight ? const Color(0xFF666666) : const Color(0xFF90A4AE);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          "DRIVER PROFILE",
          style: TextStyle(color: primaryTextColor),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.only(left: 20, right: 20, top: 10, bottom: 100),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Driver Credentials Card (Nothing Cyber-Driver Style)
              GlassCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 60,
                          height: 60,
                          decoration: BoxDecoration(
                            color: isLight ? Colors.black.withOpacity(0.05) : AppColors.primary.withOpacity(0.08),
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: isLight ? Colors.black : AppColors.primary,
                              width: 1.5,
                            ),
                          ),
                          child: Icon(
                            Icons.person,
                            color: isLight ? Colors.black : AppColors.primary,
                            size: 32,
                          ),
                        ),
                        const SizedBox(width: 18),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                profile.name,
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: primaryTextColor,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                "ID: ${profile.driverId.toUpperCase()}  •  ${profile.companyCode}",
                                style: TextStyle(fontSize: 11, color: secondaryTextColor),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 18),
                    const Divider(color: Colors.white10),
                    const SizedBox(height: 10),

                    // Gamified XP Leveling progress
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          "LEVEL ${profile.level}",
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w900,
                            color: isLight ? Colors.black : AppColors.primary,
                            letterSpacing: 1.0,
                          ),
                        ),
                        Text(
                          "${profile.xp % 1000} / 1000 XP",
                          style: TextStyle(fontSize: 11, color: secondaryTextColor, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: (profile.xp % 1000) / 1000.0,
                        minHeight: 6,
                        backgroundColor: isLight ? const Color(0xFFE5E5E5) : AppColors.border,
                        valueColor: AlwaysStoppedAnimation<Color>(isLight ? Colors.black : AppColors.primary),
                      ),
                    ),
                    
                    // Streak counter badge
                    if (profile.streak > 0) ...[
                      const SizedBox(height: 14),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: AppColors.warning.withOpacity(0.08),
                          border: Border.all(color: AppColors.warning.withOpacity(0.2), width: 1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.local_fire_department, color: AppColors.warning, size: 16),
                            const SizedBox(width: 6),
                            Text(
                              "${profile.streak} DAY SAFE DRIVING STREAK",
                              style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w900, color: AppColors.warning),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // 2. Achievements Grid
              const Text(
                "UNLOCKED ACHIEVEMENTS",
                style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.textSecondary, letterSpacing: 1.5),
              ),
              const SizedBox(height: 10),
              GlassCard(
                child: GridView.count(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount: 2,
                  childAspectRatio: 2.2,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  children: [
                    _buildBadgeCard(
                      "🚀 SMOOTH",
                      "0 Harsh G-Events",
                      profile.badges.contains("smooth_operator"),
                      AppColors.success,
                    ),
                    _buildBadgeCard(
                      "🛡️ SPEED",
                      "Adheres limits",
                      profile.badges.contains("speed_sentinel"),
                      AppColors.primary,
                    ),
                    _buildBadgeCard(
                      "📱 FOCUSED",
                      "No device usage",
                      profile.badges.contains("focus_champion"),
                      Colors.pink,
                    ),
                    _buildBadgeCard(
                      "🌙 NIGHT",
                      "Safe night runs",
                      profile.badges.contains("night_rider"),
                      Colors.purple,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // 2. Maintenance Milestones Reminder
              const Text(
                "UPCOMING MAINTENANCE CHECKS",
                style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.textSecondary, letterSpacing: 1.5),
              ),
              const SizedBox(height: 10),
              GlassCard(
                child: Column(
                  children: [
                    _buildServiceItem("Brakes Pad Inspection", "380 mi remaining", 0.82, AppColors.warning),
                    const Divider(),
                    _buildServiceItem("Engine/Motor Coolant Check", "840 mi remaining", 0.44, AppColors.primary),
                    const Divider(),
                    _buildServiceItem("Tire Rotation & Pressure Check", "1,720 mi remaining", 0.18, AppColors.success),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // 4. Utility Paths (Settings, Logout)
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        Navigator.pushNamed(context, AppRoutes.settings);
                      },
                      style: OutlinedButton.styleFrom(
                        foregroundColor: primaryTextColor,
                        side: BorderSide(color: isLight ? const Color(0xFFCCCCCC) : AppColors.border, width: 1.5),
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.settings_outlined, size: 18),
                          SizedBox(width: 8),
                          Text("CONFIG"),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () async {
                        await auth.logout();
                        if (context.mounted) {
                          Navigator.pushReplacementNamed(context, AppRoutes.login);
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.error.withOpacity(0.08),
                        foregroundColor: AppColors.error,
                        side: const BorderSide(color: AppColors.error, width: 1),
                        shadowColor: Colors.transparent,
                        elevation: 0,
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.exit_to_app_outlined, size: 18),
                          SizedBox(width: 8),
                          Text("LOGOUT"),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }





  Widget _buildServiceItem(String title, String status, double progressValue, Color progressColor) {
    final isLight = Theme.of(context).brightness == Brightness.light;
    final primaryTextColor = isLight ? Colors.black : Colors.white;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: primaryTextColor),
              ),
              Text(
                status,
                style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: progressColor),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progressValue,
              minHeight: 4,
              backgroundColor: isLight ? const Color(0xFFE5E5E5) : AppColors.border,
              valueColor: AlwaysStoppedAnimation<Color>(progressColor),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBadgeCard(String label, String desc, bool isUnlocked, Color themeColor) {
    final isLight = Theme.of(context).brightness == Brightness.light;
    final primaryTextColor = isLight ? Colors.black : Colors.white;
    final secondaryTextColor = isLight ? const Color(0xFF666666) : const Color(0xFF90A4AE);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isUnlocked 
            ? themeColor.withOpacity(0.08) 
            : (isLight ? const Color(0xFFF2F3F5) : const Color(0xFF1E2026)),
        border: Border.all(
          color: isUnlocked 
              ? themeColor.withOpacity(0.4) 
              : (isLight ? const Color(0xFFDDDDDD) : Colors.white.withOpacity(0.05)),
          width: 1.5,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                    color: isUnlocked ? themeColor : secondaryTextColor,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  desc,
                  style: TextStyle(
                    fontSize: 9, 
                    color: isUnlocked ? primaryTextColor.withOpacity(0.7) : secondaryTextColor.withOpacity(0.5),
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          if (!isUnlocked)
            Icon(Icons.lock, size: 14, color: secondaryTextColor.withOpacity(0.4))
          else
            Icon(Icons.check_circle_outline, size: 14, color: themeColor),
        ],
      ),
    );
  }
}
