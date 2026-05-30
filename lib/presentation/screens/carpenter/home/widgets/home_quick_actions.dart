import 'package:balaji_points/core/design/app_radius.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:balaji_points/core/design/app_colors.dart';
import 'package:balaji_points/core/design/app_typography.dart';

class _QuickAction {
  final IconData icon;
  final String label;
  final String sublabel;
  final Color color;
  final VoidCallback onTap;

  const _QuickAction({
    required this.icon,
    required this.label,
    required this.sublabel,
    required this.color,
    required this.onTap,
  });
}

class HomeQuickActions extends StatelessWidget {
  const HomeQuickActions({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = context.themeSurface;

    final actions = [
      _QuickAction(
        icon: Icons.receipt_long_rounded,
        label: 'Add Bill',
        sublabel: 'Upload & Earn',
        color: const Color(0xFF2563EB),
        onTap: () => context.push('/add-bill'),
      ),
      _QuickAction(
        icon: Icons.account_balance_wallet_rounded,
        label: 'Wallet',
        sublabel: 'My Points',
        color: AppColors.gold,
        onTap: () => context.go('/wallet'),
      ),
      _QuickAction(
        icon: Icons.redeem_rounded,
        label: 'Rewards',
        sublabel: 'Redeem Now',
        color: AppColors.tierPlatinum,
        onTap: () => context.push('/notifications'),
      ),
      _QuickAction(
        icon: Icons.history_rounded,
        label: 'History',
        sublabel: 'My Activity',
        color: const Color(0xFF0891B2),
        onTap: () => context.push('/orders'),
      ),
      _QuickAction(
        icon: Icons.leaderboard_rounded,
        label: 'Leaderboard',
        sublabel: 'Top Carpenters',
        color: AppColors.success,
        onTap: () => context.push('/notifications'),
      ),
    ];

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: AppRadius.all16,
        boxShadow: [
          BoxShadow(
            color: AppColors.black.withValues(alpha: isDark ? 0.25 : 0.07),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: actions
            .map((a) => _QuickActionItem(action: a, isDark: isDark))
            .toList(),
      ),
    );
  }
}

class _QuickActionItem extends StatelessWidget {
  final _QuickAction action;
  final bool isDark;

  const _QuickActionItem({required this.action, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: action.onTap,
      child: SizedBox(
        width: 60,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: action.color.withValues(alpha: isDark ? 0.22 : 0.12),
                borderRadius: AppRadius.all16,
              ),
              child: Icon(action.icon, size: 26, color: action.color),
            ),
            const SizedBox(height: 6),
            Text(
              action.label,
              style: AppTypography.labelMedium(color: context.themeTextPrimary),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            Text(
              action.sublabel,
              style: AppTypography.caption(color: context.themeTextSecondary),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
