import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/driver_model.dart';
import '../models/trip_model.dart';
import '../models/transaction_model.dart';

class LocalStorageService {
  static const String _keyProfile = 'sd_driver_profile';
  static const String _keyTrips = 'sd_driver_trips';
  static const String _keyExpenses = 'sd_driver_expenses';
  static const String _keyCustomIncomes = 'sd_driver_custom_incomes';
  static const String _keySettingsShowSim = 'sd_settings_show_sim';

  LocalStorageService._();

  static String _keyFor(String baseKey, String? driverId) {
    if (driverId == null || driverId.trim().isEmpty) return baseKey;
    final sanitized = driverId.trim().toLowerCase().replaceAll(RegExp(r'[^a-z0-9_-]'), '_');
    return '${baseKey}_$sanitized';
  }

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

  static Future<bool> saveTrips(List<DriverTrip> trips, {String? driverId}) async {
    final prefs = await SharedPreferences.getInstance();
    final List<String> list = trips.map((t) => jsonEncode(t.toJson())).toList();
    return prefs.setStringList(_keyFor(_keyTrips, driverId), list);
  }

  static Future<List<DriverTrip>> getTrips({String? driverId}) async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getStringList(_keyFor(_keyTrips, driverId));
    if (data == null) return [];
    try {
      return data.map((d) => DriverTrip.fromJson(jsonDecode(d))).toList();
    } catch (_) {
      return [];
    }
  }

  static Future<bool> saveExpenses(List<PaymentTransaction> expenses, {String? driverId}) async {
    final prefs = await SharedPreferences.getInstance();
    final List<String> list = expenses.map((e) => jsonEncode(e.toJson())).toList();
    return prefs.setStringList(_keyFor(_keyExpenses, driverId), list);
  }

  static Future<List<PaymentTransaction>> getExpenses({String? driverId}) async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getStringList(_keyFor(_keyExpenses, driverId));
    if (data == null) return [];
    try {
      return data.map((d) => PaymentTransaction.fromJson(jsonDecode(d))).toList();
    } catch (_) {
      return [];
    }
  }

  static Future<bool> saveCustomIncomes(List<PaymentTransaction> incomes, {String? driverId}) async {
    final prefs = await SharedPreferences.getInstance();
    final List<String> list = incomes.map((e) => jsonEncode(e.toJson())).toList();
    return prefs.setStringList(_keyFor(_keyCustomIncomes, driverId), list);
  }

  static Future<List<PaymentTransaction>> getCustomIncomes({String? driverId}) async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getStringList(_keyFor(_keyCustomIncomes, driverId));
    if (data == null) return [];
    try {
      return data.map((d) => PaymentTransaction.fromJson(jsonDecode(d))).toList();
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

  static Future<bool> saveHasSeenTour(bool seen) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.setBool('sd_has_seen_tour', seen);
  }

  static Future<bool> getHasSeenTour() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('sd_has_seen_tour') ?? false;
  }

  static Future<void> clearAll({String? driverId}) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyProfile);
    if (driverId != null) {
      await prefs.remove(_keyFor(_keyTrips, driverId));
      await prefs.remove(_keyFor(_keyExpenses, driverId));
      await prefs.remove(_keyFor(_keyCustomIncomes, driverId));
    }
    await prefs.remove(_keyTrips);
    await prefs.remove(_keyExpenses);
    await prefs.remove(_keyCustomIncomes);
    await prefs.remove(_keySettingsShowSim);
    await prefs.remove('sd_has_seen_tour');
  }
}

