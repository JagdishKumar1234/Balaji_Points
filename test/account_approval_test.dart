import 'dart:io';

import 'package:balaji_points/config/routes.dart';
import 'package:balaji_points/services/auth/account_approval_service.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';

Future<FakeFirebaseFirestore> _seed() async {
  final db = FakeFirebaseFirestore();
  await db.collection('branches').doc('b1').set({
    'name': 'Erode',
    'phone': '96006-09121',
  });
  await db.collection('branches').doc('b2').set({'name': 'Karur'});
  Future<void> user(String id, Map<String, dynamic> d) =>
      db.collection('users').doc(id).set(d);
  await user('ok', {
    'role': 'carpenter',
    'branchId': 'b1',
    'phone': '9000000001',
    'profile_verified': true,
  });
  await user('pend', {
    'role': 'architect',
    'branchId': 'b1',
    'phone': '9000000002',
    'profile_verified': false,
    'approvalStatus': 'pending',
    'firstName': 'Pooja',
  });
  await user('rej', {
    'role': 'engineer',
    'branchId': 'b1',
    'phone': '9000000003',
    'profile_verified': false,
    'approvalStatus': 'rejected',
    'rejectReason': 'Wrong branch',
  });
  await user('other', {
    'role': 'carpenter',
    'branchId': 'b2',
    'phone': '9000000004',
    'profile_verified': false,
  });
  await user('adm', {'role': 'admin', 'branchId': 'b1', 'phone': '9000000005'});
  return db;
}

