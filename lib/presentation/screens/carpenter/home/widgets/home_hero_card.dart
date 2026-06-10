import 'package:balaji_points/core/design/app_radius.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';

import 'package:balaji_points/core/design/app_colors.dart';
import 'package:balaji_points/core/design/app_typography.dart';
import 'package:balaji_points/l10n/app_localizations.dart';
import 'package:balaji_points/presentation/widgets/shared/app_text.dart';
import 'package:balaji_points/providers/home_provider.dart';

// ---------------------------------------------------------------------------
// Tier helpers
// ---------------------------------------------------------------------------

int _tierNextThreshold(String tier) {
  switch (tier) {
    case 'Silver':  return 5000;
    case 'Gold':    return 10000;
    case 'Platinum': return 10000;
    default:        return 2000;
  }
}

int _tierCurrentThreshold(String tier) {
  switch (tier) {
    case 'Silver':  return 2000;
    case 'Gold':    return 5000;
    case 'Platinum': return 10000;
    default:        return 0;
  }
}

String _tierNextLabel(String tier) {
  switch (tier) {
    case 'Bronze':  return 'Silver';
    case 'Silver':  return 'Gold';
    case 'Gold':    return 'Platinum';
    default:        return 'Max';
  }
}

Color _tierColor(String tier) {
  switch (tier) {
    case 'Silver':  return AppColors.tierSilver;
    case 'Gold':    return AppColors.warning;
    case 'Platinum': return AppColors.tierPlatinum;
    default:        return AppColors.tierBronze; // Bronze
  }
}

int _imageCacheWidthPx(BuildContext context, double logicalWidth) {
  final dpr = MediaQuery.devicePixelRatioOf(context);
  return (logicalWidth * dpr).round().clamp(120, 2048);
}

// ---------------------------------------------------------------------------
// HomeHeroCard
// ---------------------------------------------------------------------------

class HomeHeroCard extends StatelessWidget {
  final HomeState homeState;
  static const double _cardHeight = 190;

  const HomeHeroCard({super.key, required this.homeState});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final hour = DateTime.now().hour;
    final greeting = hour < 12
        ? l10n.goodMorningGreeting
        : (hour < 17 ? l10n.goodAfternoonGreeting : l10n.goodEveningGreeting);

    final profileImage = homeState.profileImage;
    final hasValidImage = profileImage != null &&
        (profileImage.startsWith('http://') ||
            profileImage.startsWith('https://'));
    final nf = NumberFormat.decimalPattern();
    final tier = homeState.tier;
    final tierColor = _tierColor(tier);
    final currentThreshold = _tierCurrentThreshold(tier);
    final nextThreshold = _tierNextThreshold(tier);
    final nextLabel = _tierNextLabel(tier);
    final isPlatinum = tier == 'Platinum';

    final progress = isPlatinum
        ? 1.0
        : ((homeState.points - currentThreshold) /
                (nextThreshold - currentThreshold))
            .clamp(0.0, 1.0);
    final pointsToNext = isPlatinum
        ? 0
        : (nextThreshold - homeState.points).clamp(0, nextThreshold);

    final bannerAsset = isDark
        ? 'assets/images/furniture/banner_dark_color.png'
        : 'assets/images/furniture/banner_light_color.png';

    // Overlay colours — semi-transparent so image shows through
    final overlayStart = isDark
        ? const Color(0xFF0D1520).withValues(alpha: 0.55)
        : const Color(0xFFFFFFFF).withValues(alpha: 0.45);
    final overlayEnd = isDark
        ? const Color(0xFF0D1520).withValues(alpha: 0.20)
        : const Color(0xFFFFFFFF).withValues(alpha: 0.10);

