import 'package:balaji_points/core/points/leaderboard_group.dart';
import 'package:balaji_points/services/admin/admin_dashboard_prefs.dart';
import 'package:balaji_points/services/notifications/notification_visibility.dart';
import 'package:balaji_points/core/design/app_radius.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:balaji_points/core/firebase/app_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:balaji_points/services/platform/enquiry_service.dart';
import 'package:balaji_points/services/branch/current_branch_service.dart';
import 'package:balaji_points/core/utils/points_utils.dart';
import 'package:balaji_points/l10n/app_localizations.dart';
import 'package:balaji_points/core/design/app_colors.dart';
import 'package:balaji_points/core/design/app_typography.dart';

/// Admin dashboard: a summary card (pending bills, requests, members), this
/// month's figures, then the menu. The admin can switch the menu between
/// grid and list and change its order; both are remembered on this device.
class AdminDashboard extends ConsumerStatefulWidget {
  const AdminDashboard({super.key, required this.onOpenSection});
  final void Function(String section) onOpenSection;

  @override
  ConsumerState<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends ConsumerState<AdminDashboard> {
  static const List<_SectionCard> _sections = [
    _SectionCard(id: 'requests', icon: Icons.how_to_reg_rounded),
    _SectionCard(id: 'pending', icon: Icons.receipt_long_rounded),
    _SectionCard(id: 'history', icon: Icons.history_rounded),
    _SectionCard(id: 'offers', icon: Icons.local_offer_rounded),
    _SectionCard(id: 'broadcast', icon: Icons.campaign_rounded),
    _SectionCard(id: 'greeting', icon: Icons.celebration_rounded),
    _SectionCard(id: 'catalogs', icon: Icons.menu_book_rounded),
    _SectionCard(id: 'enquiries', icon: Icons.mark_email_unread_rounded),
    _SectionCard(id: 'users', icon: Icons.people_rounded),
    _SectionCard(id: 'notifications', icon: Icons.notifications_rounded),
    _SectionCard(id: 'spin', icon: Icons.casino_rounded),
    // Maintenance tools stay hidden from branch admins (2026-11-12); the
    // screens are still routed by id in admin_home_page.dart.
  ];

  static final List<String> _defaultOrder = [for (final s in _sections) s.id];

  int _refreshKey = 0;
  List<String> _order = _defaultOrder;
  bool _listView = false;

  @override
  void initState() {
    super.initState();
    _loadPrefs();
  }

  Future<void> _loadPrefs() async {
    final saved = await AdminDashboardPrefs.loadOrder();
    final list = await AdminDashboardPrefs.loadListView();
    if (!mounted) return;
    setState(() {
      _order = AdminDashboardPrefs.applyOrder(_defaultOrder, saved);
      _listView = list;
    });
  }

  Future<void> _onRefresh() async {
    setState(() => _refreshKey++);
    await Future.delayed(const Duration(milliseconds: 400));
  }

  void _toggleView() {
    setState(() => _listView = !_listView);
    AdminDashboardPrefs.saveListView(_listView);
  }

  Future<void> _editOrder() async {
    final result = await showModalBottomSheet<List<String>>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      backgroundColor: context.themeBackground,
      builder: (_) => _ReorderSheet(
        order: _order,
        defaults: _defaultOrder,
        iconOf: _iconOf,
      ),
    );
    if (result == null || !mounted) return;
    setState(() => _order = result);
    final isDefault = _listEquals(result, _defaultOrder);
    await AdminDashboardPrefs.saveOrder(isDefault ? null : result);
  }

