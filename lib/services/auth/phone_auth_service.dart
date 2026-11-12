// CLEAN PHONE AUTH SERVICE (OTP REMOVED)
// --------------------------------------
// This service is kept only so your codebase does not break.
// All OTP-related logic has been removed completely.
// The login system now uses PIN + Firestore only.

import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/firebase/test_emulators.dart';
import '../../core/logger.dart';

class PhoneAuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Live Firebase has anonymous sign-in turned off, so every attempt fails
  /// after a full network round trip. Once it fails that way the app stops
  /// asking for a day (saved on the phone), and concurrent callers share one
  /// attempt, so startup and Home never wait on it.
  static const _disabledUntilKey = 'anonSignInDisabledUntil';
  static bool _disabledThisRun = false;
  static Future<User?>? _inFlight;

  /// Sign in anonymously (used by PIN login system)
  Future<User?> signInSilently() {
    final current = _auth.currentUser;
    if (current != null) return Future.value(current);
    if (TestEmulators.blocksAnonymousSignIn || _disabledThisRun) {
      return Future.value(null);
    }
    return _inFlight ??= _signIn().whenComplete(() => _inFlight = null);
  }

  Future<User?> _signIn() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final until = prefs.getInt(_disabledUntilKey) ?? 0;
      if (DateTime.now().millisecondsSinceEpoch < until) {
        _disabledThisRun = true;
        return null;
      }
      final userCred = await _auth.signInAnonymously();
      AppLogger.info('Anonymous sign-in successful: ${userCred.user?.uid}');
      return userCred.user;
    } on FirebaseAuthException catch (e) {
      if (e.code == 'admin-restricted-operation' ||
          e.code == 'operation-not-allowed') {
        // Expected on live: not an error, so it is not sent to Crashlytics.
        _disabledThisRun = true;
        AppLogger.info('Anonymous sign-in is off in Firebase; skipping it.');
        try {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setInt(
            _disabledUntilKey,
            DateTime.now().add(const Duration(days: 1)).millisecondsSinceEpoch,
          );
        } catch (_) {}
        return null;
      }
      AppLogger.error('Anonymous sign-in failed', e);
      return null;
    } catch (e) {
      AppLogger.error('Anonymous sign-in failed', e);
      return null;
    }
  }

  /// Dummy sendOTP method (NO OTP SENT)
  Future<bool> sendOTP({
    required String phoneNumber,
    Function(String verificationId)? onCodeSent,
    Function(String error)? onError,
  }) async {
    AppLogger.warning(
      'sendOTP() called but OTP authentication is disabled. Using PIN login instead.',
    );

    onError?.call('OTP login is disabled. Please use PIN login.');
    return false;
  }

  /// Dummy verifyOTP method (NO OTP VERIFIED)
  Future<User?> verifyOTP({
    required String otpCode,
    Function(String error)? onError,
  }) async {
    AppLogger.warning('verifyOTP() called but OTP authentication is disabled.');

    onError?.call('OTP login is disabled. Please use PIN login.');
    return null;
  }

  /// SIGN OUT
  Future<void> signOut() async {
    try {
      await _auth.signOut();
      AppLogger.info('User signed out successfully');
    } catch (e) {
      AppLogger.error('Sign out failed', e);
    }
  }

  /// GET CURRENT USER
  User? getCurrentUser() => _auth.currentUser;

  /// CHECK AUTH
  bool get isAuthenticated => _auth.currentUser != null;

  /// Clear state (no-op now)
  void clearVerificationState() {
    AppLogger.info('Verification state cleared (OTP disabled)');
  }
}
