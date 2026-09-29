import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../core/theme/hardware_theme.dart';
import '../providers/sensor_provider.dart';
import '../services/esp32_service.dart';
import '../services/haptic_service.dart';

class SensorRadarModal extends StatefulWidget {
  const SensorRadarModal({super.key});

  static void show(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => const SensorRadarModal(),
    );
  }

  @override
  State<SensorRadarModal> createState() => _SensorRadarModalState();
}

class _SensorRadarModalState extends State<SensorRadarModal> {
  final TextEditingController _ipController = TextEditingController(text: Esp32Service.defaultNodeIp);
  int _selectedTab = 0; // 0: Telemetry View, 1: External Hardware / BLE
  bool _isBleScanning = false;
  BluetoothDevice? _connectingDevice;

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _ipController.dispose();
    Esp32Service.stopBleScan();
    super.dispose();
  }

  Future<void> _startBleScan() async {
    setState(() => _isBleScanning = true);
    HapticService.lightImpact();
    await Esp32Service.startBleScan(timeout: const Duration(seconds: 6));
    if (mounted) setState(() => _isBleScanning = false);
  }

  Future<void> _connectBleDevice(BluetoothDevice device) async {
    setState(() => _connectingDevice = device);
    HapticService.selectionClick();
    final sensor = context.read<SensorProvider>();
    final ok = await sensor.connectBle(device);
    if (mounted) {
      setState(() => _connectingDevice = null);
      if (ok) {
        setState(() => _selectedTab = 0);
      }
    }
  }

  Future<void> _connectWifiNode() async {
    final sensor = context.read<SensorProvider>();
    HapticService.selectionClick();
    final ok = await sensor.scanAndConnectEsp32(ip: _ipController.text.trim());
    if (mounted && ok) {
      setState(() => _selectedTab = 0);
    }
  }

  @override
  Widget build(BuildContext context) {
    final sensor = context.watch<SensorProvider>();
    final isConnected = sensor.isEsp32Connected;

    // Unified telemetry values regardless of source
    final double gx = sensor.gyroX;
    final double gy = sensor.gyroY;
    final double gz = sensor.gyroZ;
    final double degX = sensor.gyroDegX;
    final double degY = sensor.gyroDegY;
    final double degZ = sensor.gyroDegZ;
    final double totalAngular = sensor.totalAngularSpeed;

    final double ax = sensor.gForceX;
    final double ay = sensor.gForceY;
    final double az = sensor.gForceZ;
    final double totalG = sensor.totalGForce;
    final double vib = sensor.vibrationRate;

    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: const BoxDecoration(
        color: Color(0xFFF5F2EB),
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          // Drag handle
          const SizedBox(height: 12),
          Container(
            width: 36,
            height: 4,
            decoration: BoxDecoration(
              color: HardwarePalette.mechanicalScrew,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 14),

          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "SENSOR TELEMETRY",
                        style: GoogleFonts.spaceGrotesk(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          color: HardwarePalette.signalEmerald,
                          letterSpacing: 1.2,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        isConnected ? "ESP32 Chassis Node Fused" : "Phone Sensors (Chassis IMU Not Connected)",
                        style: GoogleFonts.spaceGrotesk(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: HardwarePalette.silkscreenDark,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: Icon(Icons.close_rounded, color: HardwarePalette.silkscreenDark, size: 20),
                  onPressed: () => Navigator.pop(context),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Tab Bar (Telemetry vs Hardware Link)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: HardwarePalette.debossedSlot,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: HardwarePalette.matrixBorderLight),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => _selectedTab = 0),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        decoration: BoxDecoration(
                          color: _selectedTab == 0 ? Colors.white : Colors.transparent,
                          borderRadius: BorderRadius.circular(8),
                          boxShadow: _selectedTab == 0
                              ? [
                                  BoxShadow(
                                    color: const Color(0xFF23201C).withOpacity(0.04),
                                    blurRadius: 4,
                                    offset: const Offset(0, 2),
                                  ),
                                ]
                              : [],
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          "Live Telemetry",
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w700,
                            color: _selectedTab == 0 ? HardwarePalette.silkscreenDark : HardwarePalette.silkscreenSubtle,
                          ),
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        setState(() => _selectedTab = 1);
                        if (!isConnected && !_isBleScanning) _startBleScan();
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        decoration: BoxDecoration(
                          color: _selectedTab == 1 ? Colors.white : Colors.transparent,
                          borderRadius: BorderRadius.circular(8),
                          boxShadow: _selectedTab == 1
                              ? [
                                  BoxShadow(
                                    color: const Color(0xFF23201C).withOpacity(0.04),
                                    blurRadius: 4,
                                    offset: const Offset(0, 2),
                                  ),
                                ]
                              : [],
                        ),
                        alignment: Alignment.center,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              "Hardware Node",
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 12.5,
                                fontWeight: FontWeight.w700,
                                color: _selectedTab == 1 ? HardwarePalette.silkscreenDark : HardwarePalette.silkscreenSubtle,
                              ),
                            ),
                            if (isConnected) ...[
                              const SizedBox(width: 5),
                              Container(
                                width: 6,
                                height: 6,
                                decoration: const BoxDecoration(
                                  color: HardwarePalette.signalEmerald,
                                  shape: BoxShape.circle,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 14),

          // Body Content
          Expanded(
            child: _selectedTab == 0
                ? _buildTelemetryView(gx, gy, gz, degX, degY, degZ, totalAngular, ax, ay, az, totalG, vib, isConnected, sensor)
                : _buildHardwareNodeView(sensor, isConnected),
          ),
        ],
      ),
    );
  }

  Widget _buildTelemetryView(
    double gx, double gy, double gz,
    double degX, double degY, double degZ, double totalAngular,
    double ax, double ay, double az, double totalG, double vib,
    bool isConnected, SensorProvider sensor,
  ) {
    return ListView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
      children: [
        // 0. Hardware Sensor Attribution & Health Matrix
        _buildSensorHardwareMatrix(sensor),
        const SizedBox(height: 14),

        // 1. Gyroscope 3-Axis Section
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: HardwarePalette.matrixBorderLight),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF23201C).withOpacity(0.03),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.screen_rotation_rounded, color: Color(0xFF0284C7), size: 16),
                          const SizedBox(width: 8),
                          Text(
                            "3-AXIS GYROSCOPE",
                            style: GoogleFonts.spaceGrotesk(
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              color: const Color(0xFF0284C7),
                              letterSpacing: 1.0,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        "DATA SOURCE: ${isConnected ? 'ESP32 CHASSIS GYRO' : 'PHONE BUILT-IN GYRO'}",
                        style: GoogleFonts.jetBrainsMono(
                          fontSize: 8.5,
                          fontWeight: FontWeight.w700,
                          color: isConnected ? HardwarePalette.signalEmerald : const Color(0xFF0284C7),
                        ),
                      ),
                    ],
                  ),
                  Text(
                    "${totalAngular.toStringAsFixed(2)} rad/s",
                    style: GoogleFonts.spaceGrotesk(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: HardwarePalette.silkscreenDark,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  _axisValueBox("PITCH (X)", "${degX.toStringAsFixed(1)}°/s", "${gx.toStringAsFixed(2)} rad/s"),
                  const SizedBox(width: 8),
                  _axisValueBox("ROLL (Y)", "${degY.toStringAsFixed(1)}°/s", "${gy.toStringAsFixed(2)} rad/s"),
                  const SizedBox(width: 8),
                  _axisValueBox("YAW (Z)", "${degZ.toStringAsFixed(1)}°/s", "${gz.toStringAsFixed(2)} rad/s"),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),

        // 2. Accelerometer & G-Force Section
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: HardwarePalette.matrixBorderLight),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF23201C).withOpacity(0.03),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.speed_rounded, color: HardwarePalette.signalEmerald, size: 16),
                          const SizedBox(width: 8),
                          Text(
                            "ACCELERATION & G-FORCE",
                            style: GoogleFonts.spaceGrotesk(
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              color: HardwarePalette.signalEmerald,
                              letterSpacing: 1.0,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        "DATA SOURCE: ${isConnected ? 'ESP32 CHASSIS ACCEL' : 'PHONE BUILT-IN ACCEL'}",
                        style: GoogleFonts.jetBrainsMono(
                          fontSize: 8.5,
                          fontWeight: FontWeight.w700,
                          color: isConnected ? HardwarePalette.signalEmerald : const Color(0xFF0284C7),
                        ),
                      ),
                    ],
                  ),
                  Text(
                    "${totalG.toStringAsFixed(2)} G",
                    style: GoogleFonts.spaceGrotesk(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: totalG > 1.8 ? const Color(0xFFEF4444) : HardwarePalette.silkscreenDark,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  _axisValueBox("LATERAL (X)", "${ax.toStringAsFixed(2)} G", "${(ax * 9.81).toStringAsFixed(1)} m/s²"),
                  const SizedBox(width: 8),
                  _axisValueBox("LONGIT (Y)", "${ay.toStringAsFixed(2)} G", "${(ay * 9.81).toStringAsFixed(1)} m/s²"),
                  const SizedBox(width: 8),
                  _axisValueBox("VERTICAL (Z)", "${az.toStringAsFixed(2)} G", "${(az * 9.81).toStringAsFixed(1)} m/s²"),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),

        // 3. Attitude & Orientation Bubble Meter
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: HardwarePalette.matrixBorderLight),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF23201C).withOpacity(0.03),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              // Bubble level
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: HardwarePalette.debossedSlot,
                  border: Border.all(color: HardwarePalette.matrixBorderLight),
                ),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Container(width: 1, height: 60, color: HardwarePalette.matrixBorderLight),
                    Container(height: 1, width: 60, color: HardwarePalette.matrixBorderLight),
                    Transform.translate(
                      offset: Offset(
                        (ax * 20).clamp(-26.0, 26.0),
                        (ay * -20).clamp(-26.0, 26.0),
                      ),
                      child: Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          color: totalG > 1.8 ? const Color(0xFFEF4444) : HardwarePalette.signalEmerald,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "VEHICLE ATTITUDE",
                      style: GoogleFonts.spaceGrotesk(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w700,
                        color: HardwarePalette.silkscreenSubtle,
                        letterSpacing: 0.8,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      vib > 3.5 ? "Heavy Vibration Detected" : (totalAngular > 1.8 ? "Sharp Rotational Swerve" : "Stable & Level"),
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: (vib > 3.5 || totalAngular > 1.8) ? const Color(0xFFD97706) : HardwarePalette.signalEmerald,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      "Vibration: ${vib.toStringAsFixed(2)} m/s² · Sample rate: 20 Hz",
                      style: GoogleFonts.plusJakartaSans(fontSize: 11, color: HardwarePalette.silkscreenSubtle),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // 4. Test Alert Simulation Strip
        Text(
          "SAFETY SIMULATION & TEST TRIGGERS",
          style: GoogleFonts.spaceGrotesk(
            fontSize: 10.5,
            fontWeight: FontWeight.w700,
            color: HardwarePalette.silkscreenSubtle,
            letterSpacing: 1.0,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: _testButton("Gyro Swerve", Icons.rotate_right_rounded, () {
                sensor.simulateSensorAlert("gyro");
              }),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _testButton("Road Bump", Icons.waves_rounded, () {
                sensor.simulateSensorAlert("pothole");
              }),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _testButton("Hard Braking", Icons.warning_amber_rounded, () {
                sensor.simulateSensorAlert("braking");
              }),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildHardwareNodeView(SensorProvider sensor, bool isConnected) {
    return ListView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
      children: [
        // Connection status card
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isConnected ? HardwarePalette.signalEmerald : HardwarePalette.matrixBorderLight,
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF23201C).withOpacity(0.03),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: isConnected ? const Color(0xFFECFDF5) : HardwarePalette.debossedSlot,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  isConnected ? Icons.bluetooth_connected_rounded : Icons.sensors_off_rounded,
                  color: isConnected ? HardwarePalette.signalEmerald : HardwarePalette.silkscreenSubtle,
                  size: 20,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isConnected ? "CHASSIS IMU: CONNECTED (ESP32)" : "CHASSIS IMU: NOT CONNECTED",
                      style: GoogleFonts.spaceGrotesk(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: isConnected ? HardwarePalette.signalEmerald : HardwarePalette.silkscreenDark,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      isConnected
                          ? "Streaming 6-Axis IMU telemetry from vehicle chassis"
                          : "No external chassis node paired. Using phone's built-in sensors.",
                      style: GoogleFonts.plusJakartaSans(fontSize: 11.5, color: HardwarePalette.silkscreenSubtle),
                    ),
                  ],
                ),
              ),
              if (isConnected)
                TextButton(
                  onPressed: () => sensor.disconnectEsp32(),
                  child: Text("Unlink", style: GoogleFonts.outfit(color: const Color(0xFFDC2626), fontWeight: FontWeight.w700)),
                ),
            ],
          ),
        ),
        const SizedBox(height: 18),

        // BLE Scanner Section
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              "NEARBY BLUETOOTH NODES",
              style: GoogleFonts.spaceGrotesk(
                fontSize: 10.5,
                fontWeight: FontWeight.w700,
                color: HardwarePalette.silkscreenSubtle,
                letterSpacing: 1.0,
              ),
            ),
            IconButton(
              icon: _isBleScanning
                  ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: HardwarePalette.signalEmerald))
                  : const Icon(Icons.refresh_rounded, color: HardwarePalette.signalEmerald, size: 18),
              onPressed: _isBleScanning ? null : _startBleScan,
            ),
          ],
        ),
        const SizedBox(height: 6),

        StreamBuilder<List<ScanResult>>(
          stream: Esp32Service.scanResults,
          builder: (context, snapshot) {
            final results = snapshot.data ?? [];
            if (results.isEmpty) {
              return Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: HardwarePalette.matrixBorderLight),
                ),
                alignment: Alignment.center,
                child: Text(
                  _isBleScanning ? "Scanning for ESP32 sensor nodes..." : "No Bluetooth devices found. Tap refresh to scan.",
                  style: GoogleFonts.plusJakartaSans(fontSize: 12, color: HardwarePalette.silkscreenSubtle),
                ),
              );
            }

            return Column(
              children: results.map((r) {
                final name = r.device.platformName.isNotEmpty ? r.device.platformName : r.advertisementData.advName;
                final isConnecting = _connectingDevice?.remoteId == r.device.remoteId;
                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: HardwarePalette.matrixBorderLight),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.sensors_rounded, color: HardwarePalette.signalEmerald, size: 18),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              name.isNotEmpty ? name : "ESP32 Sensor (${r.device.remoteId.str.substring(0, math.min(8, r.device.remoteId.str.length))})",
                              style: GoogleFonts.plusJakartaSans(fontSize: 13, fontWeight: FontWeight.w700, color: HardwarePalette.silkscreenDark),
                            ),
                            Text("RSSI: ${r.rssi} dBm", style: GoogleFonts.spaceGrotesk(fontSize: 10.5, color: HardwarePalette.silkscreenSubtle)),
                          ],
                        ),
                      ),
                      GestureDetector(
                        onTap: isConnecting ? null : () => _connectBleDevice(r.device),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: HardwarePalette.signalEmerald,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: isConnecting
                              ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                              : Text("Connect", style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.w700, color: Colors.white)),
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            );
          },
        ),
        const SizedBox(height: 18),

        // Wi-Fi Direct Option
        Text(
          "WI-FI DIRECT FALLBACK",
          style: GoogleFonts.spaceGrotesk(
            fontSize: 10.5,
            fontWeight: FontWeight.w700,
            color: HardwarePalette.silkscreenSubtle,
            letterSpacing: 1.0,
          ),
        ),
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: HardwarePalette.matrixBorderLight),
          ),
          child: Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: _ipController,
                  style: GoogleFonts.spaceGrotesk(color: HardwarePalette.silkscreenDark, fontSize: 13),
                  decoration: InputDecoration(
                    hintText: "192.168.4.1",
                    hintStyle: TextStyle(color: HardwarePalette.silkscreenSubtle),
                    border: InputBorder.none,
                    isDense: true,
                  ),
                ),
              ),
              GestureDetector(
                onTap: _connectWifiNode,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0284C7),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text("Link Wi-Fi", style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.w700, color: Colors.white)),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _axisValueBox(String label, String primary, String secondary) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
        decoration: BoxDecoration(
          color: HardwarePalette.debossedSlot,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: HardwarePalette.matrixBorderLight),
        ),
        child: Column(
          children: [
            Text(
              label,
              style: GoogleFonts.spaceGrotesk(
                fontSize: 9,
                fontWeight: FontWeight.w700,
                color: HardwarePalette.silkscreenSubtle,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              primary,
              style: GoogleFonts.outfit(
                fontSize: 13,
                fontWeight: FontWeight.w800,
                color: HardwarePalette.silkscreenDark,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              secondary,
              style: GoogleFonts.spaceGrotesk(
                fontSize: 9,
                fontWeight: FontWeight.w600,
                color: HardwarePalette.silkscreenSubtle,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _testButton(String title, IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: () {
        HapticService.mediumImpact();
        onTap();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: HardwarePalette.matrixBorderLight),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF23201C).withOpacity(0.02),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: [
            Icon(icon, size: 18, color: HardwarePalette.signalEmerald),
            const SizedBox(height: 4),
            Text(
              title,
              textAlign: TextAlign.center,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 10.5,
                fontWeight: FontWeight.w700,
                color: HardwarePalette.silkscreenDark,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSensorHardwareMatrix(SensorProvider sensor) {
    final hasDefect = sensor.hasAnyDefect;
    final defects = sensor.defectDescriptions;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              "SENSOR ATTRIBUTION & HEALTH",
              style: GoogleFonts.spaceGrotesk(
                fontSize: 10.5,
                fontWeight: FontWeight.w800,
                color: HardwarePalette.silkscreenSubtle,
                letterSpacing: 1.0,
              ),
            ),
            if (hasDefect)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFFFEF2F2),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: const Color(0xFFEF4444)),
                ),
                child: Text(
                  "FAULT DETECTED",
                  style: GoogleFonts.jetBrainsMono(
                    fontSize: 8.5,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFFDC2626),
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 8),

        if (hasDefect) ...[
          Container(
            padding: const EdgeInsets.all(12),
            margin: const EdgeInsets.only(bottom: 10),
            decoration: BoxDecoration(
              color: const Color(0xFFFEF2F2),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFEF4444), width: 1.2),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.warning_rounded, color: Color(0xFFDC2626), size: 16),
                    const SizedBox(width: 6),
                    Text(
                      "SENSOR DIAGNOSTIC WARNING",
                      style: GoogleFonts.spaceGrotesk(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFFDC2626),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                ...defects.map(
                  (d) => Padding(
                    padding: const EdgeInsets.only(bottom: 3),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text("• ", style: TextStyle(color: Color(0xFFDC2626), fontWeight: FontWeight.bold)),
                        Expanded(
                          child: Text(
                            d,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF991B1B),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],

        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: HardwarePalette.matrixBorderLight),
          ),
          child: Column(
            children: [
              _sensorStatusRow(
                icon: Icons.speed_rounded,
                title: "Phone Accelerometer",
                dataSource: "Measures G-Force, Harsh Braking & Acceleration",
                statusLabel: sensor.phoneAccelStatus == SensorDeviceStatus.healthy ? "HEALTHY" : "DEFECTIVE",
                isHealthy: sensor.phoneAccelStatus == SensorDeviceStatus.healthy,
                isNotConnected: false,
              ),
              const Divider(height: 14, color: Color(0xFFF1EFE9)),

              _sensorStatusRow(
                icon: Icons.screen_rotation_rounded,
                title: "Phone Gyroscope",
                dataSource: "Measures Angular Velocity, Pitch/Roll & Swerves",
                statusLabel: sensor.phoneGyroStatus == SensorDeviceStatus.healthy ? "HEALTHY" : "DEFECTIVE",
                isHealthy: sensor.phoneGyroStatus == SensorDeviceStatus.healthy,
                isNotConnected: false,
              ),
              const Divider(height: 14, color: Color(0xFFF1EFE9)),

              _sensorStatusRow(
                icon: Icons.gps_fixed_rounded,
                title: "Phone GPS Receiver",
                dataSource: "Measures Live Speed, Distance & Route Map",
                statusLabel: sensor.gpsStatus == SensorDeviceStatus.healthy
                    ? "HEALTHY"
                    : (sensor.gpsStatus == SensorDeviceStatus.permissionDenied ? "PERMISSION DENIED" : "DEFECTIVE"),
                isHealthy: sensor.gpsStatus == SensorDeviceStatus.healthy,
                isNotConnected: false,
              ),
              const Divider(height: 14, color: Color(0xFFF1EFE9)),

              _sensorStatusRow(
                icon: Icons.developer_board_rounded,
                title: "Chassis IMU Node",
                dataSource: "Direct Axle Shock & Frame Vibration Telemetry",
                statusLabel: sensor.isEsp32Connected ? "CONNECTED" : "NOT CONNECTED",
                isHealthy: sensor.isEsp32Connected,
                isNotConnected: !sensor.isEsp32Connected,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _sensorStatusRow({
    required IconData icon,
    required String title,
    required String dataSource,
    required String statusLabel,
    required bool isHealthy,
    required bool isNotConnected,
  }) {
    Color statusColor;
    Color statusBg;
    if (isNotConnected) {
      statusColor = HardwarePalette.silkscreenSubtle;
      statusBg = HardwarePalette.debossedSlot;
    } else if (isHealthy) {
      statusColor = HardwarePalette.signalEmerald;
      statusBg = const Color(0xFFECFDF5);
    } else {
      statusColor = const Color(0xFFDC2626);
      statusBg = const Color(0xFFFEF2F2);
    }

    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: statusBg,
            shape: BoxShape.circle,
          ),
          child: Icon(icon, size: 16, color: statusColor),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: HardwarePalette.silkscreenDark,
                ),
              ),
              Text(
                dataSource,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 10,
                  color: HardwarePalette.silkscreenSubtle,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
          decoration: BoxDecoration(
            color: statusBg,
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: statusColor.withOpacity(0.4)),
          ),
          child: Text(
            statusLabel,
            style: GoogleFonts.jetBrainsMono(
              fontSize: 8.5,
              fontWeight: FontWeight.w800,
              color: statusColor,
            ),
          ),
        ),
      ],
    );
  }
}
