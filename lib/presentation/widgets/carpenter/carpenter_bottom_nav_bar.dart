import 'package:balaji_points/core/design/app_radius.dart';
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
  final bool showAddBill;

  const CarpenterBottomNavBar({
    super.key,
    required this.currentIndex,
    required this.onTabSelected,
    required this.onAddBillTap,
    required this.bottomInset,
    this.showAddBill = true,
  });

  factory CarpenterBottomNavBar.fromContext(
    BuildContext context, {
    Key? key,
    required int currentIndex,
    required ValueChanged<int> onTabSelected,
    required VoidCallback onAddBillTap,
    bool showAddBill = true,
  }) {
    return CarpenterBottomNavBar(
      key: key,
      currentIndex: currentIndex,
      onTabSelected: onTabSelected,
      onAddBillTap: onAddBillTap,
      bottomInset: CarpenterShellLayout.bottomInset(MediaQuery.of(context)),
      showAddBill: showAddBill,
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      decoration: BoxDecoration(
        color: context.themeChrome,
        border: Border(top: BorderSide(color: context.themeBorder, width: 1)),
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
                if (showAddBill)
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
    // Spec: active = brand ink on gold-soft pill, inactive = secondary text.
    final activeColor = context.themeContentColor;
    final inactiveColor = context.themeTextSecondary;
    final pillBg = context.themePendingSoft;

    return Expanded(
      child: Semantics(
        selected: selected,
        button: true,
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
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: selected ? pillBg : Colors.transparent,
                  borderRadius: AppRadius.md12,
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
                style: AppTypography.navLabel(
                  color: selected ? activeColor : inactiveColor,
                ),
              ),
            ],
          ),
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
        // Semantics label comes from the visible text below.
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Raised circle — floats slightly above bar
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                // Main action — gold with navy glyph (spec CTA colours).
                color: AppColors.gold,
                shape: BoxShape.circle,
                boxShadow: AppColors.shadowLevel2,
              ),
              child: const Icon(
                Icons.add_rounded,
                color: AppColors.primary,
                size: 24,
              ),
            ),
            const SizedBox(height: 1),
            // Label
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTypography.navLabel(color: context.themeContentColor),
            ),
          ],
        ),
      ),
    );
  }
}
