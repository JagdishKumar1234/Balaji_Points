import 'package:balaji_points/core/firebase/app_firestore.dart';
import 'package:balaji_points/core/notifications/notification_category.dart';
import 'package:balaji_points/l10n/app_localizations.dart';
import 'package:balaji_points/presentation/screens/admin/send_notification_page.dart';
import 'package:balaji_points/services/branch/current_branch_service.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Admin "Send Notification": all four roles start selected, the count
/// follows the role chips, and the form fits one phone screen.
void main() {
  late FakeFirebaseFirestore db;

  Future<void> member(String id, String role, {String branch = 'erode'}) => db
      .collection('users')
      .doc(id)
      .set({'role': role, 'branchId': branch, 'profile_verified': true});

  setUp(() async {
    db = FakeFirebaseFirestore();
    overrideAppFirestoreForTesting(db);
    CurrentBranchService.setAdminBranch('erode');
    await member('c1', 'carpenter');
    await member('c2', '');
    await member('i1', 'interior_designer');
    await member('a1', 'architect');
    await member('e1', 'engineer');
    await member('x1', 'carpenter', branch: 'karur');
    await db.collection('users').doc('p1').set({
      'role': 'carpenter',
      'branchId': 'erode',
      'profile_verified': false,
    });
    await db.collection('users').doc('adm').set({
      'role': 'admin',
      'branchId': 'erode',
    });
  });

  tearDown(() => overrideAppFirestoreForTesting(null));

  Future<void> pump(WidgetTester tester) async {
    tester.view.physicalSize = const Size(360, 740);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      const MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: SendNotificationPage(),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('all roles preselected: approved members of this branch', (
    tester,
  ) async {
    await pump(tester);
    expect(find.text('5 members'), findsOneWidget);

    // Untick architect and engineer: carpenters (with no-role) + interior.
    await tester.tap(find.text('Architect'));
    await tester.tap(find.text('Engineer'));
    await tester.pumpAndSettle();
    expect(find.text('3 members'), findsOneWidget);

    // "All members" selects every role again.
    await tester.tap(find.text('All members'));
    await tester.pumpAndSettle();
    expect(find.text('5 members'), findsOneWidget);

    // And clears them all.
    await tester.tap(find.text('All members'));
    await tester.pumpAndSettle();
    expect(find.text('0 members'), findsOneWidget);
  });

  testWidgets('fits one screen with no scrolling', (tester) async {
    await pump(tester);
    expect(tester.takeException(), isNull);
    final pos = tester
        .state<ScrollableState>(
          find
              .descendant(
                of: find.byType(CustomScrollView),
                matching: find.byType(Scrollable),
              )
              .first,
        )
        .position;
    expect(pos.maxScrollExtent, 0);
  });

  testWidgets('send stays off until title and message are filled', (
    tester,
  ) async {
    await pump(tester);
    final send = find.text('Send to 5 members');
    expect(send, findsOneWidget);
    await tester.tap(send);
    await tester.pumpAndSettle();
    expect(find.text('Send notification?'), findsNothing);

    await tester.enterText(find.byType(TextField).first, 'Diwali offer');
    await tester.enterText(find.byType(TextField).last, 'Double points');
    await tester.pumpAndSettle();
    await tester.tap(send);
    await tester.pumpAndSettle();
    expect(find.text('Send notification?'), findsOneWidget);
  });

  test('categories: admin choices match the server list', () {
    expect(NotificationCategory.sendable.map((c) => c.id).toList(), [
      'general',
      'offer',
      'festival',
      'catalog',
      'dailySpin',
      'addBill',
      'wallet',
      'branch',
    ]);
  });

  test('every category route is a member route', () {
    const memberRoutes = {
      '/',
      '/wallet',
      '/profile',
      '/add-bill',
      '/my-branch',
      '/catalogs',
      '/daily-spin',
    };
    for (final c in NotificationCategory.values) {
      if (c.route != null)
        expect(memberRoutes, contains(c.route), reason: c.id);
    }
  });

  test('older notifications get a category from their type', () {
    expect(
      NotificationCategory.of({'type': 'billApproved'}),
      NotificationCategory.bill,
    );
    expect(
      NotificationCategory.of({'type': 'dailySpinWon'}),
      NotificationCategory.dailySpin,
    );
    expect(
      NotificationCategory.of({'type': 'greeting'}),
      NotificationCategory.festival,
    );
    expect(
      NotificationCategory.of({'type': 'announcement', 'category': 'catalog'}),
      NotificationCategory.catalog,
    );
    expect(
      NotificationCategory.of({
        'type': 'announcement',
        'data': {'category': 'wallet'},
      }),
      NotificationCategory.wallet,
    );
    expect(
      NotificationCategory.of({'type': 'x'}),
      NotificationCategory.general,
    );
  });
}
