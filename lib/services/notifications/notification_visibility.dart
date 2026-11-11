import 'package:balaji_points/services/branch/current_branch_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// Who may see which notification: by role, branch and user. Every
/// notification screen and count goes through these rules.
class NotificationVisibility {
  NotificationVisibility._();

  /// Shown only to branch admins.
  static const adminTypes = {'newPendingBill', 'newUserRegistered'};

  /// Internal records that nobody's inbox shows.
  static const hiddenTypes = {'dailySpinReminder'};

  /// The only kinds that may go to every branch when they carry no branch.
  static const allBranchTypes = {
    'newOfferAvailable',
    'greeting',
    'announcement',
  };

  /// A member's inbox: their own notifications, plus announcements for their
  /// branch or for every branch. Never another branch's, never admin alerts.
  static bool memberCanSee(
    Map<String, dynamic>? data, {
    required Set<String> myIds,
    required String? myBranchId,
  }) {
    if (data == null) return false;
    final type = data['type'] as String? ?? '';
    if (adminTypes.contains(type) || hiddenTypes.contains(type)) return false;

    final userId = (data['userId'] as String? ?? '').trim();
    if (userId.isNotEmpty) return myIds.contains(userId);

    final branchId = (data['branchId'] as String? ?? '').trim();
    if (branchId.isNotEmpty) {
      return myBranchId != null && branchId == myBranchId;
    }
    return allBranchTypes.contains(type);
  }

  /// A branch admin's inbox: admin alerts for exactly their branch. Alerts
  /// with no branch are hidden, so one branch never sees another's.
  static bool adminCanSee(Map<String, dynamic>? data, {String? adminBranchId}) {
    if (data == null || adminBranchId == null || adminBranchId.isEmpty) {
      return false;
    }
    final type = data['type'] as String? ?? '';
    final branchId = (data['branchId'] as String? ?? '').trim();
    return adminTypes.contains(type) && branchId == adminBranchId;
  }
}

/// Filters notification documents for the signed-in branch admin.
extension AdminNotificationDocs<T extends Object?>
    on Iterable<QueryDocumentSnapshot<T>> {
  List<QueryDocumentSnapshot<T>> visibleToAdmin() {
    final branch = CurrentBranchService.adminBranchId;
    return where((doc) {
      final data = doc.data();
      return NotificationVisibility.adminCanSee(
        data is Map<String, dynamic> ? data : null,
        adminBranchId: branch,
      );
    }).toList();
  }
}