void main() {
  late FakeFirebaseFirestore db;
  late AccountApprovalService service;
  setUp(() async {
    db = await _seed();
    service = AccountApprovalService(firestore: db);
  });

  group('sign-in gate', () {
    test('approved members and staff may sign in', () async {
      expect(
        await service.gateFor({'role': 'carpenter', 'profile_verified': true}),
        isNull,
      );
      expect(await service.gateFor({'role': 'admin'}), isNull);
      expect(await service.gateFor({'role': 'super_admin'}), isNull);
      expect(await service.gateFor(null), isNull);
    });

    test('pending, missing field and rejected members are blocked', () async {
      final pending = await service.gateFor({
        'role': 'architect',
        'branchId': 'b1',
        'profile_verified': false,
      });
      expect(pending!.status, 'pending');
      expect(pending.branchName, 'Erode');
      expect(pending.branchPhone, '96006-09121');

      // Old-app sign-up after the migration: no field at all.
      final missing = await service.gateFor({'role': '', 'branchId': 'b1'});
      expect(missing!.status, 'pending');

      final rejected = await service.gateFor({
        'role': 'engineer',
        'branchId': 'b1',
        'approvalStatus': 'rejected',
        'rejectReason': 'Duplicate',
      });
      expect(rejected!.isRejected, isTrue);
      expect(rejected.rejectReason, 'Duplicate');
    });

    test('saved session is checked against the account', () async {
      expect(await service.gateForSession(userId: 'ok'), isNull);
      expect((await service.gateForSession(userId: 'pend'))!.status, 'pending');
      expect((await service.gateForSession(userId: 'rej'))!.status, 'rejected');
      expect(
        (await service.gateForSession(phone: '+91 90000 00002'))!.status,
        'pending',
      );
      // Unknown account: never locked out by this check.
      expect(await service.gateForSession(userId: 'nobody'), isNull);
    });
  });

  group('one account per phone at sign-up', () {
    Future<PhoneSignupCheck> check(String phone, String branch) async =>
        (await service.checkPhoneForSignup(phone, branchId: branch)).check;

    test('a new number may sign up', () async {
      expect(await check('9111111111', 'b1'), PhoneSignupCheck.free);
    });

    test('same branch: pending, rejected or approved', () async {
      expect(
        await check('9000000002', 'b1'),
        PhoneSignupCheck.pendingSameBranch,
      );
      expect(
        await check('9000000003', 'b1'),
        PhoneSignupCheck.rejectedSameBranch,
      );
      expect(
        await check('9000000001', 'b1'),
        PhoneSignupCheck.approvedSameBranch,
      );
      expect(
        await check('9000000005', 'b1'),
        PhoneSignupCheck.approvedSameBranch,
      );
    });

    test('another branch never names that branch', () async {
      final r = await service.checkPhoneForSignup('9000000004', branchId: 'b1');
      expect(r.check, PhoneSignupCheck.otherBranch);
      expect(r.branchName, isEmpty);
      expect(r.branchPhone, isEmpty);
    });

    test('formatting does not hide a duplicate', () async {
      expect(
        await check('+91 90000-00002', 'b1'),
        PhoneSignupCheck.pendingSameBranch,
      );
    });

    test(
      'a half-finished Google profile is not a duplicate of itself',
      () async {
        final r = await service.checkPhoneForSignup(
          '9000000002',
          branchId: 'b1',
          selfId: 'pend',
        );
        expect(r.check, PhoneSignupCheck.free);
      },
    );

    test('same-branch result carries the branch contact', () async {
      final r = await service.checkPhoneForSignup('9000000002', branchId: 'b1');
      expect(r.branchName, 'Erode');
      expect(r.branchPhone, '96006-09121');
    });
  });

  group('requests list', () {
    test('only this branch, only unapproved members', () async {
      final list = await service.watchRequests('b1').first;
      expect(list.map((r) => r.id).toSet(), {'pend', 'rej'});
      expect(list.firstWhere((r) => r.id == 'rej').status, 'rejected');
      expect(list.firstWhere((r) => r.id == 'pend').name, 'Pooja');
    });

    test('no branch → nothing', () async {
      expect(await service.watchRequests('').first, isEmpty);
      expect(await service.watchRequests(null).first, isEmpty);
    });
  });

  test('sign-ups write pending fields', () {
    final f = AccountApprovalService.pendingFields();
    expect(f['profile_verified'], false);
    expect(f['approvalStatus'], 'pending');
    expect(f.containsKey('approvalRequestedAt'), isTrue);
  });

  group('routes', () {
    test('status page is public; requests only for the branch admin', () {
      expect(redirectForRole('/account-status', null), isNull);
      expect(redirectForRole('/account-requests', 'admin'), isNull);
      // The super admin cannot approve accounts.
      expect(
        redirectForRole('/account-requests', 'super_admin'),
        '/super-admin',
      );
      for (final r in ['carpenter', 'architect', 'engineer', null]) {
        expect(redirectForRole('/account-requests', r), '/', reason: '$r');
      }
    });
  });

  test('every sign-in and sign-up path uses the approval gate', () {
    final auth = File('lib/providers/auth_provider.dart').readAsStringSync();
    // Firebase (email, Google, saved Firebase session) and PIN sign-in.
    expect('_approval.gateFor('.allMatches(auth).length, 2);
    // Email and Google sign-ups: phone check first, pending fields saved,
    // then signed out to the "Request sent" screen.
    expect('_approval.checkPhoneForSignup('.allMatches(auth).length, 2);
    expect('AccountApprovalService.pendingFields()'.allMatches(auth).length, 2);
    expect('justRegistered: true'.allMatches(auth).length, 2);
    final splash = File(
      'lib/presentation/screens/common/splash/splash_page.dart',
    ).readAsStringSync();
    expect(splash, contains('gateForSession('));
  });

  test('the super admin has no way to approve accounts', () {
    final page = File(
      'lib/presentation/screens/super_admin/super_admin_page.dart',
    ).readAsStringSync();
    expect(page, isNot(contains('/account-requests')));
    final screen = File(
      'lib/presentation/screens/admin/account_requests_screen.dart',
    ).readAsStringSync();
    expect(screen, isNot(contains('super_admin')));
    final fn = File('functions/index.js').readAsStringSync();
    final review = fn.substring(fn.indexOf('exports.reviewMemberAccount'));
    expect(review, isNot(contains('requireSuperAdmin')));
  });
}
