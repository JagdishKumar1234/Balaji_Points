// filepath: lib/main.dart

import 'package:flutter/material.dart';
import 'package:balaji_points/core/design/app_colors.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:package_info_plus/package_info_plus.dart';

import 'app.dart';
import 'firebase_options.dart';
import 'core/logger.dart';
import 'services/notifications/fcm_service.dart';
import 'services/notifications/local_notification_service.dart';

/// -------------------------------
/// BACKGROUND FCM HANDLER (TOP LEVEL)
/// -------------------------------
/// This handler is called when app is in background or terminated
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // For Android, explicitly show local notification when app is in background
  if (message.notification != null) {
    try {
      final localNotificationService = LocalNotificationService();
      await localNotificationService.initialize();

      // Determine channel based on priority or type
      String channelId = 'balaji_points_default';
      if (message.data['type'] == 'billApproved' ||
          message.data['type'] == 'tierUpgraded' ||
          message.data['type'] == 'pointsWithdrawn') {
        channelId = 'balaji_points_important';
      }

      await localNotificationService.showNotification(
        title: message.notification!.title ?? 'Notification',
        body: message.notification!.body ?? '',
        payload: message.data.toString(),
        channelId: channelId,
      );
    } catch (e) {
      AppLogger.error('Background notification error', e);
    }
  }
}

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  // System UI Styling (Status bar)
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: AppColors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ),
  );

  // App begins with Bootstrap (Firebase initialization inside)
  runApp(const ProviderScope(child: _Bootstrap()));
}

/// ------------------------------------------------------
/// BOOTSTRAP WIDGET — Handles ALL initialization cleanly
/// ------------------------------------------------------
/// Init future is cached so it runs only ONCE (FutureBuilder would
/// otherwise call _init() on every rebuild and slow/hang the app).
class _Bootstrap extends StatelessWidget {
  const _Bootstrap();

  static Future<void> _init() async {
    try {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );

      final packageInfo = await PackageInfo.fromPlatform();
      AppLogger.appLaunchBanner(
        version: packageInfo.version,
        build: int.tryParse(packageInfo.buildNumber) ?? 0,
      );

      try {
        FirebaseMessaging.onBackgroundMessage(
          _firebaseMessagingBackgroundHandler,
        );
        await FCMService().initialize();
      } catch (fcmError) {
        AppLogger.warning('FCM init failed');
      }

      AppLogger.startup('Bootstrap OK');
    } catch (e) {
      AppLogger.error('Bootstrap failed', e);
      rethrow;
    }
  }

  static final Future<void> _initFuture = _init();

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: _initFuture,
      builder: (context, snapshot) {
        // Show splash until Firebase is ready
        if (snapshot.connectionState != ConnectionState.done) {
          return const MaterialApp(
            debugShowCheckedModeBanner: false,
            home: _SplashScreen(),
          );
        }

        // Firebase ready → Load full app
        return const BalajiPointsApp();
      },
    );
  }
}

/// ------------------------
/// Minimal Splash UI
/// ------------------------
class _SplashScreen extends StatelessWidget {
  const _SplashScreen();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: AppColors.white,
      body: Center(
        child: SizedBox(
          width: 48,
          height: 48,
          child: CircularProgressIndicator(strokeWidth: 2.6),
        ),
      ),
    );
  }
}
