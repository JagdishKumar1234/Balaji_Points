import 'package:balaji_points/core/points/leaderboard_group.dart';
import 'package:balaji_points/services/auth/account_approval_service.dart';
import 'package:balaji_points/services/branch/branch_celebration_service.dart';
import 'package:balaji_points/services/auth/session_service.dart';
import 'package:balaji_points/services/branch/daily_winner_scope.dart';
import 'package:balaji_points/services/leaderboard/leaderboard_service.dart';
import 'package:balaji_points/services/spin/daily_spin_service.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';

/// Every feature built on 2026-11-13, checked on BOTH branches with the same
/// test accounts as functions/scripts/emulator_seed.js.
const erode = 'erode_main';
const karur = 'karur_test';
const today = '2026-11-14';

class _Session implements SessionService {
  _Session(this.id);
  final String id;
  @override
  Future<String?> getUserId() async => id;
  @override
  Future<String?> getPhoneNumber() async => null;
  @override
  Future<String?> getUserRole() async => null;
  @override
  dynamic noSuchMethod(Invocation i) => super.noSuchMethod(i);
}

/// (phone/id, name, role, branch, points, approval)
const _members = [
  ('9000000001', 'Erode Carpenter', 'carpenter', erode, 120, 'approved'),
  ('9000000007', 'Erode Designer', 'interior_designer', erode, 90, 'approved'),
  ('9000000005', 'Erode Architect', 'architect', erode, 30, 'approved'),
  ('9000000006', 'Erode Engineer', 'engineer', erode, 45, 'approved'),
  ('9000000013', 'Waiting Erode', 'carpenter', erode, 999, 'pending'),
  ('9000000002', 'Karur Carpenter', 'carpenter', karur, 60, 'approved'),
  ('9000000012', 'Karur Designer', 'interior_designer', karur, 75, 'approved'),
  ('9000000010', 'Karur Architect', 'architect', karur, 20, 'approved'),
  ('9000000011', 'Karur Engineer', 'engineer', karur, 10, 'approved'),
  ('9000000014', 'Waiting Karur', 'architect', karur, 999, 'pending'),
  ('9000000015', 'Rejected Karur', 'carpenter', karur, 999, 'rejected'),
];

Future<FakeFirebaseFirestore> _seed() async {
  final db = FakeFirebaseFirestore();
  await db.collection('branches').doc(erode).set({
    'name': 'TEST E Road',
    'phone': '9000000000',
  });
  await db.collection('branches').doc(karur).set({
    'name': 'TEST Karur',
    'phone': '9000000009',
  });
  for (final (id, name, role, branch, points, approval) in _members) {
    final parts = name.split(' ');
    await db.collection('users').doc(id).set({
      'firstName': parts.first,
      'lastName': parts.last,
      'role': role,
      'branchId': branch,
      'phone': id,
      'totalPoints': points,
      'profile_verified': approval == 'approved',
      'approvalStatus': approval,
      if (approval == 'rejected') 'rejectReason': 'Wrong branch',
    });
  }
  for (final (id, branch) in [('9000000003', erode), ('karurAdmin', karur)]) {
    await db.collection('users').doc(id).set({
      'firstName': 'Admin',
      'role': 'admin',
      'branchId': branch,
      'phone': id,
      'totalPoints': 9999,
    });
  }
  // Bills approved today (and one from yesterday that must not count).
  var n = 0;
  Future<void> bill(String who, String branch, num amount, {String? date}) =>
      db.collection('bills').doc('b${n++}').set({
        'carpenterId': who,
        'branchId': branch,
        'amount': amount,
        'status': 'approved',
        'approvedDate': date ?? today,
      });
  await bill('9000000001', erode, 12000);
  await bill('9000000007', erode, 8000);
  await bill('9000000005', erode, 50000);
  await bill('9000000013', erode, 99999); // waiting account: never eligible
  await bill('9000000002', karur, 7000);
  await bill('9000000010', karur, 30000);
  await bill('9000000011', karur, 25000);
  await bill('9000000012', karur, 4000, date: '2026-11-13');
  return db;
}

