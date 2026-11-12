import 'package:balaji_points/services/telemetry/telemetry.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:google_sign_in/google_sign_in.dart';
import 'package:balaji_points/core/models/user.dart';
import 'package:balaji_points/core/constants/app_constants.dart';
import 'package:balaji_points/services/auth/pin_auth_service.dart';
import 'package:balaji_points/services/auth/admin_pin_sign_in_service.dart';
import 'package:balaji_points/services/auth/session_service.dart';
import 'package:balaji_points/services/notifications/fcm_service.dart';
import 'package:balaji_points/services/user/user_migration_service.dart';
import 'package:balaji_points/services/user/user_points_sync_service.dart';
import 'package:balaji_points/services/auth/role_service.dart';
import 'package:balaji_points/providers/home_provider.dart';
import 'package:balaji_points/providers/wallet_provider.dart';
import 'package:balaji_points/core/logger.dart';

// ─── Service providers ────────────────────────────────────────────────────────

final pinAuthServiceProvider = Provider<PinAuthService>(
  (_) => PinAuthService(),
);
final sessionServiceProvider = Provider<SessionService>(
  (_) => SessionService(),
);
final fcmServiceProvider = Provider<FCMService>((_) => FCMService());
final userMigrationServiceProvider = Provider<UserMigrationService>(
  (_) => UserMigrationService(),
);

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

class AuthPasswordResetSent extends AuthState {
  final String message;
  const AuthPasswordResetSent(this.message);
}

class AuthProfileCompletionRequired extends AuthState {
  final String email;
  final String displayName;
  final String? existingRole;
  const AuthProfileCompletionRequired({
    required this.email,
    required this.displayName,
    this.existingRole,
  });
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

