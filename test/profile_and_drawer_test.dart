import 'dart:io';

import 'package:balaji_points/core/design/app_theme.dart';
import 'package:balaji_points/l10n/app_localizations.dart';
import 'package:balaji_points/presentation/screens/carpenter/home/widgets/home_drawer.dart';
import 'package:balaji_points/presentation/screens/carpenter/profile/widgets/profile_widgets.dart';
import 'package:balaji_points/presentation/widgets/carpenter/member_identity.dart';
import 'package:balaji_points/providers/home_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';

const _longName = 'Venkata Subramanian Ramakrishnan Iyengar Sundaram';

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
      home: Scaffold(body: child),
    ),
  );
  await tester.pump();
}

HomeState _home({String? role, String? roleName}) => HomeState(
  points: 1234.5,
  userData: {
    'firstName': 'Esha',
    'lastName': 'Raman',
    'phone': '9000000001',
    'role': ?role,
    'roleName': ?roleName,
  },
);

Widget _drawer(HomeState state) => HomeDrawer(
  homeState: state,
  appVersion: 'Version 1',
  onLogout: (_) async {},
);

Widget _profileHeader(String role) => SingleChildScrollView(
  child: Builder(
    builder: (context) => ProfileHeader(
      name: _longName,
      roleName: memberRoleName(context, {'role': role}),
      displayId: '123',
      phone: '9000000001',
      points: '12,34,567.50',
      tier: 'Platinum',
    ),
  ),
);

void main() {
  GoogleFonts.config.allowRuntimeFetching = false;

  test('My Orders is gone from the profile screen', () {
    final source = File(
      'lib/presentation/screens/carpenter/profile/profile_page.dart',
    ).readAsStringSync();
    expect(source, isNot(contains('myOrders')));
    expect(source, isNot(contains("'/orders'")));
  });

  group('role shown', () {
    for (final (role, expected) in [
      ('carpenter', 'Carpenter'),
      ('architect', 'Architect'),
      ('engineer', 'Engineer'),
      ('interior_designer', 'Interior designer'),
    ]) {
      testWidgets('side menu and profile show $expected', (tester) async {
        await _pump(tester, _drawer(_home(role: role)));
        expect(find.text(expected), findsOneWidget);
        await _pump(tester, _profileHeader(role));
        expect(find.text(expected), findsOneWidget);
      });
    }

    testWidgets('an older account with no role counts as a carpenter', (
      tester,
    ) async {
      await _pump(tester, _drawer(_home()));
      expect(find.text('Carpenter'), findsOneWidget);
    });

    testWidgets('a renamed role shows the saved name', (tester) async {
      await _pump(
        tester,
        _drawer(_home(role: 'engineer', roleName: 'Site Engineer')),
      );
      expect(find.text('Site Engineer'), findsOneWidget);
    });
  });

  group('side menu', () {
    testWidgets('shows the member, points and every menu item', (tester) async {
      await _pump(tester, _drawer(_home(role: 'carpenter')));
      expect(find.text('Esha Raman'), findsOneWidget);
      expect(find.text('9000000001'), findsOneWidget);
      expect(find.text('1234.5'), findsOneWidget);
      // Exactly these options, in this order.
      const items = [
        'Home',
        'Wallet',
        'Notifications',
        'Profile',
        'Catalogs',
        'About Us',
        'Contact Us',
      ];
      for (final label in items) {
        expect(find.text(label), findsOneWidget, reason: label);
      }
      final ys = [for (final l in items) tester.getTopLeft(find.text(l)).dy];
      for (var i = 1; i < ys.length; i++) {
        expect(ys[i], greaterThan(ys[i - 1]), reason: items[i]);
      }
      for (final label in ['Daily Spin', 'My Branch', 'Add Bill']) {
        expect(find.text(label), findsNothing, reason: label);
      }
      expect(find.text('Logout'), findsOneWidget);
      // Logout is pinned at the bottom of the menu, not floating mid-way.
      final menuBottom = tester.getRect(find.byType(Drawer)).bottom;
      final logoutBottom = tester.getRect(find.text('Logout')).bottom;
      expect(menuBottom - logoutBottom, lessThan(80));
    });

    for (final (name, size, scale, dark, locale) in [
      ('small phone', const Size(320, 568), 1.0, false, const Locale('en')),
      ('large text', const Size(320, 568), 2.0, false, const Locale('en')),
      ('dark mode', const Size(390, 844), 1.0, true, const Locale('en')),
      ('Hindi', const Size(320, 568), 1.0, false, const Locale('hi')),
      ('Tamil', const Size(320, 568), 1.0, false, const Locale('ta')),
    ]) {
      testWidgets('has no overflow: $name', (tester) async {
        await _pump(
          tester,
          _drawer(_home(role: 'interior_designer')),
          size: size,
          textScale: scale,
          dark: dark,
          locale: locale,
        );
        expect(tester.takeException(), isNull);
      });
    }
  });

  group('profile', () {
    testWidgets('a long name is shown in full, not cut', (tester) async {
      await _pump(
        tester,
        _profileHeader('carpenter'),
        size: const Size(320, 568),
      );
      final name = tester.widget<Text>(find.text(_longName));
      expect(name.maxLines, isNull);
      expect(name.overflow, isNot(TextOverflow.ellipsis));
      expect(find.text('#BP123  ·  9000000001'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('a photo-less member gets initials', (tester) async {
      await _pump(tester, const MemberAvatar(name: 'Esha Raman', size: 60));
      expect(find.text('ER'), findsOneWidget);
    });

    testWidgets('an empty name does not crash the avatar', (tester) async {
      await _pump(tester, const MemberAvatar(name: '', size: 60));
      expect(tester.takeException(), isNull);
    });

    testWidgets('tiles have no overflow with long text and a control', (
      tester,
    ) async {
      await _pump(
        tester,
        ProfileMenuGroup(
          title: 'Preferences',
          children: [
            ProfileMenuTile(
              icon: Icons.language,
              title: 'A very long setting title that has to wrap',
              trailing: const SizedBox(width: 100, height: 36),
            ),
            ProfileMenuTile(icon: Icons.info, title: 'About', onTap: () {}),
          ],
        ),
        size: const Size(320, 568),
        textScale: 2,
      );
      expect(tester.takeException(), isNull);
      expect(find.byIcon(Icons.chevron_right_rounded), findsOneWidget);
    });

    for (final (name, size, scale, dark) in [
      ('small phone', const Size(320, 568), 1.0, false),
      ('large text', const Size(320, 568), 2.0, false),
      ('dark mode', const Size(390, 844), 1.0, true),
    ]) {
      testWidgets('header has no overflow: $name', (tester) async {
        await _pump(
          tester,
          _profileHeader('interior_designer'),
          size: size,
          textScale: scale,
          dark: dark,
        );
        expect(tester.takeException(), isNull);
      });
    }
  });
}
