/// API endpoint URLs and base configurations.
class AppUrls {
  AppUrls._();

  // Active Host IPv4 Address (Auto-synced with active interfaces)
  static const String serverIp = "192.168.177.244"; // PC Wi-Fi IPv4 Address
  static const String secondaryServerIp = "127.0.0.1"; // ADB Reverse Loopback
  static const String priorServerIp = "172.16.29.209"; // Previous Host IP

  // Fallback candidate hosts to probe in parallel during dynamic discovery
  static const List<String> fallbackCandidateIps = [
    "192.168.177.244", // Active PC Subnet IP
    "192.168.31.51",   // Active Wi-Fi IP
    "127.0.0.1",       // ADB reverse proxy loopback
    "172.16.29.209",   // Prior Wi-Fi IP
    "10.0.2.2",        // Android Emulator host loopback
    "localhost",
  ];

  // Development Base URLs
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