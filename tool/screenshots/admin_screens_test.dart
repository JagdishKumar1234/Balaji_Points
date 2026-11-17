// Visual QA harness for the branch admin dashboard and admin notifications
// (not part of `flutter test`).
//
//   flutter test tool/screenshots/admin_screens_test.dart \
//     --dart-define=SHOT_DIR=/path/to/output \
//     --dart-define=SDK_FONTS=$FLUTTER_ROOT/bin/cache/artifacts/material_fonts
//
// Renders the real widgets on a fake Firestore with sample data.
import 'dart:io';
import 'dart:ui' as ui;

import 'package:balaji_points/core/design/app_theme.dart';
import 'package:balaji_points/core/firebase/app_firestore.dart';
import 'package:balaji_points/core/models/enquiry.dart';
import 'package:balaji_points/l10n/app_localizations.dart';
import 'package:balaji_points/presentation/screens/admin/admin_notifications_page.dart';
import 'package:balaji_points/presentation/widgets/admin/admin_dashboard.dart';
import 'package:balaji_points/services/branch/current_branch_service.dart';
import 'package:balaji_points/services/platform/enquiry_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

const outDir = String.fromEnvironment(
  'SHOT_DIR',
  defaultValue: 'build/screenshots',
);
const sdkFonts = String.fromEnvironment('SDK_FONTS');

Future<void> _loadFont(String family, String path) async {
  final bytes = File(path).readAsBytesSync();
  final loader = FontLoader(family)
    ..addFont(Future.value(ByteData.view(bytes.buffer)));
  await loader.load();
}

Future<void> _seed(FakeFirebaseFirestore db) async {
  const b = 'erode_main';
  final users = db.collection('users');
  for (var i = 0; i < 6; i++) {
    await users.doc('m$i').set({
      'role': i < 4 ? 'carpenter' : 'architect',
      'branchId': b,
      'profile_verified': true,
    });
  }
  await users.doc('p1').set({
    'role': 'carpenter',
    'branchId': b,
    'approvalStatus': 'pending',
  });
  final now = DateTime.now();
  final bills = db.collection('bills');
  for (var i = 0; i < 3; i++) {
    await bills.add({
      'branchId': b,
      'status': i == 0 ? 'approved' : 'pending',
      'pointsEarned': 12,
      'createdAt': Timestamp.fromDate(now.subtract(Duration(hours: i))),
    });
  }
  final logs = db.collection('notification_logs');
  final samples = [
    (
      'newPendingBill',
      'New bill to review',
      'Ravi Kumar sent a bill of 24,500.',
      0,
    ),
    (
      'newUserRegistered',
      'New account request',
      'Priya S (Architect) asked to join.',
      2,
    ),
    (
      'newPendingBill',
      'New bill to review',
      'Suresh M sent a bill of 8,200.',
      26,
    ),
    (
      'newUserRegistered',
      'New account request',
      'Arun (Carpenter) asked to join.',
      80,
    ),
  ];
  for (final s in samples) {
    await logs.add({
      'type': s.$1,
      'title': s.$2,
      'body': s.$3,
      'branchId': b,
      'userId': 'admin1',
      'sentAt': Timestamp.fromDate(now.subtract(Duration(hours: s.$4))),
    });
  }
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

  for (final dark in [false, true]) {
    final mode = dark ? 'dark' : 'light';
    for (final screen in ['grid', 'list', 'reorder', 'notifications']) {
      testWidgets('$screen $mode', (tester) async {
        SharedPreferences.setMockInitialValues({
          if (screen == 'list') 'admin_dashboard_list_view': true,
        });
        final db = FakeFirebaseFirestore();
        await _seed(db);
        overrideAppFirestoreForTesting(db);
        CurrentBranchService.setAdminBranch('erode_main');
        addTearDown(() => overrideAppFirestoreForTesting(null));

        tester.view.physicalSize = const Size(390, 844);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        final key = GlobalKey();
        final Widget body = screen == 'notifications'
            ? const AdminNotificationsPage(embedded: true)
            : AdminDashboard(onOpenSection: (_) {});
        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              enquiriesProvider.overrideWith(
                (ref, branchId) => Stream.value(const <Enquiry>[]),
              ),
            ],
            child: RepaintBoundary(
              key: key,
              child: MaterialApp(
                debugShowCheckedModeBanner: false,
                theme: AppThemeData.light(),
                darkTheme: AppThemeData.dark(),
                themeMode: dark ? ThemeMode.dark : ThemeMode.light,
                localizationsDelegates: AppLocalizations.localizationsDelegates,
                supportedLocales: AppLocalizations.supportedLocales,
                home: Scaffold(
                  appBar: AppBar(
                    title: Text(
                      screen == 'notifications'
                          ? 'Notifications'
                          : 'Balaji Points - Admin Panel',
                    ),
                  ),
                  body: body,
                ),
              ),
            ),
          ),
        );
        await tester.runAsync(() => GoogleFonts.pendingFonts());
        for (var k = 0; k < 10; k++) {
          await tester.pump(const Duration(milliseconds: 100));
        }
        if (screen == 'reorder') {
          await tester.tap(find.byIcon(Icons.tune_rounded));
          await tester.pumpAndSettle();
        }
        final boundary = tester.renderObject<RenderRepaintBoundary>(
          find.byKey(key),
        );
        final bytes = await tester.runAsync(() async {
          final image = await boundary.toImage(pixelRatio: 1);
          final data = await image.toByteData(format: ui.ImageByteFormat.png);
          return data!.buffer.asUint8List();
        });
        File('$outDir/admin_${screen}_$mode.png').writeAsBytesSync(bytes!);
        final err = tester.takeException();
        if (err != null) debugPrint('LAYOUT ERROR in $screen $mode: $err');
      });
    }
  }
}
