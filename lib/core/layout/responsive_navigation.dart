import 'package:flutter/material.dart';
import 'package:balaji_points/core/layout/responsive.dart';

/// Determines navigation layout based on device size
enum NavigationLayout {
  /// Mobile: drawer only, no bottom nav
  mobileDrawer,

  /// Tablet: side panel + content
  tabletSidePanel,

  /// Desktop: side panel + content (wider)
  desktopSidePanel,
}

/// Get navigation layout for current screen size
NavigationLayout getNavigationLayout(BuildContext context) {
  final deviceType = context.deviceType;
  switch (deviceType) {
    case DeviceType.mobile:
      return NavigationLayout.mobileDrawer;
    case DeviceType.tablet:
      return NavigationLayout.tabletSidePanel;
    case DeviceType.desktop:
    case DeviceType.largeDesktop:
      return NavigationLayout.desktopSidePanel;
  }
}

/// Responsive side panel width based on device
double getSidePanelWidth(BuildContext context) {
  final deviceType = context.deviceType;
  switch (deviceType) {
    case DeviceType.tablet:
      return 280; // Tablet side panel
    case DeviceType.desktop:
      return 320; // Desktop side panel
    case DeviceType.largeDesktop:
      return 360; // Large desktop side panel
    default:
      return 0; // Mobile has no side panel
  }
}

/// Responsive bottom nav height (when used)
double getBottomNavHeight(BuildContext context) {
  return 64; // Standard bottom nav height
}

/// Check if device should show side panel
bool shouldShowSidePanel(BuildContext context) {
  return context.isTablet || context.isDesktop;
}

/// Check if device should show drawer (mobile)
bool shouldShowDrawer(BuildContext context) {
  return context.isMobile;
}

/// Check if device should show bottom navigation
bool shouldShowBottomNav(BuildContext context) {
  // Only mobile uses bottom nav (optional)
  return false; // Currently using drawer for all mobile nav
}

/// Responsive navigation shell that adapts to device size
class ResponsiveNavigationShell extends StatelessWidget {
  final Widget? sidePanel;
  final Widget body;
  final Widget? appBar;
  final Widget? drawer;
  final Color? backgroundColor;
  final EdgeInsets? bodyPadding;

  const ResponsiveNavigationShell({
    super.key,
    this.sidePanel,
    required this.body,
    this.appBar,
    this.drawer,
    this.backgroundColor,
    this.bodyPadding,
  });

  @override
  Widget build(BuildContext context) {
    final navigationLayout = getNavigationLayout(context);
    final sidePanelWidth = getSidePanelWidth(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = backgroundColor ?? Theme.of(context).scaffoldBackgroundColor;

    // Mobile: Drawer only
    if (navigationLayout == NavigationLayout.mobileDrawer) {
      return Scaffold(
        backgroundColor: bgColor,
        appBar: appBar != null ? _wrapAppBar(appBar!) : null,
        drawer: drawer,
        body: Padding(
          padding: bodyPadding ?? EdgeInsets.zero,
          child: body,
        ),
      );
    }

    // Tablet/Desktop: Side panel + content
    return Scaffold(
      backgroundColor: bgColor,
      body: Row(
        children: [
          // Side panel
          if (sidePanel != null)
            SizedBox(
              width: sidePanelWidth,
              child: sidePanel!,
            ),

          // Divider
          if (sidePanel != null)
            VerticalDivider(
              width: 1,
              thickness: 1,
              color: isDark
                  ? Colors.white.withValues(alpha: 0.08)
                  : Colors.black.withValues(alpha: 0.08),
            ),

          // Main content
          Expanded(
            child: Column(
              children: [
                if (appBar != null) _wrapAppBar(appBar!),
                Expanded(
                  child: Padding(
                    padding: bodyPadding ?? EdgeInsets.zero,
                    child: body,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  PreferredSizeWidget _wrapAppBar(Widget appBar) {
    if (appBar is PreferredSizeWidget) {
      return appBar;
    }
    // Fallback: wrap in container with standard height
    return PreferredSize(
      preferredSize: const Size.fromHeight(56),
      child: appBar,
    );
  }
}

/// Side panel widget for tablet/desktop navigation
class ResponsiveSidePanel extends StatelessWidget {
  final List<NavigationItem> items;
  final int selectedIndex;
  final ValueChanged<int> onItemSelected;
  final Widget? header;
  final Widget? footer;
  final ScrollController? scrollController;

  const ResponsiveSidePanel({
    super.key,
    required this.items,
    required this.selectedIndex,
    required this.onItemSelected,
    this.header,
    this.footer,
    this.scrollController,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Header (logo, app name)
        if (header != null)
          Padding(
            padding: const EdgeInsets.all(16),
            child: header!,
          ),

        // Navigation items
        Expanded(
          child: ListView(
            controller: scrollController,
            padding: const EdgeInsets.symmetric(vertical: 8),
            children: [
              for (int i = 0; i < items.length; i++)
                _buildNavItem(
                  context,
                  items[i],
                  i,
                  isSelected: i == selectedIndex,
                  onTap: () => onItemSelected(i),
                ),
            ],
          ),
        ),

        // Footer (logout, settings)
        if (footer != null)
          Padding(
            padding: const EdgeInsets.all(16),
            child: footer!,
          ),
      ],
    );
  }

  Widget _buildNavItem(
    BuildContext context,
    NavigationItem item,
    int index, {
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);
    final primaryColor = theme.primaryColor;
    final textColor = theme.textTheme.bodyMedium?.color ?? Colors.black;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(8),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            decoration: BoxDecoration(
              color: isSelected
                  ? primaryColor.withValues(alpha: 0.12)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(8),
              border: isSelected
                  ? Border.all(
                      color: primaryColor.withValues(alpha: 0.3),
                      width: 1,
                    )
                  : null,
            ),
            child: Row(
              children: [
                Icon(
                  item.icon,
                  color: isSelected ? primaryColor : textColor.withValues(alpha: 0.6),
                  size: 24,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                          color: isSelected ? primaryColor : textColor,
                        ),
                      ),
                      if (item.subtitle != null)
                        Text(
                          item.subtitle!,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 12,
                            color: textColor.withValues(alpha: 0.5),
                          ),
                        ),
                    ],
                  ),
                ),
                if (item.badge != null)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: primaryColor.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      item.badge!,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: primaryColor,
                      ),
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

/// Navigation item model
class NavigationItem {
  final String label;
  final IconData icon;
  final String? subtitle;
  final String? badge;
  final String? route;

  const NavigationItem({
    required this.label,
    required this.icon,
    this.subtitle,
    this.badge,
    this.route,
  });
}
