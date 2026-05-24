// Updated FirebaseConfigValidator without PhoneAuth / SHA checks
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import '../../core/logger.dart';

class FirebaseConfigValidator {
  /// Main validator (OTP removed → no SHA, no CAPTCHA check)
  static Future<FirebaseConfigStatus> validateConfiguration() async {
    try {
      AppLogger.info('Starting Firebase configuration validation...');

      // 1. Firebase initialized?
      if (Firebase.apps.isEmpty) {
        return FirebaseConfigStatus(
          isValid: false,
          message: 'Firebase is not initialized',
          errorType: ConfigErrorType.notInitialized,
        );
      }

      // 2. FirebaseAuth available?
      try {
        FirebaseAuth.instance;
      } catch (e) {
        return FirebaseConfigStatus(
          isValid: false,
          message: 'Firebase Auth not configured: $e',
          errorType: ConfigErrorType.authError,
        );
      }

      // 3. google-services.json validation
      try {
        final app = Firebase.app();
        final options = app.options;

        if (options.apiKey.isEmpty) {
          return FirebaseConfigStatus(
            isValid: false,
            message: 'Missing API key in google-services.json',
            errorType: ConfigErrorType.missingApiKey,
          );
        }

        if (options.appId.isEmpty) {
          return FirebaseConfigStatus(
            isValid: false,
            message: 'Missing App ID in google-services.json',
            errorType: ConfigErrorType.missingAppId,
          );
        }

        AppLogger.info('Firebase config valid — OTP disabled (PIN login only)');
      } catch (e) {
        return FirebaseConfigStatus(
          isValid: false,
          message: 'Firebase configuration parsing error: $e',
          errorType: ConfigErrorType.configError,
        );
      }

      return FirebaseConfigStatus(
        isValid: true,
        message: 'Firebase configuration valid',
        errorType: ConfigErrorType.none,
      );
    } catch (e, stack) {
      AppLogger.error('Unexpected Firebase validation error', e, stack);
      return FirebaseConfigStatus(
        isValid: false,
        message: 'Unexpected error: $e',
        errorType: ConfigErrorType.unknown,
      );
    }
  }

  /// Phone Auth removed → always return true
  static Future<bool> checkPhoneAuthConfiguration() async {
    AppLogger.info('PhoneAuth disabled → skipping check');
    return true;
  }

  /// User-friendly error message mapping
  static String getConfigErrorMessage(FirebaseConfigStatus status) {
    switch (status.errorType) {
      case ConfigErrorType.notInitialized:
        return '❌ Firebase not initialized';
      case ConfigErrorType.authError:
        return '❌ Firebase Auth not configured: ${status.message}';
      case ConfigErrorType.missingApiKey:
        return '❌ Missing API key in google-services.json';
      case ConfigErrorType.missingAppId:
        return '❌ Missing App ID in google-services.json';
      case ConfigErrorType.configError:
        return '❌ Firebase configuration error: ${status.message}';
      case ConfigErrorType.unknown:
        return '❌ Unknown error: ${status.message}';
      case ConfigErrorType.none:
        return '✅ Firebase configuration valid';
    }
  }

  /// Debug logger
  static void logConfigurationDetails() {
    try {
      if (Firebase.apps.isEmpty) {
        AppLogger.info('No Firebase apps initialized');
        return;
      }

      final app = Firebase.app();
      final options = app.options;

      AppLogger.info('========================================');
      AppLogger.info('Firebase Configuration');
      AppLogger.info('App Name: ${app.name}');
      AppLogger.info('Project ID: ${options.projectId}');
      AppLogger.info('App ID: ${options.appId}');
      AppLogger.info('API Key: ${options.apiKey.substring(0, 10)}...');
      AppLogger.info('========================================');
    } catch (e) {
      AppLogger.error('Failed to log Firebase configuration', e);
    }
  }
}

class FirebaseConfigStatus {
  final bool isValid;
  final String message;
  final ConfigErrorType errorType;

  FirebaseConfigStatus({
    required this.isValid,
    required this.message,
    required this.errorType,
  });
}

enum ConfigErrorType {
  none,
  notInitialized,
  authError,
  missingApiKey,
  missingAppId,
  configError,
  unknown,
}
