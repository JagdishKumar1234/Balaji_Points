/// Shared helpers for carpenter points — single display/calculation rules app-wide.
class PointsUtils {
  PointsUtils._();

  static double asDouble(dynamic value) {
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString() ?? '') ?? 0.0;
  }

  /// [user_points] doc is the source of truth. If [totalPoints] is stale but
  /// [pointsHistory] is correct (legacy double-credit bug), trust deduped history.
  static double resolveTotalPoints(Map<String, dynamic> data) {
    final stored = asDouble(data['totalPoints']);
    final history = (data['pointsHistory'] as List<dynamic>?) ?? [];
    if (history.isEmpty) return stored;

    final dedupedSum = sumDedupedHistory(history);
    if ((stored - dedupedSum).abs() > 0.001) return dedupedSum;
    return stored;
  }

  static double sumDedupedHistory(List<dynamic> history) {
    double total = 0;
    for (final entry in dedupeHistory(history)) {
      total += asDouble((entry as Map)['points']);
    }
    return total;
  }

  /// For the same [billId], keep the entry with the highest points value.
  static List<Map<String, dynamic>> dedupeHistory(List<dynamic> entries) {
    final byBillId = <String, Map<String, dynamic>>{};
    final withoutBillId = <Map<String, dynamic>>[];

    for (final entry in entries) {
      final entryMap = Map<String, dynamic>.from(entry as Map);
      final billId = entryMap['billId'] as String? ?? '';
      if (billId.isEmpty) {
        withoutBillId.add(entryMap);
        continue;
      }

      final points = asDouble(entryMap['points']);
      final existing = byBillId[billId];
      if (existing == null) {
        byBillId[billId] = entryMap;
        continue;
      }

      if (points > asDouble(existing['points'])) {
        byBillId[billId] = entryMap;
      }
    }

    return [...byBillId.values, ...withoutBillId];
  }

  /// Consistent carpenter-facing points label (e.g. 2.5, 10, 1,250.50).
  static String formatPoints(num value) {
    final amount = value.toDouble();
    if (amount == amount.truncateToDouble()) {
      return amount.toStringAsFixed(0);
    }
    final twoDecimals = amount.toStringAsFixed(2);
    if (twoDecimals.endsWith('0')) {
      return amount.toStringAsFixed(1);
    }
    return twoDecimals;
  }
}