    final textPrimary = isDark ? AppColors.white : const Color(0xFF0D1520);
    final textSecondary = isDark
        ? AppColors.white.withValues(alpha: 0.70)
        : const Color(0xFF0D1520).withValues(alpha: 0.55);
    final dividerColor = isDark
        ? AppColors.white.withValues(alpha: 0.18)
        : AppColors.black.withValues(alpha: 0.10);
    // Stats bar at bottom — frosted transparent
    final statsOverlayBg = isDark
        ? AppColors.black.withValues(alpha: 0.35)
        : AppColors.white.withValues(alpha: 0.55);
    final progressBg = isDark
        ? AppColors.white.withValues(alpha: 0.20)
        : AppColors.black.withValues(alpha: 0.12);

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      height: _cardHeight,
      decoration: BoxDecoration(
        borderRadius: AppRadius.all16,
        boxShadow: [
          BoxShadow(
            color: AppColors.black.withValues(alpha: isDark ? 0.35 : 0.12),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: AppRadius.all16,
        child: Stack(
          fit: StackFit.expand,
          children: [
            // ── 1. Full-width background image ──────────────────────────────
            Image.asset(
              bannerAsset,
              fit: BoxFit.cover,
              cacheWidth: _imageCacheWidthPx(context, 400),
              errorBuilder: (_, __, ___) => Container(color: context.themePrimary),
            ),

            // ── 2. Subtle left-side gradient for text readability ───────────
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                  colors: [overlayStart, overlayEnd],
                  stops: const [0.0, 1.0],
                ),
              ),
            ),

            // ── 3. Main content ─────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 14, 14, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Avatar + greeting + name row
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // Avatar
                      Container(
                        width: 52,
                        height: 52,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: tierColor, width: 2.5),
                          color: isDark
                              ? AppColors.black.withValues(alpha: 0.3)
                              : AppColors.white.withValues(alpha: 0.5),
                        ),
                        child: ClipOval(
                          child: hasValidImage
                              ? Image.network(
                                  profileImage,
                                  key: ValueKey<String>(profileImage),
                                  fit: BoxFit.cover,
                                  cacheWidth: 120,
                                  cacheHeight: 120,
                                  loadingBuilder: (context, child, progress) {
                                    if (progress == null) {
                                      return child;
                                    }
                                    return Container(
                                      color: context.themeSecondary
                                          .withValues(alpha: 0.3),
                                      child: Center(
                                        child: CircularProgressIndicator(
                                          value: progress.expectedTotalBytes !=
                                                  null
                                              ? progress.cumulativeBytesLoaded /
                                                  progress.expectedTotalBytes!
                                              : null,
                                          strokeWidth: 2,
                                          valueColor:
                                              AlwaysStoppedAnimation<Color>(
                                                  tierColor),
                                        ),
                                      ),
                                    );
                                  },
                                  errorBuilder: (context, error, _) =>
                                      Container(
                                    color: context.themeSecondary,
                                    child: Icon(Icons.person_rounded,
                                        color: AppColors.white, size: 28),
                                  ),
                                )
                              : Container(
                                  color: context.themeSecondary,
                                  child: Icon(Icons.person_rounded,
                                      color: AppColors.white, size: 28),
                                ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      // Greeting + name
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(greeting,
                                style: AppTypography.caption(
                                    color: textSecondary)),
                            const SizedBox(height: 1),
                            Text(
                              homeState.displayName,
                              style: AppTypography.h5(color: textPrimary),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  const Spacer(),

                  // ── 4. Stats + progress — full-width frosted overlay ───────
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
                    decoration: BoxDecoration(
                      color: statsOverlayBg,
                      borderRadius: const BorderRadius.vertical(
                        bottom: Radius.circular(20),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Stats row — Total Points | To Next | Rank
                        IntrinsicHeight(
                          child: Row(
                            children: [
                              _HeroStat(
                                label: 'Total Points',
                                value: nf.format(homeState.points),
                                valueColor: tierColor,
                                textSecondary: textSecondary,
                              ),
                              VerticalDivider(
                                  color: dividerColor, width: 1, thickness: 1),
                              _HeroStat(
                                label: isPlatinum ? 'Status' : 'To $nextLabel',
                                value: isPlatinum
                                    ? 'Max'
                                    : nf.format(pointsToNext),
                                valueColor: textPrimary,
                                textSecondary: textSecondary,
                              ),
                              VerticalDivider(
                                  color: dividerColor, width: 1, thickness: 1),
                              _HeroStat(
                                label: 'Rank',
                                value: homeState.userRank != null
                                    ? '#${homeState.userRank}'
                                    : '—',
                                valueColor: textPrimary,
                                textSecondary: textSecondary,
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 8),

                        // Progress bar
                        if (!isPlatinum) ...[
                          Row(
                            children: [
                              Text(
                                '$pointsToNext pts to $nextLabel',
                                style:
                                    AppTypography.caption(color: textSecondary),
                              ),
                              const Spacer(),
                              Text(
                                '${(progress * 100).toStringAsFixed(0)}%',
                                style:
                                    AppTypography.caption(color: textSecondary),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(999),
                            child: LinearProgressIndicator(
                              value: progress,
                              minHeight: 5,
                              backgroundColor: progressBg,
                              valueColor:
                                  AlwaysStoppedAnimation<Color>(tierColor),
                            ),
                          ),
                        ] else
                          Row(
                            children: [
                              Icon(Icons.workspace_premium_rounded,
                                  size: 13, color: tierColor),
                              const SizedBox(width: 4),
                              AppText.caption('Platinum — Highest Tier!',
                                  color: tierColor),
                            ],
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // ── 5. Tier badge — absolute top-right ─────────────────────────
            Positioned(
              top: 12,
              right: 12,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: tierColor.withValues(alpha: 0.85),
                  borderRadius: AppRadius.all16,
                  boxShadow: [
                    BoxShadow(
                      color: tierColor.withValues(alpha: 0.35),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.star_rounded,
                        size: 12, color: AppColors.white),
                    const SizedBox(width: 4),
                    Text(
                      tier,
                      style: AppTypography.labelMedium(color: AppColors.white),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
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
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      height: HomeHeroCard._cardHeight,
      decoration: BoxDecoration(
        color: context.themeSoftSurface,
        borderRadius: AppRadius.all16,
      ),
    ).animate(onPlay: (c) => c.repeat()).shimmer(duration: 1200.ms);
  }
}

// ---------------------------------------------------------------------------
// _HeroStat
// ---------------------------------------------------------------------------

class _HeroStat extends StatelessWidget {
  final String label;
  final String value;
  final Color valueColor;
  final Color textSecondary;

  const _HeroStat({
    required this.label,
    required this.value,
    required this.valueColor,
    required this.textSecondary,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            label,
            style: AppTypography.caption(color: textSecondary),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 3),
          Text(
            value,
            style: AppTypography.pointsLarge(color: valueColor),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
