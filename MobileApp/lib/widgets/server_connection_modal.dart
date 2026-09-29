import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../core/constants/app_urls.dart';
import '../core/theme/hardware_theme.dart';
import '../services/discovery_service.dart';
import '../services/haptic_service.dart';
import '../services/socket_service.dart';

class ServerConnectionModal {
  static void show(BuildContext context) {
    HapticService.selectionClick();
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => const _ServerConnectionSheet(),
    );
  }
}

class _ServerConnectionSheet extends StatefulWidget {
  const _ServerConnectionSheet();

  @override
  State<_ServerConnectionSheet> createState() => _ServerConnectionSheetState();
}

class _ServerConnectionSheetState extends State<_ServerConnectionSheet> {
  late TextEditingController _hostCtrl;
  bool _isProbing = false;
  String? _probeStatus;
  bool _probeSuccess = false;

  @override
  void initState() {
    super.initState();
    _hostCtrl = TextEditingController(text: DiscoveryService.currentHost);
  }

  @override
  void dispose() {
    _hostCtrl.dispose();
    super.dispose();
  }

  Future<void> _testAndConnect(String host) async {
    setState(() {
      _isProbing = true;
      _probeStatus = "Probing server health...";
      _probeSuccess = false;
    });

    final target = host.trim();
    if (target.isEmpty) {
      setState(() {
        _isProbing = false;
        _probeStatus = "Please enter a valid IP or Cloud URL";
      });
      return;
    }

    final healthy = await DiscoveryService.probeHealth(target, timeoutMs: 2000);

    if (healthy) {
      await DiscoveryService.setManualHost(target);
      setState(() {
        _isProbing = false;
        _probeSuccess = true;
        _probeStatus = "Connected successfully to $target!";
      });
      HapticService.heavyImpact();
    } else {
      // Allow connecting anyway in case /health is behind tunnel proxy
      await DiscoveryService.setManualHost(target);
      setState(() {
        _isProbing = false;
        _probeSuccess = false;
        _probeStatus = "Server reachable or link set to: $target";
      });
      HapticService.selectionClick();
    }
  }

