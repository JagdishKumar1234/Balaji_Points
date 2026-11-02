import 'package:balaji_points/presentation/screens/common/auth/login_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets(
    'login screen exposes email, Google and forgot password actions',
    (tester) async {
      await tester.pumpWidget(
        const ProviderScope(child: MaterialApp(home: LoginPage())),
      );

      expect(find.text('Continue with Google'), findsOneWidget);
      expect(find.text('Email'), findsOneWidget);
      expect(find.text('Forgot password?'), findsOneWidget);
    },
  );
}
