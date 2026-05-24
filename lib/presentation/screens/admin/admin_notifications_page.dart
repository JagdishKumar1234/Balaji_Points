import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:balaji_points/core/design/app_colors.dart';
import 'package:balaji_points/core/design/app_typography.dart';
import 'package:intl/intl.dart';
import 'package:go_router/go_router.dart';

import 'package:balaji_points/presentation/widgets/home_nav_bar.dart';

/// Admin-only notifications screen.
///
/// This is intentionally independent from the carpenter `NotificationsPage`
/// to avoid crashes/indexing issues caused by shared notification logic.
class AdminNotificationsPage extends StatefulWidget {
  /// If embedded inside `AdminHomePage`, the parent already shows AppBar.
  /// In that case we must not render `HomeNavBar` again.
  const AdminNotificationsPage({
    super.key,
    this.embedded = false,
  });

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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Delete All Notifications'),
        content: const Text('Are you sure you want to delete all admin notifications?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFE53935),
              foregroundColor: AppColors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    // Show a blocking progress while deleting.
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('notification_logs')
          .where('type', whereIn: _adminNotificationTypes)
          .get();

      final docs = snapshot.docs;
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
            content: Text('${docs.length} notification(s) deleted'),
            backgroundColor: AppColors.lightPrimary,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Delete failed: $e'),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  String _formatTimestamp(Timestamp? timestamp) {
    if (timestamp == null) return 'Just now';

    final date = timestamp.toDate();
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      if (difference.inHours == 0) {
        if (difference.inMinutes == 0) return 'Just now';
        return '${difference.inMinutes}m ago';
      }
      return '${difference.inHours}h ago';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    }

    return DateFormat('MMM dd, yyyy').format(date);
  }

  IconData _getNotificationIcon(String? type) {
    switch (type) {
      case 'newPendingBill':
        return Icons.receipt_long;
      case 'newUserRegistered':
        return Icons.person_add;
      default:
        return Icons.notifications;
    }
  }

  Color _getNotificationColor(String? type) {
    switch (type) {
      case 'newPendingBill':
        return AppColors.info;
      case 'newUserRegistered':
        return AppColors.success;
      default:
        return AppColors.lightPrimary;
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
              final notificationCount =
                  snapshot.hasError ? 0 : snapshot.data?.docs.length ?? 0;

              if (widget.embedded) {
                // Parent `AdminHomePage` already provides the top AppBar.
                return const SizedBox.shrink();
              }

              return HomeNavBar(
                title: 'Notifications',
                showLogo: false,
                showProfileButton: false,
                showBackButton: true,
                onBackTap: () => context.go('/admin'),
                actions: [
                  IconButton(
                    icon: const Icon(Icons.delete_outline, size: 22),
                    onPressed:
                        notificationCount > 0 ? _deleteAllNotifications : null,
                    tooltip: notificationCount > 0 ? 'Delete All' : null,
                  ),
                ],
              );
            },
          ),
          Container(
            height: 1,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: AppColors.primaryGradient,
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
              ),
            ),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: _notificationsStream,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  debugPrint(
                    'AdminNotificationsPage: stream error: ${snapshot.error}',
                  );
                  return const Center(
                    child: Text('Unable to load admin notifications'),
                  );
                }

                final notifications =
                    snapshot.data?.docs ?? const <QueryDocumentSnapshot<Map<String, dynamic>>>[];

                if (notifications.isEmpty) {
                  return ListView(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 120),
                    children: [
                      const SizedBox(height: 24),
                      Text(
                        'No Notifications',
                        style: AppTypography.labelLarge().copyWith(
                          fontSize: 24,
                          color: AppColors.lightPrimary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'You don\'t have any admin notifications yet',
                        style: AppTypography.bodyMedium().copyWith(
                          fontSize: 16,
                          color: AppColors.grey600,
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
                  final Timestamp? aTs =
                      aSentAtValue is Timestamp ? aSentAtValue : null;
                  final Timestamp? bTs =
                      bSentAtValue is Timestamp ? bSentAtValue : null;
                  if (aTs == null && bTs == null) return 0;
                  if (aTs == null) return 1;
                  if (bTs == null) return -1;
                  return bTs.compareTo(aTs); // desc
                });

                return RefreshIndicator(
                  onRefresh: () async {
                    await Future.delayed(const Duration(milliseconds: 500));
                  },
                  color: AppColors.lightPrimary,
                  child: ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 120),
                    itemCount: sortedNotifications.length,
                    itemBuilder: (context, index) {
                      final doc = sortedNotifications[index];
                      final data = doc.data();

                      final type = _asString(data['type']);
                      final title = _asString(data['title']) ?? 'Notification';
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
                            color: const Color(0xFFE53935),
                            borderRadius: BorderRadius.circular(16),
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
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  title: const Text('Delete Notification'),
                                  content: const Text(
                                    'Are you sure you want to delete this notification?',
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed: () =>
                                          Navigator.of(context).pop(false),
                                      child: const Text('Cancel'),
                                    ),
                                    ElevatedButton(
                                      onPressed: () =>
                                          Navigator.of(context).pop(true),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: const Color(0xFFE53935),
                                        foregroundColor: AppColors.white,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                      ),
                                      child: const Text('Delete'),
                                    ),
                                  ],
                                ),
                              ) ??
                              false;
                        },
                        onDismissed: (_) => _deleteNotification(doc.id),
                        child: InkWell(
                          onTap: null,
                          borderRadius: BorderRadius.circular(14),
                          child: Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.surface,
                              borderRadius: BorderRadius.circular(14),
                              boxShadow: [
                                BoxShadow(
                                  color:
                                      AppColors.black.withValues(alpha: 0.04),
                                  blurRadius: 10,
                                  offset: const Offset(0, 2),
                                ),
                                BoxShadow(
                                  color:
                                      AppColors.black.withValues(alpha: 0.02),
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
                                      gradient: LinearGradient(
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                        colors: [
                                          notificationColor
                                              .withValues(alpha: 0.2),
                                          notificationColor
                                              .withValues(alpha: 0.1),
                                        ],
                                      ),
                                      borderRadius: BorderRadius.circular(12),
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
                                                  color: AppColors.lightPrimary,
                                                  letterSpacing: -0.2,
                                                ),
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            Text(
                                              _formatTimestamp(sentAt),
                                              style: TextStyle(
                                                fontSize: 12,
                                                color: AppColors.grey600,
                                              ),
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
                                              color: AppColors.grey600,
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

