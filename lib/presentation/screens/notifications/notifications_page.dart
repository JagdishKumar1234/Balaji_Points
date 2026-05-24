import 'package:balaji_points/core/design/app_colors.dart';
// lib/presentation/screens/notifications/notifications_page.dart
// Notifications screen for carpenters to view and manage their notifications

import 'package:balaji_points/presentation/widgets/home_nav_bar.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:go_router/go_router.dart';
import 'package:balaji_points/config/theme.dart' hide AppColors;
import 'package:balaji_points/services/session_service.dart';
import 'dart:async';

enum NotificationsPageMode {
  /// Decide behavior from the logged-in user's role.
  auto,

  /// Force carpenter behavior (personal + broadcast notifications).
  carpenter,

  /// Force admin behavior (admin-only notifications + admin back navigation).
  admin,
}

class NotificationsPage extends StatefulWidget {
  const NotificationsPage({super.key, this.mode = NotificationsPageMode.auto});

  final NotificationsPageMode mode;

  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {
  final SessionService _sessionService = SessionService();
  String? _userId;
  String? _userRole;
  bool _isLoading = true;

  bool get _resolvedIsAdmin {
    if (widget.mode == NotificationsPageMode.admin) return true;
    if (widget.mode == NotificationsPageMode.carpenter) return false;
    return _userRole == 'admin';
  }

  // Stream controllers for merging queries
  Stream<List<QueryDocumentSnapshot>>? _mergedNotificationsStream;
  StreamController<List<QueryDocumentSnapshot>>? _streamController;
  StreamSubscription<QuerySnapshot>? _userNotificationsSubscription;
  StreamSubscription<QuerySnapshot>? _broadcastNotificationsSubscription;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final userId = await _sessionService.getUserId();
    final userRole = await _sessionService.getUserRole();
    setState(() {
      _userId = userId;
      _userRole = userRole;
      _isLoading = false;
    });

    // Create merged stream after userId is loaded
    if (userId != null) {
      _createMergedStream(userId);
    }
  }

  void _createMergedStream(String userId) {
    // Clean up existing subscriptions
    _userNotificationsSubscription?.cancel();
    _broadcastNotificationsSubscription?.cancel();
    _streamController?.close();

    debugPrint(
      '🔔 Creating notification stream for user: $userId (Role: $_userRole)',
    );

    // For carpenters: merge personal notifications + broadcast notifications
    // For admins: only admin-specific notifications
    if (!_resolvedIsAdmin) {
      // CARPENTERS: Show personal + broadcast notifications
      // Need to merge two streams: personal notifications + broadcast notifications
      _createCarpenterMergedStream(userId);
      return;
    }

    // ADMINS: Only show admin-specific notifications
    final notificationsQuery = FirebaseFirestore.instance
        .collection('notification_logs')
        .where('userId', isEqualTo: userId)
        .limit(50);

    debugPrint('✅ Admin Query: WHERE userId = $userId, LIMIT 50');

    // Use broadcast stream to allow multiple listeners (StreamBuilder may rebuild)
    _streamController =
        StreamController<List<QueryDocumentSnapshot>>.broadcast();

    // Single stream - filter only carpenter-relevant notifications
    _userNotificationsSubscription = notificationsQuery.snapshots().listen(
      (snapshot) {
        debugPrint(
          '📊 Received ${snapshot.docs.length} notifications from Firestore',
        );

        // SAFETY CHECK: Verify all notifications belong to this user
        if (snapshot.docs.isNotEmpty) {
          final firstDoc = snapshot.docs.first.data();
          final firstUserId = firstDoc['userId'];
          debugPrint(
            '   ✓ First notification userId: $firstUserId (Expected: $userId)',
          );

          // Double-check: filter out any notifications that don't belong to this user
          // (This should never happen due to Firestore query, but extra safety)
          final userNotifications = snapshot.docs.where((doc) {
            final data = doc.data();
            return data['userId'] == userId;
          }).toList();

          if (userNotifications.length != snapshot.docs.length) {
            debugPrint(
              '   ⚠️ WARNING: Filtered out ${snapshot.docs.length - userNotifications.length} notifications from other users!',
            );
          }
        }

        // Filter notifications based on user role
        List<QueryDocumentSnapshot> filteredDocs = snapshot.docs;

        if (_resolvedIsAdmin) {
          // Admins: show only admin-specific notifications
          filteredDocs = snapshot.docs.where((doc) {
            final data = doc.data();
            final type = data['type'] as String?;

            // Admin sees only these notification types
            const adminNotificationTypes = [
              'newPendingBill', // New bill to review
              'newUserRegistered', // New carpenter registered
              'dailySpinReminder', // Daily spin reminder (analytics)
            ];
            return adminNotificationTypes.contains(type);
          }).toList();

          debugPrint(
            '📊 After filtering: ${filteredDocs.length} admin notifications',
          );
        } else {
          // Carpenters: hide admin-only notifications + ensure user isolation
          filteredDocs = snapshot.docs.where((doc) {
            final data = doc.data();
            final type = data['type'] as String?;
            final notifUserId = data['userId'] as String?;

            // SAFETY: Ensure this notification belongs to THIS carpenter
            if (notifUserId != userId) {
              debugPrint(
                '   ⚠️ Skipping notification for different user: $notifUserId',
              );
              return false;
            }

            // Carpenter should NOT see these admin-only types
            const adminOnlyTypes = [
              'dailySpinReminder',
              'newPendingBill',
              'newUserRegistered',
            ];
            return !adminOnlyTypes.contains(type);
          }).toList();

          debugPrint(
            '📊 After filtering: ${filteredDocs.length} carpenter notifications (all for userId: $userId)',
          );
        }

        if (!_streamController!.isClosed) {
          _streamController!.add(filteredDocs);
        }
      },
      onError: (e) {
        debugPrint('❌ Admin notifications stream error: $e');
        // Don't crash the route; show empty notifications instead.
        if (!_streamController!.isClosed) {
          _streamController!.add(const []);
        }
      },
    );

    _mergedNotificationsStream = _streamController!.stream;

    setState(() {}); // Trigger rebuild with new stream
  }

