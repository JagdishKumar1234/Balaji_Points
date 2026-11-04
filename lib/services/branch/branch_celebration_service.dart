import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:balaji_points/core/constants/app_constants.dart';
import 'package:balaji_points/core/utils/points_utils.dart';
import 'package:balaji_points/services/auth/session_service.dart';
import 'package:balaji_points/services/branch/branch_service.dart';

class BranchCelebrationEntry {
  const BranchCelebrationEntry({
    required this.name,
    required this.points,
    required this.rank,
    this.isCurrentUser = false,
  });

  final String name;
  final double points;
  final int rank;
  final bool isCurrentUser;

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

/// What the Diwali popup may show. It deliberately holds only the top three and
/// the logged-in member: never the rest of the branch or any phone number.
class BranchCelebrationSummary {
  const BranchCelebrationSummary({
    required this.topThree,
    required this.currentUser,
  });

  final List<BranchCelebrationEntry> topThree;

  /// Null when the logged-in user is not a member in this branch.
  final BranchCelebrationEntry? currentUser;
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
    final role = await _session.getUserRole();
    if (role == null || !AppConstants.isMemberRole(role)) {
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

  Future<BranchCelebrationSummary> loadCelebrationSummary(
    String branchId,
  ) async {
    final users = await _firestore
        .collection('users')
        .where('branchId', isEqualTo: branchId)
        .get();
    final memberDocs = users.docs.where((doc) {
      final data = doc.data();
      return AppConstants.isMemberRole(data['role'] as String?) &&
          data['status'] != 'deleted';
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
        <({String id, String uid, String phone, String name, double points})>[];
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
      final savedName = '$firstName $lastName'.trim();
      // Google accounts may only have a display name.
      final fullName = savedName.isNotEmpty
          ? savedName
          : (data['displayName'] as String? ?? data['name'] as String? ?? '')
                .trim();
      rows.add((
        id: userDoc.id,
        uid: uid,
        phone: phone,
        name: fullName.isEmpty ? 'Member' : fullName,
        points: resolvedPoints,
      ));
    }

    rows.sort((a, b) {
      final byPoints = b.points.compareTo(a.points);
      return byPoints != 0
          ? byPoints
          : a.name.toLowerCase().compareTo(b.name.toLowerCase());
    });

    final sessionId = (await _session.getUserId())?.trim() ?? '';
    final sessionPhone = (await _session.getPhoneNumber())?.trim() ?? '';
    var currentIndex = sessionId.isEmpty
        ? -1
        : rows.indexWhere((row) => row.id == sessionId);
    if (currentIndex < 0 && sessionId.isNotEmpty) {
      currentIndex = rows.indexWhere((row) => row.uid == sessionId);
    }
    if (currentIndex < 0 && sessionPhone.isNotEmpty) {
      currentIndex = rows.indexWhere((row) => row.phone == sessionPhone);
    }

    BranchCelebrationEntry entryAt(int index) => BranchCelebrationEntry(
      name: rows[index].name,
      points: rows[index].points,
      rank: index + 1,
      isCurrentUser: index == currentIndex,
    );

    return BranchCelebrationSummary(
      topThree: [
        for (var index = 0; index < rows.length && index < 3; index++)
          entryAt(index),
      ],
      currentUser: currentIndex < 0 ? null : entryAt(currentIndex),
    );
  }

  static double _asDouble(dynamic value) =>
      value is num ? value.toDouble() : double.tryParse('$value') ?? 0;
}
