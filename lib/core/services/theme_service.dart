import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeService extends ChangeNotifier {
  static final ThemeService _instance = ThemeService._internal();
  factory ThemeService() => _instance;
  ThemeService._internal();

  static const String _themeKey = 'app_theme_mode';
  ThemeMode _themeMode = ThemeMode.light;
  bool _isLoading = true;

  ThemeMode get themeMode => _themeMode;
  bool get isDarkMode => _themeMode == ThemeMode.dark;
  bool get isLoading => _isLoading;

  /// Initialize theme service and load saved theme preference
  Future<void> initialize() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final themeModeString = prefs.getString(_themeKey);
      
      if (themeModeString != null) {
        _themeMode = _getThemeModeFromString(themeModeString);
      } else {
        // Default to light theme on first launch
        _themeMode = ThemeMode.light;
      }
      
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      print('Error loading theme preference: $e');
      _themeMode = ThemeMode.light;
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Set theme mode and persist to storage
  Future<void> setThemeMode(ThemeMode themeMode) async {
    try {
      _themeMode = themeMode;
      notifyListeners();

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_themeKey, themeMode.toString());
    } catch (e) {
      print('Error saving theme preference: $e');
    }
  }

  /// Toggle between light and dark mode
  Future<void> toggleTheme() async {
    final newTheme = _themeMode == ThemeMode.dark 
        ? ThemeMode.light 
        : ThemeMode.dark;
    await setThemeMode(newTheme);
  }

  /// Set light theme
  Future<void> setLightTheme() async {
    await setThemeMode(ThemeMode.light);
  }

  /// Set dark theme
  Future<void> setDarkTheme() async {
    await setThemeMode(ThemeMode.dark);
  }

  /// Convert string to ThemeMode enum
  ThemeMode _getThemeModeFromString(String themeModeString) {
    switch (themeModeString) {
      case 'ThemeMode.light':
        return ThemeMode.light;
      case 'ThemeMode.dark':
        return ThemeMode.dark;
      case 'ThemeMode.system':
        // Convert old system mode to light mode
        return ThemeMode.light;
      default:
        return ThemeMode.light;
    }
  }

  /// Get user-friendly theme name
  String get currentThemeName {
    return _themeMode == ThemeMode.dark ? 'Dark' : 'Light';
  }

  /// Check if current theme is dark
  bool isDarkModeActive(BuildContext context) {
    return _themeMode == ThemeMode.dark;
  }
}