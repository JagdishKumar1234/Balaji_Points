import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'app_colors.dart';
import 'app_typography.dart';
import 'app_spacing.dart';
import 'app_radius.dart';

/// Balaji Points Design System v2.0 — ThemeData.
///
/// Light + Dark themes wired to v2.0 tokens & dynamic Light Material Color Palettes.
class AppThemeData {
  AppThemeData._();

  // ── Light ───────────────────────────────────────────────────────────────────

  static ThemeData light([AppColorPalette palette = AppColorPalette.navy]) {
    final colors = AppPaletteColors.of(palette);
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,

      scaffoldBackgroundColor: AppColors.background,
      primaryColor: colors.primary,

      colorScheme: ColorScheme.light(
        primary: colors.primary,
        secondary: AppColors.gold,
        tertiary: AppColors.action,
        surface: AppColors.surface,
        error: AppColors.error,
        onPrimary: AppColors.white,
        onSecondary: colors.primary, // gold button → primary text
        onSurface: AppColors.textPrimary,
        onError: AppColors.white,
        outline: AppColors.border,
      ),

      canvasColor: AppColors.background,
      cardColor: AppColors.surface,

      textTheme: AppTypography.textTheme(false),

      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.background,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: AppTypography.title(color: AppColors.textPrimary),
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
        actionsIconTheme: const IconThemeData(color: AppColors.textPrimary),
        systemOverlayStyle: SystemUiOverlayStyle.dark,
      ),

