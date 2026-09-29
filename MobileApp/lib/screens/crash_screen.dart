import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../providers/trip_provider.dart';
import '../providers/auth_provider.dart';
import '../routes/app_routes.dart';
import '../core/theme/hardware_theme.dart';
import '../core/theme/mechanical_motion.dart';
import '../services/sound_effect_service.dart';

class CrashScreen extends StatelessWidget {
  const CrashScreen({super.key});

  void _call(String number) async {
    final url = 'tel:$number';
    if (await canLaunchUrl(Uri.parse(url))) await launchUrl(Uri.parse(url));
  }

  @override
  Widget build(BuildContext context) {
    final tripProv = Provider.of<TripProvider>(context);
    final authProv = Provider.of<AuthProvider>(context);
    final profile = authProv.profile;

    final kinName = profile.emergencyContactName.isNotEmpty
        ? profile.emergencyContactName
        : (profile.familyMemberName.isNotEmpty ? profile.familyMemberName : 'Family Kin / Parent');
    final kinPhone = profile.emergencyContactPhone.isNotEmpty
        ? profile.emergencyContactPhone
        : (profile.familyWhatsappNumber.isNotEmpty ? profile.familyWhatsappNumber : '');
    final kinRel = profile.familyRelationship.isNotEmpty ? profile.familyRelationship : 'Parent';

    return Scaffold(
      backgroundColor: HardwarePalette.obsidianChassis,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(56),
        child: Container(
          decoration: BoxDecoration(
            color: HardwarePalette.charcoalSurface,
            border: const Border(bottom: BorderSide(color: HardwarePalette.criticalRed, width: 1.0)),
          ),
          alignment: Alignment.bottomCenter,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              MechanicalPressable(
                onTap: () {
                  SoundEffectService.playRelayLatch();
                  tripProv.confirmSafe();
                  Navigator.pushReplacementNamed(context, AppRoutes.home);
                },
                child: Row(
                  children: [
                    const Icon(Icons.arrow_back_ios_new_rounded, color: HardwarePalette.criticalRed, size: 14),
                    const SizedBox(width: 4),
                    Text(
                      "RETURN DECK",
                      style: HardwareTypography.jetBrainsButton(fontSize: 10, color: HardwarePalette.criticalRed),
                    ),
                  ],
                ),
              ),
              Text(
                "CRITICAL EMERGENCY CHANNEL",
                style: HardwareTypography.ndotHeader(fontSize: 11, color: HardwarePalette.criticalRed),
              ),
            ],
          ),
        ),
      ),
      body: SafeArea(
        child: ListView(
          physics: const ClampingScrollPhysics(),
          padding: const EdgeInsets.all(14),
          children: [
            // High Urgency Alert Banner (Flat Boxy Chassis)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: HardwareDeco.stampedCard(
                backgroundColor: HardwarePalette.charcoalSurface,
                borderColor: HardwarePalette.criticalRed,
                radius: 2,
              ),
              child: Column(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: HardwareDeco.stampedCard(
                      backgroundColor: HardwarePalette.debossedChassis,
                      borderColor: HardwarePalette.criticalRed,
                      radius: 2,
                    ),
                    child: const Icon(Icons.emergency_rounded, color: HardwarePalette.criticalRed, size: 24),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    "COLLISION / IMPACT DETECTED",
                    style: HardwareTypography.ndotHeader(
                      fontSize: 13,
                      color: HardwarePalette.criticalRed,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    tripProv.crashReason.toUpperCase(),
                    textAlign: TextAlign.center,
                    style: HardwareTypography.jetBrainsBody(
                      fontSize: 11,
                      color: HardwarePalette.pureWhite,
                    ),
                  ),
                  if (tripProv.sosCountdown > 0) ...[
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: HardwareDeco.stampedCard(
                        backgroundColor: HardwarePalette.debossedChassis,
                        borderColor: HardwarePalette.criticalRed,
                        radius: 2,
                      ),
                      child: Text(
                        "AUTO ESCALATING IN ${tripProv.sosCountdown}S",
                        style: HardwareTypography.ndotNumber(
                          fontSize: 12,
                          color: HardwarePalette.criticalRed,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 14),

            // Primary Safety Confirmation Button
            MechanicalPressable(
              onTap: () {
                SoundEffectService.playSuccess();
                tripProv.confirmSafe();
                Navigator.pushReplacementNamed(context, AppRoutes.home);
              },
              child: Container(
                height: 48,
                decoration: HardwareDeco.stampedCard(
                  backgroundColor: HardwarePalette.neonActiveGreen,
                  radius: 2,
                ),
                alignment: Alignment.center,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.check_circle_rounded, color: Colors.black, size: 18),
                    const SizedBox(width: 8),
                    Text(
                      "I AM SAFE — CANCEL ALERT",
                      style: HardwareTypography.jetBrainsButton(
                        fontSize: 11,
                        color: Colors.black,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 10),

            // Immediate Escalation Button
            MechanicalPressable(
              onTap: () {
                SoundEffectService.playAlertTone();
                tripProv.escalateEmergency();
              },
              child: Container(
                height: 46,
                decoration: HardwareDeco.stampedCard(
                  backgroundColor: HardwarePalette.charcoalSurface,
                  borderColor: HardwarePalette.criticalRed,
                  radius: 2,
                ),
                alignment: Alignment.center,
                child: Text(
                  "TRIGGER IMMEDIATE SOS ESCALATION",
                  style: HardwareTypography.jetBrainsButton(
                    fontSize: 10.5,
                    color: HardwarePalette.criticalRed,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Telemetry Snapshot Card (NDot 57 Numbers)
            Text(
              "TELEMETRY INCIDENT SNAPSHOT",
              style: HardwareTypography.jetBrainsLabel(fontSize: 9.0),
            ),
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: HardwareDeco.stampedCard(
                backgroundColor: HardwarePalette.charcoalSurface,
                radius: 2,
              ),
              child: Column(
                children: [
                  _telemetryRow("IMPACT VELOCITY", "${tripProv.currentSpeed.toStringAsFixed(1)} KM/H"),
                  Divider(color: HardwarePalette.matrixBorder, height: 14),
                  _telemetryRow("PEAK G-FORCE", "${tripProv.maxGForce.toStringAsFixed(2)} G"),
                  Divider(color: HardwarePalette.matrixBorder, height: 14),
                  _telemetryRow("DISPATCH PROTOCOL", tripProv.isCrashDetected ? "LIVE FLEET ALERT ACTIVE" : "STANDBY BUFFER"),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Emergency Parent / Kin SOS Channel
            Text(
              "EMERGENCY PARENT / KIN SOS CHANNEL",
              style: HardwareTypography.jetBrainsLabel(fontSize: 9.0),
            ),
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: HardwareDeco.stampedCard(
                backgroundColor: HardwarePalette.charcoalSurface,
                borderColor: const Color(0xFFF43F5E),
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
                          const Icon(Icons.family_restroom_rounded, size: 16, color: Color(0xFFF43F5E)),
                          const SizedBox(width: 6),
                          Text(
                            "CRITICAL RESCUE RECIPIENT",
                            style: HardwareTypography.ndotHeader(fontSize: 10, color: const Color(0xFFF43F5E)),
                          ),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF43F5E).withOpacity(0.2),
                          borderRadius: BorderRadius.circular(2),
                        ),
                        child: Text(
                          kinRel.toUpperCase(),
                          style: HardwareTypography.jetBrainsLabel(fontSize: 8, color: const Color(0xFFF43F5E)),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    kinName.toUpperCase(),
                    style: HardwareTypography.jetBrainsButton(fontSize: 12, color: HardwarePalette.pureWhite),
                  ),
                  Text(
                    kinPhone.isNotEmpty ? kinPhone : "NO NUMBER REGISTERED",
                    style: HardwareTypography.jetBrainsLabel(fontSize: 10, color: HardwarePalette.silkscreenMuted),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: MechanicalPressable(
                          onTap: () {
                            SoundEffectService.playRelayLatch();
                            if (kinPhone.isNotEmpty) {
                              _call(kinPhone);
                            }
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 9),
                            decoration: HardwareDeco.stampedCard(
                              backgroundColor: const Color(0xFF1E293B),
                              borderColor: const Color(0xFF38BDF8),
                              radius: 2,
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.phone_in_talk_rounded, size: 14, color: Color(0xFF38BDF8)),
                                const SizedBox(width: 6),
                                Text(
                                  "CALL $kinRel".toUpperCase(),
                                  style: HardwareTypography.jetBrainsButton(fontSize: 9.5, color: const Color(0xFF38BDF8)),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: MechanicalPressable(
                          onTap: () {
                            SoundEffectService.playRelayLatch();
                            final sosMsg = "🚨 EMERGENCY SOS: I have been involved in an emergency incident while driving. "
                                "Velocity: ${tripProv.currentSpeed.toStringAsFixed(1)} KM/H, G-Force: ${tripProv.maxGForce.toStringAsFixed(2)}G. "
                                "Please call me or send assistance immediately!";
                            profile.openFamilyWhatsapp(customMessage: sosMsg);
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 9),
                            decoration: HardwareDeco.stampedCard(
                              backgroundColor: const Color(0xFF064E3B),
                              borderColor: const Color(0xFF10B981),
                              radius: 2,
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.chat_bubble_outline_rounded, size: 14, color: Color(0xFF10B981)),
                                const SizedBox(width: 6),
                                Text(
                                  "WHATSAPP SOS",
                                  style: HardwareTypography.jetBrainsButton(fontSize: 9.5, color: const Color(0xFF10B981)),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Emergency Contacts
            Text(
              "EMERGENCY HOTLINE FREQUENCIES",
              style: HardwareTypography.jetBrainsLabel(fontSize: 9.0),
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                Expanded(
                  child: _contactButton("POLICE (112)", Icons.local_police_rounded, () => _call("112")),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _contactButton("AMBULANCE (108)", Icons.medical_services_rounded, () => _call("108")),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _contactButton("FLEET ADMIN", Icons.headset_mic_rounded, () => _call("911")),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _telemetryRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: HardwareTypography.jetBrainsLabel(fontSize: 9.5)),
        Text(value, style: HardwareTypography.ndotNumber(fontSize: 12, color: HardwarePalette.pureWhite)),
      ],
    );
  }

  Widget _contactButton(String title, IconData icon, VoidCallback onTap) {
    return MechanicalPressable(
      onTap: () {
        SoundEffectService.playRelayLatch();
        onTap();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
        decoration: HardwareDeco.stampedCard(
          backgroundColor: HardwarePalette.moduleCard,
          radius: 2,
        ),
        child: Column(
          children: [
            Icon(icon, size: 16, color: const Color(0xFF38BDF8)),
            const SizedBox(height: 4),
            Text(
              title,
              textAlign: TextAlign.center,
              style: HardwareTypography.jetBrainsLabel(fontSize: 8.5, color: HardwarePalette.pureWhite),
            ),
          ],
        ),
      ),
    );
  }
}
