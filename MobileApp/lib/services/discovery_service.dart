import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/constants/app_urls.dart';

class DiscoveryService {
  static const int discoveryPort = 41234;
  static const String discoveryReq = 'SMARTDRIVE_DISCOVERY_REQ';
  static const String discoveryRes = 'SMARTDRIVE_DISCOVERY_RES';
  static const String _keyCachedHost = 'smartdrive_discovered_host';

  static String? _activeHost;
  static String? get activeHost => _activeHost;
  static String get currentHost => _activeHost ?? AppUrls.socketUrl;

  static final StreamController<String> _hostStreamController = StreamController<String>.broadcast();
  static Stream<String> get onHostChanged => _hostStreamController.stream;

  /// Probes an HTTP endpoint's health in milliseconds
  static Future<bool> probeHealth(String host, {int timeoutMs = 800}) async {
    try {
      final client = HttpClient()..connectionTimeout = Duration(milliseconds: timeoutMs);
      final formatted = host.startsWith('http') ? host : 'http://$host:3000';
      final uri = Uri.parse("$formatted/health");
      final req = await client.getUrl(uri);
      final res = await req.close().timeout(Duration(milliseconds: timeoutMs));
      return res.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  /// Manually set and persist the target backend host
  static Future<void> setManualHost(String host) async {
    String formatted = host.trim();
    if (!formatted.startsWith('http://') && !formatted.startsWith('https://')) {
      formatted = 'http://$formatted:3000';
    }
    // Strip trailing slash if present
    if (formatted.endsWith('/')) {
      formatted = formatted.substring(0, formatted.length - 1);
    }
    _activeHost = formatted;
    _cacheHost(formatted);
    _hostStreamController.add(formatted);
    print('[AutoDiscovery] 💾 Manually set and cached target host: $formatted');
  }

  /// Automatically discovers the SmartDrive backend on the local network (Zero-Config)
  /// Even if Wi-Fi or DHCP IP changes, this dynamically finds the active backend.
  static Future<String?> autoDiscoverHost({bool forceRefresh = false}) async {
    print('[AutoDiscovery] 🔍 Starting zero-config backend discovery (forceRefresh: $forceRefresh)...');

    final prefs = await SharedPreferences.getInstance();

    // ── Phase 1: Fast Cache (0 - 50ms) ──────────────
    if (!forceRefresh) {
      final cached = prefs.getString(_keyCachedHost);
      if (cached != null && cached.isNotEmpty) {
        if (await probeHealth(cached, timeoutMs: 400)) {
          print('[AutoDiscovery] ⚡ Cached backend host verified: $cached');
          _activeHost = cached;
          return cached;
        }
      }
    }

    // ── Phase 2: Probe Known Candidate IPs (< 300ms) ──────────
    final quickCandidates = <String>[];
    for (final ip in AppUrls.fallbackCandidateIps) {
      quickCandidates.add("http://$ip:3000");
    }

    // Also probe current cached if we forced refresh
    final cached = prefs.getString(_keyCachedHost);
    if (cached != null && !quickCandidates.contains(cached)) {
      quickCandidates.insert(0, cached);
    }

    // Check fast parallel candidates
    final quickResults = await Future.wait(
      quickCandidates.map((host) async {
        final ok = await probeHealth(host, timeoutMs: 350);
        return ok ? host : null;
      }),
    );

    final validQuick = quickResults.firstWhere((h) => h != null, orElse: () => null);
    if (validQuick != null) {
      print('[AutoDiscovery] 🚀 Candidate backend responded: $validQuick');
      _cacheHost(validQuick);
      return validQuick;
    }

    // ── Phase 3: UDP Broadcast Discovery (50 - 350ms) ───────────────────
    final udpFound = await _discoverViaUdp();
    if (udpFound != null) {
      print('[AutoDiscovery] ✨ Backend discovered via UDP Beacon: $udpFound');
      _cacheHost(udpFound);
      return udpFound;
    }

    // ── Phase 4: Fast Parallel Subnet Sweep (< 1.5s) ────────────────────
    final subnetFound = await _discoverViaSubnetSweep();
    if (subnetFound != null) {
      print('[AutoDiscovery] 🎯 Backend found via Subnet Sweep: $subnetFound');
      _cacheHost(subnetFound);
      return subnetFound;
    }

    print('[AutoDiscovery] ⚠️ Auto-discovery fallback to default: ${AppUrls.socketUrl}');
    _activeHost = AppUrls.socketUrl;
    return AppUrls.socketUrl;
  }

  static Future<String?> _discoverViaUdp() async {
    RawDatagramSocket? socket;
    try {
      socket = await RawDatagramSocket.bind(InternetAddress.anyIPv4, 0);
      socket.broadcastEnabled = true;

      final completer = Completer<String?>();
      final reqBytes = utf8.encode(discoveryReq);

      socket.listen((event) {
        if (event == RawSocketEvent.read) {
          final datagram = socket?.receive();
          if (datagram != null) {
            final text = utf8.decode(datagram.data).trim();
            if (text.contains(discoveryRes) || text.contains('smartdrive-backend')) {
              final senderIp = datagram.address.address;
              final foundUrl = "http://$senderIp:3000";
              if (!completer.isCompleted) {
                completer.complete(foundUrl);
              }
            }
          }
        }
      });

      // Broadcast global ping
      try {
        socket.send(reqBytes, InternetAddress("255.255.255.255"), discoveryPort);
      } catch (_) {}

      // Broadcast directed subnet pings to each active interface
      try {
        final interfaces = await NetworkInterface.list(type: InternetAddressType.IPv4);
        for (final iface in interfaces) {
          for (final addr in iface.addresses) {
            final parts = addr.address.split('.');
            if (parts.length == 4) {
              final bcast = "${parts[0]}.${parts[1]}.${parts[2]}.255";
              try {
                socket.send(reqBytes, InternetAddress(bcast), discoveryPort);
              } catch (_) {}
            }
          }
        }
      } catch (_) {}

      // Wait max 600ms for UDP response
      Future.delayed(const Duration(milliseconds: 600), () {
        if (!completer.isCompleted) completer.complete(null);
      });

      final result = await completer.future;
      if (result != null && await probeHealth(result, timeoutMs: 500)) {
        return result;
      }
    } catch (_) {} finally {
      socket?.close();
    }
    return null;
  }

  static Future<String?> _discoverViaSubnetSweep() async {
    try {
      final interfaces = await NetworkInterface.list(type: InternetAddressType.IPv4);
      final subnets = <String>{};

      for (final iface in interfaces) {
        for (final addr in iface.addresses) {
          final ip = addr.address;
          if (ip != '127.0.0.1' && !ip.startsWith('169.254')) {
            final parts = ip.split('.');
            if (parts.length == 4) {
              subnets.add("${parts[0]}.${parts[1]}.${parts[2]}");
            }
          }
        }
      }

      // Add common default and fallback subnets
      subnets.addAll(['172.16.0', '192.168.31', '192.168.163', '172.16.23', '172.26.64', '192.168.1', '192.168.0', '192.168.43', '10.0.2']);

      for (final subnet in subnets) {
        final targets = <String>[];
        // Priority IP assignees (common DHCP assignments & routers)
        for (final i in [51, 65, 144, 1, 2, 3, 100, 101, 102, 103, 104, 105, 120, 130, 161, 200]) {
          targets.add("http://$subnet.$i:3000");
        }
        // Fill remaining IPs in the subnet
        for (int i = 4; i <= 254; i++) {
          final host = "http://$subnet.$i:3000";
          if (!targets.contains(host)) targets.add(host);
        }

        // Process in fast parallel batches of 40 with 300ms timeout
        const batchSize = 40;
        for (int i = 0; i < targets.length; i += batchSize) {
          final batch = targets.sublist(i, (i + batchSize > targets.length) ? targets.length : i + batchSize);
          final results = await Future.wait(batch.map((h) async {
            final ok = await probeHealth(h, timeoutMs: 300);
            return ok ? h : null;
          }));

          final found = results.firstWhere((h) => h != null, orElse: () => null);
          if (found != null) {
            return found;
          }
        }
      }
    } catch (_) {}
    return null;
  }

  static void _cacheHost(String host) async {
    _activeHost = host;
    _hostStreamController.add(host);
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_keyCachedHost, host);
    } catch (_) {}
  }
}
