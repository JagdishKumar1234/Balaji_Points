import 'package:balaji_points/core/design/app_colors.dart';
import 'package:balaji_points/core/design/app_typography.dart';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:balaji_points/core/constants/app_constants.dart';
import 'package:balaji_points/core/logger.dart';
import 'package:balaji_points/presentation/widgets/shared/app_update_dialog.dart';
import 'package:balaji_points/services/notifications/local_notification_service.dart';
import 'package:balaji_points/services/auth/session_service.dart';

class AppUpdateService {
  AppUpdateService({
    FirebaseFirestore? firestore,
    LocalNotificationService? notificationService,
    SessionService? sessionService,
  }) : _firestore = firestore ?? FirebaseFirestore.instance,
       _notificationService = notificationService ?? LocalNotificationService(),
       _sessionService = sessionService ?? SessionService();

  final FirebaseFirestore _firestore;
  final LocalNotificationService _notificationService;
  final SessionService _sessionService;

  /// Notify admin and carpenter users about new version availability
  /// Shows a local notification if a new version is available
  Future<void> notifyAdminCarpenterAboutUpdate() async {
    try {
      final userRole = await _sessionService.getUserRole();
      final isAdminOrCarpenter =
          userRole == AppConstants.roleAdmin ||
          userRole == AppConstants.roleCarpenter;

      if (!isAdminOrCarpenter) return;

      final remoteInfo = await _fetchRemoteUpdateInfo();
      if (remoteInfo == null) return;

      final platformInfo = remoteInfo.forCurrentPlatform;
      if (platformInfo == null) return;

      final packageInfo = await PackageInfo.fromPlatform();
      final currentVersion = packageInfo.version.trim();
      final latestVersion = platformInfo.latestVersion.trim();
      final updateUrl = platformInfo.updateUrl.trim();

      if (currentVersion.isEmpty || latestVersion.isEmpty) return;

      // Check if update is available
      if (compareVersionStrings(currentVersion, latestVersion) >= 0) {
        return; // Already on latest version
      }

      if (updateUrl.isEmpty) return;

      // Show notification for admin/carpenter
      await _notificationService.showNotification(
        title: '🚀 New Version Available',
        body: 'Version $latestVersion is now available. Tap to update.',
        payload: updateUrl,
        channelId: 'balaji_points_important',
      );

      AppLogger.info(
        'Update notification shown: $currentVersion → $latestVersion',
      );
    } catch (error, stackTrace) {
      AppLogger.error('Failed to notify about update', error, stackTrace);
    }
  }

  /// Loads app update metadata from Firestore and shows the appropriate
  /// update prompt if required.
  ///
  /// Returns true when a force update dialog was shown and the splash flow
  /// should postpone navigation until the user updates the app.
  Future<bool> checkForUpdate(BuildContext context) async {
    try {
      final remoteInfo = await _fetchRemoteUpdateInfo();
      if (remoteInfo == null) return false;

      final platformInfo = remoteInfo.forCurrentPlatform;
      if (platformInfo == null) return false;

      final packageInfo = await PackageInfo.fromPlatform();
      final currentVersion = packageInfo.version.trim();
      final latestVersion = platformInfo.latestVersion.trim();
      final minimumVersion = platformInfo.minimumVersion.trim();
      final forceFlag = platformInfo.forceUpdate;

      if (currentVersion.isEmpty) return false;

      final isBelowMinimum =
          minimumVersion.isNotEmpty &&
          compareVersionStrings(currentVersion, minimumVersion) < 0;
      final isBelowLatest =
          latestVersion.isNotEmpty &&
          compareVersionStrings(currentVersion, latestVersion) < 0;
      final needsForceUpdate = isBelowMinimum || (forceFlag && isBelowLatest);
      final needsOptionalUpdate = !needsForceUpdate && isBelowLatest;
      final targetVersion = isBelowMinimum ? minimumVersion : latestVersion;

      if (!needsForceUpdate && !needsOptionalUpdate) return false;

      if (!context.mounted) return needsForceUpdate;

      AppLogger.update(
        needsForceUpdate
            ? 'Force update required ($currentVersion → $targetVersion)'
            : 'Optional update ($currentVersion → $latestVersion)',
      );

      await _showUpdateDialog(
        context: context,
        currentVersion: currentVersion,
        latestVersion: latestVersion,
        minimumVersion: minimumVersion,
        targetVersion: targetVersion,
        platformInfo: platformInfo,
        forceUpdate: needsForceUpdate,
      );

      return needsForceUpdate;
    } catch (error, stackTrace) {
      AppLogger.error('Failed to check app update', error, stackTrace);
      return false;
    }
  }

  Future<AppUpdateInfo?> _fetchRemoteUpdateInfo() async {
    try {
      final doc = await _firestore
          .collection(AppConstants.appConfigCollection)
          .doc(AppConstants.appConfigDocument)
          .get(const GetOptions(source: Source.server));

      if (!doc.exists || doc.data() == null) return null;
      return AppUpdateInfo.fromMap(doc.data()!);
    } on FirebaseException catch (e) {
      if (e.code == 'permission-denied') {
        AppLogger.error(
          'Firestore PERMISSION_DENIED for app_config/version. '
          'Deploy rules: firebase deploy --only firestore:rules',
          e,
        );
      } else {
        AppLogger.error('Firestore error loading app config', e);
      }
      return null;
    }
  }

