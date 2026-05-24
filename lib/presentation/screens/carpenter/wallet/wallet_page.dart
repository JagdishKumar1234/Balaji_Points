import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import 'package:balaji_points/core/design/app_animations.dart';
import 'package:balaji_points/core/design/app_colors.dart';
import 'package:balaji_points/core/design/app_radius.dart';
import 'package:balaji_points/core/design/app_typography.dart';
import 'package:balaji_points/core/layout/carpenter_shell_layout.dart';
import 'package:balaji_points/l10n/app_localizations.dart';
import 'package:balaji_points/providers/wallet_provider.dart';
import 'package:balaji_points/presentation/widgets/carpenter/home_nav_bar.dart';

class WalletPage extends ConsumerWidget {
  const WalletPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final walletState = ref.watch(walletProvider);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final mq = MediaQuery.of(context);
    final bottomPadding = CarpenterShellLayout.bottomPaddingForScrollView(mq);
    final l10n = AppLocalizations.of(context)!;
    final canvas = isDark ? theme.colorScheme.surface : AppColors.carpenterAppBackground;

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
              onRefresh: () => ref.read(walletProvider.notifier).refresh(),
              color: AppColors.lightPrimary,
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
                    walletState.loading
                        ? _ShimmerPointsCard()
                        : _PointsCard(
                            points: walletState.totalPoints,
                            tier: walletState.tier,
                          ).enterCard(delay: AppAnimations.stagger(1)),
                    const SizedBox(height: 14),

