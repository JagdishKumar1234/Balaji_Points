import 'package:flutter/material.dart';
import 'package:balaji_points/core/design/app_colors.dart';
import 'package:balaji_points/core/design/app_radius.dart';
import 'package:balaji_points/core/design/app_spacing.dart';
import 'package:balaji_points/core/design/app_typography.dart';
import 'app_loader.dart';

/// Balaji Points Design System v2.0 — Button.
///
/// Variants:
///   primary  — navy bg, white text   (default)
///   secondary — transparent, navy border + text
///   gold     — gold bg, navy text    (redeem / claim only)
///   danger   — red bg, white text
///   outline  — alias for secondary
enum AppButtonVariant { primary, secondary, outline, gold, danger }

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

  @override
  Widget build(BuildContext context) {
    final isDark   = Theme.of(context).brightness == Brightness.dark;
    final disabled = isLoading || onPressed == null;

    final bg     = _bg(context, isDark, disabled);
    final fg     = _fg(context, isDark, disabled);
    final border = _border(context, isDark, disabled);

    final Widget child = isLoading
        ? AppLoader(size: 20, strokeWidth: 2, color: fg)
        : Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                Icon(icon, size: 18, color: fg),
                const SizedBox(width: AppSpacing.sm),
              ],
              Text(label, style: AppTypography.buttonMedium(color: fg)),
            ],
          );

    return ElevatedButton(
      onPressed: disabled ? null : onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor:         bg,
        foregroundColor:         fg,
        disabledBackgroundColor: bg,
        disabledForegroundColor: fg,
        shadowColor:  Colors.transparent,
        elevation:    0,
        padding: EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: verticalPadding,
        ),
        minimumSize: fullWidth
            ? const Size(double.infinity, 0)
            : width != null
                ? Size(width!, 0)
                : Size.zero,
        shape: RoundedRectangleBorder(
          borderRadius: AppRadius.all16,
          side: border,
        ),
      ),
      child: child,
    );
  }

  Color _bg(BuildContext context, bool isDark, bool disabled) {
    final a = disabled ? 0.50 : 1.0;
    switch (variant) {
      case AppButtonVariant.primary:
        return AppColors.primary.withValues(alpha: a);
      case AppButtonVariant.gold:
        return AppColors.gold.withValues(alpha: a);
      case AppButtonVariant.danger:
        return AppColors.error.withValues(alpha: a);
      case AppButtonVariant.secondary:
      case AppButtonVariant.outline:
        return disabled
            ? (isDark
                ? AppColors.darkBorder.withValues(alpha: 0.12)
                : AppColors.primary.withValues(alpha: 0.05))
            : Colors.transparent;
    }
  }

  Color _fg(BuildContext context, bool isDark, bool disabled) {
    final dimmed = disabled ? 0.45 : 1.0;
    switch (variant) {
      case AppButtonVariant.gold:
        return AppColors.primary.withValues(alpha: disabled ? 0.5 : 1.0);
      case AppButtonVariant.secondary:
      case AppButtonVariant.outline:
        return (isDark ? AppColors.darkTextPrimary : AppColors.primary)
            .withValues(alpha: dimmed);
      default:
        return AppColors.white.withValues(alpha: disabled ? 0.65 : 1.0);
    }
  }

  BorderSide _border(BuildContext context, bool isDark, bool disabled) {
    switch (variant) {
      case AppButtonVariant.secondary:
      case AppButtonVariant.outline:
        return BorderSide(
          color: (isDark ? AppColors.darkBorder : AppColors.primary)
              .withValues(alpha: disabled ? 0.30 : 1.0),
          width: 1.5,
        );
      default:
        return BorderSide.none;
    }
  }
}