      cardTheme: const CardThemeData(
        elevation: 0,
        color: AppColors.surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: AppRadius.all16,
          side: BorderSide(color: AppColors.border, width: 1),
        ),
      ),

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.action,
          foregroundColor: AppColors.white,
          disabledBackgroundColor: AppColors.action.withValues(alpha: 0.45),
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
          foregroundColor: colors.primary,
          textStyle: AppTypography.buttonMedium(color: colors.primary),
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
          foregroundColor: colors.primary,
          minimumSize: Size.zero,
          side: BorderSide(color: colors.primary, width: 1.5),
          shape: AppRadius.buttonShape,
          textStyle: AppTypography.buttonMedium(color: colors.primary),
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
        hintStyle: AppTypography.body(color: AppColors.textMuted),
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
          borderSide: BorderSide(color: colors.primary, width: 2),
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
        backgroundColor: AppColors.softSurface,
        selectedColor: colors.primary,
        labelStyle: AppTypography.caption(color: AppColors.textPrimary),
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
        backgroundColor: AppColors.surface,
        selectedItemColor: colors.primary,
        unselectedItemColor: AppColors.textMuted,
        selectedLabelStyle: AppTypography.caption(),
        unselectedLabelStyle: AppTypography.caption(),
        elevation: 0,
        type: BottomNavigationBarType.fixed,
      ),

      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: colors.primary,
        foregroundColor: AppColors.white,
        elevation: 0,
        shape: const CircleBorder(),
      ),

      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppColors.textPrimary,
        contentTextStyle: AppTypography.body(color: AppColors.white),
        shape: const RoundedRectangleBorder(borderRadius: AppRadius.all16),
        behavior: SnackBarBehavior.floating,
        elevation: 0,
      ),

      dialogTheme: DialogThemeData(
        backgroundColor: AppColors.surface,
        surfaceTintColor: Colors.transparent,
        shape: const RoundedRectangleBorder(borderRadius: AppRadius.all24),
        titleTextStyle: AppTypography.title(color: AppColors.textPrimary),
        contentTextStyle: AppTypography.body(color: AppColors.textSecondary),
        elevation: 0,
      ),

      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: AppColors.surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: AppRadius.topLarge),
        elevation: 0,
      ),

      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.selected)
              ? colors.primary
              : AppColors.textMuted,
        ),
        trackColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.selected)
              ? colors.primary.withValues(alpha: 0.25)
              : AppColors.border,
        ),
      ),

      navigationBarTheme: NavigationBarThemeData(
        height: 72,
        backgroundColor: AppColors.surface,
        indicatorColor: colors.primarySoft,
        elevation: 0,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
      ),

      navigationRailTheme: NavigationRailThemeData(
        backgroundColor: AppColors.navigation,
        indicatorColor: AppColors.primary.withValues(alpha: 0.30),
        selectedIconTheme: const IconThemeData(color: AppColors.white),
        unselectedIconTheme: IconThemeData(
          color: AppColors.white.withValues(alpha: 0.72),
        ),
        selectedLabelTextStyle: AppTypography.labelMedium(
          color: AppColors.white,
        ),
        unselectedLabelTextStyle: AppTypography.labelMedium(
          color: AppColors.white.withValues(alpha: 0.72),
        ),
      ),
    );
  }

  // ── Dark ────────────────────────────────────────────────────────────────────

  static ThemeData dark([AppColorPalette palette = AppColorPalette.navy]) {
    final colors = AppPaletteColors.of(palette);
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,

      scaffoldBackgroundColor: AppColors.darkBackground,
      primaryColor: colors.primary,

      colorScheme: ColorScheme.dark(
        primary: colors.primary,
        secondary: AppColors.gold,
        tertiary: AppColors.action,
        surface: AppColors.darkSurface,
        error: AppColors.error,
        onPrimary: AppColors.white,
        onSecondary: colors.primary,
        onSurface: AppColors.darkTextPrimary,
        onError: AppColors.white,
        outline: AppColors.darkBorder,
      ),

      canvasColor: AppColors.darkBackground,
      cardColor: AppColors.darkSurface,

      textTheme: AppTypography.textTheme(true),

      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.darkBackground,
        foregroundColor: AppColors.darkTextPrimary,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: AppTypography.title(color: AppColors.darkTextPrimary),
        iconTheme: const IconThemeData(color: AppColors.darkTextPrimary),
        actionsIconTheme: const IconThemeData(color: AppColors.darkTextPrimary),
        systemOverlayStyle: SystemUiOverlayStyle.light,
      ),

      cardTheme: const CardThemeData(
        elevation: 0,
        color: AppColors.darkSurface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: AppRadius.all16,
          side: BorderSide(color: AppColors.darkBorder, width: 1),
        ),
      ),

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.action,
          foregroundColor: AppColors.white,
          disabledBackgroundColor: AppColors.action.withValues(alpha: 0.45),
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
          textStyle: AppTypography.buttonMedium(
            color: AppColors.darkTextPrimary,
          ),
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
          textStyle: AppTypography.buttonMedium(
            color: AppColors.darkTextPrimary,
          ),
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
        hintStyle: AppTypography.body(color: AppColors.darkTextMuted),
        errorStyle: AppTypography.caption(color: AppColors.error),
        border: OutlineInputBorder(
          borderRadius: AppRadius.all16,
          borderSide: const BorderSide(color: AppColors.darkBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: AppRadius.all16,
          borderSide: const BorderSide(color: AppColors.darkBorder),
        ),
        focusedBorder: OutlineInputBorder(
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
        backgroundColor: AppColors.darkSoftSurface,
        selectedColor: AppColors.gold,
        labelStyle: AppTypography.caption(color: AppColors.darkTextPrimary),
        secondaryLabelStyle: AppTypography.caption(color: colors.primary),
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
        backgroundColor: AppColors.darkSurface,
        selectedItemColor: AppColors.gold,
        unselectedItemColor: AppColors.darkTextMuted,
        selectedLabelStyle: AppTypography.caption(),
        unselectedLabelStyle: AppTypography.caption(),
        elevation: 0,
        type: BottomNavigationBarType.fixed,
      ),

      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: colors.primary,
        foregroundColor: AppColors.white,
        elevation: 0,
        shape: const CircleBorder(),
      ),

      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppColors.darkSurface,
        contentTextStyle: AppTypography.body(color: AppColors.darkTextPrimary),
        shape: const RoundedRectangleBorder(borderRadius: AppRadius.all16),
        behavior: SnackBarBehavior.floating,
        elevation: 0,
      ),

      dialogTheme: DialogThemeData(
        backgroundColor: AppColors.darkSurface,
        surfaceTintColor: Colors.transparent,
        shape: const RoundedRectangleBorder(borderRadius: AppRadius.all24),
        titleTextStyle: AppTypography.title(color: AppColors.darkTextPrimary),
        contentTextStyle: AppTypography.body(
          color: AppColors.darkTextSecondary,
        ),
        elevation: 0,
      ),

      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: AppColors.darkSurface,
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

      navigationBarTheme: NavigationBarThemeData(
        height: 72,
        backgroundColor: AppColors.darkSurface,
        indicatorColor: AppColors.gold.withValues(alpha: 0.18),
        elevation: 0,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
      ),

      navigationRailTheme: NavigationRailThemeData(
        backgroundColor: AppColors.navigation,
        indicatorColor: AppColors.gold.withValues(alpha: 0.20),
        selectedIconTheme: const IconThemeData(color: AppColors.white),
        unselectedIconTheme: IconThemeData(
          color: AppColors.white.withValues(alpha: 0.72),
        ),
        selectedLabelTextStyle: AppTypography.labelMedium(
          color: AppColors.white,
        ),
        unselectedLabelTextStyle: AppTypography.labelMedium(
          color: AppColors.white.withValues(alpha: 0.72),
        ),
      ),
    );
  }
}
