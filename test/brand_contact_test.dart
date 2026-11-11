import 'dart:io';

import 'package:balaji_points/core/constants/app_constants.dart';
import 'package:balaji_points/core/legal/legal_documents.dart';
import 'package:flutter_test/flutter_test.dart';

/// The company is "Balaji Points" and support is one email and phone,
/// everywhere. Store names such as "Sri Balaji Plywood and Hardware" are
/// branches, not the company.
void main() {
  test('one company name and support contact', () {
    expect(AppConstants.companyName, 'Balaji Points');
    expect(AppConstants.supportEmail, 'aaijitechstudio@gmail.com');
    expect(AppConstants.supportPhone, '8947038661');
    expect(AppConstants.supportPhoneE164, '+918947038661');
    expect(LegalDocuments.company, AppConstants.companyName);
    expect(LegalDocuments.supportEmail, AppConstants.supportEmail);
  });

  test('no screen shows the store as the company or old store numbers', () {
    final banned = RegExp(
      r"Sri Balaji Plywood|Shri Balaji Plywood|Balaji Hardware'|"
      r'96006|3557187|support@balajipoints',
    );
    final offenders = <String>[];
    for (final f in Directory('lib/presentation').listSync(recursive: true)) {
      if (f is! File || !f.path.endsWith('.dart')) continue;
      if (banned.hasMatch(f.readAsStringSync())) offenders.add(f.path);
    }
    for (final lang in ['en', 'hi', 'ta']) {
      final arb = File('lib/l10n/app_$lang.arb').readAsStringSync();
      if (banned.hasMatch(arb)) offenders.add('app_$lang.arb');
      // The company name is the brand in every language.
      final company = RegExp(r'"companyName": "([^"]*)"').firstMatch(arb)!;
      final app = RegExp(r'"appName": "([^"]*)"').firstMatch(arb)!;
      if (company.group(1) != app.group(1)) offenders.add('app_$lang.arb');
    }
    expect(offenders, isEmpty);
  });
}
