import 'package:balaji_points/core/design/app_radius.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:balaji_points/core/design/app_animations.dart';
import 'package:balaji_points/core/design/app_colors.dart';
import 'package:balaji_points/core/design/app_typography.dart';
import 'package:balaji_points/core/layout/carpenter_shell_layout.dart';
import 'package:balaji_points/l10n/app_localizations.dart';
import 'package:balaji_points/core/utils/points_utils.dart';
import 'package:balaji_points/providers/wallet_provider.dart';
import 'package:balaji_points/services/user/user_points_sync_service.dart';
import 'package:balaji_points/presentation/widgets/carpenter/home_nav_bar.dart';
import 'package:balaji_points/presentation/widgets/shared/app_card.dart';
import 'package:balaji_points/presentation/widgets/shared/app_loader.dart';

class WalletPage extends ConsumerWidget {
  const WalletPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final walletState = ref.watch(walletProvider);
    final carpenterPoints = ref.watch(carpenterPointsProvider);
    final pointsLoading = !carpenterPoints.loaded;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final mq = MediaQuery.of(context);
    final bottomPadding = CarpenterShellLayout.bottomPaddingForScrollView(mq);
    final l10n = AppLocalizations.of(context)!;
    final canvas = isDark ? theme.colorScheme.surface : context.themeBackground;

    final ids = walletState.carpenterIds;
    final idsReady = walletState.idsLoaded && ids.isNotEmpty;

