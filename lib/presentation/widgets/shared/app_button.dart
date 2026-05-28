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
    final bg = _backgroundColor(context);
    final fg = _foregroundColor(context);
    final border = _borderSide(context);
    final disabled = isLoading || onPressed == null;

    Widget child = isLoading
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

    final button = ElevatedButton(
      onPressed: disabled ? null : onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: disabled && !isLoading ? bg.withValues(alpha: 0.6) : bg,
        foregroundColor: fg,
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

    return button;
  }

  Color _backgroundColor(BuildContext context) {
    switch (variant) {
      case AppButtonVariant.primary:
        return context.themePrimary;
      case AppButtonVariant.secondary:
        return context.themeSecondary;
      case AppButtonVariant.outline:
        return AppColors.transparent;
      case AppButtonVariant.danger:
        return context.themeError;
    }
  }

  Color _foregroundColor(BuildContext context) {
    switch (variant) {
      case AppButtonVariant.outline:
        return context.themePrimary;
      default:
        return AppColors.white;
    }
  }

  BorderSide _borderSide(BuildContext context) {
    switch (variant) {
      case AppButtonVariant.outline:
        return BorderSide(color: context.themePrimary, width: 1.5);
      default:
        return BorderSide.none;
    }
  }
}
