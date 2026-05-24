import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'dart:io' show Platform;
import 'package:go_router/go_router.dart';
import '../../core/logger.dart';
import '../../config/routes.dart';

/// Local Notification Service for displaying notifications
/// when app is in foreground or for scheduled notifications
class LocalNotificationService {
  static final LocalNotificationService _instance =
      LocalNotificationService._internal();
  factory LocalNotificationService() => _instance;
  LocalNotificationService._internal();

  final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();
  bool _initialized = false;

  /// Callback for when notification is tapped
  Function(String?)? onNotificationTapped;

  /// Initialize local notifications
  Future<void> initialize() async {
    if (_initialized) {
      AppLogger.info('Local notifications already initialized');
      return;
    }

    try {
      // Android initialization settings
      const androidSettings = AndroidInitializationSettings(
        '@mipmap/ic_launcher',
      );

      // iOS initialization settings
      const iosSettings = DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
      );

      // Initialization settings
      const initSettings = InitializationSettings(
        android: androidSettings,
        iOS: iosSettings,
      );

      // Initialize plugin
      final initialized = await _notifications.initialize(
        initSettings,
        onDidReceiveNotificationResponse: _onNotificationTapped,
      );

      if (initialized == true) {
        _initialized = true;
        AppLogger.info('Local notifications initialized successfully');

        // Create notification channels for Android
        await _createNotificationChannels();
      } else {
        AppLogger.warning('Local notifications initialization failed');
      }
    } catch (e) {
      AppLogger.error('Error initializing local notifications', e);
    }
  }

  /// Create notification channels for Android (required for Android 8.0+)
  Future<void> _createNotificationChannels() async {
    if (!Platform.isAndroid) return;

    try {
      // Default channel for general notifications
      const defaultChannel = AndroidNotificationChannel(
        'balaji_points_default',
        'Balaji Points Notifications',
        description: 'General notifications from Balaji Points app',
        importance: Importance.high,
        playSound: true,
        enableVibration: true,
      );

      await _notifications
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >()
          ?.createNotificationChannel(defaultChannel);

      // High priority channel for important notifications
      const highPriorityChannel = AndroidNotificationChannel(
        'balaji_points_important',
        'Important Notifications',
        description:
            'Important notifications like bill approvals and tier upgrades',
        importance: Importance.high,
        playSound: true,
        enableVibration: true,
      );

      await _notifications
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >()
          ?.createNotificationChannel(highPriorityChannel);

      AppLogger.info('Notification channels created');
    } catch (e) {
      AppLogger.error('Error creating notification channels', e);
    }
  }

  /// Show a local notification
  Future<void> showNotification({
    required String title,
    required String body,
    String? payload,
    String channelId = 'balaji_points_default',
    Importance importance = Importance.high,
    Priority priority = Priority.high,
  }) async {
    if (!_initialized) {
      AppLogger.warning('Local notifications not initialized, skipping');
      return;
    }

    try {
      // Determine channel name and description based on channelId
      String channelName;
      String channelDescription;

      if (channelId == 'balaji_points_important') {
        channelName = 'Important Notifications';
        channelDescription =
            'Important notifications like bill approvals and tier upgrades';
      } else {
        channelName = 'Balaji Points Notifications';
        channelDescription = 'General notifications from Balaji Points app';
      }

      final androidDetails = AndroidNotificationDetails(
        channelId,
        channelName,
        channelDescription: channelDescription,
        importance: importance,
        priority: priority,
        showWhen: true,
        enableVibration: true,
        playSound: true,
      );

      const iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );

      final details = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      final notificationId = DateTime.now().millisecondsSinceEpoch.remainder(
        100000,
      );
      await _notifications.show(
        notificationId,
        title,
        body,
        details,
        payload: payload,
      );

      AppLogger.info('Local notification shown: $title');
    } catch (e) {
      AppLogger.error('Error showing local notification', e);
    }
  }

  /// Handle notification tap
  void _onNotificationTapped(NotificationResponse response) {
    AppLogger.info('Notification tapped: ${response.payload}');

    // Call custom callback if set (e.g., for update notifications)
    if (onNotificationTapped != null) {
      onNotificationTapped!(response.payload);
      return;
    }

    // Default behavior: Navigate to notifications screen
    try {
      final context = navigatorKey.currentContext;
      if (context != null) {
        context.pushNamed('notifications');
        AppLogger.info(
          '✅ Navigated to notifications screen from local notification tap',
        );
      } else {
        AppLogger.warning(
          'Navigator context not available for notification tap',
        );
      }
    } catch (e) {
      AppLogger.error('Error navigating from notification tap', e);
    }
  }

  /// Cancel all notifications
  Future<void> cancelAll() async {
    await _notifications.cancelAll();
  }

  /// Cancel a specific notification by ID
  Future<void> cancel(int id) async {
    await _notifications.cancel(id);
  }

  /// Schedule a daily spin reminder notification
  /// Note: For production, scheduled notifications should be handled by Cloud Functions
  /// This method is a placeholder that can be enhanced with timezone package
  ///
  /// To implement properly:
  /// 1. Add timezone package: timezone: ^0.9.4
  /// 2. Use zonedSchedule with proper timezone handling
  /// 3. Or use Cloud Functions with scheduled triggers
  Future<void> scheduleDailySpinReminder() async {
    if (!_initialized) {
      AppLogger.warning(
        'Local notifications not initialized, skipping reminder',
      );
      return;
    }

    AppLogger.info(
      'Daily spin reminder scheduling - Use Cloud Functions for production',
    );
    // TODO: Implement with timezone package or Cloud Functions
    // For now, this is a placeholder
    // Cloud Functions can check daily_spins collection and send reminders
    // to users who haven't spun today
  }
}