    return Scaffold(
      backgroundColor: canvas,
      body: Column(
        children: [
          HomeNavBar(
            title: l10n.wallet,
            showLogo: false,
            showProfileButton: false,
            subtitle: 'Track your points and manage your bills',
            actions: [
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: IconButton(
                  onPressed: () => context.push('/add-bill'),
                  icon: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: context.themePrimary,
                      borderRadius: AppRadius.md12,
                    ),
                    child: const Icon(
                      Icons.add,
                      color: AppColors.white,
                      size: 20,
                    ),
                  ),
                ),
              ),
            ],
          ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: () async {
                await ref.read(carpenterPointsProvider.notifier).refresh();
                await ref.read(walletProvider.notifier).refresh();
              },
              color: context.themePrimary,
              backgroundColor: canvas,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: EdgeInsets.fromLTRB(16, 16, 16, bottomPadding),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Total points card with tier progress
                    walletState.loading || pointsLoading
                        ? _ShimmerPointsCard()
                        : _DesignPointsCard(
                            points: carpenterPoints.totalPoints,
                            tier: carpenterPoints.tier,
                          ).enterCard(delay: AppAnimations.stagger(1)),
                    const SizedBox(height: 16),

                    // Status pills row (Pending, Approved, Rejected)
                    Row(
                      children: [
                        Expanded(
                          child: _StatusPill(
                            icon: Icons.schedule,
                            label: l10n.pending,
                            color: AppColors.warning,
                            child: walletState.loading || !idsReady
                                ? _statLoading(context)
                                : _PendingCount(ids: ids),
                          ).fadeIn(delay: AppAnimations.stagger(2)),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _StatusPill(
                            icon: Icons.check_circle,
                            label: l10n.approved,
                            color: AppColors.success,
                            child: walletState.loading || !idsReady
                                ? _statLoading(context)
                                : _ApprovedCount(ids: ids),
                          ).fadeIn(delay: AppAnimations.stagger(2)),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _StatusPill(
                            icon: Icons.cancel,
                            label: 'Rejected',
                            color: AppColors.error,
                            child: walletState.loading || !idsReady
                                ? _statLoading(context)
                                : _RejectedCount(ids: ids),
                          ).fadeIn(delay: AppAnimations.stagger(2)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // Bill History section with filter tabs
                    _BillHistorySectionHeader().fadeIn(
                      delay: AppAnimations.stagger(3),
                    ),
                    const SizedBox(height: 12),

                    // Bill history with filter
                    if (!idsReady)
                      const _BillsLoading()
                    else
                      _BillHistoryTableWithFilter(ids: ids),

                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _statLoading(BuildContext context) {
    return Text(
      '...',
      style: AppTypography.h4(color: context.themeTextPrimary),
    );
  }
}

// ---------------------------------------------------------------------------
// Shimmer
// ---------------------------------------------------------------------------

class _ShimmerPointsCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      height: 110,
      decoration: BoxDecoration(
        color: context.themeSoftSurface,
        borderRadius: AppRadius.all16,
      ),
    ).animate(onPlay: (c) => c.repeat()).shimmer(duration: 1200.ms);
  }
}

// ---------------------------------------------------------------------------
// Design Points Card - With tier progress
// ---------------------------------------------------------------------------

// Tier threshold helpers - same as home screen
int _tierNextThreshold(String tier) {
  switch (tier) {
    case 'Silver':
      return 5000;
    case 'Gold':
      return 10000;
    case 'Platinum':
      return 10000;
    default:
      return 2000;
  }
}

int _tierCurrentThreshold(String tier) {
  switch (tier) {
    case 'Silver':
      return 2000;
    case 'Gold':
      return 5000;
    case 'Platinum':
      return 10000;
    default:
      return 0;
  }
}

String _tierNextLabel(String tier) {
  switch (tier) {
    case 'Bronze':
      return 'Silver';
    case 'Silver':
      return 'Gold';
    case 'Gold':
      return 'Platinum';
    default:
      return 'Max';
  }
}

class _DesignPointsCard extends StatelessWidget {
  final double points;
  final String tier;
  const _DesignPointsCard({required this.points, required this.tier});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final pointsDisplay = PointsUtils.formatPoints(points);

    // Calculate tier progress using home screen logic
    final currentThreshold = _tierCurrentThreshold(tier);
    final nextThreshold = _tierNextThreshold(tier);
    final nextLabel = _tierNextLabel(tier);
    final isPlatinum = tier == 'Platinum';

    final progress = isPlatinum
        ? 1.0
        : ((points - currentThreshold) / (nextThreshold - currentThreshold))
              .clamp(0.0, 1.0);
    final pointsToNext = isPlatinum
        ? 0
        : (nextThreshold - points).clamp(0, nextThreshold).toInt();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            context.themePrimary,
            context.themePrimary.withValues(alpha: 0.88),
            context.themePrimary.withValues(alpha: 0.75),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: AppRadius.all16,
        boxShadow: [
          BoxShadow(
            color: context.themePrimary.withValues(alpha: 0.30),
            blurRadius: 12,
            spreadRadius: 1,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Top row: Points and tier badge
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.totalPoints,
                    style: AppTypography.bodySmall(
                      color: AppColors.white.withValues(alpha: 0.85),
                    ).copyWith(fontWeight: FontWeight.w600, fontSize: 11),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    pointsDisplay,
                    style: AppTypography.pointsHero(
                      color: AppColors.white,
                    ).copyWith(fontWeight: FontWeight.w900, fontSize: 36),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: AppColors.white.withValues(alpha: 0.15),
                  borderRadius: AppRadius.all16,
                  border: Border.all(
                    color: AppColors.white.withValues(alpha: 0.25),
                  ),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      tier,
                      style: AppTypography.bodySmall(
                        color: AppColors.white,
                      ).copyWith(fontWeight: FontWeight.w800, fontSize: 12),
                    ),
                    const SizedBox(height: 1),
                    const Icon(Icons.shield, size: 14, color: AppColors.white),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Next tier progress section - dynamic based on tier
          if (!isPlatinum)
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Next Tier: $nextLabel',
                  style: AppTypography.bodySmall(
                    color: AppColors.white,
                  ).copyWith(fontWeight: FontWeight.w700, fontSize: 12),
                ),
                const SizedBox(height: 6),
                // Progress bar
                ClipRRect(
                  borderRadius: AppRadius.sm8,
                  child: LinearProgressIndicator(
                    value: progress,
                    minHeight: 5,
                    backgroundColor: AppColors.white.withValues(alpha: 0.2),
                    valueColor: AlwaysStoppedAnimation(
                      AppColors.white.withValues(alpha: 0.9),
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '$pointsToNext pts to next tier',
                  style: AppTypography.labelSmall(
                    color: AppColors.white,
                  ).copyWith(fontWeight: FontWeight.w500, fontSize: 10),
                ),
              ],
            )
          else
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    const Icon(Icons.star, size: 14, color: AppColors.white),
                    const SizedBox(width: 6),
                    Text(
                      'Platinum Tier - Maximum Level',
                      style: AppTypography.bodySmall(
                        color: AppColors.white,
                      ).copyWith(fontWeight: FontWeight.w700, fontSize: 12),
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

// ---------------------------------------------------------------------------
// Status Pill Card
// ---------------------------------------------------------------------------

class _StatusPill extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final Widget child;

  const _StatusPill({
    required this.icon,
    required this.label,
    required this.color,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final bg = isDark ? theme.colorScheme.surface : AppColors.white;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: AppRadius.all16,
        border: Border.all(
          color: context.themeTextPrimary.withValues(alpha: 0.06),
        ),
        boxShadow: [
          BoxShadow(
            color: context.themeTextPrimary.withValues(alpha: 0.02),
            blurRadius: 6,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              borderRadius: AppRadius.md12,
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(height: 8),
          DefaultTextStyle(
            style: AppTypography.h4(
              color: context.themeTextPrimary,
            ).copyWith(fontWeight: FontWeight.w800, fontSize: 22),
            child: child,
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: AppTypography.bodySmall(
              color: color,
            ).copyWith(fontWeight: FontWeight.w700, fontSize: 11),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Live count widgets
// ---------------------------------------------------------------------------

class _PendingCount extends StatelessWidget {
  final List<String> ids;
  const _PendingCount({required this.ids});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('bills')
          .where('carpenterId', whereIn: ids)
          .where('status', isEqualTo: 'pending')
          .snapshots(),
      builder: (context, snap) {
        final count = snap.hasData ? snap.data!.docs.length : 0;
        return Text(
          '$count',
          style: AppTypography.h4(
            color: context.themeTextPrimary,
          ).copyWith(fontWeight: FontWeight.w800),
        );
      },
    );
  }
}

class _ApprovedCount extends StatelessWidget {
  final List<String> ids;
  const _ApprovedCount({required this.ids});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('bills')
          .where('carpenterId', whereIn: ids)
          .where('status', isEqualTo: 'approved')
          .snapshots(),
      builder: (context, snap) {
        final count = snap.hasData ? snap.data!.docs.length : 0;
        return Text(
          '$count',
          style: AppTypography.h4(
            color: context.themeTextPrimary,
          ).copyWith(fontWeight: FontWeight.w800),
        );
      },
    );
  }
}

class _RejectedCount extends StatelessWidget {
  final List<String> ids;
  const _RejectedCount({required this.ids});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('bills')
          .where('carpenterId', whereIn: ids)
          .where('status', isEqualTo: 'rejected')
          .snapshots(),
      builder: (context, snap) {
        final count = snap.hasData ? snap.data!.docs.length : 0;
        return Text(
          '$count',
          style: AppTypography.h4(
            color: context.themeTextPrimary,
          ).copyWith(fontWeight: FontWeight.w800),
        );
      },
    );
  }
}

// ---------------------------------------------------------------------------
// Bill History Section Header with Filter
// ---------------------------------------------------------------------------

class _BillHistorySectionHeader extends StatelessWidget {
  const _BillHistorySectionHeader();

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: context.themePrimary.withValues(alpha: 0.1),
                borderRadius: AppRadius.sm8,
              ),
              child: Icon(
                Icons.receipt_long_outlined,
                color: context.themePrimary,
                size: 18,
              ),
            ),
            const SizedBox(width: 10),
            Text(
              'Bill History',
              style: AppTypography.h5(
                color: context.themeTextPrimary,
              ).copyWith(fontWeight: FontWeight.w700),
            ),
          ],
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: context.themeTextPrimary.withValues(alpha: 0.05),
            borderRadius: AppRadius.all16,
            border: Border.all(
              color: context.themeTextPrimary.withValues(alpha: 0.1),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.filter_list, size: 14, color: context.themePrimary),
              const SizedBox(width: 4),
              Text(
                'Filter',
                style: AppTypography.labelSmall(
                  color: context.themePrimary,
                ).copyWith(fontWeight: FontWeight.w700),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Bills list
// ---------------------------------------------------------------------------

class _BillsLoading extends StatelessWidget {
  const _BillsLoading();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.all(32),
      child: Center(child: AppLoader()),
    );
  }
}

