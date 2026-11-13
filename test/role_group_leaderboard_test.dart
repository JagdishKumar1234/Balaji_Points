import 'package:balaji_points/core/points/leaderboard_group.dart';
import 'package:balaji_points/services/leaderboard/leaderboard_service.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';

/// (id, name, role, branch, points, extra fields)
typedef _P = (String, String, String?, String, num, Map<String, dynamic>);

const _approved = {'profile_verified': true};

Future<FakeFirebaseFirestore> _seed() async {
  final db = FakeFirebaseFirestore();
  final List<_P> people = [
    // Branch 1, Group 1 (trade)
    ('c1', 'Chitra', 'carpenter', 'b1', 120, _approved),
    ('c2', 'Kumar', 'carpenter', 'b1', 80, _approved),
    ('i1', 'Indu', 'interior_designer', 'b1', 100, _approved),
    ('old', 'Old', null, 'b1', 50, _approved), // no role saved
    ('cap', 'Capital', 'Carpenter', 'b1', 10, _approved), // case
    // Branch 1, Group 2 (professional)
    ('a1', 'Arun', 'architect', 'b1', 40, _approved),
    ('e1', 'Ezhil', 'engineer', 'b1', 60, _approved),
    // Not on any board
    ('adm', 'Admin', 'admin', 'b1', 999, _approved),
    ('sup', 'Boss', 'super_admin', 'b1', 999, _approved),
    (
      'del',
      'Deleted',
      'carpenter',
      'b1',
      999,
      {'profile_verified': true, 'status': 'deleted'},
    ),
    (
      'pend',
      'Pending',
      'carpenter',
      'b1',
      999,
      {'profile_verified': false, 'approvalStatus': 'pending'},
    ),
    (
      'rej',
      'Rejected',
      'architect',
      'b1',
      999,
      {'profile_verified': false, 'approvalStatus': 'rejected'},
    ),
    ('nofield', 'NoField', 'carpenter', 'b1', 999, {}),
    // Branch 2
    ('c9', 'Other', 'carpenter', 'b2', 999, _approved),
    ('e9', 'OtherE', 'engineer', 'b2', 999, _approved),
  ];
  for (final (id, name, role, branch, points, extra) in people) {
    await db.collection('users').doc(id).set({
      'firstName': name,
      'role': ?role,
      'branchId': branch,
      'phone': '9$id',
      'totalPoints': points,
      ...extra,
    });
  }
  return db;
}

