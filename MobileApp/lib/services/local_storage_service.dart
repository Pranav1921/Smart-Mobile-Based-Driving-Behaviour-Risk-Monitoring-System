import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/driver_model.dart';
import '../models/trip_model.dart';

class LocalStorageService {
  static const String _keyProfile = 'fg_driver_profile';
  static const String _keyTrips = 'fg_driver_trips';
  static const String _keySettingsShowSim = 'fg_settings_show_sim';

  LocalStorageService._();

  static Future<bool> saveProfile(DriverProfile profile) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.setString(_keyProfile, jsonEncode(profile.toJson()));
  }

  static Future<DriverProfile?> getProfile() async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString(_keyProfile);
    if (data == null) return null;
    try {
      return DriverProfile.fromJson(jsonDecode(data));
    } catch (_) {
      return null;
    }
  }

  static Future<bool> saveTrips(List<DriverTrip> trips) async {
    final prefs = await SharedPreferences.getInstance();
    final List<String> list = trips.map((t) => jsonEncode(t.toJson())).toList();
    return prefs.setStringList(_keyTrips, list);
  }

  static Future<List<DriverTrip>> getTrips() async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getStringList(_keyTrips);
    if (data == null) return [];
    try {
      return data.map((d) => DriverTrip.fromJson(jsonDecode(d))).toList();
    } catch (_) {
      return [];
    }
  }

  static Future<bool> saveSimulationSettings(bool showSim) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.setBool(_keySettingsShowSim, showSim);
  }

  static Future<bool> getSimulationSettings() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keySettingsShowSim) ?? true; // Default true for demo verification
  }

  static Future<void> clearAll() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyProfile);
    await prefs.remove(_keyTrips);
    await prefs.remove(_keySettingsShowSim);
  }
}