  Future<void> _showUpdateDialog({
    required BuildContext context,
    required String currentVersion,
    required String latestVersion,
    required String minimumVersion,
    required String targetVersion,
    required AppPlatformUpdate platformInfo,
    required bool forceUpdate,
  }) async {
    await showDialog<void>(
      context: context,
      barrierDismissible: !forceUpdate,
      barrierColor: AppColors.black.withValues(alpha: 0.54),
      builder: (dialogContext) {
        return AppUpdateDialog(
          forceUpdate: forceUpdate,
          currentVersion: currentVersion,
          latestVersion: latestVersion,
          minimumVersion: minimumVersion,
          targetVersion: targetVersion,
          onUpdate: () =>
              _launchUpdateUrl(dialogContext, platformInfo.updateUrl),
          onLater: forceUpdate ? null : () => Navigator.of(dialogContext).pop(),
        );
      },
    );
  }

  Future<void> _launchUpdateUrl(BuildContext context, String url) async {
    if (url.isEmpty) {
      _showLaunchError(context);
      return;
    }

    final uri = Uri.tryParse(url);
    if (uri == null) {
      _showLaunchError(context);
      return;
    }

    try {
      if (await _tryLaunchUrl(uri)) {
        return;
      }

      final fallbackUri = _playStoreFallbackUri(uri);
      if (fallbackUri != null && await _tryLaunchUrl(fallbackUri)) {
        return;
      }

      _showLaunchError(context);
    } catch (error) {
      AppLogger.error('Failed to launch update URL', error);
      _showLaunchError(context);
    }
  }

  Future<bool> _tryLaunchUrl(Uri uri) async {
    try {
      if (!await canLaunchUrl(uri)) {
        return false;
      }
      return await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (error) {
      AppLogger.error('Launch failed for $uri', error);
      return false;
    }
  }

  Uri? _playStoreFallbackUri(Uri uri) {
    if (!Platform.isAndroid) return null;
    if (uri.scheme != 'https' || uri.host != 'play.google.com') return null;
    final id = uri.queryParameters['id'];
    if (id == null || id.isEmpty) return null;
    return Uri(scheme: 'market', host: 'details', queryParameters: {'id': id});
  }

  void _showLaunchError(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Unable to open the app store. Please check your connection or contact support.',
          style: AppTypography.bodyMedium().copyWith(color: AppColors.white),
        ),
        backgroundColor: AppColors.error,
      ),
    );
  }

  /// Compares two semantic version strings.
  ///
  /// Returns a negative value when `a < b`, zero when equal, and positive when
  /// `a > b`.
  int compareVersionStrings(String a, String b) {
    final aParts = a.split('.').map((part) => int.tryParse(part) ?? 0).toList();
    final bParts = b.split('.').map((part) => int.tryParse(part) ?? 0).toList();
    final length = aParts.length > bParts.length
        ? aParts.length
        : bParts.length;

    for (var i = 0; i < length; i++) {
      final aValue = i < aParts.length ? aParts[i] : 0;
      final bValue = i < bParts.length ? bParts[i] : 0;
      final diff = aValue - bValue;
      if (diff != 0) {
        return diff;
      }
    }
    return 0;
  }
}

class AppUpdateInfo {
  AppUpdateInfo({required this.android, required this.ios});

  final AppPlatformUpdate android;
  final AppPlatformUpdate ios;

  AppPlatformUpdate? get forCurrentPlatform {
    if (Platform.isAndroid) {
      return android;
    }
    if (Platform.isIOS) {
      return ios;
    }
    return null;
  }

  factory AppUpdateInfo.fromMap(Map<String, dynamic> data) {
    return AppUpdateInfo(
      android: AppPlatformUpdate.fromMap(data, prefix: 'android'),
      ios: AppPlatformUpdate.fromMap(data, prefix: 'ios'),
    );
  }
}

class AppPlatformUpdate {
  AppPlatformUpdate({
    required this.latestVersion,
    required this.minimumVersion,
    required this.updateUrl,
    required this.forceUpdate,
  });

  final String latestVersion;
  final String minimumVersion;
  final String updateUrl;
  final bool forceUpdate;

  factory AppPlatformUpdate.fromMap(
    Map<String, dynamic> data, {
    required String prefix,
  }) {
    return AppPlatformUpdate(
      latestVersion: _readVersionField(data, '${prefix}LatestVersion'),
      minimumVersion: _readVersionField(data, '${prefix}MinimumVersion'),
      updateUrl: (data['${prefix}UpdateUrl'] as String?)?.trim() ?? '',
      forceUpdate: _readBoolField(data, '${prefix}ForceUpdate'),
    );
  }

  static String _readVersionField(Map<String, dynamic> data, String key) {
    final value = data[key];
    if (value == null) return '';
    return value.toString().trim();
  }

  static bool _readBoolField(Map<String, dynamic> data, String key) {
    final value = data[key];
    if (value is bool) return value;
    if (value is String) {
      return value.toLowerCase() == 'true';
    }
    if (value is num) return value != 0;
    return false;
  }
}
