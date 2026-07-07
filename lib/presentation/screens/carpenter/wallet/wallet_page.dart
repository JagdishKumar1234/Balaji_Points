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

/// Collapse duplicate bill-approval rows (legacy cloud-function double credit).
List<Map<String, dynamic>> _dedupePointsHistory(
  List<Map<String, dynamic>> entries,
) =>
    PointsUtils.dedupeHistory(entries);

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
                padding: EdgeInsets.fromLTRB(16, 14, 16, bottomPadding),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Intro banner
                    _WalletIntroBanner(isDark: isDark, theme: theme)
                        .fadeIn(),
                    const SizedBox(height: 14),

                    // Total points card
                    walletState.loading || pointsLoading
                        ? _ShimmerPointsCard()
                        : _PointsCard(
                            points: carpenterPoints.totalPoints,
                            tier: carpenterPoints.tier,
                          ).enterCard(delay: AppAnimations.stagger(1)),
                    const SizedBox(height: 14),

                    // Stats row
                    Row(
                      children: [
                        Expanded(
                          child: _StatCard(
                            icon: Icons.pending_actions,
                            label: l10n.pending,
                            color: AppColors.warning,
                            child: walletState.loading || !idsReady
                                ? _statLoading(context)
                                : _PendingCount(ids: ids),
                          ).fadeIn(delay: AppAnimations.stagger(2)),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _StatCard(
                            icon: Icons.check_circle,
                            label: l10n.approved,
                            color: AppColors.success,
                            child: walletState.loading || !idsReady
                                ? _statLoading(context)
                                : _ApprovedCount(ids: ids),
                          ).fadeIn(delay: AppAnimations.stagger(2)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),

                    // Add bill CTA
                    _AddBillButton(l10n: l10n)
                        .enterCard(delay: AppAnimations.stagger(3)),
                    const SizedBox(height: 16),

                    // Points history header
                    _SectionHeader(
                      icon: Icons.history,
                      title: 'Points History',
                      subtitle: 'All transactions',
                    ).fadeIn(delay: AppAnimations.stagger(3)),
                    const SizedBox(height: 8),

                    // Points history table
                    if (!idsReady)
                      const _BillsLoading()
                    else
                      _PointsHistoryTable(ids: ids),

                    const SizedBox(height: 14),
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
      height: 100,
      decoration: BoxDecoration(
        color: context.themeSoftSurface,
        borderRadius: AppRadius.all16,
      ),
    ).animate(onPlay: (c) => c.repeat()).shimmer(duration: 1200.ms);
  }
}

// ---------------------------------------------------------------------------
// Wallet intro banner
// ---------------------------------------------------------------------------

