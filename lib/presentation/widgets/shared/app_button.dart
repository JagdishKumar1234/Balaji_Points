import 'package:flutter/material.dart';
import 'package:balaji_points/core/design/app_colors.dart';
import 'package:balaji_points/core/design/app_typography.dart';
import 'app_loader.dart';

enum AppButtonVariant { primary, secondary, outline, danger }

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
    this.verticalPadding = 16,
  });

  const AppButton.primary({
    super.key,
    required this.label,
    this.onPressed,
    this.isLoading = false,
    this.fullWidth = true,
    this.width,
    this.icon,
    this.verticalPadding = 16,
  }) : variant = AppButtonVariant.primary;

  const AppButton.secondary({
    super.key,
    required this.label,
    this.onPressed,
    this.isLoading = false,
    this.fullWidth = true,
    this.width,
    this.icon,
    this.verticalPadding = 16,
  }) : variant = AppButtonVariant.secondary;

  const AppButton.outline({
    super.key,
    required this.label,
    this.onPressed,
    this.isLoading = false,
    this.fullWidth = true,
    this.width,
    this.icon,
    this.verticalPadding = 16,
  }) : variant = AppButtonVariant.outline;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final disabled = isLoading || onPressed == null;

    final bg    = _backgroundColor(context, isDark, disabled);
    final fg    = _foregroundColor(context, isDark, disabled);
    final border = _borderSide(context, isDark, disabled);

    final Widget child = isLoading
        ? AppLoader(size: 20, strokeWidth: 2, color: fg)
        : Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                Icon(icon, size: 18, color: fg),
                const SizedBox(width: 8),
              ],
              Text(
                label,
                style: AppTypography.buttonMedium(color: fg).copyWith(fontSize: 16),
              ),
            ],
          );

    return ElevatedButton(
      onPressed: disabled ? null : onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: bg,
        foregroundColor: fg,
        disabledBackgroundColor: bg,
        disabledForegroundColor: fg,
        shadowColor: AppColors.transparent,
        elevation: 0,
        padding: EdgeInsets.symmetric(horizontal: 24, vertical: verticalPadding),
        minimumSize: fullWidth
            ? const Size(double.infinity, 0)
            : width != null
                ? Size(width!, 0)
                : const Size(0, 0),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: border,
        ),
      ),
      child: child,
    );
  }

  Color _backgroundColor(BuildContext context, bool isDark, bool disabled) {
    final alpha = disabled ? 0.50 : 1.0;
    switch (variant) {
      case AppButtonVariant.primary:
        return context.themePrimary.withValues(alpha: alpha);
      case AppButtonVariant.secondary:
        return context.themeSecondary.withValues(alpha: alpha);
      case AppButtonVariant.danger:
        return context.themeError.withValues(alpha: alpha);
      case AppButtonVariant.outline:
        // Transparent bg; dim with a faint surface tint when disabled.
        return disabled
            ? (isDark
                ? AppColors.darkBorder.withValues(alpha: 0.15)
                : context.themePrimary.withValues(alpha: 0.06))
            : AppColors.transparent;
    }
  }

  Color _foregroundColor(BuildContext context, bool isDark, bool disabled) {
    final mutedAlpha = disabled ? 0.45 : 1.0;
    switch (variant) {
      case AppButtonVariant.outline:
        return context.themePrimary.withValues(alpha: mutedAlpha);
      default:
        // White text on filled buttons; dim when disabled.
        return AppColors.white.withValues(alpha: disabled ? 0.65 : 1.0);
    }
  }

  BorderSide _borderSide(BuildContext context, bool isDark, bool disabled) {
    switch (variant) {
      case AppButtonVariant.outline:
        return BorderSide(
          color: context.themePrimary.withValues(alpha: disabled ? 0.30 : 1.0),
          width: 1.5,
        );
      default:
        return BorderSide.none;
    }
  }
}
