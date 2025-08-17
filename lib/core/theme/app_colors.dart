import 'package:flutter/material.dart';

/// Modern color palette for Keiko Wallet
/// Based on Material Design 3 color system
class AppColors {
  // Primary Colors - Green Theme
  static const Color primarySeed = Color(0xFF10B981); // Emerald primary
  static const Color primary = Color(0xFF10B981);
  static const Color onPrimary = Color(0xFFFFFFFF);
  static const Color primaryContainer = Color(0xFFD1FAE5);
  static const Color onPrimaryContainer = Color(0xFF064E3B);

  // Secondary Colors - Green Accent
  static const Color secondary = Color(0xFF059669);
  static const Color onSecondary = Color(0xFFFFFFFF);
  static const Color secondaryContainer = Color(0xFFA7F3D0);
  static const Color onSecondaryContainer = Color(0xFF022C22);

  // Tertiary Colors - Supporting Green
  static const Color tertiary = Color(0xFF16A34A);
  static const Color onTertiary = Color(0xFFFFFFFF);
  static const Color tertiaryContainer = Color(0xFFBBF7D0);
  static const Color onTertiaryContainer = Color(0xFF052E16);

  // Error Colors
  static const Color error = Color(0xFFBA1A1A);
  static const Color onError = Color(0xFFFFFFFF);
  static const Color errorContainer = Color(0xFFFFDAD6);
  static const Color onErrorContainer = Color(0xFF410002);

  // Success Colors (Custom)
  static const Color success = Color(0xFF00C853);
  static const Color onSuccess = Color(0xFFFFFFFF);
  static const Color successContainer = Color(0xFFB9F6CA);
  static const Color onSuccessContainer = Color(0xFF002114);

  // Warning Colors (Custom)
  static const Color warning = Color(0xFFFF9800);
  static const Color onWarning = Color(0xFFFFFFFF);
  static const Color warningContainer = Color(0xFFFFE0B2);
  static const Color onWarningContainer = Color(0xFF2E1500);

  // Neutral Colors - Light Theme (Green tinted)
  static const Color surface = Color(0xFFF7FEF7);
  static const Color onSurface = Color(0xFF1A201A);
  static const Color surfaceVariant = Color(0xFFE0ECE0);
  static const Color onSurfaceVariant = Color(0xFF454F45);
  static const Color outline = Color(0xFF747E74);
  static const Color outlineVariant = Color(0xFFC4D0C4);
  static const Color shadow = Color(0xFF000000);
  static const Color scrim = Color(0xFF000000);
  static const Color inverseSurface = Color(0xFF2F352F);
  static const Color onInverseSurface = Color(0xFFEFF7EF);
  static const Color inversePrimary = Color(0xFF6EE7B7);

  // Background Colors (Green tinted)
  static const Color background = Color(0xFFF7FEF7);
  static const Color onBackground = Color(0xFF1A201A);

  // Dark Theme Colors (Green theme)
  static const Color darkSurface = Color(0xFF0F1B0F);
  static const Color darkOnSurface = Color(0xFFE0E9E0);
  static const Color darkSurfaceVariant = Color(0xFF454F45);
  static const Color darkOnSurfaceVariant = Color(0xFFC4D0C4);
  static const Color darkBackground = Color(0xFF0F1B0F);
  static const Color darkOnBackground = Color(0xFFE0E9E0);
  static const Color darkPrimary = Color(0xFF6EE7B7);
  static const Color darkOnPrimary = Color(0xFF003D29);
  static const Color darkPrimaryContainer = Color(0xFF00513C);
  static const Color darkOnPrimaryContainer = Color(0xFF8EEDC7);

  // Crypto-specific Colors
  static const Color bitcoin = Color(0xFFF7931A);
  static const Color ethereum = Color(0xFF627EEA);
  static const Color binance = Color(0xFFF3BA2F);
  static const Color polygon = Color(0xFF8247E5);
  static const Color cardano = Color(0xFF0033AD);
  static const Color solana = Color(0xFF9945FF);

  // Gradient Colors
  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF10B981), Color(0xFF059669)],
  );

  static const LinearGradient successGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF22C55E), Color(0xFF16A34A)],
  );

  static const LinearGradient warningGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFFF9800), Color(0xFFFF5722)],
  );

  static const LinearGradient errorGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFBA1A1A), Color(0xFFD32F2F)],
  );

  // Surface Tints
  static const Color surfaceTint = primary;
  static const Color darkSurfaceTint = darkPrimary;

  // Elevation Colors (for Material 3)
  static Color surfaceContainerLowest = const Color(0xFFFFFFFF);
  static Color surfaceContainerLow = const Color(0xFFF7F2FA);
  static Color surfaceContainer = const Color(0xFFF3EDF7);
  static Color surfaceContainerHigh = const Color(0xFFECE6F0);
  static Color surfaceContainerHighest = const Color(0xFFE6E0E9);

  // Dark Surface Containers
  static Color darkSurfaceContainerLowest = const Color(0xFF0F0D13);
  static Color darkSurfaceContainerLow = const Color(0xFF1D1B20);
  static Color darkSurfaceContainer = const Color(0xFF211F26);
  static Color darkSurfaceContainerHigh = const Color(0xFF2B2930);
  static Color darkSurfaceContainerHighest = const Color(0xFF36343B);

  // Utility Methods
  static Color withOpacity(Color color, double opacity) {
    return color.withOpacity(opacity);
  }

  static Color blend(Color color1, Color color2, double ratio) {
    return Color.lerp(color1, color2, ratio) ?? color1;
  }

  // State Colors
  static Color get hovered => primary.withOpacity(0.08);
  static Color get focused => primary.withOpacity(0.12);
  static Color get pressed => primary.withOpacity(0.12);
  static Color get dragged => primary.withOpacity(0.16);
  static Color get selected => primary.withOpacity(0.08);

  // Disabled Colors
  static Color get disabled => onSurface.withOpacity(0.12);
  static Color get onDisabled => onSurface.withOpacity(0.38);
}