void main() {
  group('LeaderboardGroups.of', () {
    test('maps the four roles into two fixed groups', () {
      expect(LeaderboardGroups.of('carpenter'), LeaderboardGroup.trade);
      expect(LeaderboardGroups.of('interior_designer'), LeaderboardGroup.trade);
      expect(LeaderboardGroups.of(' Carpenter '), LeaderboardGroup.trade);
      expect(LeaderboardGroups.of(''), LeaderboardGroup.trade);
      expect(LeaderboardGroups.of(null), LeaderboardGroup.trade);
      expect(LeaderboardGroups.of('architect'), LeaderboardGroup.professional);
      expect(LeaderboardGroups.of('ENGINEER'), LeaderboardGroup.professional);
      for (final r in ['admin', 'super_admin', 'dealer']) {
        expect(LeaderboardGroups.of(r), isNull, reason: r);
      }
    });

    test('group ids round-trip', () {
      for (final g in LeaderboardGroup.values) {
        expect(LeaderboardGroup.fromId(g.id), g);
      }
      expect(LeaderboardGroup.fromId('x'), isNull);
    });
  });

  group('AccountApproval', () {
    test('only profile_verified == true counts as verified', () {
      expect(AccountApproval.isVerified({'profile_verified': true}), isTrue);
      expect(AccountApproval.isVerified({'profile_verified': false}), isFalse);
      expect(AccountApproval.isVerified({}), isFalse);
      expect(AccountApproval.isVerified(null), isFalse);
    });

    test('status', () {
      expect(AccountApproval.statusOf({'profile_verified': true}), 'approved');
      expect(
        AccountApproval.statusOf({'approvalStatus': 'rejected'}),
        'rejected',
      );
      expect(AccountApproval.statusOf({}), 'pending');
    });
  });

  group('LeaderboardService', () {
    late FakeFirebaseFirestore db;
    setUp(() async => db = await _seed());

    Future<LeaderboardResult> boardFor(String id, {String branch = 'b1'}) =>
        LeaderboardService(
          firestore: db,
        ).load(branchId: branch, currentUserId: id);

    test(
      'carpenter sees only branch 1 carpenters + interior designers',
      () async {
        final board = await boardFor('c2');
        expect(board.group, LeaderboardGroup.trade);
        expect(board.entries.map((e) => e.userId), [
          'c1',
          'i1',
          'c2',
          'old',
          'cap',
        ]);
        expect(board.entries.map((e) => e.rank), [1, 2, 3, 4, 5]);
        expect(board.currentUser!.rank, 3);
        expect(board.total, 5);
      },
    );

    test('interior designer sees the same board as a carpenter', () async {
      final a = await boardFor('i1');
      final b = await boardFor('c1');
      expect(a.entries.map((e) => e.userId), b.entries.map((e) => e.userId));
      expect(a.currentUser!.rank, 2);
    });

    test(
      'architect and engineer see only branch 1 architects + engineers',
      () async {
        for (final id in ['a1', 'e1']) {
          final board = await boardFor(id);
          expect(board.group, LeaderboardGroup.professional);
          expect(board.entries.map((e) => e.userId), ['e1', 'a1']);
        }
        expect((await boardFor('a1')).currentUser!.rank, 2);
      },
    );

    test('other branch has its own boards', () async {
      final trade = await boardFor('c9', branch: 'b2');
      expect(trade.entries.map((e) => e.userId), ['c9']);
      final pro = await boardFor('e9', branch: 'b2');
      expect(pro.entries.map((e) => e.userId), ['e9']);
    });

    test('a user cannot see another branch by passing its id', () async {
      // c1 belongs to b1; asking for b2 never returns b1 people.
      final board = await LeaderboardService(firestore: db).load(
        branchId: 'b2',
        group: LeaderboardGroup.trade,
        currentUserId: 'c1',
      );
      expect(board.entries.map((e) => e.userId), ['c9']);
      expect(board.currentUser, isNull);
    });

    test(
      'admins, deleted, pending, rejected and unverified are never ranked',
      () async {
        final all = [
          ...(await boardFor('c1')).entries,
          ...(await boardFor('a1')).entries,
        ].map((e) => e.userId);
        for (final id in ['adm', 'sup', 'del', 'pend', 'rej', 'nofield']) {
          expect(all, isNot(contains(id)), reason: id);
        }
      },
    );

    test('no branch gives an empty board (never all users)', () async {
      for (final b in [null, '', '  ']) {
        final board = await LeaderboardService(
          firestore: db,
        ).load(branchId: b, group: LeaderboardGroup.trade);
        expect(board.entries, isEmpty);
      }
    });

    test('an admin gets no board', () async {
      final board = await boardFor('adm');
      expect(board.group, isNull);
      expect(board.entries, isEmpty);
    });

    test('ties are sorted by name', () async {
      await db.collection('users').doc('t1').set({
        'firstName': 'Zara',
        'role': 'engineer',
        'branchId': 'b1',
        'totalPoints': 60,
        'profile_verified': true,
      });
      final board = await boardFor('a1');
      expect(board.entries.map((e) => e.name), ['Ezhil', 'Zara', 'Arun']);
      expect(board.entries.map((e) => e.rank), [1, 2, 3]);
    });

    test(
      'user_points total is used first, users.totalPoints as fallback',
      () async {
        await db.collection('user_points').doc('c2').set({
          'userId': 'c2',
          'branchId': 'b1',
          'totalPoints': 500,
        });
        final board = await boardFor('c2');
        expect(board.entries.first.userId, 'c2');
        expect(board.entries.first.points, 500);
      },
    );
  });

  group('MemberRoleFilter', () {
    test('all, group and single-role filters', () {
      final roles = [
        'carpenter',
        'interior_designer',
        null,
        'architect',
        'engineer',
      ];
      List<String?> pass(MemberRoleFilter f) => roles.where(f.matches).toList();
      expect(pass(MemberRoleFilter.all), roles);
      expect(pass(MemberRoleFilter.group(LeaderboardGroup.trade)), [
        'carpenter',
        'interior_designer',
        null,
      ]);
      expect(pass(MemberRoleFilter.group(LeaderboardGroup.professional)), [
        'architect',
        'engineer',
      ]);
      expect(pass(MemberRoleFilter.role('carpenter')), ['carpenter', null]);
      expect(pass(MemberRoleFilter.role('engineer')), ['engineer']);
    });

    test('dropdown lists all, then each group with its roles', () {
      expect(MemberRoleFilter.options.map((f) => f.id), [
        'all',
        'group:trade',
        'role:carpenter',
        'role:interior_designer',
        'group:professional',
        'role:architect',
        'role:engineer',
      ]);
    });
  });
}
