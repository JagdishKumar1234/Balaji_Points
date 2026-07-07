import 'package:balaji_points/core/design/app_radius.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:balaji_points/core/design/app_colors.dart';
import 'package:balaji_points/core/design/app_typography.dart';
import 'package:balaji_points/l10n/app_localizations.dart';
import 'package:balaji_points/core/utils/points_utils.dart';
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
    final cardColor = context.themeSurface;
    final top3 = homeState.topCarpenters.take(3).toList();

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
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
                    borderRadius: AppRadius.sm8,
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
                      AppText.labelSmall('Leaderboard',
                          color: context.themeContentColor),
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
// TODAY'S WINNER  — reads from daily_winners/{YYYY-MM-DD} set by admin spin
// ---------------------------------------------------------------------------

class HomeTodaysWinnerCard extends StatelessWidget {
  const HomeTodaysWinnerCard({super.key});

  static String get _todayKey {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('daily_winners')
          .doc(_todayKey)
          .snapshots(),
      builder: (context, snap) {
        // Loading
        if (snap.connectionState == ConnectionState.waiting) {
          return _WinnerCardShell(
            isDark: isDark,
            child: _WinnerShimmer(isDark: isDark),
          );
        }

        // No winner yet today — show placeholder card
        final data = snap.data?.data();
        if (data == null) {
          return _WinnerCardShell(
            isDark: isDark,
            child: Row(
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.warning.withValues(alpha: 0.12),
                    border: Border.all(
                        color: AppColors.warning.withValues(alpha: 0.30),
                        width: 2),
                  ),
                  child: const Icon(Icons.emoji_events_rounded,
                      color: AppColors.warning, size: 28),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Today's Winner",
                        style: AppTypography.overline(color: AppColors.warning)
                            .copyWith(letterSpacing: 0.8),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'No Winner Today',
                        style: AppTypography.h5(color: context.themeTextPrimary),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Spin not done yet · $_todayKey',
                        style: AppTypography.caption(
                            color: context.themeTextSecondary),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.warning.withValues(alpha: 0.10),
                    borderRadius: AppRadius.md12,
                  ),
                  child: Icon(Icons.hourglass_top_rounded,
                      color: AppColors.warning.withValues(alpha: 0.60),
                      size: 22),
                ),
              ],
            ),
          );
        }

        final name = (data['carpenterName'] as String? ?? '').trim();
        final photo = (data['carpenterPhoto'] as String? ?? '').trim();
        final displayName = name.isEmpty ? 'Carpenter' : name;
        final hasPhoto = photo.isNotEmpty;

        return _WinnerCardShell(
          isDark: isDark,
          child: Row(
            children: [
              // Avatar: photo or initials circle
              Stack(
                clipBehavior: Clip.none,
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.warning.withValues(alpha: 0.18),
                      border: Border.all(
                          color: AppColors.warning.withValues(alpha: 0.5),
                          width: 2),
                    ),
                    child: hasPhoto
                        ? ClipOval(
                            child: Image.network(
                              photo,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) =>
                                  _InitialsCircle(name: displayName),
                            ),
                          )
                        : _InitialsCircle(name: displayName),
                  ),
                  // Trophy badge bottom-right
                  Positioned(
                    bottom: -4,
                    right: -4,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(
                        color: AppColors.warning,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.emoji_events_rounded,
                          color: AppColors.white, size: 12),
                    ),
                  ),
                ],
              ),

              const SizedBox(width: 14),

              // Name + label
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Today's Lucky Winner 🎉",
                      style: AppTypography.overline(color: AppColors.warning)
                          .copyWith(letterSpacing: 0.8),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      displayName,
                      style: AppTypography.h5(color: context.themeTextPrimary),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Selected via daily spin · $_todayKey',
                      style: AppTypography.caption(
                          color: context.themeTextSecondary),
                    ),
                  ],
                ),
              ),

              // Crown
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.warning.withValues(alpha: 0.14),
                  borderRadius: AppRadius.md12,
                ),
                child: const Icon(Icons.workspace_premium_rounded,
                    color: AppColors.warning, size: 24),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _WinnerCardShell extends StatelessWidget {
  final bool isDark;
  final Widget child;
  const _WinnerCardShell({required this.isDark, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDark
              ? [const Color(0xFF2A1F00), const Color(0xFF1A1400)]
              : [AppColors.goldSoft, AppColors.goldSoft],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: AppRadius.all16,
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
      child: child,
    );
  }
}

class _InitialsCircle extends StatelessWidget {
  final String name;
  const _InitialsCircle({required this.name});

  String get _initials {
    final parts = name.trim().split(' ');
    if (parts.length == 1) return parts[0].isNotEmpty ? parts[0][0].toUpperCase() : '?';
    return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        _initials,
        style: AppTypography.labelLarge(color: AppColors.warning)
            .copyWith(fontWeight: FontWeight.w900),
      ),
    );
  }
}

class _WinnerShimmer extends StatelessWidget {
  final bool isDark;
  const _WinnerShimmer({required this.isDark});

  @override
  Widget build(BuildContext context) {
    final shimmerColor =
        isDark ? AppColors.white.withValues(alpha: 0.08) : AppColors.black.withValues(alpha: 0.06);
    return Row(
      children: [
        Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            color: shimmerColor,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(height: 10, width: 100, color: shimmerColor),
              const SizedBox(height: 8),
              Container(height: 16, width: 160, color: shimmerColor),
              const SizedBox(height: 6),
              Container(height: 10, width: 120, color: shimmerColor),
            ],
          ),
        ),
      ],
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
              : [AppColors.primary, AppColors.primaryLight],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: AppRadius.all16,
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
                        '${PointsUtils.formatPoints(pts)} pts',
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
                  borderRadius: AppRadius.md12,
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
