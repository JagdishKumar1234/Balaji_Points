import 'package:balaji_points/l10n/app_localizations.dart';
import 'package:balaji_points/presentation/screens/common/contact/contact_us_page.dart';
import 'package:balaji_points/services/branch/branch_support_service.dart';
import 'package:balaji_points/services/branch/current_branch_service.dart';
import 'package:balaji_points/services/platform/enquiry_service.dart';
import 'package:balaji_points/services/branch/public_branches.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

/// Contact Us must fit one phone screen: topic, fields, message and Send
/// all visible without scrolling.
void main() {
  const member = EnquirySender.member(
    name: 'Ravi Kumar',
    phone: '9876543210',
    userId: 'u9',
    branchId: 'erode',
    branchName: 'Erode',
    role: 'carpenter',
  );
  const branch = BranchSupport(
    branch: CurrentBranch(
      id: 'erode',
      name: 'Erode',
      shortName: 'Erode',
      code: 'ERD',
      phone: '96006-09121',
    ),
    adminPhone: '9876500000',
    adminEmail: 'erode@balaji.test',
  );

  Future<void> pump(WidgetTester tester, EnquirySender sender) async {
    // A common small phone: 360 x 740 dp.
    tester.view.physicalSize = const Size(1080, 2220);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          enquirySenderProvider.overrideWith((ref) async => sender),
          branchSupportProvider.overrideWith((ref) => Stream.value(branch)),
          publicBranchesProvider.overrideWith(
            (ref) => Stream.value(const [
              PublicBranch(
                id: 'erode_main',
                name: 'E Road',
                shortName: 'E Road',
              ),
              PublicBranch(id: 'karur', name: 'Karur', shortName: 'Karur'),
            ]),
          ),
        ],
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const ContactUsPage(),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
  }

  void expectNoScroll(WidgetTester tester) {
    expect(tester.takeException(), isNull);
    final pos = tester
        .state<ScrollableState>(
          find
              .descendant(
                of: find.byType(CustomScrollView),
                matching: find.byType(Scrollable),
              )
              .first,
        )
        .position;
    expect(pos.maxScrollExtent, 0, reason: 'form must fit without scrolling');
    final send = tester.getRect(find.text('Send enquiry'));
    expect(send.bottom, lessThanOrEqualTo(740));
  }

  testWidgets('member: branch phone + email, topics, fits one screen', (
    tester,
  ) async {
    await pump(tester, member);
    expect(find.text('96006-09121'), findsOneWidget);
    expect(find.text('erode@balaji.test'), findsOneWidget);
    expect(find.text('Points & bills'), findsOneWidget);
    // Name comes from the login; mobile is shown pre-filled and editable.
    expect(find.text('Your name'), findsNothing);
    expect(find.text('Mobile number'), findsOneWidget);
    expect(find.widgetWithText(TextFormField, '9876543210'), findsOneWidget);
    expectNoScroll(tester);
  });

  testWidgets('guest: support contacts, name + mobile, fits one screen', (
    tester,
  ) async {
    await pump(tester, const EnquirySender.guest());
    expect(find.text('aaijitechstudio@gmail.com'), findsOneWidget);
    // Both support numbers and the email, each in full (nothing cut off).
    for (final t in [
      '96807 77735',
      '89470 38661',
      'aaijitechstudio@gmail.com',
      'App support · Balaji Points',
    ]) {
      final para = tester.renderObject<RenderParagraph>(find.text(t));
      expect(para.didExceedMaxLines, isFalse, reason: t);
      expect(para.size.width, greaterThan(0), reason: t);
    }
    // First number comes first.
    expect(
      tester.getTopLeft(find.text('96807 77735')).dx,
      lessThan(tester.getTopLeft(find.text('89470 38661')).dx),
    );
    expect(find.text('Become a member'), findsOneWidget);
    expect(find.text('Your name'), findsOneWidget);
    expect(find.text('Mobile number'), findsOneWidget);
    // A guest may pick a branch (optional; otherwise the super admin).
    expect(find.text('Branch (optional)'), findsOneWidget);
    expectNoScroll(tester);
  });

  testWidgets('guest can send without a branch (goes to super admin)', (
    tester,
  ) async {
    await pump(tester, const EnquirySender.guest());
    await tester.tap(find.text('Send enquiry'));
    await tester.pump();
    // Other fields are still checked, but the branch is not required.
    expect(find.text('Select a branch'), findsNothing);
    expect(find.text('Enter a valid 10-digit mobile number'), findsOneWidget);
  });

  testWidgets('member can change the call-back number', (tester) async {
    await pump(tester, member);
    final field = find.widgetWithText(TextFormField, '9876543210');
    await tester.enterText(field, '12345');
    await tester.tap(find.text('Points & bills'));
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Message'),
      'Please call me back',
    );
    await tester.tap(find.text('Send enquiry'));
    await tester.pump();
    expect(find.text('Enter a valid 10-digit mobile number'), findsOneWidget);
  });

  testWidgets('topic is required', (tester) async {
    await pump(tester, const EnquirySender.guest());
    await tester.tap(find.text('Send enquiry'));
    await tester.pump();
    expect(find.text('What is it about?'), findsNWidgets(2));
  });

  testWidgets('Send stays visible above the keyboard', (tester) async {
    await pump(tester, const EnquirySender.guest());
    // Keyboard takes 300 dp of the 740 dp screen.
    tester.view.viewInsets = const FakeViewPadding(bottom: 900);
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    final send = tester.getRect(find.text('Send enquiry'));
    expect(send.bottom, lessThanOrEqualTo(440));
  });
}
