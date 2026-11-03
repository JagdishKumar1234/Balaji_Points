import 'package:flutter/material.dart';

/// Balaji Points Design System v3 — Color tokens.
///
/// Source of truth: `docs/Carpenter Rewards App – UI Design.html`.
/// One brand (navy + gold), one neutral ramp, three status pairs.
/// No extra palettes, no gradients outside celebration screens.
///
/// Every text/icon pair below meets WCAG AA (≥ 4.5:1 for text, ≥ 3:1 for
/// icons and large text). See `docs/ui_spec_conformance_audit.md` §5.
class AppColors {
  AppColors._();

  // ── Brand ──────────────────────────────────────────────────────────────────

  /// Navy — headers, sidebar, headings, icon tiles. White on navy = 16:1.
  static const Color primary = Color(0xFF0B1F3A);

  /// Navy hover / active sidebar item.
  static const Color primaryLight = Color(0xFF16325C);

  /// Lines and progress tracks drawn on navy.
  static const Color primaryLine = Color(0xFF2B4570);

  /// Very light navy tint for selected rows and soft fills.
  static const Color primarySoft = Color(0xFFE8EDF5);

  /// Dark-mode primary: readable as text on dark (3.9:1) and under white
  /// text (4.8:1). Navy itself is too dark to see on a dark background.
  static const Color primaryOnDark = Color(0xFF4A74B0);

  /// Secondary text on navy surfaces (10.9:1).
  static const Color onPrimaryMuted = Color(0xFFC9D3E3);

  /// Gold accent — main call-to-action fill (navy text on gold = 6.9:1),
  /// icons on navy, progress. Never use as text on white.
  static const Color gold = Color(0xFFC9A24B);
  static const Color goldSoft = Color(0xFFFBF0D3);

  /// Desktop sidebar / rail background.
  static const Color navigation = primary;

  // ── Status (single static values that work in light AND dark) ──────────────

  static const Color success = Color(
    0xFF2F855A,
  ); // 4.5:1 on white & under white
  static const Color warning = Color(
    0xFFA87F1E,
  ); // dark gold — same hue as brand
  static const Color error = Color(0xFFB3261E); // 6.5:1 on white & under white

  // Status chips — tinted background + dark text (spec).
  static const Color successSoft = Color(0xFFE6F2EA);
  static const Color successText = Color(0xFF1C5B34);
  static const Color pendingSoft = goldSoft;
  static const Color pendingText = Color(0xFF6B4D08);
  static const Color errorSoft = Color(0xFFF6DCDA);
  static const Color errorText = Color(0xFF8C1D18);

  // ── Light surfaces ──────────────────────────────────────────────────────────

  static const Color background = Color(0xFFF4F5F7);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color softSurface = Color(0xFFEEF0F3);
  static const Color border = Color(0xFFE3E6EB); // cards, dividers
  static const Color borderStrong = Color(
    0xFFCBD1DB,
  ); // inputs, outline buttons
  static const Color divider = Color(0xFFEEF0F3); // table rows

  // ── Light text ──────────────────────────────────────────────────────────────

  static const Color textPrimary = Color(0xFF1B2433);
  static const Color textSecondary = Color(0xFF5B6577);
  static const Color textMuted = Color(0xFF667085); // 5.0:1 — was failing 2.6:1

  // ── Dark surfaces (navy-black ramp from "Wallet dark") ──────────────────────

  static const Color darkBackground = Color(0xFF0B1220);
  static const Color darkChrome = Color(0xFF121B2D); // app bar, bottom nav
  static const Color darkSurface = Color(0xFF162033); // cards, sheets
  static const Color darkSoftSurface = Color(
    0xFF1F2A40,
  ); // raised chips, inputs
  static const Color darkBorder = Color(0xFF26324A);

  // ── Dark text ───────────────────────────────────────────────────────────────

  static const Color darkTextPrimary = Color(0xFFE8ECF3);
  static const Color darkTextSecondary = Color(0xFFB4BED0);
  static const Color darkTextMuted = Color(0xFF9AA6BA);

  // Dark status chips.
  static const Color darkSuccessSoft = Color(0xFF14301F);
  static const Color darkSuccessText = Color(0xFF7FD39B);
  static const Color darkPendingSoft = Color(0xFF3A2E0F);
  static const Color darkPendingText = Color(0xFFE9C46A);
  static const Color darkErrorSoft = Color(0xFF3B1816);
  static const Color darkErrorText = Color(0xFFF2A19B);

  // ── Loyalty tiers (kept muted; platinum uses brand blue, not purple) ────────

  static const Color tierBronze = Color(0xFFB0793F);
  static const Color tierSilver = Color(0xFF9AA6BA);
  static const Color tierGold = gold;
  static const Color tierPlatinum = primaryOnDark;

