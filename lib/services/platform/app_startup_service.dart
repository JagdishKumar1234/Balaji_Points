import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:balaji_points/core/logger.dart';
import 'package:balaji_points/services/platform/app_update_service.dart';
import 'package:balaji_points/services/branch/branch_migration_service.dart';
import 'package:balaji_points/services/branch/branch_service.dart';
import 'package:balaji_points/services/notifications/fcm_service.dart';
import 'package:balaji_points/services/notifications/local_notification_service.dart';
import 'package:balaji_points/services/auth/session_service.dart';
import 'package:balaji_points/services/user/user_migration_service.dart';

class AppStartupService {
  AppStartupService({
    AppUpdateService? updateService,
    UserMigrationService? migrationService,
    FCMService? fcmService,
    SessionService? sessionService,
    LocalNotificationService? notificationService,
  }) : _updateService = updateService ?? AppUpdateService(),
       _migrationService = migrationService ?? UserMigrationService(),
       _fcmService = fcmService ?? FCMService(),
       _sessionService = sessionService ?? SessionService(),
       _notificationService = notificationService ?? LocalNotificationService();

  final AppUpdateService _updateService;
  final UserMigrationService _migrationService;
  final FCMService _fcmService;
  final SessionService _sessionService;
  final LocalNotificationService _notificationService;

  Future<bool> runPreLaunchChecks(BuildContext context) async {
    // Set up notification tap handler to open Play Store URL
    _setupNotificationTapHandler();

    final forceUpdatePending = await _updateService.checkForUpdate(context);
    if (forceUpdatePending) return true;

    // Notify admin/carpenter about new version (non-blocking)
    await _updateService.notifyAdminCarpenterAboutUpdate();

    // Ensure the default branch document exists in Firestore.
    await BranchService().seedDefaultBranch();

    // One-time backfill: stamp branchId on all legacy docs.
    await BranchMigrationService().runIfNeeded();

    await _runMigrationAndRefreshFcm();
    return false;
  }

  void _setupNotificationTapHandler() {
    _notificationService.onNotificationTapped = (payload) {
      if (payload != null && payload.isNotEmpty) {
        _openUpdateUrl(payload);
      }
    };
  }

  Future<void> _openUpdateUrl(String url) async {
    try {
      final uri = Uri.tryParse(url);
      if (uri == null) return;

      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    } catch (error) {
      AppLogger.error('Failed to open update URL from notification', error);
    }
  }

  Future<void> _runMigrationAndRefreshFcm() async {
    if (!await _sessionService.isLoggedIn()) return;

    final phone = await _sessionService.getPhoneNumber();
    final firstName = await _sessionService.getFirstName();
    final lastName = await _sessionService.getLastName();
    final displayName = [
      firstName,
      lastName,
    ].where((s) => s != null && s.trim().isNotEmpty).join(' ').trim();

    AppLogger.startup(
      'Logged in: ${displayName.isEmpty ? "User" : displayName}'
      '${phone != null ? " · $phone" : ""}',
    );

    if (phone == null || phone.isEmpty) return;

    final sessionUserId = await _sessionService.getUserId();
    final uid = await _migrationService.ensureFirebaseUid();
    if (uid == null || uid.isEmpty) return;

    final normalizedPhone = _migrationService.normalizePhone(phone);
    final legacyDocId = (sessionUserId != null && sessionUserId.isNotEmpty)
        ? sessionUserId
        : normalizedPhone;

    final postLogin = await _migrationService.completePostPinLogin(
      phone: normalizedPhone,
      legacyDocId: legacyDocId,
    );

    final targetUid = postLogin?.firebaseUid ?? uid;
    final targetSessionUserId = postLogin?.firebaseUid ?? uid;
    final targetPhone = postLogin?.phone ?? normalizedPhone;

    if (targetSessionUserId.isNotEmpty &&
        targetSessionUserId != sessionUserId) {
      final sessionData = await _sessionService.getSessionData();
      await _sessionService.saveSession(
        phoneNumber: sessionData['phoneNumber'] ?? normalizedPhone,
        userId: targetSessionUserId,
        role: sessionData['role'] ?? 'carpenter',
        firstName: sessionData['firstName'],
        lastName: sessionData['lastName'],
        profileImage: sessionData['profileImage'],
        branchId: sessionData['branchId'],
      );
    }

    try {
      await _fcmService.refreshTokenAfterLogin(
        uid: targetUid,
        phone: targetPhone,
      );
    } catch (_) {
      // FCM sync is non-blocking at startup
    }
  }
}
