import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsService {
  static const _key = 'settings_theme_mode_v1';
  static final ValueNotifier<ThemeMode> themeModeNotifier = ValueNotifier(ThemeMode.system);

  /// Initialize settings from persistent storage. Safe on errors.
  static Future<void> init() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_key);
      if (raw == 'light') {
        themeModeNotifier.value = ThemeMode.light;
      } else if (raw == 'dark') {
        themeModeNotifier.value = ThemeMode.dark;
      } else {
        themeModeNotifier.value = ThemeMode.system;
      }
    } catch (_) {
      themeModeNotifier.value = ThemeMode.system;
    }
  }

  /// Persist theme mode and notify listeners.
  static Future<void> setThemeMode(ThemeMode mode) async {
    themeModeNotifier.value = mode;
    try {
      final prefs = await SharedPreferences.getInstance();
      final s = mode == ThemeMode.light ? 'light' : mode == ThemeMode.dark ? 'dark' : 'system';
      await prefs.setString(_key, s);
    } catch (_) {
      // ignore write errors
    }
  }
}
