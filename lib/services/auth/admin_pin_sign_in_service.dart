import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../core/logger.dart';

/// Gives a branch admin who logs in with phone + PIN a real Firebase
/// sign-in, the same as an email admin. Without it the security rules
/// cannot tell the admin apart from anyone else, so admin-only data such as
/// their branch's enquiries is refused.
///
/// The PIN just typed is sent once to the `adminPinSignIn` function, which
/// checks it on the server and returns a sign-in token for the admin's own
/// user record. Never throws: if it fails, PIN login still works as before,
/// only the admin-only screens stay locked.
class AdminPinSignInService {
  AdminPinSignInService({FirebaseFunctions? functions, FirebaseAuth? auth})
    : _functions =
          functions ?? FirebaseFunctions.instanceFor(region: 'us-central1'),
      _auth = auth ?? FirebaseAuth.instance;

  final FirebaseFunctions _functions;
  final FirebaseAuth _auth;

  /// Returns the signed-in uid, or null when it could not sign in.
  Future<String?> signIn({required String phone, required String pin}) async {
    try {
      final res = await _functions
          .httpsCallable('adminPinSignIn')
          .call<Map<String, dynamic>>({'phone': phone, 'pin': pin});
      final token = res.data['token'] as String?;
      if (token == null || token.isEmpty) return null;
      final cred = await _auth.signInWithCustomToken(token);
      AppLogger.info('Admin PIN sign-in: ${cred.user?.uid}');
      return cred.user?.uid;
    } on FirebaseFunctionsException catch (e) {
      AppLogger.warning('Admin PIN sign-in refused: ${e.code} ${e.message}');
      return null;
    } catch (e) {
      AppLogger.warning('Admin PIN sign-in failed: $e');
      return null;
    }
  }
}
