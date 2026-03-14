import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Provides persistent app settings (theme mode + accent color).
class SettingsService extends ChangeNotifier {
  static const _themeModeKey = 'theme_mode';
  static const _accentColorKey = 'accent_color';

  static SettingsService? _instance;

  /// Access the singleton instance.
  ///
  /// If the service was not initialized through [initialize()], it will return
  /// a default instance (system theme + blue accent) so the app can still run
  /// in tests or during initial build.
  static SettingsService get instance => _instance ??= SettingsService._(ThemeMode.system, Colors.blue);

  ThemeMode themeMode;
  Color seedColor;

  SettingsService._(this.themeMode, this.seedColor);

  static Future<void> initialize() async {
    final prefs = await SharedPreferences.getInstance();
    final themeIndex = prefs.getInt(_themeModeKey) ?? ThemeMode.system.index;
    final seedValue = prefs.getInt(_accentColorKey) ?? Colors.blue.toARGB32();

    _instance = SettingsService._(
      ThemeMode.values[themeIndex],
      Color(seedValue),
    );
  }

  void updateThemeMode(ThemeMode mode) {
    themeMode = mode;
    SharedPreferences.getInstance().then((prefs) => prefs.setInt(_themeModeKey, mode.index));
    notifyListeners();
  }

  void updateAccentColor(Color color) {
    seedColor = color;
    SharedPreferences.getInstance().then((prefs) => prefs.setInt(_accentColorKey, color.toARGB32()));
    notifyListeners();
  }
}
