import 'package:balaji_points/l10n/app_localizations.dart';
import 'package:balaji_points/presentation/screens/common/catalog/catalogs_page.dart';
import 'package:balaji_points/services/platform/catalog_service.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

/// The merged Catalogs screen: chips + covers on one screen, one tap to read.
void main() {
  late FakeFirebaseFirestore db;
  late List<String> opened;

  setUp(() async {
    db = FakeFirebaseFirestore();
    opened = [];
    for (final c in [
      {'id': 'laminates', 'name': 'Laminates', 'sortOrder': 1, 'n': 2},
      {'id': 'doors', 'name': 'Doors', 'sortOrder': 2, 'n': 1},
    ]) {
      await db.collection('catalog_categories').doc(c['id'] as String).set({
        'name': c['name'],
        'sortOrder': c['sortOrder'],
        'catalogCount': c['n'],
      });
    }
    for (final c in [
      {'id': 'v', 'cat': 'laminates', 'title': 'Virgo ABCO'},
      {'id': 'b', 'cat': 'laminates', 'title': 'Blinco'},
      {'id': 'k', 'cat': 'doors', 'title': 'Kan-B E3 Pro'},
    ]) {
      await db.collection('catalogs').doc(c['id']).set({
        'categoryId': c['cat'],
        'title': c['title'],
        'pdfUrl': 'https://example.com/${c['id']}.pdf',
        'pages': 10,
      });
    }
  });

  Future<void> pump(WidgetTester tester) async {
    final router = GoRouter(
      initialLocation: '/catalogs',
      routes: [
        GoRoute(
          path: '/catalogs',
          builder: (_, __) => const CatalogsPage(),
          routes: [
            GoRoute(
              path: ':categoryId/:catalogId',
              builder: (_, s) {
                opened.add(s.pathParameters['catalogId']!);
                return const Scaffold(body: Text('reader'));
              },
            ),
          ],
        ),
      ],
    );
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          catalogServiceProvider.overrideWithValue(CatalogService(db)),
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

  testWidgets('shows every catalog under category headings', (tester) async {
    await pump(tester);
    expect(find.text('All  3'), findsOneWidget);
    expect(find.text('Laminates  2'), findsOneWidget);
    expect(find.text('Doors  1'), findsOneWidget);
    expect(find.text('Virgo ABCO'), findsOneWidget);
    expect(find.text('Blinco'), findsOneWidget);
    expect(find.text('Kan-B E3 Pro'), findsOneWidget);
  });

  testWidgets('a chip filters to one category', (tester) async {
    await pump(tester);
    await tester.tap(find.text('Doors  1'));
    await tester.pump();
    expect(find.text('Kan-B E3 Pro'), findsOneWidget);
    expect(find.text('Virgo ABCO'), findsNothing);
  });

  testWidgets('one tap on a cover opens the reader', (tester) async {
    await pump(tester);
    await tester.ensureVisible(find.text('Kan-B E3 Pro'));
    await tester.pump();
    await tester.tap(find.text('Kan-B E3 Pro'));
    await tester.pumpAndSettle();
    expect(opened, ['k']);
    expect(find.text('reader'), findsOneWidget);
  });

  testWidgets('tiles do not overflow with large system fonts', (tester) async {
    tester.view.physicalSize = const Size(1080, 2340);
    tester.view.devicePixelRatio = 2.75;
    tester.platformDispatcher.textScaleFactorTestValue = 1.4;
    addTearDown(tester.view.reset);
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    await pump(tester);
    expect(tester.takeException(), isNull);
    expect(find.text('Virgo ABCO'), findsOneWidget);
  });
}
