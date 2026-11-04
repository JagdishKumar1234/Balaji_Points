import 'dart:io';

import 'package:balaji_points/l10n/app_localizations.dart';
import 'package:balaji_points/presentation/screens/common/auth/login_page.dart';
import 'package:balaji_points/presentation/widgets/shared/app_button.dart';
import 'package:balaji_points/presentation/widgets/shared/auth_scaffold.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

const _backKey = ValueKey('auth-back-button');

/// `/login` → (push) `/a`, and `/b` which only opens with `go`.
GoRouter _router({VoidCallback? onBack}) => GoRouter(
  initialLocation: '/login',
  routes: [
    GoRoute(path: '/login', builder: (_, __) => const Text('login-screen')),
    GoRoute(
      path: '/a',
      builder: (_, __) =>
          AuthScaffold(onBack: onBack, child: const Text('a-screen')),
    ),
    GoRoute(
      path: '/b',
      builder: (_, __) =>
          const AuthScaffold(fallbackRoute: '/a', child: Text('b-screen')),
    ),
  ],
);

Future<void> _pump(WidgetTester tester, GoRouter router) async {
  await tester.pumpWidget(MaterialApp.router(routerConfig: router));
  await tester.pumpAndSettle();
}

void main() {
  for (final device in [false, true]) {
    final name = device ? 'device Back' : 'back button';

    Future<void> press(WidgetTester tester) async {
      if (device) {
        await tester.binding.handlePopRoute();
      } else {
        await tester.tap(find.byKey(_backKey));
      }
      await tester.pumpAndSettle();
    }

    testWidgets('$name returns to the previous screen', (tester) async {
      final router = _router();
      await _pump(tester, router);
      router.push('/a');
      await tester.pumpAndSettle();
      await press(tester);
      expect(find.text('login-screen'), findsOneWidget);
    });

    testWidgets('$name uses the fallback when nothing is behind', (
      tester,
    ) async {
      final router = _router();
      await _pump(tester, router);
      router.go('/b');
      await tester.pumpAndSettle();
      await press(tester);
      expect(find.text('a-screen'), findsOneWidget);
    });

    testWidgets('$name runs a custom action instead of navigating', (
      tester,
    ) async {
      var calls = 0;
      final router = _router(onBack: () => calls++);
      await _pump(tester, router);
      router.go('/a');
      await tester.pumpAndSettle();
      await press(tester);
      expect(calls, 1);
      expect(find.text('a-screen'), findsOneWidget);
    });
  }

  testWidgets('frame shows the square splash logo centred at the top', (
    tester,
  ) async {
    final router = _router();
    await _pump(tester, router);
    router.go('/a');
    await tester.pumpAndSettle();

    final logo = find.byType(BrandLogo);
    final image = tester.widget<Image>(
      find.descendant(of: logo, matching: find.byType(Image)),
    );
    expect((image.image as AssetImage).assetName, contains('splash_logo.png'));

    final rect = tester.getRect(logo);
    expect(rect.width, rect.height);
    expect(
      rect.center.dx,
      tester.view.physicalSize.width / tester.view.devicePixelRatio / 2,
    );
    expect(rect.top, lessThan(tester.getTopLeft(find.text('a-screen')).dy));
  });

  testWidgets('Login with PIN is a solid button with an icon', (tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: LoginPage(),
        ),
      ),
    );
    final button = tester.widget<AppButton>(
      find.ancestor(
        of: find.text('Login with PIN'),
        matching: find.byType(AppButton),
      ),
    );
    expect(button.variant, AppButtonVariant.strong);
    expect(button.icon, Icons.dialpad_rounded);
  });

  group('auth screens in the source', () {
    const dir = 'lib/presentation/screens/common/auth';
    // pin_setup_page.dart has no route, so nothing can open it.
    const pages = [
      'login_page.dart',
      'phone_pin_entry_page.dart',
      'pin_login_page.dart',
      'reset_pin_page.dart',
      'forgot_password_page.dart',
      'register_page.dart',
    ];

    for (final page in pages) {
      test('$page uses the shared frame only', () {
        final source = File('$dir/$page').readAsStringSync();
        expect(source, contains('AuthScaffold('));
        expect(source, isNot(contains('PopScope(')));
        expect(source, isNot(contains('balaji_point_logo')));
        expect(source, isNot(contains('Icons.arrow_back')));
      });
    }

    test('every auth link goes to a route that exists', () {
      final routes = File('lib/config/routes.dart').readAsStringSync();
      final link = RegExp(r"context\.(?:go|push)\(\s*'(/[^'?]*)");
      for (final page in pages) {
        final source = File('$dir/$page').readAsStringSync();
        for (final match in link.allMatches(source)) {
          expect(
            routes,
            contains("path: '${match.group(1)}'"),
            reason: '$page links to ${match.group(1)}',
          );
        }
      }
    });
  });
}