  static bool _listEquals(List<String> a, List<String> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  static IconData _iconOf(String id) =>
      _sections.firstWhere((s) => s.id == id).icon;

  @override
  Widget build(BuildContext context) {
    // Starts (and keeps) the enquiry list, so the Enquiries screen opens
    // instantly; the tile shows how many are still open.
    // No count when the list could not be read (e.g. a PIN login), never a
    // stale cached one.
    final enquiriesAsync = ref.watch(enquiriesProvider(adminEnquiriesKey()));
    final openEnquiries = enquiriesAsync.hasError
        ? null
        : enquiriesAsync.asData?.value.where((e) => e.isOpen).length;
    return ColoredBox(
      color: context.themeBackground,
      child: RefreshIndicator(
        onRefresh: _onRefresh,
        color: context.themeContentColor,
        child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
          key: ValueKey<int>(_refreshKey),
          stream: appFirestore
              .collection('bills')
              .forAdminBranch()
              .where('status', isEqualTo: 'pending')
              .snapshots(),
          builder: (context, billsSnap) {
            final pendingBillsCount = billsSnap.data?.docs.length ?? 0;
            return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              key: ValueKey<int>(_refreshKey),
              stream: appFirestore
                  .collection('users')
                  .forAdminBranch()
                  .snapshots(),
              builder: (context, usersSnap) {
                final usersDocs = usersSnap.data?.docs ?? const [];
                // Approved members of all four roles.
                final membersCount = usersDocs
                    .where((doc) => MemberFilter.isActiveMember(doc.data()))
                    .length;
                // New member sign-ups still waiting for approval.
                final requestsCount = usersDocs.where((doc) {
                  final d = doc.data();
                  return LeaderboardGroups.of(d['role'] as String?) != null &&
                      d['status'] != 'deleted' &&
                      AccountApproval.statusOf(d) == AccountApproval.pending;
                }).length;

                return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                  stream: appFirestore
                      .collection('notification_logs')
                      .where(
                        'type',
                        whereIn: const ['newPendingBill', 'newUserRegistered'],
                      )
                      .snapshots(),
                  builder: (context, notifSnap) {
                    final notificationCount = notifSnap.hasError
                        ? 0
                        : notifSnap.data?.docs.visibleToAdmin().length ?? 0;

                    int? badgeOf(String id) => switch (id) {
                      'pending' => pendingBillsCount,
                      'notifications' => notificationCount,
                      'enquiries' => openEnquiries,
                      'requests' => requestsCount,
                      'users' => membersCount,
                      _ => null,
                    };

                    final items = [
                      for (final id in _order)
                        _MenuItem(
                          id: id,
                          icon: _iconOf(id),
                          badge: badgeOf(id),
                          onTap: () => widget.onOpenSection(id),
                        ),
                    ];

                    return CustomScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      slivers: [
                        SliverPadding(
                          padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                          sliver: SliverToBoxAdapter(
                            child: _HeroCard(
                              pendingBills: pendingBillsCount,
                              requests: requestsCount,
                              members: membersCount,
                              onOpenSection: widget.onOpenSection,
                            ),
                          ),
                        ),
                        SliverPadding(
                          padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                          sliver: SliverToBoxAdapter(
                            child: _MonthRow(
                              refreshKey: _refreshKey,
                              onOpenSection: widget.onOpenSection,
                            ),
                          ),
                        ),
                        SliverPadding(
                          padding: const EdgeInsets.fromLTRB(20, 18, 8, 6),
                          sliver: SliverToBoxAdapter(
                            child: _MenuHeader(
                              listView: _listView,
                              onToggleView: _toggleView,
                              onEditOrder: _editOrder,
                            ),
                          ),
                        ),
                        SliverPadding(
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                          sliver: _listView
                              ? SliverToBoxAdapter(
                                  child: _MenuList(items: items),
                                )
                              : SliverGrid(
                                  gridDelegate:
                                      const SliverGridDelegateWithMaxCrossAxisExtent(
                                        maxCrossAxisExtent: 180,
                                        mainAxisSpacing: 10,
                                        crossAxisSpacing: 10,
                                        mainAxisExtent: 118,
                                      ),
                                  delegate: SliverChildListDelegate([
                                    for (final item in items)
                                      _MenuGridTile(item: item),
                                  ]),
                                ),
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
    );
  }
}

// ── Summary card ────────────────────────────────────────────────────────────

/// Navy card: greeting and date, then the three numbers an admin acts on.
class _HeroCard extends StatelessWidget {
  const _HeroCard({
    required this.pendingBills,
    required this.requests,
    required this.members,
    required this.onOpenSection,
  });

  final int pendingBills;
  final int requests;
  final int members;
  final void Function(String section) onOpenSection;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final hour = DateTime.now().hour;
    final greeting = hour < 12
        ? l10n.goodMorningGreeting
        : hour < 17
        ? l10n.goodAfternoonGreeting
        : l10n.goodEveningGreeting;
    final date = DateFormat(
      'EEE, d MMM',
      Localizations.localeOf(context).toLanguageTag(),
    ).format(DateTime.now());

    return Container(
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 14),
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: const BorderRadius.all(Radius.circular(20)),
        border: context.isDarkMode
            ? Border.all(color: AppColors.gold.withValues(alpha: 0.35))
            : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      greeting.replaceAll(',', ''),
                      style: AppTypography.section(color: AppColors.white),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      l10n.adminTodayGlance,
                      style: AppTypography.caption(
                        color: AppColors.white.withValues(alpha: 0.72),
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: AppColors.gold.withValues(alpha: 0.16),
                  borderRadius: AppRadius.pill,
                  border: Border.all(
                    color: AppColors.gold.withValues(alpha: 0.5),
                  ),
                ),
                child: Text(
                  date,
                  style: AppTypography.labelSmall(color: AppColors.gold),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          IntrinsicHeight(
            child: Row(
              children: [
                _HeroStat(
                  value: pendingBills,
                  label: l10n.statPendingBills,
                  onTap: () => onOpenSection('pending'),
                ),
                const _HeroDivider(),
                _HeroStat(
                  value: requests,
                  label: l10n.adminStatRequests,
                  onTap: () => onOpenSection('requests'),
                ),
                const _HeroDivider(),
                _HeroStat(
                  value: members,
                  label: l10n.adminStatMembers,
                  onTap: () => onOpenSection('users'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _HeroStat extends StatelessWidget {
  const _HeroStat({
    required this.value,
    required this.label,
    required this.onTap,
  });
  final int value;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Semantics(
        button: true,
        label: '$label: $value',
        excludeSemantics: true,
        child: InkWell(
          onTap: onTap,
          borderRadius: AppRadius.md12,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Column(
              children: [
                Text(
                  '$value',
                  style: AppTypography.pointsLarge(color: AppColors.gold),
                ),
                const SizedBox(height: 2),
                Text(
                  label,
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.caption(
                    color: AppColors.white.withValues(alpha: 0.8),
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

class _HeroDivider extends StatelessWidget {
  const _HeroDivider();

  @override
  Widget build(BuildContext context) => Container(
    width: 1,
    margin: const EdgeInsets.symmetric(vertical: 8),
    color: AppColors.white.withValues(alpha: 0.15),
  );
}

// ── This month ──────────────────────────────────────────────────────────────

/// Bills this month and points issued this month, from one range query on
/// `createdAt` (matches the existing (branchId, createdAt DESC) index).
class _MonthRow extends StatelessWidget {
  const _MonthRow({required this.refreshKey, required this.onOpenSection});

  final int refreshKey;
  final void Function(String section) onOpenSection;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final now = DateTime.now();
    final monthStart = DateTime(now.year, now.month);

    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      key: ValueKey<int>(refreshKey),
      stream: appFirestore
          .collection('bills')
          .forAdminBranch()
          .where(
            'createdAt',
            isGreaterThanOrEqualTo: Timestamp.fromDate(monthStart),
          )
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
        return Row(
          children: [
            Expanded(
              child: _MiniStat(
                icon: Icons.receipt_long_rounded,
                label: l10n.statBillsThisMonth,
                value: loading ? '—' : '${docs.length}',
                caption: l10n.statApprovedThisMonth('$approved'),
                onTap: () => onOpenSection('history'),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _MiniStat(
                icon: Icons.stars_rounded,
                label: l10n.statPointsIssued,
                value: loading
                    ? '—'
                    : PointsUtils.formatPoints(points.toDouble()),
                caption: l10n.statThisMonth,
              ),
            ),
          ],
        );
      },
    );
  }
}

class _MiniStat extends StatelessWidget {
  const _MiniStat({
    required this.icon,
    required this.label,
    required this.value,
    required this.caption,
    this.onTap,
  });
  final IconData icon;
  final String label;
  final String value;
  final String caption;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: onTap != null,
      label: '$label: $value, $caption',
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
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
            child: Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: context.themeGoldSoft,
                    borderRadius: AppRadius.md12,
                  ),
                  child: Icon(icon, size: 20, color: context.themePendingText),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        value,
                        style: AppTypography.section(
                          color: context.themeTextPrimary,
                        ),
                      ),
                      Text(
                        label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.caption(
                          color: context.themeTextSecondary,
                        ),
                      ),
                    ],
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

// ── Menu ────────────────────────────────────────────────────────────────────

class _SectionCard {
  const _SectionCard({required this.id, required this.icon});
  final String id;
  final IconData icon;
}

class _MenuItem {
  const _MenuItem({
    required this.id,
    required this.icon,
    required this.badge,
    required this.onTap,
  });
  final String id;
  final IconData icon;
  final int? badge;
  final VoidCallback onTap;

  /// Members always show their count; other sections only when something
  /// is waiting.
  bool get showBadge => badge != null && (id == 'users' || badge! > 0);
}

String _labelOf(AppLocalizations l10n, String id) => switch (id) {
  'pending' => l10n.pendingBills,
  'history' => l10n.billHistory,
  'offers' => l10n.offers,
  'broadcast' => l10n.sendNotification,
  'greeting' => l10n.sendGreeting,
  'catalogs' => l10n.catalogs,
  'users' => l10n.users,
  'notifications' => l10n.notifications,
  'spin' => l10n.spin,
  'enquiries' => l10n.enquiries,
  'requests' => l10n.accountRequests,
  _ => id,
};

String _descOf(AppLocalizations l10n, String id) => switch (id) {
  'pending' => l10n.adminDescPending,
  'history' => l10n.adminDescHistory,
  'offers' => l10n.adminDescOffers,
  'broadcast' => l10n.adminDescBroadcast,
  'greeting' => l10n.adminDescGreeting,
  'catalogs' => l10n.adminDescCatalogs,
  'users' => l10n.adminDescUsers,
  'notifications' => l10n.adminDescNotifications,
  'spin' => l10n.adminDescSpin,
  'enquiries' => l10n.adminDescEnquiries,
  'requests' => l10n.adminDescRequests,
  _ => '',
};

class _MenuHeader extends StatelessWidget {
  const _MenuHeader({
    required this.listView,
    required this.onToggleView,
    required this.onEditOrder,
  });
  final bool listView;
  final VoidCallback onToggleView;
  final VoidCallback onEditOrder;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Row(
      children: [
        Expanded(
          child: Text(
            l10n.menu,
            style: AppTypography.section(color: context.themeTextPrimary),
          ),
        ),
        IconButton(
          tooltip: listView ? l10n.adminViewGrid : l10n.adminViewList,
          onPressed: onToggleView,
          icon: Icon(
            listView ? Icons.grid_view_rounded : Icons.view_agenda_rounded,
            color: context.themeContentColor,
          ),
        ),
        IconButton(
          tooltip: l10n.adminEditMenu,
          onPressed: onEditOrder,
          icon: Icon(Icons.tune_rounded, color: context.themeContentColor),
        ),
      ],
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge(this.count);
  final int count;

  @override
  Widget build(BuildContext context) => Container(
    constraints: const BoxConstraints(minWidth: 24),
    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
    decoration: const BoxDecoration(
      color: AppColors.gold,
      borderRadius: AppRadius.pill,
    ),
    child: Text(
      '$count',
      textAlign: TextAlign.center,
      style: AppTypography.labelSmall(color: AppColors.primary),
    ),
  );
}

class _IconSquare extends StatelessWidget {
  const _IconSquare(this.icon, {this.size = 42});
  final IconData icon;
  final double size;

  @override
  Widget build(BuildContext context) => Container(
    width: size,
    height: size,
    decoration: BoxDecoration(
      // Navy squares vanish on dark cards: use a lighter tint there.
      color: context.isDarkMode
          ? AppColors.primaryOnDark.withValues(alpha: 0.28)
          : AppColors.primary,
      borderRadius: const BorderRadius.all(Radius.circular(12)),
    ),
    child: Icon(icon, size: size * 0.52, color: AppColors.gold),
  );
}

class _MenuGridTile extends StatelessWidget {
  const _MenuGridTile({required this.item});
  final _MenuItem item;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final label = _labelOf(l10n, item.id);
    return Semantics(
      button: true,
      label: item.showBadge ? '$label, ${item.badge}' : label,
      excludeSemantics: true,
      child: Material(
        color: context.themeCard,
        shape: RoundedRectangleBorder(
          borderRadius: AppRadius.all16,
          side: BorderSide(color: context.themeBorder),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: item.onTap,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _IconSquare(item.icon),
                    const Spacer(),
                    if (item.showBadge) _Badge(item.badge!),
                  ],
                ),
                const Spacer(),
                Text(
                  label,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.label(
                    color: context.themeContentColor,
                  ).copyWith(fontSize: 14, height: 1.2),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _MenuList extends StatelessWidget {
  const _MenuList({required this.items});
  final List<_MenuItem> items;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Material(
      color: context.themeCard,
      shape: RoundedRectangleBorder(
        borderRadius: AppRadius.all16,
        side: BorderSide(color: context.themeBorder),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          for (var i = 0; i < items.length; i++) ...[
            if (i > 0)
              Divider(height: 1, indent: 70, color: context.themeDivider),
            Semantics(
              button: true,
              label: items[i].showBadge
                  ? '${_labelOf(l10n, items[i].id)}, ${items[i].badge}'
                  : _labelOf(l10n, items[i].id),
              excludeSemantics: true,
              child: InkWell(
                onTap: items[i].onTap,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(14, 12, 10, 12),
                  child: Row(
                    children: [
                      _IconSquare(items[i].icon, size: 42),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _labelOf(l10n, items[i].id),
                              style: AppTypography.label(
                                color: context.themeContentColor,
                              ).copyWith(fontSize: 14),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              _descOf(l10n, items[i].id),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: AppTypography.caption(
                                color: context.themeTextSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (items[i].showBadge) ...[
                        const SizedBox(width: 8),
                        _Badge(items[i].badge!),
                      ],
                      Icon(
                        Icons.chevron_right_rounded,
                        color: context.themeTextMuted,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Bottom sheet: drag the menu sections into the order the admin wants.
class _ReorderSheet extends StatefulWidget {
  const _ReorderSheet({
    required this.order,
    required this.defaults,
    required this.iconOf,
  });
  final List<String> order;
  final List<String> defaults;
  final IconData Function(String id) iconOf;

  @override
  State<_ReorderSheet> createState() => _ReorderSheetState();
}

class _ReorderSheetState extends State<_ReorderSheet> {
  late List<String> _ids = List.of(widget.order);

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final maxHeight = MediaQuery.sizeOf(context).height * 0.8;
    return ConstrainedBox(
      constraints: BoxConstraints(maxHeight: maxHeight),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 12, 4),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.adminEditMenu,
                        style: AppTypography.section(
                          color: context.themeTextPrimary,
                        ),
                      ),
                      Text(
                        l10n.adminEditMenuHint,
                        style: AppTypography.caption(
                          color: context.themeTextSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                TextButton(
                  onPressed: () =>
                      setState(() => _ids = List.of(widget.defaults)),
                  child: Text(l10n.adminResetMenu),
                ),
              ],
            ),
          ),
          Flexible(
            child: ReorderableListView.builder(
              shrinkWrap: true,
              buildDefaultDragHandles: false,
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
              itemCount: _ids.length,
              onReorder: (from, to) => setState(() {
                if (to > from) to--;
                _ids.insert(to, _ids.removeAt(from));
              }),
              itemBuilder: (context, i) {
                final id = _ids[i];
                return Padding(
                  key: ValueKey(id),
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Material(
                    color: context.themeCard,
                    shape: RoundedRectangleBorder(
                      borderRadius: AppRadius.md12,
                      side: BorderSide(color: context.themeBorder),
                    ),
                    child: ReorderableDragStartListener(
                      index: i,
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(10, 8, 6, 8),
                        child: Row(
                          children: [
                            _IconSquare(widget.iconOf(id), size: 34),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                _labelOf(l10n, id),
                                style: AppTypography.label(
                                  color: context.themeContentColor,
                                ),
                              ),
                            ),
                            Icon(
                              Icons.drag_indicator_rounded,
                              color: context.themeTextMuted,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
              child: FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.gold,
                  foregroundColor: AppColors.primary,
                  minimumSize: const Size.fromHeight(48),
                  shape: const StadiumBorder(),
                ),
                onPressed: () => Navigator.pop(context, _ids),
                child: Text(l10n.done),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
