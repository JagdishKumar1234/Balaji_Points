import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:balaji_points/core/design/app_colors.dart';
import 'package:balaji_points/core/design/app_spacing.dart';
import 'package:balaji_points/core/design/app_typography.dart';
import 'package:balaji_points/core/layout/carpenter_shell_layout.dart';
import 'package:balaji_points/l10n/app_localizations.dart';
import 'package:balaji_points/providers/home_provider.dart';
import 'package:balaji_points/presentation/widgets/shared/app_button.dart';
import 'package:balaji_points/presentation/widgets/shared/app_text.dart';

class HomeDrawer extends StatelessWidget {
  final HomeState homeState;
  final String appVersion;
  final Future<void> Function(BuildContext) onLogout;

  const HomeDrawer({
    super.key,
    required this.homeState,
    required this.appVersion,
    required this.onLogout,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final mq = MediaQuery.of(context);
    final topInset = mq.padding.top;
    final drawerFooterBottom = CarpenterShellLayout.chromeHeight(mq) + AppSpacing.sm;
    final titleColor = isDark ? AppColors.white : context.themeTextPrimary;
    final subtitleColor = isDark
        ? AppColors.white.withValues(alpha: 0.80)
        : context.themeTextPrimary.withValues(alpha: 0.70);

    final phone = homeState.userData?['phone'] as String? ?? '';
    final profileImage = homeState.profileImage;
    final hasImg = profileImage != null &&
        (profileImage.startsWith('http://') || profileImage.startsWith('https://'));
    final l10n = AppLocalizations.of(context)!;

    final drawerBase = theme.colorScheme.surface;
    final drawerTintSoft = isDark
        ? context.themePrimary.withValues(alpha: 0.10)
        : context.themeSecondary.withValues(alpha: 0.06);
    final drawerTintAccent = isDark
        ? const Color(0xFF2563EB).withValues(alpha: 0.16)
        : AppColors.warning.withValues(alpha: 0.30);

    return Drawer(
      elevation: 8,
      child: SafeArea(
        top: false,
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [drawerBase, drawerTintSoft, drawerTintAccent],
              stops: const [0.0, 0.45, 1.0],
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header
              Container(
                padding: EdgeInsets.fromLTRB(20, 20 + topInset, 20, 20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      isDark
                          ? const Color(0xFF2563EB).withValues(alpha: 0.6)
                          : context.themeSecondary.withValues(alpha: 0.15),
                      isDark
                          ? AppColors.tierPlatinum.withValues(alpha: 0.7)
                          : AppColors.warning.withValues(alpha: 0.9),
                    ],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.black.withValues(alpha: 0.15),
                      blurRadius: 18,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                            color: AppColors.white.withValues(alpha: 0.9),
                            width: 2),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.black.withValues(alpha: 0.25),
                            blurRadius: 12,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: ClipOval(
                        child: hasImg
                            ? Image.network(profileImage,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => ColoredBox(
                                  color: AppColors.white,
                                  child: Icon(Icons.person,
                                      color: context.themePrimary),
                                ))
                            : ColoredBox(
                                color: AppColors.white,
                                child: Icon(Icons.person,
                                    color: context.themePrimary),
                              ),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.cardPadding),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            homeState.displayName,
                            style: AppTypography.h5(color: AppColors.white),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: AppSpacing.xs),
                          if (phone.isNotEmpty)
                            Text(
                              phone,
                              style: AppTypography.bodySmall(
                                  color: AppColors.white.withValues(alpha: 0.85)),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.xs),

              // Nav items
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                  children: [
                    _DrawerSectionLabel(
                        label: l10n.drawerSectionMainNav, color: subtitleColor),
                    _DrawerNavItem(
                      icon: Icons.home_rounded,
                      label: l10n.home,
                      titleColor: titleColor,
                      onTap: () {
                        Navigator.of(context).pop();
                        context.go('/');
                      },
                    ),
                    _DrawerNavItem(
                      icon: Icons.account_balance_wallet_outlined,
                      label: l10n.earn,
                      titleColor: titleColor,
                      onTap: () {
                        Navigator.of(context).pop();
                        context.go('/wallet');
                      },
                    ),
                    _DrawerNavItem(
                      icon: Icons.notifications_outlined,
                      label: l10n.notifications,
                      titleColor: titleColor,
                      onTap: () {
                        Navigator.of(context).pop();
                        context.go('/notifications');
                      },
                    ),
                    _DrawerNavItem(
                      icon: Icons.person_outline,
                      label: l10n.profile,
                      titleColor: titleColor,
                      onTap: () {
                        Navigator.of(context).pop();
                        context.go('/profile');
                      },
                    ),
                    Padding(
                      padding: AppSpacing.screenHorizontal,
                      child: Divider(
                          height: 24,
                          color: subtitleColor.withValues(alpha: 0.22)),
                    ),
                    _DrawerSectionLabel(
                        label: l10n.drawerSectionMore, color: subtitleColor),
                    _DrawerNavItem(
                      icon: Icons.layers_rounded,
                      label: l10n.drawerProductsTitle,
                      subtitle: l10n.drawerProductsSubtitle,
                      titleColor: titleColor,
                      subtitleColor: subtitleColor,
                      onTap: () {
                        Navigator.of(context).pop();
                        context.push('/products');
                      },
                    ),
                    _DrawerNavItem(
                      icon: Icons.shopping_cart_outlined,
                      label: l10n.drawerCart,
                      titleColor: titleColor,
                      onTap: () {
                        Navigator.of(context).pop();
                        context.push('/cart');
                      },
                    ),
                    _DrawerNavItem(
                      icon: Icons.receipt_long_rounded,
                      label: l10n.myOrders,
                      titleColor: titleColor,
                      onTap: () {
                        Navigator.of(context).pop();
                        context.push('/orders');
                      },
                    ),
                    _DrawerNavItem(
                      icon: Icons.info_outline_rounded,
                      label: l10n.aboutUs,
                      subtitle: l10n.aboutUsMenuSubtitle,
                      titleColor: titleColor,
                      subtitleColor: subtitleColor,
                      onTap: () {
                        Navigator.of(context).pop();
                        context.push('/about-us');
                      },
                    ),
                  ],
                ),
              ),

              // Footer
              Padding(padding: AppSpacing.screenHorizontal, child: const Divider()),
              Padding(
                padding: EdgeInsets.fromLTRB(
                  AppSpacing.cardPadding,
                  AppSpacing.sm,
                  AppSpacing.cardPadding,
                  drawerFooterBottom,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (appVersion.isNotEmpty) ...[
                      Center(
                        child: Text(
                          appVersion,
                          style: AppTypography.labelSmall(
                            color: context.themeTextSecondary
                                .withValues(alpha: 0.5),
                          ),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.md),
                    ],
                    AppButton(
                      label: l10n.logout,
                      onPressed: () => onLogout(context),
                      variant: AppButtonVariant.danger,
                      icon: Icons.logout_rounded,
                      verticalPadding: 14,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DrawerSectionLabel extends StatelessWidget {
  final String label;
  final Color color;

  const _DrawerSectionLabel({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, AppSpacing.md, 20, AppSpacing.xs),
      child: Text(label, style: AppTypography.overline(color: color)),
    );
  }
}

class _DrawerNavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String? subtitle;
  final Color titleColor;
  final Color? subtitleColor;
  final VoidCallback onTap;

  const _DrawerNavItem({
    required this.icon,
    required this.label,
    required this.titleColor,
    required this.onTap,
    this.subtitle,
    this.subtitleColor,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: context.themeSecondary),
      title: Text(label, style: AppTypography.bodyMedium(color: titleColor)),
      subtitle: subtitle != null
          ? Text(
              subtitle!,
              style: AppTypography.bodySmall(
                  color: subtitleColor ??
                      titleColor.withValues(alpha: 0.65)),
            )
          : null,
      onTap: onTap,
    );
  }
}

// Unused import guard
// ignore: unused_element
const _appTextRef = AppText;
