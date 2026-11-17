import 'package:balaji_points/services/notifications/notification_visibility.dart';
import 'package:balaji_points/presentation/widgets/shared/app_loader.dart';
import 'package:balaji_points/core/design/app_radius.dart';
import 'package:balaji_points/core/design/app_colors.dart';
import 'package:balaji_points/core/design/app_typography.dart';
// lib/presentation/screens/notifications/notifications_page.dart
// Notifications screen for carpenters to view and manage their notifications

import 'package:balaji_points/presentation/widgets/carpenter/home_nav_bar.dart';
import 'package:flutter/material.dart';
import 'package:balaji_points/l10n/app_localizations.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:go_router/go_router.dart';
import 'package:balaji_points/services/auth/session_service.dart';
import 'dart:async';

import 'package:balaji_points/core/notifications/notification_category.dart';
import 'package:balaji_points/presentation/screens/carpenter/notifications/widgets/notification_tile.dart';

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
  String? _myPhone;
  String? _myBranchId;
  bool _isLoading = true;

  /// Category chip picked above the list; null shows everything.
  NotificationCategory? _filter;

  /// The list last shown, so returning to this screen needs no loader. Keyed by
  /// user, and only used once the session confirms who is logged in.
  static String? _savedKey;
  static List<QueryDocumentSnapshot>? _savedList;

  String get _listKey => '$_userId|$_resolvedIsAdmin';

  List<QueryDocumentSnapshot>? get _knownList =>
      _savedKey == _listKey ? _savedList : null;

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
    final myPhone = await _sessionService.getPhoneNumber();
    final myBranchId = await _sessionService.getBranchId();
    if (!mounted) return;
    setState(() {
      _userId = userId;
      _userRole = userRole;
      _myPhone = myPhone;
      _myBranchId = myBranchId;
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

      // Only this member's own notifications, plus announcements for their
      // branch or for every branch. Never another branch's, never admin alerts.
      final myIds = {userId, if (_myPhone != null) _myPhone!};
      result = result.where((doc) {
        return NotificationVisibility.memberCanSee(
          doc.data() as Map<String, dynamic>?,
          myIds: myIds,
          myBranchId: _myBranchId,
          myRole: _userRole,
        );
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
        // Only the same bill's notice twice in an hour is a duplicate;
        // other notifications are each kept (announcements share a type).
        final uniqueKey = billId == null
            ? doc.id
            : '$type-$billId-$hourKey';

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
        .limit(60); // Other branches' are filtered out below

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
            content: Text(AppLocalizations.of(context)!.notificationDeleted),
            backgroundColor: context.themePrimary,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      debugPrint('Error deleting notification: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)!.errorWithDetails('$e')),
            backgroundColor: context.themeError,
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
        shape: RoundedRectangleBorder(borderRadius: AppRadius.all16),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: context.themeError.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.delete_outline_rounded,
                color: context.themeError,
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                AppLocalizations.of(context)!.deleteAllNotifications,
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        content: Text(
          AppLocalizations.of(context)!.deleteAllNotificationsConfirm,
          style: TextStyle(fontSize: 16),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(
              AppLocalizations.of(context)!.cancel,
              style: TextStyle(color: context.themeTextSecondary, fontSize: 16),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: context.themeError,
              foregroundColor: AppColors.white,
              shape: RoundedRectangleBorder(borderRadius: AppRadius.md12),
            ),
            child: Text(
              AppLocalizations.of(context)!.deleteAll,
              style: TextStyle(fontSize: 16),
            ),
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
          builder: (context) => const Center(child: AppLoader()),
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
            content: Text(
              AppLocalizations.of(
                context,
              )!.notificationsDeleted('${snapshot.length}'),
            ),
            backgroundColor: context.themePrimary,
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
            content: Text(AppLocalizations.of(context)!.errorWithDetails('$e')),
            backgroundColor: context.themeError,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  String _formatTimestamp(Timestamp? timestamp) {
    if (timestamp == null) return AppLocalizations.of(context)!.justNow;

    final date = timestamp.toDate();
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      if (difference.inHours == 0) {
        if (difference.inMinutes == 0) {
          return AppLocalizations.of(context)!.justNow;
        }
        return AppLocalizations.of(context)!.mAgo('${difference.inMinutes}');
      }
      return AppLocalizations.of(context)!.hAgo('${difference.inHours}');
    } else if (difference.inDays == 1) {
      return AppLocalizations.of(context)!.yesterday;
    } else if (difference.inDays < 7) {
      return AppLocalizations.of(context)!.dAgo('${difference.inDays}');
    } else {
      return DateFormat('MMM dd, yyyy').format(date);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // Reading the session takes a moment: show the screen's header, not a loader.
    if (_isLoading) {
      return Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        body: Column(
          children: [
            HomeNavBar(
              title: AppLocalizations.of(context)!.notifications,
              showLogo: false,
              showProfileButton: false,
              showBackButton: widget.mode == NotificationsPageMode.admin,
            ),
          ],
        ),
      );
    }

    final bool isAdmin = _resolvedIsAdmin;

    if (_userId == null) {
      return Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        body: Column(
          children: [
            HomeNavBar(
              title: AppLocalizations.of(context)!.notifications,
              showLogo: false,
              showProfileButton: false,
            ),
            Expanded(
              child: Center(
                child: Text(
                  AppLocalizations.of(context)!.unableToLoadNotifications,
                ),
              ),
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
                title: AppLocalizations.of(context)!.notifications,
                showLogo: false,
                showProfileButton: false,
                showBackButton: isAdmin,
                // Notifications route lives inside the carpenter ShellRoute.
                // For admins, we must override back to return to Admin dashboard.
                onBackTap: isAdmin ? () => context.go('/admin') : null,
                actions: [
                  StreamBuilder<List<QueryDocumentSnapshot>>(
                    stream: _mergedNotificationsStream,
                    initialData: _knownList,
                    builder: (context, snapshot) {
                      final hasNotifications =
                          snapshot.hasData && snapshot.data!.isNotEmpty;
                      if (!hasNotifications) {
                        return const SizedBox.shrink();
                      }
                      return IconButton(
                        icon: const Icon(
                          Icons.delete_outline_rounded,
                          size: 22,
                        ),
                        onPressed: _deleteAllNotifications,
                        tooltip: AppLocalizations.of(context)!.deleteAll,
                      );
                    },
                  ),
                ],
              ),
            ],
          ),
          Expanded(
            child: Container(
              color: context.themeBackground,
              child: SafeArea(
                top: false,
                child: _mergedNotificationsStream == null
                    ? const Center(child: AppLoader())
                    : StreamBuilder<List<QueryDocumentSnapshot>>(
                        stream: _mergedNotificationsStream,
                        initialData: _knownList,
                        builder: (context, snapshot) {
                          if (snapshot.hasData) {
                            _savedKey = _listKey;
                            _savedList = snapshot.data;
                          } else if (snapshot.connectionState ==
                              ConnectionState.waiting) {
                            return const Center(child: AppLoader());
                          }

                          if (snapshot.hasError) {
                            return Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.error_outline_rounded,
                                    size: 64,
                                    color: AppColors.error,
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    AppLocalizations.of(
                                      context,
                                    )!.errorLoadingNotifications,
                                    style: TextStyle(
                                      color: context.themeTextSecondary,
                                      fontSize: 16,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  TextButton(
                                    onPressed: () => setState(() {}),
                                    child: Text(
                                      AppLocalizations.of(context)!.retry,
                                    ),
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
                                      color: context.themePrimary.withValues(
                                        alpha: 0.1,
                                      ),
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(
                                      Icons.notifications_none_rounded,
                                      size: 64,
                                      color: context.themePrimary.withValues(
                                        alpha: 0.5,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 24),
                                  Text(
                                    AppLocalizations.of(
                                      context,
                                    )!.noNotificationsTitle,
                                    style: AppTypography.buttonMedium()
                                        .copyWith(
                                          fontSize: 24,
                                          color: context.themeTextPrimary,
                                        ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    AppLocalizations.of(
                                      context,
                                    )!.noNotificationsYet,
                                    style: AppTypography.bodyMedium().copyWith(
                                      fontSize: 16,
                                      color: context.themeTextSecondary,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }

                          return _buildList(snapshot.data!);
                        },
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Category chips, then the cards grouped under Today / Yesterday /
  /// Earlier. Swipe left deletes one.
  Widget _buildList(List<QueryDocumentSnapshot> all) {
    final l10n = AppLocalizations.of(context)!;
    final present = <NotificationCategory>{
      for (final d in all)
        NotificationCategory.of(d.data() as Map<String, dynamic>?),
    };
    final filter = present.contains(_filter) ? _filter : null;
    final shown = filter == null
        ? all
        : all
              .where(
                (d) =>
                    NotificationCategory.of(
                      d.data() as Map<String, dynamic>?,
                    ) ==
                    filter,
              )
              .toList();

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    String section(Timestamp? t) {
      if (t == null) return l10n.today;
      final d = t.toDate();
      final day = DateTime(d.year, d.month, d.day);
      if (day == today) return l10n.today;
      if (today.difference(day).inDays == 1) return l10n.yesterday;
      return l10n.notifEarlier;
    }

    final rows = <Widget>[];
    String? lastSection;
    for (final doc in shown) {
      final data = doc.data() as Map<String, dynamic>;
      final sentAt = data['sentAt'] as Timestamp?;
      final heading = section(sentAt);
      if (heading != lastSection) {
        lastSection = heading;
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
      rows.add(_dismissibleTile(doc, data));
    }

    final chips = <NotificationCategory?>[
      null,
      ...NotificationCategory.values.where(present.contains),
    ];

    return Column(
      children: [
        if (present.length > 1)
          SizedBox(
            height: 52,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 6),
              itemCount: chips.length,
              separatorBuilder: (_, _) => const SizedBox(width: 8),
              itemBuilder: (context, i) {
                final c = chips[i];
                final selected = c == filter;
                return ChoiceChip(
                  label: Text(c == null ? l10n.all : c.label(l10n)),
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
                    color: selected
                        ? context.themePrimary
                        : context.themeBorder,
                  ),
                  labelStyle: AppTypography.label(
                    color: selected
                        ? context.themeOnPrimary
                        : context.themeTextPrimary,
                  ),
                  onSelected: (_) => setState(() => _filter = c),
                );
              },
            ),
          ),
        Expanded(
          child: RefreshIndicator(
            onRefresh: () => Future.delayed(const Duration(milliseconds: 500)),
            color: context.themePrimary,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 120),
              children: rows,
            ),
          ),
        ),
      ],
    );
  }

  Widget _dismissibleTile(
    QueryDocumentSnapshot doc,
    Map<String, dynamic> data,
  ) {
    final l10n = AppLocalizations.of(context)!;
    final type = data['type'] as String?;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Dismissible(
        key: Key(doc.id),
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
        onDismissed: (_) => _deleteNotification(doc.id),
        confirmDismiss: (_) async =>
            await showDialog<bool>(
              context: context,
              builder: (context) => AlertDialog(
                shape: RoundedRectangleBorder(borderRadius: AppRadius.all16),
                title: Text(l10n.deleteNotification),
                content: Text(l10n.deleteNotificationConfirm),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(false),
                    child: Text(
                      l10n.cancel,
                      style: TextStyle(color: context.themeTextSecondary),
                    ),
                  ),
                  ElevatedButton(
                    onPressed: () => Navigator.of(context).pop(true),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: context.themeError,
                      foregroundColor: AppColors.white,
                    ),
                    child: Text(l10n.delete),
                  ),
                ],
              ),
            ) ??
            false,
        child: NotificationTile(
          category: NotificationCategory.of(data),
          type: type,
          title: data['title'] as String? ?? l10n.notification,
          body: data['body'] as String? ?? '',
          time: _formatTimestamp(data['sentAt'] as Timestamp?),
          onTap: () => _handleNotificationTap(data, type),
        ),
      ),
    );
  }

  /// A tap opens the screen of the notification's category. Admin alerts
  /// open the admin dashboard.
  void _handleNotificationTap(Map<String, dynamic> data, String? type) {
    try {
      if (_resolvedIsAdmin) {
        context.go('/admin');
        return;
      }
      final route = NotificationCategory.of(data).route;
      if (route == null) return;
      final category = NotificationCategory.of(data);
      if (category.isTab) {
        context.go(route);
      } else {
        context.push(route);
      }
    } catch (e) {
      debugPrint('Error navigating from notification: $e');
    }
  }
}
