import 'package:balaji_points/services/notifications/notification_visibility.dart';
import 'package:balaji_points/core/design/app_radius.dart';
import 'package:balaji_points/presentation/widgets/shared/app_button.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:balaji_points/core/firebase/app_firestore.dart';
import 'package:flutter/material.dart';
import 'package:balaji_points/presentation/widgets/shared/app_loader.dart';
import 'package:balaji_points/presentation/widgets/shared/empty_state.dart';
import 'package:balaji_points/l10n/app_localizations.dart';
import 'package:balaji_points/core/design/app_colors.dart';
import 'package:balaji_points/core/design/app_typography.dart';
import 'package:intl/intl.dart';
import 'package:go_router/go_router.dart';

import 'package:balaji_points/presentation/widgets/carpenter/home_nav_bar.dart';

/// What an admin alert is about. Decides its icon, filter chip and the
/// screen a tap opens. Admin-only; member notifications have their own
/// categories (NotificationCategory) and are not affected.
enum AdminNotificationCategory {
  bill('newPendingBill', Icons.receipt_long_rounded, 'pending'),
  request('newUserRegistered', Icons.how_to_reg_rounded, 'requests'),
  spin('spinReminder', Icons.casino_rounded, 'spin');

  const AdminNotificationCategory(this.type, this.icon, this.section);

  /// `notification_logs.type` of this kind of alert.
  final String type;
  final IconData icon;

  /// Admin section a tap opens.
  final String section;

  static AdminNotificationCategory? ofType(String? type) {
    for (final c in values) {
      if (c.type == type) return c;
    }
    return null;
  }

  String label(AppLocalizations l10n) => switch (this) {
    bill => l10n.adminNotifCatBill,
    request => l10n.adminNotifCatRequest,
    spin => l10n.adminNotifCatSpin,
  };

  String action(AppLocalizations l10n) => switch (this) {
    bill => l10n.adminNotifActBill,
    request => l10n.adminNotifActRequest,
    spin => l10n.adminNotifActSpin,
  };
}

/// Admin-only notifications screen: new bills and account requests for
/// this admin's branch, with category chips and day groups. A tap opens the
/// matching admin screen.
///
/// Independent from the member `NotificationsPage` on purpose.
class AdminNotificationsPage extends StatefulWidget {
  /// If embedded inside `AdminHomePage`, the parent already shows AppBar.
  /// In that case we must not render `HomeNavBar` again.
  const AdminNotificationsPage({
    super.key,
    this.embedded = false,
    this.onOpenSection,
  });

  final bool embedded;

  /// Opens an admin section (from `AdminHomePage`). Without it a tap goes
  /// back to the admin dashboard.
  final void Function(String section)? onOpenSection;

  @override
  State<AdminNotificationsPage> createState() => _AdminNotificationsPageState();
}

class _AdminNotificationsPageState extends State<AdminNotificationsPage> {
  static final List<String> _adminNotificationTypes = [
    for (final c in AdminNotificationCategory.values) c.type,
  ];

  late final Stream<QuerySnapshot<Map<String, dynamic>>> _notificationsStream;

  /// Chip picked above the list; null shows everything.
  AdminNotificationCategory? _filter;

  /// Swiped away; a dismissed Dismissible must leave the tree at once.
  final Set<String> _dismissedIds = {};

  @override
  void initState() {
    super.initState();
    // No `orderBy` here to avoid Firestore index requirements.
    _notificationsStream = appFirestore
        .collection('notification_logs')
        .where('type', whereIn: _adminNotificationTypes)
        .snapshots();
  }

