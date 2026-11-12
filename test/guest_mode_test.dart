import 'package:balaji_points/core/models/enquiry.dart';
import 'package:balaji_points/l10n/app_localizations.dart';
import 'package:balaji_points/presentation/screens/guest/branches_page.dart';
import 'package:balaji_points/presentation/screens/guest/careers_page.dart';
import 'package:balaji_points/presentation/screens/guest/guest_home_page.dart';
import 'package:balaji_points/services/branch/public_branches.dart';
import 'package:balaji_points/services/platform/enquiry_service.dart';
import 'package:balaji_points/services/platform/catalog_service.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Guest mode: catalogs, branches, service, careers and contact only.
void main() {
  const karur = PublicBranch(
    id: 'karur',
    name: 'Sri Balaji Plywood and Hardware - Karur',
    shortName: 'Karur Branch',
    address: 'D.No.9/955/2, Ponvel Nagar, Karur',
    phone: '9042949135',
  );
  const erode = PublicBranch(
    id: 'erode_main',
    name: 'Sri Balaji Plywood and Hardware - E Road',
    shortName: 'E Road Branch',
    address: '150 VCTV Main Road, Erode',
    phone: '96006-09121',
    mapsUrl: 'https://maps.app.goo.gl/abc123',
  );

  late FakeFirebaseFirestore catalogDb;

  setUp(() async {
    catalogDb = FakeFirebaseFirestore();
    await catalogDb.doc('catalog_categories/doors').set({
      'name': 'Doors',
      'catalogCount': 1,
    });
    await catalogDb.doc('catalogs/k').set({
      'categoryId': 'doors',
      'title': 'Kan-B E3 Pro',
      'pdfUrl': 'https://example.com/k.pdf',
    });
  });

  Future<void> pump(WidgetTester tester, Widget page) async {
    tester.view.physicalSize = const Size(1080, 2220); // 360 x 740 dp
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          publicBranchesProvider.overrideWith(
            (ref) => Stream.value(const [erode, karur]),
          ),
          catalogServiceProvider.overrideWithValue(CatalogService(catalogDb)),
          enquirySenderProvider.overrideWith(
            (ref) async => const EnquirySender.guest(),
          ),
        ],
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: page,
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
  }

  test('directions use the map link, else search name + address', () {
    expect(erode.directions.toString(), 'https://maps.app.goo.gl/abc123');
    final search = karur.directions;
    expect(search.host, 'www.google.com');
    expect(search.queryParameters['query'], contains('Ponvel Nagar, Karur'));
    expect(search.queryParameters['query'], contains('Karur'));
    expect(karur.dialable, '+919042949135');
    expect(erode.dialable, '+919600609121');
  });

  testWidgets('guest home: tab bar, live stats, join and grow panels', (
    tester,
  ) async {
    await pump(tester, const GuestHomePage());
    await tester.pump(const Duration(milliseconds: 100));
    expect(tester.takeException(), isNull);
    // Bottom tab bar.
    for (final t in ['Home', 'Catalogs', 'Branches', 'Contact']) {
      expect(
        find.descendant(of: find.byType(NavigationBar), matching: find.text(t)),
        findsOneWidget,
        reason: t,
      );
    }
    // Header with Log in.
    expect(find.text('Balaji Points'), findsWidgets);
    expect(find.text('Log in'), findsWidgets);
    // Live stats: 2 branches, 1 catalog, 1 category.
    expect(find.text('2'), findsOneWidget);
    expect(find.text('1'), findsNWidgets(2));
    // What we sell.
    for (final t in ['Plywood', 'Hardware', 'Fittings']) {
      expect(find.text(t), findsOneWidget, reason: t);
    }
    await tester.scrollUntilVisible(
      find.text('Partner with us'),
      300,
      // Tabs stay alive in the background: scroll the Home list itself.
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('Register now'), findsOneWidget);
    expect(find.text('Grow your business with Balaji Points'), findsOneWidget);
    expect(find.text('Full admin panel for your team'), findsOneWidget);
    // Buttons on the navy panels keep a see-through fill, so their white
    // labels show (the theme's outlined buttons are white).
    for (final b in tester.widgetList<OutlinedButton>(
      find.byType(OutlinedButton),
    )) {
      final fill = b.style?.backgroundColor?.resolve({});
      final fg = b.style?.foregroundColor?.resolve({});
      if (fg == Colors.white) {
        expect(fill, Colors.transparent);
      }
    }
    // Nothing for members only.
    expect(find.textContaining('Bill'), findsNothing);
    expect(find.textContaining('Offer'), findsNothing);
  });

  testWidgets('tabs switch without leaving guest mode', (tester) async {
    await pump(tester, const GuestHomePage());
    await tester.tap(
      find.descendant(
        of: find.byType(NavigationBar),
        matching: find.text('Branches'),
      ),
    );
    await tester.pump();
    expect(find.text('150 VCTV Main Road, Erode'), findsOneWidget);
    // In a tab there is no back arrow.
    expect(find.byIcon(Icons.arrow_back_rounded), findsNothing);
  });

  testWidgets('branches: every branch with address, call and directions', (
    tester,
  ) async {
    await pump(tester, const BranchesPage());
    expect(tester.takeException(), isNull);
    expect(find.text('E Road Branch'), findsOneWidget);
    expect(find.text('150 VCTV Main Road, Erode'), findsOneWidget);
    await tester.scrollUntilVisible(find.text('Karur Branch'), 200);
    expect(find.text('D.No.9/955/2, Ponvel Nagar, Karur'), findsOneWidget);
    expect(find.text('Directions'), findsWidgets);
  });

  testWidgets('careers: fits one screen, branch and position required', (
    tester,
  ) async {
    await pump(tester, const CareersPage());
    expect(tester.takeException(), isNull);
    final scroll = tester
        .state<ScrollableState>(find.byType(Scrollable).first)
        .position;
    expect(scroll.maxScrollExtent, 0);
    expect(
      tester.getRect(find.text('Send application')).bottom,
      lessThanOrEqualTo(740),
    );
    await tester.tap(find.text('Send application'));
    await tester.pump();
    expect(find.text('Select a branch'), findsOneWidget);
    expect(find.text('Enter the position'), findsOneWidget);
  });

  test('career application is saved for the chosen branch', () async {
    SharedPreferences.setMockInitialValues({});
    final db = FakeFirebaseFirestore();
    await EnquiryService(db: db).submit(
      sender: const EnquirySender.guest(),
      type: EnquiryType.career,
      name: 'Suresh',
      phone: '9123456780',
      message: 'Five years in a plywood showroom',
      position: 'Sales executive',
      experience: '5 years',
      guestBranchId: 'karur',
      guestBranchName: 'Karur Branch',
    );
    final d = (await db.collection('enquiries').get()).docs.single.data();
    expect(d['type'], 'career');
    expect(d['source'], 'guest');
    expect(d['branchId'], 'karur');
    expect(d['position'], 'Sales executive');
    expect(d['experience'], '5 years');
    expect(d.containsKey('role'), isFalse);
    expect(d.containsKey('userId'), isFalse);
    // That branch's admin inbox gets it.
    final inbox = await EnquiryService(db: db).watch(branchId: 'karur').first;
    expect(inbox.single.position, 'Sales executive');
  });
}
