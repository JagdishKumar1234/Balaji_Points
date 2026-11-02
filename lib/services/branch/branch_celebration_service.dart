import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:balaji_points/core/utils/points_utils.dart';
import 'package:balaji_points/services/auth/session_service.dart';
import 'package:balaji_points/services/branch/branch_service.dart';

class BranchCelebrationEntry {
  const BranchCelebrationEntry({
    required this.userId,
    required this.name,
    required this.mobileNumber,
    required this.points,
    required this.rank,
    required this.tier,
  });

  final String userId;
  final String name;
  final String mobileNumber;
  final double points;
  final int rank;
  final String tier;

  int get rewardAmount => (points * 10).round();

  int get bonusAmount => switch (rank) {
    1 => 10000,
    2 => 5000,
    3 => 3500,
    _ => 0,
  };

  String get giftDetails => switch (rank) {
    1 => 'Mega Trophy',
    2 || 3 => 'Premium Gift',
    _ => 'Nil',
  };

  String? get prizeLabel => switch (rank) {
    1 => '1st prize',
    2 => '2nd prize',
    3 => '3rd prize',
    _ => null,
  };
}

class BranchCelebrationService {
  BranchCelebrationService({
    FirebaseFirestore? firestore,
    SessionService? session,
  }) : _firestore = firestore ?? FirebaseFirestore.instance,
       _session = session ?? SessionService();

  final FirebaseFirestore _firestore;
  final SessionService _session;

  Future<String> loadBranchName(String branchId) async {
    final branch = await _firestore.collection('branches').doc(branchId).get();
    return branch.data()?['name'] as String? ?? branchId;
  }

  Future<String?> getCurrentBranchId() => _resolveCurrentBranchId();

  Stream<bool> watchCurrentBranchEnabled() async* {
    final role = (await _session.getUserRole())?.toLowerCase();
    if (role != 'carpenter') {
      yield false;
      return;
    }
    final branchId = await _resolveCurrentBranchId();
    if (branchId == null || branchId.isEmpty) {
      yield false;
      return;
    }
    yield* _firestore.collection('branches').doc(branchId).snapshots().map((
      snapshot,
    ) {
      final data = snapshot.data();
      final setting = data?['diwaliCelebrationEnabled'];
      return setting is bool ? setting : branchId == kDefaultBranchId;
    });
  }

  Future<String?> _resolveCurrentBranchId() async {
    final stored = await _session.getBranchId();
    if (stored != null && stored.trim().isNotEmpty) return stored.trim();

    final userId = await _session.getUserId();
    if (userId != null && userId.trim().isNotEmpty) {
      final user = await _firestore.collection('users').doc(userId).get();
      final branchId = user.data()?['branchId'] as String?;
      if (branchId != null && branchId.trim().isNotEmpty) {
        return branchId.trim();
      }
    }
    final phone = await _session.getPhoneNumber();
    if (phone != null && phone.trim().isNotEmpty) {
      final users = await _firestore
          .collection('users')
          .where('phone', isEqualTo: phone.trim())
          .limit(1)
          .get();
      if (users.docs.isNotEmpty) {
        final branchId = users.docs.first.data()['branchId'] as String?;
        if (branchId != null && branchId.trim().isNotEmpty) {
          return branchId.trim();
        }
      }
    }
    return null;
  }

  Future<List<BranchCelebrationEntry>> loadBranchCarpenters(
    String branchId,
  ) async {
    final users = await _firestore
        .collection('users')
        .where('branchId', isEqualTo: branchId)
        .get();
    final memberDocs = users.docs.where((doc) {
      final data = doc.data();
      final role = (data['role'] as String? ?? 'carpenter').toLowerCase();
      return role == 'carpenter' && data['status'] != 'deleted';
    }).toList();

    final pointsSnapshot = await _firestore
        .collection('user_points')
        .where('branchId', isEqualTo: branchId)
        .get();
    final pointsById = <String, Map<String, dynamic>>{};
    for (final pointsDoc in pointsSnapshot.docs) {
      pointsById[pointsDoc.id] = pointsDoc.data();
      final userId = pointsDoc.data()['userId'] as String?;
      if (userId != null && userId.isNotEmpty) {
        pointsById[userId] = pointsDoc.data();
      }
    }

    final rows =
        <
          ({String id, String name, String mobile, String tier, double points})
        >[];
    for (final userDoc in memberDocs) {
      final data = userDoc.data();
      final uid = data['uid'] as String? ?? '';
      final phone = data['phone'] as String? ?? '';
      final pointsData =
          pointsById[userDoc.id] ??
          (uid.isEmpty ? null : pointsById[uid]) ??
          (phone.isEmpty ? null : pointsById[phone]);
      final resolvedPoints = pointsData == null
          ? _asDouble(data['totalPoints'])
          : PointsUtils.resolveTotalPoints(pointsData);
      final firstName = (data['firstName'] as String? ?? '').trim();
      final lastName = (data['lastName'] as String? ?? '').trim();
      final fullName = '$firstName $lastName'.trim();
      rows.add((
        id: userDoc.id,
        name: fullName.isEmpty ? 'Carpenter' : fullName,
        mobile: phone,
        tier:
            (pointsData?['tier'] as String? ??
            data['tier'] as String? ??
            'Bronze'),
        points: resolvedPoints,
      ));
    }

    rows.sort((a, b) {
      final byPoints = b.points.compareTo(a.points);
      return byPoints != 0
          ? byPoints
          : a.name.toLowerCase().compareTo(b.name.toLowerCase());
    });
    return [
      for (var index = 0; index < rows.length; index++)
        BranchCelebrationEntry(
          userId: rows[index].id,
          name: rows[index].name,
          mobileNumber: rows[index].mobile,
          points: rows[index].points,
          rank: index + 1,
          tier: index < 10
              ? 'Gold'
              : index < 30
              ? 'Silver'
              : 'Bronze',
        ),
    ];
  }

  static double _asDouble(dynamic value) =>
      value is num ? value.toDouble() : double.tryParse('$value') ?? 0;
}
