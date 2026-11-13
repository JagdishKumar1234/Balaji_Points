import 'package:balaji_points/core/design/app_radius.dart';
import 'package:balaji_points/core/points/leaderboard_group.dart';
import 'package:balaji_points/presentation/widgets/shared/group_labels.dart';
import 'package:balaji_points/services/spin/daily_spin_service.dart';
import 'package:balaji_points/presentation/widgets/shared/app_text.dart';
import 'package:flutter/material.dart';
import 'package:balaji_points/presentation/widgets/shared/app_loader.dart';
import 'package:balaji_points/services/branch/current_branch_service.dart';
import 'package:balaji_points/l10n/app_localizations.dart';
import 'package:balaji_points/core/design/app_colors.dart';
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
    return FutureBuilder<List<SpinCandidate>>(
      future: _load(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _buildLoadingCard(context);
        }

        if (snapshot.hasError) {
          return _buildErrorCard(context, snapshot.error.toString());
        }

        final carpenters = snapshot.data ?? [];

        if (carpenters.isEmpty) {
          return _buildEmptyCard(context);
        }

        return _buildEligibleCarpentersList(context, carpenters);
      },
    );
  }

  Widget _buildLoadingCard(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: context.themeSurface,
        borderRadius: AppRadius.all16,
        boxShadow: [
          BoxShadow(
            color: AppColors.black.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AppLoader(color: context.themeSecondary),
          const SizedBox(height: 16),
          AppText.body(
            AppLocalizations.of(context)!.loadingEligibleCarpenters,
            color: context.themeTextSecondary,
          ),
        ],
      ),
    );
  }

  Widget _buildErrorCard(BuildContext context, String error) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: context.themeError,
        borderRadius: AppRadius.all16,
        border: Border.all(color: context.themeError),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.error_outline_rounded,
            color: context.themeError,
            size: 48,
          ),
          const SizedBox(height: 12),
          AppText.label(
            AppLocalizations.of(context)!.errorLoadingData,
            color: context.themeError,
          ),
          const SizedBox(height: 8),
          AppText.bodySmall(
            error,
            color: context.themeError,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyCard(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: context.themeSurface,
        borderRadius: AppRadius.all16,
        boxShadow: [
          BoxShadow(
            color: AppColors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.receipt_long_outlined,
            size: 64,
            color: context.themeTextMuted,
          ),
          const SizedBox(height: 16),
          AppText.label(
            group.shortLabel(context),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          AppText.body(
            AppLocalizations.of(context)!.spinNoQualifiedToday,
            color: context.themeTextSecondary,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildEligibleCarpentersList(
    BuildContext context,
    List<SpinCandidate> carpenters,
  ) {
    final groupSales = carpenters.fold<double>(0, (t, c) => t + c.todaySales);

    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.themeSurface,
        borderRadius: AppRadius.all16,
        boxShadow: [
          BoxShadow(
            color: AppColors.black.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: context.themeSecondary,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.white.withValues(alpha: 0.2),
                    borderRadius: AppRadius.md12,
                  ),
                  child: const Icon(
                    Icons.check_circle_rounded,
                    color: AppColors.white,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      AppText.label(
                        group.shortLabel(context),
                        color: AppColors.white,
                      ),
                      const SizedBox(height: 4),
                      AppText.body(
                        AppLocalizations.of(context)!.groupSalesToday(
                          '${carpenters.length}',
                          _rupees(groupSales),
                        ),
                        color: AppColors.white.withValues(alpha: 0.9),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // List of carpenters
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            padding: const EdgeInsets.all(16),
            itemCount: carpenters.length,
            separatorBuilder: (context, index) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final carpenter = carpenters[index];
              return _buildCarpenterCard(context, carpenter, index + 1);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildCarpenterCard(
    BuildContext context,
    SpinCandidate carpenter,
    int rank,
  ) {
    final name = carpenter.name;
    final phone = carpenter.phone ?? 'N/A';
    final billsCount = carpenter.billsCount;
    final profileImage = carpenter.profileImage;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.themeSoftSurface,
        borderRadius: AppRadius.md12,
        border: Border.all(
          color: context.themeSecondary.withValues(alpha: 0.2),
          width: 1.5,
        ),
      ),
      child: Row(
        children: [
          // Rank badge
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: context.themeSecondary.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: Center(child: AppText.label('$rank')),
          ),
          const SizedBox(width: 16),

          // Profile image
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: context.themeSecondary.withValues(alpha: 0.3),
                width: 2,
              ),
            ),
            child: ClipOval(
              child: _isValidImageUrl(profileImage)
                  ? Image.network(
                      profileImage!,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          color: context.themeSecondary.withValues(alpha: 0.1),
                          child: Icon(
                            Icons.person_rounded,
                            size: 28,
                            color: context.themeContentColor,
                          ),
                        );
                      },
                    )
                  : Container(
                      color: context.themeSecondary.withValues(alpha: 0.1),
                      child: Icon(
                        Icons.person_rounded,
                        size: 28,
                        color: context.themeContentColor,
                      ),
                    ),
            ),
          ),
          const SizedBox(width: 16),

          // Carpenter info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AppText.label(
                  name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(
                      Icons.phone_rounded,
                      size: 14,
                      color: context.themeTextSecondary,
                    ),
                    const SizedBox(width: 4),
                    Flexible(
                      child: AppText.body(
                        phone,
                        color: context.themeTextSecondary,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(width: 8),

          // Stats
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: AppColors.success,
                  borderRadius: AppRadius.sm8,
                  border: Border.all(color: AppColors.success),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.receipt_rounded,
                      size: 14,
                      color: AppColors.white,
                    ),
                    const SizedBox(width: 4),
                    AppText.labelSmall('$billsCount', color: AppColors.white),
                  ],
                ),
              ),
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: AppColors.warning,
                  borderRadius: AppRadius.sm8,
                  border: Border.all(color: AppColors.warning),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.currency_rupee_rounded,
                      size: 14,
                      color: AppColors.white,
                    ),
                    const SizedBox(width: 2),
                    AppText.label(
                      _rupees(carpenter.todaySales).substring(1),
                      color: AppColors.white,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  bool _isValidImageUrl(String? url) {
    if (url == null || url.isEmpty) return false;
    final trimmed = url.trim();
    return trimmed.startsWith('http://') || trimmed.startsWith('https://');
  }
}
