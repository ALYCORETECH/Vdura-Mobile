import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum ThemeStyle {
  vanguarde('Vanguarde Signature'),
  slate('Executive Slate'),
  nordic('Nordic Minimal');

  final String label;
  const ThemeStyle(this.label);
}

class ThemeService extends ChangeNotifier {
  static const _themeModeKey = 'theme_mode_preference';
  static const _themeStyleKey = 'theme_style_preference';

  ThemeMode _themeMode = ThemeMode.dark;
  ThemeStyle _themeStyle = ThemeStyle.vanguarde;

  ThemeMode get themeMode => _themeMode;
  ThemeStyle get themeStyle => _themeStyle;
  bool get isDark => _themeMode == ThemeMode.dark;

  Future<void> initialize() async {
    final prefs = await SharedPreferences.getInstance();
    
    final modeIndex = prefs.getInt(_themeModeKey);
    if (modeIndex != null) {
      _themeMode = ThemeMode.values[modeIndex];
    }

    final styleIndex = prefs.getInt(_themeStyleKey);
    if (styleIndex != null) {
      _themeStyle = ThemeStyle.values[styleIndex];
    }
    notifyListeners();
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    _themeMode = mode;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_themeModeKey, mode.index);
  }

  Future<void> setThemeStyle(ThemeStyle style) async {
    _themeStyle = style;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_themeStyleKey, style.index);
  }

  Future<void> toggleThemeMode() async {
    final newMode = _themeMode == ThemeMode.light ? ThemeMode.dark : ThemeMode.light;
    await setThemeMode(newMode);
  }
}
