import 'dart:convert';
import 'dart:io';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:path/path.dart' as p;
import '../models/driver_model.dart';
import '../models/trip_model.dart';
import '../models/order_model.dart';
import 'dart:math';

import '../core/constants/app_urls.dart';
import 'discovery_service.dart';

class ApiService {
  static String? _activeBaseUrl;
  static String? get activeHost => _activeBaseUrl?.replaceAll('/api', '') ?? DiscoveryService.activeHost;

  static final HttpClient _client = HttpClient()..connectionTimeout = const Duration(milliseconds: 1200);
  
  static const String _keyToken = 'sd_auth_jwt_token';
  static Map<String, dynamic>? lastAuthResult;

  ApiService._();

  static void setCustomHost(String host) {
    String formatted = host.trim();
    if (!formatted.startsWith('http://') && !formatted.startsWith('https://')) {
      formatted = 'http://$formatted:3000';
    }
    if (formatted.endsWith('/')) {
      formatted = formatted.substring(0, formatted.length - 1);
    }
    _activeBaseUrl = "$formatted/api";
  }

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

  static List<String> _buildCandidateBaseUrls() {
    final list = <String>[];
    if (_activeBaseUrl != null) {
      list.add(_activeBaseUrl!);
    }
    for (final ip in AppUrls.fallbackCandidateIps) {
      final url = "http://$ip:3000/api";
      if (!list.contains(url)) list.add(url);
    }
    return list;
  }

  static String? lastErrorMessage;

  static Future<Map<String, dynamic>?> _executeHttp(
    String baseUrl,
    String path,
    String method,
    Map<String, dynamic>? body,
  ) async {
    try {
      final uri = Uri.parse("$baseUrl$path");
      final request = await _client.openUrl(method, uri);

      request.headers.set(HttpHeaders.contentTypeHeader, "application/json");

      final token = await getToken();
      if (token != null) {
        request.headers.set(HttpHeaders.authorizationHeader, "Bearer $token");
      }

      if (body != null) {
        request.write(jsonEncode(body));
      }

      final response = await request.close().timeout(const Duration(milliseconds: 3000));
      final responseBody = await response.transform(utf8.decoder).join();

      Map<String, dynamic>? decoded;
      try {
        if (responseBody.isNotEmpty) {
          final res = jsonDecode(responseBody);
          if (res is Map<String, dynamic>) {
            decoded = res;
          }
        }
      } catch (_) {}

      if (response.statusCode >= 200 && response.statusCode < 300) {
        lastErrorMessage = null;
        return decoded ?? {'status': 'success'};
      } else {
        // Server returned an error (400, 401, 403, 404, 500, etc.)
        final msg = decoded?['message']?.toString() ?? 'Server error (${response.statusCode})';
        lastErrorMessage = msg;
        return {
          '__isHttpError': true,
          'statusCode': response.statusCode,
          'message': msg,
        };
      }
    } catch (_) {}
    return null;
  }

  // Base HTTP Request handler with parallel host fallback and self-healing auto-discovery
  static Future<Map<String, dynamic>?> _request(
    String path, {
    required String method,
    Map<String, dynamic>? body,
    bool allowRediscovery = true,
  }) async {
    // Fast path: try cached working active host first (< 50ms)
    if (_activeBaseUrl != null) {
      final cachedResult = await _executeHttp(_activeBaseUrl!, path, method, body);
      if (cachedResult != null) return cachedResult;
    }

    // Parallel discovery phase (< 400ms parallel candidates check)
    final host = await DiscoveryService.autoDiscoverHost(forceRefresh: allowRediscovery);
    if (host != null) {
      _activeBaseUrl = "$host/api";
      final res = await _executeHttp(_activeBaseUrl!, path, method, body);
      if (res != null) return res;
    }

    // Final quick parallel probe of remaining candidate IPs
    final candidates = AppUrls.fallbackCandidateIps.map((ip) => "http://$ip:3000/api").toList();
    for (final cand in candidates) {
      if (cand == _activeBaseUrl) continue;
      final res = await _executeHttp(cand, path, method, body);
      if (res != null) {
        _activeBaseUrl = cand;
        DiscoveryService.setManualHost(cand.replaceAll('/api', ''));
        return res;
      }
    }

    return null;
  }

