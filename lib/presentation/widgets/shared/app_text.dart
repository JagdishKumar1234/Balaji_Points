import 'package:flutter/material.dart';
import 'package:balaji_points/core/design/app_colors.dart';
import 'package:balaji_points/core/design/app_typography.dart';

/// Standardised text widget that always uses the design system tokens.
/// Pick the right variant — never write raw Text() with manual styles.
class AppText extends StatelessWidget {
  final String text;
  final Color? color;
  final TextAlign? textAlign;
  final int? maxLines;
  final TextOverflow? overflow;
  final List<Shadow>? shadows;
  final _Variant _variant;

  // ── Heading ─────────────────────────────────────────────────────────────────
  const AppText.h1(this.text, {super.key, this.color, this.textAlign, this.maxLines, this.overflow, this.shadows})
      : _variant = _Variant.h1;

  const AppText.h2(this.text, {super.key, this.color, this.textAlign, this.maxLines, this.overflow, this.shadows})
      : _variant = _Variant.h2;

  const AppText.h3(this.text, {super.key, this.color, this.textAlign, this.maxLines, this.overflow, this.shadows})
      : _variant = _Variant.h3;

  const AppText.h4(this.text, {super.key, this.color, this.textAlign, this.maxLines, this.overflow, this.shadows})
      : _variant = _Variant.h4;

  // ── Body ────────────────────────────────────────────────────────────────────
  const AppText.bodyLarge(this.text, {super.key, this.color, this.textAlign, this.maxLines, this.overflow, this.shadows})
      : _variant = _Variant.bodyLarge;

  const AppText.body(this.text, {super.key, this.color, this.textAlign, this.maxLines, this.overflow, this.shadows})
      : _variant = _Variant.body;

  const AppText.bodySmall(this.text, {super.key, this.color, this.textAlign, this.maxLines, this.overflow, this.shadows})
      : _variant = _Variant.bodySmall;

  // ── Label ───────────────────────────────────────────────────────────────────
  const AppText.label(this.text, {super.key, this.color, this.textAlign, this.maxLines, this.overflow, this.shadows})
      : _variant = _Variant.label;

  const AppText.labelSmall(this.text, {super.key, this.color, this.textAlign, this.maxLines, this.overflow, this.shadows})
      : _variant = _Variant.labelSmall;

  // ── Muted (secondary colour, smaller) ───────────────────────────────────────
  const AppText.muted(this.text, {super.key, this.color, this.textAlign, this.maxLines, this.overflow, this.shadows})
      : _variant = _Variant.muted;

  // ── Button text ─────────────────────────────────────────────────────────────
  const AppText.button(this.text, {super.key, this.color, this.textAlign, this.maxLines, this.overflow, this.shadows})
      : _variant = _Variant.button;

  @override
  Widget build(BuildContext context) {
    final effectiveColor = color ?? _defaultColor(context);
    final style = _baseStyle(effectiveColor).copyWith(shadows: shadows);

    return Text(
      text,
      style: style,
      textAlign: textAlign,
      maxLines: maxLines,
      overflow: overflow ?? (maxLines != null ? TextOverflow.ellipsis : null),
    );
  }

  Color _defaultColor(BuildContext context) {
    switch (_variant) {
      case _Variant.h1:
      case _Variant.h2:
      case _Variant.h3:
      case _Variant.h4:
      case _Variant.bodyLarge:
      case _Variant.body:
      case _Variant.label:
      case _Variant.button:
        return context.themeTextPrimary;
      case _Variant.bodySmall:
      case _Variant.labelSmall:
        return context.themeTextSecondary;
      case _Variant.muted:
        return context.themeTextMuted;
    }
  }

  TextStyle _baseStyle(Color c) {
    switch (_variant) {
      case _Variant.h1:
        return AppTypography.h1(color: c);
      case _Variant.h2:
        return AppTypography.h2(color: c);
      case _Variant.h3:
        return AppTypography.h3(color: c);
      case _Variant.h4:
        return AppTypography.h4(color: c);
      case _Variant.bodyLarge:
        return AppTypography.bodyLarge(color: c);
      case _Variant.body:
        return AppTypography.bodyMedium(color: c);
      case _Variant.bodySmall:
        return AppTypography.bodySmall(color: c);
      case _Variant.label:
        return AppTypography.labelLarge(color: c);
      case _Variant.labelSmall:
        return AppTypography.labelMedium(color: c);
      case _Variant.muted:
        return AppTypography.bodySmall(color: c);
      case _Variant.button:
        return AppTypography.buttonMedium(color: c);
    }
  }
}

enum _Variant { h1, h2, h3, h4, bodyLarge, body, bodySmall, label, labelSmall, muted, button }
