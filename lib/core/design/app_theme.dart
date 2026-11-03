import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'app_colors.dart';
import 'app_typography.dart';
import 'app_spacing.dart';
import 'app_radius.dart';

/// Balaji Points Design System v3 — ThemeData.
///
/// Built from `docs/Carpenter Rewards App – UI Design.html`.
/// Colour roles:
///   • Navy   — chrome (headers, sidebar), headings, brand surfaces
///   • Gold   — the one main action per screen (filled buttons, FAB)
///   • Neutral — everything else (white cards, grey borders, ink text)
///   • Status — tinted chip pairs only (success / pending / error)
///
/// Light and dark share one builder so they can never drift apart.
class AppThemeData {
  AppThemeData._();

  static ThemeData light() => _build(Brightness.light);
  static ThemeData dark() => _build(Brightness.dark);

  static ThemeData _build(Brightness brightness) {
    final dark = brightness == Brightness.dark;

    // ── Resolved tokens ──────────────────────────────────────────────────────
    final primary = dark ? AppColors.primaryOnDark : AppColors.primary;
    final background = dark ? AppColors.darkBackground : AppColors.background;
    final surface = dark ? AppColors.darkSurface : AppColors.surface;
    final chrome = dark ? AppColors.darkChrome : AppColors.surface;
    final soft = dark ? AppColors.darkSoftSurface : AppColors.softSurface;
    final border = dark ? AppColors.darkBorder : AppColors.border;
    final borderStrong = dark ? AppColors.darkBorder : AppColors.borderStrong;
    final textPrimary = dark
        ? AppColors.darkTextPrimary
        : AppColors.textPrimary;
    final textSecondary = dark
        ? AppColors.darkTextSecondary
        : AppColors.textSecondary;
    final textMuted = dark ? AppColors.darkTextMuted : AppColors.textMuted;
    // Error must stay readable as text on dark surfaces.
    final error = dark ? AppColors.darkErrorText : AppColors.error;
    final onError = dark ? AppColors.darkErrorSoft : AppColors.white;
    // Active nav / selection ink: navy on light, light ink on dark (spec).
    final activeInk = dark ? AppColors.darkTextPrimary : AppColors.primary;
    final activePill = dark ? AppColors.darkPendingSoft : AppColors.goldSoft;

    final scheme = ColorScheme(
      brightness: brightness,
      primary: primary,
      onPrimary: AppColors.white,
      primaryContainer: AppColors.primary,
      onPrimaryContainer: AppColors.white,
      secondary: AppColors.gold,
      onSecondary: AppColors.primary,
      secondaryContainer: activePill,
      onSecondaryContainer: dark
          ? AppColors.darkPendingText
          : AppColors.pendingText,
      tertiary: AppColors.gold,
      onTertiary: AppColors.primary,
      error: error,
      onError: onError,
      errorContainer: dark ? AppColors.darkErrorSoft : AppColors.errorSoft,
      onErrorContainer: dark ? AppColors.darkErrorText : AppColors.errorText,
      surface: surface,
      onSurface: textPrimary,
      onSurfaceVariant: textSecondary,
      surfaceContainerLowest: surface,
      surfaceContainerLow: surface,
      surfaceContainer: soft,
      surfaceContainerHigh: soft,
      surfaceContainerHighest: soft,
      outline: borderStrong,
      outlineVariant: border,
      shadow: AppColors.primary,
      scrim: AppColors.black,
      inverseSurface: dark ? AppColors.darkTextPrimary : AppColors.textPrimary,
      onInverseSurface: dark ? AppColors.darkBackground : AppColors.white,
      inversePrimary: dark ? AppColors.primary : AppColors.primaryOnDark,
      surfaceTint: Colors.transparent,
    );

    // ── Shared shapes / sizes ────────────────────────────────────────────────
    const pill = StadiumBorder();
    const minTap = Size(48, AppSpacing.buttonHeight);
    const btnPadding = EdgeInsets.symmetric(horizontal: 18);
    final btnText = AppTypography.button();

    OutlineInputBorder inputBorder(Color c, [double w = 1]) =>
        OutlineInputBorder(
          borderRadius: AppRadius.md12,
          borderSide: BorderSide(color: c, width: w),
        );

    final disabledBg = soft;
    final disabledFg = textMuted;

    final filledStyle = ButtonStyle(
      backgroundColor: WidgetStateProperty.resolveWith(
        (s) => s.contains(WidgetState.disabled) ? disabledBg : AppColors.gold,
      ),
      foregroundColor: WidgetStateProperty.resolveWith(
        (s) =>
            s.contains(WidgetState.disabled) ? disabledFg : AppColors.primary,
      ),
      overlayColor: WidgetStatePropertyAll(
        AppColors.primary.withValues(alpha: 0.08),
      ),
      elevation: const WidgetStatePropertyAll(0),
      shadowColor: const WidgetStatePropertyAll(Colors.transparent),
      minimumSize: const WidgetStatePropertyAll(minTap),
      padding: const WidgetStatePropertyAll(btnPadding),
      shape: const WidgetStatePropertyAll(pill),
      textStyle: WidgetStatePropertyAll(btnText),
    );

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: scheme,
      primaryColor: primary,
      scaffoldBackgroundColor: background,
      canvasColor: background,
      cardColor: surface,
      dividerColor: border,
      fontFamily: AppTypography.fontFamily,
      textTheme: AppTypography.textTheme(dark),
      visualDensity: VisualDensity.standard,
      materialTapTargetSize: MaterialTapTargetSize.padded,

      appBarTheme: AppBarTheme(
        backgroundColor: chrome,
        foregroundColor: textPrimary,
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
        centerTitle: false,
        shape: Border(bottom: BorderSide(color: border)),
        titleTextStyle: AppTypography.title(color: textPrimary),
        iconTheme: IconThemeData(color: textPrimary),
        actionsIconTheme: IconThemeData(color: textPrimary),
        systemOverlayStyle: dark
            ? SystemUiOverlayStyle.light
            : SystemUiOverlayStyle.dark,
      ),

      cardTheme: CardThemeData(
        elevation: 0,
        margin: EdgeInsets.zero,
        color: surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: AppRadius.all16,
          side: BorderSide(color: border),
        ),
      ),

