// filepath: lib/main.dart

import 'package:balaji_points/services/telemetry/telemetry.dart';
import 'dart:async';
import 'dart:ui' show PlatformDispatcher;

import 'package:flutter/material.dart';
import 'package:balaji_points/core/design/app_colors.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart'
    show LicenseEntryWithLineBreaks, LicenseRegistry;
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:package_info_plus/package_info_plus.dart';

import 'core/constants/app_constants.dart';
import 'core/firebase/test_emulators.dart';
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

  // Nunito ships in assets/google_fonts/ — never download fonts at runtime
  // (works offline on first launch, no layout jump when the font arrives).
  GoogleFonts.config.allowRuntimeFetching = false;
  LicenseRegistry.addLicense(() async* {
    final license = await rootBundle.loadString('assets/google_fonts/OFL.txt');
    yield LicenseEntryWithLineBreaks(['google_fonts', 'Nunito'], license);
  });

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
      // Test builds only: switch to the local Firebase copy. Stops the app
      // on failure rather than continuing on live data.
      await TestEmulators.connectIfRequested();
      // Only Firebase itself is awaited: everything else starts in the
      // background, so the first screen appears as soon as possible.
      FirebaseMessaging.onBackgroundMessage(
        _firebaseMessagingBackgroundHandler,
      );
      unawaited(_startInBackground());

      AppLogger.startup('Bootstrap OK');
    } catch (e) {
      AppLogger.error('Bootstrap failed', e);
      rethrow;
    }
  }

  /// Work that must not delay the first screen: analytics, the launch log,
  /// and push setup (which asks for notification permission on first run;
  /// a notification tap is still handled once it finishes).
  static Future<void> _startInBackground() async {
    // Test mode never reports to live Analytics or Crashlytics.
    if (!TestEmulators.enabled) await _startTelemetry();
    try {
      final packageInfo = await PackageInfo.fromPlatform();
      AppLogger.appLaunchBanner(
        version: packageInfo.version,
        build: int.tryParse(packageInfo.buildNumber) ?? 0,
      );
    } catch (_) {}
    try {
      await FCMService().initialize();
    } catch (fcmError) {
      AppLogger.warning('FCM init failed');
    }
  }

  /// Analytics and crash reporting. Never blocks or breaks startup.
  static Future<void> _startTelemetry() async {
    try {
      final sink = FirebaseTelemetrySink();
      await sink.start();
      Telemetry.use(sink);
      AppLogger.errorReporter = (message, error, stack) =>
          Telemetry.recordError(
            error ?? message,
            stack ?? StackTrace.current,
            reason: message,
          );
      AppLogger.breadcrumbs = Telemetry.breadcrumb;

      if (!kIsWeb && FirebaseTelemetrySink.enabled) {
        // Errors while drawing the screen.
        FlutterError.onError = (details) {
          FlutterError.presentError(details);
          Telemetry.recordError(
            details.exception,
            details.stack,
            reason: details.context?.toString(),
            fatal: true,
          );
        };
        // Errors in async code that nothing caught.
        PlatformDispatcher.instance.onError = (error, stack) {
          Telemetry.recordError(error, stack, fatal: true);
          return true;
        };
      }
    } catch (e) {
      AppLogger.warning('Telemetry not started: $e');
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

        // A test build that could not reach the local Firebase copy must
        // stop here, never carry on against live data.
        if (TestEmulators.enabled && snapshot.hasError) {
          return MaterialApp(
            debugShowCheckedModeBanner: false,
            home: Scaffold(
              body: Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text(
                    'TEST MODE could not reach the local Firebase emulators. '
                    'Nothing was loaded.\n\n${snapshot.error}',
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            ),
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
    // Matches the native launch screen (same logo, size and background), so
    // the hand-over from Android to Flutter is invisible.
    final dark = MediaQuery.platformBrightnessOf(context) == Brightness.dark;
    return Scaffold(
      backgroundColor: dark ? AppColors.darkBackground : AppColors.white,
      body: Center(
        child: ClipRRect(
          borderRadius: BorderRadius.circular(150 * 0.22),
          child: Image.asset(
            AppConstants.logoPath,
            width: 150,
            height: 150,
            cacheWidth: 450,
            gaplessPlayback: true,
          ),
        ),
      ),
    );
  }
}
