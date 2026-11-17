import 'package:balaji_points/core/design/app_colors.dart';
import 'package:balaji_points/core/design/app_radius.dart';
import 'package:balaji_points/core/design/app_typography.dart';
import 'package:balaji_points/core/points/leaderboard_group.dart';
import 'package:balaji_points/l10n/app_localizations.dart';
import 'package:balaji_points/presentation/widgets/shared/app_loader.dart';
import 'package:balaji_points/services/branch/current_branch_service.dart';
import 'package:balaji_points/services/spin/daily_spin_service.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// Members of one role group who qualify for today's draw in this branch
/// (at least one bill approved today), with their sales today.
class TodaysEligibleCarpenters extends StatelessWidget {
  const TodaysEligibleCarpenters({
    super.key,
    required this.group,
    required this.date,
  });

  final LeaderboardGroup group;

  /// `YYYY-MM-DD`.
  final String date;

  Future<List<SpinCandidate>> _load() => DailySpinService().eligible(
    branchId: CurrentBranchService.adminBranchId,
    group: group,
    date: date,
  );

  static String _rupees(num v) =>
      '₹${NumberFormat.decimalPattern('en_IN').format(v.round())}';

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return FutureBuilder<List<SpinCandidate>>(
      future: _load(),
      builder: (context, snapshot) {
        final members = snapshot.data ?? const <SpinCandidate>[];
        final sales = members.fold<double>(0, (t, c) => t + c.todaySales);

        final Widget body;
        if (snapshot.connectionState == ConnectionState.waiting) {
          body = const Padding(
            padding: EdgeInsets.all(12),
            child: Center(child: AppLoader()),
          );
        } else if (snapshot.hasError) {
          body = _note(
            context,
            l10n.errorLoadingData,
            icon: Icons.error_outline_rounded,
            color: context.themeError,
          );
        } else if (members.isEmpty) {
          body = _note(context, l10n.spinNoQualifiedToday);
        } else {
          body = Column(
            children: [
              for (final (i, m) in members.indexed) ...[
                if (i > 0) Divider(height: 1, color: context.themeDivider),
                _MemberRow(
                  rank: i + 1,
                  member: m,
                  sales: _rupees(m.todaySales),
                ),
              ],
            ],
          );
        }

        return Container(
          key: const ValueKey('admin-spin-eligible'),
          decoration: BoxDecoration(
            color: context.themeCard,
            borderRadius: AppRadius.all16,
            border: Border.all(color: context.themeBorder),
          ),
          padding: const EdgeInsets.fromLTRB(16, 12, 12, 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.how_to_reg_rounded,
                    size: 20,
                    color: context.themeContentColor,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      l10n.spinEligibleToday,
                      style: AppTypography.section(
                        color: context.themeTextPrimary,
                      ),
                    ),
                  ),
                  if (members.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: AppRadius.pill,
                      ),
                      child: Text(
                        '${members.length}',
                        style: AppTypography.label(color: AppColors.gold),
                      ),
                    ),
                ],
              ),
              if (members.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(
                  l10n.groupSalesToday('${members.length}', _rupees(sales)),
                  style: AppTypography.caption(
                    color: context.themeTextSecondary,
                  ),
                ),
              ],
              const SizedBox(height: 8),
              body,
            ],
          ),
        );
      },
    );
  }

  Widget _note(
    BuildContext context,
    String text, {
    IconData icon = Icons.receipt_long_outlined,
    Color? color,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: context.themeSoftSurface,
        borderRadius: AppRadius.md12,
      ),
      child: Row(
        children: [
          Icon(icon, color: color ?? context.themeTextMuted),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: AppTypography.bodyMedium().copyWith(
                color: color ?? context.themeTextSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MemberRow extends StatelessWidget {
  const _MemberRow({
    required this.rank,
    required this.member,
    required this.sales,
  });

  final int rank;
  final SpinCandidate member;
  final String sales;

  @override
  Widget build(BuildContext context) {
    final photo = member.profileImage?.trim() ?? '';
    final hasPhoto = photo.startsWith('http');
    final phone = member.phone?.trim() ?? '';

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          SizedBox(
            width: 22,
            child: Text(
              '$rank',
              textAlign: TextAlign.center,
              style: AppTypography.label(color: context.themeTextSecondary),
            ),
          ),
          const SizedBox(width: 8),
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.primary,
              border: Border.all(color: AppColors.gold, width: 1.5),
            ),
            clipBehavior: Clip.antiAlias,
            child: hasPhoto
                ? Image.network(
                    photo,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) =>
                        const Icon(Icons.person_rounded, color: AppColors.gold),
                  )
                : const Icon(Icons.person_rounded, color: AppColors.gold),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  member.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.label(color: context.themeTextPrimary),
                ),
                if (phone.isNotEmpty)
                  Text(
                    phone,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.caption(
                      color: context.themeTextSecondary,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                sales,
                style: AppTypography.label(color: context.themeTextPrimary),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.receipt_rounded,
                    size: 12,
                    color: context.themeTextSecondary,
                  ),
                  const SizedBox(width: 3),
                  Text(
                    '${member.billsCount}',
                    style: AppTypography.caption(
                      color: context.themeTextSecondary,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}
