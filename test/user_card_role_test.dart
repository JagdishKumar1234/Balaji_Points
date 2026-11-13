import 'package:balaji_points/core/design/app_theme.dart';
import 'package:balaji_points/l10n/app_localizations.dart';
import 'package:balaji_points/presentation/widgets/admin/users_list/user_list_item.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';

Future<void> _pump(WidgetTester tester, Map<String, dynamic> data) =>
    tester.pumpWidget(
      MaterialApp(
        theme: AppThemeData.light(),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: UserListItem(
            userId: 'u1',
            userData: {
              'firstName': 'Ravi',
              'lastName': 'K',
              'phone': '9000000001',
              'totalPoints': 12,
              ...data,
            },
          ),
        ),
      ),
    );

void main() {
  GoogleFonts.config.allowRuntimeFetching = false;

  for (final (role, label) in [
    ('carpenter', 'Carpenter'),
    ('interior_designer', 'Interior designer'),
    ('architect', 'Architect'),
    ('engineer', 'Engineer'),
  ]) {
    testWidgets('admin user card shows the role: $role', (tester) async {
      await _pump(tester, {'role': role});
      expect(find.byKey(const ValueKey('user-role-tag')), findsOneWidget);
      expect(find.text(label), findsOneWidget);
    });
  }

  testWidgets('an account with no role saved shows as Carpenter', (
    tester,
  ) async {
    await _pump(tester, {});
    expect(find.text('Carpenter'), findsOneWidget);
  });
}
