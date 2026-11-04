import 'package:flutter/material.dart';
import 'package:balaji_points/core/design/app_colors.dart';
import 'package:balaji_points/core/design/app_spacing.dart';
import 'package:balaji_points/core/design/app_typography.dart';
import 'app_loader.dart';

/// Balaji Points Design System v3 — Button (UI spec).
///
/// All variants are 48 px pills with a 15/600 label.
///   primary   — gold fill, navy label. The ONE main action on a screen.
///   gold      — alias of primary.
///   secondary — surface fill, 1 px grey outline, brand ink label.
///   outline   — alias of secondary.
///   danger    — surface fill, red outline + red label (destructive).
///   strong    — solid navy (white in dark mode). A second action that has to
///               stand out next to the gold one.
enum AppButtonVariant { primary, secondary, outline, gold, danger, strong }

class AppButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final AppButtonVariant variant;
  final bool isLoading;
  final bool fullWidth;
  final double? width;
  final IconData? icon;
  final double verticalPadding;

  const AppButton({
    super.key,
    required this.label,
    this.onPressed,
    this.variant = AppButtonVariant.primary,
    this.isLoading = false,
    this.fullWidth = true,
    this.width,
    this.icon,
    this.verticalPadding = 14,
  });

  const AppButton.primary({
    super.key,
    required this.label,
    this.onPressed,
    this.isLoading = false,
    this.fullWidth = true,
    this.width,
    this.icon,
    this.verticalPadding = 14,
  }) : variant = AppButtonVariant.primary;

  const AppButton.secondary({
    super.key,
    required this.label,
    this.onPressed,
    this.isLoading = false,
    this.fullWidth = true,
    this.width,
    this.icon,
    this.verticalPadding = 14,
  }) : variant = AppButtonVariant.secondary;

  const AppButton.outline({
    super.key,
    required this.label,
    this.onPressed,
    this.isLoading = false,
    this.fullWidth = true,
    this.width,
    this.icon,
    this.verticalPadding = 14,
  }) : variant = AppButtonVariant.outline;

  const AppButton.gold({
    super.key,
    required this.label,
    this.onPressed,
    this.isLoading = false,
    this.fullWidth = true,
    this.width,
    this.icon,
    this.verticalPadding = 14,
  }) : variant = AppButtonVariant.gold;

  const AppButton.danger({
    super.key,
    required this.label,
    this.onPressed,
    this.isLoading = false,
    this.fullWidth = true,
    this.width,
    this.icon,
    this.verticalPadding = 14,
  }) : variant = AppButtonVariant.danger;

  const AppButton.strong({
    super.key,
    required this.label,
    this.onPressed,
    this.isLoading = false,
    this.fullWidth = true,
    this.width,
    this.icon,
    this.verticalPadding = 14,
  }) : variant = AppButtonVariant.strong;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final disabled = isLoading || onPressed == null;

    final bg = _bg(context, isDark, disabled);
    final fg = _fg(context, isDark, disabled);
    final border = _border(context, isDark, disabled);

    final Widget child = isLoading
        ? AppLoader(size: 20, strokeWidth: 2, color: fg)
        : Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (icon != null) ...[
                Icon(icon, size: 18, color: fg),
                const SizedBox(width: AppSpacing.sm),
              ],
              Flexible(
                child: Text(
                  label,
                  style: AppTypography.button(color: fg),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          );

    const minHeight = AppSpacing.buttonHeight; // 48 — spec + touch target

    final button = ElevatedButton(
      onPressed: disabled ? null : onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: bg,
        foregroundColor: fg,
        disabledBackgroundColor: bg,
        disabledForegroundColor: fg,
        shadowColor: Colors.transparent,
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 18),
        minimumSize: Size(width ?? 0, minHeight),
        shape: StadiumBorder(side: border),
      ),
      child: child,
    );

    if (fullWidth) {
      return SizedBox(width: double.infinity, height: minHeight, child: button);
    }

    if (width != null) {
      return SizedBox(width: width, height: minHeight, child: button);
    }

    return button;
  }

  Color _bg(BuildContext context, bool isDark, bool disabled) {
    if (disabled) return context.themeSoftSurface;
    switch (variant) {
      case AppButtonVariant.primary:
      case AppButtonVariant.gold:
        return AppColors.gold;
      case AppButtonVariant.strong:
        return isDark ? AppColors.white : AppColors.primary;
      case AppButtonVariant.secondary:
      case AppButtonVariant.outline:
      case AppButtonVariant.danger:
        return context.themeSurface;
    }
  }

  Color _fg(BuildContext context, bool isDark, bool disabled) {
    if (disabled) return context.themeTextMuted;
    switch (variant) {
      case AppButtonVariant.primary:
      case AppButtonVariant.gold:
        return AppColors.primary;
      case AppButtonVariant.strong:
        return isDark ? AppColors.primary : AppColors.white;
      case AppButtonVariant.secondary:
      case AppButtonVariant.outline:
        return context.themeContentColor;
      case AppButtonVariant.danger:
        return context.themeError;
    }
  }

  BorderSide _border(BuildContext context, bool isDark, bool disabled) {
    switch (variant) {
      case AppButtonVariant.secondary:
      case AppButtonVariant.outline:
        return BorderSide(
          color: disabled ? context.themeBorder : context.themeBorderStrong,
        );
      case AppButtonVariant.danger:
        return BorderSide(
          color: disabled ? context.themeBorder : context.themeError,
        );
      default:
        return BorderSide.none;
    }
  }
}
