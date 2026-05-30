import 'package:flutter/material.dart';
import 'package:balaji_points/core/design/app_colors.dart';
import 'package:balaji_points/core/design/app_radius.dart';

/// Balaji Points Design System v2.0 — Card.
///
/// Default  : white surface, 1px border, Level 1 shadow (opacity 0.05).
/// Primary  : navy background, white child (wallet card, balance card).
/// Flat     : surface color, no border, no shadow.
class AppCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final double borderRadius;
  final Color? color;
  final bool showBorder;
  final bool showShadow;
  final VoidCallback? onTap;
  final _CardType _type;

  const AppCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.margin,
    this.borderRadius = AppRadius.r16,
    this.color,
    this.showBorder = true,
    this.showShadow = true,
    this.onTap,
  }) : _type = _CardType.normal;

  /// Navy background card — wallet balance, primary highlight.
  const AppCard.primary({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.margin,
    this.borderRadius = AppRadius.r16,
    this.onTap,
  })  : color = AppColors.primary,
        showBorder = false,
        showShadow = true,
        _type = _CardType.primary;

  /// No border, no shadow — nested inner card.
  const AppCard.flat({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.margin,
    this.borderRadius = AppRadius.r16,
    this.color,
    this.onTap,
  })  : showBorder = false,
        showShadow = false,
        _type = _CardType.flat;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final bg = color ??
        (_type == _CardType.primary
            ? AppColors.primary
            : (isDark ? AppColors.darkSurface : AppColors.surface));

    final radius = BorderRadius.circular(borderRadius);

    Widget card = Container(
      margin:  margin,
      padding: padding,
      decoration: BoxDecoration(
        color:        bg,
        borderRadius: radius,
        border: showBorder
            ? Border.all(
                color: isDark ? AppColors.darkBorder : AppColors.border,
                width: 1,
              )
            : null,
        boxShadow: showShadow
            ? (isDark ? AppColors.shadowLevel1Dark : AppColors.shadowLevel1)
            : null,
      ),
      child: child,
    );

    if (onTap != null) {
      return Material(
        color:        Colors.transparent,
        borderRadius: radius,
        child: InkWell(
          onTap:        onTap,
          borderRadius: radius,
          child: card,
        ),
      );
    }
    return card;
  }
}

enum _CardType { normal, primary, flat }