class _WalletIntroBanner extends StatelessWidget {
  final bool isDark;
  final ThemeData theme;
  const _WalletIntroBanner({required this.isDark, required this.theme});

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      borderRadius: 14,
      color: isDark ? theme.colorScheme.surface.withValues(alpha: 0.8) : AppColors.white,
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: context.themePrimary.withValues(alpha: 0.12),
              borderRadius: AppRadius.sm8,
            ),
            child: Icon(
              Icons.account_balance_wallet_outlined,
              size: 18,
              color: context.themePrimary,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Track your points and bill rewards in one place',
              style: AppTypography.bodySmall(
                color: context.themeTextPrimary.withValues(alpha: 0.75),
              ).copyWith(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Points card
// ---------------------------------------------------------------------------

class _PointsCard extends StatelessWidget {
  final double points;
  final String tier;
  const _PointsCard({required this.points, required this.tier});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final pointsDisplay = PointsUtils.formatPoints(points);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            context.themePrimary,
            context.themePrimary.withValues(alpha: 0.85),
            context.themePrimary.withValues(alpha: 0.70),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: AppRadius.all16,
        boxShadow: [
          BoxShadow(
            color: context.themePrimary.withValues(alpha: 0.35),
            blurRadius: 20,
            spreadRadius: 2,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.totalPoints,
                style: AppTypography.bodySmall(
                  color: AppColors.white.withValues(alpha: 0.9),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                pointsDisplay,
                style: AppTypography.pointsHero(color: AppColors.white),
              ),
            ],
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
            decoration: BoxDecoration(
              color: AppColors.white.withValues(alpha: 0.2),
              borderRadius: AppRadius.all16,
            ),
            child: Text(
              tier,
              style: AppTypography.bodySmall(color: AppColors.white)
                  .copyWith(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Stat card
// ---------------------------------------------------------------------------

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final Widget child;

  const _StatCard({
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

    return AppCard(
      padding: const EdgeInsets.all(14),
      borderRadius: 18,
      color: bg,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(9),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [color.withValues(alpha: 0.2), color.withValues(alpha: 0.1)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: AppRadius.md12,
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(height: 14),
          child,
          const SizedBox(height: 6),
          Text(
            label,
            style: AppTypography.labelSmall(
              color: context.themeTextPrimary.withValues(alpha: 0.7),
            ),
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
          style: AppTypography.h4(color: context.themeTextPrimary),
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
          style: AppTypography.h4(color: context.themeTextPrimary),
        );
      },
    );
  }
}

// ---------------------------------------------------------------------------
// Add bill button
// ---------------------------------------------------------------------------

class _AddBillButton extends StatelessWidget {
  final AppLocalizations l10n;
  const _AddBillButton({required this.l10n});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [context.themeSecondary, Color(0xFF7C3AED), Color(0xFF2563EB)],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        borderRadius: AppRadius.all16,
        boxShadow: [
          BoxShadow(
            color: context.themeSecondary.withValues(alpha: 0.28),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Material(
        color: AppColors.transparent,
        child: InkWell(
          onTap: () => context.push('/add-bill'),
          borderRadius: AppRadius.all16,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(7),
                  decoration: BoxDecoration(
                    color: AppColors.white.withValues(alpha: 0.2),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.add_circle_outline, color: AppColors.white, size: 24),
                ),
                const SizedBox(width: 10),
                Text(
                  l10n.addNewBill,
                  style: AppTypography.bodyLarge(color: AppColors.white)
                      .copyWith(fontWeight: FontWeight.w700, letterSpacing: 0.2),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Section header
// ---------------------------------------------------------------------------

class _SectionHeader extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  const _SectionHeader({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: context.themePrimary.withValues(alpha: 0.1),
            borderRadius: AppRadius.sm8,
          ),
          child: Icon(icon, color: context.themePrimary, size: 18),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: AppTypography.h5(color: context.themeTextPrimary),
              ),
              Text(
                subtitle,
                style: AppTypography.labelSmall(
                  color: context.themeTextPrimary.withValues(alpha: 0.6),
                ),
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
// Points History Table - Shows all transactions in tabular form
// ---------------------------------------------------------------------------

class _PointsHistoryTable extends ConsumerStatefulWidget {
  final List<String> ids;
  const _PointsHistoryTable({required this.ids});

  @override
  ConsumerState<_PointsHistoryTable> createState() => _PointsHistoryTableState();
}

class _PointsHistoryTableState extends ConsumerState<_PointsHistoryTable> {
  @override
  Widget build(BuildContext context) {

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('user_points')
          .where('userId', whereIn: widget.ids)
          .snapshots(),
      builder: (context, snap) {
        if (snap.hasError) {
          return _errorCard(context, snap.error.toString());
        }
        if (snap.connectionState == ConnectionState.waiting) {
          return const _BillsLoading();
        }

        // Collect all history entries from all user_points docs
        final rawHistory = <Map<String, dynamic>>[];

        if (snap.hasData) {
          for (final doc in snap.data!.docs) {
            final data = doc.data() as Map<String, dynamic>;
            final history = (data['pointsHistory'] as List<dynamic>?) ?? [];
            for (final entry in history) {
              rawHistory.add(Map<String, dynamic>.from(entry as Map));
            }
          }
        }

        final allHistory = _dedupePointsHistory(rawHistory);
        double grandTotal = 0;
        for (final entry in allHistory) {
          grandTotal += (entry['points'] as num?)?.toDouble() ?? 0;
        }

        if (allHistory.isEmpty) {
          return _emptyCard(context);
        }

        // Sort by date descending
        allHistory.sort((a, b) {
          final aDate = (a['date'] as Timestamp?)?.toDate() ?? DateTime.now();
          final bDate = (b['date'] as Timestamp?)?.toDate() ?? DateTime.now();
          return bDate.compareTo(aDate);
        });

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Points history list (card-based, no scroll)
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: allHistory.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final entry = allHistory[index];
                final date =
                    (entry['date'] as Timestamp?)?.toDate() ??
                    DateTime.now();
                final reason = (entry['reason'] as String?) ?? 'Transaction';
                final points = (entry['points'] as num?)?.toDouble() ?? 0;

                final timeStr =
                    '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
                final dateStr =
                    '${date.day}/${date.month}/${date.year}';

                return Container(
                  decoration: BoxDecoration(
                    color: context.themeSurface,
                    borderRadius: AppRadius.md12,
                    border: Border.all(
                      color: context.themeTextPrimary.withValues(alpha: 0.08),
                    ),
                  ),
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    children: [
                      // Date & Time (left)
                      Expanded(
                        flex: 2,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              dateStr,
                              style: AppTypography.labelSmall(
                                color: context.themeTextPrimary
                                    .withValues(alpha: 0.6),
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              timeStr,
                              style: AppTypography.bodySmall(
                                color: context.themeTextPrimary,
                              ).copyWith(fontWeight: FontWeight.w600),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      // Reason (middle - flexible)
                      Expanded(
                        flex: 3,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Reason',
                              style: AppTypography.labelSmall(
                                color: context.themeTextPrimary
                                    .withValues(alpha: 0.6),
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              reason,
                              style: AppTypography.bodySmall(
                                color: context.themeTextPrimary,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      // Points (right)
                      Container(
                        decoration: BoxDecoration(
                          color: context.themePrimary.withValues(alpha: 0.08),
                          borderRadius: AppRadius.sm8,
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              'Points',
                              style: AppTypography.labelSmall(
                                color: context.themeTextPrimary
                                    .withValues(alpha: 0.6),
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              points.toStringAsFixed(2),
                              style: AppTypography.h5(
                                color: context.themePrimary,
                              ).copyWith(fontWeight: FontWeight.w700),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
            const SizedBox(height: 16),
            // Grand total card
            Container(
              decoration: BoxDecoration(
                color: context.themePrimary.withValues(alpha: 0.08),
                borderRadius: AppRadius.md12,
                border: Border.all(
                  color: context.themePrimary.withValues(alpha: 0.15),
                  width: 2,
                ),
              ),
              padding: const EdgeInsets.all(14),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Total Points Earned',
                        style: AppTypography.labelSmall(
                          color: context.themeTextPrimary
                              .withValues(alpha: 0.7),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${allHistory.length} transactions',
                        style: AppTypography.bodySmall(
                          color: context.themeTextPrimary
                              .withValues(alpha: 0.5),
                        ),
                      ),
                    ],
                  ),
                  Container(
                    decoration: BoxDecoration(
                      color: context.themePrimary,
                      borderRadius: AppRadius.sm8,
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    child: Text(
                      grandTotal.toStringAsFixed(2),
                      style: AppTypography.h5(
                        color: AppColors.white,
                      ).copyWith(fontWeight: FontWeight.w700),
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
            'Error loading history',
            style: AppTypography.bodyLarge(color: context.themeError)
                .copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          Text(
            error,
            style: AppTypography.labelSmall(
                color: context.themeTextPrimary.withValues(alpha: 0.5)),
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
            Icons.history,
            size: 48,
            color: context.themeTextPrimary.withValues(alpha: 0.3),
          ),
          const SizedBox(height: 12),
          Text(
            'No transactions yet',
            style: AppTypography.bodyLarge(
                color: context.themeTextPrimary.withValues(alpha: 0.6))
                .copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          Text(
            'Your points history will appear here',
            style: AppTypography.bodySmall(
                color: context.themeTextPrimary.withValues(alpha: 0.5)),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
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
            return _BillCard(bill: bill)
                .fadeIn(delay: AppAnimations.stagger(index));
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
            style: AppTypography.bodyLarge(color: context.themeError)
                .copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          Text(
            error,
            style: AppTypography.labelSmall(
                color: context.themeTextPrimary.withValues(alpha: 0.5)),
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
                color: context.themeTextPrimary.withValues(alpha: 0.6))
                .copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          Text(
            l10n.submitFirstBill,
            style: AppTypography.bodySmall(
                color: context.themeTextPrimary.withValues(alpha: 0.5)),
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
                  style: AppTypography.bodyMedium(color: context.themeTextPrimary)
                      .copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 4),
                if (status == 'approved' && (pointsEarned as num) > 0) ...[
                  Text(
                    '${(pointsEarned).toString().contains('.') ? pointsEarned : '$pointsEarned.00'} pts',
                    style: AppTypography.bodySmall(color: context.themePrimary)
                        .copyWith(fontWeight: FontWeight.w600),
                  ),
                ] else ...[
                  Text(
                    'Pending approval',
                    style: AppTypography.bodySmall(color: context.themeTextPrimary.withValues(alpha: 0.6))
                        .copyWith(fontWeight: FontWeight.w500),
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
              style: AppTypography.labelSmall(color: statusColor)
                  .copyWith(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  static Color _statusColor(String status) {
    switch (status.toLowerCase()) {
      case 'approved': return AppColors.success;
      case 'pending':  return AppColors.warning;
      case 'rejected': return AppColors.error;
      default:         return AppColors.textSecondary;
    }
  }

  static IconData _statusIcon(String status) {
    switch (status.toLowerCase()) {
      case 'approved': return Icons.check_circle;
      case 'pending':  return Icons.pending;
      case 'rejected': return Icons.cancel;
      default:         return Icons.receipt;
    }
  }

  static String _statusLabel(String status, AppLocalizations l10n) {
    switch (status.toLowerCase()) {
      case 'approved': return l10n.statusApproved;
      case 'pending':  return l10n.statusPending;
      case 'rejected': return l10n.statusRejected;
      default:         return status.toUpperCase();
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
