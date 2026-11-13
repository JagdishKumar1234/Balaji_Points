import 'package:balaji_points/services/branch/daily_winner_scope.dart';
import 'package:balaji_points/core/design/app_radius.dart';
import 'package:flutter/material.dart';
import 'package:balaji_points/presentation/widgets/shared/app_loader.dart';
import 'package:balaji_points/services/branch/current_branch_service.dart';
import 'package:balaji_points/l10n/app_localizations.dart';
import 'package:balaji_points/core/design/app_colors.dart';
import 'package:balaji_points/presentation/widgets/shared/app_text.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:go_router/go_router.dart';
import 'package:balaji_points/core/points/leaderboard_group.dart';
import 'package:balaji_points/presentation/widgets/shared/group_labels.dart';
import 'package:balaji_points/services/spin/daily_spin_service.dart';
import 'todays_eligible_carpenters.dart';

class DailySpinManagement extends StatefulWidget {
  const DailySpinManagement({super.key});

  @override
  State<DailySpinManagement> createState() => _DailySpinManagementState();
}

class _DailySpinManagementState extends State<DailySpinManagement>
    with TickerProviderStateMixin {
  bool _isSpinning = false;
  String? _winnerName;

  /// Each role group has its own draw, once a day.
  LeaderboardGroup _group = LeaderboardGroup.trade;
  final _spin = DailySpinService();
  static String get _today => DailyWinnerScope.dayKey(DateTime.now());
  AnimationController? _spinAnimationController;
  AnimationController? _pulseAnimationController;
  Animation<double>? _spinAnimation;
  Animation<double>? _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _spinAnimationController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    );
    _pulseAnimationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat(reverse: true);

    _spinAnimation = Tween<double>(begin: 0, end: 8 * 3.14159).animate(
      CurvedAnimation(
        parent: _spinAnimationController!,
        curve: Curves.easeInOutCubic,
      ),
    );

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.1).animate(
      CurvedAnimation(
        parent: _pulseAnimationController!,
        curve: Curves.easeInOut,
      ),
    );
  }

  @override
  void dispose() {
    _spinAnimationController?.dispose();
    _pulseAnimationController?.dispose();
    super.dispose();
  }

  /// Today's winner for this branch and the selected group, or null.
  Future<Map<String, dynamic>?> _todaysGroupWinner() => _spin.winnerOn(
    branchId: CurrentBranchService.adminBranchId,
    group: _group,
    date: _today,
  );

  Future<bool> _canSpinToday() => _spin.canSpin(
    branchId: CurrentBranchService.adminBranchId,
    group: _group,
    date: _today,
  );

  Future<void> _spinWheel() async {
    final canSpin = await _canSpinToday();
    if (!canSpin) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.schedule_rounded, color: context.themeOnSecondary),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    AppLocalizations.of(context)!.spinGroupDoneToday,
                    style: TextStyle(color: context.themeOnSecondary),
                  ),
                ),
              ],
            ),
            backgroundColor: context.themeSecondary,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: AppRadius.md12),
          ),
        );
      }
      return;
    }
    if (!mounted) return;
    final l10n = AppLocalizations.of(context)!;

    setState(() {
      _isSpinning = true;
      _winnerName = null;
    });

    _spinAnimationController?.reset();
    _spinAnimationController?.forward();

    try {
      final branchId = CurrentBranchService.adminBranchId ?? '';
      final results = await Future.wait([
        _spin.spin(branchId: branchId, group: _group, date: _today),
        // Let the wheel turn for its full animation.
        Future<void>.delayed(const Duration(seconds: 3)),
      ]);
      final winner = results.first as SpinCandidate?;
      if (winner == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                l10n.spinNoQualifiedToday,
                style: TextStyle(color: context.themeOnSecondary),
              ),
              backgroundColor: context.themeSecondary,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: AppRadius.md12),
            ),
          );
          setState(() => _isSpinning = false);
        }
        return;
      }
      final carpenterName = winner.name;

      if (mounted) {
        setState(() {
          _winnerName = carpenterName;
          _isSpinning = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.celebration_rounded, color: AppColors.white),
                const SizedBox(width: 12),
                Expanded(
                  child: AppText.section(
                    AppLocalizations.of(
                      context,
                    )!.isTodaySWinner('$carpenterName'),
                    color: AppColors.white,
                  ),
                ),
              ],
            ),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: AppRadius.md12),
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error_rounded, color: AppColors.white),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    AppLocalizations.of(context)!.error2('${e.toString()}'),
                  ),
                ),
              ],
            ),
            backgroundColor: context.themeError,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: AppRadius.md12),
          ),
        );
        setState(() => _isSpinning = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: context.themeBackground,
      child: CustomScrollView(
        slivers: [
          // Modern Header
          SliverToBoxAdapter(
            child: Container(
              decoration: BoxDecoration(
                color: context.themeContentColor,
                boxShadow: [
                  BoxShadow(
                    color: AppColors.black.withValues(alpha: 0.15),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: SafeArea(
                bottom: false,
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: AppColors.white.withValues(alpha: 0.2),
                              borderRadius: AppRadius.all16,
                            ),
                            child: const Icon(
                              Icons.casino_rounded,
                              color: AppColors.white,
                              size: 32,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                AppText.hero(
                                  AppLocalizations.of(context)!.dailySpin,
                                  color: AppColors.white,
                                ),
                                AppText.body(
                                  AppLocalizations.of(
                                    context,
                                  )!.selectALuckyWinner,
                                  color: AppColors.white.withValues(alpha: 0.9),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            icon: const Icon(
                              Icons.history_rounded,
                              color: AppColors.white,
                              size: 24,
                            ),
                            onPressed: () => GoRouter.of(
                              context,
                            ).push('/admin/spin-history'),
                            tooltip: AppLocalizations.of(
                              context,
                            )!.viewSpinHistory,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // Group switch: each group has its own draw.
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
              child: _buildGroupSwitch(),
            ),
          ),

          // Spin Wheel Section
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: _buildSpinSection(),
            ),
          ),

          // Today's Eligible Carpenters
          SliverToBoxAdapter(
            child: TodaysEligibleCarpenters(
              key: ValueKey(_group),
              group: _group,
              date: _today,
            ),
          ),

          // Today's Winners
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: _buildTodaysWinners(),
            ),
          ),

          // Monthly Winners
          SliverPadding(
            padding: const EdgeInsets.all(24),
            sliver: SliverToBoxAdapter(child: _buildMonthlyWinners()),
          ),
        ],
      ),
    );
  }

  Widget _buildGroupSwitch() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SegmentedButton<LeaderboardGroup>(
          segments: [
            for (final g in LeaderboardGroup.values)
              ButtonSegment(value: g, label: Text(g.shortLabel(context))),
          ],
          selected: {_group},
          showSelectedIcon: false,
          onSelectionChanged: _isSpinning
              ? null
              : (s) => setState(() {
                  _group = s.first;
                  _winnerName = null;
                }),
        ),
        const SizedBox(height: 6),
        AppText.bodySmall(
          AppLocalizations.of(context)!.spinGroupHint,
          color: context.themeTextSecondary,
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildSpinSection() {
    return FutureBuilder<bool>(
      future: _canSpinToday(),
      builder: (context, snapshot) {
        final canSpin = snapshot.data ?? false;

        return Container(
          decoration: BoxDecoration(
            color: context.themeSurface,
            borderRadius: AppRadius.all24,
            boxShadow: [
              BoxShadow(
                color: AppColors.black.withValues(alpha: 0.1),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          padding: const EdgeInsets.all(32),
          child: Column(
            children: [
              // Spinning Wheel Animation
              if (_spinAnimation != null)
                AnimatedBuilder(
                  animation: _spinAnimation!,
                  builder: (context, child) {
                    return Transform.rotate(
                      angle: _spinAnimation!.value,
                      child: Container(
                        width: 200,
                        height: 200,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: RadialGradient(
                            colors: [
                              context.themeSecondary,
                              AppColors.warning,
                              context.themeError,
                            ],
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.warning.withValues(alpha: 0.5),
                              blurRadius: 30,
                              spreadRadius: _isSpinning ? 10 : 5,
                            ),
                          ],
                        ),
                        child: Stack(
                          children: [
                            // Wheel segments
                            ...List.generate(8, (index) {
                              final angle = (index * 45) * (3.14159 / 180);
                              return Positioned.fill(
                                child: Transform.rotate(
                                  angle: angle,
                                  child: Container(
                                    decoration: BoxDecoration(
                                      border: Border(
                                        right: BorderSide(
                                          color: AppColors.white.withValues(
                                            alpha: 0.3,
                                          ),
                                          width: 2,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            }),
                            // Center
                            Center(
                              child: Container(
                                width: 120,
                                height: 120,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: AppColors.white,
                                  boxShadow: [
                                    BoxShadow(
                                      color: AppColors.black.withValues(
                                        alpha: 0.2,
                                      ),
                                      blurRadius: 10,
                                    ),
                                  ],
                                ),
                                child: Center(
                                  child: _isSpinning
                                      ? const Icon(
                                          Icons.autorenew_rounded,
                                          size: 48,
                                          color: AppColors.warning,
                                        )
                                      : Icon(
                                          Icons.stars_rounded,
                                          size: 56,
                                          color: AppColors.warning,
                                        ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              if (_spinAnimation == null)
                Container(
                  width: 200,
                  height: 200,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: context.themeTextSecondary,
                  ),
                  child: const Center(child: AppLoader()),
                ),

              const SizedBox(height: 32),

              // Winner Display
              if (_winnerName != null && !_isSpinning)
                TweenAnimationBuilder<double>(
                  duration: const Duration(milliseconds: 500),
                  tween: Tween(begin: 0.0, end: 1.0),
                  builder: (context, value, child) {
                    return Transform.scale(
                      scale: value,
                      child: Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: context.themeSurface,
                          borderRadius: AppRadius.all16,
                          border: Border.all(
                            color: AppColors.warning.withValues(alpha: 0.5),
                            width: 2,
                          ),
                        ),
                        child: Column(
                          children: [
                            const Icon(
                              Icons.celebration_rounded,
                              size: 48,
                              color: AppColors.warning,
                            ),
                            const SizedBox(height: 12),
                            Text(
                              AppLocalizations.of(
                                context,
                              )!.winner2('$_winnerName'),
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: context.themeContentColor,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),

              if (_winnerName == null || _isSpinning)
                const SizedBox(height: 24),

              // Status Badge
              FutureBuilder<Map<String, dynamic>?>(
                future: _todaysGroupWinner(),
                builder: (context, lastSpinSnapshot) {
                  final statusText = canSpin
                      ? AppLocalizations.of(context)!.readyToSpin
                      : AppLocalizations.of(context)!.spinGroupDoneToday;

                  return Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: canSpin
                          ? AppColors.successSoft
                          : context.themeSoftSurface,
                      borderRadius: AppRadius.md12,
                      border: Border.all(
                        color: canSpin
                            ? AppColors.success
                            : context.themeSecondary,
                        width: 2,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          canSpin
                              ? Icons.check_circle_rounded
                              : Icons.schedule_rounded,
                          color: canSpin
                              ? AppColors.successText
                              : context.themeSecondary,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        // Long messages wrap instead of overflowing.
                        Flexible(
                          child: AppText.section(
                            statusText,
                            textAlign: TextAlign.center,
                            color: canSpin
                                ? AppColors.successText
                                : context.themeSecondary,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),

              const SizedBox(height: 32),

              // Spin Button
              if (_pulseAnimation != null)
                AnimatedBuilder(
                  animation: _pulseAnimation!,
                  builder: (context, child) {
                    return Transform.scale(
                      scale: canSpin && !_isSpinning
                          ? _pulseAnimation!.value
                          : 1.0,
                      child: ElevatedButton(
                        onPressed: _isSpinning || !canSpin ? null : _spinWheel,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: canSpin
                              ? context.themePrimary
                              : context.themeTextSecondary,
                          foregroundColor: AppColors.white,
                          disabledBackgroundColor: context.themeSoftSurface,
                          disabledForegroundColor: context.themeTextSecondary,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 48,
                            vertical: 20,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: AppRadius.all16,
                          ),
                          elevation: _isSpinning ? 0 : 8,
                          shadowColor: context.themePrimary.withValues(
                            alpha: 0.5,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (_isSpinning)
                              SizedBox(
                                width: 24,
                                height: 24,
                                child: AppLoader(
                                  color: context.themeTextSecondary,
                                  strokeWidth: 2,
                                ),
                              )
                            else
                              const Icon(Icons.casino_rounded, size: 28),
                            const SizedBox(width: 12),
                            Text(
                              _isSpinning
                                  ? AppLocalizations.of(context)!.spinning
                                  : AppLocalizations.of(context)!.spinNow,
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1.2,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              if (_pulseAnimation == null)
                ElevatedButton(
                  onPressed: null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: context.themeSoftSurface,
                    foregroundColor: context.themeTextSecondary,
                    disabledBackgroundColor: context.themeSoftSurface,
                    disabledForegroundColor: context.themeTextSecondary,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 48,
                      vertical: 20,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: AppRadius.all16,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.casino_rounded, size: 28),
                      SizedBox(width: 12),
                      Text(
                        AppLocalizations.of(context)!.loading,
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.2,
                        ),
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

  Widget _buildTodaysWinners() {
    final today = DateTime.now();
    final todayStr =
        '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';

    return Container(
      decoration: BoxDecoration(
        color: context.themeSurface,
        borderRadius: AppRadius.all16,
        border: Border.all(color: context.themeBorder),
        boxShadow: [
          BoxShadow(
            color: AppColors.black.withValues(alpha: 0.06),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.today_rounded,
                color: context.themeContentColor,
                size: 24,
              ),
              const SizedBox(width: 12),
              Text(
                AppLocalizations.of(context)!.todaySWinners,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: context.themeTextPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('daily_prize_winners')
                .where('date', isEqualTo: todayStr)
                .snapshots(),
            builder: (context, snapshot) {
              // This branch's winners only.
              final branchDocs = (snapshot.data?.docs ?? [])
                  .where(
                    (doc) => DailyWinnerScope.belongsTo(
                      doc.data() as Map<String, dynamic>?,
                      CurrentBranchService.adminBranchId,
                      group: _group,
                    ),
                  )
                  .toList();
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(
                  child: Padding(
                    padding: EdgeInsets.all(20),
                    child: AppLoader(),
                  ),
                );
              }

              if (branchDocs.isEmpty) {
                return Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: context.themeSoftSurface,
                    borderRadius: AppRadius.md12,
                  ),
                  child: Center(
                    child: AppText.body(
                      AppLocalizations.of(context)!.noWinnersYetToday,
                      color: context.themeTextSecondary,
                    ),
                  ),
                );
              }

              return Column(
                children: branchDocs.map((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: context.themeSoftSurface,
                      borderRadius: AppRadius.md12,
                      border: Border.all(
                        color: AppColors.warning.withValues(alpha: 0.4),
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 50,
                          height: 50,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: context.themeSoftSurface,
                            image:
                                data['carpenterPhoto'] != null &&
                                    data['carpenterPhoto'].toString().isNotEmpty
                                ? DecorationImage(
                                    image: NetworkImage(data['carpenterPhoto']),
                                    fit: BoxFit.cover,
                                  )
                                : null,
                          ),
                          child:
                              data['carpenterPhoto'] == null ||
                                  data['carpenterPhoto'].toString().isEmpty
                              ? Icon(
                                  Icons.person_rounded,
                                  color: context.themeTextSecondary,
                                )
                              : null,
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Text(
                            data['carpenterName'] ??
                                AppLocalizations.of(context)!.unknown,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: context.themeTextPrimary,
                            ),
                          ),
                        ),
                        const Icon(
                          Icons.emoji_events_rounded,
                          color: AppColors.warning,
                          size: 32,
                        ),
                      ],
                    ),
                  );
                }).toList(),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildMonthlyWinners() {
    final now = DateTime.now();
    final firstDayOfMonth = DateTime(now.year, now.month, 1);
    final firstDayStr =
        '${firstDayOfMonth.year}-${firstDayOfMonth.month.toString().padLeft(2, '0')}-01';

    return Container(
      decoration: BoxDecoration(
        color: context.themeSurface,
        borderRadius: AppRadius.all16,
        border: Border.all(color: context.themeBorder),
        boxShadow: [
          BoxShadow(
            color: AppColors.black.withValues(alpha: 0.06),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.calendar_month_rounded,
                    color: context.themeContentColor,
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    AppLocalizations.of(context)!.monthlyWinners,
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: context.themeTextPrimary,
                    ),
                  ),
                ],
              ),
              ElevatedButton.icon(
                onPressed: () =>
                    GoRouter.of(context).push('/admin/spin-history'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: context.themePrimary,
                  foregroundColor: AppColors.white,
                  shape: RoundedRectangleBorder(borderRadius: AppRadius.md12),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                ),
                icon: const Icon(Icons.history_rounded, size: 18),
                label: Text(
                  AppLocalizations.of(context)!.fullHistory,
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('daily_prize_winners')
                .where('date', isGreaterThanOrEqualTo: firstDayStr)
                .orderBy('date', descending: true)
                .snapshots(),
            builder: (context, snapshot) {
              // This branch's winners only.
              final branchDocs = (snapshot.data?.docs ?? [])
                  .where(
                    (doc) => DailyWinnerScope.belongsTo(
                      doc.data() as Map<String, dynamic>?,
                      CurrentBranchService.adminBranchId,
                      group: _group,
                    ),
                  )
                  .toList();
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(
                  child: Padding(
                    padding: EdgeInsets.all(20),
                    child: AppLoader(),
                  ),
                );
              }

              if (branchDocs.isEmpty) {
                return Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: context.themeSoftSurface,
                    borderRadius: AppRadius.md12,
                  ),
                  child: Center(
                    child: Text(
                      AppLocalizations.of(context)!.noWinnersThisMonthYet,
                      style: TextStyle(color: context.themeTextSecondary),
                    ),
                  ),
                );
              }

              final Map<String, List<Map<String, dynamic>>> groupedWinners = {};
              for (var doc in branchDocs) {
                final data = doc.data() as Map<String, dynamic>;
                final date = data['date'] as String? ?? '';
                if (date.isNotEmpty) {
                  if (!groupedWinners.containsKey(date)) {
                    groupedWinners[date] = [];
                  }
                  groupedWinners[date]!.add(data);
                }
              }

              final sortedDates = groupedWinners.keys.toList()
                ..sort((a, b) => b.compareTo(a));

              return Column(
                children: sortedDates.map((date) {
                  final winners = groupedWinners[date]!;
                  final dateObj = DateTime.parse(date);
                  final formattedDate =
                      '${dateObj.day} ${_getMonthName(dateObj.month)} ${dateObj.year}';

                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                      color: context.themeSoftSurface,
                      borderRadius: AppRadius.md12,
                      border: Border.all(color: context.themeBorder),
                    ),
                    child: ExpansionTile(
                      leading: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: context.themeSecondary.withValues(alpha: 0.1),
                          borderRadius: AppRadius.sm8,
                        ),
                        child: Icon(
                          Icons.calendar_today_rounded,
                          color: context.themeContentColor,
                          size: 20,
                        ),
                      ),
                      title: AppText.section(
                        formattedDate,
                        color: context.themeTextPrimary,
                      ),
                      subtitle: AppText.body(
                        AppLocalizations.of(
                          context,
                        )!.winnersCount(winners.length),
                        color: context.themeTextSecondary,
                      ),
                      children: winners.map((winner) {
                        return ListTile(
                          leading: CircleAvatar(
                            backgroundColor: context.themeBorder,
                            backgroundImage:
                                winner['carpenterPhoto']
                                        ?.toString()
                                        .isNotEmpty ==
                                    true
                                ? NetworkImage(winner['carpenterPhoto'])
                                : null,
                            child:
                                winner['carpenterPhoto']?.toString().isEmpty ??
                                    true
                                ? Icon(
                                    Icons.person_rounded,
                                    color: context.themeTextSecondary,
                                  )
                                : null,
                          ),
                          title: AppText.label(
                            winner['carpenterName'] ??
                                AppLocalizations.of(context)!.unknown,
                          ),
                          trailing: const Icon(
                            Icons.emoji_events_rounded,
                            color: AppColors.warning,
                          ),
                        );
                      }).toList(),
                    ),
                  );
                }).toList(),
              );
            },
          ),
        ],
      ),
    );
  }

  String _getMonthName(int month) {
    final months = [
      AppLocalizations.of(context)!.jan,
      AppLocalizations.of(context)!.feb,
      AppLocalizations.of(context)!.mar,
      AppLocalizations.of(context)!.apr,
      AppLocalizations.of(context)!.may,
      AppLocalizations.of(context)!.jun,
      AppLocalizations.of(context)!.jul,
      AppLocalizations.of(context)!.aug,
      AppLocalizations.of(context)!.sep,
      AppLocalizations.of(context)!.oct,
      AppLocalizations.of(context)!.nov,
      AppLocalizations.of(context)!.dec,
    ];
    return months[month - 1];
  }
}
