import 'package:balaji_points/core/layout/carpenter_shell_layout.dart';
import 'package:balaji_points/core/theme/design_token.dart';
import 'package:balaji_points/l10n/app_localizations.dart';
import 'package:flutter/material.dart';

/// Simple flat bottom tab bar (primary) with bottom safe-area fill.
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
    const barColor = DesignToken.primary;

    return Material(
      color: barColor,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            height: CarpenterShellLayout.navBarHeight,
            child: Row(
              children: [
                _Tab(
                  index: 0,
                  currentIndex: currentIndex,
                  icon: Icons.home_rounded,
                  label: l10n.home,
                  onTap: onTabSelected,
                ),
                _Tab(
                  index: 1,
                  currentIndex: currentIndex,
                  icon: Icons.account_balance_wallet_outlined,
                  label: l10n.earn,
                  onTap: onTabSelected,
                ),
                _CenterAddButton(onTap: onAddBillTap),
                _Tab(
                  index: 2,
                  currentIndex: currentIndex,
                  icon: Icons.notifications_outlined,
                  label: l10n.notifications,
                  onTap: onTabSelected,
                ),
                _Tab(
                  index: 3,
                  currentIndex: currentIndex,
                  icon: Icons.person_outline,
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

class _Tab extends StatelessWidget {
  final int index;
  final int currentIndex;
  final IconData icon;
  final String label;
  final ValueChanged<int> onTap;

  const _Tab({
    required this.index,
    required this.currentIndex,
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final selected = index == currentIndex;
    final color = selected
        ? DesignToken.white
        : DesignToken.white.withValues(alpha: 0.55);

    return Expanded(
      child: InkWell(
        onTap: () => onTap(index),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 22, color: color),
            const SizedBox(height: 2),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 10,
                fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                color: color,
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

  const _CenterAddButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Expanded(
      child: InkWell(
        onTap: onTap,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: DesignToken.secondary,
                shape: BoxShape.circle,
                border: Border.all(color: DesignToken.white, width: 2),
              ),
              child: const Icon(
                Icons.add,
                color: DesignToken.white,
                size: 22,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              l10n.addPoints,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.w600,
                color: DesignToken.white.withValues(alpha: 0.9),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
