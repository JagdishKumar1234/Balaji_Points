import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:balaji_points/core/constants/app_constants.dart';
import 'package:balaji_points/core/points/leaderboard_group.dart';
import 'package:balaji_points/services/leaderboard/leaderboard_service.dart';
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

  /// The top three and the signed-in member's own rank, counted only among
  /// approved members of the same branch **and the same role group**.
  Future<BranchCelebrationSummary> loadCelebrationSummary(
    String branchId,
  ) async {
    final sessionId = (await _session.getUserId())?.trim() ?? '';
    final sessionPhone = (await _session.getPhoneNumber())?.trim() ?? '';
    final service = LeaderboardService(firestore: _firestore);
    var board = await service.load(
      branchId: branchId,
      currentUserId: sessionId,
      currentPhone: sessionPhone,
    );
    // Profile not found by ID or phone: fall back to the role saved at login.
    if (board.group == null) {
      final group = LeaderboardGroups.of(await _session.getUserRole());
      final role = await _session.getUserRole();
      if (group != null && AppConstants.isMemberRole(role)) {
        board = await service.load(
          branchId: branchId,
          group: group,
          currentUserId: sessionId,
          currentPhone: sessionPhone,
        );
      }
    }

    BranchCelebrationEntry entryOf(LeaderboardEntry e) =>
        BranchCelebrationEntry(
          name: e.name,
          points: e.points,
          rank: e.rank,
          isCurrentUser: e.isCurrentUser,
        );

    return BranchCelebrationSummary(
      topThree: [for (final e in board.entries.take(3)) entryOf(e)],
      currentUser: board.currentUser == null
          ? null
          : entryOf(board.currentUser!),
    );
  }

}
