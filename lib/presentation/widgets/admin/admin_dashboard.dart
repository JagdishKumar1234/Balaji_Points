import 'package:balaji_points/core/constants/app_constants.dart';
import 'package:balaji_points/services/notifications/notification_visibility.dart';
import 'package:balaji_points/core/design/app_radius.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:balaji_points/services/branch/current_branch_service.dart';
import 'package:balaji_points/core/utils/points_utils.dart';
import 'package:balaji_points/l10n/app_localizations.dart';
import 'package:balaji_points/presentation/widgets/shared/stat_card.dart';
import 'package:balaji_points/core/design/app_colors.dart';
import 'package:balaji_points/core/design/app_typography.dart';

/// Admin dashboard: 8 section cards with live Firestore counts.
class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key, required this.onOpenSection});
  final void Function(String section) onOpenSection;

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  static const List<_SectionCard> _sections = [
    _SectionCard(
      id: 'pending',
      label: 'Pending Bills',
      icon: Icons.receipt_long_rounded,
    ),
    _SectionCard(
      id: 'history',
      label: 'Bill History',
      icon: Icons.history_rounded,
    ),
    _SectionCard(
      id: 'offers',
      label: 'Offers',
      icon: Icons.local_offer_rounded,
    ),
    _SectionCard(
      id: 'greeting',
      label: 'Send Greeting',
      icon: Icons.message_rounded,
    ),
    _SectionCard(id: 'users', label: 'Users', icon: Icons.people_rounded),
    _SectionCard(
      id: 'notifications',
      label: 'Notifications',
      icon: Icons.notifications_rounded,
    ),
    _SectionCard(id: 'spin', label: 'Spin', icon: Icons.casino_rounded),
    _SectionCard(
      id: 'points-repair',
      label: 'Points Repair',
      icon: Icons.build_circle_rounded,
    ),
    _SectionCard(
      id: 'duplicates',
      label: 'Duplicates',
      icon: Icons.content_copy_rounded,
    ),
    _SectionCard(
      id: 'backup',
      label: 'Backup',
      icon: Icons.cloud_download_rounded,
    ),
    _SectionCard(
      id: 'check-duplicates',
      label: 'Check Firebase',
      icon: Icons.search_rounded,
    ),
    _SectionCard(
      id: 'smart-cleanup',
      label: 'Smart Cleanup',
      icon: Icons.auto_delete_rounded,
    ),
  ];

  int _refreshKey = 0;

  Future<void> _onRefresh() async {
    setState(() => _refreshKey++);
    await Future.delayed(const Duration(milliseconds: 400));
  }

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: context.themeBackground,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
        child: RefreshIndicator(
          onRefresh: _onRefresh,
          color: context.themeContentColor,
          child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
            key: ValueKey<int>(_refreshKey),
            stream: FirebaseFirestore.instance
                .collection('bills')
                .forAdminBranch()
                .where('status', isEqualTo: 'pending')
                .snapshots(),
            builder: (context, billsSnap) {
              final pendingBillsCount = billsSnap.data?.docs.length ?? 0;
              return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                key: ValueKey<int>(_refreshKey),
                stream: FirebaseFirestore.instance
                    .collection('users')
                    .forAdminBranch()
                    .snapshots(),
                builder: (context, usersSnap) {
                  final usersDocs = usersSnap.data?.docs ?? const [];
                  final carpentersCount = usersDocs.where((doc) {
                    final role = doc.data()['role'] as String?;
                    if (role == 'admin') return false;
                    return AppConstants.isMemberRole(role);
                  }).length;
                  final totalUsersCount = carpentersCount;

                  return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                    stream: FirebaseFirestore.instance
                        .collection('notification_logs')
                        .where(
                          'type',
                          whereIn: const [
                            'newPendingBill',
                            'newUserRegistered',
                          ],
                        )
                        .snapshots(),
                    builder: (context, notifSnap) {
                      final notificationCount = notifSnap.hasError
                          ? 0
                          : notifSnap.data?.docs.visibleToAdmin().length ?? 0;

                      final tiles = _sections.map((s) {
                        int? count;
                        int? secondaryCount;
                        if (s.id == 'pending') count = pendingBillsCount;
                        if (s.id == 'notifications') count = notificationCount;
                        if (s.id == 'users') {
                          count = totalUsersCount;
                          secondaryCount = carpentersCount;
                        }
                        return _SectionTile(
                          section: s,
                          count: count,
                          secondaryCount: secondaryCount,
                          onTap: () => widget.onOpenSection(s.id),
                        );
                      }).toList();

                      // Spec: stat row (auto-fit, min 200 px) above the
                      // quick-action grid. Both are width-driven, so a phone
                      // gets 2 stat columns and desktop gets 4.
                      return CustomScrollView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        slivers: [
                          SliverToBoxAdapter(
                            child: _StatsRow(
                              refreshKey: _refreshKey,
                              carpenters: carpentersCount,
                              pendingBills: pendingBillsCount,
                              onOpenSection: widget.onOpenSection,
                            ),
                          ),
                          const SliverToBoxAdapter(child: SizedBox(height: 16)),
                          SliverGrid(
                            gridDelegate:
                                const SliverGridDelegateWithMaxCrossAxisExtent(
                                  maxCrossAxisExtent: 200,
                                  mainAxisSpacing: 10,
                                  crossAxisSpacing: 10,
                                  mainAxisExtent: 112,
                                ),
                            delegate: SliverChildListDelegate(tiles),
                          ),
                        ],
                      );
                    },
                  );
                },
              );
            },
          ),
        ),
      ),
    );
  }
}

