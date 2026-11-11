import 'dart:io';

import 'package:balaji_points/services/platform/offer_visibility.dart';
import 'package:flutter_test/flutter_test.dart';

const _erode = 'erode_main';
const _karur = 'karur_branch';

void main() {
  group('members see', () {
    test('their own branch\'s offers', () {
      expect(
        OfferVisibility.memberCanSee({'branchId': _karur}, _karur),
        isTrue,
      );
    });

    test('never another branch\'s offers', () {
      expect(
        OfferVisibility.memberCanSee({'branchId': _erode}, _karur),
        isFalse,
      );
    });

    test('the super admin\'s all-branch offers', () {
      expect(OfferVisibility.memberCanSee({'title': 'Diwali'}, _karur), isTrue);
      expect(OfferVisibility.memberCanSee({'branchId': ''}, _erode), isTrue);
    });

    test('only all-branch offers while their branch is unknown', () {
      expect(OfferVisibility.memberCanSee({'branchId': _karur}, null), isFalse);
      expect(OfferVisibility.memberCanSee({}, null), isTrue);
    });
  });

  group('a branch admin manages', () {
    test('only their own branch\'s offers', () {
      expect(OfferVisibility.adminCanSee({'branchId': _karur}, _karur), isTrue);
      expect(
        OfferVisibility.adminCanSee({'branchId': _erode}, _karur),
        isFalse,
      );
    });

    test('never the super admin\'s all-branch offers', () {
      expect(OfferVisibility.adminCanSee({'title': 'Diwali'}, _karur), isFalse);
    });

    test('nothing until their branch is known', () {
      expect(OfferVisibility.adminCanSee({'branchId': _karur}, null), isFalse);
    });
  });

  group('wired into the app', () {
    String read(String path) => File(path).readAsStringSync();

    test('a branch admin\'s new offer saves their branch', () {
      final source = read('lib/services/platform/offer_service.dart');
      expect(source, contains("if (branchId != null) 'branchId': branchId,"));
      expect(source, contains('branchId: branchId,'));
      expect(source, contains('Offer not created: admin branch unknown'));
    });

    test('the push goes only to that branch\'s members', () {
      final source = read(
        'lib/services/notifications/notification_service.dart',
      );
      expect(source, contains(".where('branchId', isEqualTo: branchId)"));
    });

    test('admin list and member home both filter by branch', () {
      expect(
        read('lib/presentation/widgets/admin/offers_management.dart'),
        contains('OfferVisibility.adminCanSee('),
      );
      expect(
        read('lib/providers/home_provider.dart'),
        contains('OfferVisibility.memberCanSee('),
      );
    });
  });
}
