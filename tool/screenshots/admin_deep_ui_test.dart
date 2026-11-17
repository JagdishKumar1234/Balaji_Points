// Deep UI check of every branch admin screen (not part of `flutter test`).
//
//   flutter test tool/screenshots/admin_deep_ui_test.dart \
//     --dart-define=SHOT_DIR=/path/to/output \
//     --dart-define=SDK_FONTS=$FLUTTER_ROOT/bin/cache/artifacts/material_fonts
//
// Renders the real admin widgets on a fake Firestore with realistic sample
// data (long names, members with no name, every bill status, active and
// inactive offers, catalogs, alerts) at 360 / 390 / 900 px wide, light and
// dark, plus large system text, and writes a PNG per case and a report of
// every layout overflow or error to $SHOT_DIR/report.txt.
import 'dart:io';
import 'dart:ui' as ui;

import 'package:balaji_points/core/design/app_theme.dart';
import 'package:balaji_points/core/firebase/app_firestore.dart';
import 'package:balaji_points/core/models/enquiry.dart';
import 'package:balaji_points/l10n/app_localizations.dart';
import 'package:balaji_points/presentation/screens/admin/admin_notifications_page.dart';
import 'package:balaji_points/presentation/screens/admin/send_greeting_page.dart';
import 'package:balaji_points/presentation/screens/admin/send_notification_page.dart';
import 'package:balaji_points/presentation/widgets/admin/admin_bottom_nav_bar.dart';
import 'package:balaji_points/presentation/widgets/admin/admin_dashboard.dart';
import 'package:balaji_points/presentation/widgets/admin/admin_more_page.dart';
import 'package:balaji_points/presentation/widgets/admin/admin_tab_pages.dart';
import 'package:balaji_points/presentation/widgets/admin/catalogs_management.dart';
import 'package:balaji_points/presentation/widgets/admin/daily_spin_management.dart';
import 'package:balaji_points/presentation/widgets/admin/enquiries_management.dart';
import 'package:balaji_points/presentation/widgets/admin/offers_management.dart';
import 'package:balaji_points/presentation/widgets/admin/users_list/users_filters.dart';
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
const _b = 'erode_main';

Future<void> _loadFont(String family, String path) async {
  final bytes = File(path).readAsBytesSync();
  final loader = FontLoader(family)
    ..addFont(Future.value(ByteData.view(bytes.buffer)));
  await loader.load();
}

