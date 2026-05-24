import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'app_colors.dart';
import 'app_typography.dart';
import 'app_spacing.dart';
import 'app_radius.dart';

/// Enterprise design system — ThemeData.
/// Replaces lib/core/theme/app_theme.dart.
/// Light + Dark themes wired to AppColors, AppTypography, AppSpacing, AppRadius.
class AppThemeData {
  AppThemeData._();

  // --------------------------------------------------------------------------
  // Light Theme
  // --------------------------------------------------------------------------
  static ThemeData get light {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,

      scaffoldBackgroundColor: AppColors.lightBackground,
      primaryColor: AppColors.lightPrimary,

      colorScheme: const ColorScheme.light(
        primary: AppColors.lightPrimary,
        secondary: AppColors.lightSecondary,
        surface: AppColors.lightSurface,
        error: AppColors.error,
        onPrimary: AppColors.white,
        onSecondary: AppColors.white,
        onSurface: AppColors.lightTextPrimary,
        onError: AppColors.white,
        outline: AppColors.lightBorder,
      ),

      textTheme: AppTypography.textTheme(false),

      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.lightSurface,
        foregroundColor: AppColors.lightTextPrimary,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        titleTextStyle: AppTypography.h4(color: AppColors.lightTextPrimary),
        iconTheme: const IconThemeData(color: AppColors.lightTextPrimary),
        systemOverlayStyle: SystemUiOverlayStyle.dark,
      ),

