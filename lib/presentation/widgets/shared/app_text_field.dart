import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:balaji_points/core/design/app_colors.dart';
import 'package:balaji_points/core/design/app_typography.dart';

/// Standard themed text field.
/// Use [AppTextField.phone] for mobile number input (prefix +91, numeric).
/// Use [AppTextField.pin] for 4-digit PIN input (obscured, centered, large).
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

  // ── Normal text field ────────────────────────────────────────────────────────
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
  })  : _variant = _Variant.normal;

  // ── Phone number field ───────────────────────────────────────────────────────
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

  // ── 4-digit PIN field ────────────────────────────────────────────────────────
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
    final isPin = _variant == _Variant.pin;
    final isPhone = _variant == _Variant.phone;

    return TextFormField(
      controller: controller,
      enabled: enabled,
      obscureText: obscureText,
      keyboardType: keyboardType,
      textAlign: textAlign,
      maxLength: maxLength,
      inputFormatters: inputFormatters ??
          (isPin || isPhone
              ? [FilteringTextInputFormatter.digitsOnly]
              : null),
      onChanged: onChanged,
      style: isPin
          ? AppTypography.buttonMedium(color: context.themeTextPrimary).copyWith(
              fontSize: 22,
              letterSpacing: letterSpacing ?? 12,
            )
          : AppTypography.bodyLarge(color: context.themeTextPrimary),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: AppTypography.labelMedium(color: context.themePrimary),
        hintText: hint,
        hintStyle: AppTypography.bodyMedium(color: context.themeTextMuted),
        counterText: '',
        filled: true,
        fillColor: enabled
            ? context.themeSurface
            : context.themeSurface.withValues(alpha: 0.6),
        prefixIcon: isPhone
            ? Padding(
                padding: const EdgeInsets.only(left: 16, right: 8),
                child: Text(
                  '+91',
                  style: AppTypography.labelLarge(color: context.themeTextPrimary),
                ),
              )
            : (prefixIcon != null
                ? Icon(prefixIcon, color: context.themePrimary, size: 20)
                : null),
        prefixIconConstraints: isPhone
            ? const BoxConstraints(minWidth: 0, minHeight: 0)
            : null,
        suffixIcon: suffix,
        contentPadding: isPin
            ? const EdgeInsets.symmetric(vertical: 18)
            : const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: context.themeBorder, width: 1.5),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: context.themeBorder, width: 1.5),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: context.themePrimary, width: 2),
        ),
        disabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: context.themeBorder.withValues(alpha: 0.5),
            width: 1.5,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: context.themeError, width: 1.5),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: context.themeError, width: 2),
        ),
      ),
      validator: validator,
    );
  }
}

enum _Variant { normal, phone, pin }
