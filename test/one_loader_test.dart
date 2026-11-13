import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Every screen uses the app's one loader widget (AppLoader). A raw
/// CircularProgressIndicator is allowed only in AppLoader itself and where
/// it shows real progress (`value:`), e.g. an upload percentage.
void main() {
  test('no screen draws its own spinner', () {
    final offenders = <String>[];
    for (final f in Directory('lib').listSync(recursive: true)) {
      if (f is! File || !f.path.endsWith('.dart')) continue;
      if (f.path.endsWith('widgets/shared/app_loader.dart')) continue;
      final s = f.readAsStringSync();
      var i = s.indexOf('CircularProgressIndicator(');
      while (i >= 0) {
        // The arguments right after the call (enough for a value:).
        final call = s.substring(i, (i + 300).clamp(0, s.length));
        if (!call.contains('value:')) offenders.add(f.path);
        i = s.indexOf('CircularProgressIndicator(', i + 1);
      }
    }
    expect(offenders, isEmpty);
  });
}