      cardTheme: CardThemeData(
        elevation: 0,
        color: AppColors.lightSurface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: AppRadius.forCard,
          side: const BorderSide(color: AppColors.lightBorder, width: 1),
        ),
      ),

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.lightPrimary,
          foregroundColor: AppColors.white,
          elevation: 0,
          minimumSize: const Size(double.infinity, AppSpacing.buttonHeight),
          shape: AppRadius.buttonShape,
          textStyle: AppTypography.buttonLarge(color: AppColors.white),
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.xl,
            vertical: AppSpacing.md,
          ),
        ),
      ),

      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.lightPrimary,
          textStyle: AppTypography.buttonMedium(color: AppColors.lightPrimary),
          shape: AppRadius.buttonShape,
        ),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.lightPrimary,
          minimumSize: const Size(double.infinity, AppSpacing.buttonHeight),
          side: const BorderSide(color: AppColors.lightPrimary, width: 1.5),
          shape: AppRadius.buttonShape,
          textStyle: AppTypography.buttonLarge(color: AppColors.lightPrimary),
        ),
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.lightSoftSurface,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.md,
        ),
        constraints: const BoxConstraints(minHeight: AppSpacing.inputHeight),
        border: OutlineInputBorder(
          borderRadius: AppRadius.forInput,
          borderSide: const BorderSide(color: AppColors.lightBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: AppRadius.forInput,
          borderSide: const BorderSide(color: AppColors.lightBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: AppRadius.forInput,
          borderSide: const BorderSide(color: AppColors.lightPrimary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: AppRadius.forInput,
          borderSide: const BorderSide(color: AppColors.error, width: 1.5),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: AppRadius.forInput,
          borderSide: const BorderSide(color: AppColors.error, width: 2),
        ),
        labelStyle: AppTypography.bodyMedium(color: AppColors.lightTextSecondary),
        hintStyle: AppTypography.bodyMedium(color: AppColors.lightTextMuted),
        errorStyle: AppTypography.bodySmall(color: AppColors.error),
      ),

      chipTheme: ChipThemeData(
        backgroundColor: AppColors.lightSoftSurface,
        selectedColor: AppColors.lightPrimary,
        labelStyle: AppTypography.labelMedium(color: AppColors.lightTextPrimary),
        shape: const StadiumBorder(),
        side: const BorderSide(color: AppColors.lightBorder),
      ),

      dividerTheme: const DividerThemeData(
        color: AppColors.lightBorder,
        thickness: 1,
        space: AppSpacing.xl2,
      ),

      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: AppColors.lightSurface,
        selectedItemColor: AppColors.lightPrimary,
        unselectedItemColor: AppColors.lightTextMuted,
        selectedLabelStyle: AppTypography.labelSmall(),
        unselectedLabelStyle: AppTypography.labelSmall(),
        elevation: 0,
        type: BottomNavigationBarType.fixed,
      ),

      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: AppColors.lightPrimary,
        foregroundColor: AppColors.white,
        elevation: 4,
        shape: CircleBorder(),
      ),

      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppColors.lightTextPrimary,
        contentTextStyle: AppTypography.bodyMedium(color: AppColors.white),
        shape: RoundedRectangleBorder(borderRadius: AppRadius.sm8),
        behavior: SnackBarBehavior.floating,
        elevation: 4,
      ),

      dialogTheme: DialogThemeData(
        backgroundColor: AppColors.lightSurface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: AppRadius.forCard),
        titleTextStyle: AppTypography.h3(color: AppColors.lightTextPrimary),
        contentTextStyle: AppTypography.bodyMedium(color: AppColors.lightTextSecondary),
      ),

      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: AppColors.lightSurface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: AppRadius.topLarge),
        elevation: 0,
      ),

      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.selected) ? AppColors.lightPrimary : AppColors.grey400,
        ),
        trackColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.selected)
              ? AppColors.lightPrimary.withValues(alpha: 0.3)
              : AppColors.lightBorder,
        ),
      ),
    );
  }

  // --------------------------------------------------------------------------
  // Dark Theme
  // --------------------------------------------------------------------------
  static ThemeData get dark {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,

      scaffoldBackgroundColor: AppColors.darkBackground,
      primaryColor: AppColors.darkPrimary,

      colorScheme: const ColorScheme.dark(
        primary: AppColors.darkPrimary,
        secondary: AppColors.darkSecondary,
        surface: AppColors.darkSurface,
        error: AppColors.error,
        onPrimary: AppColors.white,
        onSecondary: AppColors.white,
        onSurface: AppColors.darkTextPrimary,
        onError: AppColors.white,
        outline: AppColors.darkBorder,
      ),

      textTheme: AppTypography.textTheme(true),

      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.darkCard,
        foregroundColor: AppColors.darkTextPrimary,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        titleTextStyle: AppTypography.h4(color: AppColors.darkTextPrimary),
        iconTheme: const IconThemeData(color: AppColors.darkTextPrimary),
        systemOverlayStyle: SystemUiOverlayStyle.light,
      ),

      cardTheme: CardThemeData(
        elevation: 0,
        color: AppColors.darkCard,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: AppRadius.forCard,
          side: const BorderSide(color: AppColors.darkBorder, width: 1),
        ),
      ),

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.darkPrimary,
          foregroundColor: AppColors.white,
          elevation: 0,
          minimumSize: const Size(double.infinity, AppSpacing.buttonHeight),
          shape: AppRadius.buttonShape,
          textStyle: AppTypography.buttonLarge(color: AppColors.white),
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.xl,
            vertical: AppSpacing.md,
          ),
        ),
      ),

      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.darkPrimary,
          textStyle: AppTypography.buttonMedium(color: AppColors.darkPrimary),
          shape: AppRadius.buttonShape,
        ),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.darkPrimary,
          minimumSize: const Size(double.infinity, AppSpacing.buttonHeight),
          side: const BorderSide(color: AppColors.darkPrimary, width: 1.5),
          shape: AppRadius.buttonShape,
          textStyle: AppTypography.buttonLarge(color: AppColors.darkPrimary),
        ),
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.darkSurface,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.md,
        ),
        constraints: const BoxConstraints(minHeight: AppSpacing.inputHeight),
        border: OutlineInputBorder(
          borderRadius: AppRadius.forInput,
          borderSide: const BorderSide(color: AppColors.darkBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: AppRadius.forInput,
          borderSide: const BorderSide(color: AppColors.darkBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: AppRadius.forInput,
          borderSide: const BorderSide(color: AppColors.darkPrimary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: AppRadius.forInput,
          borderSide: const BorderSide(color: AppColors.error, width: 1.5),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: AppRadius.forInput,
          borderSide: const BorderSide(color: AppColors.error, width: 2),
        ),
        labelStyle: AppTypography.bodyMedium(color: AppColors.darkTextSecondary),
        hintStyle: AppTypography.bodyMedium(color: AppColors.darkTextMuted),
        errorStyle: AppTypography.bodySmall(color: AppColors.error),
      ),

      chipTheme: ChipThemeData(
        backgroundColor: AppColors.darkSurface,
        selectedColor: AppColors.darkPrimary,
        labelStyle: AppTypography.labelMedium(color: AppColors.darkTextPrimary),
        shape: const StadiumBorder(),
        side: const BorderSide(color: AppColors.darkBorder),
      ),

      dividerTheme: const DividerThemeData(
        color: AppColors.darkBorder,
        thickness: 1,
        space: AppSpacing.xl2,
      ),

      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: AppColors.darkCard,
        selectedItemColor: AppColors.darkPrimary,
        unselectedItemColor: AppColors.darkTextMuted,
        selectedLabelStyle: AppTypography.labelSmall(),
        unselectedLabelStyle: AppTypography.labelSmall(),
        elevation: 0,
        type: BottomNavigationBarType.fixed,
      ),

      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: AppColors.darkPrimary,
        foregroundColor: AppColors.white,
        elevation: 4,
        shape: CircleBorder(),
      ),

      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppColors.darkSurface,
        contentTextStyle: AppTypography.bodyMedium(color: AppColors.darkTextPrimary),
        shape: RoundedRectangleBorder(borderRadius: AppRadius.sm8),
        behavior: SnackBarBehavior.floating,
        elevation: 4,
      ),

      dialogTheme: DialogThemeData(
        backgroundColor: AppColors.darkCard,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: AppRadius.forCard),
        titleTextStyle: AppTypography.h3(color: AppColors.darkTextPrimary),
        contentTextStyle: AppTypography.bodyMedium(color: AppColors.darkTextSecondary),
      ),

      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: AppColors.darkCard,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: AppRadius.topLarge),
        elevation: 0,
      ),

      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.selected) ? AppColors.darkPrimary : AppColors.grey600,
        ),
        trackColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.selected)
              ? AppColors.darkPrimary.withValues(alpha: 0.3)
              : AppColors.darkBorder,
        ),
      ),
    );
  }
}
