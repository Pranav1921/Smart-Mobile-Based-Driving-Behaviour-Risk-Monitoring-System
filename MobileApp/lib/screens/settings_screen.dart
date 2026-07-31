import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/constants/app_colors.dart';
import '../providers/sensor_provider.dart';
import '../providers/trip_provider.dart';
import '../providers/theme_provider.dart';
import '../widgets/glass_card.dart';
import 'package:permission_handler/permission_handler.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _locPerm = true;
  bool _sensorPerm = true;
  bool _camPerm = true;

  @override
  void initState() {
    super.initState();
    _checkPermissions();
  }

  void _checkPermissions() async {
    final loc = await Permission.location.status.isGranted;
    final cam = await Permission.camera.status.isGranted;
    final sensors = await Permission.sensors.status.isGranted;
    if (mounted) {
      setState(() {
        _locPerm = loc;
        _camPerm = cam;
        _sensorPerm = sensors;
      });
    }
  }

  void _requestPermission(Permission perm, String name) async {
    final status = await perm.request();
    if (status.isGranted) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("$name access granted successfully."),
            backgroundColor: AppColors.success,
          ),
        );
      }
      _checkPermissions();
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Access to $name was denied."),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final sensorProv = Provider.of<SensorProvider>(context);
    final tripProv = Provider.of<TripProvider>(context);
    final isLight = Theme.of(context).brightness == Brightness.light;
    final primaryTextColor = isLight ? Colors.black : Colors.white;
    final secondaryTextColor = isLight ? const Color(0xFF666666) : const Color(0xFF90A4AE);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          "SYSTEM CONFIG",
          style: TextStyle(color: primaryTextColor),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Theme Configuration Panel
              Text(
                "APPLICATION THEME MODE",
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.5,
                  color: isLight ? Colors.black : AppColors.primary,
                ),
              ),
              const SizedBox(height: 10),
              GlassCard(
                child: Row(
                  children: [
                    _buildThemeOption(context, "DARK", ThemeMode.dark, Icons.dark_mode_outlined),
                    const SizedBox(width: 8),
                    _buildThemeOption(context, "LIGHT", ThemeMode.light, Icons.light_mode_outlined),
                    const SizedBox(width: 8),
                    _buildThemeOption(context, "SYSTEM", ThemeMode.system, Icons.settings_brightness_outlined),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // 2. Telemetry Simulation Control Panel (IMPORTANT FOR DEMO)
              Text(
                "DEVELOPER TELEMETRY SIMULATOR",
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.5,
                  color: isLight ? Colors.black : AppColors.primary,
                ),
              ),
              const SizedBox(height: 10),
              GlassCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SwitchListTile(
                      title: Text(
                        "Simulation Override",
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: primaryTextColor),
                      ),
                      subtitle: Text(
                        "Allows mock triggers for testing safety events",
                        style: TextStyle(fontSize: 11, color: secondaryTextColor),
                      ),
                      value: sensorProv.simulationMode,
                      activeColor: isLight ? Colors.black : AppColors.primary,
                      onChanged: (val) {
                        sensorProv.toggleSimulationMode(val);
                      },
                    ),
                    const Divider(),
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: Text(
                        "TAP ANY BUTTON BELOW TO FORCE TRIGGER A REAL-TIME EVENT IN NAVIGATION SCREEN:",
                        style: TextStyle(fontSize: 8.5, fontWeight: FontWeight.bold, color: AppColors.warning, letterSpacing: 0.5),
                      ),
                    ),
                    const SizedBox(height: 8),
                    GridView.count(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      crossAxisCount: 2,
                      mainAxisSpacing: 10,
                      crossAxisSpacing: 10,
                      childAspectRatio: 2.2,
                      children: [
                        _buildSimButton(
                          "Harsh Braking",
                          Icons.front_hand,
                          () {
                            sensorProv.triggerEvent(
                              "Harsh Braking", 
                              0.48, 
                              "Maintain a 3-second spacing with vehicles ahead to allow gradual braking."
                            );
                            _showToast(context, "Harsh Braking triggered");
                          },
                        ),
                        _buildSimButton(
                          "Sudden Accel",
                          Icons.speed,
                          () {
                            sensorProv.triggerEvent(
                              "Rapid Acceleration", 
                              0.36, 
                              "Squeeze the accelerator gently to save up to 15% fuel economy."
                            );
                            _showToast(context, "Sudden Acceleration triggered");
                          },
                        ),
                        _buildSimButton(
                          "Sharp Turn",
                          Icons.gesture,
                          () {
                            sensorProv.triggerEvent(
                              "Sharp Turn", 
                              0.51, 
                              "Reduce speed prior to entering curves to reduce cargo weight shifting."
                            );
                            _showToast(context, "Sharp Turn triggered");
                          },
                        ),
                        _buildSimButton(
                          "Overspeeding",
                          Icons.trending_up,
                          () {
                            sensorProv.triggerEvent(
                              "Overspeed", 
                              78.0, 
                              "Maintain vehicle speeds below the local limits (currently 65 mph)."
                            );
                            sensorProv.updateSpeed(78.0);
                            _showToast(context, "Overspeed triggered");
                          },
                        ),
                        _buildSimButton(
                          "Distraction",
                          Icons.phone_android,
                          () {
                            sensorProv.triggerEvent(
                              "Phone Usage", 
                              1.0, 
                              "Keep focus on forward lanes; phone interaction triggers company dispatch notifications."
                            );
                            _showToast(context, "Phone Usage triggered");
                          },
                        ),
                        _buildSimButton(
                          "Pothole Hit",
                          Icons.analytics,
                          () {
                            sensorProv.triggerEvent(
                              "Pothole", 
                              0.62, 
                              "Scan forward road profiles to steer clear of deep surface irregularities."
                            );
                            _showToast(context, "Pothole Anomaly triggered");
                          },
                        ),
                      ],
                    ),
                    const Divider(height: 24),
                    // Severe Crash SOS Simulation Button
                    ElevatedButton(
                      onPressed: () {
                        // Route crash simulator
                        tripProv.triggerCrashSimulation();
                        Navigator.pushReplacementNamed(context, '/crash');
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.error.withOpacity(0.15),
                        foregroundColor: AppColors.error,
                        side: const BorderSide(color: AppColors.error, width: 1.5),
                        shadowColor: Colors.transparent,
                        elevation: 0,
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.emergency_share, size: 20),
                          SizedBox(width: 8),
                          Flexible(
                            child: Text(
                              "FORCE SEVERE CRASH SOS TRIGGER",
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // 3. Hardware System Permissions
              Text(
                "SYSTEM HARDWARE PERMISSIONS",
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.5,
                  color: secondaryTextColor,
                ),
              ),
              const SizedBox(height: 10),
              GlassCard(
                child: Column(
                  children: [
                    _buildPermissionRow(
                      "GPS Location Sensors",
                      "Required for routing and mapping",
                      _locPerm,
                      () => _requestPermission(Permission.location, "GPS Location"),
                    ),
                    const Divider(),
                    _buildPermissionRow(
                      "Device Inertial Sensors",
                      "Required for accelerometer G-Force readings",
                      _sensorPerm,
                      () => _requestPermission(Permission.sensors, "Motion Sensors"),
                    ),
                    const Divider(),
                    _buildPermissionRow(
                      "Dashcam Camera",
                      "Required for crash video recording",
                      _camPerm,
                      () => _requestPermission(Permission.camera, "Camera"),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showToast(BuildContext context, String msg) {
    final isLight = Theme.of(context).brightness == Brightness.light;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: isLight ? Colors.black : AppColors.surface,
        duration: const Duration(seconds: 1),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  Widget _buildThemeOption(BuildContext context, String label, ThemeMode mode, IconData icon) {
    final themeProv = Provider.of<ThemeProvider>(context);
    final isSelected = themeProv.themeMode == mode;
    final isLight = Theme.of(context).brightness == Brightness.light;
    final primaryTextColor = isLight ? Colors.black : Colors.white;

    final boxBgColor = isSelected
        ? (isLight ? Colors.black.withOpacity(0.08) : AppColors.primary.withOpacity(0.12))
        : (isLight ? const Color(0xFFF0F1F4) : const Color(0xFF1B1D22));
    final borderColor = isSelected
        ? (isLight ? Colors.black : AppColors.primary)
        : (isLight ? const Color(0xFFE5E5E5) : AppColors.border);

    return Expanded(
      child: InkWell(
        onTap: () => themeProv.setThemeMode(mode),
        borderRadius: BorderRadius.circular(12),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: boxBgColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: borderColor, width: 1),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 20,
                color: isSelected 
                    ? (isLight ? Colors.black : AppColors.primary) 
                    : (isLight ? Colors.black54 : Colors.white70),
              ),
              const SizedBox(height: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: isSelected 
                      ? (isLight ? Colors.black : AppColors.primary) 
                      : primaryTextColor,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSimButton(String label, IconData icon, VoidCallback onTap) {
    final isLight = Theme.of(context).brightness == Brightness.light;
    final primaryTextColor = isLight ? Colors.black : Colors.white;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: isLight ? const Color(0xFFF0F1F4) : AppColors.background.withOpacity(0.6),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: isLight ? const Color(0xFFE5E5E5) : AppColors.border),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 16, color: isLight ? Colors.black87 : AppColors.primary),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                label,
                style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: primaryTextColor),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPermissionRow(String title, String desc, bool isGranted, VoidCallback onRequest) {
    final isLight = Theme.of(context).brightness == Brightness.light;
    final primaryTextColor = isLight ? Colors.black : Colors.white;
    final secondaryTextColor = isLight ? const Color(0xFF666666) : const Color(0xFF90A4AE);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: primaryTextColor)),
                const SizedBox(height: 2),
                Text(desc, style: TextStyle(fontSize: 10, color: secondaryTextColor)),
              ],
            ),
          ),
          ElevatedButton(
            onPressed: isGranted ? null : onRequest,
            style: ElevatedButton.styleFrom(
              backgroundColor: isGranted ? Colors.transparent : (isLight ? Colors.black : AppColors.primary),
              foregroundColor: isGranted ? AppColors.success : (isLight ? Colors.white : Colors.black),
              minimumSize: const Size(80, 36),
              padding: const EdgeInsets.symmetric(horizontal: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              elevation: 0,
            ),
            child: Text(
              isGranted ? "ACTIVE" : "GRANT",
              style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }
}