Future<void> _seed(FakeFirebaseFirestore db) async {
  final now = DateTime.now();
  Timestamp ago(Duration d) => Timestamp.fromDate(now.subtract(d));

  await db.collection('branches').doc(_b).set({
    'name': 'Sri Balaji Plywood and Hardware - E Road',
    'shortName': 'E Road Branch',
    'isActive': true,
    'phone': '96006-09121',
  });
  final members = [
    ('m1', 'Ravi', 'Kumar', 'carpenter', '9000000011', 42.5, 'Silver'),
    ('m2', 'Priya', 'Sundaram', 'architect', '9000000012', 8, 'Bronze'),
    ('m3', '', '', 'interior_designer', '9000000013', 0, 'Bronze'),
    (
      'm4',
      'Arunachalam Venkatesan',
      'Subramaniyan',
      'engineer',
      '9000000014',
      1250,
      'Gold',
    ),
    ('m5', 'Mohammed', 'Irfan', '', '9000000016', 310.75, 'Platinum'),
  ];
  for (final (i, m) in members.indexed) {
    await db.collection('users').doc(m.$1).set({
      'uid': m.$1,
      'firstName': m.$2,
      'lastName': m.$3,
      'role': m.$4,
      'phone': m.$5,
      'totalPoints': m.$6,
      'tier': m.$7,
      'branchId': _b,
      'profile_verified': true,
      'approvalStatus': 'approved',
      'status': 'active',
      'createdAt': ago(Duration(days: 9 * (i + 1))),
    });
    await db.collection('user_points').doc(m.$1).set({
      'userId': m.$1,
      'branchId': _b,
      'totalPoints': m.$6,
      'tier': m.$7,
    });
  }
  await db.collection('users').doc('req1').set({
    'firstName': 'Suresh',
    'lastName': 'M',
    'role': 'carpenter',
    'phone': '9000000015',
    'branchId': _b,
    'approvalStatus': 'pending',
    'createdAt': ago(const Duration(hours: 3)),
  });
  await db.collection('users').doc('adm').set({
    'role': 'admin',
    'branchId': _b,
    'firstName': 'Branch',
    'lastName': 'Admin',
  });

  final bills = [
    ('b1', 'm1', 24500.0, 'pending', 'Gandhi Nagar', 1),
    ('b2', 'm4', 182340.5, 'pending', 'Perundurai Road New Villa Project', 5),
    ('b3', 'm2', 8200.0, 'approved', 'Site A', 30),
    ('b4', 'm1', 3100.0, 'rejected', 'Shop renovation', 60),
    ('b5', 'm5', 56000.0, 'approved', 'Hotel lobby', 200),
  ];
  for (final b in bills) {
    await db.collection('bills').doc(b.$1).set({
      'billId': b.$1,
      'billNumber': 'INV-${b.$1.toUpperCase()}',
      'carpenterId': b.$2,
      'carpenterPhone': members.firstWhere((m) => m.$1 == b.$2).$5,
      'amount': b.$3,
      'status': b.$4,
      'siteName': b.$5,
      'billDate': ago(Duration(hours: b.$6 + 20)),
      'createdAt': ago(Duration(hours: b.$6)),
      'branchId': _b,
      'imageUrl': '',
      if (b.$4 == 'approved') 'pointsEarned': (b.$3 / 1000).floor(),
      if (b.$4 == 'rejected') 'rejectionReason': 'Bill photo is not clear',
    });
  }

  for (final (i, o) in [
    ('Double points on plywood', true),
    ('Diwali gift hamper for top 10 members this festive season', true),
    ('Old monsoon offer', false),
  ].indexed) {
    await db.collection('offers').add({
      'title': o.$1,
      'description': 'Valid on bills above 10,000. Ask the branch for details.',
      'points': 50 * (i + 1),
      'isActive': o.$2,
      'branchId': _b,
      'createdAt': ago(Duration(days: i)),
      'validUntil': Timestamp.fromDate(now.add(Duration(days: 10 - i * 20))),
    });
  }

  await db.collection('catalog_categories').doc('laminates').set({
    'name': 'Laminates',
    'sortOrder': 1,
    'isActive': true,
  });
  await db.collection('catalog_categories').doc('doors').set({
    'name': 'Doors',
    'sortOrder': 2,
    'isActive': true,
  });
  for (final (i, c) in [
    ('Virgo ABCO Lam 2025 .8mm', 'laminates'),
    ('Kan-B Door Travelogue 2024 with a very long catalogue title', 'doors'),
  ].indexed) {
    await db.collection('catalogs').add({
      'title': c.$1,
      'categoryId': c.$2,
      'isActive': true,
      'sortOrder': i,
      'pageCount': 60 + i * 26,
      'sizeBytes': 5500000 + i * 2500000,
      'pdfUrl': '',
      'coverUrl': '',
      'createdAt': ago(Duration(days: i)),
    });
  }

  for (final n in [
    ('newPendingBill', 'New bill to review', 'Ravi Kumar sent a bill.', 0),
    ('newUserRegistered', 'New account request', 'Suresh M asked to join.', 3),
    ('newPendingBill', 'New bill to review', 'Arunachalam sent a bill.', 30),
  ]) {
    await db.collection('notification_logs').add({
      'type': n.$1,
      'title': n.$2,
      'body': n.$3,
      'branchId': _b,
      'userId': 'adm',
      'sentAt': ago(Duration(hours: n.$4)),
    });
  }
}