  final firebase_auth.FirebaseAuth _firebaseAuth =
      firebase_auth.FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    clientId: kIsWeb ? AppConstants.googleWebClientId : null,
  );

  PinAuthService get _pin => ref.read(pinAuthServiceProvider);
  SessionService get _session => ref.read(sessionServiceProvider);
  FCMService get _fcm => ref.read(fcmServiceProvider);
  UserMigrationService get _migration => ref.read(userMigrationServiceProvider);

  // ── Check session on app start ──────────────────────────────────────────────

  Future<void> checkSession() async {
    try {
      final firebaseUser = _firebaseAuth.currentUser;
      if (firebaseUser != null) {
        await _finishFirebaseSignIn(firebaseUser, rememberMe: true);
        return;
      }

      final session = await _session.getSessionData();
      if (session.isNotEmpty && session['userId'] != null) {
        final user = User(
          id: session['userId'] ?? '',
          email: session['email'] ?? '',
          phoneNumber: session['phoneNumber'] ?? '',
          displayName: _displayName(session['firstName'], session['lastName']),
          role: session['role'] ?? 'carpenter',
          isEmailVerified: true,
          createdAt: DateTime.now(),
        );
        Telemetry.identify(
          userId: user.id,
          role: user.role,
          branchId: user.branchId,
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

  Future<void> loginWithEmailAndPassword({
    required String email,
    required String password,
    bool rememberMe = true,
  }) async {
    state = const AuthLoading();
    try {
      final normalizedEmail = email.trim();
      final userCredential = await _firebaseAuth.signInWithEmailAndPassword(
        email: normalizedEmail,
        // Firebase passwords are case- and whitespace-sensitive. Registration
        // stores the exact submitted password, so login must pass it unchanged.
        password: password,
      );

      final fbUser = userCredential.user;
      if (fbUser == null) {
        state = const AuthError('Unable to sign in. Please try again.');
        return;
      }

      await _finishFirebaseSignIn(
        fbUser,
        rememberMe: rememberMe,
        loginMethod: 'email',
      );
    } on firebase_auth.FirebaseAuthException catch (e) {
      AppLogger.error('Email login failed', e);
      state = AuthError(_messageFromFirebaseError(e));
    } catch (e) {
      AppLogger.error('Email login failed', e);
      state = AuthError('Login failed: $e');
    }
  }

  Future<void> loginWithGoogle({bool rememberMe = true}) async {
    state = const AuthLoading();
    try {
      if (kIsWeb) {
        // google_sign_in_web's legacy signIn() popup flow is deprecated and
        // can close before returning a token. Firebase Auth owns the web OAuth
        // popup flow and completes the Firebase credential exchange directly.
        final provider = firebase_auth.GoogleAuthProvider();
        final result = await _firebaseAuth.signInWithPopup(provider);
        final firebaseUser = result.user;
        if (firebaseUser == null) {
          state = const AuthError('Google sign in failed.');
          return;
        }

        await _finishFirebaseSignIn(
          firebaseUser,
          rememberMe: rememberMe,
          loginMethod: 'google',
        );
        return;
      }

      final googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        state = const AuthUnauthenticated();
        return;
      }

      final googleAuth = await googleUser.authentication;
      final credential = firebase_auth.GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final firebaseUser = (await _firebaseAuth.signInWithCredential(
        credential,
      )).user;
      if (firebaseUser == null) {
        state = const AuthError('Google sign in failed.');
        return;
      }

      await _finishFirebaseSignIn(
        firebaseUser,
        rememberMe: rememberMe,
        loginMethod: 'google',
      );
    } on firebase_auth.FirebaseAuthException catch (e) {
      AppLogger.error('Google login failed', e);
      state = AuthError(_messageFromFirebaseError(e));
    } catch (e) {
      AppLogger.error('Google login failed', e);
      state = AuthError('Google sign in failed: $e');
    }
  }

  Future<void> completeGoogleRegistration({
    required String firstName,
    required String lastName,
    required String phoneNumber,
    required String role,
    required String roleName,
    required String roleAbbreviation,
    required String branchId,
    String? termsVersion,
  }) async {
    state = const AuthLoading();
    try {
      final firebaseUser = _firebaseAuth.currentUser;
      if (firebaseUser == null || firebaseUser.email == null) {
        state = const AuthError('Google session expired. Sign in again.');
        return;
      }
      if (!await RoleService().isActiveSignupRole(role)) {
        state = const AuthError(
          'This role is no longer available. Choose another role.',
        );
        return;
      }

      final normalizedPhone = phoneNumber.replaceAll(RegExp(r'[^0-9]'), '');
      if (normalizedPhone.length != 10) {
        state = const AuthError('Please enter a valid 10-digit mobile number.');
        return;
      }

      final branchSnapshot = await _firestore
          .collection('branches')
          .doc(branchId)
          .get();
      if (!branchSnapshot.exists ||
          branchSnapshot.data()?['isActive'] != true) {
        state = const AuthError('Select an active branch to continue.');
        return;
      }
      final branchData = branchSnapshot.data()!;
      final branchCode =
          (branchData['branchCode'] as String? ?? '').trim().isNotEmpty
          ? (branchData['branchCode'] as String).trim()
          : branchId;
      final branchName = branchData['name'] as String? ?? branchId;
      final branchShortName = branchData['shortName'] as String? ?? branchName;

      final userRef = _firestore.collection('users').doc(firebaseUser.uid);
      final existing = await userRef.get();
      final existingRole = (existing.data()?['role'] as String?)?.trim();
      if (existingRole != null &&
          existingRole.isNotEmpty &&
          existingRole != role) {
        state = const AuthError(
          'A role is already assigned to this account. Contact your branch administrator to change it.',
        );
        return;
      }

      final duplicatePhone = await _firestore
          .collection('users')
          .where('phone', isEqualTo: normalizedPhone)
          .limit(2)
          .get();
      if (duplicatePhone.docs.any((doc) => doc.id != firebaseUser.uid)) {
        state = const AuthError(
          'This mobile number is already registered. Contact your branch administrator.',
        );
        return;
      }

      final fullName = '$firstName $lastName'.trim();
      final completionFields = <String, dynamic>{
        'firstName': firstName.trim(),
        'lastName': lastName.trim(),
        'phone': normalizedPhone,
        'phoneNumber': '+91$normalizedPhone',
        'role': role,
        'roleId': role,
        'roleName': roleName,
        'roleAbbreviation': roleAbbreviation,
        'branchId': branchId,
        'branchCode': branchCode,
        'branchName': branchName,
        'branchShortName': branchShortName,
        'status': 'verified',
        'profileCompletedAt': FieldValue.serverTimestamp(),
        // Terms & Conditions and Privacy Policy accepted at registration.
        if (termsVersion != null) 'termsVersion': termsVersion,
        if (termsVersion != null)
          'termsAcceptedAt': FieldValue.serverTimestamp(),
      };
      if (existing.exists) {
        await userRef.update(completionFields);
      } else {
        await userRef.set({
          ...completionFields,
          'uid': firebaseUser.uid,
          'userId': firebaseUser.uid,
          'email': firebaseUser.email!.trim(),
          'totalPoints': 0,
          'tier': 'Bronze',
          'createdAt': FieldValue.serverTimestamp(),
          'verifiedAt': FieldValue.serverTimestamp(),
          'verifiedBy': 'google-profile-completion',
        });
      }

      final pointsRef = _firestore
          .collection('user_points')
          .doc(firebaseUser.uid);
      final points = await pointsRef.get();
      if (!points.exists) {
        await pointsRef.set({
          'userId': firebaseUser.uid,
          'branchId': branchId,
          'branchCode': branchCode,
          'totalPoints': 0,
          'tier': 'Bronze',
          'lastUpdated': FieldValue.serverTimestamp(),
          'pointsHistory': <dynamic>[],
        });
      }

      await firebaseUser.updateDisplayName(fullName);
      await _session.saveSession(
        phoneNumber: normalizedPhone,
        userId: firebaseUser.uid,
        role: role,
        email: firebaseUser.email!.trim(),
        firstName: firstName.trim(),
        lastName: lastName.trim(),
        profileImage: firebaseUser.photoURL,
        branchId: branchId,
      );

      final user = User(
        id: firebaseUser.uid,
        email: firebaseUser.email!.trim(),
        phoneNumber: normalizedPhone,
        displayName: fullName,
        photoUrl: firebaseUser.photoURL,
        role: role,
        branchId: branchId,
        isEmailVerified: true,
        createdAt: firebaseUser.metadata.creationTime ?? DateTime.now(),
      );
      Telemetry.signUp(method: 'google');
      Telemetry.identify(
        userId: user.id,
        role: user.role,
        branchId: user.branchId,
      );
      state = AuthAuthenticated(user, role: role);
    } on firebase_auth.FirebaseAuthException catch (e) {
      AppLogger.error('Google profile completion failed', e);
      state = AuthError(_messageFromFirebaseError(e));
    } catch (e) {
      AppLogger.error('Google profile completion failed', e);
      state = AuthError('Unable to complete registration: $e');
    }
  }

  Future<void> cancelGoogleProfileCompletion() async {
    await _firebaseAuth.signOut();
    await _googleSignIn.signOut();
    state = const AuthUnauthenticated();
  }

  Future<void> _finishFirebaseSignIn(
    firebase_auth.User firebaseUser, {
    required bool rememberMe,
    String? loginMethod, // null when the app reopens with a saved session
  }) async {
    await _ensureConfiguredSuperAdminProfile(firebaseUser);
    final profile = await _findUserProfile(firebaseUser);
    final role =
        (profile?['role'] as String? ??
                profile?['roleId'] as String? ??
                profile?['userRole'] as String?)
            ?.trim();
    final branchId = profile?['branchId'] as String?;
    final phone =
        (profile?['phone'] as String? ??
                profile?['phoneNumber'] as String? ??
                await _session.getPhoneNumber() ??
                '')
            .replaceAll(RegExp(r'[^0-9]'), '');
    final isSuperAdmin = role == AppConstants.roleSuperAdmin;

    if (profile == null ||
        role == null ||
        role.isEmpty ||
        phone.length != 10 ||
        (!isSuperAdmin && (branchId == null || branchId.trim().isEmpty))) {
      state = AuthProfileCompletionRequired(
        email: firebaseUser.email ?? '',
        displayName:
            firebaseUser.displayName ??
            _displayNameFromEmail(firebaseUser.email),
        existingRole: role,
      );
      return;
    }

    if (!isSuperAdmin) {
      final branch = await _firestore
          .collection('branches')
          .doc(branchId)
          .get();
      if (!branch.exists || branch.data()?['isActive'] != true) {
        state = const AuthError(
          'Your assigned branch is inactive. Contact your administrator.',
        );
        return;
      }
    }

    final firstName =
        profile['firstName'] as String? ??
        firebaseUser.displayName?.split(' ').first ??
        _displayNameFromEmail(firebaseUser.email);
    final lastName = profile['lastName'] as String? ?? '';
    final displayName = '$firstName $lastName'.trim();
    final email = firebaseUser.email ?? '';
    final user = User(
      id: firebaseUser.uid,
      email: email,
      phoneNumber: phone,
      displayName: displayName.isEmpty ? 'User' : displayName,
      photoUrl: profile['profileImage'] as String? ?? firebaseUser.photoURL,
      role: role,
      branchId: branchId,
      isEmailVerified: firebaseUser.emailVerified,
      createdAt: firebaseUser.metadata.creationTime ?? DateTime.now(),
    );

    if (rememberMe) {
      await _session.saveSession(
        phoneNumber: phone,
        userId: firebaseUser.uid,
        role: role,
        email: email,
        firstName: firstName,
        lastName: lastName,
        profileImage: user.photoUrl,
        branchId: branchId,
      );
    }
    if (loginMethod != null) Telemetry.login(method: loginMethod);
    Telemetry.identify(
      userId: user.id,
      role: user.role,
      branchId: user.branchId,
    );
    state = AuthAuthenticated(user, role: role);
  }

  Future<Map<String, dynamic>?> _findUserProfile(
    firebase_auth.User firebaseUser,
  ) async {
    final byUid = await _firestore
        .collection('users')
        .doc(firebaseUser.uid)
        .get();
    if (byUid.exists) return byUid.data();

    final email = firebaseUser.email?.trim();
    if (email == null || email.isEmpty) return null;
    final byEmail = await _firestore
        .collection('users')
        .where('email', isEqualTo: email)
        .limit(1)
        .get();
    if (byEmail.docs.isEmpty) return null;
    return byEmail.docs.first.data();
  }

  Future<void> resetPassword({required String email}) async {
    state = const AuthLoading();
    try {
      await _firebaseAuth.sendPasswordResetEmail(email: email.trim());
      state = const AuthPasswordResetSent(
        'If an account exists for this email, password reset instructions have been sent.',
      );
    } on firebase_auth.FirebaseAuthException catch (e) {
      AppLogger.error('Password reset failed', e);
      if (e.code == 'user-not-found') {
        // Keep the response generic to avoid revealing whether an email is registered.
        state = const AuthPasswordResetSent(
          'If an account exists for this email, password reset instructions have been sent.',
        );
      } else {
        state = AuthError(_messageFromFirebaseError(e));
      }
    } catch (e) {
      AppLogger.error('Password reset failed', e);
      state = AuthError('Unable to send password reset email: $e');
    }
  }

  Future<void> registerWithEmailAndPassword({
    required String firstName,
    required String lastName,
    required String email,
    required String password,
    required String phoneNumber,
    required String role,
    required String roleName,
    required String roleAbbreviation,
    required String branchId,
    String? termsVersion,
  }) async {
    state = const AuthLoading();
    firebase_auth.User? createdUser;
    try {
      if (!await RoleService().isActiveSignupRole(role)) {
        state = const AuthError(
          'This role is no longer available. Choose another role.',
        );
        return;
      }

      final normalizedPhone = phoneNumber.replaceAll(RegExp(r'[^0-9]'), '');
      if (normalizedPhone.length != 10) {
        state = const AuthError('Please enter a valid 10-digit phone number.');
        return;
      }

      final branch = await _firestore
          .collection('branches')
          .doc(branchId)
          .get();
      if (!branch.exists || branch.data()?['isActive'] != true) {
        state = const AuthError('Please select an active branch.');
        return;
      }
      final branchData = branch.data()!;
      final branchCode =
          (branchData['branchCode'] as String? ?? '').trim().isNotEmpty
          ? (branchData['branchCode'] as String).trim()
          : branchId;
      final branchName = branchData['name'] as String? ?? branchId;
      final branchShortName = branchData['shortName'] as String? ?? branchName;

      final credential = await _firebaseAuth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      final registeredUser = credential.user;
      if (registeredUser == null) {
        state = const AuthError(
          'Unable to create your account. Please try again.',
        );
        return;
      }
      createdUser = registeredUser;

      final fullName = '$firstName $lastName'.trim();
      await registeredUser.updateDisplayName(fullName);

      final userRef = _firestore.collection('users').doc(registeredUser.uid);
      final pointsRef = _firestore
          .collection('user_points')
          .doc(registeredUser.uid);
      final batch = _firestore.batch();
      batch.set(userRef, {
        'uid': registeredUser.uid,
        'userId': registeredUser.uid,
        'firstName': firstName.trim(),
        'lastName': lastName.trim(),
        'email': email.trim(),
        'phone': normalizedPhone,
        'phoneNumber': '+91$normalizedPhone',
        'role': role,
        'roleId': role,
        'roleName': roleName,
        'roleAbbreviation': roleAbbreviation,
        'branchId': branchId,
        'branchCode': branchCode,
        'branchName': branchName,
        'branchShortName': branchShortName,
        'status': 'verified',
        'totalPoints': 0,
        'tier': 'Bronze',
        'createdAt': FieldValue.serverTimestamp(),
        'verifiedAt': FieldValue.serverTimestamp(),
        'verifiedBy': 'email-registration',
        // Terms & Conditions and Privacy Policy accepted at registration.
        if (termsVersion != null) 'termsVersion': termsVersion,
        if (termsVersion != null)
          'termsAcceptedAt': FieldValue.serverTimestamp(),
      });
      batch.set(pointsRef, {
        'userId': registeredUser.uid,
        'branchId': branchId,
        'branchCode': branchCode,
        'totalPoints': 0,
        'tier': 'Bronze',
        'lastUpdated': FieldValue.serverTimestamp(),
        'pointsHistory': <dynamic>[],
      });
      await batch.commit();

      await _session.saveSession(
        phoneNumber: normalizedPhone,
        userId: registeredUser.uid,
        role: role,
        email: email.trim(),
        firstName: firstName.trim(),
        lastName: lastName.trim(),
        branchId: branchId,
      );

      try {
        await _fcm.refreshTokenAfterLogin(
          uid: registeredUser.uid,
          phone: normalizedPhone,
        );
      } catch (e) {
        AppLogger.warning('FCM refresh after registration failed: $e');
      }

      final user = User(
        id: registeredUser.uid,
        email: email.trim(),
        phoneNumber: normalizedPhone,
        displayName: fullName,
        role: role,
        branchId: branchId,
        isEmailVerified: registeredUser.emailVerified,
        createdAt: registeredUser.metadata.creationTime ?? DateTime.now(),
      );
      Telemetry.signUp(method: 'email');
      Telemetry.identify(
        userId: user.id,
        role: user.role,
        branchId: user.branchId,
      );
      state = AuthAuthenticated(user, role: role);
    } on firebase_auth.FirebaseAuthException catch (e) {
      AppLogger.error('Email registration failed', e);
      final incompleteUser = createdUser;
      if (incompleteUser != null) {
        try {
          await incompleteUser.delete();
        } catch (cleanupError) {
          AppLogger.warning(
            'Unable to clean up incomplete registration: $cleanupError',
          );
        }
      }
      state = AuthError(_messageFromFirebaseError(e));
    } catch (e) {
      AppLogger.error('Email registration failed', e);
      final incompleteUser = createdUser;
      if (incompleteUser != null) {
        try {
          await incompleteUser.delete();
        } catch (cleanupError) {
          AppLogger.warning(
            'Unable to clean up incomplete registration: $cleanupError',
          );
        }
      }
      state = AuthError('Registration failed: $e');
    }
  }

  // ── Check if phone exists ───────────────────────────────────────────────────

  Future<void> checkUserExists(String phoneNumber) async {
    state = const AuthCheckingUser();
    try {
      final exists = await _pin.userExists(phoneNumber);
      state = exists
          ? AuthUserExists(phoneNumber)
          : AuthUserNotFound(phoneNumber);
    } catch (e) {
      AppLogger.error('Error checking user existence', e);
      state = AuthError('Error checking user: $e');
    }
  }

  /// Checks that a legacy account has a PIN before sending it to PIN login.
  Future<void> checkPinAccount(String phoneNumber) async {
    final normalized = _pin.normalizePhone(phoneNumber);
    if (normalized.length != 10) {
      state = const AuthError('Please enter a valid 10-digit mobile number.');
      return;
    }

    state = const AuthCheckingUser();
    try {
      final hasPin = await _pin.hasPin(normalized);
      state = hasPin
          ? AuthUserExists(normalized)
          : AuthUserNotFound(normalized);
    } catch (e) {
      AppLogger.error('Error checking legacy PIN account', e);
      state = const AuthError('Unable to check this mobile number. Try again.');
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

      final legacyDocId =
          userData['docId'] as String? ??
          userData['id'] as String? ??
          phoneNumber;
      // A branch admin also gets a real Firebase sign-in (checked on the
      // server), so admin-only data like their branch's enquiries can be
      // read. Done before the post-login step, which then uses this
      // sign-in for the admin's own record.
      final loginRole = (userData['role'] as String? ?? '').toLowerCase();
      if (loginRole == AppConstants.roleAdmin) {
        await AdminPinSignInService().signIn(phone: phoneNumber, pin: pin);
      }
      final postLogin = await _migration.completePostPinLogin(
        phone: phoneNumber,
        legacyDocId: legacyDocId,
      );
      final userId =
          postLogin?.firebaseUid ??
          postLogin?.sessionUserId ??
          userData['id'] as String? ??
          phoneNumber;

      if (rememberMe) {
        await _session.saveSession(
          phoneNumber: phoneNumber,
          userId: userId,
          role: userData['role'] as String? ?? 'carpenter',
          firstName: userData['firstName'] as String?,
          lastName: userData['lastName'] as String?,
          branchId: userData['branchId'] as String?,
          pinHash: userData['pinHash'] as String?,
        );
      }

      if (postLogin != null) {
        try {
          await _fcm.refreshTokenAfterLogin(
            uid: postLogin.firebaseUid,
            phone: postLogin.phone,
          );
        } catch (e) {
          AppLogger.warning('FCM refresh after login failed: $e');
        }
      }

      final role = userData['role'] as String? ?? 'carpenter';
      final user = User(
        id: userId,
        email: userData['email'] as String? ?? '',
        phoneNumber: phoneNumber,
        displayName: _displayName(
          userData['firstName'] as String?,
          userData['lastName'] as String?,
        ),
        photoUrl: userData['profileImage'] as String?,
        role: role,
        isEmailVerified: true,
        createdAt: DateTime.now(),
      );

      if (AppConstants.isMemberRole(role)) {
        ref.invalidate(homeProvider);
        ref.invalidate(walletProvider);
        await ref.read(carpenterPointsProvider.notifier).prepareForSession();
      }

      AppLogger.auth('Login: ${user.displayName} · $role');
      Telemetry.login(method: 'pin');
      Telemetry.identify(
        userId: user.id,
        role: user.role,
        branchId: user.branchId,
      );
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
    String? role,
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
        role: role,
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

      final legacyDocId =
          userData['docId'] as String? ??
          userData['id'] as String? ??
          phoneNumber;
      final postLogin = await _migration.completePostPinLogin(
        phone: phoneNumber,
        legacyDocId: legacyDocId,
      );
      final userId =
          postLogin?.firebaseUid ??
          postLogin?.sessionUserId ??
          userData['id'] as String? ??
          phoneNumber;

      await _session.saveSession(
        phoneNumber: phoneNumber,
        userId: userId,
        role: userData['role'] as String? ?? 'carpenter',
        firstName: userData['firstName'] as String?,
        lastName: userData['lastName'] as String?,
        branchId: userData['branchId'] as String? ?? branchId,
        pinHash: userData['pinHash'] as String?,
      );

      if (postLogin != null) {
        try {
          await _fcm.refreshTokenAfterLogin(
            uid: postLogin.firebaseUid,
            phone: postLogin.phone,
          );
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
      final success = await _pin.setPinForPhone(
        phone: phoneNumber,
        pin: newPin,
      );
      if (success) {
        final storedPhone = await _session.getPhoneNumber();
        if (storedPhone != null && storedPhone.trim() == phoneNumber.trim()) {
          final updatedUserData = await _pin.verifyPin(
            phone: phoneNumber,
            pin: newPin,
          );
          final newHash = updatedUserData?['pinHash'] as String?;
          if (newHash != null && newHash.isNotEmpty) {
            await _session.setPinHash(newHash);
          }
        }
        state = const ResetPinSuccess();
        await Future.delayed(const Duration(milliseconds: 100));
        state = const AuthInitial();
      } else {
        state = const ResetPinError('Failed to reset PIN');
      }
    } catch (e) {
      AppLogger.error('PIN reset failed', e);
      state = ResetPinError('PIN reset failed: $e');
    }
  }

  void resetToInitial() {
    state = const AuthInitial();
  }

  // ── Logout ──────────────────────────────────────────────────────────────────

  Future<void> logout() async {
    try {
      await _firebaseAuth.signOut();
      await _googleSignIn.signOut();
      ref.read(carpenterPointsProvider.notifier).resetForLogout();
      ref.invalidate(homeProvider);
      ref.invalidate(walletProvider);
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

  String _displayNameFromEmail(String? email) {
    if (email == null || email.isEmpty) return 'User';
    final local = email.split('@').first.trim();
    return local.isEmpty ? 'User' : local;
  }

  String _messageFromFirebaseError(firebase_auth.FirebaseAuthException e) {
    switch (e.code) {
      case 'invalid-email':
        return 'Please enter a valid email address.';
      case 'user-not-found':
        return 'No account found for this email.';
      case 'wrong-password':
        return 'Incorrect password. Please try again.';
      case 'too-many-requests':
        return 'Too many attempts. Please try again later.';
      case 'email-already-in-use':
        return 'This email address is already in use.';
      case 'weak-password':
        return 'Password is too weak. Use a stronger password.';
      case 'account-exists-with-different-credential':
        return 'This account already exists with a different sign-in method.';
      default:
        return e.message ?? 'Authentication failed. Please try again.';
    }
  }

  Future<void> _ensureConfiguredSuperAdminProfile(
    firebase_auth.User firebaseUser,
  ) async {
    final email = firebaseUser.email?.trim().toLowerCase();
    AppLogger.info(
      'Checking configured super-admin identity: email=$email uid=${firebaseUser.uid}',
    );
    if (email != AppConstants.superAdminEmail.toLowerCase()) return;

    if (!firebaseUser.emailVerified) {
      await _firebaseAuth.signOut();
      throw StateError(
        'The configured super admin account must have a verified email. Sign in with Google or verify the email first.',
      );
    }

    final userRef = _firestore.collection('users').doc(firebaseUser.uid);
    final existing = await userRef.get();
    final profile = <String, dynamic>{
      'uid': firebaseUser.uid,
      'userId': firebaseUser.uid,
      'email': AppConstants.superAdminEmail,
      'firstName': 'Jagdish',
      'lastName': 'Kumar',
      'phone': AppConstants.superAdminPhone,
      'phoneNumber': AppConstants.superAdminPhoneE164,
      'role': AppConstants.roleSuperAdmin,
      'branchId': null,
      'status': 'active',
      'lastLoginAt': FieldValue.serverTimestamp(),
      'verifiedBy': 'configured-super-admin',
    };
    if (!existing.exists) {
      profile.addAll({
        'totalPoints': 0,
        'tier': 'Bronze',
        'createdAt': FieldValue.serverTimestamp(),
      });
    }

    await userRef.set(profile, SetOptions(merge: true));
    if (firebaseUser.displayName != 'Jagdish Kumar') {
      await firebaseUser.updateDisplayName('Jagdish Kumar');
    }
    AppLogger.auth('Configured super admin profile ensured for $email');
  }
}

// ─── Provider ─────────────────────────────────────────────────────────────────

final authProvider = NotifierProvider<AuthNotifier, AuthState>(
  () => AuthNotifier(),
);
