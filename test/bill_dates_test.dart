import 'package:balaji_points/l10n/app_localizations.dart';
import 'package:balaji_points/presentation/widgets/admin/bill_dates.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Admin bill cards show every date with its time and never cut them off.
void main() {
  Future<void> pump(WidgetTester tester, Map<String, dynamic> bill) =>
      tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: Center(
              // A narrow phone card.
              child: SizedBox(width: 300, child: BillDates(bill: bill)),
            ),
          ),
        ),
      );

  Timestamp at(int d, int h, int m) =>
      Timestamp.fromDate(DateTime(2026, 11, d, h, m));

  testWidgets('approved bill: bill date, submitted and approved times', (
    tester,
  ) async {
    await pump(tester, {
      'status': 'approved',
      'billDate': at(10, 0, 0),
      'createdAt': at(12, 10, 42),
      'approvedAt': at(12, 15, 5),
    });
    expect(tester.takeException(), isNull);
    expect(
      find.textContaining('10 Nov 2026', findRichText: true),
      findsOneWidget,
    );
    expect(find.textContaining('12:00 AM', findRichText: true), findsNothing);
    expect(
      find.textContaining('12 Nov 2026, 10:42 AM', findRichText: true),
      findsOneWidget,
    );
    expect(
      find.textContaining('12 Nov 2026, 03:05 PM', findRichText: true),
      findsOneWidget,
    );
  });

  testWidgets('rejected bill shows the rejection time', (tester) async {
    await pump(tester, {
      'status': 'rejected',
      'createdAt': at(12, 9, 0),
      'rejectedAt': at(12, 18, 30),
    });
    expect(
      find.textContaining('Rejected: ', findRichText: true),
      findsOneWidget,
    );
    expect(
      find.textContaining('12 Nov 2026, 06:30 PM', findRichText: true),
      findsOneWidget,
    );
  });

  testWidgets('pending bill: submitted time always shown', (tester) async {
    await pump(tester, {'status': 'pending', 'createdAt': at(12, 11, 15)});
    expect(
      find.textContaining('12 Nov 2026, 11:15 AM', findRichText: true),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });
}
