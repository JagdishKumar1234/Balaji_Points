// CLEAN PHONE AUTH SERVICE (OTP REMOVED)
// --------------------------------------
// This service is kept only so your codebase does not break.
// All OTP-related logic has been removed completely.
// The login system now uses PIN + Firestore only.

import 'package:firebase_auth/firebase_auth.dart';
import '../../core/logger.dart';

class PhoneAuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Sign in anonymously (used by PIN login system)
  Future<User?> signInSilently() async {
    try {
      final current = _auth.currentUser;
      if (current != null) {
        AppLogger.info('User already signed in anonymously: ${current.uid}');
        return current;
      }

      final userCred = await _auth.signInAnonymously();
      AppLogger.info('Anonymous sign-in successful: ${userCred.user?.uid}');
      return userCred.user;
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
