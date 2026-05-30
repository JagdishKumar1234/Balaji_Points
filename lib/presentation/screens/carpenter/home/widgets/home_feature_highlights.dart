import 'package:balaji_points/core/design/app_radius.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:balaji_points/core/design/app_colors.dart';
import 'package:balaji_points/core/design/app_typography.dart';

class _FeatureHighlight {
  final IconData icon;
  final String label;
  final String sublabel;
  final Color iconColor;
  final VoidCallback onTap;

  const _FeatureHighlight({
    required this.icon,
    required this.label,
    required this.sublabel,
    required this.iconColor,
    required this.onTap,
  });
}

class HomeFeatureHighlights extends StatelessWidget {
  const HomeFeatureHighlights({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = context.themeSurface;

    final features = [
      _FeatureHighlight(
        icon: Icons.receipt_long_rounded,
        label: 'EARN MORE',
        sublabel: 'Upload Bills\nEarn Points',
        iconColor: AppColors.warning,
        onTap: () => context.push('/add-bill'),
      ),
      _FeatureHighlight(
        icon: Icons.redeem_rounded,
        label: 'REDEEM MORE',
        sublabel: 'Exciting Rewards\n& Gifts',
        iconColor: AppColors.tierPlatinum,
        onTap: () => context.push('/notifications'),
      ),
      _FeatureHighlight(
        icon: Icons.leaderboard_rounded,
        label: 'GROW MORE',
        sublabel: 'Climb Leaderboard\nBe a Top Carpenter',
        iconColor: AppColors.warning,
        onTap: () => context.push('/notifications'),
      ),
      _FeatureHighlight(
        icon: Icons.workspace_premium_rounded,
        label: 'EXCLUSIVE',
        sublabel: 'Special Benefits\nJust for You',
        iconColor: const Color(0xFF0891B2),
        onTap: () => context.push('/notifications'),
      ),
    ];

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
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
        children: features.map((f) => _FeatureHighlightItem(f)).toList(),
      ),
    );
  }
}

class _FeatureHighlightItem extends StatelessWidget {
  final _FeatureHighlight feature;

  const _FeatureHighlightItem(this.feature);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: feature.onTap,
      child: SizedBox(
        width: 72,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: feature.iconColor.withValues(alpha: 0.12),
                border: Border.all(
                    color: feature.iconColor.withValues(alpha: 0.3), width: 1.5),
              ),
              child: Icon(feature.icon, size: 24, color: feature.iconColor),
            ),
            const SizedBox(height: 6),
            Text(
              feature.label,
              style: AppTypography.overline(color: feature.iconColor),
              textAlign: TextAlign.center,
              maxLines: 1,
            ),
            const SizedBox(height: 2),
            Text(
              feature.sublabel,
              style: AppTypography.caption(color: context.themeTextSecondary),
              textAlign: TextAlign.center,
              maxLines: 2,
            ),
          ],
        ),
      ),
    );
  }
}