  /// Create merged stream for carpenters (personal + broadcast notifications)
  void _createCarpenterMergedStream(String userId) {
    debugPrint('🔔 Creating CARPENTER notification stream with broadcasts');

    // Use broadcast stream to allow multiple listeners
    _streamController =
        StreamController<List<QueryDocumentSnapshot>>.broadcast();
    final Map<String, QueryDocumentSnapshot> combined = {};

    void updateCombined() {
      List<QueryDocumentSnapshot> result = combined.values.toList();

      // Filter out admin-only notifications
      result = result.where((doc) {
        final data = doc.data() as Map<String, dynamic>?;
        final type = data?['type'] as String?;

        // Carpenter should NOT see these admin-only types
        const adminOnlyTypes = [
          'dailySpinReminder', // Admin analytics
          'newPendingBill', // Admin notification
          'newUserRegistered', // Admin notification
        ];
        return !adminOnlyTypes.contains(type);
      }).toList();

      // DEDUPLICATION: Remove duplicate notifications based on unique key
      // Key = type + billId/data combination + approximate time
      final seen = <String>{};
      result = result.where((doc) {
        final data = doc.data() as Map<String, dynamic>?;
        final type = data?['type'] as String?;
        final notifData = data?['data'] as Map<String, dynamic>?;
        final billId = notifData?['billId'] as String?;
        final sentAt = data?['sentAt'] as Timestamp?;

        // Create unique key: type + billId + hour (to allow same bill notifications hours apart)
        final hourKey = sentAt != null
            ? '${sentAt.toDate().year}-${sentAt.toDate().month}-${sentAt.toDate().day}-${sentAt.toDate().hour}'
            : 'unknown';
        final uniqueKey = '$type-${billId ?? 'none'}-$hourKey';

        if (seen.contains(uniqueKey)) {
          debugPrint('   🔄 Skipping duplicate notification: $uniqueKey');
          return false; // Skip duplicate
        }
        seen.add(uniqueKey);
        return true;
      }).toList();

      // Sort by timestamp
      result.sort((a, b) {
        final aData = a.data() as Map<String, dynamic>?;
        final bData = b.data() as Map<String, dynamic>?;
        final aSentAt = aData?['sentAt'] as Timestamp?;
        final bSentAt = bData?['sentAt'] as Timestamp?;

        if (aSentAt == null && bSentAt == null) return 0;
        if (aSentAt == null) return 1;
        if (bSentAt == null) return -1;

        return bSentAt.compareTo(aSentAt); // Descending order
      });

      // Limit to 50 most recent
      if (result.length > 50) {
        result = result.sublist(0, 50);
      }

      debugPrint(
        '📊 Combined stream: ${result.length} carpenter notifications',
      );

      if (!_streamController!.isClosed) {
        _streamController!.add(result);
      }
    }

    // Stream 1: Personal notifications (bills, points, tier upgrades, etc.)
    final personalQuery = FirebaseFirestore.instance
        .collection('notification_logs')
        .where('userId', isEqualTo: userId)
        .orderBy('sentAt', descending: true)
        .limit(30); // Limit personal to 30

    debugPrint('   Stream 1: Personal notifications WHERE userId = $userId');

    _userNotificationsSubscription = personalQuery.snapshots().listen((
      snapshot,
    ) {
      // Add/update personal notifications
      for (var doc in snapshot.docs) {
        combined[doc.id] = doc;
      }
      updateCombined();
    });

    // Stream 2: Broadcast notifications (new offers, daily spin winners)
    final broadcastQuery = FirebaseFirestore.instance
        .collection('notification_logs')
        .where('isBroadcast', isEqualTo: true)
        .orderBy('sentAt', descending: true)
        .limit(20); // Limit broadcasts to 20

    debugPrint('   Stream 2: Broadcast notifications WHERE isBroadcast = true');

    _broadcastNotificationsSubscription = broadcastQuery.snapshots().listen((
      snapshot,
    ) {
      // Add/update broadcast notifications
      for (var doc in snapshot.docs) {
        combined[doc.id] = doc;
      }
      updateCombined();
    });

    _mergedNotificationsStream = _streamController!.stream;
    setState(() {}); // Trigger rebuild with new stream
  }

