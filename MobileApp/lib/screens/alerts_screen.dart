import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/sensor_provider.dart';
import '../providers/trip_provider.dart';
import '../routes/app_routes.dart';
import '../models/event_model.dart';
import '../core/theme/hardware_theme.dart';
import '../core/theme/mechanical_motion.dart';
import '../services/sound_effect_service.dart';
import '../services/chatbot_service.dart';

class AlertsScreen extends StatefulWidget {
  const AlertsScreen({super.key});

  @override
  State<AlertsScreen> createState() => _AlertsScreenState();
}

class _AlertsScreenState extends State<AlertsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _chatCtrl = TextEditingController();
  final List<Map<String, dynamic>> _messages = [
    {
      'text': "SMART DRIVING AI DISPATCH ACTIVE. SENSOR TELEMETRY STREAM ONLINE (20 HZ). REPORT ANY ROAD HAZARDS OR IRREGULARITIES.",
      'isUser': false,
      'time': "00:00:01",
    },
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _chatCtrl.dispose();
    super.dispose();
  }

  void _sendMessage() async {
    final text = _chatCtrl.text.trim();
    if (text.isEmpty) return;

    SoundEffectService.playRelayLatch(isEngage: true);
    final now = DateFormat('hh:mm:ss a').format(DateTime.now());
    setState(() {
      _messages.add({'text': text.toUpperCase(), 'isUser': true, 'time': now});
    });
    _chatCtrl.clear();

    final trip = context.read<TripProvider>();
    final response = await ChatbotService.processQuery(text, safetyScore: trip.tripSafetyScore);

    if (mounted) {
      SoundEffectService.playTelemetryBeep();
      setState(() {
        _messages.add({'text': response.toUpperCase(), 'isUser': false, 'time': now});
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final sensor = Provider.of<SensorProvider>(context, listen: false);

    return Scaffold(
      backgroundColor: HardwarePalette.obsidianChassis,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(96),
        child: Container(
          decoration: BoxDecoration(
            color: HardwarePalette.charcoalSurface,
            border: Border(bottom: BorderSide(color: HardwarePalette.matrixBorder, width: 1.0)),
          ),
          child: SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          MechanicalPressable(
                            onTap: () {
                              if (Navigator.canPop(context)) {
                                Navigator.pop(context);
                              } else {
                                Navigator.pushReplacementNamed(context, AppRoutes.home);
                              }
                            },
                            child: Container(
                              height: 32,
                              width: 32,
                              decoration: HardwareDeco.stampedCard(
                                backgroundColor: HardwarePalette.moduleCard,
                                radius: 2,
                              ),
                              child: const Icon(Icons.arrow_back_ios_new_rounded, color: HardwarePalette.pureWhite, size: 14),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Text(
                            "TELEMETRY ALERTS & COMMS",
                            style: HardwareTypography.ndotHeader(fontSize: 13, color: HardwarePalette.pureWhite),
                          ),
                        ],
                      ),
                      Container(
                        width: 7,
                        height: 7,
                        decoration: const BoxDecoration(
                          color: HardwarePalette.neonActiveGreen,
                          shape: BoxShape.rectangle,
                        ),
                      ),
                    ],
                  ),
                ),
                TabBar(
                  controller: _tabController,
                  indicatorColor: HardwarePalette.neonActiveGreen,
                  indicatorWeight: 2,
                  indicatorSize: TabBarIndicatorSize.tab,
                  labelColor: HardwarePalette.neonActiveGreen,
                  unselectedLabelColor: HardwarePalette.chassisLabelDim,
                  labelStyle: HardwareTypography.jetBrainsLabel(fontSize: 9.5),
                  tabs: const [
                    Tab(text: "LIVE SENSOR FEED"),
                    Tab(text: "DISPATCH LOGS & COMMS"),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          Consumer<SensorProvider>(
            builder: (context, liveSensor, _) => _buildSensorAlertsTab(liveSensor),
          ),
          _buildChatTab(),
        ],
      ),
    );
  }

  Widget _buildSensorAlertsTab(SensorProvider sensor) {
    final alerts = sensor.recentAlerts;
    final hasDefect = sensor.hasAnyDefect;
    final defects = sensor.defectDescriptions;

    return ListView(
      physics: const ClampingScrollPhysics(),
      padding: const EdgeInsets.all(14),
      children: [
        // ── SENSOR FAULT / DEFECT DIAGNOSTIC BANNER ──
        if (hasDefect) ...[
          Container(
            padding: const EdgeInsets.all(12),
            margin: const EdgeInsets.only(bottom: 12),
            decoration: HardwareDeco.stampedCard(
              backgroundColor: const Color(0xFF330D0D),
              borderColor: HardwarePalette.criticalRed,
              radius: 2,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.warning_rounded, color: HardwarePalette.criticalRed, size: 16),
                    const SizedBox(width: 8),
                    Text(
                      "HARDWARE SENSOR DEFECT DETECTED",
                      style: HardwareTypography.ndotHeader(color: HardwarePalette.criticalRed, fontSize: 11),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                ...defects.map(
                  (d) => Padding(
                    padding: const EdgeInsets.only(bottom: 2),
                    child: Text(
                      "• $d",
                      style: HardwareTypography.jetBrainsBody(color: const Color(0xFFFCA5A5), fontSize: 9.5),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],

        // 1. Live IMU Status Card (Flat Boxy Chassis)
        Container(
          padding: const EdgeInsets.all(14),
          decoration: HardwareDeco.stampedCard(
            backgroundColor: HardwarePalette.charcoalSurface,
            radius: 2,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: HardwareDeco.stampedCard(
                          backgroundColor: HardwarePalette.debossedChassis,
                          radius: 2,
                        ),
                        child: Icon(
                          sensor.isEsp32Connected ? Icons.speed_rounded : Icons.sensors_off_rounded,
                          color: sensor.isEsp32Connected ? HardwarePalette.neonActiveGreen : HardwarePalette.chassisLabelDim,
                          size: 16,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        "LIVE IMU SENSOR CHASSIS",
                        style: HardwareTypography.ndotHeader(color: HardwarePalette.pureWhite, fontSize: 11),
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: HardwareDeco.stampedCard(
                      backgroundColor: HardwarePalette.debossedChassis,
                      borderColor: sensor.isEsp32Connected ? HardwarePalette.neonActiveGreen : HardwarePalette.matrixBorder,
                      radius: 2,
                    ),
                    child: Text(
                      sensor.isEsp32Connected ? "ONLINE (ESP32)" : "NOT CONNECTED",
                      style: HardwareTypography.jetBrainsLabel(
                        color: sensor.isEsp32Connected ? HardwarePalette.neonActiveGreen : HardwarePalette.chassisLabelDim,
                        fontSize: 8.5,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                "DATA FEED: ${sensor.isEsp32Connected ? 'ESP32 HARDWARE CHASSIS NODE' : 'PHONE BUILT-IN 6-AXIS MOTION SENSORS'}",
                style: HardwareTypography.jetBrainsLabel(
                  color: sensor.isEsp32Connected ? HardwarePalette.neonActiveGreen : const Color(0xFF38BDF8),
                  fontSize: 7.5,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  _telemetryTile(
                    "GYRO YAW",
                    "${sensor.gyroZ.toStringAsFixed(2)} RAD/S",
                    Icons.screen_rotation_rounded,
                    const Color(0xFF38BDF8),
                    sensor.isEsp32Connected ? "ESP32 Gyro" : "Phone Gyro",
                  ),
                  const SizedBox(width: 8),
                  _telemetryTile(
                    "VIBRATION",
                    "${sensor.vibrationRate.toStringAsFixed(2)} M/S²",
                    Icons.vibration_rounded,
                    HardwarePalette.industrialAmber,
                    "Filtered",
                  ),
                  const SizedBox(width: 8),
                  _telemetryTile(
                    "G-FORCE",
                    "${sensor.gForceY.abs().toStringAsFixed(2)} G",
                    Icons.directions_car_rounded,
                    HardwarePalette.neonActiveGreen,
                    sensor.isEsp32Connected ? "ESP32 Accel" : "Phone Accel",
                  ),
                ],
              ),
            ],
          ),
        ),

        const SizedBox(height: 14),

        // 2. Quick Test Simulation Triggers
        Text(
          "TEST HARDWARE EVENT INJECTION",
          style: HardwareTypography.jetBrainsLabel(color: HardwarePalette.chassisLabelDim, fontSize: 9.0),
        ),
        const SizedBox(height: 8),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          physics: const ClampingScrollPhysics(),
          child: Row(
            children: [
              _testBtn("GYRO SWERVE", () => sensor.simulateSensorAlert("gyro"), const Color(0xFF38BDF8)),
              const SizedBox(width: 6),
              _testBtn("ROAD VIBRATION", () => sensor.simulateSensorAlert("vibration"), HardwarePalette.industrialAmber),
              const SizedBox(width: 6),
              _testBtn("POTHOLE IMPACT", () => sensor.simulateSensorAlert("pothole"), HardwarePalette.industrialAmber),
              const SizedBox(width: 6),
              _testBtn("HARSH BRAKING", () => sensor.simulateSensorAlert("braking"), HardwarePalette.criticalRed),
            ],
          ),
        ),

        const SizedBox(height: 16),

        // 3. Alert History Log
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              "RECENT SENSOR EVENTS (${alerts.length})",
              style: HardwareTypography.ndotHeader(color: HardwarePalette.pureWhite, fontSize: 11),
            ),
            if (alerts.isNotEmpty)
              Text(
                "20 HZ LOG",
                style: HardwareTypography.jetBrainsLabel(color: HardwarePalette.chassisLabelDim, fontSize: 8.5),
              ),
          ],
        ),
        const SizedBox(height: 8),

        if (alerts.isEmpty)
          Container(
            padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 16),
            decoration: HardwareDeco.stampedCard(
              backgroundColor: HardwarePalette.charcoalSurface,
              radius: 2,
            ),
            child: Column(
              children: [
                const Icon(Icons.verified_user_outlined, color: HardwarePalette.neonActiveGreen, size: 36),
                const SizedBox(height: 10),
                Text(
                  "NO HAZARDS DETECTED IN BUFFER",
                  style: HardwareTypography.ndotHeader(color: HardwarePalette.pureWhite, fontSize: 11),
                ),
                const SizedBox(height: 4),
                Text(
                  "Gyroscope, accelerometer, and chassis sensors running nominally.",
                  textAlign: TextAlign.center,
                  style: HardwareTypography.jetBrainsBody(color: HardwarePalette.chassisLabelDim, fontSize: 10.5),
                ),
              ],
            ),
          )
        else
          ...alerts.map((a) => _buildAlertCard(a)),
      ],
    );
  }

  Widget _testBtn(String title, VoidCallback onTap, Color color) {
    return MechanicalPressable(
      onTap: () {
        SoundEffectService.playNotchTick();
        onTap();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
        decoration: HardwareDeco.stampedCard(
          backgroundColor: HardwarePalette.moduleCard,
          borderColor: color.withValues(alpha: 0.4),
          radius: 2,
        ),
        child: Text(
          title,
          style: HardwareTypography.jetBrainsLabel(color: color, fontSize: 9.0),
        ),
      ),
    );
  }

  Widget _telemetryTile(String label, String val, IconData icon, Color color, [String? source]) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        decoration: HardwareDeco.stampedCard(
          backgroundColor: HardwarePalette.debossedChassis,
          radius: 2,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 14),
            const SizedBox(height: 4),
            Text(
              val,
              style: HardwareTypography.ndotNumber(color: HardwarePalette.pureWhite, fontSize: 11),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: HardwareTypography.jetBrainsLabel(color: HardwarePalette.chassisLabelDim, fontSize: 7.5),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            if (source != null) ...[
              const SizedBox(height: 2),
              Text(
                source,
                style: HardwareTypography.jetBrainsLabel(color: color.withOpacity(0.8), fontSize: 7.0),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildAlertCard(SafetyEvent a) {
    Color color = HardwarePalette.industrialAmber;
    IconData icon = Icons.warning_amber_rounded;

    final lower = a.type.toLowerCase();
    if (lower.contains("gyro") || lower.contains("swerve")) {
      color = const Color(0xFF38BDF8);
      icon = Icons.screen_rotation_rounded;
    } else if (lower.contains("vibration") || lower.contains("pothole")) {
      color = HardwarePalette.industrialAmber;
      icon = Icons.vibration_rounded;
    } else if (lower.contains("braking") || lower.contains("crash")) {
      color = HardwarePalette.criticalRed;
      icon = Icons.speed_rounded;
    }

    final timeStr = DateFormat('hh:mm:ss a').format(a.timestamp);

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: HardwareDeco.stampedCard(
        backgroundColor: HardwarePalette.charcoalSurface,
        borderColor: color.withValues(alpha: 0.6),
        radius: 2,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: HardwareDeco.stampedCard(
                  backgroundColor: HardwarePalette.debossedChassis,
                  borderColor: color,
                  radius: 2,
                ),
                child: Icon(icon, color: color, size: 16),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      a.type.toUpperCase(),
                      style: HardwareTypography.ndotHeader(color: HardwarePalette.pureWhite, fontSize: 11),
                    ),
                    Text(
                      "TIME: $timeStr",
                      style: HardwareTypography.jetBrainsLabel(color: HardwarePalette.chassisLabelDim, fontSize: 8.5),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: HardwareDeco.stampedCard(
                  backgroundColor: HardwarePalette.debossedChassis,
                  borderColor: color,
                  radius: 2,
                ),
                child: Text(
                  a.triggerValue.toStringAsFixed(2),
                  style: HardwareTypography.ndotNumber(color: color, fontSize: 11),
                ),
              ),
            ],
          ),
          if (a.aiTip.isNotEmpty) ...[
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: HardwareDeco.stampedCard(
                backgroundColor: HardwarePalette.debossedChassis,
                radius: 2,
              ),
              child: Row(
                children: [
                  Icon(Icons.lightbulb_outline_rounded, color: color, size: 13),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      a.aiTip.toUpperCase(),
                      style: HardwareTypography.jetBrainsBody(color: HardwarePalette.chassisLabelLight, fontSize: 9.5),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildChatTab() {
    return Column(
      children: [
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(14),
            physics: const ClampingScrollPhysics(),
            itemCount: _messages.length,
            itemBuilder: (context, i) {
              final m = _messages[i];
              final bool isUser = m['isUser'] as bool;
              return Align(
                alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
                child: Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.82),
                  padding: const EdgeInsets.all(10),
                  decoration: HardwareDeco.stampedCard(
                    backgroundColor: isUser ? const Color(0xFF162B1D) : HardwarePalette.charcoalSurface,
                    borderColor: isUser ? HardwarePalette.neonActiveGreen : HardwarePalette.matrixBorder,
                    radius: 2,
                  ),
                  child: Column(
                    crossAxisAlignment: isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                    children: [
                      Text(
                        m['text'],
                        style: HardwareTypography.jetBrainsBody(
                          color: isUser ? HardwarePalette.neonActiveGreen : HardwarePalette.pureWhite,
                          fontSize: 11,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        m['time'] ?? "",
                        style: HardwareTypography.jetBrainsLabel(
                          color: HardwarePalette.chassisLabelDim,
                          fontSize: 8.0,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: HardwarePalette.charcoalSurface,
            border: Border(top: BorderSide(color: HardwarePalette.matrixBorder, width: 1.0)),
          ),
          child: Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  decoration: HardwareDeco.stampedCard(
                    backgroundColor: HardwarePalette.debossedChassis,
                    radius: 2,
                  ),
                  child: TextField(
                    controller: _chatCtrl,
                    style: HardwareTypography.jetBrainsBody(color: HardwarePalette.pureWhite, fontSize: 11),
                    decoration: InputDecoration(
                      hintText: "TRANSMIT DISPATCH PACKET...",
                      hintStyle: HardwareTypography.jetBrainsLabel(color: HardwarePalette.chassisLabelDim, fontSize: 9.5),
                      border: InputBorder.none,
                    ),
                    onSubmitted: (_) => _sendMessage(),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              MechanicalPressable(
                onTap: _sendMessage,
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: HardwareDeco.stampedCard(
                    backgroundColor: HardwarePalette.neonActiveGreen,
                    radius: 2,
                  ),
                  child: const Icon(Icons.send_rounded, color: Colors.black, size: 16),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