  // ── Common ──────────────────────────────────────────────────────────────────

  static const Color white = Color(0xFFFFFFFF);
  static const Color black = Color(0xFF000000);
  static const Color transparent = Colors.transparent;

  // ── Shadows (navy-tinted, tight — spec) ─────────────────────────────────────

  /// Card shadow: 0 1 2 rgba(11,31,58,.06).
  static List<BoxShadow> get shadowLevel1 => [
    BoxShadow(
      color: primary.withValues(alpha: 0.06),
      blurRadius: 2,
      offset: const Offset(0, 1),
    ),
  ];

  /// Hero / points card shadow: 0 2 6 rgba(11,31,58,.10).
  static List<BoxShadow> get shadowLevel2 => [
    BoxShadow(
      color: primary.withValues(alpha: 0.10),
      blurRadius: 6,
      offset: const Offset(0, 2),
    ),
  ];

  /// Dark mode relies on borders, not shadows.
  static List<BoxShadow> get shadowLevel1Dark => const [];
}

// ── BuildContext extensions ──────────────────────────────────────────────────

extension AppColorsThemeExtension on BuildContext {
  bool get isDarkMode => Theme.of(this).brightness == Brightness.dark;

  // Brand
  Color get themePrimary => Theme.of(this).colorScheme.primary;
  Color get themeOnPrimary => Theme.of(this).colorScheme.onPrimary;
  Color get themePrimaryLight =>
      isDarkMode ? AppColors.primaryOnDark : AppColors.primaryLight;
  Color get themePrimarySoft => isDarkMode
      ? AppColors.primaryOnDark.withValues(alpha: 0.16)
      : AppColors.primarySoft;

  /// Navy brand surface (headers, hero cards). Stays navy in both themes.
  Color get themeBrandSurface => AppColors.primary;
  Color get themeGold => AppColors.gold;
  Color get themeGoldSoft =>
      isDarkMode ? AppColors.darkPendingSoft : AppColors.goldSoft;
  Color get themeSecondary => Theme.of(this).colorScheme.secondary; // gold
  Color get themeOnSecondary => Theme.of(this).colorScheme.onSecondary;

  // Surfaces
  Color get themeBackground => Theme.of(this).scaffoldBackgroundColor;
  Color get themeSurface => Theme.of(this).colorScheme.surface;
  Color get themeChrome =>
      isDarkMode ? AppColors.darkChrome : AppColors.surface;
  Color get themeSoftSurface =>
      isDarkMode ? AppColors.darkSoftSurface : AppColors.softSurface;
  Color get themeCard => isDarkMode ? AppColors.darkSurface : AppColors.surface;
  Color get themeBorder => isDarkMode ? AppColors.darkBorder : AppColors.border;
  Color get themeBorderStrong =>
      isDarkMode ? AppColors.darkBorder : AppColors.borderStrong;
  Color get themeDivider =>
      isDarkMode ? AppColors.darkBorder : AppColors.divider;
  Color get themeLineBorder => themeBorder;

  // Text
  Color get themeTextPrimary => Theme.of(this).colorScheme.onSurface;
  Color get themeTextSecondary =>
      isDarkMode ? AppColors.darkTextSecondary : AppColors.textSecondary;
  Color get themeTextMuted =>
      isDarkMode ? AppColors.darkTextMuted : AppColors.textMuted;

  // Status
  Color get themeError => Theme.of(this).colorScheme.error;
  Color get themeOnError => Theme.of(this).colorScheme.onError;
  Color get themeSuccessSoft =>
      isDarkMode ? AppColors.darkSuccessSoft : AppColors.successSoft;
  Color get themeSuccessText =>
      isDarkMode ? AppColors.darkSuccessText : AppColors.successText;
  Color get themePendingSoft =>
      isDarkMode ? AppColors.darkPendingSoft : AppColors.pendingSoft;
  Color get themePendingText =>
      isDarkMode ? AppColors.darkPendingText : AppColors.pendingText;
  Color get themeErrorSoft =>
      isDarkMode ? AppColors.darkErrorSoft : AppColors.errorSoft;
  Color get themeErrorText =>
      isDarkMode ? AppColors.darkErrorText : AppColors.errorText;

  /// Foreground for icons/text that should read as "brand" — navy in light,
  /// light ink in dark.
  Color get themeContentColor =>
      isDarkMode ? AppColors.darkTextPrimary : AppColors.primary;

  // Shadow
  List<BoxShadow> get themeShadow =>
      isDarkMode ? AppColors.shadowLevel1Dark : AppColors.shadowLevel1;
}
