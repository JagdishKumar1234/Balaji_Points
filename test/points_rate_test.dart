import 'dart:io';

import 'package:balaji_points/core/points/points_rate.dart';
import 'package:balaji_points/services/auth/role_service.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('role rates', () {
    test('built-in defaults: 1,000 for carpenters and interior designers, '
        '5,000 for architects and engineers', () {
      expect(PointsRate.defaultFor('carpenter'), 1000);
      expect(PointsRate.defaultFor('interior_designer'), 1000);
      expect(PointsRate.defaultFor('architect'), 5000);
      expect(PointsRate.defaultFor('engineer'), 5000);
      expect(PointsRate.defaultFor('mason'), 1000);
      expect(PointsRate.defaultFor(null), 1000);
    });

    test('points follow the rate, with decimals', () {
      expect(PointsRate.pointsFor(12500, 1000), 12.5);
      expect(PointsRate.pointsFor(12500, 5000), 2.5);
      expect(PointsRate.pointsFor(0, 1000), 0);
      expect(PointsRate.pointsFor(100, 0), 0);
    });

    test('a bill keeps the rate it was saved with', () {
      // Submitted by an engineer at 5,000, not yet approved.
      expect(PointsRate.forBill({'amount': 10000, 'rupeesPerPoint': 5000}), 2);
      // Approved: the credited points win.
      expect(
        PointsRate.forBill({
          'amount': 10000,
          'rupeesPerPoint': 5000,
          'pointsEarned': 2,
        }),
        2,
      );
      // Old bill from before rates existed: 1 per 1,000.
      expect(PointsRate.forBill({'amount': 10000}), 10);
      // Old pending bill, but the member's rate is known: use it.
      expect(PointsRate.forBill({'amount': 10000}, rupeesPerPoint: 5000), 2);
    });

    test('stored rates outside the allowed range fall back', () {
      expect(PointsRate.sanitize(0, fallback: 1000), 1000);
      expect(PointsRate.sanitize(5000000, fallback: 1000), 1000);
      expect(PointsRate.sanitize('abc', fallback: 1000), 1000);
      expect(PointsRate.sanitize(2500, fallback: 1000), 2500);
      expect(PointsRate.sanitize(2500.0, fallback: 1000), 2500);
    });

    test('labels in Indian digit grouping', () {
      expect(PointsRate.label(5000), '1 pt / ₹5,000');
      expect(PointsRate.label(100000), '1 pt / ₹1,00,000');
    });
  });

  group('RoleService rates', () {
    test(
      'role records override the default rate; others keep defaults',
      () async {
        final fake = FakeFirebaseFirestore();
        await fake.collection('roles').doc('engineer').set({
          'roleId': 'engineer',
          'name': 'Engineer',
          'abbreviation': 'Er.',
          'isActive': true,
          'isBuiltIn': true,
          'rupeesPerPoint': 4000,
        });
        await fake.collection('roles').doc('mason').set({
          'roleId': 'mason',
          'name': 'Mason',
          'abbreviation': '',
          'isActive': true,
          'isBuiltIn': false,
        });
        RoleService.clearRateCache();
        final service = RoleService(firestore: fake);
        final roles = await service.listRoles();
        final byId = {for (final r in roles) r.id: r};
        expect(byId['engineer']!.rupeesPerPoint, 4000);
        expect(byId['architect']!.rupeesPerPoint, 5000);
        expect(byId['carpenter']!.rupeesPerPoint, 1000);
        expect(byId['mason']!.rupeesPerPoint, 1000);

        expect(await service.rateForRole('engineer'), 4000);
        expect(await service.rateForRole('ENGINEER'), 4000);
        expect(await service.rateForRole('interior_designer'), 1000);
        expect(await service.rateForRole(null), 1000);
        RoleService.clearRateCache();
      },
    );

    test('saving a role writes its rate', () async {
      final fake = FakeFirebaseFirestore();
      final service = RoleService(firestore: fake);
      final created = await service.createRole(
        name: 'Mason',
        abbreviation: '',
        rupeesPerPoint: 2000,
      );
      expect(created.rupeesPerPoint, 2000);
      expect(
        (await fake.collection('roles').doc('mason').get())
            .data()!['rupeesPerPoint'],
        2000,
      );
      final engineer = AppRole.builtInDefault('engineer')!;
      await service.updateRole(
        engineer,
        name: engineer.name,
        abbreviation: engineer.abbreviation,
        rupeesPerPoint: 6000,
      );
      final doc = await fake.collection('roles').doc('engineer').get();
      expect(doc.data()!['rupeesPerPoint'], 6000);
      expect(doc.data()!['isBuiltIn'], true);
      RoleService.clearRateCache();
    });
  });

  test('rate is locked at submission: a later role change does not alter '
      'a pending bill', () {
    // Engineer submitted ₹12,000 at ₹4,000/pt (shown "3.00 points"); the
    // role rate later changed to ₹5,000. The bill still counts 3.
    final bill = {'amount': 12000, 'rupeesPerPoint': 4000, 'pointsEarned': 0};
    expect(PointsRate.forBill(bill, rupeesPerPoint: 5000), 3);
  });

  test('approval reads the bill rate before the role rate', () {
    final src = File(
      'lib/services/platform/bill_service.dart',
    ).readAsStringSync();
    expect(src, contains('await _rateForBill(billId, carpenterId)'));
    final fn = File('functions/index.js').readAsStringSync();
    expect(fn, contains('Number(after.rupeesPerPoint)'));
  });
}
