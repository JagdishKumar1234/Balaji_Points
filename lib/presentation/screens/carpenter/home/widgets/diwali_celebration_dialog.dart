import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'package:balaji_points/core/design/app_radius.dart';
import 'package:balaji_points/core/design/app_spacing.dart';
import 'package:balaji_points/core/design/app_typography.dart';
import 'package:balaji_points/presentation/screens/super_admin/super_admin_loading_view.dart';
import 'package:balaji_points/services/branch/branch_celebration_service.dart';

class DiwaliCelebrationDialog extends StatelessWidget {
  const DiwaliCelebrationDialog({
    super.key,
    required this.branchName,
    required this.leaderboard,
  });

  final String branchName;
  final Future<List<BranchCelebrationEntry>> leaderboard;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final size = MediaQuery.sizeOf(context);
    final isCompact = size.width < 700;
    final dialogWidth = math.min(size.width - 24, 1040.0);
    final dialogHeight = math.min(size.height - 32, 900.0);

    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
      clipBehavior: Clip.antiAlias,
      backgroundColor: colors.surface,
      shape: RoundedRectangleBorder(borderRadius: AppRadius.all24),
      child: SizedBox(
        width: dialogWidth,
        height: dialogHeight,
        child: Column(
          children: [
            _CelebrationHeader(branchName: branchName),
            Expanded(
              child: FutureBuilder<List<BranchCelebrationEntry>>(
                future: leaderboard,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const SuperAdminLoadingView(
                      label: 'Preparing the branch reward report…',
                    );
                  }
                  if (snapshot.hasError) {
                    return _ReportMessage(
                      icon: Icons.cloud_off_rounded,
                      message:
                          'The carpenter reward report could not be loaded. Close this window and try again.',
                      isError: true,
                    );
                  }
                  final entries = snapshot.data ?? const [];
                  if (entries.isEmpty) {
                    return const _ReportMessage(
                      icon: Icons.groups_2_outlined,
                      message:
                          'No carpenter accounts are listed for this branch yet.',
                    );
                  }
                  return _RewardReportBody(
                    entries: entries,
                    compact: isCompact,
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              child: SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.celebration_rounded),
                  label: const Text('Continue to Home'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CelebrationHeader extends StatelessWidget {
  const _CelebrationHeader({required this.branchName});

  final String branchName;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Stack(
      clipBehavior: Clip.hardEdge,
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(22, 20, 12, 18),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                colors.primaryContainer,
                colors.tertiaryContainer,
                colors.secondaryContainer,
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 54,
                height: 54,
                decoration: BoxDecoration(
                  color: colors.surface.withValues(alpha: .82),
                  borderRadius: AppRadius.all16,
                ),
                child: Icon(
                  Icons.emoji_events_rounded,
                  color: colors.primary,
                  size: 30,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'CARPENTER REWARD & BONUS REPORT',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.h5(color: colors.onPrimaryContainer),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '$branchName  ·  Diwali celebration',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.bodySmall(
                        color: colors.onPrimaryContainer.withValues(alpha: .82),
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      'Generated ${DateFormat('dd/MM/yyyy').format(DateTime.now())}  ·  Base rate ₹10 per point',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.caption(
                        color: colors.onPrimaryContainer.withValues(alpha: .72),
                      ),
                    ),
                  ],
                ),
              ),
              IconButton.filledTonal(
                tooltip: 'Close report',
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(Icons.close_rounded),
              ),
            ],
          ),
        ),
        Positioned(
          right: 64,
          top: -18,
          child: Icon(
            Icons.auto_awesome_rounded,
            size: 74,
            color: colors.onPrimaryContainer.withValues(alpha: .08),
          ),
        ),
        Positioned(
          right: 18,
          bottom: -30,
          child: Icon(
            Icons.local_florist_rounded,
            size: 90,
            color: colors.onTertiaryContainer.withValues(alpha: .09),
          ),
        ),
      ],
    );
  }
}

class _RewardReportBody extends StatelessWidget {
  const _RewardReportBody({required this.entries, required this.compact});

