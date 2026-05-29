import 'package:balaji_points/core/design/app_colors.dart';
import 'package:balaji_points/core/design/app_typography.dart';
import 'package:balaji_points/core/layout/carpenter_shell_layout.dart';
import 'package:balaji_points/l10n/app_localizations.dart';
import 'package:flutter/material.dart';

/// Facebook-style bottom tab bar: white/dark surface, active tab highlighted
/// with a filled pill, center Add Bill button raised as a blue circle.
class CarpenterBottomNavBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTabSelected;
  final VoidCallback onAddBillTap;
  final double bottomInset;

  const CarpenterBottomNavBar({
    super.key,
    required this.currentIndex,
    required this.onTabSelected,
    required this.onAddBillTap,
    required this.bottomInset,
  });

  factory CarpenterBottomNavBar.fromContext(
    BuildContext context, {
    Key? key,
    required int currentIndex,
    required ValueChanged<int> onTabSelected,
    required VoidCallback onAddBillTap,
  }) {
    return CarpenterBottomNavBar(
      key: key,
      currentIndex: currentIndex,
      onTabSelected: onTabSelected,
      onAddBillTap: onAddBillTap,
      bottomInset: CarpenterShellLayout.bottomInset(MediaQuery.of(context)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final barBg = isDark ? const Color(0xFF141C2E) : AppColors.white;
    final topBorder = isDark
        ? AppColors.white.withValues(alpha: 0.08)
        : AppColors.black.withValues(alpha: 0.08);

    return Container(
      decoration: BoxDecoration(
        color: barBg,
        border: Border(top: BorderSide(color: topBorder, width: 1)),
        boxShadow: [
          BoxShadow(
            color: AppColors.black.withValues(alpha: isDark ? 0.30 : 0.08),
            blurRadius: 12,
            offset: const Offset(0, -3),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            height: CarpenterShellLayout.navBarHeight,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                _NavTab(
                  index: 0,
                  currentIndex: currentIndex,
                  icon: Icons.home_rounded,
                  activeIcon: Icons.home_rounded,
                  label: l10n.home,
                  onTap: onTabSelected,
                ),
                _NavTab(
                  index: 1,
                  currentIndex: currentIndex,
                  icon: Icons.account_balance_wallet_outlined,
                  activeIcon: Icons.account_balance_wallet_rounded,
                  label: l10n.earn,
                  onTap: onTabSelected,
                ),
                // Centre: Add Bill raised button
                _CenterAddButton(onTap: onAddBillTap, label: l10n.addPoints),
                _NavTab(
                  index: 2,
                  currentIndex: currentIndex,
                  icon: Icons.notifications_outlined,
                  activeIcon: Icons.notifications_rounded,
                  label: l10n.notifications,
                  onTap: onTabSelected,
                ),
                _NavTab(
                  index: 3,
                  currentIndex: currentIndex,
                  icon: Icons.person_outline_rounded,
                  activeIcon: Icons.person_rounded,
                  label: l10n.profile,
                  onTap: onTabSelected,
                ),
              ],
            ),
          ),
          if (bottomInset > 0) SizedBox(height: bottomInset),
        ],
      ),
    );
  }
}

class _NavTab extends StatelessWidget {
  final int index;
  final int currentIndex;
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final ValueChanged<int> onTap;

  const _NavTab({
    required this.index,
    required this.currentIndex,
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final selected = index == currentIndex;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final activeColor = context.themePrimary;
    final inactiveColor = isDark
        ? AppColors.white.withValues(alpha: 0.50)
        : AppColors.black.withValues(alpha: 0.45);
    final pillBg = activeColor.withValues(alpha: isDark ? 0.18 : 0.10);

    return Expanded(
      child: InkWell(
        onTap: () => onTap(index),
        splashColor: activeColor.withValues(alpha: 0.08),
        highlightColor: Colors.transparent,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Icon with active pill background
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeOut,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              decoration: BoxDecoration(
                color: selected ? pillBg : Colors.transparent,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(
                selected ? activeIcon : icon,
                size: 24,
                color: selected ? activeColor : inactiveColor,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTypography.caption(
                color: selected ? activeColor : inactiveColor,
              ).copyWith(
                fontWeight: selected ? FontWeight.w700 : FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CenterAddButton extends StatelessWidget {
  final VoidCallback onTap;
  final String label;

  const _CenterAddButton({required this.onTap, required this.label});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Raised circle — floats slightly above bar
            Transform.translate(
              offset: const Offset(0, -3),
              child: Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: context.themePrimary,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: context.themePrimary.withValues(alpha: 0.45),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: const Icon(Icons.add_rounded, color: AppColors.white, size: 28),
              ),
            ),
            // Label
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTypography.caption(
                color: context.themePrimary,
              ).copyWith(fontWeight: FontWeight.w700),
            ),
          ],
        ),
      ),
    );
  }
}
