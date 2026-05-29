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

// ---------------------------------------------------------------------------
// Podium + top-10 list card  (no winner / position strips inside anymore)
// ---------------------------------------------------------------------------

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
                      Text('Leaderboard',
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
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
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

          // Full top-10 list
          if (!homeState.rankingsLoading && homeState.topCarpenters.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
              child: TopCarpentersList(
                carpenters: homeState.topCarpenters,
                showViewAll: false,
              ),
            )
          else
            const SizedBox(height: 12),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// TODAY'S WINNER  — standalone card for home page
// ---------------------------------------------------------------------------

class HomeTodaysWinnerCard extends StatelessWidget {
  final HomeState homeState;
  const HomeTodaysWinnerCard({super.key, required this.homeState});

  @override
  Widget build(BuildContext context) {
    if (homeState.rankingsLoading || homeState.topCarpenters.isEmpty) {
      return const SizedBox.shrink();
    }

    final winner = homeState.topCarpenters.first;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDark
              ? [const Color(0xFF2A1F00), const Color(0xFF1A1400)]
              : [const Color(0xFFFFFBEB), const Color(0xFFFEF3C7)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppColors.warning.withValues(alpha: isDark ? 0.45 : 0.35),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.warning.withValues(alpha: isDark ? 0.15 : 0.12),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            // Trophy + rank bubble
            Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: AppColors.warning.withValues(alpha: 0.18),
                    shape: BoxShape.circle,
                    border: Border.all(
                        color: AppColors.warning.withValues(alpha: 0.40),
                        width: 2),
                  ),
                  child: const Icon(Icons.emoji_events_rounded,
                      color: AppColors.warning, size: 30),
                ),
                Positioned(
                  bottom: -4,
                  right: -4,
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.warning,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text('#1',
                        style: AppTypography.labelSmall(color: AppColors.white)
                            .copyWith(fontWeight: FontWeight.w900)),
                  ),
                ),
              ],
            ),

            const SizedBox(width: 14),

            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Today's Winner",
                    style: AppTypography.overline(color: AppColors.warning)
                        .copyWith(letterSpacing: 0.8),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    winner.name,
                    style: AppTypography.h5(color: context.themeTextPrimary),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.stars_rounded,
                          color: AppColors.warning, size: 14),
                      const SizedBox(width: 4),
                      Text(
                        '${winner.points} pts',
                        style:
                            AppTypography.labelMedium(color: AppColors.warning),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Crown icon
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.warning.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.workspace_premium_rounded,
                  color: AppColors.warning, size: 24),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// YOUR POSITION  — standalone card for home page
// ---------------------------------------------------------------------------

class HomeYourPositionCard extends StatelessWidget {
  final HomeState homeState;
  const HomeYourPositionCard({super.key, required this.homeState});

  @override
  Widget build(BuildContext context) {
    if (homeState.userRank == null) return const SizedBox.shrink();

    final l10n = AppLocalizations.of(context)!;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Find current user's entry for points display
    final userEntry = homeState.topCarpenters
        .cast<CarpenterRank?>()
        .firstWhere((c) => c?.userId == homeState.userDocId,
            orElse: () => null);
    final pts = userEntry?.points ?? homeState.points;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDark
              ? [const Color(0xFF0D1A3A), const Color(0xFF091226)]
              : [const Color(0xFF1D2B6B), const Color(0xFF2D4A9E)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: context.themePrimary.withValues(alpha: isDark ? 0.25 : 0.30),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            // Rank badge
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: AppColors.white.withValues(alpha: 0.12),
                shape: BoxShape.circle,
                border: Border.all(
                    color: AppColors.warning.withValues(alpha: 0.6), width: 2),
              ),
              child: Center(
                child: Text(
                  '#${homeState.userRank}',
                  style: AppTypography.h5(color: AppColors.white)
                      .copyWith(fontWeight: FontWeight.w900),
                ),
              ),
            ),

            const SizedBox(width: 14),

            // Name + label
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.yourPosition,
                    style: AppTypography.overline(
                            color: AppColors.white.withValues(alpha: 0.65))
                        .copyWith(letterSpacing: 0.8),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    homeState.displayName,
                    style: AppTypography.h5(color: AppColors.white),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.stars_rounded,
                          color: AppColors.warning, size: 14),
                      const SizedBox(width: 4),
                      Text(
                        '$pts pts',
                        style: AppTypography.labelMedium(color: AppColors.white),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Leaderboard icon button
            GestureDetector(
              onTap: () => context.push('/notifications'),
              child: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.white.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.leaderboard_rounded,
                    color: AppColors.white, size: 22),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
