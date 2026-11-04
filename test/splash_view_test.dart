import 'package:balaji_points/core/design/app_theme.dart';
import 'package:balaji_points/l10n/app_localizations.dart';
import 'package:balaji_points/presentation/screens/common/splash/splash_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';

const _loader = ValueKey('splash-loader');

Future<void> _pumpSplash(
  WidgetTester tester, {
  Size size = const Size(390, 844),
  double textScale = 1,
  bool disableAnimations = false,
  bool dark = false,
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  await tester.pumpWidget(
    MediaQuery(
      data: MediaQueryData(
        size: size,
        textScaler: TextScaler.linear(textScale),
        disableAnimations: disableAnimations,
      ),
      child: MaterialApp(
        theme: dark ? AppThemeData.dark() : AppThemeData.light(),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: const SplashView(),
      ),
    ),
  );
}

void main() {
  GoogleFonts.config.allowRuntimeFetching = false;

  group('SplashView', () {
    testWidgets('loader and logo sit at the exact centre of the screen', (
      tester,
    ) async {
      await _pumpSplash(tester);
      await tester.pump(const Duration(seconds: 2));

      final loader = tester.getCenter(find.byKey(_loader));
      expect(loader.dx, 195);
      expect(loader.dy, 422);
      expect(tester.getCenter(find.byType(Image)), loader);
    });

    testWidgets('loader ring clears the logo and the title', (tester) async {
      await _pumpSplash(tester);
      await tester.pump(const Duration(seconds: 2));

      final ring = tester.getRect(find.byKey(_loader));
      final logo = tester.getRect(find.byType(Image));
      expect(ring.width, greaterThan(logo.width));
      expect(ring.bottom, lessThan(tester.getTopLeft(find.text('Balaji Points')).dy));
    });

    testWidgets('title is above the footer', (tester) async {
      await _pumpSplash(tester);
      await tester.pump(const Duration(seconds: 2));

      final tagline = tester.getRect(find.text('Rewards & Loyalty Program'));
      final footer = tester.getRect(find.textContaining('Powered by'));
      expect(tagline.bottom, lessThan(footer.top));
    });

    testWidgets('logo appears on the very first frame', (tester) async {
      await _pumpSplash(tester);
      expect(find.byType(Image), findsOneWidget);
      await tester.pump(const Duration(seconds: 2));
    });

    testWidgets('entrance animation moves the logo over time', (tester) async {
      await _pumpSplash(tester);
      await tester.pump(const Duration(milliseconds: 50));
      final early = tester.getRect(find.byType(Image));
      await tester.pump(const Duration(milliseconds: 800));
      final settled = tester.getRect(find.byType(Image));
      expect(early.width, lessThan(settled.width));
      expect(settled.width, 112);
      await tester.pump(const Duration(seconds: 2));
    });

    for (final (name, size, scale) in [
      ('small phone', const Size(320, 568), 1.0),
      ('small phone with large text', const Size(320, 568), 2.0),
      ('landscape phone', const Size(844, 390), 1.0),
      ('tablet', const Size(900, 1000), 1.0),
      ('desktop', const Size(1366, 900), 1.0),
    ]) {
      testWidgets('has no overflow on $name', (tester) async {
        await _pumpSplash(tester, size: size, textScale: scale);
        await tester.pump(const Duration(seconds: 2));
        expect(tester.takeException(), isNull);
        expect(find.byKey(_loader), findsOneWidget);
      });
    }

    testWidgets('renders in dark mode', (tester) async {
      await _pumpSplash(tester, dark: true);
      await tester.pump(const Duration(seconds: 2));
      expect(tester.takeException(), isNull);
    });

    testWidgets('skips decorative motion when reduced motion is on', (
      tester,
    ) async {
      await _pumpSplash(tester, disableAnimations: true);
      // Fully settled from the first frame, with nothing scaling the logo.
      expect(tester.getSize(find.byType(Image)).width, 112);
      expect(tester.getRect(find.byType(Image)).width, 112);
      expect(find.byKey(_loader), findsOneWidget);
    });
  });
}