/// Every admin screen, as it sits under the admin app bar and tab bar.
final Map<String, (AdminTab?, Widget Function())> _screens = {
  'dashboard_grid': (
    AdminTab.home,
    () => AdminDashboard(onOpenSection: (_) {}),
  ),
  'dashboard_list': (
    AdminTab.home,
    () => AdminDashboard(onOpenSection: (_) {}),
  ),
  'bills_pending': (AdminTab.bills, () => const AdminBillsTab(pendingCount: 2)),
  'bills_history': (
    AdminTab.bills,
    () => const AdminBillsTab(pendingCount: 2, initial: 1),
  ),
  'members': (
    AdminTab.members,
    () => AdminMembersTab(requestsCount: 1, onOpenRequests: () {}),
  ),
  'more': (
    AdminTab.more,
    () => AdminMorePage(
      onOpenSection: (_) {},
      onLogout: () {},
      alertsBadge: 3,
      enquiriesBadge: 1,
    ),
  ),
  'notifications': (
    AdminTab.more,
    () => AdminNotificationsPage(embedded: true, onOpenSection: (_) {}),
  ),
  'send_notification': (AdminTab.more, () => const SendNotificationPage()),
  'send_greeting': (
    AdminTab.more,
    () => const SendGreetingPage(embedded: true),
  ),
  'offers': (AdminTab.more, () => const OffersManagement()),
  'catalogs': (AdminTab.more, () => const CatalogsManagement()),
  'enquiries': (AdminTab.more, () => const EnquiriesManagement(branchId: _b)),
  'spin': (AdminTab.more, () => const DailySpinManagement()),
};

void main() {
  GoogleFonts.config.allowRuntimeFetching = false;
  final report = StringBuffer();

  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    if (sdkFonts.isNotEmpty) {
      await _loadFont('MaterialIcons', '$sdkFonts/MaterialIcons-Regular.otf');
    }
    Directory(outDir).createSync(recursive: true);
  });

  tearDownAll(() {
    File('$outDir/report.txt').writeAsStringSync(
      report.isEmpty ? 'No layout errors.\n' : report.toString(),
    );
  });

  const variants = <String, (Size, bool, double)>{
    '360_light': (Size(360, 740), false, 1.0),
    '360_dark': (Size(360, 740), true, 1.0),
    '390_light': (Size(390, 844), false, 1.0),
    '900_light': (Size(900, 1100), false, 1.0),
    '360_bigtext': (Size(360, 740), false, 1.3),
  };

  for (final screen in _screens.entries) {
    for (final v in variants.entries) {
      final name = '${screen.key}__${v.key}';
      testWidgets(name, (tester) async {
        final (size, dark, scale) = v.value;
        final (tab, build) = screen.value;
        SharedPreferences.setMockInitialValues({
          if (screen.key == 'dashboard_list') 'admin_dashboard_list_view': true,
        });
        final db = FakeFirebaseFirestore();
        await _seed(db);
        overrideAppFirestoreForTesting(db);
        CurrentBranchService.setAdminBranch(_b);
        addTearDown(() => overrideAppFirestoreForTesting(null));

        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.reset);

        final errors = <String>[];
        final oldOnError = FlutterError.onError;
        FlutterError.onError = (d) =>
            errors.add(d.exceptionAsString().split('\n').first);
        addTearDown(() => FlutterError.onError = oldOnError);

        final key = GlobalKey();
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
                builder: (context, child) => MediaQuery(
                  data: MediaQuery.of(
                    context,
                  ).copyWith(textScaler: TextScaler.linear(scale)),
                  child: child!,
                ),
                home: Scaffold(
                  appBar: AppBar(
                    title: Text(screen.key),
                    actions: [
                      if (screen.key == 'members') const UsersFilterButton(),
                    ],
                  ),
                  body: build(),
                  bottomNavigationBar: size.width < 840
                      ? AdminBottomNavBar(
                          current: tab,
                          onTab: (_) {},
                          onAddBill: () {},
                          billsBadge: 2,
                          membersBadge: 1,
                          moreBadge: 4,
                        )
                      : null,
                ),
              ),
            ),
          ),
        );
        await tester.runAsync(() => GoogleFonts.pendingFonts());
        for (var k = 0; k < 15; k++) {
          await tester.pump(const Duration(milliseconds: 100));
        }
        final late = tester.takeException();
        if (late != null) errors.add('$late'.split('\n').first);

        final boundary = tester.renderObject<RenderRepaintBoundary>(
          find.byKey(key),
        );
        final bytes = await tester.runAsync(() async {
          final image = await boundary.toImage(pixelRatio: 1);
          final data = await image.toByteData(format: ui.ImageByteFormat.png);
          return data!.buffer.asUint8List();
        });
        File('$outDir/$name.png').writeAsBytesSync(bytes!);
        for (final e in errors.toSet()) {
          report.writeln('$name: $e');
        }
      });
    }
  }
}
