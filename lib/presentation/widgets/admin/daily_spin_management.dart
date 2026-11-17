import 'dart:math' as math;

import 'package:balaji_points/core/design/app_colors.dart';
import 'package:balaji_points/core/design/app_radius.dart';
import 'package:balaji_points/core/design/app_typography.dart';
import 'package:balaji_points/core/firebase/app_firestore.dart';
import 'package:balaji_points/core/points/leaderboard_group.dart';
import 'package:balaji_points/core/spin/spin_prizes.dart';
import 'package:balaji_points/l10n/app_localizations.dart';
import 'package:balaji_points/presentation/widgets/admin/spin/prize_wheel.dart';
import 'package:balaji_points/presentation/widgets/shared/app_loader.dart';
import 'package:balaji_points/presentation/widgets/shared/group_labels.dart';
import 'package:balaji_points/services/branch/current_branch_service.dart';
import 'package:balaji_points/services/branch/daily_winner_scope.dart';
import 'package:balaji_points/services/spin/daily_spin_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import 'todays_eligible_carpenters.dart';

/// Admin Daily Spin: pick a group, spin the prize wheel, see today's
/// winner, who qualifies today and this month's winners. Only the admin
/// spins; members see the result.
class DailySpinManagement extends StatefulWidget {
  const DailySpinManagement({super.key});

  @override
  State<DailySpinManagement> createState() => _DailySpinManagementState();
}

