import 'package:balaji_points/l10n/app_localizations.dart';
import 'package:balaji_points/presentation/widgets/admin/offers_management.dart';
import 'package:balaji_points/services/platform/offer_service.dart';
import 'package:balaji_points/services/platform/offer_visibility.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Branch admins set the order members see offers in.
void main() {
  test('arranged order first, then the rest newest first', () {
    final offers = [
      {'title': 'C', 'createdAt': Timestamp.fromMillisecondsSinceEpoch(3)},
      {'title': 'B', 'sortOrder': 2},
      {'title': 'D', 'createdAt': Timestamp.fromMillisecondsSinceEpoch(1)},
      {'title': 'A', 'sortOrder': 1},
    ]..sort(OfferVisibility.compare);
    expect(offers.map((o) => o['title']), ['A', 'B', 'C', 'D']);
  });

  test('saving the order numbers offers 1, 2, 3', () async {
    final db = FakeFirebaseFirestore();
    for (final id in ['x', 'y', 'z']) {
      await db.doc('offers/$id').set({'title': id, 'points': 1});
    }
    expect(
      await OfferService(firestore: db).saveOrder(['z', 'x', 'y']),
      isTrue,
    );
    final order = {
      for (final d in (await db.collection('offers').get()).docs)
        d.id: d.data()['sortOrder'],
    };
    expect(order, {'z': 1, 'x': 2, 'y': 3});
  });

  testWidgets('arrange screen: drag an offer to the top and save', (
    tester,
  ) async {
    final db = FakeFirebaseFirestore();
    for (final id in ['a', 'b', 'c']) {
      await db.doc('offers/$id').set({'title': 'Offer $id', 'points': 100});
    }
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Builder(
          builder: (context) => Scaffold(
            body: Center(
              child: ElevatedButton(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ArrangeOffersPage(
                      service: OfferService(firestore: db),
                      offers: [
                        for (final id in ['a', 'b', 'c'])
                          (id: id, data: {'title': 'Offer $id', 'points': 100}),
                      ],
                    ),
                  ),
                ),
                child: const Text('open'),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    expect(find.text('Arrange order'), findsOneWidget);

    // Drag "Offer c" (third) above "Offer a" (first) by its handle.
    final handle = find.byIcon(Icons.drag_handle_rounded).at(2);
    final gesture = await tester.startGesture(tester.getCenter(handle));
    await tester.pump(const Duration(milliseconds: 100));
    await gesture.moveBy(const Offset(0, -300));
    await tester.pump(const Duration(milliseconds: 100));
    await gesture.up();
    await tester.pumpAndSettle();

    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();
    final order = {
      for (final d in (await db.collection('offers').get()).docs)
        d.id: d.data()['sortOrder'],
    };
    expect(order, {'c': 1, 'a': 2, 'b': 3});
  });
}
