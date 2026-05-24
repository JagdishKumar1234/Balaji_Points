import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

/// Enterprise design system — typography tokens.
///
/// Primary    : Plus Jakarta Sans (UI labels, body, headings)
/// Secondary  : Outfit          (subheadings, display callouts)
/// Numeric    : Satoshi          (points, balances, counters — loaded via google_fonts)
class AppTypography {
  AppTypography._();

  // --------------------------------------------------------------------------
  // Font families
  // --------------------------------------------------------------------------
  static String get primary => GoogleFonts.plusJakartaSans().fontFamily!;
  static String get secondary => GoogleFonts.outfit().fontFamily!;
  // Satoshi is available through google_fonts as well
  static String get numeric => GoogleFonts.spaceGrotesk().fontFamily!;

  // --------------------------------------------------------------------------
  // Base TextStyle factories
  // --------------------------------------------------------------------------
  static TextStyle _jakarta({
    required double size,
    required FontWeight weight,
    double? height,
    double? letterSpacing,
    Color? color,
  }) =>
      GoogleFonts.plusJakartaSans(
        fontSize: size,
        fontWeight: weight,
        height: height,
        letterSpacing: letterSpacing,
        color: color,
      );

  static TextStyle _outfit({
    required double size,
    required FontWeight weight,
    double? height,
    double? letterSpacing,
    Color? color,
  }) =>
      GoogleFonts.outfit(
        fontSize: size,
        fontWeight: weight,
        height: height,
        letterSpacing: letterSpacing,
        color: color,
      );

  static TextStyle _numeric({
    required double size,
    required FontWeight weight,
    double? height,
    double? letterSpacing,
    Color? color,
  }) =>
      GoogleFonts.spaceGrotesk(
        fontSize: size,
        fontWeight: weight,
        height: height,
        letterSpacing: letterSpacing,
        color: color,
      );

  // --------------------------------------------------------------------------
  // Display — Outfit, used for hero numbers / splash callouts
  // --------------------------------------------------------------------------
  static TextStyle displayLarge({Color? color}) => _outfit(
        size: 48,
        weight: FontWeight.w700,
        height: 1.1,
        letterSpacing: -1.0,
        color: color,
      );

  static TextStyle displayMedium({Color? color}) => _outfit(
        size: 40,
        weight: FontWeight.w700,
        height: 1.15,
        letterSpacing: -0.8,
        color: color,
      );

  static TextStyle displaySmall({Color? color}) => _outfit(
        size: 32,
        weight: FontWeight.w600,
        height: 1.2,
        letterSpacing: -0.5,
        color: color,
      );

  // --------------------------------------------------------------------------
  // Headings — Plus Jakarta Sans
  // --------------------------------------------------------------------------
  static TextStyle h1({Color? color}) => _jakarta(
        size: 28,
        weight: FontWeight.w700,
        height: 1.25,
        letterSpacing: -0.3,
        color: color,
      );

  static TextStyle h2({Color? color}) => _jakarta(
        size: 24,
        weight: FontWeight.w700,
        height: 1.3,
        letterSpacing: -0.2,
        color: color,
      );

  static TextStyle h3({Color? color}) => _jakarta(
        size: 20,
        weight: FontWeight.w600,
        height: 1.35,
        color: color,
      );

  static TextStyle h4({Color? color}) => _jakarta(
        size: 18,
        weight: FontWeight.w600,
        height: 1.4,
        color: color,
      );

  static TextStyle h5({Color? color}) => _jakarta(
        size: 16,
        weight: FontWeight.w600,
        height: 1.4,
        color: color,
      );

  // --------------------------------------------------------------------------
  // Body — Plus Jakarta Sans
  // --------------------------------------------------------------------------
  static TextStyle bodyLarge({Color? color}) => _jakarta(
        size: 16,
        weight: FontWeight.w400,
        height: 1.6,
        color: color,
      );

  static TextStyle bodyMedium({Color? color}) => _jakarta(
        size: 14,
        weight: FontWeight.w400,
        height: 1.6,
        color: color,
      );

  static TextStyle bodySmall({Color? color}) => _jakarta(
        size: 12,
        weight: FontWeight.w400,
        height: 1.5,
        color: color,
      );

