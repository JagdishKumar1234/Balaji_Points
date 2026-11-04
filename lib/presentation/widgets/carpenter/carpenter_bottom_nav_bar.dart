import 'package:balaji_points/core/design/app_radius.dart';
import 'package:balaji_points/core/design/app_colors.dart';
import 'package:balaji_points/core/design/app_typography.dart';
import 'package:balaji_points/core/layout/carpenter_shell_layout.dart';
import 'package:balaji_points/l10n/app_localizations.dart';
import 'package:flutter/material.dart';

/// Navy tab bar with rounded top corners: the active tab is a gold pill, and
/// Add Bill is a gold button raised above the bar. Labels shrink slightly
/// rather than ever being cut.
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
    // The bar has a fixed height, so very large system text is limited here.
    return MediaQuery.withClampedTextScaling(
      maxScaleFactor: 1.15,
      child: Stack(
        children: [
          // Starts lower than the widget, leaving room for the raised button.
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
                  _NavTab(
                    index: 0,
                    currentIndex: currentIndex,
                    icon: Icons.home_outlined,
                    activeIcon: Icons.home_rounded,
                    label: l10n.home,
                    onTap: onTabSelected,
                  ),
                  _NavTab(
                    index: 1,
                    currentIndex: currentIndex,
                    icon: Icons.account_balance_wallet_outlined,
                    activeIcon: Icons.account_balance_wallet_rounded,
                    label: l10n.wallet,
                    onTap: onTabSelected,
                  ),
                  if (showAddBill)
                    _CenterAddButton(
                      onTap: onAddBillTap,
                      label: l10n.navAddBill,
                    ),
                  _NavTab(
                    index: 2,
                    currentIndex: currentIndex,
                    icon: Icons.notifications_outlined,
                    activeIcon: Icons.notifications_rounded,
                    label: l10n.navAlerts,
                    semanticLabel: l10n.notifications,
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
          ),
        ],
      ),
    );
  }
}

/// One line of tab text that scales down to fit instead of being cut.
class _NavLabel extends StatelessWidget {
  const _NavLabel(this.text, {required this.color, this.bold = false});

  final String text;
  final Color color;
  final bool bold;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 2),
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Text(
          text,
          maxLines: 1,
          style: AppTypography.navLabel(
            color: color,
          ).copyWith(fontWeight: bold ? FontWeight.w700 : FontWeight.w500),
        ),
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
  final String? semanticLabel;
  final ValueChanged<int> onTap;

  const _NavTab({
    required this.index,
    required this.currentIndex,
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.onTap,
    this.semanticLabel,
  });

  @override
  Widget build(BuildContext context) {
    final selected = index == currentIndex;

    return Expanded(
      child: Semantics(
        selected: selected,
        button: true,
        label: semanticLabel ?? label,
        excludeSemantics: true,
        // The strip above the bar belongs to the page, so taps there reach it.
        child: Padding(
          padding: const EdgeInsets.only(top: CarpenterShellLayout.navBarRaise),
          child: InkWell(
            onTap: () => onTap(index),
            splashColor: AppColors.gold.withValues(alpha: 0.14),
            highlightColor: Colors.transparent,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                AnimatedContainer(
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
                const SizedBox(height: 3),
                _NavLabel(
                  label,
                  bold: selected,
                  color: selected ? AppColors.gold : AppColors.onPrimaryMuted,
                ),
              ],
            ),
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
      child: Semantics(
        button: true,
        label: label,
        excludeSemantics: true,
        child: GestureDetector(
          onTap: onTap,
          behavior: HitTestBehavior.opaque,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              // The navy ring joins the button to the bar over any page content.
              Container(
                key: const ValueKey('nav-add-bill'),
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
              _NavLabel(label, bold: true, color: AppColors.gold),
              const SizedBox(height: 6),
            ],
          ),
        ),
      ),
    );
  }
}
