import 'package:flutter/material.dart';
import 'package:balaji_points/core/design/app_radius.dart';
import 'package:balaji_points/core/design/app_colors.dart';
import 'package:balaji_points/presentation/widgets/shared/app_text.dart';

class PointsRepairDetailsPage extends StatelessWidget {
  final Map<String, dynamic> repairReport;
  final Map<String, dynamic> repairResults;

  const PointsRepairDetailsPage({
    super.key,
    required this.repairReport,
    required this.repairResults,
  });

  @override
  Widget build(BuildContext context) {
    final results = (repairResults['results'] as Map<String, dynamic>?) ?? {};
    final successCount = repairResults['repaired'] as int? ?? 0;
    final totalUsers = repairResults['total'] as int? ?? 0;
    final totalDuplicatesRemoved = repairResults['totalDuplicatesRemoved'] as int? ?? 0;
    final totalPointsDifference = repairResults['totalPointsDifference'] as num? ?? 0;

    return Scaffold(
      backgroundColor: context.themeBackground,
      appBar: AppBar(
        backgroundColor: context.themeBackground,
        foregroundColor: context.themeTextPrimary,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: AppText.h3('Repair Details', color: context.themeTextPrimary),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Summary cards
            _SummarySection(
              successCount: successCount,
              totalUsers: totalUsers,
              totalDuplicatesRemoved: totalDuplicatesRemoved,
              totalPointsDifference: totalPointsDifference.toInt(),
            ),
            const SizedBox(height: 20),

            // User-wise results
            AppText.h5('User-wise Repair Results',
                color: context.themeTextPrimary),
            const SizedBox(height: 12),

            if (results.isEmpty)
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: context.themeSoftSurface,
                  borderRadius: AppRadius.all16,
                ),
                child: AppText.body('No repairs completed',
                    color: context.themeTextSecondary),
              )
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: results.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final entry = results.entries.elementAt(index);
                  final userId = entry.key;
                  final repairData = entry.value as Map<String, dynamic>?;

                  if (repairData == null) {
                    return _FailedRepairCard(userId: userId);
                  }

                  return _UserRepairCard(
                    userId: userId,
                    beforeTotal: repairData['beforeTotal'] as int? ?? 0,
                    afterTotal: repairData['afterTotal'] as int? ?? 0,
                    beforeTier: repairData['beforeTier'] as String? ?? 'Unknown',
                    afterTier: repairData['afterTier'] as String? ?? 'Unknown',
                    historyBefore: repairData['historyBefore'] as int? ?? 0,
                    historyAfter: repairData['historyAfter'] as int? ?? 0,
                    duplicatesRemoved: repairData['duplicatesRemoved'] as int? ?? 0,
                  );
                },
              ),

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}

// Summary section showing total repair impact
class _SummarySection extends StatelessWidget {
  final int successCount;
  final int totalUsers;
  final int totalDuplicatesRemoved;
  final int totalPointsDifference;

  const _SummarySection({
    required this.successCount,
    required this.totalUsers,
    required this.totalDuplicatesRemoved,
    required this.totalPointsDifference,
  });