  // --------------------------------------------------------------------------
  // Labels / UI text
  // --------------------------------------------------------------------------
  static TextStyle labelLarge({Color? color}) => _jakarta(
        size: 14,
        weight: FontWeight.w600,
        height: 1.4,
        letterSpacing: 0.1,
        color: color,
      );

  static TextStyle labelMedium({Color? color}) => _jakarta(
        size: 12,
        weight: FontWeight.w600,
        height: 1.4,
        letterSpacing: 0.1,
        color: color,
      );

  static TextStyle labelSmall({Color? color}) => _jakarta(
        size: 11,
        weight: FontWeight.w500,
        height: 1.4,
        letterSpacing: 0.2,
        color: color,
      );

  // --------------------------------------------------------------------------
  // Captions / hints
  // --------------------------------------------------------------------------
  static TextStyle caption({Color? color}) => _jakarta(
        size: 11,
        weight: FontWeight.w400,
        height: 1.5,
        color: color,
      );

  static TextStyle overline({Color? color}) => _jakarta(
        size: 10,
        weight: FontWeight.w600,
        height: 1.4,
        letterSpacing: 0.8,
        color: color,
      );

  // --------------------------------------------------------------------------
  // Button text
  // --------------------------------------------------------------------------
  static TextStyle buttonLarge({Color? color}) => _jakarta(
        size: 16,
        weight: FontWeight.w700,
        height: 1.0,
        letterSpacing: 0.2,
        color: color,
      );

  static TextStyle buttonMedium({Color? color}) => _jakarta(
        size: 14,
        weight: FontWeight.w600,
        height: 1.0,
        letterSpacing: 0.2,
        color: color,
      );

  static TextStyle buttonSmall({Color? color}) => _jakarta(
        size: 12,
        weight: FontWeight.w600,
        height: 1.0,
        letterSpacing: 0.2,
        color: color,
      );

  // --------------------------------------------------------------------------
  // Numeric / Points — Space Grotesk (tabular, monospace-feel)
  // --------------------------------------------------------------------------
  static TextStyle pointsHero({Color? color}) => _numeric(
        size: 40,
        weight: FontWeight.w700,
        height: 1.1,
        letterSpacing: -1.0,
        color: color,
      );

  static TextStyle pointsLarge({Color? color}) => _numeric(
        size: 28,
        weight: FontWeight.w700,
        height: 1.2,
        letterSpacing: -0.5,
        color: color,
      );

  static TextStyle pointsMedium({Color? color}) => _numeric(
        size: 20,
        weight: FontWeight.w600,
        height: 1.3,
        color: color,
      );

  static TextStyle pointsSmall({Color? color}) => _numeric(
        size: 14,
        weight: FontWeight.w600,
        height: 1.4,
        color: color,
      );

  static TextStyle balanceAmount({Color? color}) => _numeric(
        size: 32,
        weight: FontWeight.w700,
        height: 1.15,
        letterSpacing: -0.8,
        color: color,
      );

  // --------------------------------------------------------------------------
  // TextTheme factory — wired into ThemeData
  // --------------------------------------------------------------------------
  static TextTheme textTheme(bool isDark) {
    final textPrimary = isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    final textSecondary = isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;
    final textMuted = isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted;

    return TextTheme(
      displayLarge: displayLarge(color: textPrimary),
      displayMedium: displayMedium(color: textPrimary),
      displaySmall: displaySmall(color: textPrimary),
      headlineLarge: h1(color: textPrimary),
      headlineMedium: h2(color: textPrimary),
      headlineSmall: h3(color: textPrimary),
      titleLarge: h4(color: textPrimary),
      titleMedium: h5(color: textPrimary),
      titleSmall: labelLarge(color: textPrimary),
      bodyLarge: bodyLarge(color: textPrimary),
      bodyMedium: bodyMedium(color: textSecondary),
      bodySmall: bodySmall(color: textMuted),
      labelLarge: labelLarge(color: textPrimary),
      labelMedium: labelMedium(color: textSecondary),
      labelSmall: labelSmall(color: textMuted),
    );
  }
}
