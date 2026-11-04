import 'dart:io';

import 'package:balaji_points/core/design/app_theme.dart';
import 'package:balaji_points/core/layout/carpenter_shell_layout.dart';
import 'package:balaji_points/l10n/app_localizations.dart';
import 'package:balaji_points/presentation/widgets/carpenter/carpenter_bottom_nav_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';

const _labels = {
  'en': ['Home', 'Wallet', 'Add Bill', 'Alerts', 'Profile'],
  'hi': ['होम', 'वॉलेट', 'बिल जोड़ें', 'सूचनाएं', 'प्रोफाइल'],
  'ta': ['முகப்பு', 'வாலெட்', 'பில் சேர்', 'அறிவிப்பு', 'சுயவிவரம்'],
};

Future<void> _pump(
  WidgetTester tester, {
  Size size = const Size(390, 844),
  double textScale = 1,
  bool dark = false,
  String locale = 'en',
  bool showAddBill = true,
  int currentIndex = 0,
  ValueChanged<int>? onTab,
  VoidCallback? onAdd,
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(
    MaterialApp(
      theme: dark ? AppThemeData.dark() : AppThemeData.light(),
      locale: Locale(locale),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(
          context,
        ).copyWith(textScaler: TextScaler.linear(textScale)),
        child: child!,
      ),
      home: Scaffold(
        body: Align(
          alignment: Alignment.bottomCenter,
          child: CarpenterBottomNavBar(
            currentIndex: currentIndex,
            onTabSelected: onTab ?? (_) {},
            onAddBillTap: onAdd ?? () {},
            bottomInset: 0,
            showAddBill: showAddBill,
          ),
        ),
      ),
    ),
  );
  await tester.pump(const Duration(milliseconds: 300));
}

void main() {
  GoogleFonts.config.allowRuntimeFetching = false;

  for (final entry in _labels.entries) {
    testWidgets('${entry.key}: no label is cut on the smallest phone', (
      tester,
    ) async {
      await _pump(tester, locale: entry.key, size: const Size(320, 568));
      for (final label in entry.value) {
        final finder = find.text(label);
        expect(finder, findsOneWidget, reason: label);
        final text = tester.widget<Text>(finder);
        expect(text.overflow, isNot(TextOverflow.ellipsis), reason: label);
        final paragraph = tester.renderObject<RenderParagraph>(finder);
        expect(paragraph.didExceedMaxLines, isFalse, reason: label);
        // Fully inside a fifth of the screen, once any shrinking is applied.
        expect(
          tester.getSize(finder).width,
          lessThanOrEqualTo(64),
          reason: label,
        );
      }
      expect(tester.takeException(), isNull);
    });
  }

  for (final (name, size, scale, dark, locale) in [
    ('large text', const Size(320, 568), 2.0, false, 'en'),
    ('large text in Tamil', const Size(320, 568), 2.0, false, 'ta'),
    ('dark mode', const Size(390, 844), 1.0, true, 'en'),
    ('tablet', const Size(800, 1000), 1.0, false, 'en'),
  ]) {
    testWidgets('has no overflow: $name', (tester) async {
      await _pump(
        tester,
        size: size,
        textScale: scale,
        dark: dark,
        locale: locale,
      );
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('each tab reports its own index', (tester) async {
    final tapped = <int>[];
    await _pump(tester, onTab: tapped.add);
    for (final label in ['Home', 'Wallet', 'Alerts', 'Profile']) {
      await tester.tap(find.text(label));
    }
    expect(tapped, [0, 1, 2, 3]);
  });

  testWidgets('the raised part of Add Bill can be tapped', (tester) async {
    var taps = 0;
    await _pump(tester, onAdd: () => taps++);
    final button = tester.getRect(find.byKey(const ValueKey('nav-add-bill')));
    final bar = tester.getRect(find.byType(CarpenterBottomNavBar));
    // The top edge sits in the raised strip, above the navy bar.
    expect(button.top, lessThan(bar.top + CarpenterShellLayout.navBarRaise));
    await tester.tapAt(Offset(button.center.dx, button.top + 3));
    expect(taps, 1);
  });

  testWidgets('the strip above the bar does not catch taps for a tab', (
    tester,
  ) async {
    final tapped = <int>[];
    await _pump(tester, onTab: tapped.add);
    final bar = tester.getRect(find.byType(CarpenterBottomNavBar));
    final wallet = tester.getCenter(find.text('Wallet'));
    await tester.tapAt(Offset(wallet.dx, bar.top + 4));
    expect(tapped, isEmpty);
    await tester.tapAt(wallet);
    expect(tapped, [1]);
  });

  test('the page reaches the navy bar, leaving no empty band', () {
    const mq = MediaQueryData(padding: EdgeInsets.only(bottom: 34));
    expect(
      CarpenterShellLayout.contentBottomPadding(mq),
      CarpenterShellLayout.navBarHeight - CarpenterShellLayout.navBarRaise + 34,
    );
    expect(
      CarpenterShellLayout.scrollEndMargin,
      greaterThan(CarpenterShellLayout.navBarRaise),
    );
    expect(
      File(
        'lib/presentation/screens/common/dashboard/dashboard_page.dart',
      ).readAsStringSync(),
      contains('CarpenterShellLayout.contentBottomPadding(mq)'),
    );
  });

  testWidgets('during Diwali there is no Add Bill, and tabs still work', (
    tester,
  ) async {
    final tapped = <int>[];
    await _pump(tester, showAddBill: false, onTab: tapped.add);
    expect(find.text('Add Bill'), findsNothing);
    await tester.tap(find.text('Alerts'));
    expect(tapped, [2]);
  });

  testWidgets('screen readers still hear the full word', (tester) async {
    final handle = tester.ensureSemantics();
    await _pump(tester);
    expect(find.bySemanticsLabel('Notifications'), findsOneWidget);
    handle.dispose();
  });

  testWidgets('the phone home-indicator area stays clear', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: Align(
            alignment: Alignment.bottomCenter,
            child: CarpenterBottomNavBar(
              currentIndex: 0,
              onTabSelected: (_) {},
              onAddBillTap: () {},
              bottomInset: 34,
            ),
          ),
        ),
      ),
    );
    expect(
      tester.getSize(find.byType(CarpenterBottomNavBar)).height,
      CarpenterShellLayout.navBarHeight + 34,
    );
  });
}