  @override
  Widget build(BuildContext context) {
    final failureCount = totalUsers - successCount;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Success rate card
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                AppColors.success.withValues(alpha: 0.1),
                AppColors.success.withValues(alpha: 0.05),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: AppRadius.all16,
            border: Border.all(
              color: AppColors.success.withValues(alpha: 0.2),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.check_circle, color: AppColors.success, size: 24),
                  const SizedBox(width: 10),
                  AppText.h5('Repair Complete', color: context.themeTextPrimary),
                ],
              ),
              const SizedBox(height: 16),
              _StatRow(
                label: 'Successfully Repaired',
                value: '$successCount/$totalUsers',
                valueColor: AppColors.success,
              ),
              if (failureCount > 0) ...[
                const SizedBox(height: 8),
                _StatRow(
                  label: 'Failed',
                  value: '$failureCount',
                  valueColor: AppColors.error,
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 12),

        // Impact cards grid
        Row(
          children: [
            Expanded(
              child: _ImpactCard(
                icon: Icons.copy_all,
                label: 'Duplicates Removed',
                value: '$totalDuplicatesRemoved',
                color: const Color(0xFFFF8A65),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _ImpactCard(
                icon: Icons.trending_down,
                label: 'Points Adjusted',
                value: '$totalPointsDifference',
                color: const Color(0xFF42A5F5),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

// Individual user repair result card
class _UserRepairCard extends StatelessWidget {
  final String userId;
  final int beforeTotal;
  final int afterTotal;
  final String beforeTier;
  final String afterTier;
  final int historyBefore;
  final int historyAfter;
  final int duplicatesRemoved;

  const _UserRepairCard({
    required this.userId,
    required this.beforeTotal,
    required this.afterTotal,
    required this.beforeTier,
    required this.afterTier,
    required this.historyBefore,
    required this.historyAfter,
    required this.duplicatesRemoved,
  });


  @override
  Widget build(BuildContext context) {
    final pointsChanged = beforeTotal != afterTotal;
    final tierChanged = beforeTier != afterTier;

    return Container(
      decoration: BoxDecoration(
        color: context.themeSurface,
        borderRadius: AppRadius.all16,
        border: Border.all(color: context.themeBorder),
      ),
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // User ID
          AppText.body(
            userId,
            color: context.themeTextSecondary,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 12),

          // Before state
          _StateRow(
            label: 'Before',
            points: beforeTotal,
            tier: beforeTier,
            context: context,
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Row(
              children: [
                Icon(Icons.arrow_downward,
                    size: 16, color: context.themeTextSecondary),
                const SizedBox(width: 4),
                Icon(Icons.arrow_downward,
                    size: 16, color: context.themeTextSecondary),
              ],
            ),
          ),
          const SizedBox(height: 8),

          // After state
          _StateRow(
            label: 'After',
            points: afterTotal,
            tier: afterTier,
            context: context,
            highlight: true,
          ),

          const SizedBox(height: 12),

          // Changes summary
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: context.themePrimary.withValues(alpha: 0.08),
              borderRadius: AppRadius.sm8,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (pointsChanged)
                  _ChangeDetail(
                    icon: Icons.trending_down,
                    label: 'Points',
                    before: beforeTotal.toString(),
                    after: afterTotal.toString(),
                  ),
                if (pointsChanged && tierChanged) const SizedBox(height: 6),
                if (tierChanged)
                  _ChangeDetail(
                    icon: Icons.grade,
                    label: 'Tier',
                    before: beforeTier,
                    after: afterTier,
                  ),
                if ((pointsChanged || tierChanged) && duplicatesRemoved > 0)
                  const SizedBox(height: 6),
                if (duplicatesRemoved > 0)
                  _ChangeDetail(
                    icon: Icons.copy_all,
                    label: 'Duplicates Removed',
                    before: historyBefore.toString(),
                    after: historyAfter.toString(),
                    suffix: '($duplicatesRemoved)',
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// Failed repair card
class _FailedRepairCard extends StatelessWidget {
  final String userId;

  const _FailedRepairCard({required this.userId});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.error.withValues(alpha: 0.08),
        borderRadius: AppRadius.all16,
        border: Border.all(color: AppColors.error.withValues(alpha: 0.2)),
      ),
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          Icon(Icons.error_outline, color: AppColors.error),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AppText.body(userId,
                    color: context.themeTextSecondary,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis),
                const SizedBox(height: 4),
                AppText.body('Repair failed', color: AppColors.error),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// State row showing points and tier
class _StateRow extends StatelessWidget {
  final String label;
  final int points;
  final String tier;
  final BuildContext context;
  final bool highlight;

  const _StateRow({
    required this.label,
    required this.points,
    required this.tier,
    required this.context,
    this.highlight = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        AppText.label(label, color: context.themeTextSecondary),
        Row(
          children: [
            AppText.body(
              '$points pts',
              color: context.themeTextPrimary,
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: context.themePrimary.withValues(alpha: 0.1),
                borderRadius: AppRadius.sm8,
              ),
              child: AppText.label(tier, color: context.themePrimary),
            ),
          ],
        ),
      ],
    );
  }
}

// Change detail showing before/after
class _ChangeDetail extends StatelessWidget {
  final IconData icon;
  final String label;
  final String before;
  final String after;
  final String? suffix;

  const _ChangeDetail({
    required this.icon,
    required this.label,
    required this.before,
    required this.after,
    this.suffix,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 16, color: context.themePrimary),
        const SizedBox(width: 6),
        Expanded(
          child: AppText.bodySmall(
            label,
            color: context.themeTextSecondary,
          ),
        ),
        AppText.bodySmall(
          '$before → $after${suffix != null ? ' $suffix' : ''}',
          color: context.themeTextPrimary,
        ),
      ],
    );
  }
}

// Impact card for summary
class _ImpactCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _ImpactCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: AppRadius.all16,
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 8),
          AppText.label(label, color: context.themeTextSecondary),
          const SizedBox(height: 4),
          AppText.h4(value, color: color),
        ],
      ),
    );
  }
}

// Stat row for summary
class _StatRow extends StatelessWidget {
  final String label;
  final String value;
  final Color valueColor;

  const _StatRow({
    required this.label,
    required this.value,
    required this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        AppText.body(label, color: context.themeTextSecondary),
        AppText.body(value, color: valueColor),
      ],
    );
  }
}
