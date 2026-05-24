import 'package:balaji_points/config/theme.dart' hide AppColors;
import 'package:balaji_points/core/layout/carpenter_shell_layout.dart';
import 'package:balaji_points/core/theme/design_token.dart';
import 'package:balaji_points/presentation/widgets/carpenter/carpenter_top_nav_bar.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Simple top navigation bar for carpenter shell screens (top safe area included).
class HomeNavBar extends StatelessWidget {
  final String? userImageUrl;
  final String? title;
  final String? subtitle;
  final bool showProfileButton;
  final bool showLogo;
  final bool showBackButton;
  final VoidCallback? onProfileTap;
  final VoidCallback? onBackTap;
  final List<Widget>? actions;

  const HomeNavBar({
    super.key,
    this.userImageUrl,
    this.title,
    this.subtitle,
    this.showProfileButton = true,
    this.showLogo = true,
    this.showBackButton = false,
    this.onProfileTap,
    this.onBackTap,
    this.actions,
  });

  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context);
    final topInset = CarpenterShellLayout.topInset(mq);

    Widget? leading;
    if (showBackButton) {
      leading = IconButton(
        icon: const Icon(Icons.arrow_back),
        onPressed: onBackTap ??
            () {
              if (Navigator.of(context).canPop()) context.pop();
            },
      );
    } else if (showProfileButton) {
      leading = IconButton(
        onPressed: onProfileTap ?? () => context.push('/profile'),
        icon: CircleAvatar(
          radius: 18,
          backgroundColor: DesignToken.primary.withValues(alpha: 0.12),
          backgroundImage: userImageUrl != null && userImageUrl!.isNotEmpty
              ? NetworkImage(userImageUrl!)
              : null,
          child: userImageUrl == null || userImageUrl!.isEmpty
              ? const Icon(Icons.person, size: 20, color: DesignToken.primary)
              : null,
        ),
      );
    }

    Widget? center;
    if (showLogo) {
      center = Row(
        children: [
          Image.asset(
            'assets/images/balaji_point_logo.png',
            width: 28,
            height: 28,
            errorBuilder: (_, __, ___) => const Icon(
              Icons.storefront_rounded,
              color: DesignToken.primary,
              size: 24,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title ?? 'Balaji Points',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.nunitoBold.copyWith(
                    fontSize: 17,
                    color: DesignToken.textDark,
                  ),
                ),
                if (subtitle != null)
                  Text(
                    subtitle!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.nunitoRegular.copyWith(
                      fontSize: 12,
                      color: DesignToken.textDark.withValues(alpha: 0.65),
                    ),
                  ),
              ],
            ),
          ),
        ],
      );
    }

    return CarpenterTopNavBar(
      topInset: topInset,
      title: title ?? 'Balaji Points',
      subtitle: showLogo ? null : subtitle,
      center: center,
      leading: leading,
      actions: actions,
    );
  }
}