  Future<void> _deleteNotification(String notificationId) async {
    setState(() => _dismissedIds.add(notificationId));
    try {
      await appFirestore
          .collection('notification_logs')
          .doc(notificationId)
          .delete();
    } catch (e) {
      if (!mounted) return;
      setState(() => _dismissedIds.remove(notificationId));
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context)!.deleteFailed('$e')),
          backgroundColor: context.themeError,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _deleteAllNotifications() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: AppRadius.all16),
        title: Text(AppLocalizations.of(context)!.deleteAllNotifications2),
        content: Text(AppLocalizations.of(context)!.areYouSureYouWantTo2),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(AppLocalizations.of(context)!.cancel),
          ),
          AppButton(
            label: AppLocalizations.of(context)!.deleteAll,
            onPressed: () => Navigator.of(context).pop(true),
            variant: AppButtonVariant.danger,
            fullWidth: false,
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: AppLoader()),
    );

    try {
      final snapshot = await appFirestore
          .collection('notification_logs')
          .where('type', whereIn: _adminNotificationTypes)
          .get();

      final docs = snapshot.docs.visibleToAdmin();
      const batchSize = 450;
      for (int i = 0; i < docs.length; i += batchSize) {
        final batch = appFirestore.batch();
        final end = i + batchSize < docs.length ? i + batchSize : docs.length;
        for (final doc in docs.sublist(i, end)) {
          batch.delete(doc.reference);
        }
        await batch.commit();
      }

      if (!mounted) return;
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            AppLocalizations.of(
              context,
            )!.notificationSDeleted('${docs.length}'),
          ),
          backgroundColor: context.themePrimary,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context)!.deleteFailed('$e')),
          backgroundColor: context.themeError,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _open(AdminNotificationCategory category) {
    final open = widget.onOpenSection;
    if (open != null) {
      open(category.section);
    } else if (category == AdminNotificationCategory.request) {
      context.push('/account-requests');
    } else {
      context.go('/admin');
    }
  }

  String _formatTimestamp(Timestamp? timestamp) {
    final l10n = AppLocalizations.of(context)!;
    if (timestamp == null) return l10n.justNow;
    final date = timestamp.toDate();
    final difference = DateTime.now().difference(date);
    if (difference.inDays == 0) {
      if (difference.inHours == 0) {
        if (difference.inMinutes == 0) return l10n.justNow;
        return l10n.mAgo('${difference.inMinutes}');
      }
      return l10n.hAgo('${difference.inHours}');
    } else if (difference.inDays == 1) {
      return l10n.yesterday;
    } else if (difference.inDays < 7) {
      return l10n.dAgo('${difference.inDays}');
    }
    return DateFormat('MMM dd, yyyy').format(date);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      backgroundColor: context.themeBackground,
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: _notificationsStream,
        builder: (context, snapshot) {
          final all =
              (snapshot.data?.docs ??
                      const <QueryDocumentSnapshot<Map<String, dynamic>>>[])
                  .visibleToAdmin()
                  .where((d) => !_dismissedIds.contains(d.id))
                  .toList();

          final Widget body;
          if (snapshot.connectionState == ConnectionState.waiting &&
              !snapshot.hasData) {
            body = const Center(child: AppLoader());
          } else if (snapshot.hasError) {
            body = Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  l10n.unableToLoadAdminNotifications,
                  textAlign: TextAlign.center,
                ),
              ),
            );
          } else if (all.isEmpty) {
            body = ListView(
              padding: const EdgeInsets.all(24),
              children: [
                const SizedBox(height: 48),
                EmptyState(
                  icon: Icons.notifications_none_rounded,
                  title: l10n.noNotifications,
                  message: l10n.youDonTHaveAnyAdmin,
                ),
              ],
            );
          } else {
            body = _buildList(all);
          }

          return Column(
            children: [
              if (!widget.embedded)
                HomeNavBar(
                  title: l10n.notifications,
                  showLogo: false,
                  showProfileButton: false,
                  showBackButton: true,
                  onBackTap: () => context.go('/admin'),
                  actions: [
                    IconButton(
                      icon: const Icon(Icons.delete_outline_rounded, size: 22),
                      onPressed: all.isNotEmpty
                          ? _deleteAllNotifications
                          : null,
                      tooltip: all.isNotEmpty ? l10n.deleteAll2 : null,
                    ),
                  ],
                ),
              Expanded(child: body),
            ],
          );
        },
      ),
    );
  }

  Widget _buildList(List<QueryDocumentSnapshot<Map<String, dynamic>>> all) {
    final l10n = AppLocalizations.of(context)!;

    // Newest first, sorted in memory (no Firestore orderBy).
    final sorted = [...all]
      ..sort((a, b) {
        final at = a.data()['sentAt'];
        final bt = b.data()['sentAt'];
        if (at is! Timestamp && bt is! Timestamp) return 0;
        if (at is! Timestamp) return 1;
        if (bt is! Timestamp) return -1;
        return bt.compareTo(at);
      });

    final counts = <AdminNotificationCategory, int>{};
    for (final d in sorted) {
      final c = AdminNotificationCategory.ofType(d.data()['type'] as String?);
      if (c != null) counts[c] = (counts[c] ?? 0) + 1;
    }
    final filter = counts.containsKey(_filter) ? _filter : null;
    final shown = filter == null
        ? sorted
        : sorted
              .where(
                (d) =>
                    AdminNotificationCategory.ofType(
                      d.data()['type'] as String?,
                    ) ==
                    filter,
              )
              .toList();

    final today = DateUtils.dateOnly(DateTime.now());
    String section(Timestamp? t) {
      if (t == null) return l10n.today;
      final day = DateUtils.dateOnly(t.toDate());
      if (day == today) return l10n.today;
      if (today.difference(day).inDays == 1) return l10n.yesterday;
      return l10n.notifEarlier;
    }

    final rows = <Widget>[];
    String? last;
    for (final doc in shown) {
      final data = doc.data();
      final sentAt = data['sentAt'] is Timestamp
          ? data['sentAt'] as Timestamp
          : null;
      final heading = section(sentAt);
      if (heading != last) {
        last = heading;
        rows.add(
          Padding(
            padding: EdgeInsets.fromLTRB(4, rows.isEmpty ? 4 : 14, 4, 8),
            child: Text(
              heading,
              style: AppTypography.label(color: context.themeTextSecondary),
            ),
          ),
        );
      }
      rows.add(_tile(doc.id, data, sentAt));
    }

    return Column(
      children: [
        SizedBox(
          height: 52,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 6),
            children: [
              _chip(null, l10n.all, sorted.length, filter == null),
              for (final c in AdminNotificationCategory.values)
                if (counts.containsKey(c))
                  _chip(c, c.label(l10n), counts[c]!, filter == c),
            ],
          ),
        ),
        Expanded(
          child: RefreshIndicator(
            onRefresh: () => Future.delayed(const Duration(milliseconds: 500)),
            color: context.themeContentColor,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
              children: rows,
            ),
          ),
        ),
      ],
    );
  }

  Widget _chip(
    AdminNotificationCategory? c,
    String label,
    int count,
    bool selected,
  ) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text('$label  $count'),
        avatar: c == null
            ? null
            : Icon(
                c.icon,
                size: 16,
                color: selected
                    ? context.themeOnPrimary
                    : context.themePrimaryLight,
              ),
        selected: selected,
        showCheckmark: false,
        selectedColor: context.themePrimary,
        backgroundColor: context.themeCard,
        side: BorderSide(
          color: selected ? context.themePrimary : context.themeBorder,
        ),
        labelStyle: AppTypography.label(
          color: selected ? context.themeOnPrimary : context.themeTextPrimary,
        ),
        onSelected: (_) => setState(() => _filter = c),
      ),
    );
  }

  Widget _tile(String id, Map<String, dynamic> data, Timestamp? sentAt) {
    final l10n = AppLocalizations.of(context)!;
    final category = AdminNotificationCategory.ofType(data['type'] as String?);
    final title = data['title'] is String
        ? data['title'] as String
        : l10n.notification;
    final body = data['body'] is String ? data['body'] as String : '';
    final icon = category?.icon ?? Icons.notifications_rounded;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Dismissible(
        key: ValueKey(id),
        direction: DismissDirection.endToStart,
        background: Container(
          decoration: BoxDecoration(
            color: context.themeError,
            borderRadius: AppRadius.all16,
          ),
          alignment: Alignment.centerRight,
          padding: const EdgeInsets.only(right: 24),
          child: const Icon(
            Icons.delete_rounded,
            color: AppColors.white,
            size: 26,
          ),
        ),
        confirmDismiss: (_) async =>
            await showDialog<bool>(
              context: context,
              builder: (context) => AlertDialog(
                shape: RoundedRectangleBorder(borderRadius: AppRadius.all16),
                title: Text(l10n.deleteNotification2),
                content: Text(l10n.deleteNotificationConfirm),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(false),
                    child: Text(l10n.cancel),
                  ),
                  AppButton(
                    label: l10n.delete,
                    onPressed: () => Navigator.of(context).pop(true),
                    variant: AppButtonVariant.danger,
                    fullWidth: false,
                  ),
                ],
              ),
            ) ??
            false,
        onDismissed: (_) => _deleteNotification(id),
        child: Material(
          color: context.themeCard,
          borderRadius: AppRadius.all16,
          child: InkWell(
            onTap: category == null ? null : () => _open(category),
            borderRadius: AppRadius.all16,
            child: Ink(
              decoration: BoxDecoration(
                borderRadius: AppRadius.all16,
                border: Border.all(color: context.themeBorder),
              ),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 46,
                      height: 46,
                      decoration: BoxDecoration(
                        color: context.themePrimarySoft,
                        borderRadius: AppRadius.md12,
                      ),
                      child: Icon(
                        icon,
                        color: context.themePrimaryLight,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              if (category != null)
                                Flexible(
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: context.themePrimarySoft,
                                      borderRadius: AppRadius.pill,
                                    ),
                                    child: Text(
                                      category.label(l10n),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: AppTypography.labelSmall(
                                        color: context.themePrimaryLight,
                                      ),
                                    ),
                                  ),
                                ),
                              const Spacer(),
                              Text(
                                _formatTimestamp(sentAt),
                                style: AppTypography.caption(
                                  color: context.themeTextMuted,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text(
                            title,
                            style: AppTypography.buttonMedium().copyWith(
                              fontSize: 15,
                              color: context.themeTextPrimary,
                            ),
                          ),
                          if (body.isNotEmpty) ...[
                            const SizedBox(height: 3),
                            Text(
                              body,
                              maxLines: 3,
                              overflow: TextOverflow.ellipsis,
                              style: AppTypography.bodyMedium().copyWith(
                                fontSize: 13,
                                height: 1.35,
                                color: context.themeTextSecondary,
                              ),
                            ),
                          ],
                          if (category != null) ...[
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Text(
                                  category.action(l10n),
                                  style: AppTypography.bodySmall().copyWith(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                    color: context.themePrimaryLight,
                                  ),
                                ),
                                const SizedBox(width: 2),
                                Icon(
                                  Icons.chevron_right_rounded,
                                  size: 18,
                                  color: context.themePrimaryLight,
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