  Future<void> _autoDiscover() async {
    setState(() {
      _isProbing = true;
      _probeStatus = "Sweeping local network for backend...";
      _probeSuccess = false;
    });

    final found = await DiscoveryService.autoDiscoverHost(forceRefresh: true);
    if (found != null) {
      _hostCtrl.text = found;
      setState(() {
        _isProbing = false;
        _probeSuccess = true;
        _probeStatus = "Found backend server at $found!";
      });
      HapticService.heavyImpact();
    } else {
      setState(() {
        _isProbing = false;
        _probeSuccess = false;
        _probeStatus = "No local backend found on current subnet.";
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isConnected = SocketService.isConnected;
    final currentHost = SocketService.connectedHost ?? DiscoveryService.currentHost;

    return Container(
      padding: EdgeInsets.fromLTRB(20, 16, 20, MediaQuery.of(context).viewInsets.bottom + 24),
      decoration: BoxDecoration(
        color: HardwarePalette.milledSurface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        border: Border.all(color: HardwarePalette.matrixBorderLight, width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 44,
                height: 4,
                decoration: BoxDecoration(
                  color: HardwarePalette.silkscreenSubtle.withOpacity(0.4),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: isConnected
                        ? HardwarePalette.signalEmerald.withOpacity(0.12)
                        : Colors.red.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    isConnected ? Icons.cloud_done_rounded : Icons.cloud_off_rounded,
                    color: isConnected ? HardwarePalette.signalEmerald : Colors.redAccent,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "SERVER & CLOUD LINK",
                        style: GoogleFonts.spaceGrotesk(
                          fontSize: 14,
                          fontWeight: FontWeight.w900,
                          color: HardwarePalette.silkscreenDark,
                          letterSpacing: 0.5,
                        ),
                      ),
                      Text(
                        isConnected ? "ONLINE: $currentHost" : "OFFLINE / DISCONNECTED",
                        style: GoogleFonts.jetBrainsMono(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: isConnected ? HardwarePalette.signalEmerald : Colors.redAccent,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: isConnected
                        ? HardwarePalette.signalEmerald.withOpacity(0.15)
                        : Colors.red.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    isConnected ? "ACTIVE" : "OFFLINE",
                    style: GoogleFonts.spaceGrotesk(
                      fontSize: 10,
                      fontWeight: FontWeight.w900,
                      color: isConnected ? HardwarePalette.signalEmerald : Colors.redAccent,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),

            // Input Field
            Text(
              "BACKEND SERVER URL / CLOUD TUNNEL",
              style: GoogleFonts.spaceGrotesk(
                fontSize: 10,
                fontWeight: FontWeight.w800,
                color: HardwarePalette.silkscreenSubtle,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 6),
            Container(
              decoration: BoxDecoration(
                color: HardwarePalette.debossedSlot,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: HardwarePalette.matrixBorderLight, width: 1.0),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
              child: Row(
                children: [
                  const Icon(Icons.link_rounded, color: Colors.blueAccent, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: _hostCtrl,
                      style: GoogleFonts.jetBrainsMono(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                        color: HardwarePalette.silkscreenDark,
                      ),
                      decoration: const InputDecoration(
                        border: InputBorder.none,
                        hintText: "http://192.168.x.x:3000 or https://xyz.link",
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.paste_rounded, size: 18),
                    color: HardwarePalette.silkscreenSubtle,
                    onPressed: () async {
                      final data = await Clipboard.getData('text/plain');
                      if (data?.text != null && data!.text!.isNotEmpty) {
                        setState(() {
                          _hostCtrl.text = data.text!.trim();
                        });
                      }
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),

            // Status message
            if (_probeStatus != null) ...[
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: _probeSuccess
                      ? HardwarePalette.signalEmerald.withOpacity(0.1)
                      : Colors.orange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: _probeSuccess
                        ? HardwarePalette.signalEmerald.withOpacity(0.3)
                        : Colors.orange.withOpacity(0.3),
                  ),
                ),
                child: Row(
                  children: [
                    if (_isProbing)
                      const SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    else
                      Icon(
                        _probeSuccess ? Icons.check_circle_rounded : Icons.info_outline_rounded,
                        size: 16,
                        color: _probeSuccess ? HardwarePalette.signalEmerald : Colors.orange,
                      ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _probeStatus!,
                        style: GoogleFonts.spaceGrotesk(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: _probeSuccess ? HardwarePalette.signalEmerald : Colors.orange.shade800,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
            ],

            // Action Buttons
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _isProbing ? null : () => _testAndConnect(_hostCtrl.text),
                    icon: const Icon(Icons.bolt_rounded, size: 18),
                    label: const Text("CONNECT"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF10B981),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 13),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      textStyle: GoogleFonts.spaceGrotesk(fontWeight: FontWeight.w800, fontSize: 12),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _isProbing ? null : _autoDiscover,
                    icon: const Icon(Icons.wifi_find_rounded, size: 18),
                    label: const Text("DISCOVER"),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: HardwarePalette.silkscreenDark,
                      side: BorderSide(color: HardwarePalette.matrixBorderLight, width: 1.2),
                      padding: const EdgeInsets.symmetric(vertical: 13),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      textStyle: GoogleFonts.spaceGrotesk(fontWeight: FontWeight.w800, fontSize: 12),
                    ),
                  ),
                ),
              ],
            ),
            // No Network / Dead Zone Offline Buffer Status Card
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: HardwarePalette.debossedSlot,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: HardwarePalette.matrixBorderLight, width: 1.0),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.wifi_off_rounded, color: Color(0xFF38BDF8), size: 18),
                          const SizedBox(width: 8),
                          Text(
                            "NO NETWORK / DEAD ZONE BUFFER",
                            style: GoogleFonts.spaceGrotesk(
                              fontSize: 11,
                              fontWeight: FontWeight.w900,
                              color: HardwarePalette.silkscreenDark,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: SocketService.isGhatModeActive
                              ? const Color(0xFF38BDF8).withOpacity(0.2)
                              : HardwarePalette.signalEmerald.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          "${SocketService.offlineBufferedCount}/500 SAVED",
                          style: GoogleFonts.jetBrainsMono(
                            fontSize: 10,
                            fontWeight: FontWeight.w900,
                            color: SocketService.isGhatModeActive
                                ? const Color(0xFF38BDF8)
                                : HardwarePalette.signalEmerald,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    "When driving through basements, tunnels, or cellular dead zones with zero reception, telemetry and Roadside SOS alerts queue automatically in memory (up to 500 points). Upon regaining signal, they burst-sync immediately to HQ.",
                    style: GoogleFonts.spaceGrotesk(
                      fontSize: 10,
                      color: HardwarePalette.silkscreenSubtle,
                      height: 1.3,
                    ),
                  ),
                  if (SocketService.offlineBufferedCount > 0 && isConnected) ...[
                    const SizedBox(height: 10),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () {
                          HapticService.heavyImpact();
                          SocketService.forceSyncBuffer();
                          setState(() {});
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text("⚡ Buffer burst-synced to server!"),
                              duration: Duration(seconds: 2),
                            ),
                          );
                        },
                        icon: const Icon(Icons.sync_rounded, size: 16),
                        label: const Text("BURST-SYNC BUFFER NOW"),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF0284C7),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          textStyle: GoogleFonts.spaceGrotesk(fontWeight: FontWeight.w800, fontSize: 11),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 14),

            // Public Cellular & Cloud Tunnel Guide Card
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFF0F172A),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFF38BDF8).withOpacity(0.4), width: 1.0),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.public_rounded, color: Color(0xFF38BDF8), size: 18),
                      const SizedBox(width: 8),
                      Text(
                        "ANY NETWORK / 4G CELLULAR ACCESS",
                        style: GoogleFonts.spaceGrotesk(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w900,
                          color: const Color(0xFF38BDF8),
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    "To track phones on 4G/5G mobile data from outside your home Wi-Fi, run this 1 command on your PC PowerShell (Zero setup, built-in Windows):",
                    style: GoogleFonts.spaceGrotesk(fontSize: 10, color: Colors.white70, height: 1.3),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.5),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.white12),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            "ssh -R 80:localhost:3000 a.pinggy.io",
                            style: GoogleFonts.jetBrainsMono(
                              fontSize: 10.5,
                              color: const Color(0xFF38BDF8),
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                        GestureDetector(
                          onTap: () {
                            Clipboard.setData(const ClipboardData(text: "ssh -R 80:localhost:3000 a.pinggy.io"));
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text("Command copied to clipboard!"),
                                duration: Duration(seconds: 1),
                              ),
                            );
                          },
                          child: const Icon(Icons.copy_rounded, color: Colors.white54, size: 14),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    "Paste the generated https link into the field above and tap CONNECT.",
                    style: GoogleFonts.spaceGrotesk(fontSize: 9.5, color: Colors.white60),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
