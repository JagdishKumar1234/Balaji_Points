// filepath: lib/services/session_service.dart

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Service for managing user session with secure storage
class SessionService {
  static final SessionService _instance = SessionService._internal();
  factory SessionService() => _instance;
  SessionService._internal();

  final FlutterSecureStorage _storage = const FlutterSecureStorage(
    aOptions: AndroidOptions(
      encryptedSharedPreferences: true,
    ),
    iOptions: IOSOptions(
      accessibility: KeychainAccessibility.first_unlock,
    ),
  );

  // Storage keys
  static const String _keyIsLoggedIn = 'is_logged_in';
  static const String _keyPhoneNumber = 'phone_number';
  static const String _keyUserRole = 'user_role';
  static const String _keyUserId = 'user_id';
  static const String _keyFirstName = 'first_name';
  static const String _keyLastName = 'last_name';
  static const String _keyProfileImage = 'profile_image';

  /// Save user session after successful login
  Future<void> saveSession({
    required String phoneNumber,
    required String userId,
    required String role,
    String? firstName,
    String? lastName,
    String? profileImage,
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

  /// Get all session data
  Future<Map<String, String?>> getSessionData() async {
    return {
      'phoneNumber': await getPhoneNumber(),
      'userId': await getUserId(),
      'role': await getUserRole(),
      'firstName': await getFirstName(),
      'lastName': await getLastName(),
      'profileImage': await getProfileImage(),
    };
  }

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
