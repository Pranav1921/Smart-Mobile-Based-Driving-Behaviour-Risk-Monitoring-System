import 'package:flutter/material.dart';
import '../models/driver_model.dart';
import '../services/local_storage_service.dart';
import '../services/api_service.dart';
import '../services/socket_service.dart';

class AuthProvider extends ChangeNotifier {
  DriverProfile _profile = DriverProfile.empty();
  bool _isAuthenticated = false;
  bool _isLoading = false;

  DriverProfile get profile => _profile;
  bool get isAuthenticated => _isAuthenticated;
  bool get isLoading => _isLoading;

  Future<void> checkAuthStatus() async {
    _isLoading = true;
    notifyListeners();

    final savedProfile = await LocalStorageService.getProfile();
    if (savedProfile != null) {
      _profile = savedProfile;
      _isAuthenticated = true;
      SocketService.initSocket();
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<bool> login(String companyCode, String driverId, String password) async {
    if (companyCode.isEmpty || driverId.isEmpty || password.isEmpty) {
      return false;
    }
    
    _isLoading = true;
    notifyListeners();

    try {
      // Execute login request to Node.js backend
      final fetchedProfile = await ApiService.login(driverId, password);
      
      if (fetchedProfile != null) {
        _profile = fetchedProfile;
        await LocalStorageService.saveProfile(_profile);
        _isAuthenticated = true;
        _isLoading = false;
        SocketService.initSocket();
        notifyListeners();
        return true;
      }
    } catch (e) {
      print("Login request error: $e");
    }

    _isAuthenticated = false;
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

  Future<void> updateSafetyScore(double delta) async {
    double newScore = (_profile.currentSafetyScore + delta).clamp(0.0, 100.0);
    _profile = _profile.copyWith(currentSafetyScore: newScore);
    await LocalStorageService.saveProfile(_profile);
    notifyListeners();
  }

  Future<void> updateVehicle({
    required String type,
    required String name,
    required String plate,
  }) async {
    _profile = _profile.copyWith(
      vehicleType: type,
      vehicleName: name,
      vehiclePlateNumber: plate,
    );
    await LocalStorageService.saveProfile(_profile);
    notifyListeners();
  }

  Future<void> logout() async {
    _isAuthenticated = false;
    _profile = DriverProfile.empty();
    await LocalStorageService.clearAll();
    SocketService.dispose();
    notifyListeners();
  }
}