class _DailySpinManagementState extends State<DailySpinManagement>
    with SingleTickerProviderStateMixin {
  final _spin = DailySpinService();
  final _random = math.Random();

  /// Each role group has its own draw, once a day.
  LeaderboardGroup _group = LeaderboardGroup.trade;
  bool _isSpinning = false;

  late final AnimationController _wheel = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 4200),
  );
  double _from = 0;
  double _to = 0;
  late Future<bool> _canSpin = _canSpinToday();

  static String get _today => DailyWinnerScope.dayKey(DateTime.now());

  double get _angle =>
      _from + (_to - _from) * Curves.easeOutCubic.transform(_wheel.value);

  @override
  void dispose() {
    _wheel.dispose();
    super.dispose();
  }

  Future<bool> _canSpinToday() => _spin.canSpin(
    branchId: CurrentBranchService.adminBranchId,
    group: _group,
    date: _today,
  );

  void _selectGroup(LeaderboardGroup g) => setState(() {
    _group = g;
    _canSpin = _canSpinToday();
  });

  /// Turns the wheel several times and stops on a random slice.
  void _startWheel() {
    const turn = 2 * math.pi;
    final slice = PrizeWheel.angleFor(
      _random.nextInt(spinPrizes.length),
      spinPrizes.length,
    );
    final current = _angle % turn;
    final target = (slice % turn + turn) % turn;
    _from = current;
    _to = current + 6 * turn + ((target - current) % turn + turn) % turn;
    _wheel
      ..reset()
      ..forward();
  }

  void _snack(String text, {Color? color, IconData? icon}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            if (icon != null) ...[
              Icon(icon, color: AppColors.white),
              const SizedBox(width: 12),
            ],
            Expanded(
              child: Text(text, style: const TextStyle(color: AppColors.white)),
            ),
          ],
        ),
        backgroundColor: color ?? AppColors.primary,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: AppRadius.md12),
      ),
    );
  }

  Future<void> _spinWheel() async {
    final l10n = AppLocalizations.of(context)!;
    if (!await _canSpinToday()) {
      _snack(l10n.spinGroupDoneToday, icon: Icons.schedule_rounded);
      setState(() => _canSpin = Future.value(false));
      return;
    }
    if (!mounted) return;
    setState(() => _isSpinning = true);
    _startWheel();

    try {
      final results = await Future.wait([
        _spin.spin(
          branchId: CurrentBranchService.adminBranchId ?? '',
          group: _group,
          date: _today,
        ),
        // Let the wheel finish turning.
        Future<void>.delayed(_wheel.duration!),
      ]);
      final winner = results.first as SpinCandidate?;
      if (!mounted) return;
      if (winner == null) {
        _snack(l10n.spinNoQualifiedToday, icon: Icons.info_outline_rounded);
      } else {
        _snack(
          l10n.isTodaySWinner(winner.name),
          color: AppColors.success,
          icon: Icons.celebration_rounded,
        );
      }
    } catch (e) {
      _snack(l10n.error2(e.toString()), color: AppColors.error);
    } finally {
      if (mounted) {
        setState(() {
          _isSpinning = false;
          _canSpin = _canSpinToday();
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: context.themeBackground,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        children: [
          _GroupSwitch(
            group: _group,
            enabled: !_isSpinning,
            onChanged: _selectGroup,
          ),
          const SizedBox(height: 14),
          _wheelCard(),
          const SizedBox(height: 14),
          _TodaysWinner(group: _group, date: _today),
          const SizedBox(height: 14),
          TodaysEligibleCarpenters(
            key: ValueKey(_group),
            group: _group,
            date: _today,
          ),
          const SizedBox(height: 14),
          _MonthWinners(group: _group),
        ],
      ),
    );
  }

  Widget _wheelCard() {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      key: const ValueKey('admin-spin-card'),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [AppColors.primary, AppColors.primaryLight],
        ),
        borderRadius: AppRadius.all24,
        boxShadow: [
          BoxShadow(
            color: AppColors.black.withValues(alpha: 0.18),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      padding: const EdgeInsets.fromLTRB(16, 18, 16, 18),
      child: Column(
        children: [
          Text(
            l10n.spinWheelTitle,
            textAlign: TextAlign.center,
            style: AppTypography.section(
              color: AppColors.gold,
            ).copyWith(fontSize: 22, letterSpacing: 0.5),
          ),
          const SizedBox(height: 2),
          Text(
            l10n.spinWheelSubtitle,
            textAlign: TextAlign.center,
            style: AppTypography.bodyMedium().copyWith(
              color: AppColors.white.withValues(alpha: 0.85),
            ),
          ),
          const SizedBox(height: 16),
          LayoutBuilder(
            builder: (context, c) {
              final size = math.min(c.maxWidth - 8, 320.0);
              return AnimatedBuilder(
                animation: _wheel,
                builder: (_, __) => PrizeWheel(angle: _angle, size: size),
              );
            },
          ),
          const SizedBox(height: 16),
          FutureBuilder<bool>(
            future: _canSpin,
            builder: (context, snap) {
              final loading = snap.connectionState != ConnectionState.done;
              final canSpin = snap.data ?? false;
              return Column(
                children: [
                  if (!loading) _StatusChip(canSpin: canSpin),
                  const SizedBox(height: 14),
                  _spinButton(
                    enabled: canSpin && !_isSpinning && !loading,
                    label: loading
                        ? l10n.loading
                        : (_isSpinning ? l10n.spinning : l10n.spinNow),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _spinButton({required bool enabled, required String label}) {
    return SizedBox(
      width: double.infinity,
      child: FilledButton(
        key: const ValueKey('admin-spin-button'),
        onPressed: enabled ? _spinWheel : null,
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.gold,
          foregroundColor: AppColors.primary,
          disabledBackgroundColor: AppColors.white.withValues(alpha: 0.12),
          disabledForegroundColor: AppColors.white.withValues(alpha: 0.6),
          minimumSize: const Size.fromHeight(54),
          shape: const StadiumBorder(),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (_isSpinning)
              const SizedBox(
                width: 22,
                height: 22,
                child: AppLoader(color: AppColors.primary, strokeWidth: 2),
              )
            else
              const Icon(Icons.casino_rounded, size: 24),
            const SizedBox(width: 10),
            Flexible(
              child: Text(
                label,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Carpenter & Interior / Architect & Engineer.
class _GroupSwitch extends StatelessWidget {
  const _GroupSwitch({
    required this.group,
    required this.enabled,
    required this.onChanged,
  });

  final LeaderboardGroup group;
  final bool enabled;
  final ValueChanged<LeaderboardGroup> onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SegmentedButton<LeaderboardGroup>(
          segments: [
            for (final g in LeaderboardGroup.values)
              ButtonSegment(value: g, label: Text(g.shortLabel(context))),
          ],
          selected: {group},
          showSelectedIcon: false,
          onSelectionChanged: enabled ? (s) => onChanged(s.first) : null,
        ),
        const SizedBox(height: 6),
        Text(
          AppLocalizations.of(context)!.spinGroupHint,
          textAlign: TextAlign.center,
          style: AppTypography.caption(color: context.themeTextSecondary),
        ),
      ],
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.canSpin});
  final bool canSpin;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.white.withValues(alpha: 0.1),
        borderRadius: AppRadius.pill,
        border: Border.all(
          color: canSpin
              ? AppColors.gold
              : AppColors.white.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            canSpin ? Icons.check_circle_rounded : Icons.schedule_rounded,
            color: canSpin ? AppColors.gold : AppColors.white,
            size: 18,
          ),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              canSpin ? l10n.readyToSpin : l10n.spinGroupDoneToday,
              textAlign: TextAlign.center,
              style: AppTypography.label(color: AppColors.white),
            ),
          ),
        ],
      ),
    );
  }
}

/// Shared card frame for the sections under the wheel.
class _Section extends StatelessWidget {
  const _Section({
    required this.icon,
    required this.title,
    required this.child,
    this.trailing,
  });

  final IconData icon;
  final String title;
  final Widget child;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: context.themeCard,
        borderRadius: AppRadius.all16,
        border: Border.all(color: context.themeBorder),
      ),
      padding: const EdgeInsets.fromLTRB(16, 12, 12, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(icon, size: 20, color: context.themeContentColor),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: AppTypography.section(color: context.themeTextPrimary),
                ),
              ),
              if (trailing != null) trailing!,
            ],
          ),
          const SizedBox(height: 10),
          child,
        ],
      ),
    );
  }
}