  @override
  void dispose() {
    _userNotificationsSubscription?.cancel();
    _broadcastNotificationsSubscription?.cancel();
    _streamController?.close();
    super.dispose();
  }

  Future<void> _deleteNotification(String notificationId) async {
    try {
      await FirebaseFirestore.instance
          .collection('notification_logs')
          .doc(notificationId)
          .delete();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Notification deleted'),
            backgroundColor: AppColors.lightPrimary,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      debugPrint('Error deleting notification: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error deleting notification: $e'),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<void> _deleteAllNotifications() async {
    if (_userId == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.error.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.delete_outline,
                color: const Color(0xFFD32F2F),
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Text(
                'Delete All Notifications',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        content: const Text(
          'Are you sure you want to delete all notifications? This action cannot be undone.',
          style: TextStyle(fontSize: 16),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(
              'Cancel',
              style: TextStyle(color: AppColors.grey600, fontSize: 16),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFE53935),
              foregroundColor: AppColors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text('Delete All', style: TextStyle(fontSize: 16)),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      // Show loading indicator
      if (mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) =>
              const Center(child: CircularProgressIndicator()),
        );
      }

      // Get user-specific notifications
      final userSnapshot = await FirebaseFirestore.instance
          .collection('notification_logs')
          .where('userId', isEqualTo: _userId)
          .get();

      // Combine notifications based on role
      final allDocs = <QueryDocumentSnapshot>[];
      allDocs.addAll(userSnapshot.docs);

      // Only admins can delete broadcast notification logs
      if (_resolvedIsAdmin) {
        final broadcastSnapshot = await FirebaseFirestore.instance
            .collection('notification_logs')
            .where('isBroadcast', isEqualTo: true)
            .get();
        allDocs.addAll(broadcastSnapshot.docs);
      }

      // Remove duplicates by document ID
      final uniqueDocs = <String, QueryDocumentSnapshot>{};
      for (var doc in allDocs) {
        uniqueDocs[doc.id] = doc;
      }

      final snapshot = uniqueDocs.values.toList();

      // Delete all notifications in batch
      final batch = FirebaseFirestore.instance.batch();
      for (var doc in snapshot) {
        // Get the document reference
        final docRef = doc.reference;
        batch.delete(docRef);
      }
      await batch.commit();

      // Close loading dialog
      if (mounted) {
        Navigator.of(context).pop();
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${snapshot.length} notification(s) deleted'),
            backgroundColor: AppColors.lightPrimary,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      debugPrint('Error deleting all notifications: $e');

      // Close loading dialog if still open
      if (mounted) {
        Navigator.of(context).pop();
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error deleting notifications: $e'),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  String _formatTimestamp(Timestamp? timestamp) {
    if (timestamp == null) return 'Just now';

    final date = timestamp.toDate();
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      if (difference.inHours == 0) {
        if (difference.inMinutes == 0) {
          return 'Just now';
        }
        return '${difference.inMinutes}m ago';
      }
      return '${difference.inHours}h ago';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return DateFormat('MMM dd, yyyy').format(date);
    }
  }

  IconData _getNotificationIcon(String? type) {
    switch (type) {
      case 'billApproved':
        return Icons.check_circle;
      case 'billRejected':
        return Icons.cancel;
      case 'pointsWithdrawn':
        return Icons.remove_circle;
      case 'tierUpgraded':
        return Icons.trending_up;
      case 'dailySpinWon':
        return Icons.casino;
      case 'offerRedeemed':
        return Icons.card_giftcard;
      case 'newOfferAvailable':
        return Icons.notifications_active;
      case 'pointsMilestone':
        return Icons.emoji_events;
      // Admin notification types
      case 'newPendingBill':
        return Icons.receipt_long;
      case 'newUserRegistered':
        return Icons.person_add;
      case 'dailySpinReminder':
        return Icons.casino;
      default:
        return Icons.notifications;
    }
  }

  Color _getNotificationColor(String? type) {
    switch (type) {
      case 'billApproved':
        return AppColors.success;
      case 'billRejected':
        return AppColors.error;
      case 'pointsWithdrawn':
        return AppColors.warning;
      case 'tierUpgraded':
        return const Color(0xFF9C27B0);
      case 'dailySpinWon':
        return const Color(0xFFFFC107);
      case 'offerRedeemed':
        return const Color(0xFF2196F3);
      case 'newOfferAvailable':
        return AppColors.lightPrimary;
      case 'pointsMilestone':
        return const Color(0xFFFFA000);
      // Admin notification types
      case 'newPendingBill':
        return AppColors.info;
      case 'newUserRegistered':
        return AppColors.success;
      case 'dailySpinReminder':
        return const Color(0xFFFFC107);
      default:
        return AppColors.lightPrimary;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (_isLoading) {
      return Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final bool isAdmin = _resolvedIsAdmin;

    if (_userId == null) {
      return Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        body: Column(
          children: [
            const HomeNavBar(
              title: 'Notifications',
              showLogo: false,
              showProfileButton: false,
            ),
            const Expanded(
              child: Center(child: Text('Unable to load notifications')),
            ),
          ],
        ),
      );
    }

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: Column(
        children: [
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              HomeNavBar(
                title: 'Notifications',
                showLogo: false,
                showProfileButton: false,
                showBackButton: isAdmin,
                // Notifications route lives inside the carpenter ShellRoute.
                // For admins, we must override back to return to Admin dashboard.
                onBackTap: isAdmin ? () => context.go('/admin') : null,
                actions: [
                  StreamBuilder<List<QueryDocumentSnapshot>>(
                    stream: _mergedNotificationsStream,
                    builder: (context, snapshot) {
                      final hasNotifications =
                          snapshot.hasData && snapshot.data!.isNotEmpty;
                      if (!hasNotifications) {
                        return const SizedBox.shrink();
                      }
                      return IconButton(
                        icon: const Icon(Icons.delete_outline, size: 22),
                        onPressed: _deleteAllNotifications,
                        tooltip: 'Delete All',
                      );
                    },
                  ),
                ],
              ),
            ],
          ),
          Expanded(
            child: Container(
              color: theme.colorScheme.surface,
              child: SafeArea(
                top: false,
                child: _mergedNotificationsStream == null
                    ? const Center(child: CircularProgressIndicator())
                    : StreamBuilder<List<QueryDocumentSnapshot>>(
                        stream: _mergedNotificationsStream,
                        builder: (context, snapshot) {
                          if (snapshot.connectionState ==
                              ConnectionState.waiting) {
                            return const Center(
                              child: CircularProgressIndicator(),
                            );
                          }

                          if (snapshot.hasError) {
                            return Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.error_outline,
                                    size: 64,
                                    color: const Color(0xFFE57373),
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    'Error loading notifications',
                                    style: TextStyle(
                                      color: AppColors.grey600,
                                      fontSize: 16,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  TextButton(
                                    onPressed: () => setState(() {}),
                                    child: const Text('Retry'),
                                  ),
                                ],
                              ),
                            );
                          }

                          if (!snapshot.hasData || snapshot.data!.isEmpty) {
                            return Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(24),
                                    decoration: BoxDecoration(
                                      color: AppColors.lightPrimary.withValues(
                                        alpha: 0.1,
                                      ),
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(
                                      Icons.notifications_none,
                                      size: 64,
                                      color: AppColors.lightPrimary.withValues(
                                        alpha: 0.5,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 24),
                                  Text(
                                    'No Notifications',
                                    style: AppTextStyles.nunitoBold.copyWith(
                                      fontSize: 24,
                                      color: AppColors.lightTextPrimary,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'You don\'t have any notifications yet',
                                    style: AppTextStyles.nunitoRegular.copyWith(
                                      fontSize: 16,
                                      color: AppColors.grey600,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }

                          final notifications = snapshot.data!;

                          return RefreshIndicator(
                            onRefresh: () async {
                              // Refresh is handled by StreamBuilder
                              await Future.delayed(
                                const Duration(milliseconds: 500),
                              );
                            },
                            color: AppColors.lightPrimary,
                            child: ListView.builder(
                              padding: const EdgeInsets.fromLTRB(
                                16,
                                16,
                                16,
                                120,
                              ),
                              itemCount: notifications.length,
                              itemBuilder: (context, index) {
                                final doc = notifications[index];
                                final data = doc.data() as Map<String, dynamic>;

                                final type = data['type'] as String?;
                                final title =
                                    data['title'] as String? ?? 'Notification';
                                final body = data['body'] as String? ?? '';
                                final sentAt = data['sentAt'] as Timestamp?;
                                final notificationColor = _getNotificationColor(
                                  type,
                                );

                                return Dismissible(
                                  key: Key(doc.id),
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
                                  onDismissed: (direction) {
                                    _deleteNotification(doc.id);
                                  },
                                  confirmDismiss: (direction) async {
                                    return await showDialog<bool>(
                                          context: context,
                                          builder: (context) => AlertDialog(
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(16),
                                            ),
                                            title: const Text(
                                              'Delete Notification',
                                            ),
                                            content: const Text(
                                              'Are you sure you want to delete this notification?',
                                            ),
                                            actions: [
                                              TextButton(
                                                onPressed: () => Navigator.of(
                                                  context,
                                                ).pop(false),
                                                child: Text(
                                                  'Cancel',
                                                  style: TextStyle(
                                                    color: AppColors.grey600,
                                                  ),
                                                ),
                                              ),
                                              ElevatedButton(
                                                onPressed: () => Navigator.of(
                                                  context,
                                                ).pop(true),
                                                style: ElevatedButton.styleFrom(
                                                  backgroundColor:
                                                      const Color(0xFFE53935),
                                                  foregroundColor:
                                                      AppColors.white,
                                                  shape: RoundedRectangleBorder(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          8,
                                                        ),
                                                  ),
                                                ),
                                                child: const Text('Delete'),
                                              ),
                                            ],
                                          ),
                                        ) ??
                                        false;
                                  },
                                  // Modern iOS-style notification card
                                  child: InkWell(
                                    onTap: () =>
                                        _handleNotificationTap(data, type),
                                    borderRadius: BorderRadius.circular(14),
                                    child: Container(
                                      margin: const EdgeInsets.only(bottom: 12),
                                      decoration: BoxDecoration(
                                        color: theme.colorScheme.surface,
                                        borderRadius: BorderRadius.circular(14),
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
                                      ),
                                      child: ClipRRect(
                                        borderRadius: BorderRadius.circular(14),
                                        child: Container(
                                          decoration: BoxDecoration(
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
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                // Icon with gradient background
                                                Container(
                                                  width: 44,
                                                  height: 44,
                                                  decoration: BoxDecoration(
                                                    gradient: LinearGradient(
                                                      begin: Alignment.topLeft,
                                                      end:
                                                          Alignment.bottomRight,
                                                      colors: [
                                                        notificationColor
                                                            .withValues(
                                                              alpha: 0.2,
                                                            ),
                                                        notificationColor
                                                            .withValues(
                                                              alpha: 0.1,
                                                            ),
                                                      ],
                                                    ),
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          12,
                                                        ),
                                                  ),
                                                  child: Icon(
                                                    _getNotificationIcon(type),
                                                    color: notificationColor,
                                                    size: 22,
                                                  ),
                                                ),
                                                const SizedBox(width: 12),
                                                // Content
                                                Expanded(
                                                  child: Column(
                                                    crossAxisAlignment:
                                                        CrossAxisAlignment
                                                            .start,
                                                    children: [
                                                      // Title and time row
                                                      Row(
                                                        crossAxisAlignment:
                                                            CrossAxisAlignment
                                                                .start,
                                                        children: [
                                                          Expanded(
                                                            child: Text(
                                                              title,
                                                              style: AppTextStyles
                                                                  .nunitoBold
                                                                  .copyWith(
                                                                    fontSize:
                                                                        15,
                                                                    color: AppColors.lightTextPrimary,
                                                                    letterSpacing:
                                                                        -0.2,
                                                                  ),
                                                            ),
                                                          ),
                                                          const SizedBox(
                                                            width: 8,
                                                          ),
                                                          Text(
                                                            _formatTimestamp(
                                                              sentAt,
                                                            ),
                                                            style: TextStyle(
                                                              fontSize: 12,
                                                              color: Colors
                                                                  .grey[400],
                                                              fontWeight:
                                                                  FontWeight
                                                                      .w500,
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                      const SizedBox(height: 4),
                                                      // Body text
                                                      Text(
                                                        body,
                                                        style: AppTextStyles
                                                            .nunitoRegular
                                                            .copyWith(
                                                              fontSize: 13,
                                                              color: Colors
                                                                  .grey[600],
                                                              height: 1.3,
                                                            ),
                                                        maxLines: 2,
                                                        overflow: TextOverflow
                                                            .ellipsis,
                                                      ),
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
                              },
                            ),
                          );
                        },
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Handle notification tap - navigate based on notification type and role
  void _handleNotificationTap(Map<String, dynamic> data, String? type) {
    try {
      // Get screen route from notification data
      final screenRaw = data['screen'] as String?;
      final screen = screenRaw?.trim();
      final normalizedScreen =
          (screen != null &&
              screen.isNotEmpty &&
              screen.endsWith('/') &&
              screen.length > 1)
          ? screen.substring(0, screen.length - 1)
          : screen;

      // If no screen specified, stay on notifications page
      if (normalizedScreen == null || normalizedScreen.isEmpty) {
        return;
      }

      // Navigate based on notification type and role/mode
      if (_resolvedIsAdmin) {
        // Admin navigation
        switch (type) {
          case 'newPendingBill':
            // Navigate to admin home with pending bills tab
            context.go('/admin');
            break;
          case 'newUserRegistered':
            // Navigate to admin home with users tab
            context.go('/admin');
            break;
          default:
            // Use screen from data
            if (normalizedScreen == '/admin') {
              context.go('/admin');
            } else if (normalizedScreen == '/notifications' ||
                normalizedScreen == '/notifications/') {
              // Admin notifications route (outside the carpenter ShellRoute)
              context.go('/admin/notifications');
            } else if (normalizedScreen == '/admin/notifications') {
              context.go('/admin/notifications');
            } else {
              // For other screens, navigate to admin home
              context.go('/admin');
            }
        }
      } else {
        // Carpenter navigation
        switch (type) {
          case 'billApproved':
          case 'billRejected':
          case 'pointsWithdrawn':
          case 'billSubmitted':
            // Navigate to home (bills are shown there)
            context.go('/');
            break;
          case 'tierUpgraded':
          case 'pointsMilestone':
            // Navigate to profile
            context.go('/profile');
            break;
          case 'dailySpinWon':
            // Navigate to daily spin
            context.go('/daily-spin');
            break;
          case 'offerRedeemed':
          case 'newOfferAvailable':
            // Navigate to home (offers are shown there)
            context.go('/');
            break;
          default:
            // Use screen from data, fallback to home
            if (normalizedScreen == '/notifications') {
              // Already on notifications page
              return;
            } else if (normalizedScreen == '/profile' ||
                normalizedScreen == '/daily-spin') {
              context.go(normalizedScreen);
            } else {
              // Default to home
              context.go('/');
            }
        }
      }
    } catch (e) {
      debugPrint('Error navigating from notification: $e');
      // On error, stay on notifications page
    }
  }
}
