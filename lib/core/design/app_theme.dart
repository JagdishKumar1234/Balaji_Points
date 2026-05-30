import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'app_colors.dart';
import 'app_typography.dart';
import 'app_spacing.dart';
import 'app_radius.dart';

/// Balaji Points Design System v2.0 — ThemeData.
///
/// Light + Dark themes wired to v2.0 tokens.
/// Single shadow level (opacity 0.05), universal radius 16.
class AppThemeData {
  AppThemeData._();

  // ── Light ───────────────────────────────────────────────────────────────────

  static ThemeData get light {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,

      scaffoldBackgroundColor: AppColors.background,
      primaryColor: AppColors.primary,

      colorScheme: const ColorScheme.light(
        primary:   AppColors.primary,
        secondary: AppColors.gold,
        surface:   AppColors.surface,
        error:     AppColors.error,
        onPrimary:   AppColors.white,
        onSecondary: AppColors.primary,   // gold button → navy text
        onSurface:   AppColors.textPrimary,
        onError:     AppColors.white,
        outline:     AppColors.border,
      ),

      canvasColor: AppColors.background,
      cardColor:   AppColors.surface,

      textTheme: AppTypography.textTheme(false),

      appBarTheme: AppBarTheme(
        backgroundColor:    AppColors.background,
        foregroundColor:    AppColors.textPrimary,
        elevation:          0,
        scrolledUnderElevation: 0,
        centerTitle:        false,
        titleTextStyle:     AppTypography.title(color: AppColors.textPrimary),
        iconTheme:          const IconThemeData(color: AppColors.textPrimary),
        actionsIconTheme:   const IconThemeData(color: AppColors.textPrimary),
        systemOverlayStyle: SystemUiOverlayStyle.dark,
      ),

      cardTheme: CardThemeData(
        elevation: 0,
        color: AppColors.surface,
        surfaceTintColor: Colors.transparent,
        shape: const RoundedRectangleBorder(
          borderRadius: AppRadius.all16,
          side: BorderSide(color: AppColors.border, width: 1),
        ),
        // Level 1 shadow applied via AppColors.shadowLevel1 where needed
      ),

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.white,
          disabledBackgroundColor: AppColors.primary.withValues(alpha: 0.45),
          disabledForegroundColor: AppColors.white.withValues(alpha: 0.65),
          elevation: 0,
          shadowColor: Colors.transparent,
          minimumSize: Size.zero,           // prevents infinite-width in Row
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.md,
          ),
          shape: AppRadius.buttonShape,
          textStyle: AppTypography.buttonMedium(color: AppColors.white),
        ),
      ),

      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.primary,
          textStyle: AppTypography.buttonMedium(color: AppColors.primary),
          shape: AppRadius.buttonShape,
          minimumSize: Size.zero,
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.sm,
          ),
        ),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primary,
          minimumSize: Size.zero,
          side: const BorderSide(color: AppColors.primary, width: 1.5),
          shape: AppRadius.buttonShape,
          textStyle: AppTypography.buttonMedium(color: AppColors.primary),
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.md,
          ),
        ),
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surface,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.md,
        ),
        constraints: const BoxConstraints(minHeight: AppSpacing.inputHeight),
        labelStyle: AppTypography.body(color: AppColors.textSecondary),
        hintStyle:  AppTypography.body(color: AppColors.textMuted),
        errorStyle: AppTypography.caption(color: AppColors.error),
        border: OutlineInputBorder(
          borderRadius: AppRadius.all16,
          borderSide: const BorderSide(color: AppColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: AppRadius.all16,
          borderSide: const BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: AppRadius.all16,
          borderSide: const BorderSide(color: AppColors.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: AppRadius.all16,
          borderSide: const BorderSide(color: AppColors.error, width: 1.5),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: AppRadius.all16,
          borderSide: const BorderSide(color: AppColors.error, width: 2),
        ),
        disabledBorder: OutlineInputBorder(
          borderRadius: AppRadius.all16,
          borderSide: BorderSide(
            color: AppColors.border.withValues(alpha: 0.5),
          ),
        ),
      ),

      chipTheme: ChipThemeData(
        backgroundColor:  AppColors.softSurface,
        selectedColor:    AppColors.primary,
        labelStyle:       AppTypography.caption(color: AppColors.textPrimary),
        secondaryLabelStyle: AppTypography.caption(color: AppColors.white),
        shape: const StadiumBorder(),
        side: const BorderSide(color: AppColors.border),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      ),

      dividerTheme: const DividerThemeData(
        color: AppColors.border,
        thickness: 1,
        space: AppSpacing.xl2,
      ),

      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor:    AppColors.surface,
        selectedItemColor:  AppColors.primary,
        unselectedItemColor: AppColors.textMuted,
        selectedLabelStyle:   AppTypography.caption(),
        unselectedLabelStyle: AppTypography.caption(),
        elevation: 0,
        type: BottomNavigationBarType.fixed,
      ),

      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.white,
        elevation: 0,
        shape: CircleBorder(),
      ),

      snackBarTheme: SnackBarThemeData(
        backgroundColor:  AppColors.textPrimary,
        contentTextStyle: AppTypography.body(color: AppColors.white),
        shape: const RoundedRectangleBorder(borderRadius: AppRadius.all16),
        behavior: SnackBarBehavior.floating,
        elevation: 0,
      ),

      dialogTheme: DialogThemeData(
        backgroundColor:    AppColors.surface,
        surfaceTintColor:   Colors.transparent,
        shape: const RoundedRectangleBorder(borderRadius: AppRadius.all24),
        titleTextStyle:   AppTypography.title(color: AppColors.textPrimary),
        contentTextStyle: AppTypography.body(color: AppColors.textSecondary),
        elevation: 0,
      ),

      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor:  AppColors.surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: AppRadius.topLarge),
        elevation: 0,
      ),

      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.selected)
              ? AppColors.primary
              : AppColors.textMuted,
        ),
        trackColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.selected)
              ? AppColors.primary.withValues(alpha: 0.25)
              : AppColors.border,
        ),
      ),
    );
  }

  // ── Dark ────────────────────────────────────────────────────────────────────

  static ThemeData get dark {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,

      scaffoldBackgroundColor: AppColors.darkBackground,
      primaryColor: AppColors.primary,

      colorScheme: const ColorScheme.dark(
        primary:   AppColors.primary,
        secondary: AppColors.gold,
        surface:   AppColors.darkSurface,
        error:     AppColors.error,
        onPrimary:   AppColors.white,
        onSecondary: AppColors.primary,
        onSurface:   AppColors.darkTextPrimary,
        onError:     AppColors.white,
        outline:     AppColors.darkBorder,
      ),

      canvasColor: AppColors.darkBackground,
      cardColor:   AppColors.darkSurface,

      textTheme: AppTypography.textTheme(true),

      appBarTheme: AppBarTheme(
        backgroundColor:    AppColors.darkBackground,
        foregroundColor:    AppColors.darkTextPrimary,
        elevation:          0,
        scrolledUnderElevation: 0,
        centerTitle:        false,
        titleTextStyle:     AppTypography.title(color: AppColors.darkTextPrimary),
        iconTheme:          const IconThemeData(color: AppColors.darkTextPrimary),
        actionsIconTheme:   const IconThemeData(color: AppColors.darkTextPrimary),
        systemOverlayStyle: SystemUiOverlayStyle.light,
      ),

      cardTheme: CardThemeData(
        elevation: 0,
        color: AppColors.darkSurface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: AppRadius.all16,
          side: const BorderSide(color: AppColors.darkBorder, width: 1),
        ),
      ),

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.white,
          disabledBackgroundColor: AppColors.primary.withValues(alpha: 0.45),
          disabledForegroundColor: AppColors.white.withValues(alpha: 0.65),
          elevation: 0,
          shadowColor: Colors.transparent,
          minimumSize: Size.zero,
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.md,
          ),
          shape: AppRadius.buttonShape,
          textStyle: AppTypography.buttonMedium(color: AppColors.white),
        ),
      ),

      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.darkTextPrimary,
          textStyle: AppTypography.buttonMedium(color: AppColors.darkTextPrimary),
          shape: AppRadius.buttonShape,
          minimumSize: Size.zero,
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.sm,
          ),
        ),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.darkTextPrimary,
          minimumSize: Size.zero,
          side: const BorderSide(color: AppColors.darkBorder, width: 1.5),
          shape: AppRadius.buttonShape,
          textStyle: AppTypography.buttonMedium(color: AppColors.darkTextPrimary),
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.md,
          ),
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
        labelStyle: AppTypography.body(color: AppColors.darkTextSecondary),
        hintStyle:  AppTypography.body(color: AppColors.darkTextMuted),
        errorStyle: AppTypography.caption(color: AppColors.error),
        border: OutlineInputBorder(
          borderRadius: AppRadius.all16,
          borderSide: const BorderSide(color: AppColors.darkBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: AppRadius.all16,
          borderSide: const BorderSide(color: AppColors.darkBorder),
        ),
        focusedBorder: OutlineInputBorder(  // gold focus ring in dark mode
          borderRadius: AppRadius.all16,
          borderSide: const BorderSide(color: AppColors.gold, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: AppRadius.all16,
          borderSide: const BorderSide(color: AppColors.error, width: 1.5),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: AppRadius.all16,
          borderSide: const BorderSide(color: AppColors.error, width: 2),
        ),
        disabledBorder: OutlineInputBorder(
          borderRadius: AppRadius.all16,
          borderSide: BorderSide(
            color: AppColors.darkBorder.withValues(alpha: 0.4),
          ),
        ),
      ),

      chipTheme: ChipThemeData(
        backgroundColor:  AppColors.darkSoftSurface,
        selectedColor:    AppColors.gold,
        labelStyle:       AppTypography.caption(color: AppColors.darkTextPrimary),
        secondaryLabelStyle: AppTypography.caption(color: AppColors.primary),
        shape: const StadiumBorder(),
        side: const BorderSide(color: AppColors.darkBorder),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      ),

      dividerTheme: const DividerThemeData(
        color: AppColors.darkBorder,
        thickness: 1,
        space: AppSpacing.xl2,
      ),

      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor:     AppColors.darkSurface,
        selectedItemColor:   AppColors.gold,         // gold active in dark
        unselectedItemColor: AppColors.darkTextMuted,
        selectedLabelStyle:   AppTypography.caption(),
        unselectedLabelStyle: AppTypography.caption(),
        elevation: 0,
        type: BottomNavigationBarType.fixed,
      ),

      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.white,
        elevation: 0,
        shape: CircleBorder(),
      ),

      snackBarTheme: SnackBarThemeData(
        backgroundColor:  AppColors.darkSurface,
        contentTextStyle: AppTypography.body(color: AppColors.darkTextPrimary),
        shape: const RoundedRectangleBorder(borderRadius: AppRadius.all16),
        behavior: SnackBarBehavior.floating,
        elevation: 0,
      ),

      dialogTheme: DialogThemeData(
        backgroundColor:    AppColors.darkSurface,
        surfaceTintColor:   Colors.transparent,
        shape: const RoundedRectangleBorder(borderRadius: AppRadius.all24),
        titleTextStyle:   AppTypography.title(color: AppColors.darkTextPrimary),
        contentTextStyle: AppTypography.body(color: AppColors.darkTextSecondary),
        elevation: 0,
      ),

      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor:  AppColors.darkSurface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: AppRadius.topLarge),
        elevation: 0,
      ),

      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.selected)
              ? AppColors.gold
              : AppColors.darkTextMuted,
        ),
        trackColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.selected)
              ? AppColors.gold.withValues(alpha: 0.30)
              : AppColors.darkBorder,
        ),
      ),
    );
  }
}
