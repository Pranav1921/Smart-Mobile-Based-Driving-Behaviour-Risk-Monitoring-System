import 'dart:convert';
import 'dart:io';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/driver_model.dart';
import '../models/trip_model.dart';
import '../models/order_model.dart';
import 'dart:math';

class ApiService {
  // Use 10.0.2.2 when running on Android emulator, or 127.0.0.1 for desktop/web development
  // Use 127.0.0.1 for Android (compatible with 'adb reverse tcp:3000 tcp:3000' for physical devices and emulators)
  static final String _baseUrl = Platform.isAndroid ? "http://127.0.0.1:3000/api/v1" : "http://localhost:3000/api/v1";
  static final HttpClient _client = HttpClient();
  
  static const String _keyToken = 'fg_auth_jwt_token';

  ApiService._();

  static Future<void> _saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyToken, token);
  }

  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyToken);
  }

  static Future<void> clearToken() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyToken);
  }

  // Base HTTP Request handler using standard dart:io HttpClient
  static Future<Map<String, dynamic>?> _request(
    String path, {
    required String method,
    Map<String, dynamic>? body,
  }) async {
    try {
      final uri = Uri.parse("$_baseUrl$path");
      final request = await _client.openUrl(method, uri);
      
      // Inject JSON headers
      request.headers.set(HttpHeaders.contentTypeHeader, "application/json");
      
      // Inject Authorization Bearer JWT Token
      final token = await getToken();
      if (token != null) {
        request.headers.set(HttpHeaders.authorizationHeader, "Bearer $token");
      }

      if (body != null) {
        request.write(jsonEncode(body));
      }

      final response = await request.close();
      final responseBody = await response.transform(utf8.decoder).join();
      
      if (response.statusCode >= 200 && response.statusCode < 300) {
        return jsonDecode(responseBody) as Map<String, dynamic>;
      } else {
        print("API Error Response: ${response.statusCode} - $responseBody");
        return null;
      }
    } catch (e) {
      print("Network Request Exception: $e");
      return null;
    }
  }

  // Authentication API endpoints
  static Future<DriverProfile?> login(String emailOrId, String password) async {
    String email = emailOrId.trim();
    if (!email.contains('@')) {
      email = '$email@acmelogistics.com';
    }
    final response = await _request("/auth/login", method: "POST", body: {
      "email": email,
      "password": password,
    });

    if (response == null) return null;
    
    final data = response['data'];
    if (data == null) return null;

    final token = data['accessToken'] as String?;
    if (token != null) {
      await _saveToken(token);
    }

    final userJson = data['user'];
    if (userJson == null) return null;

    final driverProfileJson = userJson['driverProfile'];
    if (driverProfileJson == null) return null;
    
    final driverId = driverProfileJson['id'] as String;

    // Fetch full driver profile details to load assignments
    final driverProfileResponse = await _request("/drivers/$driverId", method: "GET");
    
    String vehicleId = "00000000-0000-0000-0000-000000000000"; // fallback
    String vehicleName = "Tesla Model Y";
    String vehiclePlate = "FG-101-AI";
    
    if (driverProfileResponse != null && driverProfileResponse['data'] != null) {
      final driverData = driverProfileResponse['data'];
      final assignments = driverData['vehicleAssignments'] as List?;
      if (assignments != null && assignments.isNotEmpty) {
        final activeVehicle = assignments[0]['vehicle'];
        if (activeVehicle != null) {
          vehicleId = activeVehicle['id'] ?? vehicleId;
          vehicleName = "${activeVehicle['make'] ?? ''} ${activeVehicle['model'] ?? ''}";
          vehiclePlate = activeVehicle['licensePlate'] ?? vehiclePlate;
        }
      }
    }

    // Cache the active driverId and vehicleId in SharedPreferences for subsequent calls
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('fg_active_driver_id', driverId);
    await prefs.setString('fg_active_vehicle_id', vehicleId);

    // Build DriverProfile from response json
    return DriverProfile(
      name: "${userJson['first_name'] ?? 'Driver'} ${userJson['last_name'] ?? ''}",
      companyCode: "ACME",
      driverId: driverId,
      industry: "Logistics",
      vehicleType: "CAR",
      vehicleName: vehicleName,
      vehiclePlateNumber: vehiclePlate,
      isOnboarded: true,
      currentSafetyScore: (driverProfileJson['safety_score'] as num?)?.toDouble() ?? 100.0,
    );
  }

  static Future<bool> register({
    required String email,
    required String password,
    required String firstName,
    required String lastName,
    required String licenseNumber,
    required String licenseExpiry,
    required String emergencyContactName,
    required String emergencyContactPhone,
  }) async {
    final response = await _request("/auth/register", method: "POST", body: {
      "email": email,
      "password": password,
      "firstName": firstName,
      "lastName": lastName,
      "role": "DRIVER",
      "organizationName": "Acme Logistics Corp", // fallback org link
      "licenseNumber": licenseNumber,
      "licenseExpiry": licenseExpiry,
      "emergencyContactName": emergencyContactName,
      "emergencyContactPhone": emergencyContactPhone,
    });
    
    return response != null;
  }

  // Trip operations
  static Future<String?> startTrip(String vehicleId) async {
    final response = await _request("/trips/start", method: "POST", body: {
      "vehicleId": vehicleId,
    });
    
    if (response == null) return null;
    return response['data']?['id'] as String?;
  }

  static Future<bool> endTrip(String tripId) async {
    final response = await _request("/trips/$tripId/end", method: "POST");
    return response != null;
  }

  static Future<bool> sendLocation(String tripId, double lat, double lng, double speed, double heading) async {
    final response = await _request("/trips/$tripId/location", method: "POST", body: {
      "latitude": lat,
      "longitude": lng,
      "speed": speed,
      "heading": heading,
      "timestamp": DateTime.now().toUtc().toIso8601String(),
    });
    return response != null;
  }

  // Telemetry warning logging
  static Future<bool> logEvent({
    String? tripId,
    required String eventType,
    required String severity,
    required double latitude,
    required double longitude,
    Map<String, dynamic>? sensorValues,
  }) async {
    final response = await _request("/events", method: "POST", body: {
      "tripId": tripId,
      "eventType": eventType,
      "severity": severity,
      "latitude": latitude,
      "longitude": longitude,
      "sensorValues": sensorValues,
    });
    return response != null;
  }

  // Crash report SOS
  static Future<bool> reportCrash({
    String? tripId,
    required double latitude,
    required double longitude,
    required Map<String, dynamic> sensorValues,
    required String severity,
  }) async {
    final response = await _request("/crashes", method: "POST", body: {
      "tripId": tripId,
      "latitude": latitude,
      "longitude": longitude,
      "sensorValues": sensorValues,
      "severity": severity,
    });
    return response != null;
  }

  // Fetch active/pending orders from the backend gateway
  static Future<List<DeliveryOrder>> fetchOrders() async {
    final response = await _request("/orders", method: "GET");
    if (response == null || response['success'] != true) return [];
    
    final List<dynamic> data = response['data'] ?? [];
    final rand = Random();
    
    return data.map((json) {
      final id = json['id'] as String? ?? '';
      final customerName = json['customerName'] as String? ?? 'Client';
      final itemsList = json['items'] as List<dynamic>? ?? [];
      final itemsString = itemsList.join(', ');
      final amount = (json['amount'] as num?)?.toDouble() ?? 0.0;
      
      final loc = json['deliveryLocation'] as Map<String, dynamic>? ?? {};
      final lat = (loc['latitude'] as num?)?.toDouble() ?? 19.0760; // default Mumbai
      final lng = (loc['longitude'] as num?)?.toDouble() ?? 72.8777;
      final address = loc['address'] as String? ?? 'Delivery Point';
      
      return DeliveryOrder(
        id: id,
        pickupAddress: "Main Dispatch Center",
        dropAddress: "$customerName ($address) - Items: $itemsString",
        distanceKm: 4.0 + rand.nextDouble() * 8.0,
        estimatedTimeMinutes: 10 + rand.nextInt(20),
        payoutAmount: amount,
        pickupLat: 19.0760, // base center
        pickupLng: 72.8777,
        dropLat: lat,
        dropLng: lng,
        status: 'available',
      );
    }).toList();
  }
}
