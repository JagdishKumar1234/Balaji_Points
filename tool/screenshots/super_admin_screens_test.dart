// Visual QA harness for the Super Admin panel (not part of `flutter test`).
//
//   flutter test tool/screenshots/super_admin_screens_test.dart \
//     --dart-define=SHOT_DIR=/path/to/output
//
// Renders the real SuperAdminPage on a fake Firestore with sample data at
// phone / tablet / desktop sizes in light and dark, and writes PNGs.
import 'dart:io';
import 'dart:ui' as ui;

import 'package:balaji_points/core/design/app_theme.dart';
import 'package:balaji_points/core/firebase/app_firestore.dart';
import 'package:balaji_points/l10n/app_localizations.dart';
import 'package:balaji_points/presentation/screens/super_admin/super_admin_page.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

const outDir = String.fromEnvironment('SHOT_DIR', defaultValue: 'build/screenshots');
const sdkFonts = String.fromEnvironment('SDK_FONTS');

Future<void> _loadFont(String family, String path) async {
  final bytes = File(path).readAsBytesSync();
  final loader = FontLoader(family)..addFont(Future.value(ByteData.view(bytes.buffer)));
  await loader.load();
}

Future<void> _seed(FakeFirebaseFirestore db) async {
  final branches = db.collection('branches');
  await branches.doc('erode_main').set({
    'name': 'Sri Balaji Plywood and Hardware - Erode Main Road',
    'shortName': 'Erode Main',
    'branchCode': 'ERD-01',
    'address': '42, Perundurai Road, Near Bus Stand, Erode, Tamil Nadu 638011',
    'phone': '9876543210',
    'isActive': true,
    'diwaliCelebrationEnabled': true,
  });
  await branches.doc('karur').set({
    'name': 'Sri Balaji Plywood and Hardware - Karur',
    'shortName': 'Karur',
    'branchCode': 'KRR-02',
    'address': 'Jawahar Bazaar, Karur',
    'phone': '9876500000',
    'isActive': true,
    'diwaliCelebrationEnabled': false,
  });
  await branches.doc('salem').set({
    'name': 'Salem Branch',
    'shortName': '',
    'branchCode': 'SLM-03',
    'address': '',
    'phone': '',
    'isActive': false,
    'diwaliCelebrationEnabled': false,
  });
  final users = db.collection('users');
  await users.doc('a1').set({
    'role': 'admin', 'firstName': 'Ravi', 'lastName': 'Kumar',
    'email': 'ravi.kumar@balajipoints.in', 'branchId': 'erode_main', 'branchName': 'Erode Main',
  });
  await users.doc('a2').set({
    'role': 'admin', 'firstName': 'Priya', 'lastName': 'S',
    'email': 'priya@balajipoints.in', 'branchId': 'karur', 'branchName': 'Karur',
  });
  await db.collection('roles').doc('mason').set({
    'roleId': 'mason', 'name': 'Mason', 'abbreviation': 'Ms.', 'isActive': true, 'isBuiltIn': false,
  });
  await db.collection('roles').doc('architect').set({
    'roleId': 'architect', 'name': 'Architect', 'abbreviation': 'Ar.', 'isActive': false, 'isBuiltIn': true,
  });
}

void main() {
  GoogleFonts.config.allowRuntimeFetching = false;

  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    if (sdkFonts.isNotEmpty) {
      await _loadFont('MaterialIcons', '$sdkFonts/MaterialIcons-Regular.otf');
    }
    Directory(outDir).createSync(recursive: true);
  });

  const sizes = {'phone': Size(390, 844), 'tablet': Size(900, 1000), 'desktop': Size(1366, 900)};
  const tabs = ['branches', 'create_admin', 'points', 'roles'];

  for (final size in sizes.entries) {
    for (final dark in [false, true]) {
      testWidgets('${size.key} ${dark ? 'dark' : 'light'}', (tester) async {
        SharedPreferences.setMockInitialValues({});
        final db = FakeFirebaseFirestore();
        await _seed(db);
        overrideAppFirestoreForTesting(db);
        addTearDown(() => overrideAppFirestoreForTesting(null));

        tester.view.physicalSize = size.value;
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        final key = GlobalKey();
        await tester.pumpWidget(
          ProviderScope(
            child: RepaintBoundary(
              key: key,
              child: MaterialApp(
                debugShowCheckedModeBanner: false,
                theme: AppThemeData.light(),
                darkTheme: AppThemeData.dark(),
                themeMode: dark ? ThemeMode.dark : ThemeMode.light,
                localizationsDelegates: AppLocalizations.localizationsDelegates,
                supportedLocales: AppLocalizations.supportedLocales,
                home: const SuperAdminPage(),
              ),
            ),
          ),
        );
        await tester.runAsync(() => GoogleFonts.pendingFonts());

        Future<void> shot(String name) async {
          final boundary = tester.renderObject<RenderRepaintBoundary>(find.byKey(key));
          final bytes = await tester.runAsync(() async {
            final image = await boundary.toImage(pixelRatio: 1);
            final data = await image.toByteData(format: ui.ImageByteFormat.png);
            return data!.buffer.asUint8List();
          });
          File('$outDir/$name').writeAsBytesSync(bytes!);
          final err = tester.takeException();
          if (err != null) debugPrint('LAYOUT ERROR in $name: $err');
        }

        for (var i = 0; i < tabs.length; i++) {
          if (i > 0) {
            final wide = size.value.width >= 840;
            final target = wide ? find.byType(NavigationRail) : find.byType(NavigationBar);
            if (wide) {
              final rail = tester.widget<NavigationRail>(target);
              rail.onDestinationSelected!(i);
            } else {
              final bar = tester.widget<NavigationBar>(target);
              bar.onDestinationSelected!(i);
            }
          }
          for (var k = 0; k < 8; k++) {
            await tester.runAsync(() => Future.delayed(const Duration(milliseconds: 30)));
            await tester.pump(const Duration(milliseconds: 100));
          }
          await shot('${size.key}_${dark ? 'dark' : 'light'}_${tabs[i]}.png');
          if (tabs[i] == 'create_admin') {
            await tester.tap(find.byIcon(Icons.person_add_alt_1_rounded));
            for (var k = 0; k < 8; k++) {
              await tester.runAsync(() => Future.delayed(const Duration(milliseconds: 30)));
              await tester.pump(const Duration(milliseconds: 100));
            }
            await shot('${size.key}_${dark ? 'dark' : 'light'}_add_admin_dialog.png');
            await tester.tap(find.byIcon(Icons.close_rounded).last);
            await tester.pumpAndSettle();
          }
        }
      });
    }
  }
}
