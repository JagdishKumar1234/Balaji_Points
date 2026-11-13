import 'package:balaji_points/services/notifications/notification_visibility.dart';
import 'package:balaji_points/core/design/app_radius.dart';
import 'package:balaji_points/presentation/widgets/shared/app_button.dart';
import 'package:balaji_points/presentation/widgets/shared/app_text.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:balaji_points/presentation/widgets/shared/app_loader.dart';
import 'package:balaji_points/l10n/app_localizations.dart';
import 'package:balaji_points/core/design/app_colors.dart';
import 'package:balaji_points/core/design/app_typography.dart';
import 'package:intl/intl.dart';
import 'package:go_router/go_router.dart';

import 'package:balaji_points/presentation/widgets/carpenter/home_nav_bar.dart';

/// Admin-only notifications screen.
///
/// This is intentionally independent from the carpenter `NotificationsPage`
/// to avoid crashes/indexing issues caused by shared notification logic.
class AdminNotificationsPage extends StatefulWidget {
  /// If embedded inside `AdminHomePage`, the parent already shows AppBar.
  /// In that case we must not render `HomeNavBar` again.
  const AdminNotificationsPage({super.key, this.embedded = false});

  final bool embedded;

  @override
  State<AdminNotificationsPage> createState() => _AdminNotificationsPageState();
}

class _AdminNotificationsPageState extends State<AdminNotificationsPage> {
  static const List<String> _adminNotificationTypes = [
    'newPendingBill',
    'newUserRegistered',
  ];

  late final Stream<QuerySnapshot<Map<String, dynamic>>> _notificationsStream;

  String? _asString(dynamic value) => value is String ? value : null;

  Timestamp? _asTimestamp(dynamic value) => value is Timestamp ? value : null;

  @override
  void initState() {
    super.initState();
    // Simple query for admin badges/list.
    // No `orderBy` here to avoid Firestore index requirements.
    _notificationsStream = FirebaseFirestore.instance
        .collection('notification_logs')
        .where('type', whereIn: _adminNotificationTypes)
        .snapshots();
  }

