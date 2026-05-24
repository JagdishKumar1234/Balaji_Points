import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:balaji_points/features/auth/domain/entities/user.dart';
import 'package:balaji_points/services/auth/pin_auth_service.dart';
import 'package:balaji_points/services/auth/session_service.dart';
import 'package:balaji_points/services/notifications/fcm_service.dart';
import 'package:balaji_points/services/user/user_migration_service.dart';
import 'package:balaji_points/core/logger.dart';

// ─── Service providers ────────────────────────────────────────────────────────

final pinAuthServiceProvider = Provider<PinAuthService>((_) => PinAuthService());
final sessionServiceProvider = Provider<SessionService>((_) => SessionService());
final fcmServiceProvider = Provider<FCMService>((_) => FCMService());
final userMigrationServiceProvider = Provider<UserMigrationService>((_) => UserMigrationService());

// ─── Auth state ───────────────────────────────────────────────────────────────

sealed class AuthState {
  const AuthState();
}

class AuthInitial extends AuthState {
  const AuthInitial();
}

class AuthLoading extends AuthState {
  const AuthLoading();
}

class AuthCheckingUser extends AuthState {
  const AuthCheckingUser();
}

class AuthUserExists extends AuthState {
  final String phoneNumber;
  const AuthUserExists(this.phoneNumber);
}

class AuthUserNotFound extends AuthState {
  final String phoneNumber;
  const AuthUserNotFound(this.phoneNumber);
}

class AuthAuthenticated extends AuthState {
  final User user;
  final String role;
  const AuthAuthenticated(this.user, {required this.role});
}

class AuthUnauthenticated extends AuthState {
  const AuthUnauthenticated();
}

class AuthError extends AuthState {
  final String message;
  const AuthError(this.message);
}

class PinSetupLoading extends AuthState {
  const PinSetupLoading();
}

class PinSetupSuccess extends AuthState {
  final User user;
  const PinSetupSuccess(this.user);
}

class PinSetupError extends AuthState {
  final String message;
  const PinSetupError(this.message);
}

class ResetPinLoading extends AuthState {
  const ResetPinLoading();
}

class ResetPinSuccess extends AuthState {
  const ResetPinSuccess();
}

class ResetPinError extends AuthState {
  final String message;
  const ResetPinError(this.message);
}

// ─── Notifier ─────────────────────────────────────────────────────────────────

class AuthNotifier extends Notifier<AuthState> {
  @override
  AuthState build() => const AuthInitial();

  PinAuthService get _pin => ref.read(pinAuthServiceProvider);
  SessionService get _session => ref.read(sessionServiceProvider);
  FCMService get _fcm => ref.read(fcmServiceProvider);
  UserMigrationService get _migration => ref.read(userMigrationServiceProvider);

  // ── Check session on app start ──────────────────────────────────────────────

  Future<void> checkSession() async {
    try {
      final session = await _session.getSessionData();
      if (session.isNotEmpty && session['userId'] != null) {
        final user = User(
          id: session['userId'] ?? '',
          email: '',
          phoneNumber: session['phoneNumber'] ?? '',
          displayName: _displayName(session['firstName'], session['lastName']),
          role: session['role'] ?? 'carpenter',
          isEmailVerified: true,
          createdAt: DateTime.now(),
        );
        state = AuthAuthenticated(user, role: user.role);
      } else {
        state = const AuthUnauthenticated();
      }
    } catch (e) {
      AppLogger.error('Session check failed', e);
      state = const AuthUnauthenticated();
    }
  }

  // ── Check if phone exists ───────────────────────────────────────────────────

  Future<void> checkUserExists(String phoneNumber) async {
    state = const AuthCheckingUser();
    try {
      final exists = await _pin.userExists(phoneNumber);
      state = exists ? AuthUserExists(phoneNumber) : AuthUserNotFound(phoneNumber);
    } catch (e) {
      AppLogger.error('Error checking user existence', e);
      state = AuthError('Error checking user: $e');
    }
  }

  // ── Login with PIN ──────────────────────────────────────────────────────────

