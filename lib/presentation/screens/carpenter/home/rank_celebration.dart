import 'package:shared_preferences/shared_preferences.dart';

/// The rank #1 confetti on Home: only for a real leader (more than 0 points,
/// so a branch where everyone has 0 doesn't crown whoever sorts first), and
/// at most once a day per account, so it doesn't cover the screen on every
/// visit.
class RankCelebration {
  RankCelebration._();

  static String _key(String userId) => 'rank1_confetti_$userId';

  static String dayOf(DateTime now) =>
      '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';

  /// Whether the member qualifies at all, before checking today's record.
  static bool isRealLeader({
    required String? topUserId,
    required String? myUserId,
    required double topPoints,
  }) {
    return topUserId != null &&
        topUserId.isNotEmpty &&
        topUserId == myUserId &&
        topPoints > 0;
  }

  /// Returns true, and records today, if the confetti should play now.
  static Future<bool> claimToday(String userId, {DateTime? now}) async {
    final today = dayOf(now ?? DateTime.now());
    try {
      final prefs = await SharedPreferences.getInstance();
      if (prefs.getString(_key(userId)) == today) return false;
      await prefs.setString(_key(userId), today);
      return true;
    } catch (_) {
      // Storage unavailable: skip rather than replay on every visit.
      return false;
    }
  }
}
