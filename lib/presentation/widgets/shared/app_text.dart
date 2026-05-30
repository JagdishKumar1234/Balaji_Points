import 'package:flutter/material.dart';
import 'package:balaji_points/core/design/app_colors.dart';
import 'package:balaji_points/core/design/app_typography.dart';

/// Balaji Points Design System v2.0 — Text widget.
///
/// Canonical 5 variants:
///   hero     32 Bold    — balance, splash
///   title    20 SemiBold — page/section heading
///   section  16 SemiBold — card heading  [AppText.h5 alias]
///   body     14 Regular  — standard copy [AppText.body]
///   caption  12 Medium   — meta/timestamp [AppText.muted]
///
/// All legacy named constructors (h1–h5, label, bodySmall…) are kept
/// so existing call-sites compile without any changes.
class AppText extends StatelessWidget {
  final String text;
  final Color? color;
  final TextAlign? textAlign;
  final int? maxLines;
  final TextOverflow? overflow;
  final List<Shadow>? shadows;
  final _V _v;

  // ── Canonical constructors ─────────────────────────────────────────────────

  const AppText.hero(this.text, {super.key, this.color, this.textAlign, this.maxLines, this.overflow, this.shadows}) : _v = _V.hero;
  const AppText.title(this.text, {super.key, this.color, this.textAlign, this.maxLines, this.overflow, this.shadows}) : _v = _V.title;
  const AppText.section(this.text, {super.key, this.color, this.textAlign, this.maxLines, this.overflow, this.shadows}) : _v = _V.section;
  const AppText.body(this.text, {super.key, this.color, this.textAlign, this.maxLines, this.overflow, this.shadows}) : _v = _V.body;
  const AppText.caption(this.text, {super.key, this.color, this.textAlign, this.maxLines, this.overflow, this.shadows}) : _v = _V.caption;

  // ── Legacy aliases (zero breakage) ─────────────────────────────────────────

  const AppText.h1(this.text, {super.key, this.color, this.textAlign, this.maxLines, this.overflow, this.shadows}) : _v = _V.hero;
  const AppText.h2(this.text, {super.key, this.color, this.textAlign, this.maxLines, this.overflow, this.shadows}) : _v = _V.hero;
  const AppText.h3(this.text, {super.key, this.color, this.textAlign, this.maxLines, this.overflow, this.shadows}) : _v = _V.title;
  const AppText.h4(this.text, {super.key, this.color, this.textAlign, this.maxLines, this.overflow, this.shadows}) : _v = _V.title;
  const AppText.h5(this.text, {super.key, this.color, this.textAlign, this.maxLines, this.overflow, this.shadows}) : _v = _V.section;

  const AppText.bodyLarge(this.text, {super.key, this.color, this.textAlign, this.maxLines, this.overflow, this.shadows}) : _v = _V.section;
  const AppText.bodySmall(this.text, {super.key, this.color, this.textAlign, this.maxLines, this.overflow, this.shadows}) : _v = _V.caption;

  const AppText.label(this.text, {super.key, this.color, this.textAlign, this.maxLines, this.overflow, this.shadows}) : _v = _V.label;
  const AppText.labelSmall(this.text, {super.key, this.color, this.textAlign, this.maxLines, this.overflow, this.shadows}) : _v = _V.caption;

  const AppText.muted(this.text, {super.key, this.color, this.textAlign, this.maxLines, this.overflow, this.shadows}) : _v = _V.muted;
  const AppText.button(this.text, {super.key, this.color, this.textAlign, this.maxLines, this.overflow, this.shadows}) : _v = _V.label;

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final c = color ?? _defaultColor(context);
    return Text(
      text,
      style: _style(c).copyWith(shadows: shadows),
      textAlign: textAlign,
      maxLines:  maxLines,
      overflow:  overflow ?? (maxLines != null ? TextOverflow.ellipsis : null),
    );
  }

  Color _defaultColor(BuildContext context) {
    switch (_v) {
      case _V.hero:
      case _V.title:
      case _V.section:
      case _V.label:
        return context.themeTextPrimary;
      case _V.body:
        return context.themeTextPrimary;
      case _V.caption:
        return context.themeTextSecondary;
      case _V.muted:
        return context.themeTextMuted;
    }
  }

  TextStyle _style(Color c) {
    switch (_v) {
      case _V.hero:    return AppTypography.hero(color: c);
      case _V.title:   return AppTypography.title(color: c);
      case _V.section: return AppTypography.section(color: c);
      case _V.body:    return AppTypography.body(color: c);
      case _V.label:   return AppTypography.labelLarge(color: c);
      case _V.caption: return AppTypography.caption(color: c);
      case _V.muted:   return AppTypography.caption(color: c);
    }
  }
}

enum _V { hero, title, section, body, label, caption, muted }