                    // Stats row
                    Row(
                      children: [
                        Expanded(
                          child: _StatCard(
                            icon: Icons.pending_actions,
                            label: l10n.pending,
                            color: AppColors.orange,
                            child: walletState.loading || !idsReady
                                ? _statLoading()
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
                                ? _statLoading()
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

                    // Recent bills header
                    _SectionHeader(
                      icon: Icons.receipt_long,
                      title: l10n.recentBills,
                      subtitle: 'Latest 10 updates',
                    ).fadeIn(delay: AppAnimations.stagger(3)),
                    const SizedBox(height: 8),

                    // Bills list
                    if (!idsReady)
                      const _BillsLoading()
                    else
                      _BillsList(ids: ids),

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

  Widget _statLoading() {
    return Text(
      '...',
      style: AppTypography.h4(color: AppColors.lightTextPrimary),
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
        color: AppColors.grey100,
        borderRadius: BorderRadius.circular(22),
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
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: isDark ? theme.colorScheme.surface.withValues(alpha: 0.8) : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: AppColors.lightPrimary.withValues(alpha: isDark ? 0.3 : 0.12),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: AppColors.lightPrimary.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.account_balance_wallet_outlined,
              size: 18,
              color: AppColors.lightPrimary,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Track your points and bill rewards in one place',
              style: AppTypography.bodySmall(
                color: AppColors.lightTextPrimary.withValues(alpha: 0.75),
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
  final int points;
  final String tier;
  const _PointsCard({required this.points, required this.tier});

  @override
  Widget build(BuildContext context) {
    final nf = NumberFormat.decimalPattern();
    final l10n = AppLocalizations.of(context)!;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.lightPrimary,
            AppColors.lightPrimary.withValues(alpha: 0.85),
            AppColors.lightPrimary.withValues(alpha: 0.70),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: AppColors.lightPrimary.withValues(alpha: 0.35),
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
                  color: Colors.white.withValues(alpha: 0.9),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                nf.format(points),
                style: AppTypography.pointsHero(color: Colors.white),
              ),
            ],
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              tier,
              style: AppTypography.bodySmall(color: Colors.white)
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
    final bg = isDark ? theme.colorScheme.surface : Colors.white;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: AppColors.lightPrimary.withValues(alpha: isDark ? 0.14 : 0.08),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 14,
            spreadRadius: 1,
            offset: const Offset(0, 6),
          ),
        ],
      ),
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
              borderRadius: BorderRadius.circular(11),
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(height: 14),
          child,
          const SizedBox(height: 6),
          Text(
            label,
            style: AppTypography.labelSmall(
              color: AppColors.lightTextPrimary.withValues(alpha: 0.7),
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
          style: AppTypography.h4(color: AppColors.lightTextPrimary),
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
          style: AppTypography.h4(color: AppColors.lightTextPrimary),
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
        gradient: const LinearGradient(
          colors: [AppColors.lightSecondary, Color(0xFF7C3AED), Color(0xFF2563EB)],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: AppColors.lightSecondary.withValues(alpha: 0.28),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => context.push('/add-bill'),
          borderRadius: BorderRadius.circular(18),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(7),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.add_circle_outline, color: Colors.white, size: 24),
                ),
                const SizedBox(width: 10),
                Text(
                  l10n.addNewBill,
                  style: AppTypography.bodyLarge(color: Colors.white)
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
            color: AppColors.lightPrimary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: AppColors.lightPrimary, size: 18),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: AppTypography.h5(color: AppColors.lightTextPrimary),
              ),
              Text(
                subtitle,
                style: AppTypography.labelSmall(
                  color: AppColors.lightTextPrimary.withValues(alpha: 0.6),
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
      child: Center(child: CircularProgressIndicator()),
    );
  }
}

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
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: AppRadius.forCard,
      ),
      child: Column(
        children: [
          const Icon(Icons.error_outline, size: 48, color: AppColors.error),
          const SizedBox(height: 12),
          Text(
            'Error loading bills',
            style: AppTypography.bodyLarge(color: AppColors.error)
                .copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          Text(
            error,
            style: AppTypography.labelSmall(
                color: AppColors.lightTextPrimary.withValues(alpha: 0.5)),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _emptyCard(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: AppRadius.forCard,
      ),
      child: Column(
        children: [
          Icon(
            Icons.receipt_long_outlined,
            size: 48,
            color: AppColors.lightTextPrimary.withValues(alpha: 0.3),
          ),
          const SizedBox(height: 12),
          Text(
            l10n.noBillsYet,
            style: AppTypography.bodyLarge(
                color: AppColors.lightTextPrimary.withValues(alpha: 0.6))
                .copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          Text(
            l10n.submitFirstBill,
            style: AppTypography.bodySmall(
                color: AppColors.lightTextPrimary.withValues(alpha: 0.5)),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _BillCard extends StatelessWidget {
  final Map<String, dynamic> bill;
  const _BillCard({required this.bill});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final cardBg = isDark ? theme.colorScheme.surface : Colors.white;

    final amount = bill['amount'] ?? 0.0;
    final status = (bill['status'] ?? 'pending') as String;
    final pointsEarned = bill['pointsEarned'] ?? 0;
    final createdAt = bill['createdAt'] as Timestamp?;
    final storeName = (bill['storeName'] ?? '') as String;

    final statusColor = _statusColor(status);
    final l10n = AppLocalizations.of(context)!;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: AppColors.lightPrimary.withValues(alpha: isDark ? 0.14 : 0.09),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 14,
            spreadRadius: 0.5,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
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
                  style: AppTypography.bodyMedium(color: AppColors.lightTextPrimary)
                      .copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Text(
                      '₹${(amount as num).toStringAsFixed(0)}',
                      style: AppTypography.bodySmall(color: AppColors.lightPrimary)
                          .copyWith(fontWeight: FontWeight.w600),
                    ),
                    if ((pointsEarned as num) > 0) ...[
                      const SizedBox(width: 6),
                      Text(
                        '• $pointsEarned pts',
                        style: AppTypography.labelSmall(
                          color: AppColors.lightTextPrimary.withValues(alpha: 0.6),
                        ),
                      ),
                    ],
                  ],
                ),
                if (createdAt != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    _formatDate(createdAt.toDate(), l10n),
                    style: AppTypography.labelSmall(
                      color: AppColors.lightTextPrimary.withValues(alpha: 0.5),
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
              borderRadius: BorderRadius.circular(12),
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
      case 'pending':  return AppColors.orange;
      case 'rejected': return AppColors.error;
      default:         return AppColors.grey500;
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
