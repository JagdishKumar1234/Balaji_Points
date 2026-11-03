import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

/// Balaji Points Design System v3 — Typography (UI spec).
///
/// Single font family: **Nunito** (rounded, friendly, very legible for
/// first-time smartphone users). Nunito has a smaller x-height than Inter,
/// so the scale is one step larger for comfortable reading.
/// Weight rule: headings 800/700 · labels 700 · body 500 (Nunito's 400 is thin).
///   Points hero 40 / 800   — balance number
///   Hero        32 / 800   — auth & splash titles
///   Title       22 / 800   — screen title
///   Section     18 / 700   — card / section heading
///   Input       16 / 500   — field text, list titles
///   Button      16 / 700
///   Body        15 / 500   — copy (line height 1.45)
///   Label       13 / 700   — field labels, table headers, chips
///   Caption     13 / 500   — meta, timestamps
///   Nav label   12 / 700   — smallest size allowed anywhere (12)
///
/// All legacy method names (h1–h5, bodyMedium, labelLarge…) are kept as
/// aliases so existing call-sites compile without changes.
class AppTypography {
  AppTypography._();

  // ── Internal factory ────────────────────────────────────────────────────────

  /// Font family name for ThemeData.fontFamily (so raw TextStyles inherit it).
  static String get fontFamily => GoogleFonts.nunito().fontFamily!;

  static TextStyle _font({
    required double size,
    required FontWeight weight,
    double height = 1.5,
    double? letterSpacing,
    Color? color,
  }) => GoogleFonts.nunito(
    fontSize: size,
    fontWeight: weight,
    height: height,
    letterSpacing: letterSpacing,
    color: color,
  );

  // ── Canonical 5-style scale ─────────────────────────────────────────────────

  /// 32 / Bold — splash, wallet balance, hero number.
  static TextStyle hero({Color? color}) => _font(
    size: 32,
    weight: FontWeight.w800,
    height: 1.2,
    letterSpacing: -0.5,
    color: color,
  );

  /// 20 / SemiBold — page title, section heading.
  static TextStyle title({Color? color}) =>
      _font(size: 22, weight: FontWeight.w800, height: 1.3, color: color);

  /// 16 / Bold — card heading, section heading.
  static TextStyle section({Color? color}) =>
      _font(size: 18, weight: FontWeight.w700, height: 1.4, color: color);

  /// 15 / Regular — input text, list item titles.
  static TextStyle input({Color? color}) =>
      _font(size: 16, weight: FontWeight.w500, height: 1.4, color: color);

  /// 14 / Regular — standard body copy.
  static TextStyle body({Color? color}) =>
      _font(size: 15, weight: FontWeight.w500, height: 1.45, color: color);

  /// 12 / SemiBold — field labels, table headers, chips.
  static TextStyle label({Color? color}) =>
      _font(size: 13, weight: FontWeight.w700, height: 1.4, color: color);

  /// 12 / Regular — captions, meta text, timestamps.
  static TextStyle caption({Color? color}) =>
      _font(size: 13, weight: FontWeight.w500, height: 1.45, color: color);

  /// 11 / SemiBold — bottom-nav labels. Minimum size in the app.
  static TextStyle navLabel({Color? color}) =>
      _font(size: 12, weight: FontWeight.w700, height: 1.3, color: color);

  // ── Numeric variant ────────────────────────────

  /// Points / balance display — 40 Bold (spec).
  static TextStyle pointsHero({Color? color}) => _font(
    size: 40,
    weight: FontWeight.w800,
    height: 1.1,
    letterSpacing: -0.5,
    color: color,
  );

  /// Stat / inline points — 24 Bold.
  static TextStyle pointsLarge({Color? color}) =>
      _font(size: 24, weight: FontWeight.w800, height: 1.2, color: color);

  /// Small points badge — 14 SemiBold.
  static TextStyle pointsSmall({Color? color}) =>
      _font(size: 15, weight: FontWeight.w700, height: 1.4, color: color);

  // ── Button text ─────────────────────────────────────────────────────────────

  /// 15 / SemiBold — standard button label (spec).
  static TextStyle button({Color? color}) =>
      _font(size: 16, weight: FontWeight.w700, height: 1.0, color: color);

  /// 16 / SemiBold — hero buttons.
  static TextStyle buttonLarge({Color? color}) =>
      _font(size: 17, weight: FontWeight.w700, height: 1.0, color: color);

  /// 14 / SemiBold — compact buttons, chips.
  static TextStyle buttonMedium({Color? color}) =>
      _font(size: 15, weight: FontWeight.w700, height: 1.0, color: color);

  // ── Legacy aliases (zero call-site breakage) ────────────────────────────────
  // All map to the nearest canonical style.

  static TextStyle h1({Color? color}) => hero(color: color);
  static TextStyle h2({Color? color}) => _font(
    size: 28,
    weight: FontWeight.w800,
    height: 1.25,
    letterSpacing: -0.3,
    color: color,
  );
  static TextStyle h3({Color? color}) => title(color: color);
  static TextStyle h4({Color? color}) =>
      _font(size: 20, weight: FontWeight.w800, height: 1.4, color: color);
  static TextStyle h5({Color? color}) => section(color: color);

  static TextStyle bodyLarge({Color? color}) => input(color: color);
  static TextStyle bodyMedium({Color? color}) => body(color: color);
  static TextStyle bodySmall({Color? color}) => caption(color: color);

  static TextStyle labelLarge({Color? color}) =>
      _font(size: 15, weight: FontWeight.w700, height: 1.4, color: color);
  static TextStyle labelMedium({Color? color}) => label(color: color);
  static TextStyle labelSmall({Color? color}) =>
      _font(size: 12, weight: FontWeight.w700, height: 1.4, color: color);

  /// 12 / SemiBold uppercase — e.g. "NEW REGISTRATION" (spec, gold on navy).
  static TextStyle overline({Color? color}) => _font(
    size: 12,
    weight: FontWeight.w800,
    height: 1.4,
    letterSpacing: 0.8,
    color: color,
  );
  static TextStyle buttonSmall({Color? color}) =>
      _font(size: 13, weight: FontWeight.w700, height: 1.0, color: color);

  // Legacy numeric aliases
  static TextStyle displayLarge({Color? color}) => hero(color: color);
  static TextStyle displayMedium({Color? color}) => hero(color: color);
  static TextStyle displaySmall({Color? color}) => hero(color: color);
  static TextStyle balanceAmount({Color? color}) => pointsHero(color: color);
  static TextStyle pointsMedium({Color? color}) => pointsLarge(color: color);

  // ── Material TextTheme ───────────────────────────────────────────────────────

  static TextTheme textTheme(bool isDark) {
    final tp = isDark ? AppColors.darkTextPrimary : AppColors.textPrimary;
    final ts = isDark ? AppColors.darkTextSecondary : AppColors.textSecondary;
    final tm = isDark ? AppColors.darkTextMuted : AppColors.textMuted;

    return TextTheme(
      displayLarge: hero(color: tp),
      displayMedium: hero(color: tp),
      displaySmall: hero(color: tp),
      headlineLarge: h2(color: tp),
      headlineMedium: title(color: tp),
      headlineSmall: title(color: tp),
      titleLarge: h4(color: tp),
      titleMedium: section(color: tp),
      titleSmall: labelLarge(color: tp),
      bodyLarge: input(color: tp),
      bodyMedium: body(color: tp),
      bodySmall: caption(color: ts),
      labelLarge: labelLarge(color: tp),
      labelMedium: label(color: ts),
      labelSmall: labelSmall(color: tm),
    );
  }
}
