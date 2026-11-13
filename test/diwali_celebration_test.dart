import 'package:balaji_points/core/constants/app_constants.dart';
import 'package:balaji_points/core/design/app_theme.dart';
import 'package:balaji_points/l10n/app_localizations.dart';
import 'package:balaji_points/presentation/screens/carpenter/home/widgets/diwali_celebration_dialog.dart';
import 'package:balaji_points/services/auth/session_service.dart';
import 'package:balaji_points/services/branch/branch_celebration_service.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';

class _FakeSession implements SessionService {
  _FakeSession({this.userId, this.phone, this.role, this.branchId});

  final String? userId;
  final String? phone;
  final String? role;
  final String? branchId;

  @override
  Future<String?> getUserRole() async => role;
  @override
  Future<String?> getBranchId() async => branchId;

  @override
  Future<String?> getUserId() async => userId;
  @override
  Future<String?> getPhoneNumber() async => phone;
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

Future<BranchCelebrationSummary> _load({String? userId, String? phone}) async {
  final db = FakeFirebaseFirestore();
  const carpenters = {
    'a': ('Asha', 500.0),
    'b': ('Bala', 400.0),
    'c': ('Chitra', 300.0),
    'd': ('Dinesh', 200.0),
    'e': ('Esha', 100.0),
  };
  var nextPhone = 9000000001;
  for (final entry in carpenters.entries) {
    await db.collection('users').doc(entry.key).set({
      'firstName': entry.value.$1,
      'role': 'carpenter',
      'branchId': 'b1',
      'phone': '${nextPhone++}',
      'totalPoints': entry.value.$2,
      'profile_verified': true,
    });
  }
  // Older Erode accounts have no role saved: they still count as carpenters.
  await db.collection('users').doc('no-role').set({
    'firstName': 'Noor',
    'branchId': 'b1',
    'phone': '9000000009',
    'totalPoints': 50,
    'profile_verified': true,
  });
  await db.collection('users').doc('other').set({
    'firstName': 'Other',
    'role': 'carpenter',
    'branchId': 'b2',
    'totalPoints': 9999,
    'profile_verified': true,
  });
  await db.collection('users').doc('admin').set({
    'firstName': 'Admin',
    'role': 'admin',
    'branchId': 'b1',
    'totalPoints': 9999,
  });
  return BranchCelebrationService(
    firestore: db,
    session: _FakeSession(userId: userId, phone: phone),
  ).loadCelebrationSummary('b1');
}

Future<void> _pumpDialog(
  WidgetTester tester,
  BranchCelebrationSummary summary, {
  String branchName = 'Erode',
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
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(
          context,
        ).copyWith(textScaler: TextScaler.linear(textScale)),
        child: child!,
      ),
      home: Scaffold(
        body: DiwaliCelebrationDialog(branchName: branchName, summary: summary),
      ),
    ),
  );
  await tester.pump(const Duration(seconds: 1));
}

Future<void> _finish(WidgetTester tester) =>
    tester.pumpWidget(const SizedBox.shrink());

