import 'dart:io' show Platform;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:go_router/go_router.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../config/routes.dart';
import '../../core/logger.dart';
import 'local_notification_service.dart';
import '../auth/session_service.dart';
import '../user/user_migration_service.dart';

/// Firebase Cloud Messaging Service for device token management
class FCMService {
  static final FCMService _instance = FCMService._internal();
  factory FCMService() => _instance;
  FCMService._internal();

  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final SessionService _sessionService = SessionService();
  final UserMigrationService _userMigrationService = UserMigrationService();
  final LocalNotificationService _localNotificationService =
      LocalNotificationService();

  String? _token;
  String? get token => _token;

  /// Initialize FCM and permissions.
  /// Token fetch and Firestore save run in background so app shows faster.
  Future<void> initialize() async {
    try {
      await _localNotificationService.initialize();

      // 🔔 Permissions
      if (Platform.isAndroid) {
        final status = await Permission.notification.request();
        AppLogger.info('Android notification permission: $status');
      } else {
        await _messaging.requestPermission(
          alert: true,
          badge: true,
          sound: true,
        );
      }

      await _messaging.setForegroundNotificationPresentationOptions(
        alert: true,
        badge: true,
        sound: true,
      );

      _messaging.onTokenRefresh.listen((newToken) async {
        _token = newToken;
        AppLogger.info('🔄 FCM token refreshed');
        await _saveTokenToFirestore(newToken);
      });

      _setupMessageHandlers();

      // Defer token fetch and Firestore save so first frame shows faster
      _getToken();
    } catch (e) {
      AppLogger.error('Error initializing FCM', e);
    }
  }

  Future<void> _getToken() async {
    try {
      _token = await _messaging.getToken();
      if (_token != null) {
        AppLogger.info('📲 FCM token: ${_token!.substring(0, 20)}...');
        await _saveTokenToFirestore(_token!);
      }
    } catch (e) {
      AppLogger.error('Error getting FCM token', e);
    }
  }

  /// Save FCM token to the canonical user document (UID-first after migration).
  Future<void> _saveTokenToFirestore(String token) async {
    try {
      final authUser = _auth.currentUser;
      final phone = await _sessionService.getPhoneNumber();

      if (authUser != null && phone != null && phone.isNotEmpty) {
        await saveTokenForUser(token, uid: authUser.uid, phone: phone);
        return;
      }

      // Fallback: session-only (pre-migration / logged-in without Auth)
      final sessionUserId = await _sessionService.getUserId();
      if (sessionUserId != null && sessionUserId.isNotEmpty) {
        await _firestore.collection('users').doc(sessionUserId).set({
          'fcmToken': token,
          'lastTokenUpdate': FieldValue.serverTimestamp(),
          'platform': defaultTargetPlatform.name,
        }, SetOptions(merge: true));
        AppLogger.info(
          '✅ FCM token saved to users/$sessionUserId (session fallback)',
        );
      }
    } catch (e) {
      AppLogger.error('Error saving FCM token', e);
    }
  }

  /// Writes token to the canonical UID document only.
  /// This avoids writing FCM tokens to legacy phone-keyed docs.
  Future<void> saveTokenForUser(
    String token, {
    required String uid,
    required String phone,
  }) async {
    try {
      final normalizedPhone = phone.isNotEmpty
          ? _userMigrationService.normalizePhone(phone)
          : null;
      final userRef = _firestore.collection('users').doc(uid);

      final data = <String, dynamic>{
        'uid': uid,
        'fcmToken': token,
        'lastTokenUpdate': FieldValue.serverTimestamp(),
        'platform': defaultTargetPlatform.name,
      };

      if (normalizedPhone != null) {
        data['phone'] = normalizedPhone;
      }

      await userRef.set(data, SetOptions(merge: true));
      AppLogger.info('✅ FCM token saved to users/$uid');
    } catch (e) {
      AppLogger.error('Error saving FCM token for user', e);
    }
  }

