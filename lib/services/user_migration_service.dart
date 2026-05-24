import 'package:cloud_firestore/cloud_firestore.dart';
import '../core/logger.dart';
import 'phone_auth_service.dart';
import 'pin_auth_service.dart';

/// One canonical user per phone: `users/{firebaseUid}`.
/// Legacy `users/{phone}` docs are marked migrated and no longer written to.
class UserMigrationService {
  UserMigrationService({
    FirebaseFirestore? firestore,
    PhoneAuthService? phoneAuthService,
    PinAuthService? pinAuthService,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _phoneAuthService = phoneAuthService ?? PhoneAuthService(),
        _pinAuthService = pinAuthService ?? PinAuthService();

  final FirebaseFirestore _firestore;
  final PhoneAuthService _phoneAuthService;
  final PinAuthService _pinAuthService;

  String normalizePhone(String phone) => _pinAuthService.normalizePhone(phone);

  CollectionReference<Map<String, dynamic>> get _users =>
      _firestore.collection('users');

  /// Ensures a Firebase Auth user exists (anonymous) and returns its UID.
  Future<String?> ensureFirebaseUid() async {
    final user = await _phoneAuthService.signInSilently();
    return user?.uid;
  }

  /// The only document the app should read/write after login.
  Future<DocumentReference<Map<String, dynamic>>> resolveCanonicalUserRef({
    required String phone,
    String? firebaseUid,
  }) async {
    final normalized = normalizePhone(phone);
    final uid = firebaseUid ?? await ensureFirebaseUid();

    if (uid != null && uid.isNotEmpty) {
      await migrateOldUserIfNeeded(uid: uid, phone: normalized);
      final uidDoc = await _users.doc(uid).get();
      if (uidDoc.exists) {
        return _users.doc(uid);
      }
    }

    final phoneDoc = await _users.doc(normalized).get();
    if (phoneDoc.exists) {
      final migratedTo = phoneDoc.data()?['migratedToUid'] as String?;
      if (migratedTo != null && migratedTo.isNotEmpty) {
        return _users.doc(migratedTo);
      }
      return phoneDoc.reference;
    }

    final query = await _users
        .where('phone', isEqualTo: normalized)
        .get();
    for (final doc in query.docs) {
      if (doc.id == normalized) continue;
      final migratedTo = doc.data()['migratedToUid'] as String?;
      if (migratedTo == null || migratedTo.isEmpty) {
        return doc.reference;
      }
    }

    if (uid != null && uid.isNotEmpty) {
      return _users.doc(uid);
    }
    return _users.doc(normalized);
  }

  Future<String> resolveCanonicalUserId({
    required String phone,
    String? firebaseUid,
  }) async {
    final ref = await resolveCanonicalUserRef(
      phone: phone,
      firebaseUid: firebaseUid,
    );
    return ref.id;
  }

  /// Copy legacy `users/{phone}` → `users/{uid}` once; mark phone doc inactive.
  Future<void> migrateOldUserIfNeeded({
    required String uid,
    required String phone,
    String? legacyDocId,
  }) async {
    final normalized = normalizePhone(phone);

    final uidDoc = await _users.doc(uid).get();
    if (uidDoc.exists) {
      await _markLegacyPhoneDocInactive(
        normalized: normalized,
        uid: uid,
        legacyDocId: legacyDocId,
      );
      return;
    }

    DocumentSnapshot<Map<String, dynamic>>? source;

    final phoneDoc = await _users.doc(normalized).get();
    if (phoneDoc.exists) {
      source = phoneDoc;
    } else if (legacyDocId != null &&
        legacyDocId.isNotEmpty &&
        legacyDocId != uid) {
      final legacyDoc = await _users.doc(legacyDocId).get();
      if (legacyDoc.exists) {
        source = legacyDoc;
      }
    }

    if (source == null) {
      final query = await _users
          .where('phone', isEqualTo: normalized)
          .limit(5)
          .get();
      for (final doc in query.docs) {
        if (doc.id != uid) {
          source = doc;
          break;
        }
      }
    }

    if (source == null || !source.exists || source.id == uid) {
      return;
    }

    final data = source.data()!;
    AppLogger.info(
      'Migrating user ${source.id} → users/$uid (phone: $normalized)',
    );

    await _users.doc(uid).set({
      ...data,
      'uid': uid,
      'phone': normalized,
      'migratedFromPhoneDoc': true,
      'migratedFromDocId': source.id,
      'migratedAt': FieldValue.serverTimestamp(),
      'legacyAccount': false,
    });

    await source.reference.set({
      'migratedToUid': uid,
      'legacyAccount': true,
      'active': false,
      'migratedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    await _migrateUserPointsIfNeeded(
      fromDocId: source.id,
      toUid: uid,
    );
  }

  Future<void> _markLegacyPhoneDocInactive({
    required String normalized,
    required String uid,
    String? legacyDocId,
  }) async {
    final ids = <String>{normalized};
    if (legacyDocId != null && legacyDocId.isNotEmpty && legacyDocId != uid) {
      ids.add(legacyDocId);
    }

    for (final id in ids) {
      if (id == uid) continue;
      final ref = _users.doc(id);
      final snap = await ref.get();
      if (!snap.exists) continue;
      final migratedTo = snap.data()?['migratedToUid'] as String?;
      if (migratedTo == uid && snap.data()?['legacyAccount'] == true) {
        continue;
      }
      await ref.set({
        'migratedToUid': uid,
        'legacyAccount': true,
        'active': false,
        'migratedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    }
  }

  /// Resolves the canonical Firestore user document (UID-first).
  @Deprecated('Use resolveCanonicalUserRef')
  Future<DocumentReference<Map<String, dynamic>>> getUserRef({
    required String uid,
    required String phone,
  }) async {
    return resolveCanonicalUserRef(phone: phone, firebaseUid: uid);
  }

  /// Anonymous Auth + migration; session always uses Firebase UID.
  Future<PostLoginResult?> completePostPinLogin({
    required String phone,
    required String legacyDocId,
  }) async {
    final uid = await ensureFirebaseUid();
    if (uid == null) {
      AppLogger.error('Post-login failed: could not obtain Firebase UID');
      return null;
    }

    final normalized = normalizePhone(phone);
    await migrateOldUserIfNeeded(
      uid: uid,
      phone: normalized,
      legacyDocId: legacyDocId,
    );

    return PostLoginResult(
      firebaseUid: uid,
      sessionUserId: uid,
      phone: normalized,
    );
  }

  Future<void> _migrateUserPointsIfNeeded({
    required String fromDocId,
    required String toUid,
  }) async {
    if (fromDocId == toUid) return;

    final points = _firestore.collection('user_points');
    final sourcePoints = await points.doc(fromDocId).get();
    if (!sourcePoints.exists) return;

    await points.doc(toUid).set({
      ...?sourcePoints.data(),
      'userId': toUid,
      'migratedFromDocId': fromDocId,
      'migratedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    await points.doc(fromDocId).set({
      'migratedToUid': toUid,
      'migratedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    AppLogger.info('Migrated user_points $fromDocId → $toUid');
  }
}

class PostLoginResult {
  final String firebaseUid;
  final String sessionUserId;
  final String phone;

  const PostLoginResult({
    required this.firebaseUid,
    required this.sessionUserId,
    required this.phone,
  });
}
