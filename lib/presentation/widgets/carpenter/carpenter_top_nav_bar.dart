import 'package:balaji_points/core/design/app_colors.dart';
import 'package:balaji_points/core/design/app_typography.dart';
import 'package:balaji_points/core/layout/carpenter_shell_layout.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Simple flat top bar with status-bar (top) safe area.
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
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final bg = backgroundColor ??
        (isDark
            ? const Color(0xFF001F3F)
            : AppColors.lightBackground);
    final fg = foregroundColor ??
        (isDark ? AppColors.white : AppColors.lightTextPrimary);
    final fgMuted = fg.withValues(alpha: 0.72);

    final overlayStyle = SystemUiOverlayStyle(
      statusBarColor: AppColors.transparent,
      statusBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
      statusBarBrightness: isDark ? Brightness.dark : Brightness.light,
    );

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: overlayStyle,
      child: Material(
        color: bg,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(height: topInset),
            SizedBox(
              height: CarpenterShellLayout.navBarHeight,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    leading ?? const SizedBox(width: 40),
                    Expanded(
                      child: center ??
                          (subtitle != null
                          ? Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  title,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: AppTypography.buttonMedium().copyWith(
                                    fontSize: 17,
                                    color: fg,
                                  ),
                                ),
                                Text(
                                  subtitle!,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: AppTypography.bodyMedium().copyWith(
                                    fontSize: 12,
                                    color: fgMuted,
                                  ),
                                ),
                              ],
                            )
                          : Align(
                              alignment: Alignment.centerLeft,
                              child: Text(
                                title,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: AppTypography.buttonMedium().copyWith(
                                  fontSize: 18,
                                  color: fg,
                                ),
                              ),
                            )),
                    ),
                    if (actions != null && actions!.isNotEmpty)
                      Row(mainAxisSize: MainAxisSize.min, children: actions!)
                    else
                      const SizedBox(width: 40),
                  ],
                ),
              ),
            ),
            Divider(height: 1, thickness: 1, color: fg.withValues(alpha: 0.08)),
          ],
        ),
      ),
    );
  }
}