  // Authentication API endpoints with STRICT credential verification against backend database
  static Future<DriverProfile?> login(String emailOrId, String password) async {
    String input = emailOrId.trim();

    var response = await _request("/auth/login", method: "POST", body: {
      "email": input,
      "driverId": input,
      "password": password,
    });

    if (response == null) {
      lastErrorMessage = "Unable to connect to backend server. Please verify network/ADB reverse.";
      print("[ApiService] Login rejected: Server unreachable.");
      return null;
    }

    if (response['__isHttpError'] == true) {
      final msg = response['message']?.toString() ?? "Invalid Driver ID or Password";
      lastErrorMessage = msg;
      print("[ApiService] Login rejected: $msg");
      return null;
    }

    final data = response['data'];
    if (data == null) {
      lastErrorMessage = "Invalid response format from server";
      return null;
    }

    lastAuthResult = data;

    final token = data['accessToken'] as String?;
    if (token != null) {
      await _saveToken(token);
    }

    final userJson = data['user'];
    if (userJson == null) {
      lastErrorMessage = "User profile missing in response";
      return null;
    }

    final driverProfileJson = userJson['driverProfile'];
    final driverId = driverProfileJson != null
        ? (driverProfileJson['id'] as String? ?? userJson['id'] as String? ?? 'drv-1')
        : (userJson['id'] as String? ?? 'drv-1');

    Map<String, dynamic>? driverProfileResponse;
    try {
      driverProfileResponse = await _request("/drivers/$driverId", method: "GET", allowRediscovery: false);
    } catch (_) {}

    String vehicleName = "Tata Ace Gold";
    String vehiclePlate = "KA-19-MN-4092";
    String vehicleType = "Truck";

    if (driverProfileResponse != null && driverProfileResponse['data'] != null) {
      final driverData = driverProfileResponse['data'];
      final assignments = driverData['vehicleAssignments'] as List?;
      if (assignments != null && assignments.isNotEmpty) {
        final activeVehicle = assignments[0]['vehicle'];
        if (activeVehicle != null) {
          final make = activeVehicle['make'] ?? '';
          final model = activeVehicle['model'] ?? '';
          vehicleName = "$make $model".trim();
          if (vehicleName.isEmpty) vehicleName = "Tata Ace Gold";
          vehiclePlate = activeVehicle['plateNumber'] ?? activeVehicle['licensePlate'] ?? vehiclePlate;
          vehicleType = activeVehicle['type'] ?? activeVehicle['vehicleType'] ?? vehicleType;
        }
      }
    }

    // Check badges for custom registered vehicle details
    final badgesList = (driverProfileJson?['badges'] as List?) ??
        (driverProfileResponse?['data']?['badges'] as List?);
    if (badgesList != null) {
      for (final b in badgesList) {
        final str = b.toString();
        if (str.startsWith('applied_vehicle_name:')) {
          final vName = str.replaceFirst('applied_vehicle_name:', '').trim();
          if (vName.isNotEmpty) vehicleName = vName;
        } else if (str.startsWith('applied_vehicle_plate:')) {
          final vPlate = str.replaceFirst('applied_vehicle_plate:', '').trim();
          if (vPlate.isNotEmpty) vehiclePlate = vPlate;
        } else if (str.startsWith('applied_vehicle:')) {
          final vType = str.replaceFirst('applied_vehicle:', '').trim();
          if (vType.isNotEmpty) vehicleType = vType;
        }
      }
    }

    final firstName = userJson['firstName'] ?? 'Driver';
    final rawLastName = (userJson['lastName'] ?? '').toString();
    final cleanLastName = rawLastName.toLowerCase() == 'applicant' ? '' : rawLastName;
    final fullName = "$firstName $cleanLastName".trim();

    double safetyScore = 95.0;
    if (driverProfileJson != null && driverProfileJson['currentSafetyScore'] != null) {
      safetyScore = (driverProfileJson['currentSafetyScore'] as num).toDouble();
    } else if (driverProfileJson != null && driverProfileJson['safetyScore'] != null) {
      safetyScore = (driverProfileJson['safetyScore'] as num).toDouble();
    }

    final driverCodeBadge = badgesList
        ?.firstWhere((b) => b.toString().startsWith('driver_code:'), orElse: () => null);
    final assignedCode = driverCodeBadge != null
        ? driverCodeBadge.toString().replaceFirst('driver_code:', '')
        : (data['driverCode'] as String? ?? driverId);

    return DriverProfile(
      driverId: assignedCode,
      name: fullName.isEmpty ? "Driver" : fullName,
      email: userJson['email'] ?? '',
      phoneNumber: userJson['phoneNumber'] ?? driverProfileJson?['emergencyContactPhone'] ?? '',
      companyCode: userJson['organizationName'] ?? "FLEET",
      vehicleName: vehicleName,
      vehiclePlateNumber: vehiclePlate,
      vehicleType: vehicleType,
      industry: "Logistics",
      isOnboarded: true,
      currentSafetyScore: safetyScore,
      emergencyContactName: driverProfileJson?['emergencyContactName'] ?? 'Guardian',
      emergencyContactPhone: driverProfileJson?['emergencyContactPhone'] ?? '000',
      licenseNumber: driverProfileJson?['licenseNumber'] ?? '',
      driverType: userJson['driverType'] == 'STANDARD' ? DriverType.STANDARD : DriverType.TACTICAL,
    );
  }

