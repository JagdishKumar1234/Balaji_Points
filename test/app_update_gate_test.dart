import 'package:balaji_points/l10n/app_localizations.dart';
import 'package:balaji_points/presentation/widgets/shared/app_update_dialog.dart';
import 'package:balaji_points/services/platform/app_update_service.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';

void main() {
  GoogleFonts.config.allowRuntimeFetching = false;

  final service = AppUpdateService(firestore: FakeFirebaseFirestore());

  AppUpdateDecision decide(String current, String latest, String minimum) =>
      service.decideUpdate(
        current: current,
        latest: latest,
        minimum: minimum,
        forceFlag: true,
      );

  group('today: the live config, before it is changed', () {
    test('the live 1.1.0 is not blocked', () {
      final decision = decide('1.1.0', '1.0.19', '1.0.19');
      expect(decision.force, isFalse);
      expect(decision.optional, isFalse);
    });

    test('the new 1.1.1 is not blocked', () {
      expect(decide('1.1.1', '1.0.19', '1.0.19').force, isFalse);
    });

    test('an app older than 1.0.19 is blocked', () {
      expect(decide('1.0.18', '1.0.19', '1.0.19').force, isTrue);
    });
  });

  group('after release: latest and minimum set to 1.1.1', () {
    for (final old in ['1.1.0', '1.0.19', '1.0.9', '0.9.0']) {
      test('$old must update', () {
        final decision = decide(old, '1.1.1', '1.1.1');
        expect(decision.force, isTrue);
        expect(decision.target, '1.1.1');
      });
    }

    for (final current in ['1.1.1', '1.1.2', '1.2.0', '2.0.0']) {
      test('$current carries on', () {
        final decision = decide(current, '1.1.1', '1.1.1');
        expect(decision.force, isFalse);
        expect(decision.optional, isFalse);
      });
    }
  });

  group('rule details', () {
    test('versions compare as numbers, not text', () {
      expect(service.compareVersionStrings('1.0.19', '1.0.9'), greaterThan(0));
      expect(service.compareVersionStrings('1.1.0', '1.0.19'), greaterThan(0));
      expect(service.compareVersionStrings('1.1', '1.1.0'), 0);
    });

    test('force flag off: below latest is only offered', () {
      final decision = service.decideUpdate(
        current: '1.1.0',
        latest: '1.1.1',
        minimum: '1.0.19',
        forceFlag: false,
      );
      expect(decision.force, isFalse);
      expect(decision.optional, isTrue);
    });

    test('below the minimum blocks even with the force flag off', () {
      final decision = service.decideUpdate(
        current: '1.1.0',
        latest: '1.1.1',
        minimum: '1.1.1',
        forceFlag: false,
      );
      expect(decision.force, isTrue);
    });

    test('an empty config blocks nobody', () {
      final decision = decide('1.1.0', '', '');
      expect(decision.force, isFalse);
      expect(decision.optional, isFalse);
    });
  });

  group('force update dialog', () {
    Future<void> open(WidgetTester tester, {required bool force}) async {
      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Builder(
            builder: (context) => Scaffold(
              body: TextButton(
                onPressed: () => showDialog<void>(
                  context: context,
                  barrierDismissible: !force,
                  builder: (dialogContext) => AppUpdateDialog(
                    forceUpdate: force,
                    currentVersion: '1.1.0',
                    latestVersion: '1.1.1',
                    minimumVersion: '1.1.1',
                    targetVersion: '1.1.1',
                    onUpdate: () {},
                    onLater: force
                        ? null
                        : () => Navigator.of(dialogContext).pop(),
                  ),
                ),
                child: const Text('open'),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
    }

    testWidgets('has no way out except Update', (tester) async {
      await open(tester, force: true);
      expect(find.text('Update now'), findsOneWidget);
      expect(find.text('Maybe later'), findsNothing);
      expect(find.text('v1.1.0'), findsOneWidget);
      expect(find.text('v1.1.1'), findsOneWidget);
    });

    testWidgets('device Back does not close it', (tester) async {
      await open(tester, force: true);
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(find.byType(AppUpdateDialog), findsOneWidget);
    });

    testWidgets('tapping outside does not close it', (tester) async {
      await open(tester, force: true);
      await tester.tapAt(const Offset(4, 4));
      await tester.pumpAndSettle();
      expect(find.byType(AppUpdateDialog), findsOneWidget);
    });

    testWidgets('an optional update can be closed', (tester) async {
      await open(tester, force: false);
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(find.byType(AppUpdateDialog), findsNothing);
    });
  });
}
