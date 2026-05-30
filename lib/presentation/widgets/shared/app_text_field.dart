import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:balaji_points/core/design/app_colors.dart';
import 'package:balaji_points/core/design/app_radius.dart';
import 'package:balaji_points/core/design/app_typography.dart';

/// Balaji Points Design System v2.0 — Text field.
///
/// Light: fill = white, border = #E5E7EB, focused = navy.
/// Dark:  fill = #171A22, border = #2B313D, focused = gold.
class AppTextField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String? hint;
  final IconData? prefixIcon;
  final Widget? suffix;
  final bool enabled;
  final bool obscureText;
  final TextInputType keyboardType;
  final TextAlign textAlign;
  final int? maxLength;
  final double? letterSpacing;
  final String? Function(String?)? validator;
  final void Function(String)? onChanged;
  final List<TextInputFormatter>? inputFormatters;
  final _Variant _variant;

  const AppTextField({
    super.key,
    required this.controller,
    required this.label,
    this.hint,
    this.prefixIcon,
    this.suffix,
    this.enabled = true,
    this.obscureText = false,
    this.keyboardType = TextInputType.text,
    this.textAlign = TextAlign.start,
    this.maxLength,
    this.letterSpacing,
    this.validator,
    this.onChanged,
    this.inputFormatters,
  }) : _variant = _Variant.normal;

  const AppTextField.phone({
    super.key,
    required this.controller,
    required this.label,
    this.hint,
    this.enabled = true,
    this.suffix,
    this.validator,
    this.onChanged,
  })  : _variant = _Variant.phone,
        prefixIcon = null,
        obscureText = false,
        keyboardType = TextInputType.phone,
        textAlign = TextAlign.start,
        maxLength = 10,
        letterSpacing = null,
        inputFormatters = null;

  const AppTextField.pin({
    super.key,
    required this.controller,
    required this.label,
    this.enabled = true,
    this.validator,
    this.onChanged,
  })  : _variant = _Variant.pin,
        hint = null,
        prefixIcon = null,
        suffix = null,
        obscureText = true,
        keyboardType = TextInputType.number,
        textAlign = TextAlign.center,
        maxLength = 4,
        letterSpacing = 12,
        inputFormatters = null;

  @override
  Widget build(BuildContext context) {
    final isPin   = _variant == _Variant.pin;
    final isPhone = _variant == _Variant.phone;
    final isDark  = Theme.of(context).brightness == Brightness.dark;

    final fillColor = enabled
        ? (isDark ? AppColors.darkSurface : AppColors.surface)
        : (isDark
            ? AppColors.darkSurface.withValues(alpha: 0.5)
            : AppColors.softSurface);

    final borderColor  = isDark ? AppColors.darkBorder : AppColors.border;
    final focusedColor = isDark ? AppColors.gold        : AppColors.primary;
    final labelColor   = isDark ? AppColors.darkTextSecondary : AppColors.textSecondary;

    return TextFormField(
      controller:   controller,
      enabled:      enabled,
      obscureText:  obscureText,
      keyboardType: keyboardType,
      textAlign:    textAlign,
      maxLength:    maxLength,
      cursorColor:  focusedColor,
      inputFormatters: inputFormatters ??
          (isPin || isPhone ? [FilteringTextInputFormatter.digitsOnly] : null),
      onChanged: onChanged,
      style: isPin
          ? AppTypography.title(color: context.themeTextPrimary).copyWith(
              letterSpacing: letterSpacing ?? 12,
            )
          : AppTypography.body(color: context.themeTextPrimary),
      decoration: InputDecoration(
        labelText:          label,
        labelStyle:         AppTypography.body(color: labelColor),
        floatingLabelStyle: AppTypography.caption(color: focusedColor),
        hintText:           hint,
        hintStyle:          AppTypography.body(color: context.themeTextMuted),
        counterText: '',
        filled:      true,
        fillColor:   fillColor,
        errorStyle:  AppTypography.caption(color: AppColors.error),

        prefixIcon: isPhone
            ? Padding(
                padding: const EdgeInsets.only(left: 16, right: 8),
                child: Text(
                  '+91',
                  style: AppTypography.body(color: context.themeTextPrimary),
                ),
              )
            : (prefixIcon != null
                ? Icon(prefixIcon, color: focusedColor, size: 20)
                : null),
        prefixIconConstraints: isPhone
            ? const BoxConstraints(minWidth: 0, minHeight: 0)
            : null,
        suffixIcon: suffix,

        contentPadding: isPin
            ? const EdgeInsets.symmetric(vertical: 18)
            : const EdgeInsets.symmetric(horizontal: 16, vertical: 14),

        border: OutlineInputBorder(
          borderRadius: AppRadius.all16,
          borderSide: BorderSide(color: borderColor),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: AppRadius.all16,
          borderSide: BorderSide(color: borderColor),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: AppRadius.all16,
          borderSide: BorderSide(color: focusedColor, width: 2),
        ),
        disabledBorder: OutlineInputBorder(
          borderRadius: AppRadius.all16,
          borderSide: BorderSide(color: borderColor.withValues(alpha: 0.4)),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: AppRadius.all16,
          borderSide: const BorderSide(color: AppColors.error, width: 1.5),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: AppRadius.all16,
          borderSide: const BorderSide(color: AppColors.error, width: 2),
        ),
      ),
      validator: validator,
    );
  }
}

enum _Variant { normal, phone, pin }
