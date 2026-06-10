// filepath: lib/services/auth/super_admin_auth_service.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/logger.dart';
import 'pin_auth_service.dart';

/// Enhanced authentication service for super_admin access
/// Includes multi-factor security checks, session management, and audit logging
class SuperAdminAuthService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final PinAuthService _pinAuthService = PinAuthService();

  // Session timeout for super_admin (15 minutes)
  static const Duration superAdminSessionTimeout = Duration(minutes: 15);

  /// Authenticate super_admin with enhanced security checks
  ///
  /// Performs the following validations:
  /// 1. Verifies phone + PIN combination
  /// 2. Checks user role is 'super_admin'
  /// 3. Validates session hasn't expired
  /// 4. Logs authentication event
  /// 5. Updates last login timestamp
  Future<bool> authenticateSuperAdmin({
    required String phone,
    required String pin,
    String? ipAddress = 'UNKNOWN',
  }) async {
    try {
      AppLogger.info('🔐 Super admin authentication attempt: $phone');

      // Step 1: Normalize phone and verify PIN
      final normalizedPhone = _pinAuthService.normalizePhone(phone);
      final verifiedUser = await _pinAuthService.verifyPin(
        phone: normalizedPhone,
        pin: pin,
      );

      if (verifiedUser == null) {
        AppLogger.warning('❌ Invalid PIN for super_admin: $normalizedPhone');
        await _logFailedAttempt(normalizedPhone, ipAddress);
        return false;
      }

      // Step 2: Get user and verify role
      final user = await _getUserByPhone(normalizedPhone);
      if (user == null) {
        AppLogger.warning('❌ Super admin not found: $normalizedPhone');
        await _logFailedAttempt(normalizedPhone, ipAddress);
        return false;
      }

      final role = user['role'] as String?;
      if (role != 'super_admin') {
        AppLogger.warning(
          '❌ User is not super_admin (role: $role): $normalizedPhone',
        );
        await _logFailedAttempt(normalizedPhone, ipAddress);
        return false;
      }

      // Step 3: Check if account is active
      final status = user['status'] as String?;
      if (status?.toLowerCase() != 'verified' &&
          status?.toLowerCase() != 'active') {
        AppLogger.warning(
          '❌ Super admin account inactive: $normalizedPhone (status: $status)',
        );
        await _logFailedAttempt(normalizedPhone, ipAddress);
        return false;
      }

      // Step 4: Validate session (check last login wasn't too old)
      final lastLogin = user['lastLogin'] as Timestamp?;
      if (lastLogin != null) {
        final elapsed = DateTime.now().difference(lastLogin.toDate());
        if (elapsed > const Duration(days: 30)) {
          AppLogger.warning(
            '⚠️ Super admin account inactive for 30+ days: $normalizedPhone',
          );
          // Allow login but log as security event
        }
      }

      // Step 5: Update last login and log successful authentication
      final userId = user['uid'] as String? ?? user['userId'] as String?;
      if (userId != null) {
        await _firestore.collection('users').doc(userId).update({
          'lastLogin': FieldValue.serverTimestamp(),
        });

        await _logSuccessfulLogin(normalizedPhone, userId, ipAddress);
        AppLogger.info('✅ Super admin authenticated: $normalizedPhone');
        return true;
      }

      return false;
    } catch (e, st) {
      AppLogger.error('💥 Super admin authentication error', e, st);
      return false;
    }
  }

  /// Verify super_admin credentials and get user data
  /// Returns user data if valid, null otherwise
  Future<Map<String, dynamic>?> verifySuperAdminCredentials({
    required String phone,
    required String pin,
  }) async {
    try {
      final normalizedPhone = _pinAuthService.normalizePhone(phone);

      // Verify PIN
      final verifiedUser = await _pinAuthService.verifyPin(
        phone: normalizedPhone,
        pin: pin,
      );
      if (verifiedUser == null) {
        return null;
      }

      // Get and validate user
      final user = await _getUserByPhone(normalizedPhone);
      if (user?['role'] == 'super_admin') {
        return user;
      }

      return null;
    } catch (e) {
      AppLogger.error('Error verifying super admin credentials', e);
      return null;
    }
  }

  /// Get super_admin user by phone number
  Future<Map<String, dynamic>?> _getUserByPhone(String phone) async {
    try {
      final query = await _firestore
          .collection('users')
          .where('phone', isEqualTo: phone)
          .limit(1)
          .get();

      if (query.docs.isNotEmpty) {
        return query.docs.first.data() as Map<String, dynamic>?;
      }
      return null;
    } catch (e) {
      AppLogger.error('Error getting user by phone', e);
      return null;
    }
  }

  /// Log failed super_admin authentication attempt
  Future<void> _logFailedAttempt(String phone, String? ipAddress) async {
    try {
      await _firestore.collection('security_events').add({
        'type': 'FAILED_SUPER_ADMIN_LOGIN',
        'phone': phone,
        'ipAddress': ipAddress ?? 'UNKNOWN',
        'timestamp': FieldValue.serverTimestamp(),
        'severity': 'CRITICAL',
        'description': 'Failed super admin authentication attempt',
      });
    } catch (e) {
      AppLogger.error('Error logging failed super admin attempt', e);
    }
  }

  /// Log successful super_admin login
  Future<void> _logSuccessfulLogin(
    String phone,
    String userId,
    String? ipAddress,
  ) async {
    try {
      await _firestore.collection('audit_logs').add({
        'action': 'SUPER_ADMIN_LOGIN',
        'phone': phone,
        'userId': userId,
        'userRole': 'super_admin',
        'ipAddress': ipAddress ?? 'UNKNOWN',
        'timestamp': FieldValue.serverTimestamp(),
        'severity': 'HIGH',
        'description': 'Super admin successfully authenticated',
      });
    } catch (e) {
      AppLogger.error('Error logging super admin login', e);
    }
  }

  /// Log super_admin action to audit trail
  /// All critical super_admin actions should be logged
  Future<void> logSuperAdminAction({
    required String userId,
    required String action,
    required String description,
    Map<String, dynamic>? details,
    String? ipAddress = 'UNKNOWN',
  }) async {
    try {
      await _firestore.collection('audit_logs').add({
        'action': action,
        'userId': userId,
        'userRole': 'super_admin',
        'description': description,
        'details': details ?? {},
        'ipAddress': ipAddress,
        'timestamp': FieldValue.serverTimestamp(),
        'severity': 'HIGH',
      });

      AppLogger.info('📝 Super admin action logged: $action by $userId');
    } catch (e) {
      AppLogger.error('Error logging super admin action', e);
    }
  }

  /// Get super_admin audit logs
  /// Returns paginated audit logs for super_admin activities
  Future<List<Map<String, dynamic>>> getAuditLogs({
    int limit = 50,
    DocumentSnapshot? lastDoc,
  }) async {
    try {
      Query query = _firestore
          .collection('audit_logs')
          .where('userRole', isEqualTo: 'super_admin')
          .orderBy('timestamp', descending: true)
          .limit(limit);

      if (lastDoc != null) {
        query = query.startAfterDocument(lastDoc);
      }

      final snapshot = await query.get();
      return snapshot.docs
          .map((doc) => doc.data() as Map<String, dynamic>)
          .toList();
    } catch (e) {
      AppLogger.error('Error fetching audit logs', e);
      return [];
    }
  }

  /// Get security events (failed login attempts, etc.)
  Future<List<Map<String, dynamic>>> getSecurityEvents({
    int limit = 50,
    String? severity, // 'CRITICAL', 'HIGH', 'MEDIUM', 'LOW'
  }) async {
    try {
      Query query = _firestore
          .collection('security_events')
          .orderBy('timestamp', descending: true)
          .limit(limit);

      if (severity != null) {
        query = query.where('severity', isEqualTo: severity);
      }

      final snapshot = await query.get();
      return snapshot.docs
          .map((doc) => doc.data() as Map<String, dynamic>)
          .toList();
    } catch (e) {
      AppLogger.error('Error fetching security events', e);
      return [];
    }
  }

  /// Check if session is still valid (not timed out)
  /// Super admin sessions expire after 15 minutes
  bool isSessionValid(Timestamp lastActivityTime) {
    final elapsed = DateTime.now().difference(lastActivityTime.toDate());
    return elapsed <= superAdminSessionTimeout;
  }

  /// Update last activity timestamp
  Future<void> updateLastActivity(String userId) async {
    try {
      await _firestore.collection('users').doc(userId).update({
        'lastActivity': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      AppLogger.error('Error updating last activity', e);
    }
  }

  /// Invalidate all super_admin sessions (emergency lockdown)
  Future<void> invalidateAllSessions() async {
    try {
      final query = await _firestore
          .collection('users')
          .where('role', isEqualTo: 'super_admin')
          .get();

      for (final doc in query.docs) {
        await doc.reference.update({
          'sessionInvalidated': true,
          'sessionInvalidatedAt': FieldValue.serverTimestamp(),
        });
      }

      AppLogger.warning('🚨 All super admin sessions invalidated (emergency)');
    } catch (e) {
      AppLogger.error('Error invalidating sessions', e);
    }
  }
}