  Future<void> loginWithPin({
    required String phoneNumber,
    required String pin,
    bool rememberMe = true,
  }) async {
    state = const AuthLoading();
    try {
      final userData = await _pin.verifyPin(phone: phoneNumber, pin: pin);
      if (userData == null) {
        state = const AuthError('Invalid PIN');
        return;
      }

      final legacyDocId = userData['docId'] as String? ?? userData['id'] as String? ?? phoneNumber;
      final postLogin = await _migration.completePostPinLogin(phone: phoneNumber, legacyDocId: legacyDocId);
      final userId = postLogin?.firebaseUid ?? postLogin?.sessionUserId ?? userData['id'] as String? ?? phoneNumber;

      if (rememberMe) {
        await _session.saveSession(
          phoneNumber: phoneNumber,
          userId: userId,
          role: userData['role'] as String? ?? 'carpenter',
          firstName: userData['firstName'] as String?,
          lastName: userData['lastName'] as String?,
          branchId: userData['branchId'] as String?,
        );
      }

      if (postLogin != null) {
        try {
          await _fcm.refreshTokenAfterLogin(uid: postLogin.firebaseUid, phone: postLogin.phone);
        } catch (e) {
          AppLogger.warning('FCM refresh after login failed: $e');
        }
      }

      final role = userData['role'] as String? ?? 'carpenter';
      final user = User(
        id: userId,
        email: userData['email'] as String? ?? '',
        phoneNumber: phoneNumber,
        displayName: _displayName(userData['firstName'] as String?, userData['lastName'] as String?),
        photoUrl: userData['profileImage'] as String?,
        role: role,
        isEmailVerified: true,
        createdAt: DateTime.now(),
      );

      AppLogger.auth('Login: ${user.displayName} · $role');
      state = AuthAuthenticated(user, role: role);
    } catch (e) {
      AppLogger.error('Login failed', e);
      state = AuthError('Login failed: $e');
    }
  }

  // ── Setup PIN (new user) ────────────────────────────────────────────────────

  Future<void> setupPin({
    required String phoneNumber,
    required String pin,
    required String firstName,
    String? lastName,
    String? profileImageUrl,
    String? branchId,
  }) async {
    state = const PinSetupLoading();
    try {
      final success = await _pin.setPinForPhone(
        phone: phoneNumber,
        pin: pin,
        firstName: firstName,
        lastName: lastName,
        profileImageUrl: profileImageUrl,
        branchId: branchId,
      );
      if (!success) {
        state = const PinSetupError('Failed to setup PIN');
        return;
      }

      final userData = await _pin.verifyPin(phone: phoneNumber, pin: pin);
      if (userData == null) {
        state = const PinSetupError('Auto-login failed after setup');
        return;
      }

      final legacyDocId = userData['docId'] as String? ?? userData['id'] as String? ?? phoneNumber;
      final postLogin = await _migration.completePostPinLogin(phone: phoneNumber, legacyDocId: legacyDocId);
      final userId = postLogin?.firebaseUid ?? postLogin?.sessionUserId ?? userData['id'] as String? ?? phoneNumber;

      await _session.saveSession(
        phoneNumber: phoneNumber,
        userId: userId,
        role: userData['role'] as String? ?? 'carpenter',
        firstName: userData['firstName'] as String?,
        lastName: userData['lastName'] as String?,
        branchId: userData['branchId'] as String? ?? branchId,
      );

      if (postLogin != null) {
        try {
          await _fcm.refreshTokenAfterLogin(uid: postLogin.firebaseUid, phone: postLogin.phone);
        } catch (e) {
          AppLogger.warning('FCM refresh after setup failed: $e');
        }
      }

      final user = User(
        id: userId,
        email: userData['email'] as String? ?? '',
        phoneNumber: phoneNumber,
        displayName: _displayName(firstName, lastName),
        photoUrl: profileImageUrl,
        role: userData['role'] as String? ?? 'carpenter',
        isEmailVerified: true,
        createdAt: DateTime.now(),
      );

      state = PinSetupSuccess(user);
    } catch (e) {
      AppLogger.error('PIN setup failed', e);
      state = PinSetupError('PIN setup failed: $e');
    }
  }

  // ── Reset PIN ───────────────────────────────────────────────────────────────

  Future<void> resetPin({
    required String phoneNumber,
    required String oldPin,
    required String newPin,
  }) async {
    state = const ResetPinLoading();
    try {
      final userData = await _pin.verifyPin(phone: phoneNumber, pin: oldPin);
      if (userData == null) {
        state = const ResetPinError('Invalid current PIN');
        return;
      }
      final success = await _pin.setPinForPhone(phone: phoneNumber, pin: newPin);
      state = success ? const ResetPinSuccess() : const ResetPinError('Failed to reset PIN');
    } catch (e) {
      AppLogger.error('PIN reset failed', e);
      state = ResetPinError('PIN reset failed: $e');
    }
  }

  // ── Logout ──────────────────────────────────────────────────────────────────

  Future<void> logout() async {
    try {
      await _session.clearSession();
      state = const AuthUnauthenticated();
    } catch (e) {
      AppLogger.error('Logout failed', e);
      state = AuthError('Logout failed: $e');
    }
  }

  // ── Clear error back to initial ─────────────────────────────────────────────

  void clearError() => state = const AuthInitial();

  // ── Helpers ─────────────────────────────────────────────────────────────────

  String _displayName(String? first, String? last) {
    final name = '${first ?? ''} ${last ?? ''}'.trim();
    return name.isEmpty ? 'User' : name;
  }
}

// ─── Provider ─────────────────────────────────────────────────────────────────

final authProvider = NotifierProvider<AuthNotifier, AuthState>(
  () => AuthNotifier(),
);
