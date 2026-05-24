import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:balaji_points/core/design/app_colors.dart';

// ---------------------------------------------------------------------------
// Legacy compatibility shim — maps old Nunito AppTextStyles to Plus Jakarta Sans.
// All call sites use .copyWith(fontSize: …) so only fontFamily + weight matter.
// ---------------------------------------------------------------------------

// Re-export AppColors under the old name so call sites that do
//   import 'config/theme.dart' hide AppColors;
// or just use AppColors directly keep working.
// ignore: unused_import
export 'package:balaji_points/core/design/app_colors.dart' show AppColors;

class AppTextStyles {
  AppTextStyles._();

  static TextStyle get nunitoRegular => GoogleFonts.plusJakartaSans(
        fontWeight: FontWeight.w400,
      );

  static TextStyle get nunitoMedium => GoogleFonts.plusJakartaSans(
        fontWeight: FontWeight.w500,
      );

  static TextStyle get nunitoSemiBold => GoogleFonts.plusJakartaSans(
        fontWeight: FontWeight.w600,
      );

  static TextStyle get nunitoBold => GoogleFonts.plusJakartaSans(
        fontWeight: FontWeight.w700,
      );
}

// Legacy ThemeData kept for reference — app.dart now uses AppThemeData from
// lib/core/design/app_theme.dart. This is not wired anywhere but kept so that
// files importing it as a side-effect don't break.
final ThemeData appTheme = ThemeData(
  useMaterial3: true,
  brightness: Brightness.light,
  scaffoldBackgroundColor: AppColors.lightBackground,
  primaryColor: AppColors.lightPrimary,
  colorScheme: const ColorScheme.light(
    primary: AppColors.lightPrimary,
    secondary: AppColors.lightSecondary,
    surface: AppColors.lightBackground,
  ),
);
