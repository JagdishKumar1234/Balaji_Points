import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:balaji_points/core/design/app_colors.dart';
import 'package:balaji_points/core/design/app_radius.dart';
import 'package:balaji_points/core/design/app_spacing.dart';
import 'package:balaji_points/core/design/app_typography.dart';
import 'package:balaji_points/core/layout/carpenter_shell_layout.dart';
import 'package:balaji_points/core/utils/points_utils.dart';
import 'package:balaji_points/l10n/app_localizations.dart';
import 'package:balaji_points/presentation/widgets/carpenter/member_identity.dart';
import 'package:balaji_points/presentation/widgets/shared/app_button.dart';
import 'package:balaji_points/providers/home_provider.dart';

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
    final l10n = AppLocalizations.of(context)!;
    final footerBottom =
        CarpenterShellLayout.chromeHeight(MediaQuery.of(context)) +
        AppSpacing.sm;

    void open(void Function() navigate) {
      Navigator.of(context).pop();
      navigate();
    }

    return Drawer(
      elevation: 8,
      backgroundColor: context.themeSurface,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _DrawerHeader(homeState: homeState),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
              children: [
                _SectionLabel(l10n.drawerSectionMainNav),
                _NavTile(
                  // This menu only opens from Home.
                  selected: true,
                  icon: Icons.home_rounded,
                  label: l10n.home,
                  onTap: () => Navigator.of(context).pop(),
                ),
                _NavTile(
                  icon: Icons.account_balance_wallet_rounded,
                  label: l10n.earn,
                  onTap: () => open(() => context.go('/wallet')),
                ),
                _NavTile(
                  icon: Icons.notifications_rounded,
                  label: l10n.notifications,
                  onTap: () => open(() => context.go('/notifications')),
                ),
                _NavTile(
                  icon: Icons.person_rounded,
                  label: l10n.profile,
                  onTap: () => open(() => context.go('/profile')),
                ),
                const SizedBox(height: 8),
                _SectionLabel(l10n.drawerSectionMore),
                _NavTile(
                  icon: Icons.info_rounded,
                  label: l10n.aboutUs,
                  subtitle: l10n.aboutUsMenuSubtitle,
                  onTap: () => open(() => context.push('/about-us')),
                ),
              ],
            ),
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(16, 8, 16, footerBottom),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                AppButton(
                  label: l10n.logout,
                  onPressed: () => onLogout(context),
                  variant: AppButtonVariant.danger,
                  icon: Icons.logout_rounded,
                ),
                if (appVersion.isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    appVersion,
                    textAlign: TextAlign.center,
                    style: AppTypography.caption(
                      color: context.themeTextSecondary,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DrawerHeader extends StatelessWidget {
  const _DrawerHeader({required this.homeState});

  final HomeState homeState;

  @override
  Widget build(BuildContext context) {
    final phone = homeState.userData?['phone'] as String? ?? '';
    return Container(
      padding: EdgeInsets.fromLTRB(
        20,
        20 + MediaQuery.paddingOf(context).top,
        20,
        16,
      ),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.primary, AppColors.primaryLight],
        ),
        borderRadius: BorderRadius.only(bottomRight: Radius.circular(28)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              MemberAvatar(
                name: homeState.displayName,
                imageUrl: homeState.profileImage,
                size: 64,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      homeState.displayName,
                      style: AppTypography.h5(color: AppColors.white),
                    ),
                    if (phone.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        phone,
                        style: AppTypography.bodySmall(
                          color: AppColors.onPrimaryMuted,
                        ),
                      ),
                    ],
                    const SizedBox(height: 6),
                    RoleTag(label: memberRoleName(context, homeState.userData)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.white.withValues(alpha: 0.08),
              borderRadius: AppRadius.md12,
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.stars_rounded,
                  color: AppColors.gold,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    PointsUtils.formatPoints(homeState.points),
                    style: AppTypography.labelLarge(
                      color: AppColors.white,
                    ).copyWith(fontWeight: FontWeight.w700),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  homeState.tier,
                  style: AppTypography.caption(color: AppColors.goldSoft),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 10, 8, 6),
      child: Text(
        label,
        style: AppTypography.overline(color: context.themeTextSecondary),
      ),
    );
  }
}

class _NavTile extends StatelessWidget {
  const _NavTile({
    required this.icon,
    required this.label,
    required this.onTap,
    this.subtitle,
    this.selected = false,
  });

  final IconData icon;
  final String label;
  final String? subtitle;
  final VoidCallback onTap;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final selectedFill = isDark
        ? AppColors.darkPendingSoft
        : AppColors.goldSoft;
    final iconFill = isDark ? AppColors.darkSoftSurface : AppColors.primarySoft;
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Material(
        color: selected ? selectedFill : AppColors.transparent,
        borderRadius: AppRadius.md12,
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            child: Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: selected ? AppColors.primary : iconFill,
                    borderRadius: AppRadius.md12,
                  ),
                  child: Icon(
                    icon,
                    size: 20,
                    color: selected
                        ? AppColors.gold
                        : context.themeContentColor,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        label,
                        style: AppTypography.labelLarge(
                          color: context.themeTextPrimary,
                        ).copyWith(fontWeight: FontWeight.w600),
                      ),
                      if (subtitle != null)
                        Text(
                          subtitle!,
                          style: AppTypography.caption(
                            color: context.themeTextSecondary,
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
