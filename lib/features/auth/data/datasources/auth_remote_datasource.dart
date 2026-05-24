// filepath: lib/features/auth/data/datasources/auth_remote_datasource.dart
import 'package:balaji_points/services/pin_auth_service.dart';
import 'package:balaji_points/services/session_service.dart';
import 'package:balaji_points/services/fcm_service.dart';
import 'package:balaji_points/services/user_migration_service.dart';
import 'package:balaji_points/features/auth/data/models/user_model.dart';

abstract class AuthRemoteDataSource {
  Future<bool> checkUserExists(String phoneNumber);
  Future<UserModel> verifyPin(String phoneNumber, String pin);
  Future<UserModel> setupPin({
    required String phoneNumber,
    required String pin,
    required String firstName,
    String? lastName,
    String? profileImageUrl,
  });
  Future<bool> resetPin({
    required String phoneNumber,
    required String oldPin,
    required String newPin,
  });
  Future<void> saveSession(UserModel user, bool rememberMe);
  Future<void> clearSession();
  Future<UserModel?> getCurrentSession();
}

class AuthRemoteDataSourceImpl implements AuthRemoteDataSource {
  final PinAuthService _pinAuthService;
  final SessionService _sessionService;
  final FCMService _fcmService;
  final UserMigrationService _userMigrationService;

  AuthRemoteDataSourceImpl({
    required PinAuthService pinAuthService,
    required SessionService sessionService,
    required FCMService fcmService,
    required UserMigrationService userMigrationService,
  })  : _pinAuthService = pinAuthService,
        _sessionService = sessionService,
        _fcmService = fcmService,
        _userMigrationService = userMigrationService;

  @override
  Future<bool> checkUserExists(String phoneNumber) async {
    return await _pinAuthService.userExists(phoneNumber);
  }

  @override
  Future<UserModel> verifyPin(String phoneNumber, String pin) async {
    final result = await _pinAuthService.verifyPin(phone: phoneNumber, pin: pin);
    if (result == null) throw Exception('Invalid PIN');

    final legacyDocId =
        result['docId'] as String? ?? result['id'] as String? ?? phoneNumber;
    final postLogin = await _userMigrationService.completePostPinLogin(
      phone: phoneNumber,
      legacyDocId: legacyDocId,
    );

    if (postLogin != null) {
      result['id'] = postLogin.sessionUserId;
      result['docId'] = postLogin.sessionUserId;
      result['uid'] = postLogin.firebaseUid;
      await _fcmService.refreshTokenAfterLogin(
        uid: postLogin.firebaseUid,
        phone: postLogin.phone,
      );
    }

    return UserModel.fromJson(result);
  }

  @override
  Future<UserModel> setupPin({
    required String phoneNumber,
    required String pin,
    required String firstName,
    String? lastName,
    String? profileImageUrl,
  }) async {
    final success = await _pinAuthService.setPinForPhone(
      phone: phoneNumber,
      pin: pin,
      firstName: firstName,
      lastName: lastName,
      profileImageUrl: profileImageUrl,
    );
    if (!success) throw Exception('Failed to setup PIN');
    return await verifyPin(phoneNumber, pin);
  }

  @override
  Future<bool> resetPin({
    required String phoneNumber,
    required String oldPin,
    required String newPin,
  }) async {
    await verifyPin(phoneNumber, oldPin);
    return await _pinAuthService.setPinForPhone(phone: phoneNumber, pin: newPin);
  }

  @override
  Future<void> saveSession(UserModel user, bool rememberMe) async {
    if (rememberMe) {
      final normalizedRole = user.role.trim().toLowerCase();

      await _sessionService.saveSession(
        phoneNumber: user.phoneNumber ?? '',
        userId: user.id,
        role: normalizedRole,
        firstName: user.displayName?.split(' ').first,
        lastName: user.displayName?.split(' ').skip(1).join(' '),
      );
    } else {
      // If user doesn't want to remember, clear any existing persisted session
      // (prevents stale "admin" role from redirecting splash incorrectly).
      await _sessionService.clearSession();
    }
    
    // FCM token is saved in verifyPin after migration (refreshTokenAfterLogin).
    try {
      await _fcmService.initialize();
    } catch (e) {
      // Continue even if FCM fails
    }
  }

  @override
  Future<void> clearSession() async {
    await _sessionService.clearSession();
  }

  @override
  Future<UserModel?> getCurrentSession() async {
    final session = await _sessionService.getSessionData();
    if (session.isEmpty) return null;
    
    return UserModel(
      id: session['userId'] ?? '',
      email: '',
      phoneNumber: session['phoneNumber'] ?? '',
      displayName: '${session['firstName'] ?? ''} ${session['lastName'] ?? ''}'.trim(),
      role: session['role'] ?? 'carpenter',
      isEmailVerified: true,
      createdAt: DateTime.now(),
    );
  }
}
