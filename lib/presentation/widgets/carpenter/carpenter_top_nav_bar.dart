import 'package:balaji_points/core/design/app_colors.dart';
import 'package:balaji_points/core/design/app_typography.dart';
import 'package:balaji_points/core/layout/carpenter_shell_layout.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Modern flat top nav bar — no bottom border.
/// Layout: [Hamburger] [Logo square + App name + Branch subtitle] → [Actions]
class CarpenterTopNavBar extends StatelessWidget implements PreferredSizeWidget {
  final Widget? leading;
  final String title;
  final String? subtitle;
  final Widget? center;
  final List<Widget>? actions;
  final Color? backgroundColor;
  final Color? foregroundColor;
  final double topInset;

  const CarpenterTopNavBar({
    super.key,
    this.leading,
    required this.title,
    this.subtitle,
    this.center,
    this.actions,
    this.backgroundColor,
    this.foregroundColor,
    required this.topInset,
  });

  factory CarpenterTopNavBar.fromContext(
    BuildContext context, {
    Key? key,
    Widget? leading,
    required String title,
    String? subtitle,
    Widget? center,
    List<Widget>? actions,
    Color? backgroundColor,
    Color? foregroundColor,
  }) {
    final mq = MediaQuery.of(context);
    return CarpenterTopNavBar(
      key: key,
      leading: leading,
      title: title,
      subtitle: subtitle,
      center: center,
      actions: actions,
      backgroundColor: backgroundColor,
      foregroundColor: foregroundColor,
      topInset: CarpenterShellLayout.topInset(mq),
    );
  }

  @override
  Size get preferredSize =>
      Size.fromHeight(topInset + CarpenterShellLayout.navBarHeight);

  @override
  Widget build(BuildContext context) {
    final bg = backgroundColor ?? context.themeBackground;
    final fg = foregroundColor ?? context.themeTextPrimary;
    final isDark = context.isDarkMode;

    final overlayStyle = SystemUiOverlayStyle(
      statusBarColor: AppColors.transparent,
      statusBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
      statusBarBrightness: isDark ? Brightness.dark : Brightness.light,
    );

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: overlayStyle,
      child: Material(
        color: bg,
        elevation: 0,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(height: topInset),
            SizedBox(
              height: CarpenterShellLayout.navBarHeight,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Hamburger or custom leading
                    leading ?? const SizedBox(width: 48),

                    // Center: logo + title/subtitle OR custom center widget
                    Expanded(
                      child: center ?? _DefaultCenter(
                        title: title,
                        subtitle: subtitle,
                        fg: fg,
                      ),
                    ),

                    // Actions (cart icon etc.)
                    if (actions != null && actions!.isNotEmpty)
                      Row(mainAxisSize: MainAxisSize.min, children: actions!)
                    else
                      const SizedBox(width: 48),
                  ],
                ),
              ),
            ),
            Container(
              height: 1,
              color: isDark
                  ? AppColors.white.withValues(alpha: 0.08)
                  : AppColors.black.withValues(alpha: 0.08),
            ),
          ],
        ),
      ),
    );
  }
}

class _DefaultCenter extends StatelessWidget {
  final String title;
  final String? subtitle;
  final Color fg;

  const _DefaultCenter({
    required this.title,
    required this.subtitle,
    required this.fg,
  });

  @override
  Widget build(BuildContext context) {
    final fgMuted = fg.withValues(alpha: 0.55);
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: AppTypography.h5(color: fg),
        ),
        if (subtitle != null)
          Text(
            subtitle!,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTypography.caption(color: fgMuted),
          ),
      ],
    );
  }
}
