import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeService extends GetxController {
  static const String _themeKey = 'theme_mode';
  
  final _isDarkMode = false.obs;
  bool get isDarkMode => _isDarkMode.value;
  
  final _themeMode = ThemeMode.light.obs;
  ThemeMode get themeMode => _themeMode.value;
  
  @override
  void onInit() {
    super.onInit();
    _loadThemeFromPrefs();
  }
  
  /// Load theme preference from SharedPreferences
  Future<void> _loadThemeFromPrefs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedTheme = prefs.getString(_themeKey) ?? 'light';
      
      switch (savedTheme) {
        case 'dark':
          _isDarkMode.value = true;
          _themeMode.value = ThemeMode.dark;
          break;
        case 'system':
          _isDarkMode.value = false;
          _themeMode.value = ThemeMode.system;
          break;
        default:
          _isDarkMode.value = false;
          _themeMode.value = ThemeMode.light;
      }
      
      // Update GetX theme
      Get.changeThemeMode(_themeMode.value);
    } catch (e) {
      debugPrint('Error loading theme: $e');
    }
  }
  
  /// Save theme preference to SharedPreferences
  Future<void> _saveThemeToPrefs(String theme) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_themeKey, theme);
    } catch (e) {
      debugPrint('Error saving theme: $e');
    }
  }
  
  /// Switch to light theme
  Future<void> switchToLightTheme() async {
    _isDarkMode.value = false;
    _themeMode.value = ThemeMode.light;
    Get.changeThemeMode(ThemeMode.light);
    await _saveThemeToPrefs('light');
  }
  
  /// Switch to dark theme
  Future<void> switchToDarkTheme() async {
    _isDarkMode.value = true;
    _themeMode.value = ThemeMode.dark;
    Get.changeThemeMode(ThemeMode.dark);
    await _saveThemeToPrefs('dark');
  }
  
  /// Switch to system theme
  Future<void> switchToSystemTheme() async {
    _isDarkMode.value = false;
    _themeMode.value = ThemeMode.system;
    Get.changeThemeMode(ThemeMode.system);
    await _saveThemeToPrefs('system');
  }
  
  /// Toggle between light and dark theme
  Future<void> toggleTheme() async {
    if (_isDarkMode.value) {
      await switchToLightTheme();
    } else {
      await switchToDarkTheme();
    }
  }
  
  /// Get current theme name as string
  String get currentThemeName {
    switch (_themeMode.value) {
      case ThemeMode.dark:
        return 'Dark';
      case ThemeMode.system:
        return 'System';
      default:
        return 'Light';
    }
  }
  
  /// Check if current theme is dark (considering system theme)
  bool get isCurrentlyDark {
    if (_themeMode.value == ThemeMode.system) {
      return Get.isPlatformDarkMode;
    }
    return _isDarkMode.value;
  }
}

/// Extension to easily access theme service
extension ThemeServiceExtension on GetInterface {
  ThemeService get themeService => Get.find<ThemeService>();
}