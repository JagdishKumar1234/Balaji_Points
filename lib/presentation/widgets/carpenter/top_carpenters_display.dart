import 'package:balaji_points/core/design/app_colors.dart';
import 'package:balaji_points/core/design/app_typography.dart';
import 'package:balaji_points/core/utils/points_utils.dart';
import 'package:balaji_points/presentation/widgets/carpenter/member_identity.dart';
import 'package:flutter/material.dart';

/// Podium for the top three: second, first, third.
class TopCarpentersDisplay extends StatelessWidget {
  final List<CarpenterRank> topCarpenters;
  final CarpenterRank? currentUser;

  const TopCarpentersDisplay({
    super.key,
    required this.topCarpenters,
    this.currentUser,
  });

  @override
  Widget build(BuildContext context) {
    if (topCarpenters.isEmpty) {
      return const SizedBox.shrink();
    }

    final top3 = topCarpenters.take(3).toList();

    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        if (top3.length > 1) _buildPodiumCard(context, top3[1], 2),
        if (top3.isNotEmpty) _buildPodiumCard(context, top3[0], 1),
        if (top3.length > 2) _buildPodiumCard(context, top3[2], 3),
      ],
    );
  }

  Widget _buildPodiumCard(
    BuildContext context,
    CarpenterRank member,
    int rank,
  ) {
    final (trophyColor, podiumHeight) = switch (rank) {
      1 => (AppColors.tierGold, 72.0),
      2 => (AppColors.tierSilver, 54.0),
      _ => (AppColors.tierBronze, 40.0),
    };

    final isCurrentUser =
        currentUser != null && member.userId == currentUser!.userId;

    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 3),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.emoji_events_rounded,
              size: rank == 1 ? 34 : 28,
              color: trophyColor,
            ),
            const SizedBox(height: 4),
            // Initials only: this podium shows other people, so no photos.
            MemberAvatar(name: member.name, size: rank == 1 ? 60 : 50),
            const SizedBox(height: 6),
            Text(
              member.name,
              textAlign: TextAlign.center,
              style: AppTypography.labelMedium(
                color: isCurrentUser
                    ? context.themeContentColor
                    : context.themeTextPrimary,
              ).copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 2),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.stars_rounded,
                  color: AppColors.gold,
                  size: 14,
                ),
                const SizedBox(width: 3),
                Flexible(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      PointsUtils.formatPoints(member.points),
                      maxLines: 1,
                      style: AppTypography.bodySmall(
                        color: context.themeTextSecondary,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Container(
              height: podiumHeight,
              alignment: Alignment.center,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [AppColors.primaryLight, AppColors.primary],
                ),
                borderRadius: BorderRadius.vertical(top: Radius.circular(10)),
              ),
              child: Text(
                '#$rank',
                style: AppTypography.h4(color: AppColors.gold),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class CarpenterRank {
  final int rank;
  final String name;

  /// Points can have decimals (₹12,500 → 12.5).
  final double points;
  final String? imageUrl;
  final String? userId;
  final bool isCurrentUser;

  CarpenterRank({
    required this.rank,
    required this.name,
    required this.points,
    this.imageUrl,
    this.userId,
    this.isCurrentUser = false,
  });
}
