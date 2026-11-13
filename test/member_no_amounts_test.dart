import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Members never see a rupee amount. (They still type the bill amount on
/// Add Bill; points are worked out from it.)
void main() {
  test('no rupee figure is shown on any member screen', () {
    final problems = <String>[];
    final files = [
      ...Directory(
        'lib/presentation/screens/carpenter',
      ).listSync(recursive: true),
      ...Directory(
        'lib/presentation/widgets/carpenter',
      ).listSync(recursive: true),
    ].whereType<File>().where((f) => f.path.endsWith('.dart'));
    for (final file in files) {
      final lines = file.readAsLinesSync();
      for (var i = 0; i < lines.length; i++) {
        final line = lines[i].trim();
        if (line.startsWith('//') || line.startsWith('///')) continue;
        if (line.contains('₹') ||
            line.contains('NumberFormat.currency') ||
            line.contains('Icons.currency_rupee_rounded') &&
                !file.path.endsWith('add_bill_page.dart')) {
          problems.add('${file.path}:${i + 1}');
        }
      }
    }
    expect(problems, isEmpty);
  });

  test('the duplicate-bill warning on Add Bill shows no amount', () {
    final source = File(
      'lib/presentation/screens/carpenter/bills/add_bill_page.dart',
    ).readAsStringSync();
    expect(source, isNot(contains("duplicateBill['amount']")));
    // The only rupee icon left is the amount input field.
    expect('Icons.currency_rupee_rounded'.allMatches(source).length, 1);
  });

  test('a member bill needs a photo before it can be submitted', () {
    final source = File(
      'lib/presentation/screens/carpenter/bills/add_bill_page.dart',
    ).readAsStringSync();
    expect(source, contains('if (_selectedImageBytes == null) {'));
    expect(source, contains('.uploadBillPhoto'));
    final check = source.indexOf('if (_selectedImageBytes == null) {');
    final save = source.indexOf('setState(() => _isSubmitting = true);');
    expect(check, lessThan(save), reason: 'checked before anything is saved');
  });
}
