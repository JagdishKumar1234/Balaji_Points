import 'package:balaji_points/core/design/app_theme.dart';
import 'package:balaji_points/core/profile/profile_completeness.dart';
import 'package:balaji_points/l10n/app_localizations.dart';
import 'package:balaji_points/presentation/screens/carpenter/profile/widgets/profile_widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';

void main() {
  GoogleFonts.config.allowRuntimeFetching = false;

  const full = {
    'firstName': 'Raja',
    'lastName': 'A',
    'phone': '9000000001',
    'profileImage': 'https://x/y.png',
    'email': 'r@x.com',
  };

  test('bills need photo, first and last name, and mobile', () {
    expect(ProfileCompleteness.from(full).isReadyForBills, isTrue);
    for (final key in ['firstName', 'lastName', 'phone', 'profileImage']) {
      final data = Map<String, dynamic>.from(full)..[key] = '';
      expect(
        ProfileCompleteness.from(data).isReadyForBills,
        isFalse,
        reason: '$key missing must block bills',
      );
    }
  });

  test('email is shown but not needed for bills', () {
    final data = Map<String, dynamic>.from(full)..remove('email');
    final c = ProfileCompleteness.from(data);
    expect(c.hasEmail, isFalse);
    expect(c.isReadyForBills, isTrue);
    expect(c.completedCount, 3);
  });

  test('lists what is missing, in screen order', () {
    final c = ProfileCompleteness.from({'phone': '9000000001'});
    expect(c.missingForBills, [ProfileItem.photo, ProfileItem.name]);
    expect(ProfileCompleteness.from(null).missingForBills, [
      ProfileItem.photo,
      ProfileItem.name,
      ProfileItem.phone,
    ]);
  });

  test('legacy phoneNumber field counts as a mobile number', () {
    expect(
      ProfileCompleteness.from({'phoneNumber': '+919000000001'}).hasPhone,
      isTrue,
    );
  });

  testWidgets('checklist marks each item and offers Complete profile', (
    tester,
  ) async {
    var tapped = false;
    await tester.pumpWidget(
      MaterialApp(
        theme: AppThemeData.light(),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: ProfileChecklist(
            completeness: ProfileCompleteness.from({
              'firstName': 'Raja',
              'phone': '9000000001',
            }),
            onComplete: () => tapped = true,
          ),
        ),
      ),
    );
    await tester.pump();
    expect(find.text('2/4'), findsNothing);
    expect(find.text('1/4'), findsOneWidget);
    expect(find.text('Verified'), findsOneWidget); // phone
    expect(find.text('Not added'), findsOneWidget); // email
    expect(find.text('Missing'), findsNWidgets(2)); // name, photo
    expect(find.text('Required for bills'), findsNWidgets(2));
    await tester.tap(find.text('Complete Profile'));
    expect(tapped, isTrue);
    expect(tester.takeException(), isNull);
  });

  testWidgets('a complete profile shows no button', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppThemeData.light(),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: ProfileChecklist(
            completeness: ProfileCompleteness.from(full),
            onComplete: () {},
          ),
        ),
      ),
    );
    await tester.pump();
    expect(find.text('4/4'), findsOneWidget);
    expect(find.text('Complete Profile'), findsNothing);
    expect(
      find.text('Your profile is complete. You can submit bills.'),
      findsOneWidget,
    );
  });
}
