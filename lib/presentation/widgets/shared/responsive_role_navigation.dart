import 'package:flutter/material.dart';

import 'package:balaji_points/core/design/app_colors.dart';
import 'package:balaji_points/core/layout/responsive.dart';

class RoleNavigationItem {
  const RoleNavigationItem({
    required this.label,
    required this.icon,
    required this.selectedIcon,
  });

  final String label;
  final IconData icon;
  final IconData selectedIcon;
}

/// Material 3 side navigation for wide role dashboards. Compact layouts keep
/// their existing bottom navigation or drawer patterns.
class ResponsiveRoleNavigation extends StatelessWidget {
  const ResponsiveRoleNavigation({
    super.key,
    required this.child,
    required this.roleLabel,
    required this.items,
    required this.selectedIndex,
    required this.onSelected,
    this.onLogout,
  });

  final Widget child;
  final String roleLabel;
  final List<RoleNavigationItem> items;
  final int selectedIndex;
  final ValueChanged<int> onSelected;
  final VoidCallback? onLogout;

  @override
  Widget build(BuildContext context) {
    if (!context.isWideScreen || items.isEmpty) return child;

    final extended = context.screenWidth >= ResponsiveBreakpoints.desktop;
    final l10n = MaterialLocalizations.of(context);

    return Row(
      children: [
        SizedBox(
          width: extended ? 264 : 80,
          child: NavigationRail(
            extended: extended,
            minWidth: 80,
            minExtendedWidth: 264,
            groupAlignment: -0.85,
            backgroundColor: AppColors.navigation,
            selectedIndex: selectedIndex.clamp(0, items.length - 1),
            labelType: extended
                ? NavigationRailLabelType.none
                : NavigationRailLabelType.all,
            onDestinationSelected: onSelected,
            leading: Padding(
              padding: EdgeInsets.fromLTRB(extended ? 20 : 8, 24, 8, 24),
              child: extended
                  ? Row(
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: AppColors.white.withValues(alpha: 0.10),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          clipBehavior: Clip.antiAlias,
                          child: Image.asset(
                            'assets/images/balaji_point_logo.png',
                            fit: BoxFit.cover,
                            errorBuilder: (_, _, _) => const Icon(
                              Icons.home_work_rounded,
                              color: AppColors.white,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Text(
                                'Balaji Hardware',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: AppColors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              Text(
                                roleLabel,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: AppColors.white.withValues(
                                    alpha: 0.68,
                                  ),
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    )
                  : const Icon(
                      Icons.home_work_rounded,
                      color: AppColors.white,
                      size: 28,
                    ),
            ),
            destinations: [
              for (final item in items)
                NavigationRailDestination(
                  icon: Icon(item.icon),
                  selectedIcon: Icon(item.selectedIcon),
                  label: Text(item.label),
                  padding: const EdgeInsets.symmetric(vertical: 4),
                ),
            ],
            trailing: onLogout == null
                ? null
                : Expanded(
                    child: Align(
                      alignment: Alignment.bottomCenter,
                      child: Padding(
                        padding: EdgeInsets.fromLTRB(
                          extended ? 16 : 8,
                          8,
                          8,
                          20,
                        ),
                        child: extended
                            ? SizedBox(
                                width: double.infinity,
                                child: OutlinedButton.icon(
                                  onPressed: onLogout,
                                  icon: const Icon(Icons.logout_rounded),
                                  label: const Text('Sign out'),
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: AppColors.white,
                                    side: BorderSide(
                                      color: AppColors.white.withValues(
                                        alpha: 0.25,
                                      ),
                                    ),
                                  ),
                                ),
                              )
                            : IconButton(
                                onPressed: onLogout,
                                tooltip: l10n.closeButtonTooltip,
                                icon: const Icon(Icons.logout_rounded),
                                color: AppColors.white,
                              ),
                      ),
                    ),
                  ),
          ),
        ),
        Expanded(child: child),
      ],
    );
  }
}
