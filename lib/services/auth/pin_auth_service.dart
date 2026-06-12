// filepath: lib/services/pin_auth_service.dart
import 'dart:convert';
import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:crypto/crypto.dart';

import '../../core/logger.dart';
import '../user/user_service.dart';

class PinAuthService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Normalize phone into a canonical format (e.g. "6376814539" -> "6376814539").
  /// You can later adapt for country codes if needed.
  String normalizePhone(String phone) {
    return phone.replaceAll(RegExp(r'[^0-9]'), '');
  }

  /// Generate a random salt (16 bytes → hex string).
  String _generateSalt() {
    final rand = Random.secure();
    final bytes = List<int>.generate(16, (_) => rand.nextInt(256));
    return base64UrlEncode(bytes);
  }

  /// Create salted hash using SHA-256 (simple and safe enough for this use case).
  String _hashPin(String pin, String salt) {
    final bytes = utf8.encode('$pin::$salt');
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  /// Create or update user with PIN.
  /// - If user with this phone exists → update PIN + profile info.
  /// - If not → create new user + user_points doc.
  Future<bool> setPinForPhone({
    required String phone,
    required String pin,
    String? firstName,
    String? lastName,
    String? profileImageUrl,
    String? branchId,
  }) async {
    try {
      final normalized = normalizePhone(phone);
      final usersRef = _firestore.collection('users');

      final salt = _generateSalt();
      final pinHash = _hashPin(pin, salt);

      final existingDoc = await _resolveDocForAuth(normalized);

      if (existingDoc != null) {
        final doc = existingDoc;
        final data = <String, dynamic>{
          'pinHash': pinHash,
          'pinSalt': salt,
          'pinUpdatedAt': FieldValue.serverTimestamp(),
        };

        if (firstName != null && firstName.isNotEmpty) {
          data['firstName'] = firstName;
        }
        if (lastName != null && lastName.isNotEmpty) {
          data['lastName'] = lastName;
        }
        if (profileImageUrl != null && profileImageUrl.isNotEmpty) {
          data['profileImage'] = profileImageUrl;
        }
        // branchId is immutable once set — only write if not already present
        if (branchId != null) {
          final existing = doc.data();
          if (existing == null || existing['branchId'] == null) {
            data['branchId'] = branchId;
          }
        }

        await doc.reference.set(data, SetOptions(merge: true));
        AppLogger.info('PIN updated for existing user: $normalized');
        return true;
      } else {
        // SAFETY CHECK: Ensure no duplicate exists before creating new user
        // This prevents race conditions where multiple requests create users simultaneously
        final duplicateCheck = await usersRef
            .where('phone', isEqualTo: normalized)
            .limit(1)
            .get();

        if (duplicateCheck.docs.isNotEmpty) {
          AppLogger.warning(
            '⚠️ [setPinForPhone] Phone $normalized already exists, using existing user',
          );
          // Use existing user instead of creating new one
          final existingDocId = duplicateCheck.docs.first.id;
          final existingRef = usersRef.doc(existingDocId);
          final updateData = <String, dynamic>{
            'pinHash': pinHash,
            'pinSalt': salt,
            'pinUpdatedAt': FieldValue.serverTimestamp(),
          };

          if (firstName != null && firstName.isNotEmpty) {
            updateData['firstName'] = firstName;
          }
          if (lastName != null && lastName.isNotEmpty) {
            updateData['lastName'] = lastName;
          }
          if (profileImageUrl != null && profileImageUrl.isNotEmpty) {
            updateData['profileImage'] = profileImageUrl;
          }

          await existingRef.set(updateData, SetOptions(merge: true));
          AppLogger.info('PIN updated for existing user (duplicate check): $normalized');
          return true;
        }

        // Create new user (phone truly does not exist)
        final docRef = usersRef.doc();
        final uid = docRef.id;

        await docRef.set({
          'uid': uid,
          'userId': uid,
          'firstName': firstName ?? 'User',
          'lastName': lastName ?? '',
          'phone': normalized,
          'profileImage': profileImageUrl ?? '',
          'role': 'carpenter',
          'branchId': branchId,
          'status': 'verified',
          'totalPoints': 0,
          'tier': 'Bronze',
          'createdAt': FieldValue.serverTimestamp(),
          'verifiedAt': FieldValue.serverTimestamp(),
          'verifiedBy': 'pin',
          'pinHash': pinHash,
          'pinSalt': salt,
          'pinUpdatedAt': FieldValue.serverTimestamp(),
        });

        // Initialize user_points
        await _firestore.collection('user_points').doc(uid).set({
          'userId': uid,
          'branchId': branchId,
          'totalPoints': 0,
          'tier': 'Bronze',
          'lastUpdated': FieldValue.serverTimestamp(),
          'pointsHistory': [],
        });

        AppLogger.info('New user created with PIN: $normalized');
        return true;
      }
    } catch (e, st) {
      AppLogger.error('Error setting PIN for phone $phone', e, st);
      return false;
    }
  }

  /// Picks the canonical user doc (UID) when a legacy phone doc was migrated.
  Future<DocumentSnapshot<Map<String, dynamic>>?> _resolveDocForAuth(
    String normalized,
  ) async {
    final usersRef = _firestore.collection('users');

    AppLogger.debug('🔍 [_resolveDocForAuth] Looking up user with phone: $normalized');

    // Step 1: Query by phone field - most reliable lookup
    final phoneQuery = await usersRef
        .where('phone', isEqualTo: normalized)
        .get();

    AppLogger.debug('🔍 [_resolveDocForAuth] Found ${phoneQuery.docs.length} docs with phone field');

    if (phoneQuery.docs.isNotEmpty) {
      // Find the best candidate:
      // Priority 1: Non-legacy active user
      // Priority 2: Any existing user (even if marked legacy but has data)

      DocumentSnapshot<Map<String, dynamic>>? activeUser;
      DocumentSnapshot<Map<String, dynamic>>? fallback;

      for (final doc in phoneQuery.docs) {
        final data = doc.data();
        final isLegacy = data['legacyAccount'] == true;
        final isActive = data['active'] != false;

        AppLogger.debug(
          '🔍 [_resolveDocForAuth] Candidate: ${doc.id}, legacy=$isLegacy, active=$isActive',
        );

        // If not legacy, this is our user
        if (!isLegacy) {
          activeUser = doc;
          break;
        }

        // Keep track of first doc as fallback
        if (fallback == null) {
          fallback = doc;
        }
      }

      final foundUser = activeUser ?? fallback;
      if (foundUser != null) {
        AppLogger.info(
          '✅ [_resolveDocForAuth] Found existing user: ${foundUser.id} with phone $normalized',
        );
        return foundUser;
      }
    }

    // Step 2: Check by document ID (phone as docId)
    final phoneDoc = await usersRef.doc(normalized).get();
    if (phoneDoc.exists) {
      AppLogger.info(
        '✅ [_resolveDocForAuth] Found user by docId: $normalized',
      );
      return phoneDoc;
    }

    // No user found
    AppLogger.warning(
      '❌ [_resolveDocForAuth] No existing user found for phone: $normalized',
    );
    return null;
  }

  /// Verify phone + PIN. Returns user data if valid, null otherwise.
  Future<Map<String, dynamic>?> verifyPin({
    required String phone,
    required String pin,
  }) async {
    try {
      final normalized = normalizePhone(phone);
      AppLogger.debug('🔐 [verifyPin] Verifying PIN for phone: $normalized');

      final doc = await _resolveDocForAuth(normalized);

      if (doc == null || !doc.exists) {
        AppLogger.warning('🔐 [verifyPin] No user found for phone: $normalized');
        return null;
      }

      final data = doc.data();
      if (data == null) {
        AppLogger.warning('🔐 [verifyPin] User doc exists but has no data: ${doc.id}');
        return null;
      }

      final salt = data['pinSalt'] as String?;
      final storedHash = data['pinHash'] as String?;

      if (salt == null || storedHash == null) {
        AppLogger.warning('🔐 [verifyPin] PIN not setup for user: ${doc.id}');
        return null;
      }

      final computedHash = _hashPin(pin, salt);
      if (computedHash == storedHash) {
        AppLogger.info(
          '✅ [verifyPin] PIN verified for $normalized (docId: ${doc.id})',
        );
        // Include doc.id so session and FCM token are saved to the correct user doc
        return {...data, 'docId': doc.id, 'id': doc.id};
      }

      AppLogger.warning('🔐 [verifyPin] PIN verification failed for: $normalized');
      return null;
    } catch (e, st) {
      AppLogger.error('Error verifying PIN for phone $phone', e, st);
      return null;
    }
  }

  /// Check if a user exists (by phone number) in the users collection.
  /// Returns true if user document exists, false otherwise.
  Future<bool> userExists(String phone) async {
    try {
      final normalized = normalizePhone(phone);
      AppLogger.debug('🔍 [DEBUG] Checking if user exists for phone: "$normalized"');

      // Check by phone field first
      final queryByPhone = await _firestore
          .collection('users')
          .where('phone', isEqualTo: normalized)
          .limit(1)
          .get();

      if (queryByPhone.docs.isNotEmpty) {
        AppLogger.debug('🔍 [DEBUG] ✅ User exists (found by phone field)');
        return true;
      }

      // Also check by document ID (phone might be document ID)
      final docRef = _firestore.collection('users').doc(normalized);
      final doc = await docRef.get();

      if (doc.exists) {
        AppLogger.debug('🔍 [DEBUG] ✅ User exists (found by document ID)');
        return true;
      }

      AppLogger.debug('🔍 [DEBUG] ❌ User does not exist');
      return false;
    } catch (e) {
      AppLogger.debug('🔍 [DEBUG] ❌ Error checking user existence: $e');
      AppLogger.error('Error checking user existence for phone $phone', e);
      return false;
    }
  }

  /// Check if a phone already has a PIN set.
  /// Matches [userExists]: by `phone` field, else document id == normalized phone.
  Future<bool> hasPin(String phone) async {
    try {
      final normalized = normalizePhone(phone);
      final query = await _firestore
          .collection('users')
          .where('phone', isEqualTo: normalized)
          .limit(1)
          .get();

      Map<String, dynamic>? data;
      if (query.docs.isNotEmpty) {
        data = query.docs.first.data();
      } else {
        final doc = await _firestore.collection('users').doc(normalized).get();
        if (doc.exists) {
          data = doc.data();
        }
      }

      if (data == null) return false;
      return data['pinHash'] != null && data['pinSalt'] != null;
    } catch (e) {
      AppLogger.error('Error checking PIN for phone $phone', e);
      return false;
    }
  }

  /// Reset PIN for an existing phone with security verification
  ///
  /// Security checks:
  /// - If loggedInPhone is provided, verifies it matches the target phone
  /// - If currentPin is provided, verifies it matches the stored PIN
  /// - If isAdmin is true, skips verification (admin privilege)
  ///
  /// Returns true if reset successful, false otherwise
  Future<bool> resetPin({
    required String phone,
    required String newPin,
    String? loggedInPhone,
    String? currentPin,
    bool isAdmin = false,
  }) async {
    try {
      final normalized = normalizePhone(phone);
      final usersRef = _firestore.collection('users');

      final query = await usersRef
          .where('phone', isEqualTo: normalized)
          .limit(1)
          .get();

      if (query.docs.isEmpty) {
        AppLogger.warning(
          'PIN reset failed: User not found for phone $normalized',
        );
        return false;
      }

      final doc = query.docs.first;
      final userData = doc.data();

      // Security Verification
      if (isAdmin) {
        // Admin PIN reset - verify admin status first
        final userService = UserService();
        final isActuallyAdmin = await userService.isAdmin();
        if (!isActuallyAdmin) {
          AppLogger.warning(
            'PIN reset denied: User is not authorized as admin for phone $normalized',
          );
          return false;
        }
        // Admin verified - skip security checks and proceed
        AppLogger.info('Admin PIN reset authorized for phone $normalized');
      } else {
        // Regular user reset - apply security checks
        // Check 1: Verify phone ownership (if logged in)
        if (loggedInPhone != null) {
          final normalizedLoggedIn = normalizePhone(loggedInPhone);
          if (normalized != normalizedLoggedIn) {
            AppLogger.warning(
              'PIN reset denied: Phone mismatch. Logged in: $normalizedLoggedIn, Requested: $normalized',
            );
            return false;
          }
        } else {
          // Not logged in and not admin - deny reset
          AppLogger.warning(
            'PIN reset denied: User not logged in and not admin for phone $normalized',
          );
          return false;
        }

        // Check 2: Verify current PIN (if provided)
        if (currentPin != null) {
          final salt = userData['pinSalt'] as String?;
          final storedHash = userData['pinHash'] as String?;

          if (salt == null || storedHash == null) {
            AppLogger.warning(
              'PIN reset denied: No PIN set for phone $normalized',
            );
            return false;
          }

          final computedHash = _hashPin(currentPin, salt);
          if (computedHash != storedHash) {
            AppLogger.warning(
              'PIN reset denied: Current PIN verification failed for phone $normalized',
            );
            return false;
          }
        } else {
          // Current PIN required for non-admin resets
          AppLogger.warning(
            'PIN reset denied: Current PIN not provided for phone $normalized',
          );
          return false;
        }
      }

      // All security checks passed - proceed with reset
      final salt = _generateSalt();
      final hash = _hashPin(newPin, salt);

      await doc.reference.set({
        'pinHash': hash,
        'pinSalt': salt,
        'pinUpdatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      AppLogger.info('PIN reset successful for $normalized');
      return true;
    } catch (e, st) {
      AppLogger.error('Error resetting PIN for phone $phone', e, st);
      return false;
    }
  }

  /// Generate next user display ID (auto-increment)
  Future<int> _getNextUserDisplayId() async {
    final counterRef = _firestore.collection('counters').doc('user_counter');

    // Use transaction for atomic increment
    return await _firestore.runTransaction((transaction) async {
      final counterDoc = await transaction.get(counterRef);

      int nextId;
      if (!counterDoc.exists) {
        // Initialize counter starting from 41
        nextId = 41;
        transaction.set(counterRef, {'lastId': nextId});
      } else {
        final currentId = counterDoc.data()?['lastId'] as int? ?? 40;
        nextId = currentId + 1;
        transaction.update(counterRef, {'lastId': nextId});
      }

      return nextId;
    });
  }

  /// Create a new account with phone number as the unique identifier.
  /// Phone number is used as the document ID for easier lookups.
  /// Returns true if account creation is successful.
  /// Returns false if account already exists with a PIN (user should use Reset PIN instead).
  /// If account exists but has no PIN, it will complete the account setup.
  /// firstName defaults to empty string - can be filled later via profile update.
  Future<bool> createAccount({
    required String phone,
    required String pin,
    String firstName = '',
    String? lastName,
    String? profileImageUrl,
  }) async {
    try {
      AppLogger.debug('🔍 [DEBUG] createAccount called');
      AppLogger.debug('🔍 [DEBUG] Input phone: "$phone"');

      final normalized = normalizePhone(phone);
      AppLogger.debug('🔍 [DEBUG] Normalized phone: "$normalized"');

      final usersRef = _firestore.collection('users');

      // Check if user exists by querying phone field (more reliable than document ID)
      // Also check by document ID in case phone is used as document ID
      AppLogger.debug(
        '🔍 [DEBUG] Querying users collection by phone field: "$normalized"',
      );
      final queryByPhone = await usersRef
          .where('phone', isEqualTo: normalized)
          .limit(1)
          .get();

      AppLogger.debug(
        '🔍 [DEBUG] Query by phone field result: ${queryByPhone.docs.length} documents found',
      );

      DocumentSnapshot? userDoc;
      DocumentReference? userDocRef;

      if (queryByPhone.docs.isNotEmpty) {
        // User found by phone field
        userDoc = queryByPhone.docs.first;
        userDocRef = userDoc.reference;
        AppLogger.debug('🔍 [DEBUG] ✅ User found by phone field query');
        AppLogger.debug('🔍 [DEBUG] Document ID: ${userDoc.id}');
        AppLogger.info('User found by phone field query: ${userDoc.id}');
      } else {
        // Check by document ID (phone number might be document ID)
        AppLogger.debug(
          '🔍 [DEBUG] No user found by phone field, checking by document ID: "$normalized"',
        );
        final docRef = usersRef.doc(normalized);
        userDoc = await docRef.get();
        if (userDoc.exists) {
          userDocRef = docRef;
          AppLogger.debug('🔍 [DEBUG] ✅ User found by document ID');
          AppLogger.debug('🔍 [DEBUG] Document ID: ${userDoc.id}');
          AppLogger.info('User found by document ID: $normalized');
        } else {
          AppLogger.debug('🔍 [DEBUG] ❌ No user found by document ID either');
        }
      }

      if (userDoc.exists && userDocRef != null) {
        AppLogger.debug('🔍 [DEBUG] User document exists, checking PIN status...');
        final userData = userDoc.data() as Map<String, dynamic>?;
        AppLogger.debug('🔍 [DEBUG] User data keys: ${userData?.keys.toList()}');

        // Check if PIN exists - must have both hash and salt, and they must not be empty
        final pinHash = userData?['pinHash'] as String?;
        final pinSalt = userData?['pinSalt'] as String?;

        AppLogger.debug(
          '🔍 [DEBUG] PIN Hash: ${pinHash != null ? "present (type: ${pinHash.runtimeType}, length: ${pinHash.toString().length})" : "null"}',
        );
        AppLogger.debug(
          '🔍 [DEBUG] PIN Salt: ${pinSalt != null ? "present (type: ${pinSalt.runtimeType}, length: ${pinSalt.toString().length})" : "null"}',
        );

        if (pinHash != null) {
          AppLogger.debug(
            '🔍 [DEBUG] PIN Hash value (first 10 chars): ${pinHash.toString().substring(0, pinHash.toString().length > 10 ? 10 : pinHash.toString().length)}...',
          );
        }
        if (pinSalt != null) {
          AppLogger.debug(
            '🔍 [DEBUG] PIN Salt value (first 10 chars): ${pinSalt.toString().substring(0, pinSalt.toString().length > 10 ? 10 : pinSalt.toString().length)}...',
          );
        }

        final hasPin =
            pinHash != null &&
            pinHash.toString().trim().isNotEmpty &&
            pinSalt != null &&
            pinSalt.toString().trim().isNotEmpty;

        AppLogger.debug('🔍 [DEBUG] Has PIN check result: $hasPin');
        AppLogger.debug('🔍 [DEBUG] - pinHash != null: ${pinHash != null}');
        AppLogger.debug(
          '🔍 [DEBUG] - pinHash not empty: ${pinHash != null && pinHash.toString().trim().isNotEmpty}',
        );
        AppLogger.debug('🔍 [DEBUG] - pinSalt != null: ${pinSalt != null}');
        AppLogger.debug(
          '🔍 [DEBUG] - pinSalt not empty: ${pinSalt != null && pinSalt.toString().trim().isNotEmpty}',
        );

        AppLogger.info(
          'User document exists. PIN hash: ${pinHash != null ? "present (${pinHash.length} chars)" : "null"}, PIN salt: ${pinSalt != null ? "present (${pinSalt.length} chars)" : "null"}, Has PIN: $hasPin',
        );

        if (hasPin) {
          // User already exists with PIN - they should use Reset PIN instead
          AppLogger.debug('🔍 [DEBUG] ❌ User already has PIN set - returning false');
          AppLogger.warning(
            'Account already exists with PIN for phone $normalized. Use Reset PIN instead.',
          );
          return false;
        } else {
          AppLogger.debug(
            '🔍 [DEBUG] ✅ User exists but NO PIN - completing account setup',
          );
          // User document exists but no PIN set - complete the account setup
          AppLogger.debug('🔍 [DEBUG] Generating new PIN hash and salt...');
          AppLogger.info(
            'User document exists but no PIN set. Completing account setup for $normalized.',
          );

          // Generate salt and hash for PIN
          final salt = _generateSalt();
          final pinHash = _hashPin(pin, salt);
          AppLogger.debug('🔍 [DEBUG] Generated PIN hash (length: ${pinHash.length})');
          AppLogger.debug('🔍 [DEBUG] Generated PIN salt (length: ${salt.length})');

          // Update existing document with PIN and other missing fields
          final updateData = <String, dynamic>{
            'pinHash': pinHash,
            'pinSalt': salt,
            'pinUpdatedAt': FieldValue.serverTimestamp(),
          };

          // Only set fields if they don't exist or are empty
          if (userData?['firstName'] == null ||
              (userData?['firstName'] as String).isEmpty) {
            updateData['firstName'] = firstName;
          }
          if (userData?['lastName'] == null ||
              (userData?['lastName'] as String).isEmpty) {
            updateData['lastName'] = lastName ?? '';
          }
          if (userData?['role'] == null) {
            updateData['role'] = 'carpenter';
          }
          if (userData?['status'] == null) {
            updateData['status'] = 'verified';
          }
          if (userData?['totalPoints'] == null) {
            updateData['totalPoints'] = 0;
          }
          if (userData?['tier'] == null) {
            updateData['tier'] = 'Bronze';
          }
          if (userData?['createdAt'] == null) {
            updateData['createdAt'] = FieldValue.serverTimestamp();
          }
          if (userData?['verifiedAt'] == null) {
            updateData['verifiedAt'] = FieldValue.serverTimestamp();
          }
          if (userData?['verifiedBy'] == null) {
            updateData['verifiedBy'] = 'pin';
          }

          AppLogger.debug(
            '🔍 [DEBUG] Updating user document with PIN and other fields...',
          );
          AppLogger.debug('🔍 [DEBUG] Update data keys: ${updateData.keys.toList()}');
          await userDocRef.set(updateData, SetOptions(merge: true));
          AppLogger.debug('🔍 [DEBUG] ✅ User document updated successfully');

          // Ensure user_points document exists
          final userIdForPoints = userDoc.id; // Use the actual document ID
          AppLogger.debug(
            '🔍 [DEBUG] Checking user_points document for: $userIdForPoints',
          );
          final pointsDocRef = _firestore
              .collection('user_points')
              .doc(userIdForPoints);
          final pointsDoc = await pointsDocRef.get();
          if (!pointsDoc.exists) {
            AppLogger.debug('🔍 [DEBUG] Creating user_points document...');
            await pointsDocRef.set({
              'userId': userIdForPoints,
              'totalPoints': 0,
              'tier': 'Bronze',
              'lastUpdated': FieldValue.serverTimestamp(),
              'pointsHistory': [],
            });
            AppLogger.debug('🔍 [DEBUG] ✅ user_points document created');
          } else {
            AppLogger.debug('🔍 [DEBUG] user_points document already exists');
          }

          AppLogger.debug('🔍 [DEBUG] ✅ Account setup completed successfully');
          AppLogger.info(
            'Account setup completed for existing user: $normalized',
          );
          return true;
        }
      }

      // Generate unique display ID for user (e.g., #BP41)
      AppLogger.debug('🔍 [DEBUG] Generating user display ID...');
      final userDisplayId = await _getNextUserDisplayId();
      AppLogger.debug('🔍 [DEBUG] Generated user display ID: $userDisplayId');

      // Generate salt and hash for PIN
      AppLogger.debug('🔍 [DEBUG] Generating PIN hash and salt for new account...');
      final salt = _generateSalt();
      final pinHash = _hashPin(pin, salt);
      AppLogger.debug('🔍 [DEBUG] Generated PIN hash (length: ${pinHash.length})');
      AppLogger.debug('🔍 [DEBUG] Generated PIN salt (length: ${salt.length})');

      // Use batch write for atomic operation - both succeed or both fail
      AppLogger.debug('🔍 [DEBUG] Creating batch write operation...');
      final batch = _firestore.batch();

      // Create new account with phone as document ID
      final newUserDocRef = usersRef.doc(normalized);
      AppLogger.debug('🔍 [DEBUG] Setting user document with ID: $normalized');
      batch.set(newUserDocRef, {
        'phone': normalized, // Phone number is the unique identifier
        'userDisplayId': userDisplayId, // Display ID like 41 (shown as #BP41)
        'firstName': firstName,
        'lastName': lastName ?? '',
        'profileImage': profileImageUrl ?? '',
        'role': 'carpenter',
        'status': 'verified',
        'totalPoints': 0,
        'tier': 'Bronze',
        'createdAt': FieldValue.serverTimestamp(),
        'verifiedAt': FieldValue.serverTimestamp(),
        'verifiedBy': 'pin',
        'pinHash': pinHash,
        'pinSalt': salt,
        'pinUpdatedAt': FieldValue.serverTimestamp(),
      });

      // Initialize user_points document with same ID (phone number)
      final pointsDocRef = _firestore.collection('user_points').doc(normalized);
      batch.set(pointsDocRef, {
        'userId': normalized,
        'totalPoints': 0,
        'tier': 'Bronze',
        'lastUpdated': FieldValue.serverTimestamp(),
        'pointsHistory': [],
      });

      // Commit batch - atomic operation
      AppLogger.debug('🔍 [DEBUG] Committing batch write...');
      await batch.commit();
      AppLogger.debug('🔍 [DEBUG] ✅ Batch write committed successfully');

      AppLogger.debug('🔍 [DEBUG] ✅ New account created successfully: $normalized');
      AppLogger.info('New account created successfully: $normalized');
      return true;
    } on FirebaseException catch (e, st) {
      AppLogger.debug(
        '🔍 [DEBUG] ❌ Firebase ERROR creating account: ${e.code} - ${e.message}',
      );
      AppLogger.debug('🔍 [DEBUG] Stack trace: $st');
      AppLogger.error(
        'Firebase error creating account for phone $phone',
        e,
        st,
      );

      // Re-throw Firebase exceptions so they can be handled in UI
      if (e.code == 'permission-denied') {
        throw Exception(
          'Firebase permission denied. Please check Firestore rules or contact support.',
        );
      }
      throw Exception('Firebase error: ${e.message}');
    } catch (e, st) {
      AppLogger.debug('🔍 [DEBUG] ❌ ERROR creating account: $e');
      AppLogger.debug('🔍 [DEBUG] Stack trace: $st');
      AppLogger.error('Error creating account for phone $phone', e, st);
      rethrow; // Re-throw so UI can handle it
    }
  }
}
