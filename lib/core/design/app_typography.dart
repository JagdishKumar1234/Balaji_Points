import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

/// Balaji Points Design System v2.0 — Typography.
///
/// Single font family: Manrope.
/// Five canonical text sizes:
///   Hero     32 / Bold    700
///   Title    20 / SemiBold 600
///   Section  16 / SemiBold 600
///   Body     14 / Regular  400
///   Caption  12 / Medium   500
///
/// All legacy method names (h1–h5, bodyMedium, labelLarge…) are kept as
/// aliases so existing call-sites compile without changes.
class AppTypography {
  AppTypography._();

  // ── Internal factory ────────────────────────────────────────────────────────

  static TextStyle _manrope({
    required double size,
    required FontWeight weight,
    double height = 1.5,
    double? letterSpacing,
    Color? color,
  }) =>
      GoogleFonts.manrope(
        fontSize: size,
        fontWeight: weight,
        height: height,
        letterSpacing: letterSpacing,
        color: color,
      );

  // ── Canonical 5-style scale ─────────────────────────────────────────────────

  /// 32 / Bold — splash, wallet balance, hero number.
  static TextStyle hero({Color? color}) => _manrope(
        size: 32,
        weight: FontWeight.w700,
        height: 1.2,
        letterSpacing: -0.5,
        color: color,
      );

  /// 20 / SemiBold — page title, section heading.
  static TextStyle title({Color? color}) => _manrope(
        size: 20,
        weight: FontWeight.w600,
        height: 1.3,
        color: color,
      );

  /// 16 / SemiBold — card heading, list item label.
  static TextStyle section({Color? color}) => _manrope(
        size: 16,
        weight: FontWeight.w600,
        height: 1.4,
        color: color,
      );

  /// 14 / Medium — standard body copy.
  static TextStyle body({Color? color}) => _manrope(
        size: 14,
        weight: FontWeight.w500,
        height: 1.5,
        color: color,
      );

  /// 12 / Medium — captions, meta text, timestamps.
  static TextStyle caption({Color? color}) => _manrope(
        size: 12,
        weight: FontWeight.w500,
        height: 1.5,
        color: color,
      );

  // ── Numeric variant (same Manrope, tabular feel) ────────────────────────────

  /// Points / balance display — 32 Bold.
  static TextStyle pointsHero({Color? color}) => _manrope(
        size: 32,
        weight: FontWeight.w700,
        height: 1.1,
        letterSpacing: -0.5,
        color: color,
      );

  /// Inline points — 20 SemiBold.
  static TextStyle pointsLarge({Color? color}) => _manrope(
        size: 20,
        weight: FontWeight.w600,
        height: 1.2,
        color: color,
      );

  /// Small points badge — 14 SemiBold.
  static TextStyle pointsSmall({Color? color}) => _manrope(
        size: 14,
        weight: FontWeight.w600,
        height: 1.4,
        color: color,
      );

  // ── Button text ─────────────────────────────────────────────────────────────

  /// 16 / SemiBold — primary/secondary buttons.
  static TextStyle buttonLarge({Color? color}) => _manrope(
        size: 16,
        weight: FontWeight.w600,
        height: 1.0,
        color: color,
      );

  /// 14 / SemiBold — compact buttons, chips.
  static TextStyle buttonMedium({Color? color}) => _manrope(
        size: 14,
        weight: FontWeight.w600,
        height: 1.0,
        color: color,
      );

  // ── Legacy aliases (zero call-site breakage) ────────────────────────────────
  // All map to the nearest canonical style.

  static TextStyle h1({Color? color})   => hero(color: color);
  static TextStyle h2({Color? color})   => _manrope(size: 28, weight: FontWeight.w700, height: 1.25, letterSpacing: -0.3, color: color);
  static TextStyle h3({Color? color})   => title(color: color);
  static TextStyle h4({Color? color})   => _manrope(size: 18, weight: FontWeight.w600, height: 1.4, color: color);
  static TextStyle h5({Color? color})   => section(color: color);

  static TextStyle bodyLarge({Color? color})  => section(color: color);
  static TextStyle bodyMedium({Color? color}) => body(color: color);
  static TextStyle bodySmall({Color? color})  => caption(color: color);

  static TextStyle labelLarge({Color? color})  => _manrope(size: 14, weight: FontWeight.w600, height: 1.4, color: color);
  static TextStyle labelMedium({Color? color}) => _manrope(size: 12, weight: FontWeight.w600, height: 1.4, color: color);
  static TextStyle labelSmall({Color? color})  => _manrope(size: 11, weight: FontWeight.w500, height: 1.4, color: color);

  static TextStyle overline({Color? color}) => _manrope(size: 10, weight: FontWeight.w600, height: 1.4, letterSpacing: 0.8, color: color);
  static TextStyle buttonSmall({Color? color}) => _manrope(size: 12, weight: FontWeight.w600, height: 1.0, color: color);

  // Legacy numeric aliases
  static TextStyle displayLarge({Color? color}) => hero(color: color);
  static TextStyle displayMedium({Color? color}) => hero(color: color);
  static TextStyle displaySmall({Color? color})  => hero(color: color);
  static TextStyle balanceAmount({Color? color}) => pointsHero(color: color);
  static TextStyle pointsMedium({Color? color})  => pointsLarge(color: color);

  // ── Material TextTheme ───────────────────────────────────────────────────────

  static TextTheme textTheme(bool isDark) {
    final tp = isDark ? AppColors.darkTextPrimary   : AppColors.textPrimary;
    final ts = isDark ? AppColors.darkTextSecondary : AppColors.textSecondary;
    final tm = isDark ? AppColors.darkTextMuted     : AppColors.textMuted;

    return TextTheme(
      displayLarge:  hero(color: tp),
      displayMedium: hero(color: tp),
      displaySmall:  hero(color: tp),
      headlineLarge:  h2(color: tp),
      headlineMedium: title(color: tp),
      headlineSmall:  title(color: tp),
      titleLarge:   h4(color: tp),
      titleMedium:  section(color: tp),
      titleSmall:   labelLarge(color: tp),
      bodyLarge:    section(color: tp),
      bodyMedium:   body(color: ts),
      bodySmall:    caption(color: tm),
      labelLarge:   labelLarge(color: tp),
      labelMedium:  labelMedium(color: ts),
      labelSmall:   labelSmall(color: tm),
    );
  }
}
