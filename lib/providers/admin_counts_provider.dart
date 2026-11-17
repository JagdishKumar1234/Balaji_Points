import 'package:balaji_points/core/firebase/app_firestore.dart';
import 'package:balaji_points/core/points/leaderboard_group.dart';
import 'package:balaji_points/services/branch/current_branch_service.dart';
import 'package:balaji_points/services/notifications/notification_visibility.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Live "waiting" counts for the signed-in branch admin, shown as badges on
/// the admin tab bar and its tabs. All scoped to the admin's own branch
/// (from [currentBranchProvider]); no branch yet means 0.

String? _branchId(Ref ref) =>
    ref.watch(currentBranchProvider).asData?.value?.id;

/// Bills waiting for review.
final adminPendingBillsCountProvider = StreamProvider.autoDispose<int>((ref) {
  final branch = _branchId(ref);
  if (branch == null || branch.isEmpty) return Stream.value(0);
  return appFirestore
      .collection('bills')
      .where('branchId', isEqualTo: branch)
      .where('status', isEqualTo: 'pending')
      .snapshots()
      .map((s) => s.size);
});

/// Member sign-ups waiting for approval (all four roles).
final adminRequestsCountProvider = StreamProvider.autoDispose<int>((ref) {
  final branch = _branchId(ref);
  if (branch == null || branch.isEmpty) return Stream.value(0);
  return appFirestore
      .collection('users')
      .where('branchId', isEqualTo: branch)
      .snapshots()
      .map(
        (s) => s.docs.where((doc) {
          final d = doc.data();
          return LeaderboardGroups.of(d['role'] as String?) != null &&
              d['status'] != 'deleted' &&
              AccountApproval.statusOf(d) == AccountApproval.pending;
        }).length,
      );
});

/// Admin alerts (new bills, account requests) for this branch.
final adminAlertsCountProvider = StreamProvider.autoDispose<int>((ref) {
  final branch = _branchId(ref);
  if (branch == null || branch.isEmpty) return Stream.value(0);
  return appFirestore
      .collection('notification_logs')
      .where('type', whereIn: const ['newPendingBill', 'newUserRegistered'])
      .snapshots()
      .map(
        (s) => s.docs
            .where(
              (d) => NotificationVisibility.adminCanSee(
                d.data(),
                adminBranchId: branch,
              ),
            )
            .length,
      );
});
