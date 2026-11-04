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
    required this.summary,
  });

  final String branchName;
  final BranchCelebrationSummary summary;

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
    final summary = widget.summary;
    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
      clipBehavior: Clip.antiAlias,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: RoundedRectangleBorder(borderRadius: AppRadius.all24),
      child: ScaleTransition(
        scale: CurvedAnimation(parent: _entrance, curve: Curves.easeOutBack),
        child: FadeTransition(
          opacity: _entrance,
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: math.min(size.width - 24, 520.0),
              maxHeight: size.height - 32,
            ),
            child: Stack(
              children: [
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Flexible(
                      child: ListView(
                        shrinkWrap: true,
                        padding: EdgeInsets.zero,
                        children: [
                          _CelebrationHeader(
                            branchName: widget.branchName,
                            animation: _fireworks,
                          ),
                          if (summary.topThree.isEmpty)
                            _ReportMessage(
                              icon: Icons.groups_2_outlined,
                              message: AppLocalizations.of(
                                context,
                              )!.noCarpenterAccountsAreListedFor,
                            )
                          else
                            Padding(
                              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  if (summary.currentUser != null) ...[
                                    _YourPrizeCard(entry: summary.currentUser!),
                                    const SizedBox(height: AppSpacing.md),
                                  ],
                                  _TopThreeList(entries: summary.topThree),
                                ],
                              ),
                            ),
                        ],
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
    required this.animation,
  });

  final String branchName;
  final Animation<double> animation;

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(
        minHeight: 150,
        minWidth: double.infinity,
      ),
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
                  branchName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.bodyMedium(
                    color: Colors.white.withValues(alpha: .9),
                  ),
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

/// The logged-in carpenter's own points and prize.
class _YourPrizeCard extends StatelessWidget {
  const _YourPrizeCard({required this.entry});

  final BranchCelebrationEntry entry;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colors = Theme.of(context).colorScheme;
    return Card.filled(
      margin: EdgeInsets.zero,
      color: colors.tertiaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.diwaliYourPrize,
              style: AppTypography.labelLarge(
                color: colors.onTertiaryContainer,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Wrap(
              spacing: AppSpacing.xl,
              runSpacing: AppSpacing.sm,
              children: [
                _PrizeValue(
                  label: l10n.myPoints,
                  value: _formatPoints(entry.points),
                ),
                _PrizeValue(
                  label: l10n.reward,
                  value: _formatCurrency(entry.rewardAmount),
                ),
                if (entry.bonusAmount > 0) ...[
                  _PrizeValue(
                    label: l10n.bonus2,
                    value: _formatCurrency(entry.bonusAmount),
                  ),
                  _PrizeValue(label: l10n.gift, value: entry.giftDetails),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _PrizeValue extends StatelessWidget {
  const _PrizeValue({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.onTertiaryContainer;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(value, style: AppTypography.h4(color: color)),
        Text(label, style: AppTypography.caption(color: color)),
      ],
    );
  }
}

/// The branch's top three, showing name, points and prize only.
class _TopThreeList extends StatelessWidget {
  const _TopThreeList({required this.entries});

  final List<BranchCelebrationEntry> entries;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colors = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.topCarpenters,
          style: AppTypography.labelLarge(color: colors.onSurface),
        ),
        const SizedBox(height: AppSpacing.xs),
        for (final entry in entries)
          Card.filled(
            color: colors.surfaceContainerLow,
            margin: const EdgeInsets.only(bottom: 6),
            // Not a ListTile, whose fixed height clips large system text.
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.sm),
              child: Row(
                children: [
                  Icon(
                    Icons.emoji_events_rounded,
                    size: 30,
                    color: switch (entry.rank) {
                      1 => const Color(0xFFB77900),
                      2 => colors.outline,
                      _ => const Color(0xFF9A5B32),
                    },
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          entry.isCurrentUser
                              ? '${entry.name} (${l10n.diwaliYou})'
                              : entry.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTypography.labelLarge(
                            color: colors.onSurface,
                          ),
                        ),
                        Text(
                          l10n.bonus(
                            _formatCurrency(entry.bonusAmount),
                            entry.giftDetails,
                          ),
                          style: AppTypography.caption(
                            color: colors.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        _formatPoints(entry.points),
                        style: AppTypography.labelLarge(color: colors.primary),
                      ),
                      Text(
                        l10n.pointsLabel,
                        style: AppTypography.caption(
                          color: colors.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
      ],
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
