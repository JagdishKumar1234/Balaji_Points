import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// Test builds made with `--dart-define=USE_FIREBASE_EMULATORS=true` use a
/// private copy of Firebase running on the developer's computer (the Firebase
/// Local Emulator Suite) instead of live data.
class TestEmulators {
  TestEmulators._();

  static const bool enabled = bool.fromEnvironment('USE_FIREBASE_EMULATORS');

  /// Live Firebase has anonymous sign-in turned off, but the local Auth
  /// emulator always allows it. Test mode skips it so PIN logins behave
  /// exactly as they do in live.
  static bool get blocksAnonymousSignIn => enabled;

  /// Connects every Firebase service to the local emulators. Must run right
  /// after `Firebase.initializeApp` and before any other Firebase call.
  ///
  /// Release builds refuse to run in test mode, and any failure stops the
  /// app, so a test build can never quietly fall back to live data.
  static Future<void> connectIfRequested() async {
    if (!enabled) return;
    if (kReleaseMode) {
      throw StateError('Test mode is not allowed in release builds.');
    }
    // Ports are forwarded to the computer with `adb reverse`, so the device
    // reaches the emulators on its own 127.0.0.1.
    const host = '127.0.0.1';
    FirebaseFirestore.instance.useFirestoreEmulator(
      host,
      8080,
      automaticHostMapping: false,
    );
    FirebaseFirestore.instance.settings = const Settings(
      persistenceEnabled: false,
    );
    await FirebaseAuth.instance.useAuthEmulator(
      host,
      9099,
      automaticHostMapping: false,
    );
    FirebaseFunctions.instanceFor(
      region: 'us-central1',
    ).useFunctionsEmulator(host, 5001, automaticHostMapping: false);
    await FirebaseStorage.instance.useStorageEmulator(
      host,
      9199,
      automaticHostMapping: false,
    );
  }

  /// A red strip on every screen, so a test build is never mistaken for live.
  static Widget banner(Widget child) {
    if (!enabled) return child;
    return Banner(
      message: 'TEST MODE',
      location: BannerLocation.topEnd,
      color: Colors.red,
      child: child,
    );
  }
}
