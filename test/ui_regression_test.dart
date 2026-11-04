import 'dart:io';

import 'package:balaji_points/core/design/app_colors.dart';
import 'package:balaji_points/core/design/app_theme.dart';
import 'package:balaji_points/core/models/greeting_model.dart';
import 'package:balaji_points/l10n/app_localizations.dart';
import 'package:balaji_points/presentation/screens/carpenter/home/widgets/home_greeting_banner.dart';
import 'package:balaji_points/presentation/widgets/carpenter/offers_carousel.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';

Widget _app(Widget child) => MaterialApp(
  theme: AppThemeData.light(),
  localizationsDelegates: AppLocalizations.localizationsDelegates,
  supportedLocales: AppLocalizations.supportedLocales,
  home: Scaffold(body: SingleChildScrollView(child: child)),
);

GreetingItem _greeting(String message) => GreetingItem(
  id: 'g1',
  message: message,
  createdAt: DateTime(2026),
  createdBy: 'admin',
  active: true,
);

void main() {
  GoogleFonts.config.allowRuntimeFetching = false;

  test('coloured buttons always set a matching text colour', () {
    // The theme's button text is navy, so a navy, green or red background with
    // no foreground colour gives a blank button.
    final problems = <String>[];
    final files = Directory('lib')
        .listSync(recursive: true)
        .whereType<File>()
        .where((file) => file.path.endsWith('.dart'));
    final style = RegExp(r'(ElevatedButton|FilledButton)\.styleFrom\(');
    for (final file in files) {
      final source = file.readAsStringSync();
      for (final match in style.allMatches(source)) {
        var depth = 1;
        var end = match.end;
        while (depth > 0 && end < source.length) {
          if (source[end] == '(') depth++;
          if (source[end] == ')') depth--;
          end++;
        }
        final body = source.substring(match.end, end);
        if (body.contains('backgroundColor') &&
            !body.contains('foregroundColor')) {
          final line = '\n'.allMatches(source.substring(0, match.start)).length;
          problems.add('${file.path}:${line + 1}');
        }
      }
    }
    expect(problems, isEmpty);
  });

  test('the branch card is only on the two home screens', () {
    final users = Directory('lib/presentation')
        .listSync(recursive: true)
        .whereType<File>()
        .where(
          (file) =>
              file.path.endsWith('.dart') &&
              file.readAsStringSync().contains('BranchBanner('),
        )
        .map((file) => file.path.split('/').last)
        .toSet();
    expect(users, {
      'branch_banner.dart',
      'home_page.dart',
      'admin_home_page.dart',
    });
    expect(
      File(
        'lib/presentation/screens/admin/admin_home_page.dart',
      ).readAsStringSync(),
      contains(RegExp(r'if \(_showDashboard\)\s+const BranchBanner\(')),
    );
  });

  test('spin status colours are readable together', () {
    double luminance(Color color) => color.computeLuminance();
    final text = luminance(AppColors.successText);
    final background = luminance(AppColors.successSoft);
    final ratio = (background + 0.05) / (text + 0.05);
    expect(ratio, greaterThan(4.5));
  });

  group('OffersCarousel', () {
    testWidgets('puts the title below a banner image, not over it', (
      tester,
    ) async {
      await tester.pumpWidget(
        _app(
          OffersCarousel(
            offers: [
              OfferItem(
                title: 'Diwali Scheme',
                description: 'Last date',
                actionText: 'View Offer',
                imageUrl: 'https://example.com/banner.png',
              ),
            ],
          ),
        ),
      );
      await tester.pump();

      final image = tester.getRect(find.byType(Image));
      final title = tester.getRect(find.text('Diwali Scheme'));
      expect(title.top, greaterThanOrEqualTo(image.bottom));
      expect(tester.takeException(), isNull);
    });

    testWidgets('an offer with no image keeps its text on the card', (
      tester,
    ) async {
      await tester.pumpWidget(
        _app(
          OffersCarousel(
            offers: [
              OfferItem(
                title: 'Plain offer',
                description: '',
                actionText: 'Learn More',
              ),
            ],
          ),
        ),
      );
      await tester.pump();
      expect(find.text('Plain offer'), findsOneWidget);
      expect(find.text('Learn More'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });

  group('HomeGreetingBanner', () {
    Future<void> pumpBanner(WidgetTester tester, String message) async {
      await tester.pumpWidget(
        _app(
          HomeGreetingBanner(greeting: _greeting(message), onDismiss: () {}),
        ),
      );
      await tester.pump(const Duration(seconds: 1));
    }

    testWidgets('a short greeting shows in full with no toggle', (
      tester,
    ) async {
      await pumpBanner(tester, 'Happy Diwali!');
      expect(find.text('Happy Diwali!'), findsOneWidget);
      expect(find.text('Read more'), findsNothing);
    });

    testWidgets('a long greeting collapses, and expands on request', (
      tester,
    ) async {
      final long = List.filled(40, 'Dear carpenters please check.').join(' ');
      await pumpBanner(tester, long);

      Text message() => tester.widget<Text>(find.text(long));
      expect(message().maxLines, 4);
      final collapsed = tester.getSize(find.text(long)).height;

      await tester.tap(find.text('Read more'));
      await tester.pump();
      expect(message().maxLines, isNull);
      expect(tester.getSize(find.text(long)).height, greaterThan(collapsed));

      await tester.tap(find.text('Show less'));
      await tester.pump();
      expect(message().maxLines, 4);
    });

    testWidgets('a greeting with many lines also collapses', (tester) async {
      await pumpBanner(tester, 'a\nb\nc\nd\ne\nf');
      expect(find.text('Read more'), findsOneWidget);
    });
  });
}
