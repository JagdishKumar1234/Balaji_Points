import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Placeholders must fit a phone-width field, so they stay short.
const _maxHintLength = 30;

void main() {
  test('every text field has a placeholder', () {
    final field = RegExp(r'\b(TextFormField|TextField|AppTextField)\(');
    final missing = <String>[];
    final files = Directory('lib/presentation')
        .listSync(recursive: true)
        .whereType<File>()
        .where((file) => file.path.endsWith('.dart'))
        // The shared widget passes through whatever its caller gives it.
        .where((file) => !file.path.endsWith('app_text_field.dart'));
    for (final file in files) {
      final source = file.readAsStringSync();
      for (final match in field.allMatches(source)) {
        var depth = 1;
        var end = match.end;
        while (depth > 0 && end < source.length) {
          if (source[end] == '(') depth++;
          if (source[end] == ')') depth--;
          end++;
        }
        final body = source.substring(match.end, end);
        if (!body.contains('hint')) {
          final line = '\n'.allMatches(source.substring(0, match.start)).length;
          missing.add('${file.path}:${line + 1}');
        }
      }
    }
    expect(missing, isEmpty);
  });

  test('placeholders say what to enter, not an example value', () {
    final strings =
        jsonDecode(File('lib/l10n/app_en.arb').readAsStringSync())
            as Map<String, dynamic>;
    for (final key in ['hintEmail', 'hintPhone', 'hintPin', 'hintAmount']) {
      expect(strings[key], startsWith('Enter'), reason: key);
    }
  });

  test('placeholder text is short in every language', () {
    const keys = [
      'descriptionHint',
      'enterGreetingMessageForAllCarpenters',
      'enterImageUrlJpgPng',
      'enterSiteLocationName',
      'enterVendorStoreNameOptional',
      'enterYourFirstName',
      'enterYourLastName',
      'enterFirstName',
      'enterLastName',
      'offerTitleHint',
      'phoneNumberHint',
      'pointsHint',
      'searchByNameEmailOrBranch',
      'searchByNameOrPhone',
      'enterPin',
      'exampleAr',
      'hintEmail',
      'hintPhone',
      'hintPin',
      'hintConfirmPin',
      'hintBranchId',
      'hintPassword',
      'hintPasswordMin',
      'hintConfirmPassword',
      'hintFullName',
      'hintAmount',
      'hintBranchFullName',
      'hintShortName',
      'hintBranchCode',
      'hintAddress',
      'hintRoleName',
    ];
    for (final language in ['en', 'hi', 'ta']) {
      final strings =
          jsonDecode(File('lib/l10n/app_$language.arb').readAsStringSync())
              as Map<String, dynamic>;
      for (final key in keys) {
        final value = strings[key] as String;
        expect(
          value.length,
          lessThanOrEqualTo(_maxHintLength),
          reason: '$language $key: $value',
        );
      }
    }
  });
}