Widget _avatar(BuildContext context, String? url, {double size = 44}) {
  final valid = url != null && url.trim().startsWith('http');
  return Container(
    width: size,
    height: size,
    decoration: BoxDecoration(
      shape: BoxShape.circle,
      color: AppColors.primary,
      border: Border.all(color: AppColors.gold, width: 1.5),
    ),
    clipBehavior: Clip.antiAlias,
    child: valid
        ? Image.network(
            url.trim(),
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) =>
                const Icon(Icons.person_rounded, color: AppColors.gold),
          )
        : const Icon(Icons.person_rounded, color: AppColors.gold),
  );
}

Widget _emptyNote(BuildContext context, String text) => Container(
  padding: const EdgeInsets.all(14),
  decoration: BoxDecoration(
    color: context.themeSoftSurface,
    borderRadius: AppRadius.md12,
  ),
  child: Text(
    text,
    textAlign: TextAlign.center,
    style: AppTypography.bodyMedium().copyWith(
      color: context.themeTextSecondary,
    ),
  ),
);

/// Today's winner of the selected group in this branch.
class _TodaysWinner extends StatelessWidget {
  const _TodaysWinner({required this.group, required this.date});
  final LeaderboardGroup group;
  final String date;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: appFirestore
          .collection('daily_prize_winners')
          .where('date', isEqualTo: date)
          .snapshots(),
      builder: (context, snap) {
        final winners = (snap.data?.docs ?? [])
            .map((d) => d.data())
            .where(
              (d) => DailyWinnerScope.belongsTo(
                d,
                CurrentBranchService.adminBranchId,
                group: group,
              ),
            )
            .toList();
        return _Section(
          icon: Icons.emoji_events_rounded,
          title: l10n.spinTodayWinnerLabel,
          child: snap.connectionState == ConnectionState.waiting
              ? const Padding(
                  padding: EdgeInsets.all(12),
                  child: Center(child: AppLoader()),
                )
              : winners.isEmpty
              ? _emptyNote(context, l10n.noWinnersYetToday)
              : Column(
                  children: [
                    for (final w in winners)
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: context.themeGoldSoft,
                          borderRadius: AppRadius.md12,
                          border: Border.all(color: AppColors.gold),
                        ),
                        child: Row(
                          children: [
                            _avatar(
                              context,
                              w['carpenterPhoto'] as String?,
                              size: 52,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                (w['carpenterName'] as String?)
                                            ?.trim()
                                            .isNotEmpty ==
                                        true
                                    ? w['carpenterName'] as String
                                    : l10n.unknown,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: AppTypography.labelLarge().copyWith(
                                  fontSize: 17,
                                  color: context.themeTextPrimary,
                                ),
                              ),
                            ),
                            const Icon(
                              Icons.celebration_rounded,
                              color: AppColors.gold,
                              size: 30,
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
        );
      },
    );
  }
}

/// This month's winners of the selected group, newest first.
class _MonthWinners extends StatelessWidget {
  const _MonthWinners({required this.group});
  final LeaderboardGroup group;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final now = DateTime.now();
    final firstDay = DateFormat('yyyy-MM-01').format(now);
    final locale = Localizations.localeOf(context).toString();

    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: appFirestore
          .collection('daily_prize_winners')
          .where('date', isGreaterThanOrEqualTo: firstDay)
          .orderBy('date', descending: true)
          .snapshots(),
      builder: (context, snap) {
        final winners = (snap.data?.docs ?? [])
            .map((d) => d.data())
            .where(
              (d) => DailyWinnerScope.belongsTo(
                d,
                CurrentBranchService.adminBranchId,
                group: group,
              ),
            )
            .toList();
        return _Section(
          icon: Icons.calendar_month_rounded,
          title: l10n.spinThisMonth,
          trailing: TextButton(
            key: const ValueKey('admin-spin-full-history'),
            onPressed: () => GoRouter.of(context).push('/admin/spin-history'),
            child: Text(l10n.fullHistory),
          ),
          child: snap.connectionState == ConnectionState.waiting
              ? const Padding(
                  padding: EdgeInsets.all(12),
                  child: Center(child: AppLoader()),
                )
              : winners.isEmpty
              ? _emptyNote(context, l10n.noWinnersThisMonthYet)
              : Column(
                  children: [
                    for (final (i, w) in winners.indexed) ...[
                      if (i > 0)
                        Divider(height: 1, color: context.themeDivider),
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Row(
                          children: [
                            _DateBadge(
                              date: DateTime.tryParse(
                                w['date'] as String? ?? '',
                              ),
                              locale: locale,
                            ),
                            const SizedBox(width: 12),
                            _avatar(context, w['carpenterPhoto'] as String?),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                (w['carpenterName'] as String?)
                                            ?.trim()
                                            .isNotEmpty ==
                                        true
                                    ? w['carpenterName'] as String
                                    : l10n.unknown,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: AppTypography.label(
                                  color: context.themeTextPrimary,
                                ),
                              ),
                            ),
                            const Icon(
                              Icons.emoji_events_rounded,
                              color: AppColors.gold,
                              size: 22,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
        );
      },
    );
  }
}

class _DateBadge extends StatelessWidget {
  const _DateBadge({required this.date, required this.locale});
  final DateTime? date;
  final String locale;

  @override
  Widget build(BuildContext context) {
    final d = date;
    return Container(
      width: 46,
      padding: const EdgeInsets.symmetric(vertical: 4),
      decoration: BoxDecoration(
        color: context.themeSoftSurface,
        borderRadius: AppRadius.sm8,
        border: Border.all(color: context.themeBorder),
      ),
      child: Column(
        children: [
          Text(
            d == null ? '–' : '${d.day}',
            style: AppTypography.section(color: context.themeTextPrimary),
          ),
          if (d != null)
            Text(
              DateFormat.MMM(locale).format(d),
              style: AppTypography.caption(color: context.themeTextSecondary),
            ),
        ],
      ),
    );
  }
}
