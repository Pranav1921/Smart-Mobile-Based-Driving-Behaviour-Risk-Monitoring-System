import 'package:flutter/material.dart';
import '../models/driver_model.dart';
import '../services/local_storage_service.dart';
import '../services/api_service.dart';
import '../services/socket_service.dart';

import 'package:shared_preferences/shared_preferences.dart';

class AuthProvider extends ChangeNotifier {
  DriverProfile _profile = DriverProfile.empty();
  bool _isAuthenticated = false;
  bool _isLoading = false;
  bool _isBackgroundMode = false;
  bool _mustChangePassword = false;
  String? _driverCode;
  String? _lastErrorMessage;
  ValueChanged<String?>? onDriverChanged;

  DriverProfile get profile => _profile;
  bool get isAuthenticated => _isAuthenticated;
  bool get isLoading => _isLoading;
  bool get isBackgroundMode => _isBackgroundMode;
  bool get mustChangePassword => _mustChangePassword;
  String? get driverCode => _driverCode;
  String? get lastErrorMessage => _lastErrorMessage;

  Future<void> checkAuthStatus() async {
    _isLoading = true;
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    _isBackgroundMode = prefs.getBool('sd_is_background_mode') ?? false;

    final savedProfile = await LocalStorageService.getProfile();
    if (savedProfile != null) {
      _profile = savedProfile;
      _driverCode = savedProfile.driverId;
      _isAuthenticated = true;
      SocketService.initSocket();
      onDriverChanged?.call(_profile.driverId);
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> setAppUsageMode(bool isBackground) async {
    _isBackgroundMode = isBackground;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('sd_is_background_mode', isBackground);
    notifyListeners();
  }

  Future<bool> login({required String driverId, required String password, String? regionId}) async {
    if (driverId.isEmpty || password.isEmpty) {
      _lastErrorMessage = "Driver ID and Password are required";
      return false;
    }
    
    _isLoading = true;
    _lastErrorMessage = null;
    notifyListeners();

    try {
      final fetchedProfile = await ApiService.login(driverId, password);
      
      if (fetchedProfile != null) {
        if (ApiService.lastAuthResult != null) {
          _mustChangePassword = ApiService.lastAuthResult?['mustChangePassword'] == true;
          _driverCode = ApiService.lastAuthResult?['driverCode'] as String? ?? fetchedProfile.driverId;
        }

        _profile = fetchedProfile;
        if (regionId != null) _profile = _profile.copyWith(regionId: regionId);
        
        await LocalStorageService.saveProfile(_profile);
        _isAuthenticated = true;
        _isLoading = false;
        _lastErrorMessage = null;
        SocketService.initSocket();
        onDriverChanged?.call(_profile.driverId);
        notifyListeners();
        return true;
      } else {
        _lastErrorMessage = ApiService.lastErrorMessage ?? "Invalid Driver ID or Password";
      }
    } catch (e) {
      _lastErrorMessage = "Login failed: $e";
      print("Login error: $e");
    }

    _isAuthenticated = false;
    _isLoading = false;
    notifyListeners();
    return false;
  }

  Future<Map<String, dynamic>?> applyDriverApplication({
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
    _isLoading = true;
    notifyListeners();
    try {
      final res = await ApiService.applyDriver(
        name: name,
        email: email,
        phone: phone,
        zone: zone,
        licenseNumber: licenseNumber,
        vehicleType: vehicleType,
        vehicleName: vehicleName,
        vehiclePlateNumber: vehiclePlateNumber,
        emergencyName: emergencyName,
        emergencyPhone: emergencyPhone,
        familyRelationship: familyRelationship,
      );
      _isLoading = false;
      notifyListeners();
      return res;
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      return null;
    }
  }

  Future<bool> changeInitialPassword(String currentPassword, String newPassword) async {
    _isLoading = true;
    notifyListeners();
    try {
      final id = _driverCode?.isNotEmpty == true
          ? _driverCode!
          : (_profile.email.isNotEmpty ? _profile.email : _profile.driverId);
      final success = await ApiService.changeInitialPassword(
        driverIdOrEmail: id,
        currentPassword: currentPassword,
        newPassword: newPassword,
      );
      if (success) {
        _mustChangePassword = false;
        _lastErrorMessage = null;
      } else {
        _lastErrorMessage = ApiService.lastErrorMessage ?? "Failed to update password";
      }
      _isLoading = false;
      notifyListeners();
      return success;
    } catch (e) {
      _lastErrorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> register({
    required String name,
    required String email,
    required String password,
    required String emergencyName,
    required String emergencyPhone,
    required String regionId,
    required String vehicleType,
    required String vehicleName,
    required String vehiclePlate,
    required String industry,
    required String driverType,
    required String licenseNumber,
    required int yearsExperience,
    required String bloodGroup,
    String? phoneNumber,
    String? familyRelationship,
  }) async {
    _isLoading = true;
    notifyListeners();

    try {
      final names = name.split(' ');
      final firstName = names[0];
      final lastName = names.length > 1 ? names.sublist(1).join(' ') : 'Driver';

      final success = await ApiService.register(
        email: email,
        password: password,
        firstName: firstName,
        lastName: lastName,
        zone: regionId,
        licenseNumber: licenseNumber,
        licenseExpiry: DateTime.now().add(const Duration(days: 365 * 5)).toIso8601String(),
        emergencyContactName: emergencyName,
        emergencyContactPhone: emergencyPhone,
        phoneNumber: phoneNumber,
        driverType: driverType,
      );

      if (success) {
        final profile = await login(driverId: email, password: password, regionId: regionId);
        if (profile != null) {
          _profile = _profile.copyWith(
            yearsExperience: yearsExperience,
            bloodGroup: bloodGroup,
            licenseNumber: licenseNumber,
            emergencyContactName: emergencyName,
            emergencyContactPhone: emergencyPhone,
            familyMemberName: emergencyName,
            familyRelationship: familyRelationship ?? 'Parent',
            familyWhatsappNumber: emergencyPhone,
          );
          await LocalStorageService.saveProfile(_profile);
        }
        return profile != null;
      }
    } catch (e) {
      print("Registration error: $e");
    }

    _isLoading = false;
    notifyListeners();
    return false;
  }

  Future<void> completeOnboarding({
    required String name,
    required String industry,
    required String vehicleType,
    required String vehicleName,
    required String vehiclePlateNumber,
    String? companyCode,
  }) async {
    _profile = _profile.copyWith(
      name: name,
      industry: industry,
      vehicleType: vehicleType,
      vehicleName: vehicleName,
      vehiclePlateNumber: vehiclePlateNumber,
      companyCode: companyCode ?? _profile.companyCode,
      isOnboarded: true,
    );
    await LocalStorageService.saveProfile(_profile);
    notifyListeners();
  }

  Future<void> updateRegion(String newRegionId) async {
    _profile = _profile.copyWith(regionId: newRegionId);
    await LocalStorageService.saveProfile(_profile);
    notifyListeners();
  }

  Future<void> updateSafetyScore(double delta) async {
    double newScore = (_profile.currentSafetyScore + delta).clamp(0.0, 100.0);
    _profile = _profile.copyWith(currentSafetyScore: newScore);
    await LocalStorageService.saveProfile(_profile);
    notifyListeners();
  }

  Future<void> updateVehicle({required String type, required String name, required String plate}) async {
    _profile = _profile.copyWith(vehicleType: type, vehicleName: name, vehiclePlateNumber: plate);
    await LocalStorageService.saveProfile(_profile);
    notifyListeners();
  }

  Future<void> updateFullProfile({
    required String name,
    required String phoneNumber,
    required String vehicleName,
    required String vehiclePlateNumber,
    required String vehicleType,
    required String bloodGroup,
    required String licenseNumber,
    required String familyMemberName,
    required String familyRelationship,
    required String familyWhatsappNumber,
    required String familyAddress,
  }) async {
    _profile = _profile.copyWith(
      name: name,
      phoneNumber: phoneNumber,
      vehicleName: vehicleName,
      vehiclePlateNumber: vehiclePlateNumber,
      vehicleType: vehicleType,
      bloodGroup: bloodGroup,
      licenseNumber: licenseNumber,
      familyMemberName: familyMemberName,
      familyRelationship: familyRelationship,
      familyWhatsappNumber: familyWhatsappNumber,
      familyAddress: familyAddress,
      emergencyContactName: familyMemberName,
      emergencyContactPhone: familyWhatsappNumber,
    );
    await LocalStorageService.saveProfile(_profile);
    notifyListeners();

    // Sync with backend database if online
    if (_profile.driverId.isNotEmpty && !_profile.driverId.startsWith('drv_local_')) {
      ApiService.updateDriverEmergencyContact(
        _profile.driverId,
        emergencyContactName: familyMemberName,
        emergencyContactPhone: familyWhatsappNumber,
      );
    }
  }

  Future<void> updateFamilyInformation({
    required String memberName,
    required String relationship,
    required String whatsappNumber,
    required String address,
  }) async {
    _profile = _profile.copyWith(
      familyMemberName: memberName,
      familyRelationship: relationship,
      familyWhatsappNumber: whatsappNumber,
      familyAddress: address,
      emergencyContactName: memberName,
      emergencyContactPhone: whatsappNumber,
    );
    await LocalStorageService.saveProfile(_profile);
    notifyListeners();
  }

  Future<void> updateProfileImage(String imagePath) async {
    _profile = _profile.copyWith(profileImagePath: imagePath);
    await LocalStorageService.saveProfile(_profile);
    notifyListeners();
  }

  Future<void> updateDriverType(DriverType type) async {
    _profile = _profile.copyWith(driverType: type);
    await LocalStorageService.saveProfile(_profile);
    notifyListeners();
  }

  Future<void> logout() async {
    final prevId = _profile.driverId;
    _isAuthenticated = false;
    _profile = DriverProfile.empty();
    _driverCode = null;
    _lastErrorMessage = null;
    await LocalStorageService.clearAll(driverId: prevId);
    SocketService.dispose();
    onDriverChanged?.call(null);
    notifyListeners();
  }
}
