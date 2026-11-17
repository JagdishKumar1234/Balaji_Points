import 'package:balaji_points/l10n/app_localizations.dart';
import 'package:balaji_points/presentation/widgets/admin/admin_bottom_nav_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('each admin tab and Add Bill report the right action', (
    tester,
  ) async {
    final tapped = <AdminTab>[];
    var addBill = 0;
    tester.view.physicalSize = const Size(360, 740);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          bottomNavigationBar: AdminBottomNavBar(
            current: AdminTab.home,
            onTab: tapped.add,
            onAddBill: () => addBill++,
            billsBadge: 3,
          ),
        ),
      ),
    );
    for (final t in AdminTab.values) {
      await tester.tap(find.byKey(ValueKey('admin-tab-${t.name}')));
    }
    await tester.tap(find.byKey(const ValueKey('admin-nav-add-bill')));
    expect(tapped, AdminTab.values);
    expect(addBill, 1);
    expect(find.text('3'), findsOneWidget, reason: 'bills badge');
    expect(tester.takeException(), isNull);
  });
}