  static Future<bool> register({
    required String email,
    required String password,
    required String firstName,
    required String lastName,
    required String zone,
    required String licenseNumber,
    required String licenseExpiry,
    required String emergencyContactName,
    required String emergencyContactPhone,
    required String driverType,
    String? phoneNumber,
  }) async {
    final response = await _request("/auth/register", method: "POST", body: {
      "email": email,
      "password": password,
      "firstName": firstName,
      "lastName": lastName,
      "phoneNumber": phoneNumber,
      "role": "DRIVER",
      "zone": zone,
      "organizationName": "Smart Driving Command Center",
      "licenseNumber": licenseNumber,
      "licenseExpiry": licenseExpiry,
      "emergencyContactName": emergencyContactName,
      "emergencyContactPhone": emergencyContactPhone,
      "driverType": driverType,
    });
    
    // Offline local fallback if backend server is unreachable
    if (response == null) {
      return true;
    }

    return response['status'] == 'success' || response['data'] != null;
  }

  static Future<Map<String, dynamic>?> applyDriver({
    required String name,
    required String email,
    required String phone,
    required String zone,
    required String licenseNumber,
    required String vehicleType,
    String? vehicleName,
    String? vehiclePlateNumber,
    required String emergencyName,
    required String emergencyPhone,
    required String familyRelationship,
  }) async {
    final response = await _request("/auth/driver-apply", method: "POST", body: {
      "name": name,
      "email": email,
      "phoneNumber": phone,
      "zone": zone,
      "licenseNumber": licenseNumber,
      "vehicleType": vehicleType,
      "vehicleName": vehicleName ?? "Tata Ace Gold EV",
      "vehiclePlateNumber": vehiclePlateNumber ?? "KA-19-PT-2026",
      "emergencyContactName": emergencyName,
      "emergencyContactPhone": emergencyPhone,
      "familyRelationship": familyRelationship,
    });

    if (response == null) {
      // Return simulated success for offline demo
      return {
        "status": "success",
        "data": {
          "trackingId": "REQ-2026-${Random().nextInt(8999) + 1000}",
          "zone": zone,
          "name": name,
        },
      };
    }

    return response;
  }

  static Future<Map<String, dynamic>?> checkApplicationStatus(String email, {String? trackingId, String? licenseNumber}) async {
    final queryParams = <String, String>{};
    if (email.isNotEmpty) queryParams['email'] = email;
    if (trackingId != null && trackingId.isNotEmpty) queryParams['trackingId'] = trackingId;
    if (licenseNumber != null && licenseNumber.isNotEmpty) queryParams['licenseNumber'] = licenseNumber;

    final queryString = Uri(queryParameters: queryParams).query;
    final path = "/auth/application-status?$queryString";

    final response = await _request(path, method: "GET");
    if (response != null && response['data'] != null) {
      return response['data'] as Map<String, dynamic>;
    }
    return null;
  }

