import 'package:balaji_points/core/models/catalog.dart';
import 'package:balaji_points/l10n/app_localizations.dart';
import 'package:balaji_points/presentation/widgets/admin/catalogs_management.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

/// Admin "Add catalog": Save is fixed at the bottom, above Android's
/// navigation bar, without scrolling.
void main() {
  Future<void> pump(WidgetTester tester, {double navBar = 0}) async {
    tester.view.physicalSize = const Size(1080, 2220); // 360 x 740 dp
    tester.view.devicePixelRatio = 3;
    // Android 3-button / gesture bar at the bottom of the screen.
    tester.view.padding = FakeViewPadding(bottom: navBar * 3);
    tester.view.viewPadding = FakeViewPadding(bottom: navBar * 3);
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const CatalogFormPage(
            categories: [CatalogCategory(id: 'doors', name: 'Doors')],
          ),
        ),
      ),
    );
    await tester.pump();
  }

  for (final navBar in [0.0, 48.0]) {
    testWidgets('Save is pinned at the bottom (nav bar ${navBar.round()} dp)', (
      tester,
    ) async {
      await pump(tester, navBar: navBar);
      expect(tester.takeException(), isNull);
      final save = tester.getRect(find.text('Save'));
      // Visible without scrolling, and above the navigation bar.
      expect(save.bottom, lessThanOrEqualTo(740 - navBar));
      expect(save.bottom, greaterThan(740 - navBar - 90));
      // Still there after scrolling the form.
      await tester.drag(find.byType(ListView).first, const Offset(0, -600));
      await tester.pump();
      expect(tester.getRect(find.text('Save')), save);
    });
  }
}
