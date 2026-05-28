// filepath: lib/services/session_service.dart

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Service for managing user session with secure storage
class SessionService {
  static final SessionService _instance = SessionService._internal();
  factory SessionService() => _instance;
  SessionService._internal();

  final FlutterSecureStorage _storage = const FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
    iOptions: IOSOptions(accessibility: KeychainAccessibility.first_unlock),
  );

  // Storage keys
  static const String _keyIsLoggedIn = 'is_logged_in';
  static const String _keyPhoneNumber = 'phone_number';
  static const String _keyUserRole = 'user_role';
  static const String _keyUserId = 'user_id';
  static const String _keyFirstName = 'first_name';
  static const String _keyLastName = 'last_name';
  static const String _keyProfileImage = 'profile_image';
  static const String _keyBiometricEnabled = 'biometric_enabled';
  static const String _keyHasAskedBiometric = 'has_asked_biometric';
  static const String _keyBranchId = 'branch_id';
  static const String _keyPinHash = 'pin_hash';

  /// Save user session after successful login
  Future<void> saveSession({
    required String phoneNumber,
    required String userId,
    required String role,
    String? firstName,
    String? lastName,
    String? profileImage,
    String? branchId,
    String? pinHash,
  }) async {
    await _storage.write(key: _keyIsLoggedIn, value: 'true');
    await _storage.write(key: _keyPhoneNumber, value: phoneNumber);
    await _storage.write(key: _keyUserId, value: userId);
    await _storage.write(key: _keyUserRole, value: role);

    if (firstName != null) {
      await _storage.write(key: _keyFirstName, value: firstName);
    }
    if (lastName != null) {
      await _storage.write(key: _keyLastName, value: lastName);
    }
    if (profileImage != null) {
      await _storage.write(key: _keyProfileImage, value: profileImage);
    }
    if (branchId != null) {
      await _storage.write(key: _keyBranchId, value: branchId);
    }
    if (pinHash != null) {
      await _storage.write(key: _keyPinHash, value: pinHash);
    }
  }

  /// Check if user is logged in
  Future<bool> isLoggedIn() async {
    final value = await _storage.read(key: _keyIsLoggedIn);
    return value == 'true';
  }

  /// Get stored phone number
  Future<String?> getPhoneNumber() async {
    return await _storage.read(key: _keyPhoneNumber);
  }

  /// Get stored user ID
  Future<String?> getUserId() async {
    return await _storage.read(key: _keyUserId);
  }

  /// IDs used when querying bills / points (session userId + phone).
  Future<List<String>> getCarpenterQueryIds() async {
    final userId = await getUserId();
    final phone = await getPhoneNumber();
    return {
      if (userId != null && userId.trim().isNotEmpty) userId.trim(),
      if (phone != null && phone.trim().isNotEmpty) phone.trim(),
    }.toList();
  }

  /// Get stored user role
  Future<String?> getUserRole() async {
    return await _storage.read(key: _keyUserRole);
  }

  /// Get stored first name
  Future<String?> getFirstName() async {
    return await _storage.read(key: _keyFirstName);
  }

  /// Get stored last name
  Future<String?> getLastName() async {
    return await _storage.read(key: _keyLastName);
  }

  /// Get stored profile image URL
  Future<String?> getProfileImage() async {
    return await _storage.read(key: _keyProfileImage);
  }

  /// Get stored branch ID (null for super_admin or unset legacy users)
  Future<String?> getBranchId() async {
    return await _storage.read(key: _keyBranchId);
  }

  /// Get stored PIN hash for the remembered session
  Future<String?> getPinHash() async {
    return await _storage.read(key: _keyPinHash);
  }

  /// Update branch ID in session (called after branch migration)
  Future<void> setBranchId(String branchId) async {
    await _storage.write(key: _keyBranchId, value: branchId);
  }

  /// Update stored PIN hash after a PIN reset
  Future<void> setPinHash(String pinHash) async {
    await _storage.write(key: _keyPinHash, value: pinHash);
  }

  /// Get all session data
  Future<Map<String, String?>> getSessionData() async {
    return {
      'phoneNumber': await getPhoneNumber(),
      'userId': await getUserId(),
      'role': await getUserRole(),
      'firstName': await getFirstName(),
      'lastName': await getLastName(),
      'profileImage': await getProfileImage(),
      'branchId': await getBranchId(),
      'pinHash': await getPinHash(),
    };
  }

  // ── Biometric preferences ───────────────────────────────────────────────────

  /// Whether the user has opted in to biometric login for this device.
  Future<bool> isBiometricEnabled() async {
    final value = await _storage.read(key: _keyBiometricEnabled);
    return value == 'true';
  }

  /// Persist biometric opt-in / opt-out choice.
  Future<void> setBiometricEnabled({required bool enabled}) async {
    await _storage.write(
      key: _keyBiometricEnabled,
      value: enabled ? 'true' : 'false',
    );
  }

  /// Whether the app has already asked the user about biometric login once.
  /// Used to show the prompt only once after first successful PIN login.
  Future<bool> hasAskedBiometric() async {
    final value = await _storage.read(key: _keyHasAskedBiometric);
    return value == 'true';
  }

  /// Mark that the biometric opt-in prompt has been shown to the user.
  Future<void> markAskedBiometric() async {
    await _storage.write(key: _keyHasAskedBiometric, value: 'true');
  }

  // ───────────────────────────────────────────────────────────────────────────

  /// Clear session (logout)
  Future<void> clearSession() async {
    await _storage.deleteAll();
  }

  /// Update user profile information (call after saving in edit profile for instant sync)
  Future<void> updateProfile({
    String? firstName,
    String? lastName,
    String? profileImage,
  }) async {
    if (firstName != null) {
      await _storage.write(key: _keyFirstName, value: firstName);
    }
    if (lastName != null) {
      await _storage.write(key: _keyLastName, value: lastName);
    }
    if (profileImage != null) {
      await _storage.write(key: _keyProfileImage, value: profileImage);
    }
  }
}