  static Future<bool> changeInitialPassword({
    required String driverIdOrEmail,
    required String currentPassword,
    required String newPassword,
  }) async {
    final response = await _request("/auth/change-initial-password", method: "POST", body: {
      "identifier": driverIdOrEmail,
      "driverId": driverIdOrEmail,
      "email": driverIdOrEmail,
      "currentPassword": currentPassword,
      "newPassword": newPassword,
    });

    if (response == null) {
      lastErrorMessage = "Backend server unreachable. Please check connection.";
      return false;
    }

    if (response['__isHttpError'] == true) {
      lastErrorMessage = response['message']?.toString() ?? "Failed to update password";
      return false;
    }

    return response['status'] == 'success' || response['success'] == true;
  }

  // Trip operations
  static Future<String?> startTrip(String vehicleId, {String? deliveryFrom, String? deliveryTo, String? orderItems, String? orderId}) async {
    final response = await _request("/trips/start", method: "POST", body: {
      "vehicleId": vehicleId,
      "deliveryFrom": deliveryFrom,
      "deliveryTo": deliveryTo,
      "orderItems": orderItems,
      "orderId": orderId,
    });
    
    if (response == null) return "trip_offline_${DateTime.now().millisecondsSinceEpoch}";
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
    });
    return response != null;
  }

  static Future<bool> logEvent({
    String? tripId,
    String? eventType,
    String? severity,
    double? latitude,
    double? longitude,
    Map<String, dynamic>? sensorValues,
    dynamic event,
  }) async {
    return true;
  }

  // Fetch pending delivery orders
  static Future<List<DeliveryOrder>> fetchPendingOrders() async {
    final response = await _request("/orders/pending", method: "GET");
    if (response != null && response['data'] != null) {
      final List list = response['data'];
      return list.map((json) => DeliveryOrder.fromJson(json)).toList();
    }
    return [];
  }

  static Future<List<DeliveryOrder>> fetchOrders() async {
    return fetchPendingOrders();
  }

  // Upload crash media (Video/Audio)
  static Future<bool> uploadCrashMedia(String crashId, String filePath, String type) async {
    final urlsToTry = _buildCandidateBaseUrls();

    for (final baseUrl in urlsToTry) {
      try {
        final uri = Uri.parse("$baseUrl/crashes/$crashId/media");
        final token = await getToken();

        final request = await _client.postUrl(uri);

        // Manual multipart-form-data for HttpClient
        final boundary = "----SmartDriveBoundary${DateTime.now().millisecondsSinceEpoch}";
        request.headers.set(HttpHeaders.contentTypeHeader, "multipart/form-data; boundary=$boundary");
        if (token != null) {
          request.headers.set(HttpHeaders.authorizationHeader, "Bearer $token");
        }

        final file = File(filePath);
        final fileName = p.basename(filePath);

        // Multi-part construction
        final sink = request;
        sink.write("--$boundary\r\n");
        sink.write("Content-Disposition: form-data; name=\"file\"; filename=\"$fileName\"\r\n");
        sink.write("Content-Type: ${type == 'video' ? 'video/mp4' : 'audio/m4a'}\r\n\r\n");
        await sink.addStream(file.openRead());
        sink.write("\r\n--$boundary\r\n");
        sink.write("Content-Disposition: form-data; name=\"fileType\"\r\n\r\n");
        sink.write(type.toUpperCase());
        sink.write("\r\n--$boundary--\r\n");

        final response = await request.close();
        final responseBody = await response.transform(utf8.decoder).join();

        if (response.statusCode >= 200 && response.statusCode < 300) {
          print("[ApiService] Media uploaded successfully: $fileName");
          return true;
        } else {
          print("[ApiService] Media upload failed: ${response.statusCode} - $responseBody");
        }
      } catch (e) {
        print("[ApiService] Media upload exception: $e");
      }
    }
    return false;
  }

  // Update Driver Profile Emergency Kin Info
  static Future<bool> updateDriverEmergencyContact(
    String driverId, {
    required String emergencyContactName,
    required String emergencyContactPhone,
  }) async {
    try {
      final response = await _request("/drivers/$driverId", method: "PUT", body: {
        "emergencyContactName": emergencyContactName,
        "emergencyContactPhone": emergencyContactPhone,
      });
      return response != null && response['status'] == 'success';
    } catch (e) {
      print("[ApiService] updateDriverEmergencyContact exception: $e");
      return false;
    }
  }
}