void main() {
  late FakeFirebaseFirestore db;
  setUp(() async => db = await _seed());

  Future<List<String>> board(String userId, String branch) async =>
      (await LeaderboardService(firestore: db).load(
        branchId: branch,
        currentUserId: userId,
      )).entries.map((e) => e.name).toList();

  group('leaderboards: own branch + own role group only', () {
    test('E Road carpenter / interior designer', () async {
      for (final id in ['9000000001', '9000000007']) {
        expect(await board(id, erode), ['Erode Carpenter', 'Erode Designer']);
      }
    });
    test('E Road architect / engineer', () async {
      for (final id in ['9000000005', '9000000006']) {
        expect(await board(id, erode), ['Erode Engineer', 'Erode Architect']);
      }
    });
    test('Karur carpenter / interior designer', () async {
      for (final id in ['9000000002', '9000000012']) {
        expect(await board(id, karur), ['Karur Designer', 'Karur Carpenter']);
      }
    });
    test('Karur architect / engineer', () async {
      for (final id in ['9000000010', '9000000011']) {
        expect(await board(id, karur), ['Karur Architect', 'Karur Engineer']);
      }
    });
    test('rank and group size are per group', () async {
      final r = await LeaderboardService(
        firestore: db,
      ).load(branchId: karur, currentUserId: '9000000011');
      expect(r.currentUser!.rank, 2);
      expect(r.total, 2);
      expect(r.group, LeaderboardGroup.professional);
    });
    test('Diwali popup matches the home board on both branches', () async {
      for (final (id, branch) in [
        ('9000000006', erode),
        ('9000000002', karur),
      ]) {
        final s = await BranchCelebrationService(
          firestore: db,
          session: _Session(id),
        ).loadCelebrationSummary(branch);
        expect(s.topThree.map((e) => e.name), await board(id, branch));
      }
    });
  });

  group('daily spin: 2 per branch, qualify with a bill approved today', () {
    Future<List<String>> eligible(String branch, LeaderboardGroup g) async =>
        (await DailySpinService(firestore: db).eligible(
          branchId: branch,
          group: g,
          date: today,
        )).map((c) => c.userId).toList();

    test('eligible lists per branch and group', () async {
      expect(await eligible(erode, LeaderboardGroup.trade), [
        '9000000001',
        '9000000007',
      ]);
      expect(await eligible(erode, LeaderboardGroup.professional), [
        '9000000005',
      ]);
      expect(await eligible(karur, LeaderboardGroup.trade), ['9000000002']);
      expect(await eligible(karur, LeaderboardGroup.professional), [
        '9000000010',
        '9000000011',
      ]);
    });

    test(
      'four draws today (2 per branch), each once, each in its group',
      () async {
        final spin = DailySpinService(firestore: db);
        for (final branch in [erode, karur]) {
          for (final g in LeaderboardGroup.values) {
            final w = await spin.spin(branchId: branch, group: g, date: today);
            expect(w, isNotNull, reason: '$branch $g');
            final user = (await db.collection('users').doc(w!.userId).get())
                .data()!;
            expect(user['branchId'], branch);
            expect(LeaderboardGroups.of(user['role'] as String?), g);
            // Members' home card reads exactly this document.
            final doc = await db
                .collection('daily_winners')
                .doc(DailyWinnerScope.docId(branch, g, today))
                .get();
            expect(doc.data()!['carpenterId'], w.userId);
            // A second draw for the same group today is refused.
            expect(
              await spin.spin(branchId: branch, group: g, date: today),
              isNull,
            );
          }
        }
        expect((await db.collection('daily_prize_winners').get()).size, 4);
      },
    );
  });

  group('admin users list: approved members, group / role filter', () {
    Future<List<String>> list(String branch, MemberRoleFilter f) async {
      final snap = await db
          .collection('users')
          .where('branchId', isEqualTo: branch)
          .get();
      return snap.docs
          .where((d) => MemberFilter.isActiveMember(d.data()))
          .where((d) => f.matches(d.data()['role'] as String?))
          .map((d) => d.id)
          .toList()
        ..sort();
    }

    test('both branches', () async {
      expect(await list(karur, MemberRoleFilter.all), [
        '9000000002',
        '9000000010',
        '9000000011',
        '9000000012',
      ]);
      expect(
        await list(
          karur,
          MemberRoleFilter.group(LeaderboardGroup.professional),
        ),
        ['9000000010', '9000000011'],
      );
      expect(await list(erode, MemberRoleFilter.role('interior_designer')), [
        '9000000007',
      ]);
      expect(await list(erode, MemberRoleFilter.all), hasLength(4));
    });
  });

  group('account approval on both branches', () {
    late AccountApprovalService approval;
    setUp(() => approval = AccountApprovalService(firestore: db));

    test('requests list per branch (pending + rejected only)', () async {
      final e = await approval.watchRequests(erode).first;
      expect(e.map((r) => r.id), ['9000000013']);
      final k = await approval.watchRequests(karur).first;
      expect(k.map((r) => r.id).toSet(), {'9000000014', '9000000015'});
      expect(k.firstWhere((r) => r.id == '9000000015').status, 'rejected');
    });

    test(
      'sign-in gate for waiting / rejected, with the right branch',
      () async {
        final w = await approval.gateForSession(userId: '9000000014');
        expect(w!.status, 'pending');
        expect(w.branchName, 'TEST Karur');
        expect(w.branchPhone, '9000000009');
        final r = await approval.gateForSession(userId: '9000000015');
        expect(r!.isRejected, isTrue);
        expect(r.rejectReason, 'Wrong branch');
        for (final id in ['9000000001', '9000000002', '9000000011']) {
          expect(await approval.gateForSession(userId: id), isNull, reason: id);
        }
      },
    );

    test('same phone cannot sign up again; other branch never named', () async {
      Future<PhoneSignupResult> check(String phone, String branch) =>
          approval.checkPhoneForSignup(phone, branchId: branch);
      expect(
        (await check('9000000014', karur)).check,
        PhoneSignupCheck.pendingSameBranch,
      );
      expect(
        (await check('9000000015', karur)).check,
        PhoneSignupCheck.rejectedSameBranch,
      );
      expect(
        (await check('9000000002', karur)).check,
        PhoneSignupCheck.approvedSameBranch,
      );
      final cross = await check('9000000002', erode);
      expect(cross.check, PhoneSignupCheck.otherBranch);
      expect(cross.branchName, isEmpty);
      expect((await check('9123456789', karur)).isFree, isTrue);
    });
  });
}
