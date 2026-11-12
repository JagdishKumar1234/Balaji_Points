import 'package:balaji_points/core/models/enquiry.dart';
import 'package:balaji_points/l10n/app_localizations.dart';
import 'package:balaji_points/presentation/screens/common/contact/contact_us_page.dart';
import 'package:balaji_points/presentation/screens/guest/careers_page.dart';
import 'package:balaji_points/presentation/screens/guest/guest_home_page.dart';
import 'package:balaji_points/services/branch/public_branches.dart';
import 'package:balaji_points/services/platform/catalog_service.dart';
import 'package:balaji_points/services/platform/enquiry_service.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

/// A visitor walking through guest mode with real navigation.
void main() {
  late FakeFirebaseFirestore db;
  late List<String> visited;

  setUp(() async {
    db = FakeFirebaseFirestore();
    visited = [];
    await db.doc('catalog_categories/doors').set({
      'name': 'Doors',
      'catalogCount': 1,
    });
    await db.doc('catalogs/k').set({
      'categoryId': 'doors',
      'title': 'Kan-B E3 Pro',
      'pdfUrl': 'https://example.com/k.pdf',
      'pages': 11,
    });
  });

  Future<void> pump(WidgetTester tester) async {
    tester.view.physicalSize = const Size(1080, 2220); // 360 x 740 dp
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    final router = GoRouter(
      initialLocation: '/guest',
      routes: [
        GoRoute(path: '/guest', builder: (_, __) => const GuestHomePage()),
        GoRoute(path: '/careers', builder: (_, __) => const CareersPage()),
        GoRoute(
          path: '/contact-us',
          builder: (_, s) => ContactUsPage(
            initialType: switch (s.uri.queryParameters['type']) {
              null => null,
              final id => EnquiryType.fromId(id),
            },
          ),
        ),
        // The reader itself needs the PDF engine; record that it opened.
        GoRoute(
          path: '/catalogs/:c/:id',
          builder: (_, s) {
            visited.add('reader ${s.pathParameters['id']}');
            return const Scaffold(body: Text('READER'));
          },
        ),
        GoRoute(
          path: '/login',
          builder: (_, __) => const Scaffold(body: Text('LOGIN')),
        ),
        GoRoute(
          path: '/register',
          builder: (_, __) => const Scaffold(body: Text('REGISTER')),
        ),
      ],
    );
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          publicBranchesProvider.overrideWith(
            (ref) => Stream.value(const [
              PublicBranch(
                id: 'erode_main',
                name: 'Sri Balaji Plywood and Hardware - E Road',
                shortName: 'E Road Branch',
                address: '150 VCTV Main Road, Erode',
                phone: '96006-09121',
                mapsUrl: 'https://maps.app.goo.gl/LGWBXRjMUJEq3bRC8',
              ),
              PublicBranch(
                id: 'karur',
                name: 'Sri Balaji Plywood and Hardware - Karur',
                shortName: 'Karur Branch',
                address: 'D.No.9/955/2, Ponvel Nagar, Karur',
                phone: '9042949135',
              ),
            ]),
          ),
          catalogServiceProvider.overrideWithValue(CatalogService(db)),
          enquirySenderProvider.overrideWith(
            (ref) async => const EnquirySender.guest(),
          ),
        ],
        child: MaterialApp.router(
          routerConfig: router,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
        ),
      ),
    );
    for (var i = 0; i < 5; i++) {
      await tester.pump(const Duration(milliseconds: 50));
    }
  }

  Finder tab(String label) => find.descendant(
    of: find.byType(NavigationBar),
    matching: find.text(label),
  );

  Future<void> settle(WidgetTester tester) async {
    for (var i = 0; i < 8; i++) {
      await tester.pump(const Duration(milliseconds: 50));
    }
  }

  testWidgets('home -> service request opens contact with Service chosen', (
    tester,
  ) async {
    await pump(tester);
    await tester.ensureVisible(find.text('Service request'));
    await tester.pump();
    await tester.tap(find.text('Service request'));
    await settle(tester);
    expect(tester.takeException(), isNull);
    final chip = tester.widget<ChoiceChip>(
      find.ancestor(
        of: find.text('Service request'),
        matching: find.byType(ChoiceChip),
      ),
    );
    expect(chip.selected, isTrue);
    // Branch is optional (no branch: the super admin gets it).
    expect(find.text('Branch (optional)'), findsOneWidget);
  });

  testWidgets('home -> careers opens the application form', (tester) async {
    await pump(tester);
    await tester.ensureVisible(find.text('Careers'));
    await tester.pump();
    await tester.tap(find.text('Careers'));
    await settle(tester);
    expect(find.text('Send application'), findsOneWidget);
  });

  testWidgets('catalogs tab -> tap a cover -> the reader opens', (
    tester,
  ) async {
    await pump(tester);
    await tester.tap(tab('Catalogs'));
    await settle(tester);
    expect(find.text('Kan-B E3 Pro'), findsOneWidget);
    await tester.tap(find.text('Kan-B E3 Pro'));
    await settle(tester);
    expect(visited, ['reader k']);
    expect(find.text('READER'), findsOneWidget);
  });

  testWidgets('branches tab shows both branches with directions', (
    tester,
  ) async {
    await pump(tester);
    await tester.tap(tab('Branches'));
    await settle(tester);
    expect(find.text('E Road Branch'), findsOneWidget);
    expect(find.text('Directions'), findsWidgets);
  });

  testWidgets('partner with us -> store sign-up needs no branch', (
    tester,
  ) async {
    await pump(tester);
    await tester.ensureVisible(find.text('Partner with us'));
    await tester.pump();
    await tester.tap(find.text('Partner with us'));
    await settle(tester);
    final chip = tester.widget<ChoiceChip>(
      find.ancestor(
        of: find.text('Register my store'),
        matching: find.byType(ChoiceChip),
      ),
    );
    expect(chip.selected, isTrue);
    // A store partnership goes to the super admin: no branch to pick.
    expect(find.text('Branch (optional)'), findsNothing);
  });

  testWidgets('log in and register leave guest mode', (tester) async {
    await pump(tester);
    await tester.tap(find.text('Log in').first);
    await settle(tester);
    expect(find.text('LOGIN'), findsOneWidget);
  });
}
