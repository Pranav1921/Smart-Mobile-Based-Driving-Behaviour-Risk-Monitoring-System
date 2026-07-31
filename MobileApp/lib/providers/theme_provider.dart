import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeProvider extends ChangeNotifier {
  static const String _keyThemeMode = 'fg_settings_theme_mode';

  ThemeMode _themeMode = ThemeMode.dark; // Default to dark theme

  ThemeMode get themeMode => _themeMode;

  ThemeProvider() {
    _loadThemeMode();
  }

  Future<void> _loadThemeMode() async {
    final prefs = await SharedPreferences.getInstance();
    final val = prefs.getString(_keyThemeMode);
    if (val != null) {
      if (val == 'light') {
        _themeMode = ThemeMode.light;
      } else if (val == 'system') {
        _themeMode = ThemeMode.system;
      } else {
        _themeMode = ThemeMode.dark;
      }
      notifyListeners();
    }
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    _themeMode = mode;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    String val = 'dark';
    if (mode == ThemeMode.light) {
      val = 'light';
    } else if (mode == ThemeMode.system) {
      val = 'system';
    }
    await prefs.setString(_keyThemeMode, val);
  }
}
