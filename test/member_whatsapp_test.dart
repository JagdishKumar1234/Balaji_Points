import 'package:balaji_points/core/design/app_theme.dart';
import 'package:balaji_points/l10n/app_localizations.dart';
import 'package:balaji_points/presentation/screens/admin/account_requests_screen.dart';
import 'package:balaji_points/services/auth/account_approval_service.dart';
import 'package:balaji_points/services/auth/member_whatsapp.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';

/// Records reviews instead of calling the server.
class _FakeReview extends AccountApprovalService {
  _FakeReview(FakeFirebaseFirestore db) : super(firestore: db);
  final calls = <(String, bool, String?)>[];

  @override
  Future<void> review({
    required String userId,
    required bool approve,
    String? reason,
  }) async => calls.add((userId, approve, reason));
}

void main() {
  GoogleFonts.config.allowRuntimeFetching = false;

  group('wa.me link', () {
    test('Indian numbers get +91; formatting is ignored', () {
      expect(MemberWhatsApp.waNumber('9600609121'), '919600609121');
      expect(MemberWhatsApp.waNumber('+91 96006-09121'), '919600609121');
      expect(MemberWhatsApp.waNumber('09600609121'), '919600609121');
      expect(MemberWhatsApp.waNumber('919600609121'), '919600609121');
      expect(MemberWhatsApp.waNumber('12345'), isNull);
      expect(MemberWhatsApp.waNumber(''), isNull);
    });

    test('message is URL-encoded', () {
      final uri = MemberWhatsApp.chatUri('9600609121', 'Hi Ravi & co!')!;
      expect(uri.host, 'wa.me');
      expect(uri.path, '/919600609121');
      expect(uri.queryParameters['text'], 'Hi Ravi & co!');
      expect(MemberWhatsApp.chatUri('123', 'x'), isNull);
    });
  });

  Future<_FakeReview> pump(WidgetTester tester) async {
    tester.view.physicalSize = const Size(390, 1600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final db = FakeFirebaseFirestore();
    await db.collection('branches').doc('b1').set({'name': 'E Road'});
    await db.collection('users').doc('m1').set({
      'firstName': 'Ravi',
      'role': 'architect',
      'branchId': 'b1',
      'phone': '9600609121',
      'profile_verified': false,
      'approvalStatus': 'pending',
    });
    final service = _FakeReview(db);
    await tester.pumpWidget(
      MaterialApp(
        theme: AppThemeData.light(),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: AccountRequestsScreen(service: service, branchIdForTest: 'b1'),
      ),
    );
    await tester.pumpAndSettle();
    return service;
  }

  testWidgets('after Approve the admin is offered a WhatsApp message', (
    tester,
  ) async {
    final service = await pump(tester);
    await tester.tap(find.byKey(const ValueKey('approve-m1')));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Approve').last);
    await tester.pumpAndSettle();

    expect(service.calls.single, ('m1', true, null));
    expect(find.byKey(const ValueKey('whatsapp-offer')), findsOneWidget);
    final message = tester
        .widget<Text>(find.byKey(const ValueKey('whatsapp-message')))
        .data!;
    expect(message, contains('Ravi'));
    expect(message, contains('E Road'));
    expect(message, contains('approved'));
    expect(find.byKey(const ValueKey('send-whatsapp')), findsOneWidget);

    await tester.tap(find.text('Not now'));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('whatsapp-offer')), findsNothing);
  });

  testWidgets('after Reject the message is polite and carries the reason', (
    tester,
  ) async {
    final service = await pump(tester);
    await tester.tap(find.byKey(const ValueKey('reject-m1')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Wrong branch'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('confirm-reject')));
    await tester.pumpAndSettle();

    expect(service.calls.single, ('m1', false, 'Wrong branch'));
    final message = tester
        .widget<Text>(find.byKey(const ValueKey('whatsapp-message')))
        .data!;
    expect(message, contains('could not be approved'));
    expect(message, contains('Reason: Wrong branch'));
    expect(message, contains('E Road'));
  });
}
