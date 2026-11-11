import 'package:balaji_points/core/design/app_theme.dart';
import 'package:balaji_points/core/firebase/app_firestore.dart';
import 'package:balaji_points/l10n/app_localizations.dart';
import 'package:balaji_points/presentation/screens/super_admin/super_admin_create_admin_tab.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';

void main() {
  GoogleFonts.config.allowRuntimeFetching = false;

  for (final width in [360.0, 1280.0]) {
    testWidgets(
      'Admins tab lists admins first, then Add admin opens the form (${width.toInt()}px)',
      (tester) async {
        final db = FakeFirebaseFirestore();
        await db.collection('branches').doc('b1').set({
          'name': 'Karur',
          'isActive': true,
        });
        await db.collection('users').doc('a1').set({
          'role': 'admin',
          'firstName': 'Ravi',
          'lastName': 'Kumar',
          'email': 'ravi@example.com',
          'branchId': 'b1',
        });
        overrideAppFirestoreForTesting(db);
        addTearDown(() => overrideAppFirestoreForTesting(null));

        tester.view.physicalSize = Size(width, 900);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        await tester.pumpWidget(
          MaterialApp(
            theme: AppThemeData.light(),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: const Scaffold(body: SuperAdminCreateAdminTab()),
          ),
        );
        await tester.pumpAndSettle();

        // List comes first; the form is not on the page.
        expect(find.text('Ravi Kumar'), findsOneWidget);
        expect(find.text('Create admin account'), findsNothing);

        // Controls live in the ⋮ menu.
        await tester.tap(find.byIcon(Icons.more_vert_rounded));
        await tester.pumpAndSettle();
        expect(find.text('Change password'), findsOneWidget);
        expect(find.text('Delete account'), findsOneWidget);
        await tester.tapAt(const Offset(5, 5));
        await tester.pumpAndSettle();

        await tester.tap(find.text('Add admin'));
        await tester.pumpAndSettle();
        expect(find.text('Create admin account'), findsOneWidget);
        expect(tester.takeException(), isNull);

        await tester.tap(find.byIcon(Icons.close_rounded));
        await tester.pumpAndSettle();
        expect(find.text('Create admin account'), findsNothing);
      },
    );
  }
}
