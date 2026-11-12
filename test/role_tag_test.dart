import 'package:balaji_points/l10n/app_localizations.dart';
import 'package:balaji_points/presentation/widgets/shared/role_label.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Admin bill cards show the member's role name.
void main() {
  Future<void> pump(WidgetTester tester, Widget child) => tester.pumpWidget(
    MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(body: Center(child: child)),
    ),
  );

  testWidgets('built-in roles use their translated name', (tester) async {
    await pump(tester, const RoleTag(roleId: 'architect'));
    expect(find.text('Architect'), findsOneWidget);
    await pump(tester, const RoleTag(roleId: 'Carpenter'));
    expect(find.text('Carpenter'), findsOneWidget);
  });

  testWidgets('custom role shows its saved name', (tester) async {
    await pump(tester, const RoleTag(roleId: 'mason', storedName: 'Mason'));
    expect(find.text('Mason'), findsOneWidget);
  });

  testWidgets('no role shows nothing', (tester) async {
    await pump(tester, const RoleTag(roleId: null));
    expect(find.byType(Text), findsNothing);
  });
}
