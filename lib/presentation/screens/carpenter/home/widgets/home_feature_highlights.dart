import 'package:balaji_points/core/design/app_radius.dart';
import 'package:flutter/material.dart';
import 'package:balaji_points/l10n/app_localizations.dart';
import 'package:go_router/go_router.dart';

import 'package:balaji_points/core/design/app_colors.dart';
import 'package:balaji_points/core/design/app_typography.dart';

/// The screen's main action: add a bill to earn points.
class HomeAddBillCard extends StatelessWidget {
  const HomeAddBillCard({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: Material(
        color: AppColors.gold,
        borderRadius: AppRadius.all16,
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () => context.push('/add-bill'),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: AppRadius.md12,
                  ),
                  child: const Icon(
                    Icons.receipt_long_rounded,
                    color: AppColors.gold,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.addBill,
                        style: AppTypography.h5(color: AppColors.primary),
                      ),
                      Text(
                        l10n.featureEarnBody.replaceAll('\n', ' · '),
                        style: AppTypography.bodySmall(
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                const Icon(
                  Icons.arrow_forward_rounded,
                  color: AppColors.primary,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _FeatureHighlight {
  final IconData icon;
  final String label;
  final String sublabel;

  const _FeatureHighlight({
    required this.icon,
    required this.label,
    required this.sublabel,
  });
}

class HomeFeatureHighlights extends StatelessWidget {
  const HomeFeatureHighlights({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final features = [
      _FeatureHighlight(
        icon: Icons.redeem_rounded,
        label: l10n.featureRedeemMore,
        sublabel: l10n.featureRedeemBody,
      ),
      _FeatureHighlight(
        icon: Icons.leaderboard_rounded,
        label: l10n.featureGrowMore,
        sublabel: l10n.featureGrowBody,
      ),
      _FeatureHighlight(
        icon: Icons.workspace_premium_rounded,
        label: l10n.featureExclusive,
        sublabel: l10n.featureExclusiveBody,
      ),
    ];

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 14),
      decoration: BoxDecoration(
        color: context.themeCard,
        borderRadius: AppRadius.all16,
        border: Border.all(color: context.themeBorder),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (final feature in features)
            Expanded(child: _FeatureHighlightItem(feature)),
        ],
      ),
    );
  }
}

class _FeatureHighlightItem extends StatelessWidget {
  final _FeatureHighlight feature;

  const _FeatureHighlightItem(this.feature);

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: AppRadius.md12,
      onTap: () => context.push('/notifications'),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
        child: Column(
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.primary,
              ),
              child: Icon(feature.icon, size: 22, color: AppColors.gold),
            ),
            const SizedBox(height: 8),
            Text(
              feature.label,
              style: AppTypography.overline(color: context.themeContentColor),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 2),
            Text(
              feature.sublabel,
              style: AppTypography.caption(color: context.themeTextSecondary),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