void main() {
  GoogleFonts.config.allowRuntimeFetching = false;

  group('the four member roles', () {
    test('only those roles, and older accounts, count as members', () {
      for (final role in [
        'carpenter',
        'architect',
        'engineer',
        'interior_designer',
        'Architect',
        '',
        null,
      ]) {
        expect(AppConstants.isMemberRole(role), isTrue, reason: '$role');
      }
      for (final role in ['admin', 'super_admin', 'dealer']) {
        expect(AppConstants.isMemberRole(role), isFalse, reason: role);
      }
    });

    test(
      'ranked only inside their own role group; staff and other branches are not',
      () async {
        final db = FakeFirebaseFirestore();
        const people = {
          'c': ('Chitra', 'carpenter', 'b1', 100),
          'a': ('Arun', 'architect', 'b1', 400),
          'e': ('Ezhil', 'engineer', 'b1', 300),
          'i': ('Indu', 'interior_designer', 'b1', 200),
          'staff': ('Staff', 'admin', 'b1', 900),
          'boss': ('Boss', 'super_admin', 'b1', 900),
          'away': ('Away', 'architect', 'b2', 900),
          'awayc': ('AwayC', 'carpenter', 'b2', 900),
        };
        for (final entry in people.entries) {
          final (name, role, branch, points) = entry.value;
          await db.collection('users').doc(entry.key).set({
            'firstName': name,
            'role': role,
            'branchId': branch,
            'totalPoints': points,
            'profile_verified': true,
          });
        }
        Future<BranchCelebrationSummary> as(String id) =>
            BranchCelebrationService(
              firestore: db,
              session: _FakeSession(userId: id),
            ).loadCelebrationSummary('b1');

        final trade = await as('i');
        expect(trade.topThree.map((e) => e.name), ['Indu', 'Chitra']);
        expect(trade.currentUser!.rank, 1);

        final pro = await as('e');
        expect(pro.topThree.map((e) => e.name), ['Arun', 'Ezhil']);
        expect(pro.currentUser!.rank, 2);
      },
    );

    Future<bool> enabledFor(String? role) async {
      final db = FakeFirebaseFirestore();
      await db.collection('branches').doc('b1').set({
        'diwaliCelebrationEnabled': true,
      });
      return BranchCelebrationService(
        firestore: db,
        session: _FakeSession(role: role, branchId: 'b1'),
      ).watchCurrentBranchEnabled().first;
    }

    for (final role in [
      'carpenter',
      'architect',
      'engineer',
      'interior_designer',
    ]) {
      test('$role gets the celebration', () async {
        expect(await enabledFor(role), isTrue);
      });
    }

    for (final role in ['admin', 'super_admin', null]) {
      test('$role does not get the celebration', () async {
        expect(await enabledFor(role), isFalse);
      });
    }

    test('a switched-off branch shows it to nobody', () async {
      final db = FakeFirebaseFirestore();
      await db.collection('branches').doc('b1').set({
        'diwaliCelebrationEnabled': false,
      });
      final enabled = await BranchCelebrationService(
        firestore: db,
        session: _FakeSession(role: 'architect', branchId: 'b1'),
      ).watchCurrentBranchEnabled().first;
      expect(enabled, isFalse);
    });
  });

  group('loadCelebrationSummary', () {
    test('returns only the top three, in order', () async {
      final summary = await _load(userId: 'e');
      expect(summary.topThree.map((e) => e.name), ['Asha', 'Bala', 'Chitra']);
      expect(summary.topThree.map((e) => e.rank), [1, 2, 3]);
    });

    test('finds the logged-in carpenter outside the top three', () async {
      final me = (await _load(userId: 'e')).currentUser!;
      expect(me.name, 'Esha');
      expect(me.points, 100);
      expect(me.rewardAmount, 1000);
      expect(me.bonusAmount, 0);
      expect(me.isCurrentUser, isTrue);
    });

    test('the card gets a position and both parts of the name', () async {
      final db = FakeFirebaseFirestore();
      await db.collection('users').doc('me').set({
        'firstName': 'Esha',
        'lastName': 'Raman',
        'role': 'carpenter',
        'branchId': 'b1',
        'totalPoints': 10,
        'profile_verified': true,
      });
      await db.collection('users').doc('top').set({
        'firstName': 'Asha',
        'role': 'carpenter',
        'branchId': 'b1',
        'totalPoints': 50,
        'profile_verified': true,
      });
      final me = (await BranchCelebrationService(
        firestore: db,
        session: _FakeSession(userId: 'me'),
      ).loadCelebrationSummary('b1')).currentUser!;
      expect(me.name, 'Esha Raman');
      expect(me.rank, 2);
    });

    test('a Google account with only a display name shows it', () async {
      final db = FakeFirebaseFirestore();
      await db.collection('users').doc('me').set({
        'displayName': 'Esha Raman',
        'role': 'carpenter',
        'branchId': 'b1',
        'totalPoints': 10,
        'profile_verified': true,
      });
      final me = (await BranchCelebrationService(
        firestore: db,
        session: _FakeSession(userId: 'me'),
      ).loadCelebrationSummary('b1')).currentUser!;
      expect(me.name, 'Esha Raman');
    });

    test('an account with no role saved is found', () async {
      final me = (await _load(userId: 'no-role')).currentUser!;
      expect(me.name, 'Noor');
    });

    test('marks the user in the top three', () async {
      final summary = await _load(userId: 'a');
      expect(summary.topThree.first.isCurrentUser, isTrue);
      expect(summary.topThree[1].isCurrentUser, isFalse);
      expect(summary.currentUser!.bonusAmount, 10000);
    });

    test('falls back to the phone number for an older session', () async {
      final me = (await _load(userId: 'old', phone: '9000000004')).currentUser;
      expect(me?.name, 'Dinesh');
    });

    test('no match gives no personal entry', () async {
      final summary = await _load(userId: 'stranger', phone: '1111111111');
      expect(summary.currentUser, isNull);
      expect(summary.topThree, hasLength(3));
    });

    test('other branches and admins are never ranked', () async {
      final names = (await _load(userId: 'a')).topThree.map((e) => e.name);
      expect(names, isNot(contains('Other')));
      expect(names, isNot(contains('Admin')));
    });
  });

  group('DiwaliCelebrationDialog', () {
    Future<BranchCelebrationSummary> load(WidgetTester t, String id) async =>
        (await t.runAsync(() => _load(userId: id)))!;

    testWidgets('shows my prize and the top three, and nobody else', (
      tester,
    ) async {
      await _pumpDialog(tester, await load(tester, 'e'));
      expect(find.text('Your Diwali prize'), findsOneWidget);
      expect(find.text('100.00'), findsOneWidget);
      // Members never see rupee amounts.
      expect(find.textContaining('₹'), findsNothing);
      expect(find.text('Asha'), findsOneWidget);
      expect(find.text('Chitra'), findsOneWidget);
      expect(find.textContaining('Dinesh'), findsNothing);
      await _finish(tester);
    });

    testWidgets('a long branch name is shown in full, not cut', (tester) async {
      const name =
          'Sri Balaji Plywood and Hardwares, 150 VCTV Main Road, Erode';
      await _pumpDialog(
        tester,
        await load(tester, 'e'),
        branchName: name,
        size: const Size(320, 568),
      );
      final text = tester.widget<Text>(find.text(name));
      expect(text.maxLines, isNull);
      expect(text.overflow, isNot(TextOverflow.ellipsis));
      expect(
        tester.getSize(find.text(name)).height,
        greaterThan(30),
        reason: 'should wrap onto more than one line',
      );
      expect(tester.takeException(), isNull);
      await _finish(tester);
    });

    testWidgets('my card shows my full name, points and position', (
      tester,
    ) async {
      await _pumpDialog(
        tester,
        const BranchCelebrationSummary(
          topThree: [
            BranchCelebrationEntry(name: 'Asha', points: 500, rank: 1),
          ],
          currentUser: BranchCelebrationEntry(
            name: 'Esha Kumar Raman',
            points: 100,
            rank: 42,
            isCurrentUser: true,
          ),
        ),
      );
      expect(find.text('Esha Kumar Raman'), findsOneWidget);
      expect(find.text('100.00'), findsOneWidget);
      expect(find.text('#42'), findsOneWidget);
      expect(find.text('Position'), findsOneWidget);
      await _finish(tester);
    });

    testWidgets('never shows a phone number or branch totals', (tester) async {
      await _pumpDialog(tester, await load(tester, 'e'));
      final texts = tester
          .widgetList<Text>(find.byType(Text))
          .map((text) => text.data ?? '');
      for (final text in texts) {
        expect(RegExp(r'\d{10}').hasMatch(text), isFalse, reason: text);
        expect(text, isNot(contains('Total')));
      }
      await _finish(tester);
    });

    testWidgets('a winner sees their bonus and is marked in the list', (
      tester,
    ) async {
      await _pumpDialog(tester, await load(tester, 'a'));
      // The prize (trophy / gift) is shown, never a rupee amount.
      expect(find.text('Mega Trophy'), findsWidgets);
      expect(find.textContaining('₹'), findsNothing);
      expect(find.text('Asha (You)'), findsOneWidget);
      await _finish(tester);
    });

    for (final (name, size, scale, dark, locale) in [
      ('small phone', const Size(320, 568), 1.0, false, const Locale('en')),
      ('large text', const Size(320, 568), 2.0, false, const Locale('en')),
      ('landscape', const Size(844, 390), 1.0, false, const Locale('en')),
      ('dark mode', const Size(390, 844), 1.0, true, const Locale('en')),
      ('Hindi', const Size(390, 844), 1.0, false, const Locale('hi')),
      ('Tamil', const Size(390, 844), 1.0, false, const Locale('ta')),
    ]) {
      testWidgets('has no overflow: $name', (tester) async {
        await _pumpDialog(
          tester,
          await load(tester, 'a'),
          size: size,
          textScale: scale,
          dark: dark,
          locale: locale,
        );
        expect(tester.takeException(), isNull);
        await _finish(tester);
      });
    }
  });
}
