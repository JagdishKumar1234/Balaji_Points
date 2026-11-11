import 'dart:io';

import 'package:balaji_points/core/firebase/test_emulators.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('normal builds are not in test mode', () {
    expect(TestEmulators.enabled, isFalse);
  });

  test(
    'test mode is refused in release builds and never falls back to live',
    () {
      final mode = File(
        'lib/core/firebase/test_emulators.dart',
      ).readAsStringSync();
      expect(mode, contains('if (kReleaseMode)'));
      expect(mode, contains("bool.fromEnvironment('USE_FIREBASE_EMULATORS')"));
      final main = File('lib/main.dart').readAsStringSync();
      expect(main, contains('await TestEmulators.connectIfRequested();'));
      expect(main, contains('TestEmulators.enabled && snapshot.hasError'));
      expect(
        main,
        contains('if (!TestEmulators.enabled) await _startTelemetry();'),
      );
    },
  );
}
