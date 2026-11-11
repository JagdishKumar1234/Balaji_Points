import 'package:balaji_points/services/branch/branch_service.dart';

/// Daily winners are per branch: each branch's admin draws their own winner,
/// and members only ever see their own branch's.
class DailyWinnerScope {
  DailyWinnerScope._();

  /// The day the second branch opened. Winner records with no branch from
  /// before this day can only belong to the original branch.
  static const branchesSplitDate = '2026-11-02';

  /// Today's winner document for one branch, in `daily_winners`.
  static String docId(String branchId, String date) => '${branchId}_$date';

  /// Whether a winner record (from `daily_prize_winners` or `daily_winners`)
  /// belongs to [branchId].
  static bool belongsTo(Map<String, dynamic>? data, String? branchId) {
    if (data == null || branchId == null || branchId.isEmpty) return false;
    final recorded = (data['branchId'] as String? ?? '').trim();
    if (recorded.isNotEmpty) return recorded == branchId;
    final date = (data['date'] as String? ?? '').trim();
    return branchId == kDefaultBranchId &&
        date.isNotEmpty &&
        date.compareTo(branchesSplitDate) < 0;
  }
}
