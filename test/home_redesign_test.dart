import 'dart:io';

import 'package:balaji_points/core/design/app_theme.dart';
import 'package:balaji_points/l10n/app_localizations.dart';
import 'package:balaji_points/presentation/screens/carpenter/home/widgets/home_feature_highlights.dart';
import 'package:balaji_points/presentation/screens/carpenter/home/widgets/home_hero_card.dart';
import 'package:balaji_points/presentation/widgets/carpenter/top_carpenters_display.dart';
import 'package:balaji_points/presentation/widgets/carpenter/top_carpenters_list.dart';
import 'package:balaji_points/providers/home_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';

HomeState _state({
  String role = 'carpenter',
  String tier = 'Silver',
  double points = 3500,
  int? rank = 4,
  String lastName = 'Raman',
}) => HomeState(
  points: points,
  userRank: rank,
  userData: {
    'firstName': 'Esha',
    'lastName': lastName,
    'role': role,
    'tier': tier,
  },
);

Future<void> _pump(
  WidgetTester tester,
  Widget child, {
  Size size = const Size(390, 844),
  double textScale = 1,
  bool dark = false,
  Locale locale = const Locale('en'),
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(
    MaterialApp(
      theme: dark ? AppThemeData.dark() : AppThemeData.light(),
      locale: locale,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      builder: (context, app) => MediaQuery(
        data: MediaQuery.of(
          context,
        ).copyWith(textScaler: TextScaler.linear(textScale)),
        child: app!,
      ),
      home: Scaffold(body: SingleChildScrollView(child: child)),
    ),
  );
  await tester.pump();
}

void main() {
  GoogleFonts.config.allowRuntimeFetching = false;

  group('points card', () {
    for (final (role, label) in [
      ('carpenter', 'Carpenter'),
      ('architect', 'Architect'),
      ('engineer', 'Engineer'),
      ('interior_designer', 'Interior designer'),
    ]) {
      testWidgets('shows the $label role', (tester) async {
        await _pump(tester, HomeHeroCard(homeState: _state(role: role)));
        expect(find.text(label), findsOneWidget);
      });
    }

    testWidgets('shows points, rank and progress to the next tier', (
      tester,
    ) async {
      await _pump(tester, HomeHeroCard(homeState: _state()));
      expect(find.text('3500'), findsOneWidget);
      expect(find.text('#4'), findsOneWidget);
      expect(find.text('1500 pts to Gold'), findsOneWidget);
      expect(find.text('50%'), findsOneWidget);
    });

    testWidgets('no rank yet shows a dash', (tester) async {
      await _pump(tester, HomeHeroCard(homeState: _state(rank: null)));
      expect(find.text('—'), findsOneWidget);
    });

    testWidgets('the gold progress bar actually fills', (tester) async {
      await _pump(tester, HomeHeroCard(homeState: _state()));
      final track = tester.getSize(
        find
            .ancestor(
              of: find.byType(FractionallySizedBox),
              matching: find.byType(Container),
            )
            .first,
      );
      final fill = tester.getSize(
        find.descendant(
          of: find.byType(FractionallySizedBox),
          matching: find.byType(DecoratedBox),
        ),
      );
      expect(fill.height, 8);
      expect(fill.width, closeTo(track.width * 0.5, 1));
    });

    testWidgets('0% and 100% progress both draw safely', (tester) async {
      await _pump(tester, HomeHeroCard(homeState: _state(points: 2000)));
      expect(find.text('0%'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await _pump(tester, HomeHeroCard(homeState: _state(points: 5000)));
      expect(find.text('100%'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('Platinum has no progress bar', (tester) async {
      await _pump(
        tester,
        HomeHeroCard(homeState: _state(tier: 'Platinum', points: 12000)),
      );
      expect(find.text('Platinum'), findsOneWidget);
      expect(find.textContaining('pts to'), findsNothing);
    });

    testWidgets('uses no photo banner, so nothing large to decode', (
      tester,
    ) async {
      await _pump(tester, HomeHeroCard(homeState: _state()));
      expect(find.byType(Image), findsNothing);
    });

    testWidgets('a long name is shown in full', (tester) async {
      const last = 'Venkata Subramanian Ramakrishnan Iyengar';
      await _pump(
        tester,
        HomeHeroCard(homeState: _state(lastName: last)),
        size: const Size(320, 568),
      );
      final name = tester.widget<Text>(find.text('Esha $last'));
      expect(name.maxLines, isNull);
      expect(tester.takeException(), isNull);
    });

    for (final (name, size, scale, dark, locale) in [
      ('small phone', const Size(320, 568), 1.0, false, const Locale('en')),
      ('large text', const Size(320, 568), 2.0, false, const Locale('en')),
      ('dark mode', const Size(390, 844), 1.0, true, const Locale('en')),
      ('Hindi', const Size(320, 568), 1.0, false, const Locale('hi')),
      ('Tamil', const Size(320, 568), 1.0, false, const Locale('ta')),
    ]) {
      testWidgets('home cards have no overflow: $name', (tester) async {
        await _pump(
          tester,
          Column(
            children: [
              HomeHeroCard(
                homeState: _state(role: 'interior_designer', points: 1234567.5),
              ),
              const HomeAddBillCard(),
              const HomeFeatureHighlights(),
            ],
          ),
          size: size,
          textScale: scale,
          dark: dark,
          locale: locale,
        );
        expect(tester.takeException(), isNull);
      });
    }
  });

  group('top members', () {
    const longName = 'Venkata Subramanian Ramakrishnan Iyengar Sundaram';
    List<CarpenterRank> members() => [
      CarpenterRank(rank: 1, name: longName, points: 12345, userId: 'a'),
      CarpenterRank(rank: 2, name: 'Bala', points: 900, userId: 'b'),
      CarpenterRank(
        rank: 3,
        name: 'Chitra Devi',
        points: 800,
        userId: 'c',
        isCurrentUser: true,
      ),
      CarpenterRank(rank: 4, name: longName, points: 700, userId: 'd'),
    ];

    testWidgets('a long name in the list is never cut', (tester) async {
      await _pump(
        tester,
        TopCarpentersList(carpenters: members()),
        size: const Size(320, 568),
      );
      for (final element in find.text(longName).evaluate()) {
        final text = element.widget as Text;
        expect(text.maxLines, isNull);
        expect(text.overflow, isNot(TextOverflow.ellipsis));
        final paragraph = element.renderObject! as RenderParagraph;
        expect(paragraph.didExceedMaxLines, isFalse);
        // Most of the row, not the sliver the old layout left for it.
        expect(paragraph.size.width, greaterThan(150));
      }
      expect(tester.takeException(), isNull);
    });

    testWidgets('a long name on the podium is never cut', (tester) async {
      await _pump(
        tester,
        TopCarpentersDisplay(topCarpenters: members()),
        size: const Size(320, 568),
      );
      final text = tester.widget<Text>(find.text(longName));
      expect(text.maxLines, isNull);
      expect(tester.takeException(), isNull);
    });

    testWidgets('shows exact points, and marks my own row', (tester) async {
      await _pump(tester, TopCarpentersList(carpenters: members()));
      expect(find.textContaining('12345'), findsOneWidget);
      expect(find.textContaining('K'), findsNothing);
      expect(find.text('Chitra Devi (You)'), findsOneWidget);
    });

    testWidgets('no profile photos of other members are shown', (tester) async {
      await _pump(tester, TopCarpentersList(carpenters: members()));
      expect(find.byType(Image), findsNothing);
    });

    for (final (name, size, scale, dark, locale) in [
      ('small phone', const Size(320, 568), 1.0, false, const Locale('en')),
      ('large text', const Size(320, 568), 2.0, false, const Locale('en')),
      ('dark mode', const Size(390, 844), 1.0, true, const Locale('en')),
      ('Hindi', const Size(320, 568), 1.0, false, const Locale('hi')),
      ('Tamil', const Size(320, 568), 1.0, false, const Locale('ta')),
    ]) {
      testWidgets('podium and list have no overflow: $name', (tester) async {
        await _pump(
          tester,
          Column(
            children: [
              TopCarpentersDisplay(topCarpenters: members()),
              TopCarpentersList(carpenters: members()),
            ],
          ),
          size: size,
          textScale: scale,
          dark: dark,
          locale: locale,
        );
        expect(tester.takeException(), isNull);
      });
    }

    testWidgets('fewer than three members still lay out', (tester) async {
      await _pump(
        tester,
        TopCarpentersDisplay(topCarpenters: members().take(1).toList()),
      );
      expect(tester.takeException(), isNull);
    });
  });

  test('Add Bill stays hidden during the Diwali celebration', () {
    final source = File(
      'lib/presentation/screens/carpenter/home/home_page.dart',
    ).readAsStringSync();
    expect(
      source,
      contains('if (!celebrationEnabled) const HomeAddBillCard()'),
    );
  });

  test('the home leaderboard ranks inside the member\'s own role group', () {
    final source = File('lib/providers/home_provider.dart').readAsStringSync();
    // Branch + group board (see role_group_leaderboard_test.dart).
    expect(source, contains('LeaderboardService('));
    expect(source, contains('LeaderboardGroups.of(role)'));
    expect(source, isNot(contains("role != 'carpenter'")));
    // Never every branch's users when the branch is unknown.
    expect(source, isNot(contains("_firestore.collection('users').get(")));
  });

  test('home cards appear with no staggered delay', () {
    final source = File(
      'lib/presentation/screens/carpenter/home/home_page.dart',
    ).readAsStringSync();
    expect(source, isNot(contains('AppAnimations.stagger')));
  });
}
