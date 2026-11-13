import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:balaji_points/core/firebase/app_firestore.dart';
import 'package:balaji_points/core/points/leaderboard_group.dart';
import 'package:balaji_points/core/utils/points_utils.dart';

/// One member on a branch + group leaderboard.
class LeaderboardEntry {
  const LeaderboardEntry({
    required this.rank,
    required this.userId,
    required this.name,
    required this.points,
    required this.role,
    this.imageUrl,
    this.isCurrentUser = false,
  });

  final int rank;
  final String userId;
  final String name;
  final double points;
  final String role;
  final String? imageUrl;
  final bool isCurrentUser;
}

/// A ranked board for one branch and one group.
class LeaderboardResult {
  const LeaderboardResult({
    required this.group,
    required this.entries,
    required this.currentUser,
  });

  static const empty = LeaderboardResult(
    group: null,
    entries: [],
    currentUser: null,
  );

  /// Null when the signed-in user is not in a member group.
  final LeaderboardGroup? group;

  /// Every active member of the group in the branch, ranked 1..n.
  final List<LeaderboardEntry> entries;

  /// The signed-in member's own entry, when they are on this board.
  final LeaderboardEntry? currentUser;

  /// How many members compete on this board.
  int get total => entries.length;
}

/// The single source of truth for rankings. Members are ranked only against
/// approved members of the **same branch and the same role group**; the home
/// board and the celebration popup both use this, so they never disagree.
class LeaderboardService {
  LeaderboardService({FirebaseFirestore? firestore})
    : _firestore = firestore ?? appFirestore;

  final FirebaseFirestore _firestore;

  /// Ranks [branchId]'s members in [group]. When [group] is null it is taken
  /// from the signed-in user's own record (found by [currentUserId],
  /// [currentUid] or [currentPhone]); a user who is not a member gets
  /// [LeaderboardResult.empty]. An empty [branchId] also gives an empty
  /// board: other branches are never read.
  Future<LeaderboardResult> load({
    required String? branchId,
    LeaderboardGroup? group,
    String? currentUserId,
    String? currentUid,
    String? currentPhone,
    Source source = Source.serverAndCache,
  }) async {
    final branch = branchId?.trim() ?? '';
    if (branch.isEmpty) return LeaderboardResult.empty;

    final options = GetOptions(source: source);
    final users = await _firestore
        .collection('users')
        .where('branchId', isEqualTo: branch)
        .get(options);

    final myId = currentUserId?.trim() ?? '';
    final myUid = currentUid?.trim() ?? '';
    final myPhone = currentPhone?.trim() ?? '';
    bool isMe(String docId, Map<String, dynamic> d) {
      if (myId.isNotEmpty && (docId == myId || d['uid'] == myId)) return true;
      if (myUid.isNotEmpty && (docId == myUid || d['uid'] == myUid)) {
        return true;
      }
      return myPhone.isNotEmpty && d['phone'] == myPhone;
    }

    // The board's group: given, or the signed-in member's own.
    var boardGroup = group;
    if (boardGroup == null) {
      for (final doc in users.docs) {
        if (isMe(doc.id, doc.data())) {
          boardGroup = LeaderboardGroups.of(doc.data()['role'] as String?);
          break;
        }
      }
    }
    if (boardGroup == null) return LeaderboardResult.empty;

    final pointsById = await _pointsByUser(branch, options);

    final rows = <_Row>[];
    for (final doc in users.docs) {
      final d = doc.data();
      // Re-check the branch: cached snapshots must never leak another one.
      if ((d['branchId'] as String? ?? '').trim() != branch) continue;
      if (!MemberFilter.isActiveMemberOf(d, boardGroup)) continue;

      final uid = d['uid'] as String? ?? '';
      final phone = d['phone'] as String? ?? '';
      final pointsData =
          pointsById[doc.id] ??
          (uid.isEmpty ? null : pointsById[uid]) ??
          (phone.isEmpty ? null : pointsById[phone]);
      final points = pointsData == null
          ? PointsUtils.asDouble(d['totalPoints'])
          : PointsUtils.resolveTotalPoints(pointsData);

      rows.add(
        _Row(
          id: doc.id,
          name: _nameOf(d),
          points: points,
          role: (d['role'] as String? ?? '').trim().toLowerCase(),
          imageUrl: d['profileImage'] as String?,
          isMe: isMe(doc.id, d),
        ),
      );
    }

    rows.sort((a, b) {
      final byPoints = b.points.compareTo(a.points);
      return byPoints != 0
          ? byPoints
          : a.name.toLowerCase().compareTo(b.name.toLowerCase());
    });

    LeaderboardEntry? me;
    final entries = <LeaderboardEntry>[];
    for (var i = 0; i < rows.length; i++) {
      final r = rows[i];
      final entry = LeaderboardEntry(
        rank: i + 1,
        userId: r.id,
        name: r.name,
        points: r.points,
        role: r.role,
        imageUrl: r.imageUrl,
        isCurrentUser: r.isMe && me == null,
      );
      if (entry.isCurrentUser) me = entry;
      entries.add(entry);
    }

    return LeaderboardResult(
      group: boardGroup,
      entries: entries,
      currentUser: me,
    );
  }

  /// `user_points` is the main points record; `users.totalPoints` is the
  /// fallback for members without one.
  Future<Map<String, Map<String, dynamic>>> _pointsByUser(
    String branchId,
    GetOptions options,
  ) async {
    final byId = <String, Map<String, dynamic>>{};
    try {
      final snap = await _firestore
          .collection('user_points')
          .where('branchId', isEqualTo: branchId)
          .get(options);
      for (final doc in snap.docs) {
        final data = doc.data();
        byId[doc.id] = data;
        final userId = data['userId'] as String?;
        if (userId != null && userId.isNotEmpty) byId[userId] = data;
      }
    } catch (_) {
      // Fall back to users.totalPoints (e.g. nothing cached yet offline).
    }
    return byId;
  }

  static String _nameOf(Map<String, dynamic> d) {
    final first = (d['firstName'] as String? ?? '').trim();
    final last = (d['lastName'] as String? ?? '').trim();
    final saved = '$first $last'.trim();
    // Google accounts may only have a display name.
    final name = saved.isNotEmpty
        ? saved
        : (d['displayName'] as String? ?? d['name'] as String? ?? '').trim();
    return name.isEmpty ? 'Member' : name;
  }
}

class _Row {
  _Row({
    required this.id,
    required this.name,
    required this.points,
    required this.role,
    required this.imageUrl,
    required this.isMe,
  });

  final String id;
  final String name;
  final double points;
  final String role;
  final String? imageUrl;
  final bool isMe;
}
