/// API endpoint URLs and base configurations.
class AppUrls {
  AppUrls._();

  // Active Host IPv4 Address (Auto-synced with active interfaces)
  static const String serverIp = "100.116.115.5"; // Permanent Tailscale Mesh IP (Connects from ANY network 4G/5G/Wi-Fi)
  static const String secondaryServerIp = "172.16.39.178"; // Local Wi-Fi IP
  static const String priorServerIp = "127.0.0.1"; // ADB Reverse Loopback

  // Fallback candidate hosts to probe in parallel during dynamic discovery
  static const List<String> fallbackCandidateIps = [
    "100.116.115.5",   // Permanent Tailscale Mesh IP (Anywhere on 4G/5G)
    "172.16.39.178",   // Current Wi-Fi IP
    "127.0.0.1",       // ADB reverse proxy loopback (USB cable)
    "192.168.177.244", // Mobile Hotspot IP
    "10.0.2.2",        // Android Emulator host loopback
    "localhost",
  ];

  // Development Base URLs (Tailscale Encrypted Direct Mesh Connection)
  static const String baseUrl = "http://$serverIp:3000/api";
  static const String socketUrl = "http://$serverIp:3000";

  // Future Endpoints
  static const String login = "/auth/login";
  static const String register = "/auth/register";

  static const String trips = "/trips";

  static const String alerts = "/alerts";

  static const String drivers = "/drivers";

  static const String dashboard = "/dashboard";
}