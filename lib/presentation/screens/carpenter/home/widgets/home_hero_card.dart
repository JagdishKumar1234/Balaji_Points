import 'package:balaji_points/core/design/app_radius.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import 'package:balaji_points/core/design/app_colors.dart';
import 'package:balaji_points/core/design/app_typography.dart';
import 'package:balaji_points/core/utils/points_utils.dart';
import 'package:balaji_points/l10n/app_localizations.dart';
import 'package:balaji_points/presentation/widgets/carpenter/member_identity.dart';
import 'package:balaji_points/providers/home_provider.dart';

// ---------------------------------------------------------------------------
// Tier helpers
// ---------------------------------------------------------------------------

int _tierNextThreshold(String tier) {
  switch (tier) {
    case 'Silver':
      return 5000;
    case 'Gold':
      return 10000;
    case 'Platinum':
      return 10000;
    default:
      return 2000;
  }
}

int _tierCurrentThreshold(String tier) {
  switch (tier) {
    case 'Silver':
      return 2000;
    case 'Gold':
      return 5000;
    case 'Platinum':
      return 10000;
    default:
      return 0;
  }
}

String _tierNextLabel(String tier) {
  switch (tier) {
    case 'Bronze':
      return 'Silver';
    case 'Silver':
      return 'Gold';
    case 'Gold':
      return 'Platinum';
    default:
      return 'Max';
  }
}

// ---------------------------------------------------------------------------
// HomeHeroCard
// ---------------------------------------------------------------------------

/// The member's greeting, points and tier progress. Painted with a gradient
/// rather than a photo, so there is no image to decode before it appears.
class HomeHeroCard extends StatelessWidget {
  final HomeState homeState;

  const HomeHeroCard({super.key, required this.homeState});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final hour = DateTime.now().hour;
    final greeting = hour < 12
        ? l10n.goodMorningGreeting
        : (hour < 17 ? l10n.goodAfternoonGreeting : l10n.goodEveningGreeting);

    final tier = homeState.tier;
    final currentThreshold = _tierCurrentThreshold(tier);
    final nextThreshold = _tierNextThreshold(tier);
    final isPlatinum = tier == 'Platinum';
    final progress = isPlatinum
        ? 1.0
        : ((homeState.points - currentThreshold) /
                  (nextThreshold - currentThreshold))
              .clamp(0.0, 1.0);
    final pointsToNext = isPlatinum
        ? 0
        : (nextThreshold - homeState.points).clamp(0, nextThreshold);

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 10, 16, 0),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.primary, AppColors.primaryLight],
        ),
        borderRadius: AppRadius.all16,
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.25),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              MemberAvatar(
                name: homeState.displayName,
                imageUrl: homeState.profileImage,
                size: 56,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      greeting,
                      style: AppTypography.caption(
                        color: AppColors.onPrimaryMuted,
                      ),
                    ),
                    Text(
                      homeState.displayName,
                      style: AppTypography.h5(color: AppColors.white),
                    ),
                    const SizedBox(height: 6),
                    RoleTag(label: memberRoleName(context, homeState.userData)),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              _TierBadge(tier: tier),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.totalPoints,
                      style: AppTypography.caption(
                        color: AppColors.onPrimaryMuted,
                      ),
                    ),
                    // Shrinks a very large balance rather than cutting it.
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Text(
                        PointsUtils.formatPoints(homeState.points),
                        maxLines: 1,
                        style: AppTypography.h1(color: AppColors.gold),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    l10n.rankShort,
                    style: AppTypography.caption(
                      color: AppColors.onPrimaryMuted,
                    ),
                  ),
                  Text(
                    homeState.userRank != null ? '#${homeState.userRank}' : '—',
                    style: AppTypography.h4(color: AppColors.white),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (isPlatinum)
            Row(
              children: [
                const Icon(
                  Icons.workspace_premium_rounded,
                  size: 16,
                  color: AppColors.gold,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    l10n.platinumHighestTier,
                    style: AppTypography.caption(color: AppColors.goldSoft),
                  ),
                ),
              ],
            )
          else ...[
            Row(
              children: [
                Expanded(
                  child: Text(
                    l10n.ptsToNextLabel(
                      PointsUtils.formatPoints(pointsToNext),
                      _tierNextLabel(tier),
                    ),
                    style: AppTypography.caption(
                      color: AppColors.onPrimaryMuted,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '${(progress * 100).toStringAsFixed(0)}%',
                  style: AppTypography.caption(color: AppColors.goldSoft),
                ),
              ],
            ),
            const SizedBox(height: 6),
            ClipRRect(
              borderRadius: AppRadius.pill,
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 6,
                backgroundColor: AppColors.white.withValues(alpha: 0.16),
                valueColor: const AlwaysStoppedAnimation<Color>(AppColors.gold),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _TierBadge extends StatelessWidget {
  const _TierBadge({required this.tier});

  final String tier;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.gold,
        borderRadius: AppRadius.pill,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.star_rounded, size: 14, color: AppColors.primary),
          const SizedBox(width: 3),
          Text(tier, style: AppTypography.caption(color: AppColors.primary)),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Shimmer placeholder
// ---------------------------------------------------------------------------

class HomeHeroCardShimmer extends StatelessWidget {
  const HomeHeroCardShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 10, 16, 0),
      height: 216,
      decoration: BoxDecoration(
        color: context.themeSoftSurface,
        borderRadius: AppRadius.all16,
      ),
    ).animate(onPlay: (c) => c.repeat()).shimmer(duration: 1200.ms);
  }
}
