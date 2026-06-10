import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/logger.dart';

/// Notification types for different events
enum NotificationType {
  billApproved,
  billRejected,
  pointsWithdrawn,
  tierUpgraded,
  dailySpinWon,
  offerRedeemed,
  newOfferAvailable,
  billSubmitted,
  // Admin notification types
  newPendingBill,
  newUserRegistered,
}

/// Notification Service for sending push notifications
///
/// This service handles sending notifications to users via FCM.
/// For production, notifications should be sent via Cloud Functions.
/// This service prepares notification data and can either:
/// 1. Queue notifications in Firestore (for Cloud Functions to process)
/// 2. Send directly via FCM REST API (requires server token)
class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Send a notification to a specific user
  ///
  /// [userId] - User ID (phone number or Firebase Auth UID)
  /// [type] - Type of notification
  /// [title] - Notification title
  /// [body] - Notification body
  /// [data] - Additional data payload for deep linking
  Future<bool> sendNotification({
    required String userId,
    required NotificationType type,
    required String title,
    required String body,
    Map<String, dynamic>? data,
  }) async {
    try {
      AppLogger.debug('🔔 NotificationService.sendNotification() called');
      AppLogger.debug('   Type: $type, UserId: $userId, Title: $title');
      AppLogger.info('📤 Sending notification: $type to user: $userId');

      // Get user's FCM token
      // Try multiple userId formats to find the user document
      DocumentSnapshot? userDoc;
      String? actualUserId;

      // First try: direct userId lookup
      AppLogger.debug('🔔 Looking up user: users/$userId');
      userDoc = await _firestore.collection('users').doc(userId).get();
      if (userDoc.exists) {
        actualUserId = userId;
        AppLogger.debug('✅ Found user with direct userId: $userId');
        AppLogger.info('Found user with direct userId: $userId');
      } else {
        AppLogger.debug('⚠️ User not found with direct userId, trying phone lookup...');
        // Second try: search by phone number if userId is phone number format
        if (userId.length >= 10 && RegExp(r'^\d+$').hasMatch(userId)) {
          // userId might be phone number, try searching by phone field
          final phoneQuery = await _firestore
              .collection('users')
              .where('phone', isEqualTo: userId)
              .limit(1)
              .get();

          if (phoneQuery.docs.isNotEmpty) {
            userDoc = phoneQuery.docs.first;
            actualUserId = userDoc.id;
            AppLogger.info(
              'Found user by phone number: $userId -> document ID: $actualUserId',
            );
          }
        }

        // Third try: search by carpenterId field
        if (!userDoc.exists) {
          final carpenterQuery = await _firestore
              .collection('users')
              .where('carpenterId', isEqualTo: userId)
              .limit(1)
              .get();

          if (carpenterQuery.docs.isNotEmpty) {
            userDoc = carpenterQuery.docs.first;
            actualUserId = userDoc.id;
            AppLogger.info(
              'Found user by carpenterId: $userId -> document ID: $actualUserId',
            );
          }
        }
      }

      if (!userDoc.exists) {
        AppLogger.debug('❌ User not found after all attempts: $userId');
        AppLogger.error(
          'User not found: $userId (tried direct lookup, phone, and carpenterId)',
        );
        return false;
      }

      final userData = userDoc.data() as Map<String, dynamic>?;
      AppLogger.debug('📄 User document keys: ${userData?.keys.toList()}');
      final fcmToken = userData?['fcmToken'] as String?;

      if (fcmToken == null || fcmToken.isEmpty) {
        AppLogger.debug('❌ NO FCM TOKEN for user: $userId');
        AppLogger.debug('   Has fcmToken field: ${userData?.containsKey('fcmToken')}');
        AppLogger.debug('   All user data keys: ${userData?.keys.toList()}');
        AppLogger.error(
          'No FCM token found for user: $userId (document ID: ${actualUserId ?? userDoc.id})',
        );
        AppLogger.info('User data keys: ${userData?.keys.toList()}');
        AppLogger.info(
          'User has fcmToken field: ${userData?.containsKey('fcmToken')}',
        );
        return false;
      }

      AppLogger.debug('✅ FCM token found: ${fcmToken.substring(0, 20)}...');

      AppLogger.info(
        'FCM token found for user: $userId (document ID: ${actualUserId ?? userDoc.id})',
      );

      // Check notification preferences (if enabled)
      final notificationPrefs =
          userData?['notificationPreferences'] as Map<String, dynamic>?;
      if (notificationPrefs != null) {
        final enabled = notificationPrefs['enabled'] as bool? ?? true;
        if (!enabled) {
          AppLogger.info('Notifications disabled for user: $userId');
          return false;
        }

        // Check specific notification type preference
        final typeKey = _getNotificationTypeKey(type);
        final typeEnabled = notificationPrefs[typeKey] as bool? ?? true;
        if (!typeEnabled) {
          AppLogger.info(
            'Notification type $typeKey disabled for user: $userId',
          );
          return false;
        }
      }

      // Prepare notification data
      final notificationData = {
        'type': type.name,
        'notificationId': _generateNotificationId(),
        'timestamp': FieldValue.serverTimestamp(),
        ...?data,
      };

      // Use actualUserId if we found it, otherwise use original userId
      final finalUserId = actualUserId ?? userId;

      // Queue notification in Firestore for Cloud Functions to process
      // This is the recommended approach for production
      AppLogger.debug('🔔 Queueing notification in notification_queue...');
      await _queueNotificationInFirestore(
        userId: finalUserId,
        fcmToken: fcmToken,
        type: type,
        title: title,
        body: body,
        data: notificationData,
      );
      AppLogger.debug('✅ Notification queued in notification_queue collection');

      // Log analytics
      await _logNotificationAnalytics(
        type: type.name,
        title: title,
        body: body,
        sentCount: 1,
        skippedCount: 0,
        isBroadcast: false,
      );

      AppLogger.info('✅ Notification queued successfully: $type');
      AppLogger.debug('✅ NotificationService.sendNotification() SUCCESS');
      return true;
    } catch (e, stackTrace) {
      AppLogger.debug('❌ EXCEPTION in NotificationService.sendNotification()');
      AppLogger.debug('   Error: $e');
      AppLogger.debug('   StackTrace: $stackTrace');
      AppLogger.error('Error sending notification', e);
      return false;
    }
  }

  /// Queue notification in Firestore for Cloud Functions to process
  Future<void> _queueNotificationInFirestore({
    required String userId,
    required String fcmToken,
    required NotificationType type,
    required String title,
    required String body,
    required Map<String, dynamic> data,
  }) async {
    try {
      await _firestore.collection('notification_queue').add({
        'userId': userId,
        'fcmToken': fcmToken,
        'type': type.name,
        'title': title,
        'body': body,
        'data': data,
        'status': 'pending',
        'createdAt': FieldValue.serverTimestamp(),
        'priority': _getNotificationPriority(type),
      });

      AppLogger.info('Notification queued in Firestore');
    } catch (e) {
      AppLogger.error('Error queueing notification in Firestore', e);
      rethrow;
    }
  }

  /// Get notification type key for preferences
  String _getNotificationTypeKey(NotificationType type) {
    switch (type) {
      case NotificationType.billApproved:
        return 'billApproved';
      case NotificationType.billRejected:
        return 'billRejected';
      case NotificationType.pointsWithdrawn:
        return 'pointsWithdrawn';
      case NotificationType.tierUpgraded:
        return 'tierUpgraded';
      case NotificationType.dailySpinWon:
        return 'dailySpin';
      case NotificationType.offerRedeemed:
        return 'newOffers';
      case NotificationType.newOfferAvailable:
        return 'newOffers';
      case NotificationType.billSubmitted:
        return 'billApproved'; // Use same preference as bill approval
      case NotificationType.newPendingBill:
        return 'adminNotifications'; // Admin notification preference
      case NotificationType.newUserRegistered:
        return 'adminNotifications'; // Admin notification preference
    }
  }

  /// Get notification priority based on type
  String _getNotificationPriority(NotificationType type) {
    switch (type) {
      case NotificationType.billApproved:
      case NotificationType.tierUpgraded:
      case NotificationType.pointsWithdrawn:
      case NotificationType.newPendingBill:
      case NotificationType.newUserRegistered:
        return 'high';
      case NotificationType.billRejected:
      case NotificationType.dailySpinWon:
      case NotificationType.offerRedeemed:
      case NotificationType.newOfferAvailable:
      case NotificationType.billSubmitted:
        return 'normal';
    }
  }

  /// Generate unique notification ID
  String _generateNotificationId() {
    return DateTime.now().millisecondsSinceEpoch.toString();
  }

  /// Send bill approved notification
  Future<bool> sendBillApprovedNotification({
    required String userId,
    required double amount,
    required double points,
    required String billId,
  }) async {
    return await sendNotification(
      userId: userId,
      type: NotificationType.billApproved,
      title: '🎉 Bill Approved!',
      body:
          'You earned ${points.toStringAsFixed(2)} points!',
      data: {
        'billId': billId,
        'amount': amount.toString(),
        'points': points.toString(),
        'screen': '/notifications', // Navigate to notifications screen
      },
    );
  }

  /// Send bill rejected notification
  Future<bool> sendBillRejectedNotification({
    required String userId,
    required double amount,
    required String billId,
  }) async {
    return await sendNotification(
      userId: userId,
      type: NotificationType.billRejected,
      title: 'Bill Rejected',
      body:
          'Your bill of ₹${amount.toStringAsFixed(0)} has been rejected. Please check and resubmit.',
      data: {
        'billId': billId,
        'amount': amount,
        'screen': '/notifications', // Navigate to notifications screen
      },
    );
  }

  /// Send points withdrawn notification
  Future<bool> sendPointsWithdrawnNotification({
    required String userId,
    required int points,
    required double amount,
    required String billId,
  }) async {
    return await sendNotification(
      userId: userId,
      type: NotificationType.pointsWithdrawn,
      title: 'Points Withdrawn',
      body:
          '$points points have been withdrawn from your account for bill ₹${amount.toStringAsFixed(0)}.',
      data: {
        'billId': billId,
        'points': points,
        'amount': amount,
        'screen': '/notifications', // Navigate to notifications screen
      },
    );
  }

  /// Send tier upgraded notification
  Future<bool> sendTierUpgradedNotification({
    required String userId,
    required String newTier,
    required double points,
  }) async {
    return await sendNotification(
      userId: userId,
      type: NotificationType.tierUpgraded,
      title: '🎊 Tier Upgraded!',
      body:
          'Congratulations! You\'ve been upgraded to $newTier tier with ${points.toStringAsFixed(2)} points!',
      data: {
        'tier': newTier,
        'points': points.toString(),
        'screen': '/notifications', // Navigate to notifications screen
      },
    );
  }

  /// Send daily spin won notification
  Future<bool> sendDailySpinWonNotification({
    required String userId,
    required int points,
  }) async {
    return await sendNotification(
      userId: userId,
      type: NotificationType.dailySpinWon,
      title: '🎰 Spin Result',
      body: 'You won $points points from today\'s spin!',
      data: {
        'points': points,
        'screen': '/notifications', // Navigate to notifications screen
      },
    );
  }

  /// Broadcast daily spin winner announcement to all carpenters
  Future<int> broadcastDailySpinWinner({
    required String winnerName,
    required int pointsWon,
  }) async {
    try {
      AppLogger.info('📢 Broadcasting daily spin winner: $winnerName');

      // Get all users (carpenters only, exclude admins)
      final usersQuery = await _firestore.collection('users').get();

      // Filter to exclude admins and users without FCM tokens
      final validUsers = usersQuery.docs.where((doc) {
        final userData = doc.data();
        final role = userData['role'] as String?;
        final fcmToken = userData['fcmToken'] as String?;
        // Include carpenters and users without role (assumed to be carpenters)
        return role != 'admin' && fcmToken != null && fcmToken.isNotEmpty;
      }).toList();

      int successCount = 0;
      int skippedCount = 0;

      // Send notification to each carpenter
      for (final userDoc in validUsers) {
        final userId = userDoc.id;
        final userData = userDoc.data();
        final fcmToken = userData['fcmToken'] as String?;

        // Check notification preferences
        final notificationPrefs =
            userData['notificationPreferences'] as Map<String, dynamic>?;
        if (notificationPrefs != null) {
          final enabled = notificationPrefs['enabled'] as bool? ?? true;
          if (!enabled) {
            skippedCount++;
            continue;
          }

          final dailySpinEnabled =
              notificationPrefs['dailySpin'] as bool? ?? true;
          if (!dailySpinEnabled) {
            skippedCount++;
            continue;
          }
        }

        // Queue notification for this carpenter
        try {
          await _queueNotificationInFirestore(
            userId: userId,
            fcmToken: fcmToken!,
            type: NotificationType.dailySpinWon,
            title: '🎰 Today\'s Spin Winner!',
            body: '$winnerName won $pointsWon points in today\'s spin!',
            data: {
              'type': NotificationType.dailySpinWon.name,
              'notificationId': _generateNotificationId(),
              'timestamp': FieldValue.serverTimestamp(),
              'winnerName': winnerName,
              'pointsWon': pointsWon,
              'screen': '/daily-spin',
            },
          );
          successCount++;
        } catch (e) {
          AppLogger.warning(
            'Failed to queue spin winner notification for user $userId: $e',
          );
          skippedCount++;
        }
      }

      AppLogger.info(
        '📢 Spin winner broadcast complete: $successCount sent, $skippedCount skipped',
      );

      // Log broadcast analytics
      await _logNotificationAnalytics(
        type: NotificationType.dailySpinWon.name,
        title: '🎰 Today\'s Spin Winner!',
        body: '$winnerName won $pointsWon points!',
        sentCount: successCount,
        skippedCount: skippedCount,
        isBroadcast: true,
      );

      return successCount;
    } catch (e) {
      AppLogger.error('Error broadcasting daily spin winner', e);
      return 0;
    }
  }

  /// Send offer redeemed notification
  Future<bool> sendOfferRedeemedNotification({
    required String userId,
    required String offerTitle,
    required int points,
  }) async {
    return await sendNotification(
      userId: userId,
      type: NotificationType.offerRedeemed,
      title: 'Offer Redeemed',
      body:
          'You\'ve successfully redeemed $offerTitle. $points points deducted.',
      data: {
        'offerTitle': offerTitle,
        'points': points,
        'screen': '/notifications', // Navigate to notifications screen
      },
    );
  }

  /// Send new offer available notification
  Future<bool> sendNewOfferNotification({
    required String userId,
    required String offerTitle,
    required int points,
  }) async {
    return await sendNotification(
      userId: userId,
      type: NotificationType.newOfferAvailable,
      title: '🎁 New Offer Available!',
      body: '$offerTitle - Redeem for $points points',
      data: {
        'offerTitle': offerTitle,
        'points': points,
        'screen': '/notifications', // Navigate to notifications screen
      },
    );
  }

  /// Send broadcast notification to all users (for new offers)
  /// This will queue notifications for all users with FCM tokens
  Future<int> sendBroadcastNewOfferNotification({
    required String offerTitle,
    required int points,
  }) async {
    try {
      AppLogger.info('📢 Broadcasting new offer notification: $offerTitle');

      // Get all users (carpenters only, exclude admins)
      // Note: Firestore doesn't support isNotEqualTo directly
      // We'll fetch all users and filter in code, or use a different approach
      // For better performance with many users, consider using Cloud Functions
      final usersQuery = await _firestore.collection('users').get();

      // Filter to exclude admins and users without FCM tokens
      final validUsers = usersQuery.docs.where((doc) {
        final userData = doc.data();
        final role = userData['role'] as String?;
        final fcmToken = userData['fcmToken'] as String?;
        // Include carpenters and users without role (assumed to be carpenters)
        return role != 'admin' && fcmToken != null && fcmToken.isNotEmpty;
      }).toList();

      int successCount = 0;
      int skippedCount = 0;

      // Send notification to each user
      for (final userDoc in validUsers) {
        final userId = userDoc.id;
        final userData = userDoc.data();
        final fcmToken = userData['fcmToken'] as String?;

        // Check notification preferences
        final notificationPrefs =
            userData['notificationPreferences'] as Map<String, dynamic>?;
        if (notificationPrefs != null) {
          final enabled = notificationPrefs['enabled'] as bool? ?? true;
          if (!enabled) {
            skippedCount++;
            continue;
          }

          final newOffersEnabled =
              notificationPrefs['newOffers'] as bool? ?? true;
          if (!newOffersEnabled) {
            skippedCount++;
            continue;
          }
        }

        // Queue notification for this user
        // fcmToken is guaranteed to be non-null due to filter above
        try {
          await _queueNotificationInFirestore(
            userId: userId,
            fcmToken: fcmToken!,
            type: NotificationType.newOfferAvailable,
            title: '🎁 New Offer Available!',
            body: '$offerTitle - Redeem for $points points',
            data: {
              'type': NotificationType.newOfferAvailable.name,
              'notificationId': _generateNotificationId(),
              'timestamp': FieldValue.serverTimestamp(),
              'offerTitle': offerTitle,
              'points': points,
              'screen': '/notifications',
            },
          );
          successCount++;
        } catch (e) {
          AppLogger.warning(
            'Failed to queue notification for user $userId: $e',
          );
          skippedCount++;
        }
      }

      AppLogger.info(
        '📢 Broadcast complete: $successCount sent, $skippedCount skipped',
      );

      // Log broadcast analytics
      await _logNotificationAnalytics(
        type: NotificationType.newOfferAvailable.name,
        title: '🎁 New Offer Available!',
        body: '$offerTitle - Redeem for $points points',
        sentCount: successCount,
        skippedCount: skippedCount,
        isBroadcast: true,
      );

      return successCount;
    } catch (e) {
      AppLogger.error('Error broadcasting new offer notification', e);
      return 0;
    }
  }

  /// Send points milestone notification
  Future<bool> sendPointsMilestoneNotification({
    required String userId,
    required double points,
    required int milestone,
  }) async {
    return await sendNotification(
      userId: userId,
      type: NotificationType.billApproved, // Reuse existing type
      title: '🎯 Milestone Reached!',
      body: 'Congratulations! You\'ve reached $milestone points!',
      data: {
        'points': points.toString(),
        'milestone': milestone.toString(),
        'screen': '/notifications', // Navigate to notifications screen
      },
    );
  }

  /// Log notification analytics
  Future<void> _logNotificationAnalytics({
    required String type,
    required String title,
    required String body,
    int sentCount = 1,
    int skippedCount = 0,
    bool isBroadcast = false,
  }) async {
    try {
      await _firestore.collection('notification_logs').add({
        'type': type,
        'title': title,
        'body': body,
        'sentCount': sentCount,
        'skippedCount': skippedCount,
        'isBroadcast': isBroadcast,
        'sentAt': FieldValue.serverTimestamp(),
        'status': 'queued',
      });

      AppLogger.info('Notification analytics logged: $type');
    } catch (e) {
      AppLogger.warning('Failed to log notification analytics: $e');
      // Don't throw - analytics logging is not critical
    }
  }

  /// Send bill submitted notification
  Future<bool> sendBillSubmittedNotification({
    required String userId,
    required double amount,
  }) async {
    return await sendNotification(
      userId: userId,
      type: NotificationType.billSubmitted,
      title: 'Bill Submitted',
      body:
          'Your bill of ₹${amount.toStringAsFixed(0)} has been submitted and is pending approval.',
      data: {
        'amount': amount,
        'screen': '/notifications', // Navigate to notifications screen
      },
    );
  }

  // ============================================
  // ADMIN NOTIFICATION METHODS
  // ============================================

  /// One row in [notification_logs] so admin panel / dashboard streams show the event.
  /// Push delivery still uses [notification_queue] per admin; this is the in-app inbox.
  Future<void> _logAdminBroadcastToNotificationLogs({
    required NotificationType type,
    required String title,
    required String body,
    required int adminsQueuedCount,
    Map<String, dynamic>? data,
  }) async {
    try {
      final logData = <String, dynamic>{
        'type': type.name,
        'title': title,
        'body': body,
        'sentAt': FieldValue.serverTimestamp(),
        'status': 'admin_broadcast',
        'isBroadcast': true,
        'adminsQueued': adminsQueuedCount,
      };
      if (data != null) {
        for (final e in data.entries) {
          if (e.value is FieldValue) continue;
          logData[e.key] = e.value;
        }
      }
      await _firestore.collection('notification_logs').add(logData);
      AppLogger.info('Admin broadcast logged to notification_logs: ${type.name}');
    } catch (e) {
      AppLogger.warning('Failed to log admin broadcast to notification_logs: $e');
    }
  }

  /// Send notification to all admin users
  Future<int> _sendNotificationToAllAdmins({
    required NotificationType type,
    required String title,
    required String body,
    Map<String, dynamic>? data,
  }) async {
    try {
      AppLogger.info('📢 Sending notification to all admins: $title');

      // Get all admin users with FCM tokens
      final usersQuery = await _firestore.collection('users').get();

      // Filter to only include admins with FCM tokens
      final adminUsers = usersQuery.docs.where((doc) {
        final userData = doc.data();
        final role = userData['role'] as String?;
        final fcmToken = userData['fcmToken'] as String?;
        return role == 'admin' && fcmToken != null && fcmToken.isNotEmpty;
      }).toList();

      if (adminUsers.isEmpty) {
        AppLogger.warning('No admin users found with FCM tokens');
        // Still record the event so admin UI shows latest activity (push may be unavailable).
        await _logAdminBroadcastToNotificationLogs(
          type: type,
          title: title,
          body: body,
          adminsQueuedCount: 0,
          data: data,
        );
        return 0;
      }

      int successCount = 0;
      int skippedCount = 0;

      // Send notification to each admin
      for (final adminDoc in adminUsers) {
        final adminId = adminDoc.id;
        final adminData = adminDoc.data();
        final fcmToken = adminData['fcmToken'] as String?;

        // Check notification preferences
        final notificationPrefs =
            adminData['notificationPreferences'] as Map<String, dynamic>?;
        if (notificationPrefs != null) {
          final enabled = notificationPrefs['enabled'] as bool? ?? true;
          if (!enabled) {
            skippedCount++;
            continue;
          }
        }

        // Queue notification for this admin
        try {
          await _queueNotificationInFirestore(
            userId: adminId,
            fcmToken: fcmToken!,
            type: type,
            title: title,
            body: body,
            data: {
              'type': type.name,
              'notificationId': _generateNotificationId(),
              'timestamp': FieldValue.serverTimestamp(),
              ...?data,
            },
          );
          successCount++;
        } catch (e) {
          AppLogger.warning(
            'Failed to queue admin notification for $adminId: $e',
          );
          skippedCount++;
        }
      }

      AppLogger.info(
        '📢 Admin notification complete: $successCount sent, $skippedCount skipped',
      );

      await _logAdminBroadcastToNotificationLogs(
        type: type,
        title: title,
        body: body,
        adminsQueuedCount: successCount,
        data: data,
      );

      return successCount;
    } catch (e) {
      AppLogger.error('Error sending notification to admins', e);
      return 0;
    }
  }

  /// Notify all admins about a new pending bill
  Future<int> notifyAdminsNewPendingBill({
    required String carpenterName,
    required String carpenterPhone,
    required double amount,
    required String billId,
  }) async {
    return await _sendNotificationToAllAdmins(
      type: NotificationType.newPendingBill,
      title: '📋 New Bill Pending',
      body: '$carpenterName submitted a bill of ₹${amount.toStringAsFixed(0)}',
      data: {
        'billId': billId,
        'carpenterPhone': carpenterPhone,
        'amount': amount,
        'screen': '/notifications', // Navigate to notifications screen
      },
    );
  }

  /// Notify all admins about a new user registration
  Future<int> notifyAdminsNewUserRegistered({
    required String userName,
    required String userPhone,
    required String userId,
  }) async {
    return await _sendNotificationToAllAdmins(
      type: NotificationType.newUserRegistered,
      title: '👤 New Carpenter Registered',
      body: '$userName ($userPhone) just registered',
      data: {
        'userId': userId,
        'userPhone': userPhone,
        'screen': '/notifications', // Navigate to notifications screen
      },
    );
  }
}
