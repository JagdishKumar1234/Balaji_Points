import 'package:balaji_points/l10n/app_localizations.dart';
import 'package:balaji_points/presentation/screens/common/auth/login_page.dart';
import 'package:balaji_points/presentation/screens/common/auth/phone_pin_entry_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('login screen exposes clear email, Google and PIN actions', (
    tester,
  ) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: LoginPage(),
        ),
      ),
    );

    expect(find.text('Sign in with Google'), findsOneWidget);
    expect(find.text('Login with PIN'), findsOneWidget);
    expect(find.text('Email'), findsOneWidget);
    expect(find.text('Forgot password?'), findsOneWidget);
  });

  testWidgets('legacy PIN entry asks for a mobile number', (tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: PhonePinEntryPage(),
        ),
      ),
    );

    expect(find.text('Sign in with mobile number'), findsOneWidget);
    expect(find.text('Mobile number'), findsOneWidget);
    expect(find.text('Continue to PIN'), findsOneWidget);
  });
}