// ---------------------------------------------------------------------------
// Bill History Table with Filter Tabs
// ---------------------------------------------------------------------------

class _BillHistoryTableWithFilter extends ConsumerStatefulWidget {
  final List<String> ids;
  const _BillHistoryTableWithFilter({required this.ids});

  @override
  ConsumerState<_BillHistoryTableWithFilter> createState() =>
      _BillHistoryTableWithFilterState();
}

class _BillHistoryTableWithFilterState
    extends ConsumerState<_BillHistoryTableWithFilter> {
  String selectedFilter = 'all';

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Filter tabs
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              _FilterTab(
                label: 'All',
                isSelected: selectedFilter == 'all',
                onTap: () => setState(() => selectedFilter = 'all'),
              ),
              const SizedBox(width: 8),
              _FilterTab(
                label: 'Approved',
                isSelected: selectedFilter == 'approved',
                onTap: () => setState(() => selectedFilter = 'approved'),
                color: AppColors.success,
              ),
              const SizedBox(width: 8),
              _FilterTab(
                label: 'Pending',
                isSelected: selectedFilter == 'pending',
                onTap: () => setState(() => selectedFilter = 'pending'),
                color: AppColors.warning,
              ),
              const SizedBox(width: 8),
              _FilterTab(
                label: 'Rejected',
                isSelected: selectedFilter == 'rejected',
                onTap: () => setState(() => selectedFilter = 'rejected'),
                color: AppColors.error,
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        // Bill list based on filter
        _BillListByFilter(ids: widget.ids, filter: selectedFilter),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Filter Tab Button
// ---------------------------------------------------------------------------

class _FilterTab extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  final Color? color;

  const _FilterTab({
    required this.label,
    required this.isSelected,
    required this.onTap,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final tabColor = color ?? context.themePrimary;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? tabColor : context.themeSurface,
          borderRadius: AppRadius.all16,
          border: isSelected
              ? null
              : Border.all(
                  color: context.themeTextPrimary.withValues(alpha: 0.1),
                ),
        ),
        child: Text(
          label,
          style: AppTypography.bodySmall(
            color: isSelected ? AppColors.white : tabColor,
          ).copyWith(fontWeight: FontWeight.w700),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Bill List by Filter
// ---------------------------------------------------------------------------

class _BillListByFilter extends StatelessWidget {
  final List<String> ids;
  final String filter;

  const _BillListByFilter({required this.ids, required this.filter});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: _buildStream(),
      builder: (context, snap) {
        if (snap.hasError) {
          return _errorCard(context, snap.error.toString());
        }
        if (snap.connectionState == ConnectionState.waiting) {
          return const _BillsLoading();
        }

        if (!snap.hasData || snap.data!.docs.isEmpty) {
          return _emptyCard(context);
        }

        final bills = snap.data!.docs;
        double approvedTotal = 0;
        int approvedCount = 0;

        for (final doc in bills) {
          final bill = doc.data() as Map<String, dynamic>;
          if ((bill['status'] as String?) == 'approved') {
            approvedTotal += (bill['pointsEarned'] as num?)?.toDouble() ?? 0;
            approvedCount++;
          }
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Bill list
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: bills.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final billData = bills[index].data() as Map<String, dynamic>;
                return _DesignBillCard(bill: billData);
              },
            ),
            const SizedBox(height: 12),
            // Summary card
            _SummaryCard(
              approvedCount: approvedCount,
              approvedTotal: approvedTotal,
            ),
          ],
        );
      },
    );
  }

  Stream<QuerySnapshot> _buildStream() {
    if (filter == 'all') {
      return FirebaseFirestore.instance
          .collection('bills')
          .where('carpenterId', whereIn: ids)
          .orderBy('createdAt', descending: true)
          .snapshots();
    } else {
      return FirebaseFirestore.instance
          .collection('bills')
          .where('carpenterId', whereIn: ids)
          .where('status', isEqualTo: filter)
          .orderBy('createdAt', descending: true)
          .snapshots();
    }
  }

  Widget _errorCard(BuildContext context, String error) {
    return AppCard(
      padding: const EdgeInsets.all(22),
      child: Column(
        children: [
          Icon(Icons.error_outline, size: 48, color: context.themeError),
          const SizedBox(height: 12),
          Text(
            'Error loading bills',
            style: AppTypography.bodyLarge(
              color: context.themeError,
            ).copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          Text(
            error,
            style: AppTypography.labelSmall(
              color: context.themeTextPrimary.withValues(alpha: 0.5),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _emptyCard(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.all(22),
      child: Column(
        children: [
          Icon(
            Icons.receipt_long_outlined,
            size: 48,
            color: context.themeTextPrimary.withValues(alpha: 0.3),
          ),
          const SizedBox(height: 12),
          Text(
            'No bills yet',
            style: AppTypography.bodyLarge(
              color: context.themeTextPrimary.withValues(alpha: 0.6),
            ).copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          Text(
            'Submit your first bill to get started',
            style: AppTypography.bodySmall(
              color: context.themeTextPrimary.withValues(alpha: 0.5),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Summary Card
// ---------------------------------------------------------------------------

class _SummaryCard extends StatelessWidget {
  final int approvedCount;
  final double approvedTotal;

  const _SummaryCard({
    required this.approvedCount,
    required this.approvedTotal,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: context.themeSurface,
        borderRadius: AppRadius.all16,
        border: Border.all(
          color: context.themeTextPrimary.withValues(alpha: 0.08),
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Total Approved Points',
                style: AppTypography.bodySmall(
                  color: context.themeTextPrimary.withValues(alpha: 0.7),
                ).copyWith(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 2),
              Text(
                approvedTotal.toStringAsFixed(2),
                style: AppTypography.h4(
                  color: context.themeTextPrimary,
                ).copyWith(fontWeight: FontWeight.w800, fontSize: 22),
              ),
            ],
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: context.themePrimary,
              borderRadius: AppRadius.md12,
            ),
            child: Icon(
              Icons.account_balance_wallet,
              color: AppColors.white,
              size: 20,
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Old Bill History Table (Deprecated)
// ---------------------------------------------------------------------------

class _BillHistoryTable extends ConsumerStatefulWidget {
  final List<String> ids;
  const _BillHistoryTable({required this.ids});

  @override
  ConsumerState<_BillHistoryTable> createState() => _BillHistoryTableState();
}

class _BillHistoryTableState extends ConsumerState<_BillHistoryTable> {
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('bills')
          .where('carpenterId', whereIn: widget.ids)
          .orderBy('createdAt', descending: true)
          .snapshots(),
      builder: (context, snap) {
        if (snap.hasError) {
          return _errorCard(context, snap.error.toString());
        }
        if (snap.connectionState == ConnectionState.waiting) {
          return const _BillsLoading();
        }

        if (!snap.hasData || snap.data!.docs.isEmpty) {
          return _emptyCard(context);
        }

        final bills = snap.data!.docs;
        double approvedTotal = 0;
        int approvedCount = 0;

        for (final doc in bills) {
          final bill = doc.data() as Map<String, dynamic>;
          if ((bill['status'] as String?) == 'approved') {
            approvedTotal += (bill['pointsEarned'] as num?)?.toDouble() ?? 0;
            approvedCount++;
          }
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Bill list
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: bills.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final billData = bills[index].data() as Map<String, dynamic>;
                return _DesignBillCard(bill: billData);
              },
            ),
            const SizedBox(height: 12),
            // Summary card - Compact
            Container(
              decoration: BoxDecoration(
                color: context.themePrimary.withValues(alpha: 0.08),
                borderRadius: AppRadius.md12,
                border: Border.all(
                  color: context.themePrimary.withValues(alpha: 0.12),
                ),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Approved',
                        style: AppTypography.labelSmall(
                          color: context.themeTextPrimary.withValues(
                            alpha: 0.7,
                          ),
                        ).copyWith(fontSize: 11, fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '$approvedCount bills',
                        style: AppTypography.bodySmall(
                          color: context.themeTextPrimary.withValues(
                            alpha: 0.5,
                          ),
                        ).copyWith(fontSize: 11),
                      ),
                    ],
                  ),
                  Container(
                    decoration: BoxDecoration(
                      color: context.themePrimary,
                      borderRadius: AppRadius.sm8,
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    child: Text(
                      approvedTotal.toStringAsFixed(0),
                      style: AppTypography.bodySmall(
                        color: AppColors.white,
                      ).copyWith(fontWeight: FontWeight.w800, fontSize: 13),
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _errorCard(BuildContext context, String error) {
    return AppCard(
      padding: const EdgeInsets.all(22),
      child: Column(
        children: [
          Icon(Icons.error_outline, size: 48, color: context.themeError),
          const SizedBox(height: 12),
          Text(
            'Error loading bills',
            style: AppTypography.bodyLarge(
              color: context.themeError,
            ).copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          Text(
            error,
            style: AppTypography.labelSmall(
              color: context.themeTextPrimary.withValues(alpha: 0.5),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _emptyCard(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.all(22),
      child: Column(
        children: [
          Icon(
            Icons.receipt_long_outlined,
            size: 48,
            color: context.themeTextPrimary.withValues(alpha: 0.3),
          ),
          const SizedBox(height: 12),
          Text(
            'No bills yet',
            style: AppTypography.bodyLarge(
              color: context.themeTextPrimary.withValues(alpha: 0.6),
            ).copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          Text(
            'Submit your first bill to get started',
            style: AppTypography.bodySmall(
              color: context.themeTextPrimary.withValues(alpha: 0.5),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Design Bill Card - With thumbnail and full details
// ---------------------------------------------------------------------------

class _DesignBillCard extends StatelessWidget {
  final Map<String, dynamic> bill;
  const _DesignBillCard({required this.bill});

  @override
  Widget build(BuildContext context) {
    final status = (bill['status'] as String?) ?? 'pending';
    final points = (bill['pointsEarned'] as num?)?.toDouble() ?? 0;
    final createdAt = bill['createdAt'] as Timestamp?;
    final siteName = (bill['siteName'] as String?) ?? '';
    final company = (bill['storeName'] as String?) ?? '';
    final attachment =
        (bill['imageUrl'] as String?) ?? (bill['billImage'] as String?);
    final billNumber =
        (bill['billNumber'] as String?) ??
        (bill['invoiceId'] as String?) ??
        'BLP-0000-0000';

    final date = createdAt?.toDate() ?? DateTime.now();
    final dateStr = '${date.day} ${_monthName(date.month)} ${date.year}';
    final timeStr =
        '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')} ${date.hour >= 12 ? 'PM' : 'AM'}';

    final statusColor = _getStatusColor(status);
    final statusLabel = _getStatusLabel(status);

    return Container(
      decoration: BoxDecoration(
        color: context.themeSurface,
        borderRadius: AppRadius.all16,
        border: Border.all(
          color: context.themeTextPrimary.withValues(alpha: 0.06),
        ),
        boxShadow: [
          BoxShadow(
            color: context.themeTextPrimary.withValues(alpha: 0.02),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Bill thumbnail
          GestureDetector(
            onTap: attachment != null && attachment.isNotEmpty
                ? () => _viewAttachmentModal(context, attachment)
                : null,
            child: Stack(
              children: [
                Container(
                  width: 70,
                  height: 70,
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.12),
                    borderRadius: AppRadius.md12,
                  ),
                  child: attachment != null && attachment.isNotEmpty
                      ? ClipRRect(
                          borderRadius: AppRadius.md12,
                          child: Image.network(
                            attachment,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) =>
                                _billPlaceholder(statusColor),
                          ),
                        )
                      : _billPlaceholder(statusColor),
                ),
                // Attachment badge
                if (attachment != null && attachment.isNotEmpty)
                  Positioned(
                    bottom: 4,
                    right: 4,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: context.themePrimary,
                        borderRadius: AppRadius.sm8,
                      ),
                      child: const Icon(
                        Icons.image,
                        size: 12,
                        color: AppColors.white,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          // Bill details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Site name
                Text(
                  siteName,
                  style: AppTypography.bodySmall(
                    color: context.themeTextPrimary,
                  ).copyWith(fontWeight: FontWeight.w800, fontSize: 13),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                // Company and details
                Row(
                  children: [
                    Icon(
                      Icons.business,
                      size: 12,
                      color: context.themeTextPrimary.withValues(alpha: 0.6),
                    ),
                    const SizedBox(width: 3),
                    Expanded(
                      child: Text(
                        company,
                        style: AppTypography.labelSmall(
                          color: context.themeTextPrimary.withValues(
                            alpha: 0.7,
                          ),
                        ).copyWith(fontSize: 10),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                // Date and time
                Row(
                  children: [
                    Icon(
                      Icons.access_time,
                      size: 12,
                      color: context.themeTextPrimary.withValues(alpha: 0.6),
                    ),
                    const SizedBox(width: 3),
                    Expanded(
                      child: Text(
                        '$dateStr • $timeStr',
                        style: AppTypography.labelSmall(
                          color: context.themeTextPrimary.withValues(
                            alpha: 0.6,
                          ),
                        ).copyWith(fontSize: 10),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                // Bill Number
                Text(
                  billNumber,
                  style: AppTypography.labelSmall(
                    color: context.themeTextPrimary.withValues(alpha: 0.5),
                  ).copyWith(fontSize: 9, fontWeight: FontWeight.w600),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          // Status and points column
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Status badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.12),
                  borderRadius: AppRadius.sm8,
                ),
                child: Text(
                  statusLabel,
                  style: AppTypography.labelSmall(
                    color: statusColor,
                  ).copyWith(fontWeight: FontWeight.w700, fontSize: 10),
                ),
              ),
              const SizedBox(height: 8),
              // Points
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '+${points.toStringAsFixed(2)}',
                    style: AppTypography.bodySmall(
                      color: context.themePrimary,
                    ).copyWith(fontWeight: FontWeight.w900, fontSize: 14),
                  ),
                  Text(
                    'Points',
                    style: AppTypography.labelSmall(
                      color: context.themeTextPrimary.withValues(alpha: 0.6),
                    ).copyWith(fontSize: 9),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              // Arrow icon
              Icon(
                Icons.chevron_right,
                color: context.themeTextPrimary.withValues(alpha: 0.3),
                size: 16,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _billPlaceholder(Color color) {
    return Container(
      color: color.withValues(alpha: 0.12),
      child: Icon(Icons.receipt_long, color: color, size: 32),
    );
  }

  String _monthName(int month) {
    const months = [
      '',
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return months[month];
  }

  void _viewAttachmentModal(BuildContext context, String url) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => Dialog(
        backgroundColor: context.themeSurface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Bill Attachment',
                    style: AppTypography.h5(
                      color: context.themeTextPrimary,
                    ).copyWith(fontWeight: FontWeight.w700),
                  ),
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: context.themeTextPrimary.withValues(alpha: 0.1),
                        borderRadius: AppRadius.sm8,
                      ),
                      child: Icon(
                        Icons.close,
                        size: 20,
                        color: context.themeTextPrimary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Image.network(
                  url,
                  fit: BoxFit.contain,
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return Center(
                      child: CircularProgressIndicator(
                        value: loadingProgress.expectedTotalBytes != null
                            ? loadingProgress.cumulativeBytesLoaded /
                                  loadingProgress.expectedTotalBytes!
                            : null,
                        color: context.themePrimary,
                      ),
                    );
                  },
                  errorBuilder: (context, error, stackTrace) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.error_outline,
                            size: 48,
                            color: context.themeError,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'Failed to load image',
                            style: AppTypography.bodySmall(
                              color: context.themeError,
                            ).copyWith(fontWeight: FontWeight.w600),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            error.toString(),
                            style: AppTypography.labelSmall(
                              color: context.themeError.withValues(alpha: 0.7),
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: context.themePrimary,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: AppRadius.md12),
                  ),
                  child: Text(
                    'Close',
                    style: AppTypography.bodySmall(
                      color: AppColors.white,
                    ).copyWith(fontWeight: FontWeight.w700),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'approved':
        return AppColors.success;
      case 'pending':
        return AppColors.warning;
      case 'rejected':
        return AppColors.error;
      default:
        return AppColors.textSecondary;
    }
  }

  String _getStatusLabel(String status) {
    switch (status.toLowerCase()) {
      case 'approved':
        return 'Approved';
      case 'pending':
        return 'Pending';
      case 'rejected':
        return 'Rejected';
      default:
        return status.toUpperCase();
    }
  }
}

// Deprecated: Use _PointsHistoryTable instead
// ignore: unused_element
class _BillsList extends StatelessWidget {
  final List<String> ids;
  const _BillsList({required this.ids});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('bills')
          .where('carpenterId', whereIn: ids)
          .orderBy('createdAt', descending: true)
          .limit(10)
          .snapshots(),
      builder: (context, snap) {
        if (snap.hasError) {
          return _errorCard(context, snap.error.toString());
        }
        if (snap.connectionState == ConnectionState.waiting) {
          return const _BillsLoading();
        }
        if (!snap.hasData || snap.data!.docs.isEmpty) {
          return _emptyCard(context);
        }

        final bills = snap.data!.docs;
        return ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: bills.length,
          separatorBuilder: (_, __) => const SizedBox(height: 6),
          itemBuilder: (context, index) {
            final bill = bills[index].data() as Map<String, dynamic>;
            return _BillCard(
              bill: bill,
            ).fadeIn(delay: AppAnimations.stagger(index));
          },
        );
      },
    );
  }

  Widget _errorCard(BuildContext context, String error) {
    return AppCard(
      padding: const EdgeInsets.all(22),
      child: Column(
        children: [
          Icon(Icons.error_outline, size: 48, color: context.themeError),
          const SizedBox(height: 12),
          Text(
            'Error loading bills',
            style: AppTypography.bodyLarge(
              color: context.themeError,
            ).copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          Text(
            error,
            style: AppTypography.labelSmall(
              color: context.themeTextPrimary.withValues(alpha: 0.5),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _emptyCard(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return AppCard(
      padding: const EdgeInsets.all(22),
      child: Column(
        children: [
          Icon(
            Icons.receipt_long_outlined,
            size: 48,
            color: context.themeTextPrimary.withValues(alpha: 0.3),
          ),
          const SizedBox(height: 12),
          Text(
            l10n.noBillsYet,
            style: AppTypography.bodyLarge(
              color: context.themeTextPrimary.withValues(alpha: 0.6),
            ).copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          Text(
            l10n.submitFirstBill,
            style: AppTypography.bodySmall(
              color: context.themeTextPrimary.withValues(alpha: 0.5),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

// Deprecated: Use _PointsHistoryTable instead
// ignore: unused_element
class _BillCard extends StatelessWidget {
  final Map<String, dynamic> bill;
  const _BillCard({required this.bill});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final cardBg = isDark ? theme.colorScheme.surface : AppColors.white;

    final status = (bill['status'] ?? 'pending') as String;
    final pointsEarned = bill['pointsEarned'] ?? 0;
    final createdAt = bill['createdAt'] as Timestamp?;
    final storeName = (bill['storeName'] ?? '') as String;

    final statusColor = _statusColor(status);
    final l10n = AppLocalizations.of(context)!;

    return AppCard(
      padding: const EdgeInsets.all(14),
      borderRadius: 18,
      color: cardBg,
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.1),
              borderRadius: AppRadius.md12,
            ),
            child: Icon(_statusIcon(status), color: statusColor, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  storeName.isNotEmpty ? storeName : l10n.billLabel,
                  style: AppTypography.bodyMedium(
                    color: context.themeTextPrimary,
                  ).copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 4),
                if (status == 'approved' && (pointsEarned as num) > 0) ...[
                  Text(
                    '${(pointsEarned).toString().contains('.') ? pointsEarned : '$pointsEarned.00'} pts',
                    style: AppTypography.bodySmall(
                      color: context.themePrimary,
                    ).copyWith(fontWeight: FontWeight.w600),
                  ),
                ] else ...[
                  Text(
                    'Pending approval',
                    style: AppTypography.bodySmall(
                      color: context.themeTextPrimary.withValues(alpha: 0.6),
                    ).copyWith(fontWeight: FontWeight.w500),
                  ),
                ],
                if (createdAt != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    _formatDate(createdAt.toDate(), l10n),
                    style: AppTypography.labelSmall(
                      color: context.themeTextPrimary.withValues(alpha: 0.5),
                    ),
                  ),
                ],
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.1),
              borderRadius: AppRadius.md12,
              border: Border.all(color: statusColor.withValues(alpha: 0.3)),
            ),
            child: Text(
              _statusLabel(status, l10n),
              style: AppTypography.labelSmall(
                color: statusColor,
              ).copyWith(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  static Color _statusColor(String status) {
    switch (status.toLowerCase()) {
      case 'approved':
        return AppColors.success;
      case 'pending':
        return AppColors.warning;
      case 'rejected':
        return AppColors.error;
      default:
        return AppColors.textSecondary;
    }
  }

  static IconData _statusIcon(String status) {
    switch (status.toLowerCase()) {
      case 'approved':
        return Icons.check_circle;
      case 'pending':
        return Icons.pending;
      case 'rejected':
        return Icons.cancel;
      default:
        return Icons.receipt;
    }
  }

  static String _statusLabel(String status, AppLocalizations l10n) {
    switch (status.toLowerCase()) {
      case 'approved':
        return l10n.statusApproved;
      case 'pending':
        return l10n.statusPending;
      case 'rejected':
        return l10n.statusRejected;
      default:
        return status.toUpperCase();
    }
  }

  static String _formatDate(DateTime date, AppLocalizations l10n) {
    final diff = DateTime.now().difference(date);
    if (diff.inDays == 0) {
      if (diff.inHours == 0) {
        if (diff.inMinutes == 0) return l10n.justNow;
        return l10n.minutesAgo(diff.inMinutes);
      }
      return l10n.hoursAgo(diff.inHours);
    } else if (diff.inDays == 1) {
      return l10n.yesterday;
    } else if (diff.inDays < 7) {
      return l10n.daysAgo(diff.inDays);
    }
    return '${date.day}/${date.month}/${date.year}';
  }
}
