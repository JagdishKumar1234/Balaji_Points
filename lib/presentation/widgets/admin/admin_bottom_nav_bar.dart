import 'package:balaji_points/core/design/app_colors.dart';
import 'package:balaji_points/core/design/app_radius.dart';
import 'package:balaji_points/core/design/app_typography.dart';
import 'package:balaji_points/core/layout/carpenter_shell_layout.dart';
import 'package:balaji_points/l10n/app_localizations.dart';
import 'package:flutter/material.dart';

/// Admin tabs, in bar order (Add Bill sits between Bills and Members).
enum AdminTab { home, bills, members, more }

/// Admin bottom bar, matching the member bar: navy with rounded top
/// corners, the active tab as a gold pill, Add Bill as a raised gold
/// button. Tabs show a gold count badge when something is waiting.
class AdminBottomNavBar extends StatelessWidget {
  const AdminBottomNavBar({
    super.key,
    required this.current,
    required this.onTab,
    required this.onAddBill,
    this.billsBadge = 0,
    this.membersBadge = 0,
    this.moreBadge = 0,
  });

  /// Selected tab, or null when a screen from More is open.
  final AdminTab? current;
  final ValueChanged<AdminTab> onTab;
  final VoidCallback onAddBill;
  final int billsBadge;
  final int membersBadge;
  final int moreBadge;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final bottomInset = CarpenterShellLayout.bottomInset(
      MediaQuery.of(context),
    );
    return MediaQuery.withClampedTextScaling(
      maxScaleFactor: 1.15,
      child: SizedBox(
        height: CarpenterShellLayout.navBarHeight + bottomInset,
        child: Stack(
          children: [
            Positioned.fill(
              top: CarpenterShellLayout.navBarRaise,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [AppColors.primaryLight, AppColors.primary],
                  ),
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(22),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.28),
                      blurRadius: 16,
                      offset: const Offset(0, -4),
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.only(bottom: bottomInset),
              child: SizedBox(
                height: CarpenterShellLayout.navBarHeight,
                child: Row(
                  children: [
                    _Tab(
                      tab: AdminTab.home,
                      current: current,
                      icon: Icons.dashboard_outlined,
                      activeIcon: Icons.dashboard_rounded,
                      label: l10n.home,
                      onTap: onTab,
                    ),
                    _Tab(
                      tab: AdminTab.bills,
                      current: current,
                      icon: Icons.receipt_long_outlined,
                      activeIcon: Icons.receipt_long_rounded,
                      label: l10n.adminTabBills,
                      badge: billsBadge,
                      onTap: onTab,
                    ),
                    _AddBillButton(onTap: onAddBill, label: l10n.navAddBill),
                    _Tab(
                      tab: AdminTab.members,
                      current: current,
                      icon: Icons.people_outline_rounded,
                      activeIcon: Icons.people_rounded,
                      label: l10n.adminStatMembers,
                      badge: membersBadge,
                      onTap: onTab,
                    ),
                    _Tab(
                      tab: AdminTab.more,
                      current: current,
                      icon: Icons.grid_view_outlined,
                      activeIcon: Icons.grid_view_rounded,
                      label: l10n.navMore,
                      badge: moreBadge,
                      onTap: onTab,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Tab extends StatelessWidget {
  const _Tab({
    required this.tab,
    required this.current,
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.onTap,
    this.badge = 0,
  });

  final AdminTab tab;
  final AdminTab? current;
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final int badge;
  final ValueChanged<AdminTab> onTap;

  @override
  Widget build(BuildContext context) {
    final selected = tab == current;
    return Expanded(
      child: Semantics(
        selected: selected,
        button: true,
        label: badge > 0 ? '$label, $badge' : label,
        excludeSemantics: true,
        child: Padding(
          padding: const EdgeInsets.only(top: CarpenterShellLayout.navBarRaise),
          child: InkWell(
            key: ValueKey('admin-tab-${tab.name}'),
            onTap: () => onTap(tab),
            splashColor: AppColors.gold.withValues(alpha: 0.14),
            highlightColor: Colors.transparent,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Badge(
                  isLabelVisible: badge > 0,
                  backgroundColor: AppColors.gold,
                  textColor: AppColors.primary,
                  label: Text(badge > 99 ? '99+' : '$badge'),
                  offset: const Offset(6, -4),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    curve: Curves.easeOut,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: selected ? AppColors.gold : Colors.transparent,
                      borderRadius: AppRadius.pill,
                    ),
                    child: Icon(
                      selected ? activeIcon : icon,
                      size: 22,
                      color: selected
                          ? AppColors.primary
                          : AppColors.onPrimaryMuted,
                    ),
                  ),
                ),
                const SizedBox(height: 3),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 2),
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      label,
                      maxLines: 1,
                      style:
                          AppTypography.navLabel(
                            color: selected
                                ? AppColors.gold
                                : AppColors.onPrimaryMuted,
                          ).copyWith(
                            fontWeight: selected
                                ? FontWeight.w700
                                : FontWeight.w500,
                          ),
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

class _AddBillButton extends StatelessWidget {
  const _AddBillButton({required this.onTap, required this.label});
  final VoidCallback onTap;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Semantics(
        button: true,
        label: label,
        excludeSemantics: true,
        child: GestureDetector(
          key: const ValueKey('admin-nav-add-bill'),
          onTap: onTap,
          behavior: HitTestBehavior.opaque,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: AppColors.gold,
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.primary, width: 3),
                ),
                child: const Icon(
                  Icons.add_rounded,
                  color: AppColors.primary,
                  size: 28,
                ),
              ),
              const SizedBox(height: 1),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 2),
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    label,
                    maxLines: 1,
                    style: AppTypography.navLabel(
                      color: AppColors.gold,
                    ).copyWith(fontWeight: FontWeight.w700),
                  ),
                ),
              ),
              const SizedBox(height: 6),
            ],
          ),
        ),
      ),
    );
  }
}
