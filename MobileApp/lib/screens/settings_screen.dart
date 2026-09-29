import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:mobile_app/providers/auth_provider.dart';
import 'package:mobile_app/providers/trip_provider.dart';
import 'package:mobile_app/providers/theme_provider.dart';
import 'package:mobile_app/models/driver_model.dart';
import 'package:mobile_app/core/theme/neon_theme.dart';
import 'package:mobile_app/services/esp32_service.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authProv = Provider.of<AuthProvider>(context);
    final themeProv = Provider.of<ThemeProvider>(context);
    final profile = authProv.profile;

    return Scaffold(
      backgroundColor: NeonColors.background,
      appBar: AppBar(
        backgroundColor: NeonColors.green,
        elevation: 0,
        toolbarHeight: 56,
        leading: IconButton(
          icon: const Icon(Icons.chevron_left_rounded, color: Colors.white, size: 28),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'Settings & Preferences',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w900,
            fontSize: 15,
          ),
        ),
      ),
      body: SafeArea(
        child: ListView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
          children: [
            _sectionLabel('Visual Theme Mode'),
            const SizedBox(height: 10),
            _buildThemeSlideBar(themeProv),

            const SizedBox(height: 28),
            _sectionLabel('Operational Telemetry Profile'),
            const SizedBox(height: 10),
            _buildModeCard(
              context,
              'Tactical Mode',
              'Full real-time sensor processing, harsh event detection & HUD gauge',
              DriverType.TACTICAL,
              profile.driverType == DriverType.TACTICAL,
            ),
            const SizedBox(height: 10),
            _buildModeCard(
              context,
              'Standard Mode',
              'Optimized battery profile with passive safety tracking',
              DriverType.STANDARD,
              profile.driverType == DriverType.STANDARD,
            ),

            const SizedBox(height: 28),
            _sectionLabel('Hardware & External Sensors'),
            const SizedBox(height: 10),
            _actionTile(
              context,
              Icons.memory_rounded,
              'ESP32 External Node Link',
              'Detect MPU-9250 IMU over Wi-Fi / AP',
              NeonColors.neonBlue,
              () => _showEsp32DiscoveryModal(context),
            ),
            const SizedBox(height: 10),
            _actionTile(
              context,
              Icons.security_rounded,
              'Phone Sensors & GPS',
              'Test integrated accelerometer, gyro & location permissions',
              NeonColors.primaryGreen,
              () async {
                final tripProv = Provider.of<TripProvider>(context, listen: false);
                await tripProv.requestAllPermissions();
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Hardware sensor permissions and telemetry verified!'),
                      backgroundColor: NeonColors.primaryGreen,
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
              },
            ),
            const SizedBox(height: 10),
            _actionTile(
              context,
              Icons.notifications_active_rounded,
              'Signal Stream & Alerts',
              'View live driver safety notifications & event log',
              NeonColors.neonYellow,
              () {
                Navigator.pushNamed(context, '/notifications');
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showEsp32DiscoveryModal(BuildContext context) {
    final TextEditingController ipCtrl = TextEditingController(text: '192.168.4.1');
    bool isScanning = false;
    Esp32DeviceStatus? status;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: NeonColors.card,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) {
          return Padding(
            padding: EdgeInsets.fromLTRB(24, 24, 24, MediaQuery.of(ctx).viewInsets.bottom + 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text("ESP32 Sensor Node Link", style: TextStyle(color: NeonColors.text, fontSize: 16, fontWeight: FontWeight.w900)),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: (status?.isConnected ?? false) ? NeonColors.primaryGreen.withOpacity(0.15) : NeonColors.surfaceMuted,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        (status?.isConnected ?? false) ? "NODE ONLINE" : "STANDBY",
                        style: TextStyle(
                          color: (status?.isConnected ?? false) ? NeonColors.primaryGreen : NeonColors.subtext,
                          fontWeight: FontWeight.w900,
                          fontSize: 9,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  "Connect to ESP32 Wi-Fi AP ('SmartDrive-ESP32-NODE' / pass: 'password123') and tap Detect Node.",
                  style: TextStyle(color: NeonColors.subtext, fontSize: 11),
                ),
                const SizedBox(height: 18),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: ipCtrl,
                        style: TextStyle(color: NeonColors.text, fontSize: 12),
                        decoration: InputDecoration(
                          hintText: "Node IP (e.g. 192.168.4.1)",
                          hintStyle: TextStyle(color: NeonColors.subtext, fontSize: 12),
                          filled: true,
                          fillColor: NeonColors.surfaceMuted,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: NeonColors.border)),
                          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: NeonColors.border)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    ElevatedButton(
                      onPressed: isScanning
                          ? null
                          : () async {
                              setModalState(() => isScanning = true);
                              final res = await Esp32Service.probeNode(ip: ipCtrl.text.trim());
                              setModalState(() {
                                isScanning = false;
                                status = res;
                              });
                            },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: NeonColors.primaryGreen,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                      ),
                      child: isScanning
                          ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                          : const Text("DETECT NODE", style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 11)),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                if (status != null) ...[
                  if (status!.isConnected) ...[
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: NeonColors.primaryGreen.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: NeonColors.primaryGreen.withOpacity(0.3)),
                      ),
                      child: Column(
                        children: [
                          _diagnosticRow("DEVICE ID", status!.deviceId),
                          _diagnosticRow("FIRMWARE", status!.firmwareVersion),
                          _diagnosticRow("IMU SENSOR", status!.sensorConnected ? "MPU-9250 (Active)" : "Disconnected"),
                          _diagnosticRow("ACCELEROMETER", "X:${status!.ax.toStringAsFixed(2)}  Y:${status!.ay.toStringAsFixed(2)}  Z:${status!.az.toStringAsFixed(2)}"),
                          _diagnosticRow("GYROSCOPE", "X:${status!.gx.toStringAsFixed(2)}  Y:${status!.gy.toStringAsFixed(2)}  Z:${status!.gz.toStringAsFixed(2)}"),
                          _diagnosticRow("FREE HEAP", "${status!.freeHeap} bytes"),
                          _diagnosticRow("NODE UPTIME", "${status!.uptime} seconds"),
                          const SizedBox(height: 12),
                          ElevatedButton.icon(
                            onPressed: () async {
                              final success = await Esp32Service.toggleLed(ip: ipCtrl.text.trim());
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(success ? "Toggled ESP32 Blue LED (GPIO 2)!" : "Failed to toggle LED"),
                                    backgroundColor: success ? const Color(0xFF3B82F6) : Colors.redAccent,
                                    behavior: SnackBarBehavior.floating,
                                  ),
                                );
                              }
                            },
                            icon: const Icon(Icons.lightbulb_rounded, color: Colors.white, size: 16),
                            label: const Text("TOGGLE BLUE LED (GPIO 2)", style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 10)),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF3B82F6),
                              minimumSize: const Size(double.infinity, 38),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ] else ...[
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.redAccent.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.redAccent.withOpacity(0.3)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.wifi_off_rounded, color: Colors.redAccent, size: 24),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              "Node not detected at ${ipCtrl.text}. Make sure the ESP32 is powered on and your device is connected to its Wi-Fi network.",
                              style: TextStyle(color: NeonColors.text, fontSize: 11, fontWeight: FontWeight.w600),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _diagnosticRow(String label, String val) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: NeonColors.subtext, fontSize: 9, fontWeight: FontWeight.w800)),
          Text(val, style: TextStyle(color: NeonColors.text, fontSize: 10, fontWeight: FontWeight.w900)),
        ],
      ),
    );
  }

  Widget _sectionLabel(String t) {
    return Text(t.toUpperCase(), style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: NeonColors.subtext, letterSpacing: 1.5));
  }

  Widget _buildThemeSlideBar(ThemeProvider theme) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: NeonColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: NeonColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(NeonColors.isDark ? 0.2 : 0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          _themeSegment(ThemeMode.light, Icons.light_mode_rounded, 'Light', theme),
          _themeSegment(ThemeMode.dark, Icons.dark_mode_rounded, 'Dark', theme),
          _themeSegment(ThemeMode.system, Icons.settings_suggest_rounded, 'System', theme),
        ],
      ),
    );
  }

  Widget _themeSegment(ThemeMode mode, IconData icon, String label, ThemeProvider theme) {
    final bool isSelected = theme.themeMode == mode;
    return Expanded(
      child: GestureDetector(
        onTap: () => theme.setThemeMode(mode),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? NeonColors.primaryGreen : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: NeonColors.primaryGreen.withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : [],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                color: isSelected ? Colors.white : NeonColors.subtext,
                size: 15,
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  color: isSelected ? Colors.white : NeonColors.subtext,
                  fontWeight: isSelected ? FontWeight.w900 : FontWeight.w700,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildModeCard(BuildContext context, String title, String sub, DriverType type, bool isSelected) {
    final authProv = Provider.of<AuthProvider>(context, listen: false);
    return GestureDetector(
      onTap: () => authProv.updateDriverType(type),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: NeonColors.card,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: isSelected ? NeonColors.primaryGreen : NeonColors.border,
            width: isSelected ? 1.5 : 1.0,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(NeonColors.isDark ? 0.2 : 0.04),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: TextStyle(fontWeight: FontWeight.w900, fontSize: 13.5, color: NeonColors.text)),
                  const SizedBox(height: 2),
                  Text(sub, style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w600, color: NeonColors.subtext)),
                ],
              ),
            ),
            if (isSelected)
              const Icon(Icons.check_circle_rounded, color: NeonColors.primaryGreen, size: 20),
          ],
        ),
      ),
    );
  }

  Widget _actionTile(BuildContext context, IconData icon, String title, String sub, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: NeonColors.card,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: NeonColors.border),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(NeonColors.isDark ? 0.2 : 0.04),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: color.withOpacity(0.12), borderRadius: BorderRadius.circular(12)),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: TextStyle(fontWeight: FontWeight.w900, fontSize: 13, color: NeonColors.text)),
                  const SizedBox(height: 2),
                  Text(sub, style: TextStyle(fontSize: 10.5, color: NeonColors.subtext, fontWeight: FontWeight.w600)),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded, color: NeonColors.subtext.withOpacity(0.5), size: 18),
          ],
        ),
      ),
    );
  }
}
