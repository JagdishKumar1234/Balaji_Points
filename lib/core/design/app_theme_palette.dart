import 'package:flutter/material.dart';

/// Modern, attractive color palettes for light and dark themes
/// Designed for easy readability with perfect contrast
class ThemePalette {
  ThemePalette._();

  // ─────────────────────────────────────────────────────────────────────────
  // LIGHT THEME — Soft, elegant, high contrast for readability
  // ─────────────────────────────────────────────────────────────────────────

  /// Primary gradient colors (light theme)
  static const List<Color> lightPrimaryGradient = [
    Color(0xFF1e40af), // Deep professional blue
    Color(0xFF2563eb), // Bright blue
  ];

  /// Auth background gradient (light theme) - soft, elegant
  static const List<Color> lightAuthBackground = [
    Color(0xFFf0f9ff), // Soft sky blue
    Color(0xFFfef3c7), // Warm cream
  ];

  /// Glass effect surface (light theme)
  static const Color lightGlassBase = Color(0xFFffffff);
  static const double lightGlassOpacity = 0.92;

  // ─────────────────────────────────────────────────────────────────────────
  // DARK THEME — Rich, sophisticated, comfortable for night viewing
  // ─────────────────────────────────────────────────────────────────────────

  /// Primary gradient colors (dark theme)
  static const List<Color> darkPrimaryGradient = [
    Color(0xFF3b82f6), // Bright blue
    Color(0xFF1e40af), // Deep blue
  ];

  /// Auth background gradient (dark theme) - sophisticated
  static const List<Color> darkAuthBackground = [
    Color(0xFF0f172a), // Deep navy
    Color(0xFF1e293b), // Navy-slate
  ];

  /// Glass effect surface (dark theme)
  static const Color darkGlassBase = Color(0xFF1e293b);
  static const double darkGlassOpacity = 0.85;

  // ─────────────────────────────────────────────────────────────────────────
  // ACCENT COLORS — Loyalty tiers, status indicators
  // ─────────────────────────────────────────────────────────────────────────

  /// Gold accent - points, rewards
  static const Color accentGold = Color(0xFFd97706); // Warm, inviting gold
  static const Color accentGoldLight = Color(0xFFFCD34D);
  static const Color accentGoldSoft = Color(0xFFFEF3C7);

  /// Success - green
  static const Color accentSuccess = Color(0xFF10b981); // Emerald green
  static const Color accentSuccessLight = Color(0xFF6EE7B7);

  /// Error - red
  static const Color accentError = Color(0xFFef4444); // Vibrant red
  static const Color accentErrorLight = Color(0xFFFCA5A5);

  /// Warning - amber
  static const Color accentWarning = Color(0xFFF59E0B); // Warm amber
  static const Color accentWarningLight = Color(0xFFFCD34D);

  // ─────────────────────────────────────────────────────────────────────────
  // TIER COLORS — Loyalty program
  // ─────────────────────────────────────────────────────────────────────────

  static const Color tierBronze = Color(0xFFB87333);
  static const Color tierSilver = Color(0xFFC0C0C0);
  static const Color tierGold = Color(0xFFD4AF37);
  static const Color tierPlatinum = Color(0xFF7C3AED); // Vibrant purple

  // ─────────────────────────────────────────────────────────────────────────
  // CONTRAST & ACCESSIBILITY
  // ─────────────────────────────────────────────────────────────────────────

  /// Light theme text - maximum readability
  static const Color lightTextPrimary = Color(0xFF0f172a); // Deep navy
  static const Color lightTextSecondary = Color(0xFF475569); // Slate
  static const Color lightTextMuted = Color(0xFF94a3b8); // Light slate

  /// Dark theme text - comfortable contrast
  static const Color darkTextPrimary = Color(0xFFf1f5f9); // Off-white
  static const Color darkTextSecondary = Color(0xFFcbd5e1); // Light slate
  static const Color darkTextMuted = Color(0xFF64748b); // Muted slate

  /// Surfaces for readability
  static const Color lightSurface = Color(0xFFffffff);
  static const Color lightBackground = Color(0xFFf8fafc);
  static const Color lightSoftSurface = Color(0xFFf1f5f9);

  static const Color darkSurface = Color(0xFF1e293b);
  static const Color darkBackground = Color(0xFF0f172a);
  static const Color darkSoftSurface = Color(0xFF334155);

  // ─────────────────────────────────────────────────────────────────────────
  // GRADIENT DEFINITIONS
  // ─────────────────────────────────────────────────────────────────────────

  static LinearGradient lightPrimaryGradientLinear = const LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: lightPrimaryGradient,
  );

  static LinearGradient darkPrimaryGradientLinear = const LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: darkPrimaryGradient,
  );

  static LinearGradient lightAuthBackgroundGradient = const LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: lightAuthBackground,
    stops: [0.0, 1.0],
  );

  static LinearGradient darkAuthBackgroundGradient = const LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: darkAuthBackground,
    stops: [0.0, 1.0],
  );

  // ─────────────────────────────────────────────────────────────────────────
  // HELPER METHODS
  // ─────────────────────────────────────────────────────────────────────────

  static LinearGradient getAuthBackgroundGradient(bool isDark) {
    return isDark
        ? darkAuthBackgroundGradient
        : lightAuthBackgroundGradient;
  }

  static LinearGradient getPrimaryGradient(bool isDark) {
    return isDark ? darkPrimaryGradientLinear : lightPrimaryGradientLinear;
  }

  static Color getTextPrimary(bool isDark) {
    return isDark ? darkTextPrimary : lightTextPrimary;
  }

  static Color getTextSecondary(bool isDark) {
    return isDark ? darkTextSecondary : lightTextSecondary;
  }

  static Color getBackground(bool isDark) {
    return isDark ? darkBackground : lightBackground;
  }

  static Color getSurface(bool isDark) {
    return isDark ? darkSurface : lightSurface;
  }
}

/// Responsive gradient helper for BuildContext
extension ThemePaletteExtension on BuildContext {

  bool get isDark => Theme.of(this).brightness == Brightness.dark;

  LinearGradient get authBackgroundGradient {
    return ThemePalette.getAuthBackgroundGradient(isDark);
  }

  LinearGradient get primaryGradient {
    return ThemePalette.getPrimaryGradient(isDark);
  }

  Color get textPrimary => ThemePalette.getTextPrimary(isDark);
  Color get textSecondary => ThemePalette.getTextSecondary(isDark);
  Color get bgSurface => ThemePalette.getBackground(isDark);
  Color get bgPaletteContainer => ThemePalette.getSurface(isDark);
}
