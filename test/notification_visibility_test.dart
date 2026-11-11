import 'dart:io';

import 'package:balaji_points/services/notifications/notification_visibility.dart';
import 'package:flutter_test/flutter_test.dart';

const _erode = 'erode_main';
const _karur = 'karur_branch';

bool member(Map<String, dynamic> n, {String branch = _karur}) =>
    NotificationVisibility.memberCanSee(
      n,
      myIds: {'me-uid', '9000000001'},
      myBranchId: branch,
    );

bool admin(Map<String, dynamic> n, {String? branch = _karur}) =>
    NotificationVisibility.adminCanSee(n, adminBranchId: branch);

void main() {
  group('a member sees', () {
    test('their own notifications, by account id or phone', () {
      expect(member({'type': 'billApproved', 'userId': 'me-uid'}), isTrue);
      expect(member({'type': 'billApproved', 'userId': '9000000001'}), isTrue);
    });

    test('nobody else\'s personal notifications', () {
      expect(
        member({'type': 'billApproved', 'userId': 'someone-else'}),
        isFalse,
      );
    });

    test('announcements for their own branch only', () {
      expect(member({'type': 'greeting', 'branchId': _karur}), isTrue);
      expect(member({'type': 'greeting', 'branchId': _erode}), isFalse);
      expect(
        member({
          'type': 'billApproved',
          'isBroadcast': true,
          'branchId': _erode,
        }),
        isFalse,
      );
    });

    test('offers and greetings meant for every branch', () {
      expect(
        member({'type': 'newOfferAvailable', 'isBroadcast': true}),
        isTrue,
      );
      expect(member({'type': 'greeting'}), isTrue);
    });

    test('no old no-branch bill notices from another branch', () {
      for (final type in [
        'billApproved',
        'billRejected',
        'tierUpgraded',
        'pointsWithdrawn',
        'dailySpinWon',
      ]) {
        expect(
          member({'type': type, 'isBroadcast': true}),
          isFalse,
          reason: type,
        );
      }
    });

    test(
      'never admin alerts or internal records, even if addressed to them',
      () {
        for (final type in [
          'newPendingBill',
          'newUserRegistered',
          'dailySpinReminder',
        ]) {
          expect(
            member({'type': type, 'userId': 'me-uid', 'branchId': _karur}),
            isFalse,
            reason: type,
          );
        }
      },
    );

    test('nothing when the record is empty', () {
      expect(
        NotificationVisibility.memberCanSee(
          null,
          myIds: {'x'},
          myBranchId: _karur,
        ),
        isFalse,
      );
    });
  });

  group('a branch admin sees', () {
    test('admin alerts for their own branch', () {
      expect(admin({'type': 'newPendingBill', 'branchId': _karur}), isTrue);
      expect(admin({'type': 'newUserRegistered', 'branchId': _karur}), isTrue);
    });

    test('never another branch\'s alerts (the reported Karur problem)', () {
      expect(admin({'type': 'newPendingBill', 'branchId': _erode}), isFalse);
    });

    test('never alerts with no branch', () {
      expect(admin({'type': 'newPendingBill'}), isFalse);
      expect(admin({'type': 'newPendingBill', 'branchId': ''}), isFalse);
    });

    test('only admin alert types', () {
      expect(admin({'type': 'billApproved', 'branchId': _karur}), isFalse);
      expect(admin({'type': 'newOfferAvailable', 'branchId': _karur}), isFalse);
    });

    test('nothing until their branch is known', () {
      expect(
        admin({'type': 'newPendingBill', 'branchId': _karur}, branch: null),
        isFalse,
      );
      expect(
        admin({'type': 'newPendingBill', 'branchId': ''}, branch: ''),
        isFalse,
      );
    });
  });

  group('wired into every screen', () {
    String read(String path) => File(path).readAsStringSync();

    test('admin inbox, delete-all and dashboard badge use the strict rule', () {
      for (final path in [
        'lib/presentation/screens/admin/admin_notifications_page.dart',
        'lib/presentation/widgets/admin/admin_dashboard.dart',
        'lib/presentation/screens/admin/admin_home_page.dart',
      ]) {
        final source = read(path);
        expect(source, contains('visibleToAdmin()'), reason: path);
        expect(source, isNot(contains('inAdminBranch()')), reason: path);
      }
    });

    test('member inbox uses the member rule', () {
      expect(
        read(
          'lib/presentation/screens/carpenter/notifications/notifications_page.dart',
        ),
        contains('NotificationVisibility.memberCanSee('),
      );
    });

    test('the server now saves the branch on every notification', () {
      expect(
        read('functions/index.js'),
        contains('branchId: doc.branchId || null,'),
      );
    });
  });
}