      // Main action — gold pill, navy label (spec `.btn.gold`).
      elevatedButtonTheme: ElevatedButtonThemeData(style: filledStyle),
      filledButtonTheme: FilledButtonThemeData(style: filledStyle),

      // Secondary — surface pill, grey outline, brand ink (spec `.btn.out`).
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          backgroundColor: surface,
          foregroundColor: activeInk,
          disabledForegroundColor: disabledFg,
          minimumSize: minTap,
          padding: btnPadding,
          side: BorderSide(color: borderStrong),
          shape: pill,
          textStyle: btnText,
        ),
      ),

      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: activeInk,
          disabledForegroundColor: disabledFg,
          minimumSize: const Size(48, 48),
          padding: const EdgeInsets.symmetric(horizontal: 12),
          shape: pill,
          textStyle: AppTypography.buttonMedium(),
        ),
      ),

      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(
          minimumSize: const Size(48, 48),
          foregroundColor: textPrimary,
        ),
      ),

      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: AppColors.gold,
        foregroundColor: AppColors.primary,
        elevation: 0,
        focusElevation: 0,
        hoverElevation: 0,
        highlightElevation: 0,
        shape: CircleBorder(),
      ),

      // Inputs — 48 high, radius 12, strong grey border, label above (spec).
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: dark ? soft : AppColors.surface,
        isDense: false,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 14,
        ),
        constraints: const BoxConstraints(minHeight: AppSpacing.inputHeight),
        floatingLabelBehavior: FloatingLabelBehavior.always,
        // M3 draws floating labels at 75 % — 16 px renders as 12 px, the
        // smallest size allowed in the app (13 px was rendering at ~10 px).
        labelStyle: AppTypography.label(
          color: textSecondary,
        ).copyWith(fontSize: 16),
        floatingLabelStyle: AppTypography.label(
          color: textSecondary,
        ).copyWith(fontSize: 16),
        hintStyle: AppTypography.input(color: textMuted),
        helperStyle: AppTypography.caption(color: textSecondary),
        errorStyle: AppTypography.caption(color: error),
        prefixIconColor: textSecondary,
        suffixIconColor: textSecondary,
        border: inputBorder(borderStrong),
        enabledBorder: inputBorder(borderStrong),
        focusedBorder: inputBorder(activeInk, 2),
        errorBorder: inputBorder(error, 1.5),
        focusedErrorBorder: inputBorder(error, 2),
        disabledBorder: inputBorder(border),
      ),

      // Chips — radius 8, neutral by default; selected = navy (spec "All").
      chipTheme: ChipThemeData(
        backgroundColor: surface,
        selectedColor: AppColors.primary,
        disabledColor: soft,
        checkmarkColor: AppColors.white,
        labelStyle: AppTypography.label(color: textPrimary),
        secondaryLabelStyle: AppTypography.label(color: AppColors.white),
        shape: RoundedRectangleBorder(
          borderRadius: AppRadius.sm8,
          side: BorderSide(color: borderStrong),
        ),
        side: BorderSide(color: borderStrong),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        showCheckmark: false,
      ),

      dividerTheme: DividerThemeData(color: border, thickness: 1, space: 1),

      // Search fields look like inputs: flat, 1 px border, radius 12, 48 high.
      searchBarTheme: SearchBarThemeData(
        elevation: const WidgetStatePropertyAll(0),
        backgroundColor: WidgetStatePropertyAll(
          dark ? soft : AppColors.surface,
        ),
        surfaceTintColor: const WidgetStatePropertyAll(Colors.transparent),
        overlayColor: const WidgetStatePropertyAll(Colors.transparent),
        side: WidgetStateProperty.resolveWith(
          (s) => BorderSide(
            color: s.contains(WidgetState.focused) ? activeInk : borderStrong,
            width: s.contains(WidgetState.focused) ? 2 : 1,
          ),
        ),
        shape: const WidgetStatePropertyAll(
          RoundedRectangleBorder(borderRadius: AppRadius.md12),
        ),
        constraints: const BoxConstraints(minHeight: 52, maxHeight: 52),
        padding: const WidgetStatePropertyAll(
          EdgeInsets.symmetric(horizontal: 12),
        ),
        textStyle: WidgetStatePropertyAll(
          AppTypography.input(color: textPrimary).copyWith(height: 1.2),
        ),
        hintStyle: WidgetStatePropertyAll(
          AppTypography.input(color: textMuted).copyWith(height: 1.2),
        ),
      ),

      listTileTheme: ListTileThemeData(
        iconColor: textSecondary,
        textColor: textPrimary,
        minVerticalPadding: 12,
        titleTextStyle: AppTypography.input(
          color: textPrimary,
        ).copyWith(fontWeight: FontWeight.w600),
        subtitleTextStyle: AppTypography.caption(color: textSecondary),
      ),

      // Bottom nav — 68 high, neutral, active = navy ink on gold-soft pill.
      navigationBarTheme: NavigationBarThemeData(
        height: AppSpacing.bottomNavHeight,
        backgroundColor: chrome,
        surfaceTintColor: Colors.transparent,
        indicatorColor: activePill,
        elevation: 0,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        iconTheme: WidgetStateProperty.resolveWith(
          (s) => IconThemeData(
            color: s.contains(WidgetState.selected) ? activeInk : textSecondary,
          ),
        ),
        labelTextStyle: WidgetStateProperty.resolveWith(
          (s) => AppTypography.navLabel(
            color: s.contains(WidgetState.selected) ? activeInk : textSecondary,
          ),
        ),
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: chrome,
        selectedItemColor: activeInk,
        unselectedItemColor: textSecondary,
        selectedLabelStyle: AppTypography.navLabel(),
        unselectedLabelStyle: AppTypography.navLabel(),
        elevation: 0,
        type: BottomNavigationBarType.fixed,
      ),

      // Desktop rail — navy in both themes, gold accent (spec sidebar).
      navigationRailTheme: NavigationRailThemeData(
        backgroundColor: AppColors.navigation,
        indicatorColor: AppColors.primaryLight,
        selectedIconTheme: const IconThemeData(color: AppColors.gold),
        unselectedIconTheme: const IconThemeData(
          color: AppColors.onPrimaryMuted,
        ),
        selectedLabelTextStyle: AppTypography.input(
          color: AppColors.white,
        ).copyWith(fontSize: 14),
        unselectedLabelTextStyle: AppTypography.input(
          color: AppColors.onPrimaryMuted,
        ).copyWith(fontSize: 15, fontWeight: FontWeight.w600),
        indicatorShape: const RoundedRectangleBorder(
          borderRadius: AppRadius.md12,
        ),
      ),

      tabBarTheme: TabBarThemeData(
        labelColor: activeInk,
        unselectedLabelColor: textSecondary,
        indicatorColor: AppColors.gold,
        dividerColor: border,
        labelStyle: AppTypography.label(),
        unselectedLabelStyle: AppTypography.label(),
      ),

      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.selected)
              ? AppColors.white
              : textSecondary,
        ),
        trackColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.selected) ? primary : soft,
        ),
        trackOutlineColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.selected)
              ? Colors.transparent
              : borderStrong,
        ),
      ),

      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith(
          (s) =>
              s.contains(WidgetState.selected) ? primary : Colors.transparent,
        ),
        checkColor: const WidgetStatePropertyAll(AppColors.white),
        side: BorderSide(color: borderStrong, width: 1.5),
        shape: const RoundedRectangleBorder(borderRadius: AppRadius.xs4),
      ),

      radioTheme: RadioThemeData(
        fillColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.selected) ? primary : borderStrong,
        ),
      ),

      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: dark ? AppColors.gold : AppColors.primary,
        linearTrackColor: soft,
        circularTrackColor: Colors.transparent,
      ),

      snackBarTheme: SnackBarThemeData(
        backgroundColor: dark
            ? AppColors.darkSoftSurface
            : AppColors.textPrimary,
        contentTextStyle: AppTypography.body(
          color: dark ? AppColors.darkTextPrimary : AppColors.white,
        ),
        actionTextColor: AppColors.gold,
        shape: const RoundedRectangleBorder(borderRadius: AppRadius.md12),
        behavior: SnackBarBehavior.floating,
        elevation: 0,
      ),

      dialogTheme: DialogThemeData(
        backgroundColor: surface,
        surfaceTintColor: Colors.transparent,
        shape: const RoundedRectangleBorder(borderRadius: AppRadius.all24),
        titleTextStyle: AppTypography.title(color: textPrimary),
        contentTextStyle: AppTypography.body(color: textSecondary),
        insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
        elevation: 0,
      ),

      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: surface,
        surfaceTintColor: Colors.transparent,
        shape: const RoundedRectangleBorder(borderRadius: AppRadius.topLarge),
        showDragHandle: true,
        dragHandleColor: borderStrong,
        elevation: 0,
      ),

      popupMenuTheme: PopupMenuThemeData(
        color: surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: AppRadius.md12,
          side: BorderSide(color: border),
        ),
        textStyle: AppTypography.body(color: textPrimary),
        elevation: 2,
      ),

      dataTableTheme: DataTableThemeData(
        headingTextStyle: AppTypography.label(color: textSecondary),
        dataTextStyle: AppTypography.body(color: textPrimary),
        dividerThickness: 1,
        headingRowHeight: 40,
        dataRowMinHeight: 48,
        horizontalMargin: 12,
        columnSpacing: 16,
      ),

      tooltipTheme: TooltipThemeData(
        decoration: BoxDecoration(
          color: dark ? AppColors.darkSoftSurface : AppColors.textPrimary,
          borderRadius: AppRadius.sm8,
        ),
        textStyle: AppTypography.caption(
          color: dark ? AppColors.darkTextPrimary : AppColors.white,
        ),
      ),
    );
  }
}
