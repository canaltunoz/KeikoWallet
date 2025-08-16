import 'package:flutter/material.dart';
import 'app_colors.dart';

/// Elevation system for Keiko Wallet
/// Based on Material Design 3 elevation tokens
class AppElevation {
  // Elevation levels
  static const double level0 = 0.0;   // Surface
  static const double level1 = 1.0;   // Cards at rest
  static const double level2 = 3.0;   // Cards on hover
  static const double level3 = 6.0;   // Dialogs, pickers
  static const double level4 = 8.0;   // Navigation drawer
  static const double level5 = 12.0;  // App bars, bottom sheets

  // Shadow colors
  static const Color shadowColor = AppColors.shadow;
  static const Color surfaceTintColor = AppColors.surfaceTint;

  // Elevation configurations
  static BoxShadow get shadow1 => BoxShadow(
    color: shadowColor.withOpacity(0.15),
    offset: const Offset(0, 1),
    blurRadius: 3,
    spreadRadius: 0,
  );

  static BoxShadow get shadow2 => BoxShadow(
    color: shadowColor.withOpacity(0.15),
    offset: const Offset(0, 1),
    blurRadius: 2,
    spreadRadius: 0,
  );

  static List<BoxShadow> get elevation1 => [
    BoxShadow(
      color: shadowColor.withOpacity(0.15),
      offset: const Offset(0, 1),
      blurRadius: 3,
      spreadRadius: 0,
    ),
    BoxShadow(
      color: shadowColor.withOpacity(0.30),
      offset: const Offset(0, 1),
      blurRadius: 2,
      spreadRadius: 0,
    ),
  ];

  static List<BoxShadow> get elevation2 => [
    BoxShadow(
      color: shadowColor.withOpacity(0.15),
      offset: const Offset(0, 1),
      blurRadius: 5,
      spreadRadius: 0,
    ),
    BoxShadow(
      color: shadowColor.withOpacity(0.30),
      offset: const Offset(0, 2),
      blurRadius: 4,
      spreadRadius: 0,
    ),
  ];

  static List<BoxShadow> get elevation3 => [
    BoxShadow(
      color: shadowColor.withOpacity(0.15),
      offset: const Offset(0, 1),
      blurRadius: 10,
      spreadRadius: 0,
    ),
    BoxShadow(
      color: shadowColor.withOpacity(0.30),
      offset: const Offset(0, 4),
      blurRadius: 5,
      spreadRadius: 0,
    ),
  ];

  static List<BoxShadow> get elevation4 => [
    BoxShadow(
      color: shadowColor.withOpacity(0.15),
      offset: const Offset(0, 2),
      blurRadius: 10,
      spreadRadius: 0,
    ),
    BoxShadow(
      color: shadowColor.withOpacity(0.30),
      offset: const Offset(0, 6),
      blurRadius: 10,
      spreadRadius: 0,
    ),
  ];

  static List<BoxShadow> get elevation5 => [
    BoxShadow(
      color: shadowColor.withOpacity(0.15),
      offset: const Offset(0, 4),
      blurRadius: 15,
      spreadRadius: 0,
    ),
    BoxShadow(
      color: shadowColor.withOpacity(0.30),
      offset: const Offset(0, 8),
      blurRadius: 10,
      spreadRadius: 0,
    ),
  ];

  // Surface colors at different elevations (Material 3)
  static Color surfaceAtElevation(double elevation, {bool isDark = false}) {
    final baseColor = isDark ? AppColors.darkSurface : AppColors.surface;
    final tintColor = isDark ? AppColors.darkSurfaceTint : AppColors.surfaceTint;
    
    // Calculate opacity based on elevation
    double opacity;
    if (elevation <= 0) {
      opacity = 0.0;
    } else if (elevation <= 1) {
      opacity = 0.05;
    } else if (elevation <= 3) {
      opacity = 0.08;
    } else if (elevation <= 6) {
      opacity = 0.11;
    } else if (elevation <= 8) {
      opacity = 0.12;
    } else {
      opacity = 0.14;
    }

    return Color.alphaBlend(
      tintColor.withOpacity(opacity),
      baseColor,
    );
  }

  // Container decorations with elevation
  static BoxDecoration containerDecoration({
    double elevation = level1,
    Color? color,
    BorderRadius? borderRadius,
    Border? border,
    bool isDark = false,
  }) {
    return BoxDecoration(
      color: color ?? surfaceAtElevation(elevation, isDark: isDark),
      borderRadius: borderRadius ?? BorderRadius.circular(12),
      border: border,
      boxShadow: _getShadowForElevation(elevation),
    );
  }

  static List<BoxShadow> _getShadowForElevation(double elevation) {
    if (elevation <= 0) return [];
    if (elevation <= 1) return elevation1;
    if (elevation <= 3) return elevation2;
    if (elevation <= 6) return elevation3;
    if (elevation <= 8) return elevation4;
    return elevation5;
  }

  // Card decorations
  static BoxDecoration get cardDecoration => containerDecoration(
    elevation: level1,
    borderRadius: BorderRadius.circular(16),
  );

  static BoxDecoration get cardHoverDecoration => containerDecoration(
    elevation: level2,
    borderRadius: BorderRadius.circular(16),
  );

  // Dialog decorations
  static BoxDecoration get dialogDecoration => containerDecoration(
    elevation: level3,
    borderRadius: BorderRadius.circular(24),
  );

  // Bottom sheet decorations
  static BoxDecoration get bottomSheetDecoration => containerDecoration(
    elevation: level5,
    borderRadius: const BorderRadius.only(
      topLeft: Radius.circular(24),
      topRight: Radius.circular(24),
    ),
  );

  // App bar decorations
  static BoxDecoration get appBarDecoration => containerDecoration(
    elevation: level0, // Material 3 app bars have no elevation by default
    borderRadius: BorderRadius.zero,
  );

  // Floating action button decorations
  static BoxDecoration get fabDecoration => containerDecoration(
    elevation: level3,
    borderRadius: BorderRadius.circular(16),
  );

  // Navigation rail decorations
  static BoxDecoration get navigationRailDecoration => containerDecoration(
    elevation: level0,
    borderRadius: BorderRadius.zero,
  );

  // Utility methods
  static BoxDecoration withCustomElevation(double elevation, {
    Color? color,
    BorderRadius? borderRadius,
    Border? border,
    bool isDark = false,
  }) {
    return containerDecoration(
      elevation: elevation,
      color: color,
      borderRadius: borderRadius,
      border: border,
      isDark: isDark,
    );
  }
}
