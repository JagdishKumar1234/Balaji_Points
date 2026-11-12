import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/logger.dart';
import '../auth/session_service.dart';
import '../notifications/notification_service.dart';
import 'user_migration_service.dart';

class UserService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final SessionService _sessionService = SessionService();
  final UserMigrationService _userMigrationService = UserMigrationService();

  /// Check if phone number exists in pending_users
  Future<bool> checkPendingUser(String phoneNumber) async {
    try {
      final doc = await _firestore
          .collection('pending_users')
          .doc(phoneNumber)
          .get();
      return doc.exists;
    } catch (e) {
      AppLogger.error('Error checking pending user', e);
      return false;
    }
  }

  /// Check if user is verified in users collection
  Future<Map<String, dynamic>?> checkVerifiedUser(String uid) async {
    try {
      final doc = await _firestore.collection('users').doc(uid).get();
      if (doc.exists) {
        return doc.data();
      }
      return null;
    } catch (e) {
      AppLogger.error('Error checking verified user', e);
      return null;
    }
  }

  /// Get user by phone number
  Future<Map<String, dynamic>?> getUserByPhone(String phoneNumber) async {
    try {
      final query = await _firestore
          .collection('users')
          .where('phone', isEqualTo: phoneNumber)
          .limit(1)
          .get();

      if (query.docs.isEmpty) return null;

      final data = query.docs.first.data();
      final status = (data['status'] as String?)?.toLowerCase();
      if (status == 'verified' || status == 'approved') {
        return data;
      }
      return null;
    } catch (e) {
      AppLogger.error('Error getting user by phone', e);
      return null;
    }
  }

  /// Create pending user
  Future<bool> createPendingUser({
    required String firstName,
    required String lastName,
    required String phone,
    String? city,
    String? skill,
    String? referral,
  }) async {
    try {
      final exists = await checkPendingUser(phone);
      if (exists) return false;

      await _firestore.collection('pending_users').doc(phone).set({
        'firstName': firstName,
        'lastName': lastName,
        'phone': phone,
        'role': 'carpenter',
        'status': 'pending',
        'createdAt': FieldValue.serverTimestamp(),
        if (city != null && city.isNotEmpty) 'city': city,
        if (skill != null && skill.isNotEmpty) 'skill': skill,
        if (referral != null && referral.isNotEmpty) 'referral': referral,
      });

      return true;
    } catch (e) {
      AppLogger.error('Error creating pending user', e);
      return false;
    }
  }

  /// Create verified user in Firestore
  Future<bool> createVerifiedUser({
    required String uid,
    required String firstName,
    required String lastName,
    required String phone,
    String? city,
    String? skill,
    String? referral,
    String verifiedBy = 'system',
  }) async {
    try {
      // For new carpenters we want docId == phone for easier lookups
      final docId = phone;

      await _firestore.collection('users').doc(docId).set({
        'uid': uid, // keep original uid for reference
        'firstName': firstName,
        'lastName': lastName,
        'phone': phone,
        'role': 'carpenter',
        'status': 'verified',
        'totalPoints': 0,
        'tier': 'Bronze',
        'verifiedAt': FieldValue.serverTimestamp(),
        'verifiedBy': verifiedBy,
        'createdAt': FieldValue.serverTimestamp(),
        if (city != null) 'city': city,
        if (skill != null) 'skill': skill,
        if (referral != null) 'referral': referral,
      });

      // Points initialization
      await _firestore.collection('user_points').doc(docId).set({
        'userId': docId,
        'totalPoints': 0,
        'tier': 'Bronze',
        'lastUpdated': FieldValue.serverTimestamp(),
        'pointsHistory': [],
      });

      // Send notification to all admins about new user registration
      try {
        final userName = '$firstName $lastName'.trim();
        final notificationService = NotificationService();
        await notificationService.notifyAdminsNewUserRegistered(
          userName: userName.isNotEmpty ? userName : phone,
          userPhone: phone,
          userId: docId,
        );
        AppLogger.info('✅ Admin notification sent for new user registration');
      } catch (e) {
        // Don't fail user creation if notification fails
        AppLogger.warning('Failed to send admin notification for new user: $e');
      }

      return true;
    } catch (e) {
      AppLogger.error('Error creating verified user', e);
      return false;
    }
  }

  /// Update user after verification
  Future<bool> updateUserAfterVerification({
    required String uid,
    required String phone,
  }) async {
    try {
      // Check pending data (most common)
      final pendingDoc = await _firestore
          .collection('pending_users')
          .doc(phone)
          .get();

      if (pendingDoc.exists) {
        final p = pendingDoc.data()!;
        await createVerifiedUser(
          uid: uid,
          firstName: p['firstName'] ?? '',
          lastName: p['lastName'] ?? '',
          phone: phone,
          city: p['city'],
          skill: p['skill'],
          referral: p['referral'],
          verifiedBy: 'phone-verification',
        );

        await _firestore.collection('pending_users').doc(phone).update({
          'status': 'approved',
          'approvedAt': FieldValue.serverTimestamp(),
        });

        return true;
      }

      // Auto-create
      await createVerifiedUser(
        uid: uid,
        firstName: 'User',
        lastName: '',
        phone: phone,
        verifiedBy: 'phone-verification',
      );

      return true;
    } catch (e) {
      AppLogger.error('Error updating user after verification', e);
      return false;
    }
  }

  /// Canonical Firestore user document id (`users/{firebaseUid}`).
  Future<String?> _getUserDocId() async {
    final phone = await _sessionService.getPhoneNumber();
    if (phone == null || phone.isEmpty) {
      return _sessionService.getUserId();
    }
    return _userMigrationService.resolveCanonicalUserId(phone: phone);
  }

  /// Fresh user data from Firestore (server) with session profile merged for instant display.
  Future<Map<String, dynamic>?> getCurrentUserData({
    bool forceRefresh = false,
    bool cacheOnly = false,
  }) async {
    try {
      final docId = await _getUserDocId();
      if (docId == null) {
        AppLogger.warning('No user id / phone in session');
        return null;
      }

      final doc = await _firestore
          .collection('users')
          .doc(docId)
          .get(
            GetOptions(
              source: cacheOnly
                  ? Source.cache
                  : forceRefresh
                  ? Source.server
                  : Source.serverAndCache,
            ),
          );

      Map<String, dynamic>? data = doc.exists ? doc.data() : null;
      if (data == null) {
        AppLogger.warning('No user document found for id: $docId');
        return null;
      }

      // Merge session profile so name/image are never stale (session updated on save)
      final sessionFirst = await _sessionService.getFirstName();
      final sessionLast = await _sessionService.getLastName();
      final sessionImage = await _sessionService.getProfileImage();
      if ((sessionFirst != null && sessionFirst.isNotEmpty) &&
          ((data['firstName'] as String? ?? '').isEmpty)) {
        data = Map<String, dynamic>.from(data)..['firstName'] = sessionFirst;
      }
      if ((sessionLast != null && sessionLast.isNotEmpty) &&
          ((data['lastName'] as String? ?? '').isEmpty)) {
        data = Map<String, dynamic>.from(data)..['lastName'] = sessionLast;
      }
      if ((sessionImage != null && sessionImage.isNotEmpty) &&
          ((data['profileImage'] as String? ?? '').isEmpty)) {
        data = Map<String, dynamic>.from(data)..['profileImage'] = sessionImage;
      }

      AppLogger.info('User data loaded for id: $docId');
      return data;
    } catch (e) {
      // A cache miss (nothing saved yet) is normal, not an error.
      if (!cacheOnly) AppLogger.error('Error getting current user data', e);
      return null;
    }
  }

  /// Admin check
  Future<bool> isAdmin() async {
    try {
      final data = await getCurrentUserData(forceRefresh: true);
      return data?['role'] == 'admin';
    } catch (e) {
      AppLogger.error('Error checking admin status', e);
      return false;
    }
  }
}
