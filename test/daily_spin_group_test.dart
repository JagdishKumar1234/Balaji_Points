import 'dart:math';

import 'package:balaji_points/core/points/leaderboard_group.dart';
import 'package:balaji_points/services/spin/daily_spin_service.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';

const _today = '2026-11-13';

Future<FakeFirebaseFirestore> _seed() async {
  final db = FakeFirebaseFirestore();
  Future<void> user(
    String id,
    String? role,
    String branch, {
    bool verified = true,
    String? status,
  }) => db.collection('users').doc(id).set({
    'firstName': id.toUpperCase(),
    'role': ?role,
    'branchId': branch,
    'profile_verified': verified,
    'status': ?status,
  });
  await user('c1', 'carpenter', 'b1');
  await user('i1', 'interior_designer', 'b1');
  await user('old', null, 'b1');
  await user('a1', 'architect', 'b1');
  await user('e1', 'engineer', 'b1');
  await user('pend', 'carpenter', 'b1', verified: false);
  await user('del', 'carpenter', 'b1', status: 'deleted');
  await user('c9', 'carpenter', 'b2');
  await user('quiet', 'carpenter', 'b1'); // no bill today

  var n = 0;
  Future<void> bill(
    String who,
    String branch,
    num amount, {
    String status = 'approved',
    String date = _today,
  }) => db.collection('bills').doc('bill${n++}').set({
    'carpenterId': who,
    'branchId': branch,
    'amount': amount,
    'status': status,
    'approvedDate': date,
  });
  await bill('c1', 'b1', 10000);
  await bill('c1', 'b1', 5000);
  await bill('i1', 'b1', 20000);
  await bill('old', 'b1', 1000);
  await bill('a1', 'b1', 50000);
  await bill('e1', 'b1', 25000);
  await bill('pend', 'b1', 99999);
  await bill('del', 'b1', 99999);
  await bill('c9', 'b2', 99999);
  await bill('quiet', 'b1', 99999, status: 'pending');
  await bill('quiet', 'b1', 99999, date: '2026-11-12');
  return db;
}

void main() {
  late FakeFirebaseFirestore db;
  setUp(() async => db = await _seed());

  test(
    'group 1 qualifies only its own approved members with a bill today',
    () async {
      final list = await DailySpinService(
        firestore: db,
      ).eligible(branchId: 'b1', group: LeaderboardGroup.trade, date: _today);
      expect(list.map((c) => c.userId), ['i1', 'c1', 'old']);
      final c1 = list.firstWhere((c) => c.userId == 'c1');
      expect(c1.todaySales, 15000);
      expect(c1.billsCount, 2);
    },
  );

  test('group 2 qualifies only architects and engineers', () async {
    final list = await DailySpinService(firestore: db).eligible(
      branchId: 'b1',
      group: LeaderboardGroup.professional,
      date: _today,
    );
    expect(list.map((c) => c.userId), ['a1', 'e1']);
  });

  test('no branch → nobody', () async {
    final list = await DailySpinService(
      firestore: db,
    ).eligible(branchId: '', group: LeaderboardGroup.trade, date: _today);
    expect(list, isEmpty);
  });

  test('two spins a day: one per group, and each only once', () async {
    final spin = DailySpinService(firestore: db, random: Random(1));
    final w1 = await spin.spin(
      branchId: 'b1',
      group: LeaderboardGroup.trade,
      date: _today,
    );
    expect(['i1', 'c1', 'old'], contains(w1!.userId));

    // Group 1 is done for today, group 2 is not blocked.
    expect(
      await spin.canSpin(
        branchId: 'b1',
        group: LeaderboardGroup.trade,
        date: _today,
      ),
      isFalse,
    );
    expect(
      await spin.spin(
        branchId: 'b1',
        group: LeaderboardGroup.trade,
        date: _today,
      ),
      isNull,
    );
    final w2 = await spin.spin(
      branchId: 'b1',
      group: LeaderboardGroup.professional,
      date: _today,
    );
    expect(['a1', 'e1'], contains(w2!.userId));

    // Branch 2 is not blocked by branch 1.
    expect(
      await spin.canSpin(
        branchId: 'b2',
        group: LeaderboardGroup.trade,
        date: _today,
      ),
      isTrue,
    );

    final day1 = await db
        .collection('daily_winners')
        .doc('b1_trade_$_today')
        .get();
    expect(day1.data()!['carpenterId'], w1.userId);
    expect(day1.data()!['group'], 'trade');
    final day2 = await db
        .collection('daily_winners')
        .doc('b1_professional_$_today')
        .get();
    expect(day2.data()!['carpenterId'], w2.userId);
    // No group-less legacy doc is written.
    expect(
      (await db.collection('daily_winners').doc('b1_$_today').get()).exists,
      isFalse,
    );
    expect((await db.collection('daily_prize_winners').get()).docs.length, 2);
  });

  test('a group with nobody qualified cannot spin a winner', () async {
    final spin = DailySpinService(firestore: db);
    expect(
      await spin.spin(
        branchId: 'b2',
        group: LeaderboardGroup.professional,
        date: _today,
      ),
      isNull,
    );
  });
}
