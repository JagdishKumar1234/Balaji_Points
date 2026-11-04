import 'package:balaji_points/core/design/app_colors.dart';
import 'package:balaji_points/core/design/app_radius.dart';
import 'package:balaji_points/core/design/app_typography.dart';
import 'package:balaji_points/core/utils/points_utils.dart';
import 'package:balaji_points/l10n/app_localizations.dart';
import 'package:balaji_points/presentation/widgets/carpenter/member_identity.dart';
import 'package:flutter/material.dart';
import 'top_carpenters_display.dart';

/// The branch's top members. Points sit under the name so that the name has
/// the full width of the row and always shows in full.
class TopCarpentersList extends StatelessWidget {
  final List<CarpenterRank> carpenters;
  final bool showViewAll;

  const TopCarpentersList({
    super.key,
    required this.carpenters,
    this.showViewAll = true,
  });

  @override
  Widget build(BuildContext context) {
    if (carpenters.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final carpenter in carpenters) _LeaderboardRow(carpenter),
      ],
    );
  }
}

class _LeaderboardRow extends StatelessWidget {
  const _LeaderboardRow(this.member);

  final CarpenterRank member;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isTopThree = member.rank <= 3;
    final isMe = member.isCurrentUser;
    final highlight = isDark ? AppColors.darkPendingSoft : AppColors.goldSoft;
    final name = isMe
        ? '${member.name} (${AppLocalizations.of(context)!.diwaliYou})'
        : member.name;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: isMe ? highlight : context.themeCard,
        borderRadius: AppRadius.md12,
        border: Border.all(color: isMe ? AppColors.gold : context.themeBorder),
      ),
      child: Row(
        children: [
          Container(
            width: 30,
            height: 30,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isTopThree ? AppColors.gold : context.themeSoftSurface,
            ),
            child: Text(
              '${member.rank}',
              style: AppTypography.labelMedium(
                color: isTopThree
                    ? AppColors.primary
                    : context.themeContentColor,
              ).copyWith(fontWeight: FontWeight.w800),
            ),
          ),
          const SizedBox(width: 10),
          // Initials only: this list shows other people, so no photos.
          MemberAvatar(name: member.name, size: 40),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: AppTypography.labelLarge(
                    color: context.themeTextPrimary,
                  ).copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    const Icon(
                      Icons.stars_rounded,
                      size: 15,
                      color: AppColors.gold,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      AppLocalizations.of(
                        context,
                      )!.ptsValue(PointsUtils.formatPoints(member.points)),
                      style: AppTypography.bodySmall(
                        color: context.themeTextSecondary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