  final List<BranchCelebrationEntry> entries;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final totalPoints = entries.fold<double>(
      0,
      (sum, entry) => sum + entry.points,
    );
    final totalReward = (totalPoints * 10).round();
    final totalBonus = entries.fold<int>(
      0,
      (sum, entry) => sum + entry.bonusAmount,
    );
    final sections =
        <
          ({
            String title,
            String subtitle,
            List<BranchCelebrationEntry> rows,
            Color color,
          })
        >[
          (
            title: 'Top Performers - Gold Tier',
            subtitle: 'Ranks 1-10',
            rows: entries.where((entry) => entry.rank <= 10).toList(),
            color: const Color(0xFFB77900),
          ),
          (
            title: 'High Performers - Silver Tier',
            subtitle: 'Ranks 11-30',
            rows: entries
                .where((entry) => entry.rank >= 11 && entry.rank <= 30)
                .toList(),
            color: Theme.of(context).colorScheme.outline,
          ),
          (
            title: 'Active Performers - Bronze Tier',
            subtitle: 'Ranks 31 onwards',
            rows: entries.where((entry) => entry.rank >= 31).toList(),
            color: const Color(0xFF9A5B32),
          ),
        ];

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      children: [
        Text(
          'Total carpenters: ${entries.length}',
          style: AppTypography.labelLarge(
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          children: [
            _SummaryTile(
              label: 'Total points',
              value: _formatPoints(totalPoints),
              icon: Icons.stars_rounded,
            ),
            _SummaryTile(
              label: 'Total reward',
              value: _formatCurrency(totalReward),
              icon: Icons.currency_rupee_rounded,
            ),
            _SummaryTile(
              label: 'Total bonus',
              value: _formatCurrency(totalBonus),
              icon: Icons.card_giftcard_rounded,
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        _PrizeHighlights(entries: entries.take(3).toList()),
        const SizedBox(height: AppSpacing.md),
        for (final section in sections)
          if (section.rows.isNotEmpty) ...[
            _SectionHeading(
              title: section.title,
              subtitle: section.subtitle,
              color: section.color,
            ),
            const SizedBox(height: AppSpacing.xs),
            if (compact)
              ...section.rows.map((entry) => _CompactReportRow(entry: entry))
            else
              _WideReportTable(entries: section.rows),
            const SizedBox(height: AppSpacing.md),
          ],
        Card.filled(
          color: Theme.of(context).colorScheme.primaryContainer,
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Row(
              children: [
                const Icon(Icons.summarize_rounded),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    '${entries.length} carpenters  ·  ${_formatPoints(totalPoints)} points  ·  ${_formatCurrency(totalReward)} reward  ·  ${_formatCurrency(totalBonus)} bonus',
                    style: AppTypography.labelLarge(
                      color: Theme.of(context).colorScheme.onPrimaryContainer,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _PrizeHighlights extends StatelessWidget {
  const _PrizeHighlights({required this.entries});

  final List<BranchCelebrationEntry> entries;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Wrap(
      alignment: WrapAlignment.center,
      spacing: AppSpacing.sm,
      runSpacing: AppSpacing.sm,
      children: entries.map((entry) {
        final medal = switch (entry.rank) {
          1 => const Color(0xFFB77900),
          2 => colors.outline,
          _ => const Color(0xFF9A5B32),
        };
        return SizedBox(
          width: 220,
          child: Card.filled(
            color: entry.rank == 1
                ? colors.tertiaryContainer
                : colors.surfaceContainerLow,
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Column(
                children: [
                  Icon(Icons.emoji_events_rounded, color: medal, size: 28),
                  const SizedBox(height: 4),
                  Text(
                    '${entry.rank}${_ordinalSuffix(entry.rank)} Prize',
                    style: AppTypography.labelLarge(color: medal),
                  ),
                  Text(
                    entry.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.bodyMedium(color: colors.onSurface),
                  ),
                  Text(
                    '${_formatCurrency(entry.bonusAmount)} bonus  ·  ${entry.giftDetails}',
                    textAlign: TextAlign.center,
                    style: AppTypography.bodySmall(
                      color: colors.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

class _SectionHeading extends StatelessWidget {
  const _SectionHeading({
    required this.title,
    required this.subtitle,
    required this.color,
  });

  final String title;
  final String subtitle;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 5,
          height: 34,
          decoration: BoxDecoration(color: color, borderRadius: AppRadius.pill),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Text(title, style: AppTypography.labelLarge(color: color)),
        ),
        Text(
          subtitle,
          style: AppTypography.caption(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

class _CompactReportRow extends StatelessWidget {
  const _CompactReportRow({required this.entry});

  final BranchCelebrationEntry entry;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final isWinner = entry.bonusAmount > 0;
    return Card.filled(
      color: isWinner
          ? colors.tertiaryContainer.withValues(alpha: .5)
          : colors.surfaceContainerLow,
      margin: const EdgeInsets.only(bottom: 6),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(10, 6, 10, 10),
        child: Column(
          children: [
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: CircleAvatar(
                backgroundColor: isWinner
                    ? colors.tertiaryContainer
                    : colors.surfaceContainerHighest,
                child: Text(
                  '${entry.rank}',
                  style: AppTypography.labelLarge(color: colors.primary),
                ),
              ),
              title: Text(
                entry.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              subtitle: Text(
                entry.mobileNumber.isEmpty
                    ? 'Mobile number unavailable'
                    : entry.mobileNumber,
              ),
              trailing: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    _formatPoints(entry.points),
                    style: AppTypography.labelLarge(color: colors.primary),
                  ),
                  Text(
                    'points',
                    style: AppTypography.caption(
                      color: colors.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 12),
            Wrap(
              alignment: WrapAlignment.spaceBetween,
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.xs,
              children: [
                _RowMetric(label: 'Tier', value: entry.tier),
                _RowMetric(
                  label: 'Reward',
                  value: _formatCurrency(entry.rewardAmount),
                ),
                _RowMetric(
                  label: 'Bonus',
                  value: entry.bonusAmount == 0
                      ? 'Nil'
                      : _formatCurrency(entry.bonusAmount),
                ),
                _RowMetric(label: 'Gift', value: entry.giftDetails),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _WideReportTable extends StatelessWidget {
  const _WideReportTable({required this.entries});

  final List<BranchCelebrationEntry> entries;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Card.filled(
      color: colors.surfaceContainerLow,
      clipBehavior: Clip.antiAlias,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          headingRowColor: WidgetStatePropertyAll(
            colors.surfaceContainerHighest,
          ),
          columnSpacing: 18,
          dataRowMinHeight: 48,
          dataRowMaxHeight: 64,
          columns: const [
            DataColumn(label: Text('S.No')),
            DataColumn(label: Text('Name')),
            DataColumn(label: Text('Mobile number')),
            DataColumn(label: Text('Tier')),
            DataColumn(label: Text('Points'), numeric: true),
            DataColumn(label: Text('Reward ₹'), numeric: true),
            DataColumn(label: Text('Bonus ₹'), numeric: true),
            DataColumn(label: Text('Gift details')),
            DataColumn(label: Text('Remarks')),
          ],
          rows: entries
              .map(
                (entry) => DataRow(
                  color: entry.bonusAmount > 0
                      ? WidgetStatePropertyAll(
                          colors.tertiaryContainer.withValues(alpha: .28),
                        )
                      : null,
                  cells: [
                    DataCell(Text('${entry.rank}')),
                    DataCell(
                      SizedBox(
                        width: 150,
                        child: Text(
                          entry.name,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                    DataCell(
                      Text(
                        entry.mobileNumber.isEmpty ? '—' : entry.mobileNumber,
                      ),
                    ),
                    DataCell(Text(entry.tier)),
                    DataCell(Text(_formatPoints(entry.points))),
                    DataCell(Text(_formatCurrency(entry.rewardAmount))),
                    DataCell(
                      Text(
                        entry.bonusAmount == 0
                            ? 'Nil'
                            : _formatCurrency(entry.bonusAmount),
                      ),
                    ),
                    DataCell(
                      SizedBox(width: 120, child: Text(entry.giftDetails)),
                    ),
                    const DataCell(Text('—')),
                  ],
                ),
              )
              .toList(),
        ),
      ),
    );
  }
}

class _SummaryTile extends StatelessWidget {
  const _SummaryTile({
    required this.label,
    required this.value,
    required this.icon,
  });

  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Card.filled(
      color: colors.surfaceContainerLow,
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 20, color: colors.primary),
            const SizedBox(width: AppSpacing.sm),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: AppTypography.labelLarge(color: colors.primary),
                ),
                Text(
                  label,
                  style: AppTypography.caption(color: colors.onSurfaceVariant),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _RowMetric extends StatelessWidget {
  const _RowMetric({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 130,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: AppTypography.caption(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTypography.labelLarge(
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
        ],
      ),
    );
  }
}

class _ReportMessage extends StatelessWidget {
  const _ReportMessage({
    required this.icon,
    required this.message,
    this.isError = false,
  });

  final IconData icon;
  final String message;
  final bool isError;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 40,
              color: isError ? colors.error : colors.primary,
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(message, textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}

String _formatPoints(double points) =>
    NumberFormat('#,##0.00', 'en_IN').format(points);
String _formatCurrency(int amount) => NumberFormat.currency(
  locale: 'en_IN',
  symbol: '₹',
  decimalDigits: 0,
).format(amount);
String _ordinalSuffix(int rank) => switch (rank) {
  1 => 'st',
  2 => 'nd',
  3 => 'rd',
  _ => 'th',
};
