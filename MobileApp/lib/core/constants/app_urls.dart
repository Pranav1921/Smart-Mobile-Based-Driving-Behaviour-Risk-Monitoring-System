/// API endpoint URLs and base configurations.
class AppUrls {
  AppUrls._();

  // Development
  static const String baseUrl =
      "http://192.168.31.51:3000/api";

  // Future Endpoints
  static const String login = "/auth/login";
  static const String register = "/auth/register";

  static const String trips = "/trips";

  static const String alerts = "/alerts";

  static const String drivers = "/drivers";

  static const String dashboard = "/dashboard";
}