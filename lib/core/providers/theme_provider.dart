import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../theme/app_theme.dart';

/// Theme provider for managing app theme state
/// Supports light/dark mode with system preference detection
class ThemeProvider extends ChangeNotifier {
  static const String _themeKey = 'theme_mode';
  
  ThemeMode _themeMode = ThemeMode.system;
  bool _isInitialized = false;

  /// Current theme mode
  ThemeMode get themeMode => _themeMode;

  /// Check if provider is initialized
  bool get isInitialized => _isInitialized;

  /// Get current theme data based on brightness
  ThemeData getTheme(Brightness brightness) {
    return AppTheme.getTheme(brightness);
  }

  /// Get light theme
  ThemeData get lightTheme => AppTheme.lightTheme;

  /// Get dark theme
  ThemeData get darkTheme => AppTheme.darkTheme;

  /// Check if current theme is dark
  bool isDark(BuildContext context) {
    return AppTheme.isDark(context);
  }

  /// Initialize theme provider
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      final prefs = await SharedPreferences.getInstance();
      final savedThemeIndex = prefs.getInt(_themeKey);
      
      if (savedThemeIndex != null) {
        _themeMode = ThemeMode.values[savedThemeIndex];
      } else {
        // Default to system theme
        _themeMode = ThemeMode.system;
      }

      _isInitialized = true;
      notifyListeners();
    } catch (e) {
      debugPrint('Error initializing theme provider: $e');
      _themeMode = ThemeMode.system;
      _isInitialized = true;
      notifyListeners();
    }
  }

  /// Set theme mode
  Future<void> setThemeMode(ThemeMode mode) async {
    if (_themeMode == mode) return;

    _themeMode = mode;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_themeKey, mode.index);
      
      // Update system UI overlay style
      _updateSystemUIOverlay();
    } catch (e) {
      debugPrint('Error saving theme preference: $e');
    }
  }

  /// Toggle between light and dark theme
  Future<void> toggleTheme() async {
    switch (_themeMode) {
      case ThemeMode.light:
        await setThemeMode(ThemeMode.dark);
        break;
      case ThemeMode.dark:
        await setThemeMode(ThemeMode.light);
        break;
      case ThemeMode.system:
        // If system, toggle to opposite of current system setting
        final brightness = WidgetsBinding.instance.platformDispatcher.platformBrightness;
        if (brightness == Brightness.dark) {
          await setThemeMode(ThemeMode.light);
        } else {
          await setThemeMode(ThemeMode.dark);
        }
        break;
    }
  }

  /// Set light theme
  Future<void> setLightTheme() async {
    await setThemeMode(ThemeMode.light);
  }

  /// Set dark theme
  Future<void> setDarkTheme() async {
    await setThemeMode(ThemeMode.dark);
  }

  /// Set system theme
  Future<void> setSystemTheme() async {
    await setThemeMode(ThemeMode.system);
  }

  /// Get theme mode name
  String get themeModeName {
    switch (_themeMode) {
      case ThemeMode.light:
        return 'Light';
      case ThemeMode.dark:
        return 'Dark';
      case ThemeMode.system:
        return 'System';
    }
  }

  /// Get theme mode icon
  IconData get themeModeIcon {
    switch (_themeMode) {
      case ThemeMode.light:
        return Icons.light_mode;
      case ThemeMode.dark:
        return Icons.dark_mode;
      case ThemeMode.system:
        return Icons.brightness_auto;
    }
  }

  /// Check if theme is light
  bool get isLight => _themeMode == ThemeMode.light;

  /// Check if theme is dark
  bool get isDarkMode => _themeMode == ThemeMode.dark;

  /// Check if theme is system
  bool get isSystem => _themeMode == ThemeMode.system;

  /// Get effective brightness based on current theme mode
  Brightness getEffectiveBrightness(BuildContext context) {
    switch (_themeMode) {
      case ThemeMode.light:
        return Brightness.light;
      case ThemeMode.dark:
        return Brightness.dark;
      case ThemeMode.system:
        return MediaQuery.of(context).platformBrightness;
    }
  }

  /// Update system UI overlay style based on current theme
  void _updateSystemUIOverlay() {
    final brightness = WidgetsBinding.instance.platformDispatcher.platformBrightness;
    
    SystemUiOverlayStyle overlayStyle;
    
    switch (_themeMode) {
      case ThemeMode.light:
        overlayStyle = SystemUiOverlayStyle.dark;
        break;
      case ThemeMode.dark:
        overlayStyle = SystemUiOverlayStyle.light;
        break;
      case ThemeMode.system:
        overlayStyle = brightness == Brightness.dark 
            ? SystemUiOverlayStyle.light 
            : SystemUiOverlayStyle.dark;
        break;
    }

    SystemChrome.setSystemUIOverlayStyle(overlayStyle);
  }

  /// Reset theme to default (system)
  Future<void> resetTheme() async {
    await setThemeMode(ThemeMode.system);
  }

  /// Get all available theme modes
  List<ThemeMode> get availableThemeModes => ThemeMode.values;

  /// Get theme mode display names
  Map<ThemeMode, String> get themeModeNames => {
    ThemeMode.light: 'Light',
    ThemeMode.dark: 'Dark',
    ThemeMode.system: 'System',
  };

  /// Get theme mode icons
  Map<ThemeMode, IconData> get themeModeIcons => {
    ThemeMode.light: Icons.light_mode,
    ThemeMode.dark: Icons.dark_mode,
    ThemeMode.system: Icons.brightness_auto,
  };

  /// Dispose resources
  @override
  void dispose() {
    super.dispose();
  }
}