  /// Call after PIN login once migration has run.
  Future<void> refreshTokenAfterLogin({
    required String uid,
    required String phone,
  }) async {
    try {
      final token = await _messaging.getToken();
      if (token == null) return;
      _token = token;
      await saveTokenForUser(token, uid: uid, phone: phone);
    } catch (e) {
      AppLogger.error('Error refreshing FCM token after login', e);
    }
  }

  // ===============================
  // MESSAGE HANDLERS
  // ===============================

  void _setupMessageHandlers() {
    FirebaseMessaging.onMessage.listen((RemoteMessage message) async {
      AppLogger.info(
        '📩 Foreground notification: ${message.notification?.title}',
      );

      if (message.notification != null) {
        String channelId = 'balaji_points_default';
        final type = message.data['type'];

        if (type == 'billApproved' ||
            type == 'tierUpgraded' ||
            type == 'pointsWithdrawn') {
          channelId = 'balaji_points_important';
        }

        await _localNotificationService.showNotification(
          title: message.notification!.title ?? 'Notification',
          body: message.notification!.body ?? '',
          payload: message.data.toString(),
          channelId: channelId,
        );
      }
    });

    FirebaseMessaging.onMessageOpenedApp.listen(_handleMessageNavigation);

    _messaging.getInitialMessage().then((message) {
      if (message != null) {
        _handleMessageNavigation(message);
      }
    });
  }

  void _handleMessageNavigation(RemoteMessage message) {
    try {
      final context = navigatorKey.currentContext;
      if (context != null) {
        context.pushNamed('notifications');
      } else {
        _pendingNavigation = true;
      }
    } catch (e) {
      AppLogger.error('Navigation error', e);
    }
  }

  bool _pendingNavigation = false;

  void processPendingNavigation() {
    if (_pendingNavigation) {
      _pendingNavigation = false;
      final context = navigatorKey.currentContext;
      if (context != null) {
        context.pushNamed('notifications');
      }
    }
  }

  /// Logout cleanup - removes FCM token from Firestore and FCM
  Future<void> deleteToken() async {
    try {
      // Prevent any pending navigation that could fire after logout.
      _pendingNavigation = false;

      // Get current user document IDs before clearing session
      final Set<String> targetDocIds = {};

      // 1️⃣ Firebase Auth user (Admin via Auth)
      final authUser = _auth.currentUser;
      if (authUser != null) {
        targetDocIds.add(authUser.uid);
      }

      // 2️⃣ PIN login phone number
      final phone = await _sessionService.getPhoneNumber();
      if (phone != null && phone.isNotEmpty) {
        targetDocIds.add(phone);
      }

      // 3️⃣ Session userId
      final sessionUserId = await _sessionService.getUserId();
      if (sessionUserId != null && sessionUserId.isNotEmpty) {
        targetDocIds.add(sessionUserId);
      }

      // Clear FCM token from Firestore for all user documents
      for (final docId in targetDocIds) {
        try {
          await _firestore.collection('users').doc(docId).update({
            'fcmToken': FieldValue.delete(),
            'lastTokenUpdate': FieldValue.serverTimestamp(),
          });
          AppLogger.info('🧹 FCM token cleared from users/$docId');
        } catch (e) {
          AppLogger.warning('Could not clear token from users/$docId: $e');
        }
      }

      // Also clear token from admin docs found by phone (handles auto-generated doc IDs)
      if (phone != null && phone.isNotEmpty) {
        final adminDocs = await _firestore
            .collection('users')
            .where('role', isEqualTo: 'admin')
            .where('phone', isEqualTo: phone)
            .get();

        for (final doc in adminDocs.docs) {
          if (!targetDocIds.contains(doc.id)) {
            await doc.reference.update({
              'fcmToken': FieldValue.delete(),
              'lastTokenUpdate': FieldValue.serverTimestamp(),
            });
            AppLogger.info('🧹 FCM token cleared from admin doc: ${doc.id}');
          }
        }
      }

      // Delete token from FCM
      await _messaging.deleteToken();
      _token = null;
      AppLogger.info('🧹 FCM token deleted from device');
    } catch (e) {
      AppLogger.error('Error deleting token', e);
    }
  }
}
