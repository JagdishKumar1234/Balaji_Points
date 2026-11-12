import 'package:balaji_points/core/design/app_theme.dart';
import 'package:balaji_points/l10n/app_localizations.dart';
import 'package:balaji_points/presentation/screens/super_admin/super_admin_roles_tab.dart';
import 'package:balaji_points/services/auth/role_service.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';

void main() {
  GoogleFonts.config.allowRuntimeFetching = false;

  late FakeFirebaseFirestore db;
  late RoleService service;

  setUp(() {
    db = FakeFirebaseFirestore();
    service = RoleService(firestore: db);
  });

  group('RoleService sync with Firestore', () {
    test('empty collection still exposes the four built-in roles', () async {
      final roles = await service.listRoles();
      expect(roles.map((r) => r.id), [
        'carpenter',
        'architect',
        'engineer',
        'interior_designer',
      ]);
      expect(roles.every((r) => r.isActive && r.isBuiltIn), isTrue);
    });

    test('createRole writes the exact shape firestore.rules expects', () async {
      final role = await service.createRole(
        name: '  Tile   Fitter ',
        abbreviation: 'TF ',
      );
      expect(role.id, 'tile_fitter');
      final doc = await db.collection('roles').doc('tile_fitter').get();
      final data = doc.data()!;
      expect(data.keys.toSet(), {
        'roleId',
        'name',
        'abbreviation',
        'isActive',
        'isBuiltIn',
        'rupeesPerPoint',
        'createdAt',
        'updatedAt',
      });
      expect(data['rupeesPerPoint'], 1000);
      expect(data['roleId'], 'tile_fitter');
      expect(data['name'], 'Tile Fitter');
      expect(data['abbreviation'], 'TF');
      expect(data['isActive'], true);
      expect(data['isBuiltIn'], false);
    });

    test(
      'createRole rejects duplicates, reserved, built-in and non-Latin names',
      () async {
        await service.createRole(name: 'Mason', abbreviation: '');
        Future<RoleErrorCode?> codeOf(String name) async {
          try {
            await service.createRole(name: name, abbreviation: '');
            return null;
          } on RoleException catch (e) {
            return e.code;
          }
        }

        expect(await codeOf('mason'), RoleErrorCode.duplicate);
        expect(await codeOf('Admin'), RoleErrorCode.reserved);
        expect(await codeOf('Super Admin'), RoleErrorCode.reserved);
        expect(await codeOf('Architect'), RoleErrorCode.builtInId);
        expect(await codeOf('बढ़ई'), RoleErrorCode.invalidName);
        expect(await codeOf('x' * 41), RoleErrorCode.invalidName);
      },
    );

    test(
      'soft delete keeps the document and hides the role from signup',
      () async {
        final mason = await service.createRole(name: 'Mason', abbreviation: '');
        await service.setRoleActive(mason, false);

        final doc = await db.collection('roles').doc('mason').get();
        expect(doc.exists, isTrue);
        expect(doc.data()!['isActive'], false);
        expect(doc.data()!['isBuiltIn'], false);
        expect(await service.isActiveSignupRole('mason'), isFalse);
        expect(
          (await service.listSignupRoles()).map((r) => r.id),
          isNot(contains('mason')),
        );

        await service.setRoleActive(mason.copyInactive(), true);
        expect(await service.isActiveSignupRole('mason'), isTrue);
      },
    );

    test('deleting a built-in role creates its override document', () async {
      final architect = AppRole.builtInDefault('architect')!;
      await service.setRoleActive(architect, false);
      final data = (await db.collection('roles').doc('architect').get())
          .data()!;
      expect(data['isBuiltIn'], true);
      expect(data['isActive'], false);
      expect(await service.isActiveSignupRole('architect'), isFalse);
    });

    test('carpenter can never be deleted', () async {
      final carpenter = AppRole.builtInDefault('carpenter')!;
      expect(
        () => service.setRoleActive(carpenter, false),
        throwsA(
          isA<RoleException>().having(
            (e) => e.code,
            'code',
            RoleErrorCode.protected,
          ),
        ),
      );
      expect(await service.isActiveSignupRole('carpenter'), isTrue);
    });

    test('admin roles are never offered for signup', () async {
      expect(await service.isActiveSignupRole('admin'), isFalse);
      expect(await service.isActiveSignupRole('super_admin'), isFalse);
      expect(await service.isActiveSignupRole('engineer'), isTrue);
    });

    test('watchRoles streams changes live', () async {
      final updates = service.watchRoles().map((r) => r.length);
      final expectation = expectLater(updates, emitsThrough(5));
      await service.createRole(name: 'Mason', abbreviation: '');
      await expectation;
    });
  });

  group('Roles tab', () {
    Future<void> pumpTab(
      WidgetTester tester, {
      Locale locale = const Locale('en'),
    }) async {
      tester.view.physicalSize = const Size(390, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        MaterialApp(
          theme: AppThemeData.light(),
          locale: locale,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(body: SuperAdminRolesTab(service: service)),
        ),
      );
      await tester.pumpAndSettle();
    }

    testWidgets('shows built-ins, locks carpenter and adds a role live', (
      tester,
    ) async {
      await pumpTab(tester);
      expect(find.text('Carpenter'), findsOneWidget);
      expect(find.byIcon(Icons.lock_outline_rounded), findsOneWidget);

      await tester.tap(find.text('Add role'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextFormField).first, 'Mason');
      await tester.pump();
      expect(find.textContaining('mason'), findsWidgets); // live ID preview
      await tester.tap(find.text('Save role'));
      await tester.pumpAndSettle();

      expect(find.text('Mason'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('Add role flags a duplicate before saving', (tester) async {
      await service.createRole(name: 'Mason', abbreviation: '');
      await pumpTab(tester);
      await tester.tap(find.text('Add role'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextFormField).first, 'mason');
      await tester.tap(find.text('Save role'));
      await tester.pumpAndSettle();
      expect(find.text('A role with this ID already exists.'), findsOneWidget);
    });

    for (final dark in [false, true]) {
      testWidgets(
        '320px · 1.3x · Tamil · ${dark ? 'dark' : 'light'} has no overflow',
        (tester) async {
          await service.createRole(
            name: 'Very Long Custom Role Name For Testing',
            abbreviation: 'ABCDEFGHIJ',
          );
          final architect = AppRole.builtInDefault('architect')!;
          await service.setRoleActive(architect, false);
          tester.view.physicalSize = const Size(320, 800);
          tester.view.devicePixelRatio = 1;
          addTearDown(tester.view.resetPhysicalSize);
          addTearDown(tester.view.resetDevicePixelRatio);
          await tester.pumpWidget(
            MaterialApp(
              theme: AppThemeData.light(),
              darkTheme: AppThemeData.dark(),
              themeMode: dark ? ThemeMode.dark : ThemeMode.light,
              locale: const Locale('ta'),
              localizationsDelegates: AppLocalizations.localizationsDelegates,
              supportedLocales: AppLocalizations.supportedLocales,
              builder: (context, child) => MediaQuery(
                data: MediaQuery.of(
                  context,
                ).copyWith(textScaler: const TextScaler.linear(1.3)),
                child: child!,
              ),
              home: Scaffold(body: SuperAdminRolesTab(service: service)),
            ),
          );
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull);
          await tester.tap(find.byIcon(Icons.add_rounded));
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull, reason: 'Add role dialog');
        },
      );
    }

    testWidgets('built-in names are translated (Tamil) with no overflow', (
      tester,
    ) async {
      await pumpTab(tester, locale: const Locale('ta'));
      expect(find.text('பொறியாளர் · Er.'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}

extension on AppRole {
  AppRole copyInactive() => AppRole(
    id: id,
    name: name,
    abbreviation: abbreviation,
    isActive: false,
    isBuiltIn: isBuiltIn,
  );
}
