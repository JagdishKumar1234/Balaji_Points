import 'package:balaji_points/core/constants/app_constants.dart';
import 'package:flutter/material.dart';
import 'package:balaji_points/l10n/app_localizations.dart';

import 'package:balaji_points/core/design/app_colors.dart';
import 'package:balaji_points/core/design/app_radius.dart';
import 'package:balaji_points/core/design/app_typography.dart';
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
    const railWidth = 80.0;
    const sidebarWidth = 232.0; // UI spec desktop sidebar

    return Row(
      // Stretch so pages that size to their content start at the top
      // instead of being centred vertically beside the rail.
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(
          width: extended ? sidebarWidth : railWidth,
          child: NavigationRail(
            extended: extended,
            minWidth: railWidth,
            minExtendedWidth: sidebarWidth,
            groupAlignment: -0.85,
            // Colours come from NavigationRailThemeData (navy + gold).
            selectedIndex: selectedIndex.clamp(0, items.length - 1),
            labelType: extended
                ? NavigationRailLabelType.none
                : NavigationRailLabelType.all,
            onDestinationSelected: onSelected,
            leading: Padding(
              padding: EdgeInsets.fromLTRB(extended ? 16 : 8, 24, 8, 16),
              child: extended
                  ? SizedBox(
                      width: sidebarWidth - 32,
                      child: Row(
                        children: [
                          Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: AppColors.gold,
                              borderRadius: AppRadius.md12,
                            ),
                            clipBehavior: Clip.antiAlias,
                            child: Image.asset(
                              'assets/images/balaji_point_logo.png',
                              fit: BoxFit.cover,
                              errorBuilder: (_, _, _) => const Icon(
                                Icons.home_work_rounded,
                                color: AppColors.primary,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  AppConstants.companyName,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: AppTypography.section(
                                    color: AppColors.white,
                                  ),
                                ),
                                Text(
                                  roleLabel,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: AppTypography.caption(
                                    color: AppColors.onPrimaryMuted,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    )
                  : const Icon(
                      Icons.home_work_rounded,
                      color: AppColors.gold,
                      size: 28,
                    ),
            ),
            destinations: [
              for (final item in items)
                NavigationRailDestination(
                  icon: Icon(item.icon),
                  selectedIcon: Icon(item.selectedIcon),
                  label: Text(
                    item.label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 2),
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
                          extended ? 16 : 8,
                          20,
                        ),
                        child: extended
                            ? SizedBox(
                                width: sidebarWidth - 32,
                                child: OutlinedButton.icon(
                                  onPressed: onLogout,
                                  icon: const Icon(Icons.logout_rounded),
                                  label: Text(
                                    AppLocalizations.of(context)!.signOut,
                                  ),
                                  style: OutlinedButton.styleFrom(
                                    backgroundColor: Colors.transparent,
                                    foregroundColor: AppColors.white,
                                    side: const BorderSide(
                                      color: AppColors.primaryLine,
                                    ),
                                  ),
                                ),
                              )
                            : IconButton(
                                onPressed: onLogout,
                                tooltip: AppLocalizations.of(context)!.signOut,
                                icon: const Icon(Icons.logout_rounded),
                                color: AppColors.onPrimaryMuted,
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
