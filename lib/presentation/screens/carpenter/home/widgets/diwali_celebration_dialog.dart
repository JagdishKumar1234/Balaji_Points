import 'dart:math' as math;

import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';
import 'package:balaji_points/l10n/app_localizations.dart';
import 'package:intl/intl.dart';

import 'package:balaji_points/core/design/app_radius.dart';
import 'package:balaji_points/core/design/app_spacing.dart';
import 'package:balaji_points/core/design/app_typography.dart';
import 'package:balaji_points/services/branch/branch_celebration_service.dart';

class DiwaliCelebrationDialog extends StatefulWidget {
  const DiwaliCelebrationDialog({
    super.key,
    required this.branchName,
    required this.leaderboard,
  });

  final String branchName;
  final List<BranchCelebrationEntry> leaderboard;

  @override
  State<DiwaliCelebrationDialog> createState() =>
      _DiwaliCelebrationDialogState();
}

class _DiwaliCelebrationDialogState extends State<DiwaliCelebrationDialog>
    with TickerProviderStateMixin {
  late final AnimationController _entrance;
  late final AnimationController _fireworks;
  late final ConfettiController _confetti;

  @override
  void initState() {
    super.initState();
    _entrance = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 650),
    )..forward();
    _fireworks = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    )..repeat();
    _confetti = ConfettiController(
      duration: const Duration(milliseconds: 3600),
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _confetti.play();
    });
  }

  @override
  void dispose() {
    _entrance.dispose();
    _fireworks.dispose();
    _confetti.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final compact = size.width < 700;
    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
      clipBehavior: Clip.antiAlias,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: RoundedRectangleBorder(borderRadius: AppRadius.all24),
      child: ScaleTransition(
        scale: CurvedAnimation(parent: _entrance, curve: Curves.easeOutBack),
        child: FadeTransition(
          opacity: _entrance,
          child: SizedBox(
            width: math.min(size.width - 24, 1040.0),
            height: math.min(size.height - 32, 900.0),
            child: Stack(
              children: [
                Column(
                  children: [
                    _CelebrationHeader(
                      branchName: widget.branchName,
                      carpenterCount: widget.leaderboard.length,
                      animation: _fireworks,
                    ),
                    Expanded(
                      child: widget.leaderboard.isEmpty
                          ? _ReportMessage(
                              icon: Icons.groups_2_outlined,
                              message: AppLocalizations.of(
                                context,
                              )!.noCarpenterAccountsAreListedFor,
                            )
                          : _RewardReportBody(
                              entries: widget.leaderboard,
                              compact: compact,
                            ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                      child: SizedBox(
                        width: double.infinity,
                        child: FilledButton.icon(
                          onPressed: () => Navigator.of(context).pop(),
                          icon: const Icon(Icons.celebration_rounded),
                          label: Text(
                            AppLocalizations.of(context)!.continueToHome,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                Positioned.fill(
                  child: IgnorePointer(
                    child: ConfettiWidget(
                      confettiController: _confetti,
                      blastDirectionality: BlastDirectionality.explosive,
                      maxBlastForce: 24,
                      minBlastForce: 8,
                      emissionFrequency: .025,
                      numberOfParticles: 34,
                      gravity: .16,
                      colors: const [
                        Color(0xFFFFD166),
                        Color(0xFFFF8A3D),
                        Color(0xFFFF4D6D),
                        Color(0xFFFFF1B8),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _CelebrationHeader extends StatelessWidget {
  const _CelebrationHeader({
    required this.branchName,
    required this.carpenterCount,
    required this.animation,
  });

  final String branchName;
  final int carpenterCount;
  final Animation<double> animation;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 190,
      width: double.infinity,
      child: Stack(
        clipBehavior: Clip.hardEdge,
        children: [
          const Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Color(0xFF160D2B),
                    Color(0xFF3A1535),
                    Color(0xFF70243A),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
            ),
          ),
          Positioned.fill(
            child: AnimatedBuilder(
              animation: animation,
              builder: (_, __) =>
                  CustomPaint(painter: _FirecrackerPainter(animation.value)),
            ),
          ),
          Positioned(
            top: -84,
            right: -28,
            child: Container(
              width: 210,
              height: 210,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: const Color(0xFFFFD166).withValues(alpha: .12),
                  width: 20,
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 20, 72, 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const _HeaderTag(),
                const SizedBox(height: 8),
                Text(
                  AppLocalizations.of(context)!.shubhDeepawali,
                  style: AppTypography.h4(color: const Color(0xFFFFE7A3)),
                ),
                const SizedBox(height: 3),
                Text(
                  AppLocalizations.of(
                    context,
                  )!.carpenters('$branchName', '$carpenterCount'),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.bodyMedium(
                    color: Colors.white.withValues(alpha: .9),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  AppLocalizations.of(context)!.carpenterRewardBonusReport(
                    DateFormat('dd/MM/yyyy').format(DateTime.now()),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.caption(color: const Color(0xFFFFD166)),
                ),
              ],
            ),
          ),
          Positioned(
            right: 12,
            top: 12,
            child: IconButton.filledTonal(
              tooltip: AppLocalizations.of(context)!.closeCelebration,
              style: IconButton.styleFrom(
                backgroundColor: Colors.white.withValues(alpha: .14),
                foregroundColor: Colors.white,
              ),
              onPressed: () => Navigator.of(context).pop(),
              icon: const Icon(Icons.close_rounded),
            ),
          ),
          const Positioned(
            right: 22,
            bottom: 18,
            child: Icon(
              Icons.auto_awesome_rounded,
              color: Color(0xFFFFD166),
              size: 34,
            ),
          ),
        ],
      ),
    );
  }
}

class _HeaderTag extends StatelessWidget {
  const _HeaderTag();

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(
      color: const Color(0xFFFFD166).withValues(alpha: .17),
      borderRadius: AppRadius.pill,
      border: Border.all(color: const Color(0xFFFFD166).withValues(alpha: .55)),
    ),
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      child: Text(
        AppLocalizations.of(context)!.deepawaliPrizeNight,
        style: AppTypography.caption(color: const Color(0xFFFFE7A3)),
      ),
    ),
  );
}

class _FirecrackerPainter extends CustomPainter {
  const _FirecrackerPainter(this.progress);
  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    const colors = [Color(0xFFFFD166), Color(0xFFFF8A3D), Color(0xFFFF4D6D)];
    final centers = [
      Offset(size.width * .13, size.height * .27),
      Offset(size.width * .78, size.height * .28),
      Offset(size.width * .88, size.height * .82),
    ];
    for (var burst = 0; burst < centers.length; burst++) {
      final phase = (progress + burst * .34) % 1.0;
      final radius = 7 + 36 * math.sin(phase * math.pi);
      final opacity = (1 - phase) * .72;
      final paint = Paint()
        ..color = colors[burst].withValues(alpha: opacity)
        ..strokeWidth = 1.5
        ..strokeCap = StrokeCap.round;
      for (var ray = 0; ray < 12; ray++) {
        final angle = ray * math.pi / 6;
        final start =
            centers[burst] +
            Offset(
              math.cos(angle) * radius * .55,
              math.sin(angle) * radius * .55,
            );
        final end =
            centers[burst] +
            Offset(math.cos(angle) * radius, math.sin(angle) * radius);
        canvas.drawLine(start, end, paint);
        canvas.drawCircle(end, 1.8, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _FirecrackerPainter oldDelegate) =>
      oldDelegate.progress != progress;
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
            title: AppLocalizations.of(context)!.topPerformersGoldTier,
            subtitle: AppLocalizations.of(context)!.ranks110,
            rows: entries.where((entry) => entry.rank <= 10).toList(),
            color: const Color(0xFFB77900),
          ),
          (
            title: AppLocalizations.of(context)!.highPerformersSilverTier,
            subtitle: AppLocalizations.of(context)!.ranks1130,
            rows: entries
                .where((entry) => entry.rank >= 11 && entry.rank <= 30)
                .toList(),
            color: Theme.of(context).colorScheme.outline,
          ),
          (
            title: AppLocalizations.of(context)!.activePerformersBronzeTier,
            subtitle: AppLocalizations.of(context)!.ranks31Onwards,
            rows: entries.where((entry) => entry.rank >= 31).toList(),
            color: const Color(0xFF9A5B32),
          ),
        ];

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      children: [
        Text(
          AppLocalizations.of(context)!.totalCarpenters('${entries.length}'),
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
              label: AppLocalizations.of(context)!.totalPoints2,
              value: _formatPoints(totalPoints),
              icon: Icons.stars_rounded,
            ),
            _SummaryTile(
              label: AppLocalizations.of(context)!.totalReward,
              value: _formatCurrency(totalReward),
              icon: Icons.currency_rupee_rounded,
            ),
            _SummaryTile(
              label: AppLocalizations.of(context)!.totalBonus,
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
                    AppLocalizations.of(context)!.carpentersPointsRewardBonus(
                      '${entries.length}',
                      '${_formatPoints(totalPoints)}',
                      '${_formatCurrency(totalReward)}',
                      '${_formatCurrency(totalBonus)}',
                    ),
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
                    AppLocalizations.of(context)!.bonus(
                      '${_formatCurrency(entry.bonusAmount)}',
                      '${entry.giftDetails}',
                    ),
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
                    ? AppLocalizations.of(context)!.mobileNumberUnavailable
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
                _RowMetric(
                  label: AppLocalizations.of(context)!.homeTierSuffix,
                  value: entry.tier,
                ),
                _RowMetric(
                  label: AppLocalizations.of(context)!.reward,
                  value: _formatCurrency(entry.rewardAmount),
                ),
                _RowMetric(
                  label: AppLocalizations.of(context)!.bonus2,
                  value: entry.bonusAmount == 0
                      ? AppLocalizations.of(context)!.nil
                      : _formatCurrency(entry.bonusAmount),
                ),
                _RowMetric(
                  label: AppLocalizations.of(context)!.gift,
                  value: entry.giftDetails,
                ),
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
          columns: [
            const DataColumn(label: Text('S.No')),
            DataColumn(label: Text(AppLocalizations.of(context)!.name)),
            DataColumn(label: Text(AppLocalizations.of(context)!.mobileNumber)),
            DataColumn(
              label: Text(AppLocalizations.of(context)!.homeTierSuffix),
            ),
            DataColumn(
              label: Text(AppLocalizations.of(context)!.pointsLabel),
              numeric: true,
            ),
            DataColumn(
              label: Text(AppLocalizations.of(context)!.reward2),
              numeric: true,
            ),
            DataColumn(
              label: Text(AppLocalizations.of(context)!.bonus3),
              numeric: true,
            ),
            DataColumn(label: Text(AppLocalizations.of(context)!.giftDetails)),
            DataColumn(label: Text(AppLocalizations.of(context)!.remarks)),
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
                            ? AppLocalizations.of(context)!.nil
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
  const _ReportMessage({required this.icon, required this.message});

  final IconData icon;
  final String message;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 40, color: colors.primary),
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
