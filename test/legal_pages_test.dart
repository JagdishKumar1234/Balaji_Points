import 'dart:io';

import 'package:balaji_points/core/design/app_theme.dart';
import 'package:balaji_points/core/legal/legal_documents.dart';
import 'package:balaji_points/l10n/app_localizations.dart';
import 'package:balaji_points/presentation/screens/common/info/legal_document_page.dart';
import 'package:balaji_points/presentation/widgets/shared/legal_consent_checkbox.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';

Widget _app(Widget child) => MaterialApp(
  theme: AppThemeData.light(),
  localizationsDelegates: AppLocalizations.localizationsDelegates,
  supportedLocales: AppLocalizations.supportedLocales,
  home: child,
);

void main() {
  GoogleFonts.config.allowRuntimeFetching = false;

  for (final doc in LegalDocument.values) {
    testWidgets('${doc.name} page shows every section', (tester) async {
      await tester.pumpWidget(_app(LegalDocumentPage(document: doc)));
      await tester.pump();
      final sections = doc == LegalDocument.terms
          ? LegalDocuments.terms
          : LegalDocuments.privacy;
      for (final s in sections) {
        await tester.scrollUntilVisible(
          find.text(s.title),
          300,
          scrollable: find.byType(Scrollable).last,
        );
        expect(find.text(s.title), findsOneWidget);
      }
      expect(tester.takeException(), isNull);
    });
  }

  test('legal texts name the contact and have no empty sections', () {
    for (final s in [...LegalDocuments.terms, ...LegalDocuments.privacy]) {
      expect(s.title.trim(), isNotEmpty);
      expect(s.body.trim(), isNotEmpty);
    }
    final privacy = LegalDocuments.privacy.map((s) => s.body).join();
    expect(privacy, contains(LegalDocuments.supportEmail));
  });

  testWidgets('consent shows an error until ticked', (tester) async {
    var value = false;
    var showError = true;
    await tester.pumpWidget(
      _app(
        StatefulBuilder(
          builder: (context, setState) => Scaffold(
            body: LegalConsentCheckbox(
              value: value,
              showError: showError,
              onChanged: (v) => setState(() => value = v),
            ),
          ),
        ),
      ),
    );
    expect(
      find.text(
        'Please accept the Terms & Conditions and Privacy Policy to continue.',
      ),
      findsOneWidget,
    );
    await tester.tap(find.byKey(const ValueKey('legal-consent')));
    await tester.pump();
    expect(value, isTrue);
    expect(
      find.text(
        'Please accept the Terms & Conditions and Privacy Policy to continue.',
      ),
      findsNothing,
    );
  });

  test('both registration paths require consent and save the version', () {
    final page = File(
      'lib/presentation/screens/common/auth/register_page.dart',
    ).readAsStringSync();
    expect(page, contains('LegalConsentCheckbox('));
    expect(page, contains('if (!formOk || !_acceptedTerms) return;'));
    expect('termsVersion: LegalDocuments.version'.allMatches(page).length, 2);
    final auth = File('lib/providers/auth_provider.dart').readAsStringSync();
    expect(
      "'termsAcceptedAt': FieldValue.serverTimestamp()".allMatches(auth).length,
      2,
    );
  });
}
