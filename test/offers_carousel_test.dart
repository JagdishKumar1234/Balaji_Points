import 'package:balaji_points/core/design/app_theme.dart';
import 'package:balaji_points/l10n/app_localizations.dart';
import 'package:balaji_points/presentation/widgets/carpenter/offers_carousel.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';

Widget _app(Widget child) => MaterialApp(
  theme: AppThemeData.light(),
  localizationsDelegates: AppLocalizations.localizationsDelegates,
  supportedLocales: AppLocalizations.supportedLocales,
  home: Scaffold(body: Center(child: child)),
);

const _offers = [
  OfferItem(
    id: 'a',
    title: 'Offer A',
    description: 'Details A',
    pointsTarget: 6000,
  ),
  OfferItem(
    id: 'b',
    title: 'Offer B',
    description: 'Details B',
    pointsTarget: 10000,
  ),
  OfferItem(
    id: 'c',
    title: 'Offer C',
    description: 'Details C',
    pointsTarget: 13500,
  ),
];

String _centreTitle(WidgetTester tester) {
  final centre = tester.getCenter(find.byType(PageView));
  // The title in the bar below the centre card.
  final bars = find.textContaining('Offer ');
  String? best;
  var bestDistance = double.infinity;
  for (final e in bars.evaluate()) {
    final box = e.renderObject as RenderBox;
    final x = box.localToGlobal(box.size.center(Offset.zero)).dx;
    final d = (x - centre.dx).abs();
    if (d < bestDistance) {
      bestDistance = d;
      best = (e.widget as Text).data;
    }
  }
  return best!;
}

void main() {
  GoogleFonts.config.allowRuntimeFetching = false;

  testWidgets('slides by itself and loops back to the first offer', (
    tester,
  ) async {
    await tester.pumpWidget(
      _app(
        const OffersCarousel(
          offers: _offers,
          autoPlayInterval: Duration(seconds: 1),
        ),
      ),
    );
    await tester.pump();
    expect(_centreTitle(tester), 'Offer A');

    for (final expected in ['Offer B', 'Offer C', 'Offer A']) {
      await tester.pump(const Duration(seconds: 1));
      await tester.pumpAndSettle(const Duration(milliseconds: 100));
      expect(_centreTitle(tester), expected);
    }
    expect(tester.takeException(), isNull);
  });

  testWidgets('swiping backwards from the first offer shows the last', (
    tester,
  ) async {
    await tester.pumpWidget(
      _app(
        const OffersCarousel(
          offers: _offers,
          autoPlayInterval: Duration(minutes: 5),
        ),
      ),
    );
    await tester.pump();
    await tester.fling(find.byType(PageView), const Offset(400, 0), 1000);
    await tester.pumpAndSettle();
    expect(_centreTitle(tester), 'Offer C');
  });

  testWidgets('a single offer does not slide', (tester) async {
    await tester.pumpWidget(
      _app(
        const OffersCarousel(
          offers: [OfferItem(title: 'Only', description: '')],
          autoPlayInterval: Duration(seconds: 1),
        ),
      ),
    );
    await tester.pump(const Duration(seconds: 3));
    expect(find.text('Only'), findsWidgets);
    expect(tester.takeException(), isNull);
  });

  testWidgets('the info button shows details and progress to the target', (
    tester,
  ) async {
    await tester.pumpWidget(
      _app(
        const OffersCarousel(
          offers: _offers,
          myPoints: 1500,
          autoPlayInterval: Duration(minutes: 5),
        ),
      ),
    );
    await tester.pump();
    await tester.tap(
      find.byIcon(Icons.info_outline_rounded).hitTestable().first,
    );
    await tester.pumpAndSettle();

    expect(find.text('Offer details'), findsOneWidget);
    expect(find.text('Details A'), findsOneWidget);
    expect(find.text('You have 1500 of 6,000 points'), findsOneWidget);
    expect(find.text('4500 more points to reach this offer'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('a member at the target sees it reached', (tester) async {
    await tester.pumpWidget(
      _app(
        const OffersCarousel(
          offers: _offers,
          myPoints: 7000,
          autoPlayInterval: Duration(minutes: 5),
        ),
      ),
    );
    await tester.pump();
    await tester.tap(
      find.byIcon(Icons.info_outline_rounded).hitTestable().first,
    );
    await tester.pumpAndSettle();
    expect(find.text('Target reached!'), findsOneWidget);
  });

  test('carousel height follows the banner shape', () {
    // 16 px each side at 1280:714, plus the info bar.
    expect(
      OffersCarousel.cardHeightFor(400),
      closeTo((400 - 32) / (1280 / 714) + 64, 0.01),
    );
  });

  testWidgets('the centre card has the same 16 px sides as other cards', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.7;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(
        theme: AppThemeData.light(),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: const Scaffold(
          body: Align(
            alignment: Alignment.topCenter,
            child: OffersCarousel(
              offers: _offers,
              autoPlayInterval: Duration(minutes: 5),
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    final screenWidth = 1080 / 2.7;
    final aspect = find.byType(AspectRatio);
    final centre = aspect
        .evaluate()
        .map((e) {
          final box = e.renderObject as RenderBox;
          return box.localToGlobal(Offset.zero) & box.size;
        })
        .firstWhere((r) => r.left >= 0 && r.right <= screenWidth);
    expect(centre.left, closeTo(16, 0.5));
    expect(screenWidth - centre.right, closeTo(16, 0.5));
  });
}
