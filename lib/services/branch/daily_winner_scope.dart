import 'package:balaji_points/core/points/leaderboard_group.dart';
import 'package:balaji_points/services/branch/branch_service.dart';

/// Daily winners are per branch **and per role group**: each branch's admin
/// draws one winner for carpenters + interior designers and one for
/// architects + engineers, and members only ever see their own branch's
/// winner for their own group.
class DailyWinnerScope {
  DailyWinnerScope._();

  /// The day the second branch opened. Winner records with no branch from
  /// before this day can only belong to the original branch.
  static const branchesSplitDate = '2026-11-02';

  /// Today's winner document for one branch and group, in `daily_winners`.
  static String docId(String branchId, LeaderboardGroup group, String date) =>
      '${branchId}_${group.id}_$date';

  /// The group a winner record was drawn for; null for records from before
  /// the draw was split by group (those were drawn from every role).
  static LeaderboardGroup? groupOf(Map<String, dynamic>? data) =>
      LeaderboardGroup.fromId(data?['group'] as String?);

  /// Whether a winner record (from `daily_prize_winners` or `daily_winners`)
  /// belongs to [branchId]. With [group], it must also have been drawn for
  /// that group, so records from before the split never match a group.
  static bool belongsTo(
    Map<String, dynamic>? data,
    String? branchId, {
    LeaderboardGroup? group,
  }) {
    if (data == null || branchId == null || branchId.isEmpty) return false;
    if (group != null && groupOf(data) != group) return false;
    final recorded = (data['branchId'] as String? ?? '').trim();
    if (recorded.isNotEmpty) return recorded == branchId;
    final date = (data['date'] as String? ?? '').trim();
    return branchId == kDefaultBranchId &&
        date.isNotEmpty &&
        date.compareTo(branchesSplitDate) < 0;
  }

  /// `YYYY-MM-DD` in local time, as stored on bills and winner records.
  static String dayKey(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
}
