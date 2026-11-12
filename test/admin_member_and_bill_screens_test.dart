// ignore_for_file: invalid_use_of_visible_for_testing_member
import 'package:balaji_points/core/firebase/app_firestore.dart';
import 'package:balaji_points/l10n/app_localizations.dart';
import 'package:balaji_points/presentation/screens/admin/bill_details_page.dart';
import 'package:balaji_points/presentation/screens/admin/carpenter_profile_detail_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Admin member and bill screens show live data, never typed-in numbers.
void main() {
  late FakeFirebaseFirestore db;

  setUp(() async {
    db = FakeFirebaseFirestore();
    overrideAppFirestoreForTesting(db);
    await db.doc('users/m1').set({
      'firstName': 'Ravi',
      'lastName': 'Kumar Subramaniam',
      'phone': '9876543210',
      'role': 'architect',
      'branchId': 'erode_main',
      'createdAt': Timestamp.fromDate(DateTime(2025, 3, 4)),
    });
    await db.doc('user_points/m1').set({
      'totalPoints': 42.5,
      'tier': 'Silver',
      'pointsHistory': [
        {
          'points': 5,
          'reason': 'Daily spin',
          'date': Timestamp.fromDate(DateTime(2026, 11, 1, 9, 30)),
        },
        // A bill approval: shown as the bill, not repeated.
        {
          'points': 10,
          'reason': 'Bill approval',
          'billId': 'b1',
          'date': Timestamp.fromDate(DateTime(2026, 11, 2)),
        },
      ],
    });
    Future<void> bill(String id, String status, num amount, int day) =>
        db.doc('bills/$id').set({
          'carpenterId': 'm1',
          'status': status,
          'amount': amount,
          'siteName': 'Site $id',
          'rupeesPerPoint': 1000,
          'billDate': Timestamp.fromDate(DateTime(2026, 11, day)),
          'createdAt': Timestamp.fromDate(DateTime(2026, 11, day, 10, 15)),
        });
    await bill('b1', 'approved', 10000, 2);
    await bill('b2', 'approved', 5000, 3);
    await bill('b3', 'pending', 2500, 4);
    await bill('b4', 'rejected', 800, 5);
  });

  tearDown(() => overrideAppFirestoreForTesting(null));

  Future<void> pump(WidgetTester tester, Widget page) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: page,
      ),
    );
    for (var i = 0; i < 6; i++) {
      await tester.pump(const Duration(milliseconds: 50));
    }
  }

  testWidgets('member screen: real counts, points, role and history', (
    tester,
  ) async {
    await pump(tester, const CarpenterProfileDetailScreen(carpenterId: 'm1'));
    expect(tester.takeException(), isNull);
    expect(find.text('Ravi Kumar Subramaniam'), findsOneWidget);
    expect(find.text('Architect'), findsOneWidget);
    expect(find.text('Active'), findsOneWidget);
    expect(find.text('04 Mar 2025'), findsOneWidget);
    // Counts from the 4 bills (never the old typed-in 32 / 5 / 2).
    expect(find.text('32'), findsNothing);
    final counts = find.descendant(
      of: find.byWidgetPredicate(
        (w) => w.runtimeType.toString() == '_CountTile',
      ),
      matching: find.byType(Text),
    );
    final shown = tester.widgetList<Text>(counts).map((t) => t.data).toList();
    expect(
      shown,
      containsAllInOrder(['2', 'Approved', '1', 'Pending', '1', 'Rejected']),
    );
    expect(find.textContaining('15,000'), findsOneWidget); // approved total
    // Pending bill has Approve / Reject.
    expect(find.text('Approve'), findsOneWidget);
    // Daily spin entry is in the history; the bill approval entry is not
    // repeated as a points row.
    await tester.scrollUntilVisible(find.text('Daily Spin'), 300);
    expect(find.text('Daily Spin'), findsOneWidget);
    expect(find.text('Bill approval'), findsNothing);
  });

  testWidgets('tapping a count filters the history', (tester) async {
    await pump(tester, const CarpenterProfileDetailScreen(carpenterId: 'm1'));
    await tester.tap(find.text('Rejected').first);
    await tester.pump();
    await tester.scrollUntilVisible(find.text('Site: Site b4'), 300);
    expect(find.text('Site: Site b4'), findsOneWidget);
    expect(find.text('Site: Site b1'), findsNothing);
    expect(find.text('Daily Spin'), findsNothing);
  });

  testWidgets('bill details: pending bill with member, points and actions', (
    tester,
  ) async {
    await pump(tester, const BillDetailsPage(billId: 'b3'));
    expect(tester.takeException(), isNull);
    expect(find.text('₹2,500'), findsOneWidget);
    expect(find.text('2.50'), findsOneWidget); // ₹2,500 at ₹1,000 / point
    expect(find.text('Ravi Kumar Subramaniam'), findsOneWidget);
    expect(find.text('Architect'), findsOneWidget);
    expect(find.text('Waiting for Approval'), findsOneWidget);
    // Footer actions for a pending bill.
    expect(find.text('Approve'), findsOneWidget);
    expect(find.text('Reject'), findsOneWidget);
    // No dead buttons any more.
    expect(find.byTooltip('PDF'), findsNothing);
    // The footer stays a footer: the bill content above it is on screen.
    final approve = tester.getRect(find.text('Approve'));
    expect(approve.top, greaterThan(800 - 120)); // 2400 / 3 = 800 dp tall
    expect(tester.getRect(find.text('₹2,500')).top, lessThan(300));
  });

  testWidgets('bill details: approved bill has no actions', (tester) async {
    await pump(tester, const BillDetailsPage(billId: 'b1'));
    expect(find.text('Points credited'), findsOneWidget);
    expect(find.text('Approve'), findsNothing);
  });
}
