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
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.primary, AppColors.primaryLight],
        ),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.gold.withValues(alpha: 0.45)),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.30),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Stack(
        children: [
          const Positioned.fill(
            child: RepaintBoundary(child: CustomPaint(painter: _HeroArcs())),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    MemberAvatar(
                      name: homeState.displayName,
                      imageUrl: homeState.profileImage,
                      size: 58,
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
                          RoleTag(
                            label: memberRoleName(context, homeState.userData),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    _TierBadge(tier: tier),
                  ],
                ),
                const SizedBox(height: 18),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
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
                          const SizedBox(height: 2),
                          Row(
                            children: [
                              const Icon(
                                Icons.stars_rounded,
                                color: AppColors.gold,
                                size: 30,
                              ),
                              const SizedBox(width: 6),
                              // Shrinks a very large balance rather than
                              // cutting it.
                              Flexible(
                                child: FittedBox(
                                  fit: BoxFit.scaleDown,
                                  alignment: Alignment.centerLeft,
                                  child: Text(
                                    PointsUtils.formatPoints(homeState.points),
                                    maxLines: 1,
                                    style:
                                        AppTypography.h1(
                                          color: AppColors.gold,
                                        ).copyWith(
                                          fontSize: 38,
                                          fontWeight: FontWeight.w800,
                                          height: 1.1,
                                        ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    _RankMedal(label: l10n.rankShort, rank: homeState.userRank),
                  ],
                ),
                const SizedBox(height: 14),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.white.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: AppColors.white.withValues(alpha: 0.10),
                    ),
                  ),
                  child: isPlatinum
                      ? Row(
                          children: [
                            const Icon(
                              Icons.workspace_premium_rounded,
                              size: 18,
                              color: AppColors.gold,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                l10n.platinumHighestTier,
                                style: AppTypography.bodySmall(
                                  color: AppColors.goldSoft,
                                ),
                              ),
                            ),
                          ],
                        )
                      : Column(
                          children: [
                            Row(
                              children: [
                                const Icon(
                                  Icons.trending_up_rounded,
                                  size: 16,
                                  color: AppColors.gold,
                                ),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Text(
                                    l10n.ptsToNextLabel(
                                      PointsUtils.formatPoints(pointsToNext),
                                      _tierNextLabel(tier),
                                    ),
                                    style: AppTypography.bodySmall(
                                      color: AppColors.white,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  '${(progress * 100).toStringAsFixed(0)}%',
                                  style: AppTypography.labelMedium(
                                    color: AppColors.gold,
                                  ).copyWith(fontWeight: FontWeight.w700),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            _TierProgressBar(progress: progress),
                          ],
                        ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Soft gold arcs in the top-right corner, drawn rather than loaded as an image.
class _HeroArcs extends CustomPainter {
  const _HeroArcs();

  @override
  void paint(Canvas canvas, Size size) {
    final centre = Offset(size.width + 6, -6);
    final stroke = Paint()
      ..style = PaintingStyle.stroke
      ..color = AppColors.gold.withValues(alpha: 0.13);
    for (final (radius, width) in [(70.0, 14.0), (112.0, 8.0), (150.0, 3.0)]) {
      canvas.drawCircle(centre, radius, stroke..strokeWidth = width);
    }
    canvas.drawCircle(
      Offset(-20, size.height + 10),
      90,
      Paint()..color = AppColors.white.withValues(alpha: 0.035),
    );
  }

  @override
  bool shouldRepaint(_HeroArcs oldDelegate) => false;
}

class _RankMedal extends StatelessWidget {
  const _RankMedal({required this.label, required this.rank});

  final String label;
  final int? rank;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minWidth: 68, minHeight: 68),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: AppColors.white.withValues(alpha: 0.08),
        border: Border.all(color: AppColors.gold, width: 1.5),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            rank != null ? '#$rank' : '—',
            style: AppTypography.h5(color: AppColors.white),
          ),
          Text(
            label,
            style: AppTypography.caption(color: AppColors.onPrimaryMuted),
          ),
        ],
      ),
    );
  }
}

/// Gold gradient bar, with a soft glow so it stands out on the navy.
class _TierProgressBar extends StatelessWidget {
  const _TierProgressBar({required this.progress});

  final double progress;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      value: '${(progress * 100).round()}%',
      child: Container(
        height: 8,
        decoration: BoxDecoration(
          color: AppColors.white.withValues(alpha: 0.16),
          borderRadius: AppRadius.pill,
        ),
        alignment: Alignment.centerLeft,
        child: FractionallySizedBox(
          widthFactor: progress,
          heightFactor: 1,
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppColors.gold, AppColors.goldSoft],
              ),
              borderRadius: AppRadius.pill,
              boxShadow: [
                BoxShadow(
                  color: AppColors.gold.withValues(alpha: 0.5),
                  blurRadius: 6,
                ),
              ],
            ),
          ),
        ),
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
      height: 252,
      decoration: BoxDecoration(
        color: context.themeSoftSurface,
        borderRadius: BorderRadius.circular(22),
      ),
    ).animate(onPlay: (c) => c.repeat()).shimmer(duration: 1200.ms);
  }
}
