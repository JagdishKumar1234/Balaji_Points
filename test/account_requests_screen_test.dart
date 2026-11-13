import 'package:balaji_points/core/design/app_theme.dart';
import 'package:balaji_points/l10n/app_localizations.dart';
import 'package:balaji_points/presentation/screens/admin/account_requests_screen.dart';
import 'package:balaji_points/services/auth/account_approval_service.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';

void main() {
  GoogleFonts.config.allowRuntimeFetching = false;

  testWidgets('each request card shows the member role and group', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 2400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final db = FakeFirebaseFirestore();
    final people = {
      'c': ('Chitra', 'carpenter'),
      'i': ('Indu', 'interior_designer'),
      'a': ('Arun', 'architect'),
      'e': ('Ezhil', 'engineer'),
    };
    for (final MapEntry(key: id, value: (name, role)) in people.entries) {
      await db.collection('users').doc(id).set({
        'firstName': name,
        'role': role,
        'branchId': 'b1',
        'phone': '90000000$id'.padRight(10, '0'),
        'profile_verified': false,
        'approvalStatus': 'pending',
      });
    }
    // Another branch's request never shows.
    await db.collection('users').doc('x').set({
      'firstName': 'Other',
      'role': 'carpenter',
      'branchId': 'b2',
      'profile_verified': false,
    });

    await tester.pumpWidget(
      MaterialApp(
        theme: AppThemeData.light(),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: AccountRequestsScreen(
          service: AccountApprovalService(firestore: db),
          branchIdForTest: 'b1',
        ),
      ),
    );
    await tester.pumpAndSettle();

    for (final id in people.keys) {
      expect(find.byKey(ValueKey('request-$id')), findsOneWidget);
    }
    expect(find.byKey(const ValueKey('request-x')), findsNothing);

    Finder inCard(String id, String text) => find.descendant(
      of: find.byKey(ValueKey('request-$id')),
      matching: find.text(text),
    );
    expect(inCard('c', 'Carpenter'), findsOneWidget);
    expect(inCard('i', 'Interior designer'), findsOneWidget);
    expect(inCard('a', 'Architect'), findsOneWidget);
    expect(inCard('e', 'Engineer'), findsOneWidget);
    expect(inCard('c', 'Carpenter & Interior'), findsOneWidget);
    expect(inCard('a', 'Architect & Engineer'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
