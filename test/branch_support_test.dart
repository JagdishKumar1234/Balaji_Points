import 'package:balaji_points/core/design/app_theme.dart';
import 'package:balaji_points/l10n/app_localizations.dart';
import 'package:balaji_points/presentation/screens/carpenter/profile/my_branch_page.dart';
import 'package:balaji_points/services/branch/branch_support_service.dart';
import 'package:balaji_points/services/branch/current_branch_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';

const _erode = CurrentBranch(
  id: 'erode_main',
  name: 'Test Store - E Road',
  shortName: 'E Road Branch',
  code: 'erode_main',
  address: '150 Main Road, Erode',
  phone: '96006-09121',
);

void main() {
  GoogleFonts.config.allowRuntimeFetching = false;

  group('picking the branch admin', () {
    final superAdminPin = {
      '_id': '8947038661',
      'role': 'admin',
      'phone': '8947038661',
    };
    final eroadAdmin = {
      '_id': 'B8Q',
      'role': 'admin',
      'phone': '9600609121',
      'firstName': 'E Road',
      'lastName': 'Admin',
    };
    final karurAdmin = {
      '_id': 'ZYd',
      'uid': 'ZYd',
      'role': 'admin',
      'phone': '9999999135',
      'email': 'k@x.com',
    };

    test('uses the linked admin when the branch has one', () {
      final a = BranchSupport.pickAdmin([
        eroadAdmin,
        karurAdmin,
      ], adminUid: 'ZYd');
      expect(a?['email'], 'k@x.com');
    });

    test('otherwise the first admin that is not the super admin', () {
      final a = BranchSupport.pickAdmin([superAdminPin, eroadAdmin]);
      expect(a?['_id'], 'B8Q');
    });

    test('nobody when the only admin is the super admin', () {
      expect(BranchSupport.pickAdmin([superAdminPin]), isNull);
    });

    test('builds the contact card from the admin record', () {
      final s = BranchSupport.fromAdmin(_erode, eroadAdmin);
      expect(s.adminName, 'E Road Admin');
      expect(s.adminPhone, '9600609121');
      expect(s.adminEmail, '');
      expect(s.hasAnyContact, isTrue);
    });
  });

  test('phones become dialable', () {
    expect(BranchSupport.dialable('96006-09121'), '+919600609121');
    expect(BranchSupport.dialable('+91 89470 38661'), '+918947038661');
    expect(BranchSupport.dialable('0424-3557187'), '04243557187');
  });

  testWidgets('My Branch shows the branch, its admin and app support', (
    tester,
  ) async {
    final support = BranchSupport.fromAdmin(_erode, {
      'firstName': 'E Road',
      'lastName': 'Admin',
      'phone': '9600609121',
    });
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          branchSupportProvider.overrideWith((ref) => Stream.value(support)),
        ],
        child: MaterialApp(
          theme: AppThemeData.light(),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const MyBranchPage(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Test Store - E Road'), findsOneWidget);
    expect(find.text('Branch ID: erode_main'), findsOneWidget);
    expect(find.text('150 Main Road, Erode'), findsOneWidget);
    expect(find.text('96006-09121'), findsOneWidget);
    expect(find.text('E Road Admin'), findsOneWidget);
    expect(find.text('9600609121'), findsOneWidget);
    // No admin email: shown as not available, never blank.
    expect(find.text('Not available'), findsOneWidget);
    expect(find.text('aaijitechstudio@gmail.com'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  test('map buttons point Google Maps at the branch address', () {
    final search = mapsSearchUrl(_erode);
    expect(search.host, 'www.google.com');
    expect(search.path, '/maps/search/');
    expect(search.queryParameters['query'], '150 Main Road, Erode, Tamil Nadu');
    final dir = mapsDirectionsUrl(_erode);
    expect(dir.path, '/maps/dir/');
    expect(
      dir.queryParameters['destination'],
      contains('150 Main Road, Erode'),
    );
  });

  testWidgets('My Branch shows the map buttons when there is an address', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          branchSupportProvider.overrideWith(
            (ref) => Stream.value(const BranchSupport(branch: _erode)),
          ),
        ],
        child: MaterialApp(
          theme: AppThemeData.light(),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const MyBranchPage(),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Open in Google Maps'), findsOneWidget);
    expect(find.text('Directions'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
