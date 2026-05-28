import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:balaji_points/core/design/app_colors.dart';
import 'package:balaji_points/core/design/app_typography.dart';
import 'package:balaji_points/l10n/app_localizations.dart';
import 'package:balaji_points/providers/home_provider.dart';
import 'package:balaji_points/presentation/widgets/shared/app_text.dart';
import 'package:balaji_points/presentation/widgets/shared/shimmer_loading.dart';
import 'package:balaji_points/presentation/widgets/carpenter/top_carpenters_display.dart';
import 'package:balaji_points/presentation/widgets/carpenter/top_carpenters_list.dart';

class HomeTopCarpenters extends StatelessWidget {
  final HomeState homeState;

  const HomeTopCarpenters({super.key, required this.homeState});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = isDark ? const Color(0xFF171A22) : AppColors.white;
    final top3 = homeState.topCarpenters.take(3).toList();

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.black.withValues(alpha: isDark ? 0.25 : 0.07),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: AppColors.warning.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.emoji_events_rounded,
                      size: 18, color: AppColors.warning),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text('Top Carpenters',
                      style: AppTypography.h5(color: context.themeTextPrimary)),
                ),
                GestureDetector(
                  onTap: () => context.push('/notifications'),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('View Leaderboard',
                          style: AppTypography.labelMedium(
                              color: context.themePrimary)),
                      const SizedBox(width: 4),
                      Icon(Icons.arrow_forward_rounded,
                          size: 14, color: context.themePrimary),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Podium
          if (homeState.rankingsLoading)
            const Padding(
              padding: EdgeInsets.all(24),
              child: ShimmerTopCarpenters(),
            )
          else if (top3.isNotEmpty)
            Padding(
              padding: const EdgeInsets.all(12),
              child: TopCarpentersDisplay(
                topCarpenters: top3,
                currentUser: homeState.topCarpenters
                    .cast<CarpenterRank?>()
                    .firstWhere(
                      (c) => c?.userId == homeState.userDocId,
                      orElse: () => null,
                    ),
              ),
            )
          else
            const Padding(
              padding: EdgeInsets.all(24),
              child: Center(child: AppText.muted('No ranking data yet')),
            ),

          // User position strip
          if (homeState.userRank != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 0),
              child: _UserPositionStrip(homeState: homeState),
            ),

          // Full top-10 list
          if (!homeState.rankingsLoading && homeState.topCarpenters.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
              child: TopCarpentersList(
                carpenters: homeState.topCarpenters,
                showViewAll: false,
              ),
            ),
        ],
      ),
    );
  }
}

class _UserPositionStrip extends StatelessWidget {
  final HomeState homeState;

  const _UserPositionStrip({required this.homeState});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [context.themePrimary, const Color(0xFF2D4A9E)],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.white,
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.warning, width: 2),
            ),
            child: Center(
              child: Text(
                '#${homeState.userRank}',
                style: AppTypography.labelMedium(color: context.themePrimary)
                    .copyWith(fontWeight: FontWeight.w900),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.yourPosition,
                  style: AppTypography.labelSmall(
                      color: AppColors.white.withValues(alpha: 0.75)),
                ),
                Text(
                  homeState.displayName,
                  style: AppTypography.labelLarge(color: AppColors.white),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          Row(
            children: [
              const Icon(Icons.stars_rounded,
                  color: AppColors.warning, size: 16),
              const SizedBox(width: 4),
              Text(
                '${homeState.points} pts',
                style: AppTypography.pointsSmall(color: AppColors.white),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
