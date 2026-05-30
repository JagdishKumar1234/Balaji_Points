import 'package:flutter/material.dart';

/// Balaji Points Design System v2.0 — Color tokens.
///
/// One primary color (navy), one accent (gold), one success, one error.
/// No gradients, no neon, no heavy tints.
class AppColors {
  AppColors._();

  // ── Brand ──────────────────────────────────────────────────────────────────

  static const Color primary      = Color(0xFF243B6B); // navy
  static const Color primaryLight = Color(0xFF3655A7); // lighter navy for hover/pressed
  static const Color primarySoft  = Color(0xFFEAF0FF); // very light navy tint (chips, tags)

  static const Color gold     = Color(0xFFF4B400); // accent — points, rewards
  static const Color goldSoft = Color(0xFFFFF7DD); // very light gold tint

  // ── Status ─────────────────────────────────────────────────────────────────

  static const Color success = Color(0xFF22C55E);
  static const Color error   = Color(0xFFEF4444);
  static const Color warning = Color(0xFFF59E0B); // expiring-soon only

  // ── Light theme surfaces ────────────────────────────────────────────────────

  static const Color background   = Color(0xFFF8F9FB);
  static const Color surface      = Color(0xFFFFFFFF);
  static const Color softSurface  = Color(0xFFF2F4F7);
  static const Color border       = Color(0xFFE5E7EB);

  // ── Light theme text ────────────────────────────────────────────────────────

  static const Color textPrimary   = Color(0xFF111827);
  static const Color textSecondary = Color(0xFF6B7280);
  static const Color textMuted     = Color(0xFF9CA3AF);

  // ── Dark theme surfaces ─────────────────────────────────────────────────────

  static const Color darkBackground  = Color(0xFF0F1115);
  static const Color darkSurface     = Color(0xFF171A22);
  static const Color darkSoftSurface = Color(0xFF1E2430);
  static const Color darkBorder      = Color(0xFF2B313D);

  // ── Dark theme text ─────────────────────────────────────────────────────────

  static const Color darkTextPrimary   = Color(0xFFFFFFFF);
  static const Color darkTextSecondary = Color(0xFFD1D5DB);
  static const Color darkTextMuted     = Color(0xFF9CA3AF);

  // ── Loyalty tiers ───────────────────────────────────────────────────────────

  static const Color tierBronze   = Color(0xFFCD7F32);
  static const Color tierSilver   = Color(0xFFC0C0C0);
  static const Color tierGold     = gold;
  static const Color tierPlatinum = Color(0xFF7C3AED);

  // ── Common ──────────────────────────────────────────────────────────────────

  static const Color white       = Color(0xFFFFFFFF);
  static const Color black       = Color(0xFF000000);
  static const Color transparent = Colors.transparent;

  // ── Shadow helper ───────────────────────────────────────────────────────────

  /// Single shadow level — opacity 0.05, blur 24, offset (0, 8).
  static List<BoxShadow> get shadowLevel1 => [
        BoxShadow(
          color: black.withValues(alpha: 0.05),
          blurRadius: 24,
          offset: const Offset(0, 8),
        ),
      ];

  /// Dark-mode variant — slightly stronger.
  static List<BoxShadow> get shadowLevel1Dark => [
        BoxShadow(
          color: black.withValues(alpha: 0.20),
          blurRadius: 24,
          offset: const Offset(0, 8),
        ),
      ];
}

// ── BuildContext extensions ──────────────────────────────────────────────────

extension AppColorsThemeExtension on BuildContext {
  bool get isDarkMode => Theme.of(this).brightness == Brightness.dark;

  // Brand
  Color get themePrimary      => Theme.of(this).colorScheme.primary;
  Color get themePrimaryLight => isDarkMode ? AppColors.primaryLight : AppColors.primaryLight;
  Color get themePrimarySoft  => isDarkMode ? AppColors.primary.withValues(alpha: 0.12) : AppColors.primarySoft;
  Color get themeGold         => AppColors.gold;
  Color get themeGoldSoft     => isDarkMode ? AppColors.gold.withValues(alpha: 0.15) : AppColors.goldSoft;
  Color get themeSecondary    => Theme.of(this).colorScheme.secondary; // = gold

  // Surfaces
  Color get themeBackground   => Theme.of(this).scaffoldBackgroundColor;
  Color get themeSurface      => Theme.of(this).colorScheme.surface;
  Color get themeSoftSurface  => isDarkMode ? AppColors.darkSoftSurface : AppColors.softSurface;
  Color get themeCard         => isDarkMode ? AppColors.darkSurface : AppColors.surface;
  Color get themeBorder       => isDarkMode ? AppColors.darkBorder : AppColors.border;
  Color get themeLineBorder   => isDarkMode
      ? AppColors.white.withValues(alpha: 0.08)
      : AppColors.black.withValues(alpha: 0.06);

  // Text
  Color get themeTextPrimary   => Theme.of(this).colorScheme.onSurface;
  Color get themeTextSecondary => isDarkMode ? AppColors.darkTextSecondary : AppColors.textSecondary;
  Color get themeTextMuted     => isDarkMode ? AppColors.darkTextMuted : AppColors.textMuted;

  // Status
  Color get themeError   => Theme.of(this).colorScheme.error;
  Color get themeOnError => Theme.of(this).colorScheme.onError;

  // Foreground — white in dark (so icons/text never appear as navy on dark bg)
  Color get themeContentColor =>
      isDarkMode ? AppColors.darkTextPrimary : AppColors.primary;

  // Shadow
  List<BoxShadow> get themeShadow =>
      isDarkMode ? AppColors.shadowLevel1Dark : AppColors.shadowLevel1;
}
