import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:balaji_points/core/firebase/app_firestore.dart';
import 'package:balaji_points/core/points/leaderboard_group.dart';
import 'package:balaji_points/core/utils/points_utils.dart';
import 'package:balaji_points/services/branch/daily_winner_scope.dart';

/// A member who may win today's draw for their group.
class SpinCandidate {
  const SpinCandidate({
    required this.userId,
    required this.name,
    required this.role,
    required this.billsCount,
    required this.todaySales,
    required this.todayPoints,
    this.phone,
    this.profileImage,
  });

  final String userId;
  final String name;
  final String role;
  final String? phone;
  final String? profileImage;

  /// Bills approved today.
  final int billsCount;

  /// ₹ total of the bills approved today.
  final double todaySales;
  final double todayPoints;
}

/// The admin's daily draw: one per branch **per role group** per day.
/// A member qualifies with at least one bill approved today in this branch.
class DailySpinService {
  DailySpinService({FirebaseFirestore? firestore, Random? random})
    : _firestore = firestore ?? appFirestore,
      _random = random ?? Random();

  final FirebaseFirestore _firestore;
  final Random _random;

  /// Approved members of [group] in [branchId] with ≥1 bill approved on
  /// [date] (`YYYY-MM-DD`), highest sales first.
  Future<List<SpinCandidate>> eligible({
    required String? branchId,
    required LeaderboardGroup group,
    required String date,
  }) async {
    final branch = branchId?.trim() ?? '';
    if (branch.isEmpty) return const [];

    final bills = await _firestore
        .collection('bills')
        .where('branchId', isEqualTo: branch)
        .where('status', isEqualTo: 'approved')
        .where('approvedDate', isEqualTo: date)
        .get();

    final sales = <String, double>{};
    final points = <String, double>{};
    final counts = <String, int>{};
    for (final doc in bills.docs) {
      final d = doc.data();
      if ((d['branchId'] as String? ?? '') != branch) continue;
      // Bills store the member as `carpenterId`; `userId` is only on very
      // old records.
      final id = ((d['carpenterId'] ?? d['userId']) as String? ?? '').trim();
      if (id.isEmpty) continue;
      sales[id] =
          (sales[id] ?? 0) +
          PointsUtils.asDouble(d['amount'] ?? d['totalAmount']);
      points[id] =
          (points[id] ?? 0) +
          PointsUtils.asDouble(d['pointsEarned'] ?? d['points']);
      counts[id] = (counts[id] ?? 0) + 1;
    }

    final candidates = <SpinCandidate>[];
    for (final id in counts.keys) {
      final user = await _firestore.collection('users').doc(id).get();
      final u = user.data();
      if (u == null) continue;
      if ((u['branchId'] as String? ?? '').trim() != branch) continue;
      if (!MemberFilter.isActiveMemberOf(u, group)) continue;
      final first = (u['firstName'] as String? ?? '').trim();
      final last = (u['lastName'] as String? ?? '').trim();
      final name = '$first $last'.trim();
      candidates.add(
        SpinCandidate(
          userId: id,
          name: name.isEmpty
              ? ((u['displayName'] as String?)?.trim() ?? 'Member')
              : name,
          role: (u['role'] as String? ?? '').trim().toLowerCase(),
          phone: u['phone'] as String?,
          profileImage: u['profileImage'] as String?,
          billsCount: counts[id]!,
          todaySales: sales[id] ?? 0,
          todayPoints: points[id] ?? 0,
        ),
      );
    }
    candidates.sort((a, b) {
      final bySales = b.todaySales.compareTo(a.todaySales);
      return bySales != 0 ? bySales : a.name.compareTo(b.name);
    });
    return candidates;
  }

  /// This branch's winner record for [group] on [date], or null.
  Future<Map<String, dynamic>?> winnerOn({
    required String? branchId,
    required LeaderboardGroup group,
    required String date,
  }) async {
    final branch = branchId?.trim() ?? '';
    if (branch.isEmpty) return null;
    final snap = await _firestore
        .collection('daily_prize_winners')
        .where('date', isEqualTo: date)
        .get();
    for (final doc in snap.docs) {
      if (DailyWinnerScope.belongsTo(doc.data(), branch, group: group)) {
        return doc.data();
      }
    }
    return null;
  }

  /// One draw per branch, per group, per calendar day.
  Future<bool> canSpin({
    required String? branchId,
    required LeaderboardGroup group,
    required String date,
  }) async {
    if ((branchId?.trim() ?? '').isEmpty) return false;
    return await winnerOn(branchId: branchId, group: group, date: date) ==
        null;
  }

  /// Picks a random candidate and saves them as [group]'s winner for [date].
  /// Returns null when nobody qualifies or the group has already spun.
  Future<SpinCandidate?> spin({
    required String branchId,
    required LeaderboardGroup group,
    required String date,
  }) async {
    if (!await canSpin(branchId: branchId, group: group, date: date)) {
      return null;
    }
    final list = await eligible(branchId: branchId, group: group, date: date);
    if (list.isEmpty) return null;
    final winner = list[_random.nextInt(list.length)];

    final record = {
      'branchId': branchId,
      'group': group.id,
      'role': winner.role,
      'carpenterId': winner.userId,
      'carpenterName': winner.name,
      'carpenterPhoto': winner.profileImage ?? '',
      'todaySales': winner.todaySales,
      'billsCount': winner.billsCount,
      'eligibleCount': list.length,
      'date': date,
      'timestamp': FieldValue.serverTimestamp(),
    };
    // One winner per branch per group per day, for the member home card.
    // Claimed in a transaction so two admins spinning at once cannot both
    // win. (No group-less legacy doc is written: old apps would show this
    // winner to the other group.)
    final dayRef = _firestore
        .collection('daily_winners')
        .doc(DailyWinnerScope.docId(branchId, group, date));
    final claimed = await _firestore.runTransaction<bool>((tx) async {
      final existing = await tx.get(dayRef);
      if (existing.exists) return false;
      tx.set(dayRef, record);
      return true;
    });
    if (!claimed) return null;
    await _firestore.collection('daily_prize_winners').add(record);
    return winner;
  }
}