/// Four spec stat cards: carpenters, pending bills, bills this month and
/// points issued this month. Month figures come from one range query on
/// `createdAt` (single-field index, no composite index needed).
class _StatsRow extends StatelessWidget {
  const _StatsRow({
    required this.refreshKey,
    required this.carpenters,
    required this.pendingBills,
    required this.onOpenSection,
  });

  final int refreshKey;
  final int carpenters;
  final int pendingBills;
  final void Function(String section) onOpenSection;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final now = DateTime.now();
    final monthStart = DateTime(now.year, now.month);

    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      key: ValueKey<int>(refreshKey),
      stream: FirebaseFirestore.instance
          .collection('bills')
          .forAdminBranch()
          .where(
            'createdAt',
            isGreaterThanOrEqualTo: Timestamp.fromDate(monthStart),
          )
          // Matches the existing (branchId, createdAt DESC) index.
          .orderBy('createdAt', descending: true)
          .snapshots(),
      builder: (context, snap) {
        final docs = snap.data?.docs ?? const [];
        var approved = 0;
        num points = 0;
        for (final d in docs) {
          final data = d.data();
          if (data['status'] == 'approved') {
            approved++;
            points += (data['pointsEarned'] as num?) ?? 0;
          }
        }
        final loading = !snap.hasData && !snap.hasError;
        final monthBills = loading ? '—' : '${docs.length}';
        final monthPoints = loading
            ? '—'
            : PointsUtils.formatPoints(points.toDouble());

        final cards = [
          StatCard(
            label: l10n.statCarpenters,
            value: '$carpenters',
            caption: l10n.statRegistered,
            icon: Icons.groups_rounded,
            onTap: () => onOpenSection('users'),
          ),
          StatCard(
            label: l10n.statPendingBills,
            value: '$pendingBills',
            caption: l10n.statAwaitingReview,
            icon: Icons.pending_actions_rounded,
            onTap: () => onOpenSection('pending'),
          ),
          StatCard(
            label: l10n.statBillsThisMonth,
            value: monthBills,
            caption: l10n.statApprovedThisMonth('$approved'),
            icon: Icons.receipt_long_rounded,
            onTap: () => onOpenSection('history'),
          ),
          StatCard(
            label: l10n.statPointsIssued,
            value: monthPoints,
            caption: l10n.statThisMonth,
            icon: Icons.stars_rounded,
          ),
        ];

        return LayoutBuilder(
          builder: (context, constraints) {
            // auto-fit minmax(200px, 1fr) — 2 columns on phones, up to 4.
            final cols = (constraints.maxWidth / 200).floor().clamp(2, 4);
            const gap = 10.0;
            final w = (constraints.maxWidth - gap * (cols - 1)) / cols;
            return Wrap(
              spacing: gap,
              runSpacing: gap,
              children: [for (final c in cards) SizedBox(width: w, child: c)],
            );
          },
        );
      },
    );
  }
}

class _SectionCard {
  const _SectionCard({
    required this.id,
    required this.label,
    required this.icon,
  });
  final String id;
  final String label;
  final IconData icon;
}

/// Spec quick-action tile: neutral card, navy icon square with gold glyph,
/// 13/600 label, navy count badge. Same look for every section — colour is
/// reserved for meaning, not decoration.
class _SectionTile extends StatelessWidget {
  const _SectionTile({
    required this.section,
    required this.onTap,
    this.count,
    this.secondaryCount,
  });
  final _SectionCard section;
  final VoidCallback onTap;
  final int? count;
  final int? secondaryCount;

  @override
  Widget build(BuildContext context) {
    final badge = section.id == 'users' ? secondaryCount : count;
    final l10n = AppLocalizations.of(context)!;
    final label = switch (section.id) {
      'pending' => l10n.pendingBills,
      'history' => l10n.billHistory,
      'offers' => l10n.offers,
      'greeting' => l10n.sendGreeting,
      'users' => l10n.users,
      'notifications' => l10n.notifications,
      'spin' => l10n.spin,
      'points-repair' => l10n.pointsRepair,
      'duplicates' => l10n.duplicateAccounts,
      'backup' => l10n.backupDatabase,
      'check-duplicates' => l10n.checkFirebaseDuplicates,
      'smart-cleanup' => l10n.smartCleanup,
      _ => section.label,
    };
    final showBadge = badge != null && (section.id == 'users' || badge > 0);

    return Semantics(
      button: true,
      label: showBadge ? '$label, $badge' : label,
      excludeSemantics: true,
      child: Material(
        color: context.themeCard,
        shape: RoundedRectangleBorder(
          borderRadius: AppRadius.all16,
          side: BorderSide(color: context.themeBorder),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Stack(
            children: [
              Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: const BoxDecoration(
                          color: AppColors.primary,
                          borderRadius: BorderRadius.all(Radius.circular(10)),
                        ),
                        child: Icon(
                          section.icon,
                          size: 22,
                          color: AppColors.gold,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        label,
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.label(
                          color: context.themeContentColor,
                        ).copyWith(fontSize: 13),
                      ),
                    ],
                  ),
                ),
              ),
              if (showBadge)
                Positioned(
                  top: 8,
                  right: 8,
                  child: Container(
                    constraints: const BoxConstraints(minWidth: 22),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 7,
                      vertical: 2,
                    ),
                    decoration: const BoxDecoration(
                      color: AppColors.gold,
                      borderRadius: AppRadius.pill,
                    ),
                    child: Text(
                      '$badge',
                      textAlign: TextAlign.center,
                      style: AppTypography.labelSmall(color: AppColors.primary),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
