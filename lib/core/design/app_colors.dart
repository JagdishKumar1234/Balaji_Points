import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // --------------------------------------------------------------------------
  // LIGHT THEME
  // --------------------------------------------------------------------------

  /// Primary Brand Color
  /// Deep premium navy blue
  static const Color lightPrimary = Color(0xFF1D2B6B);

  /// Secondary Accent
  /// Warm wood amber for carpenter identity
  static const Color lightSecondary = Color(0xFFD97706);

  /// Main backgrounds
  static const Color lightBackground = Color(0xFFF8F9FB);
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color lightSoftSurface = Color(0xFFF2F4F7);

  /// Borders & dividers
  static const Color lightBorder = Color(0xFFE4E7EC);

  /// Typography
  static const Color lightTextPrimary = Color(0xFF101828);
  static const Color lightTextSecondary = Color(0xFF667085);
  static const Color lightTextMuted = Color(0xFF98A2B3);

  // --------------------------------------------------------------------------
  // DARK THEME
  // --------------------------------------------------------------------------

  /// Keep same brand color for consistency
  static const Color darkPrimary = lightPrimary;

  /// Same secondary accent
  static const Color darkSecondary = lightSecondary;

  /// Dark backgrounds
  static const Color darkBackground = Color(0xFF0F1115);
  static const Color darkSurface = Color(0xFF171A22);

  /// Borders
  static const Color darkBorder = Color(0xFF313543);

  /// Typography
  static const Color darkTextPrimary = Color(0xFFFFFFFF);
  static const Color darkTextSecondary = Color(0xFFA0A8B8);
  static const Color darkTextMuted = Color(0xFF6B7280);

  // --------------------------------------------------------------------------
  // STATUS COLORS
  // --------------------------------------------------------------------------

  static const Color success = Color(0xFF16A34A);
  static const Color warning = Color(0xFFF59E0B);
  static const Color error = Color(0xFFDC2626);

  // --------------------------------------------------------------------------
  // COMMON
  // --------------------------------------------------------------------------

  static const Color white = Color(0xFFFFFFFF);
  static const Color black = Color(0xFF000000);
  static const Color transparent = Colors.transparent;

  // --------------------------------------------------------------------------
  // HELPERS
  // --------------------------------------------------------------------------

  static Color shadow(bool isDark) {
    return isDark
        ? black.withValues(alpha: 0.30)
        : black.withValues(alpha: 0.06);
  }

  static Color overlay(double opacity) {
    return black.withValues(alpha: opacity);
  }
}

extension AppColorsThemeExtension on BuildContext {
  bool get isDarkMode => Theme.of(this).brightness == Brightness.dark;

  Color get themePrimary => Theme.of(this).colorScheme.primary;
  Color get themeSecondary => Theme.of(this).colorScheme.secondary;
  Color get themeSurface => Theme.of(this).colorScheme.surface;
  Color get themeCard => isDarkMode ? AppColors.darkSurface : AppColors.lightSurface;
  Color get themeBackground => Theme.of(this).scaffoldBackgroundColor;

  Color get themeSoftSurface =>
      isDarkMode ? AppColors.darkSurface : AppColors.lightSoftSurface;
  Color get themeBorder =>
      isDarkMode ? AppColors.darkBorder : AppColors.lightBorder;
  /// Subtle divider/separator: white 12% on dark, black 8% on light.
  Color get themeLineBorder =>
      isDarkMode ? AppColors.white.withValues(alpha: 0.12) : AppColors.black.withValues(alpha: 0.08);

  Color get themeTextPrimary => Theme.of(this).colorScheme.onSurface;
  Color get themeTextSecondary =>
      isDarkMode ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;
  Color get themeTextMuted =>
      isDarkMode ? AppColors.darkTextMuted : AppColors.lightTextMuted;
  Color get themeError => Theme.of(this).colorScheme.error;
  Color get themeOnError => Theme.of(this).colorScheme.onError;
}