  Future<void> _deleteNotification(String notificationId) async {
    await FirebaseFirestore.instance
        .collection('notification_logs')
        .doc(notificationId)
        .delete();
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

    if (confirmed != true) return;

    // Show a blocking progress while deleting.
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: AppLoader()),
    );

    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('notification_logs')
          .where('type', whereIn: _adminNotificationTypes)
          .get();

      final docs = snapshot.docs.visibleToAdmin();
      if (docs.isEmpty) {
        if (context.mounted) Navigator.of(context).pop();
        return;
      }

      // Firestore batch limit is 500 writes. Keep it safe.
      const batchSize = 450;
      for (int i = 0; i < docs.length; i += batchSize) {
        final batch = FirebaseFirestore.instance.batch();
        final chunk = docs.sublist(
          i,
          i + batchSize < docs.length ? i + batchSize : docs.length,
        );
        for (final doc in chunk) {
          batch.delete(doc.reference);
        }
        await batch.commit();
      }

      if (context.mounted) {
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
      }
    } catch (e) {
      if (context.mounted) Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context)!.deleteFailed('$e')),
          backgroundColor: context.themeError,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  String _formatTimestamp(Timestamp? timestamp) {
    if (timestamp == null) return AppLocalizations.of(context)!.justNow;

    final date = timestamp.toDate();
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      if (difference.inHours == 0) {
        if (difference.inMinutes == 0)
          return AppLocalizations.of(context)!.justNow;
        return AppLocalizations.of(context)!.mAgo('${difference.inMinutes}');
      }
      return AppLocalizations.of(context)!.hAgo('${difference.inHours}');
    } else if (difference.inDays == 1) {
      return AppLocalizations.of(context)!.yesterday;
    } else if (difference.inDays < 7) {
      return AppLocalizations.of(context)!.dAgo('${difference.inDays}');
    }

    return DateFormat('MMM dd, yyyy').format(date);
  }

  IconData _getNotificationIcon(String? type) {
    switch (type) {
      case 'newPendingBill':
        return Icons.receipt_long_rounded;
      case 'newUserRegistered':
        return Icons.person_add_rounded;
      default:
        return Icons.notifications_rounded;
    }
  }

  Color _getNotificationColor(String? type) {
    switch (type) {
      case 'newPendingBill':
        return context.themePrimary;
      case 'newUserRegistered':
        return AppColors.success;
      default:
        return context.themePrimary;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    debugPrint('AdminNotificationsPage: build');

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: Column(
        children: [
          StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
            stream: _notificationsStream,
            builder: (context, snapshot) {
              final notificationCount = snapshot.hasError
                  ? 0
                  : snapshot.data?.docs.visibleToAdmin().length ?? 0;

              if (widget.embedded) {
                // Parent `AdminHomePage` already provides the top AppBar.
                return const SizedBox.shrink();
              }

              return HomeNavBar(
                title: AppLocalizations.of(context)!.notifications,
                showLogo: false,
                showProfileButton: false,
                showBackButton: true,
                onBackTap: () => context.go('/admin'),
                actions: [
                  IconButton(
                    icon: const Icon(Icons.delete_outline_rounded, size: 22),
                    onPressed: notificationCount > 0
                        ? _deleteAllNotifications
                        : null,
                    tooltip: notificationCount > 0
                        ? AppLocalizations.of(context)!.deleteAll2
                        : null,
                  ),
                ],
              );
            },
          ),
          Container(
            height: 1,
            decoration: BoxDecoration(color: AppColors.primary),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: _notificationsStream,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: AppLoader());
                }

                if (snapshot.hasError) {
                  debugPrint(
                    'AdminNotificationsPage: stream error: ${snapshot.error}',
                  );
                  return Center(
                    child: Text(
                      AppLocalizations.of(
                        context,
                      )!.unableToLoadAdminNotifications,
                    ),
                  );
                }

                final notifications =
                    (snapshot.data?.docs ??
                            const <
                              QueryDocumentSnapshot<Map<String, dynamic>>
                            >[])
                        .visibleToAdmin();

                if (notifications.isEmpty) {
                  return ListView(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 120),
                    children: [
                      const SizedBox(height: 24),
                      AppText.label(
                        AppLocalizations.of(context)!.noNotifications,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        AppLocalizations.of(context)!.youDonTHaveAnyAdmin,
                        style: AppTypography.bodyMedium().copyWith(
                          fontSize: 16,
                          color: context.themeTextSecondary,
                        ),
                      ),
                    ],
                  );
                }

                // Sort by `sentAt` safely in-memory (no Firestore orderBy).
                final sortedNotifications = [...notifications];
                sortedNotifications.sort((a, b) {
                  final aSentAtValue = a.data()['sentAt'];
                  final bSentAtValue = b.data()['sentAt'];
                  final Timestamp? aTs = aSentAtValue is Timestamp
                      ? aSentAtValue
                      : null;
                  final Timestamp? bTs = bSentAtValue is Timestamp
                      ? bSentAtValue
                      : null;
                  if (aTs == null && bTs == null) return 0;
                  if (aTs == null) return 1;
                  if (bTs == null) return -1;
                  return bTs.compareTo(aTs); // desc
                });

                return RefreshIndicator(
                  onRefresh: () async {
                    await Future.delayed(const Duration(milliseconds: 500));
                  },
                  color: context.themeContentColor,
                  child: ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 120),
                    itemCount: sortedNotifications.length,
                    itemBuilder: (context, index) {
                      final doc = sortedNotifications[index];
                      final data = doc.data();

                      final type = _asString(data['type']);
                      final title =
                          _asString(data['title']) ??
                          AppLocalizations.of(context)!.notification;
                      final body = _asString(data['body']) ?? '';
                      final sentAtValue = data['sentAt'];
                      final Timestamp? sentAt = _asTimestamp(sentAtValue);

                      final notificationColor = _getNotificationColor(type);
                      final notificationIcon = _getNotificationIcon(type);

                      return Dismissible(
                        key: ValueKey(doc.id),
                        direction: DismissDirection.endToStart,
                        background: Container(
                          margin: const EdgeInsets.only(bottom: 12),
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
                        confirmDismiss: (direction) async {
                          return await showDialog<bool>(
                                context: context,
                                builder: (context) => AlertDialog(
                                  shape: RoundedRectangleBorder(
                                    borderRadius: AppRadius.all16,
                                  ),
                                  title: Text(
                                    AppLocalizations.of(
                                      context,
                                    )!.deleteNotification2,
                                  ),
                                  content: Text(
                                    AppLocalizations.of(
                                      context,
                                    )!.deleteNotificationConfirm,
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed: () =>
                                          Navigator.of(context).pop(false),
                                      child: Text(
                                        AppLocalizations.of(context)!.cancel,
                                      ),
                                    ),
                                    AppButton(
                                      label: "action",
                                      onPressed: () =>
                                          Navigator.of(context).pop(true),
                                      variant: AppButtonVariant.danger,
                                      fullWidth: false,
                                    ),
                                  ],
                                ),
                              ) ??
                              false;
                        },
                        onDismissed: (_) => _deleteNotification(doc.id),
                        child: InkWell(
                          onTap: null,
                          borderRadius: AppRadius.all16,
                          child: Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.surface,
                              borderRadius: AppRadius.all16,
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.black.withValues(
                                    alpha: 0.04,
                                  ),
                                  blurRadius: 10,
                                  offset: const Offset(0, 2),
                                ),
                                BoxShadow(
                                  color: AppColors.black.withValues(
                                    alpha: 0.02,
                                  ),
                                  blurRadius: 4,
                                  offset: const Offset(0, 1),
                                ),
                              ],
                              border: Border(
                                left: BorderSide(
                                  color: notificationColor,
                                  width: 4,
                                ),
                              ),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(14),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    width: 44,
                                    height: 44,
                                    decoration: BoxDecoration(
                                      color: notificationColor.withValues(
                                        alpha: 0.2,
                                      ),
                                      borderRadius: AppRadius.md12,
                                    ),
                                    child: Icon(
                                      notificationIcon,
                                      color: notificationColor,
                                      size: 22,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Expanded(
                                              child: Text(
                                                title,
                                                style: AppTypography.labelLarge()
                                                    .copyWith(
                                                      fontSize: 15,
                                                      color: context
                                                          .themeContentColor,
                                                      letterSpacing: -0.2,
                                                    ),
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            AppText.caption(
                                              _formatTimestamp(sentAt),
                                              color: context.themeTextSecondary,
                                            ),
                                          ],
                                        ),
                                        if (body.isNotEmpty) ...[
                                          const SizedBox(height: 6),
                                          Text(
                                            body,
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                            style: AppTypography.bodyMedium()
                                                .copyWith(
                                                  fontSize: 13,
                                                  color: context
                                                      .themeTextSecondary,
                                                ),
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
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
