import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/logger.dart';

/// Maintenance service to detect and fix duplicate points in history
class DuplicatePointsCleaner {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Scan all user_points and find duplicates
  /// Returns map of userId -> duplicate billIds
  Future<Map<String, List<String>>> findDuplicates() async {
    try {
      AppLogger.info('Starting duplicate points scan...');
      final duplicates = <String, List<String>>{};

      final userPointsSnap =
          await _firestore.collection('user_points').get();

      for (final doc in userPointsSnap.docs) {
        final data = doc.data();
        final userId = data['userId'] as String?;
        final history =
            (data['pointsHistory'] as List<dynamic>?) ?? [];

        // Count occurrences of each billId
        final billCounts = <String, int>{};
        final billIds = <String>[];

        for (final entry in history) {
          final entryMap = entry as Map<String, dynamic>;
          final billId = entryMap['billId'] as String?;
          if (billId != null) {
            billCounts[billId] = (billCounts[billId] ?? 0) + 1;
            if (billCounts[billId]! > 1) {
              billIds.add(billId);
            }
          }
        }

        if (billIds.isNotEmpty && userId != null) {
          duplicates[userId] = billIds.toSet().toList();
          AppLogger.warning(
            'Found duplicates for user $userId: $billIds',
          );
        }
      }

      AppLogger.info(
        'Scan complete. Found ${duplicates.length} users with duplicates',
      );
      return duplicates;
    } catch (e) {
      AppLogger.error('Error scanning for duplicates', e);
      return {};
    }
  }

  /// Fix duplicates by removing extra entries, keeping only the first
  /// Returns count of fixed entries
  Future<int> fixDuplicates() async {
    try {
      AppLogger.info('Starting duplicate fix...');
      int fixedCount = 0;

      final userPointsSnap =
          await _firestore.collection('user_points').get();

      for (final doc in userPointsSnap.docs) {
        final data = doc.data();
        final history =
            (data['pointsHistory'] as List<dynamic>?) ?? [];

        if (history.isEmpty) continue;

        // Find and deduplicate
        final seen = <String>{};
        final cleanedHistory = <Map<String, dynamic>>[];

        for (final entry in history) {
          final entryMap = Map<String, dynamic>.from(entry as Map);
          final billId = entryMap['billId'] as String?;

          if (billId == null) {
            // Keep entries without billId
            cleanedHistory.add(entryMap);
          } else if (!seen.contains(billId)) {
            // Keep first occurrence of each billId
            cleanedHistory.add(entryMap);
            seen.add(billId);
          } else {
            // Skip duplicates
            AppLogger.warning(
              'Removing duplicate entry for bill $billId from user ${data['userId']}',
            );
            fixedCount++;
          }
        }

        // Update if changes were made
        if (cleanedHistory.length != history.length) {
          // Recalculate totalPoints from cleaned history
          double totalPoints = 0;
          for (final entry in cleanedHistory) {
            final points = (entry['points'] as num?)?.toDouble() ?? 0;
            totalPoints += points;
          }

          // Update document
          await doc.reference.update({
            'pointsHistory': cleanedHistory,
            'totalPoints': totalPoints,
            'lastUpdated': FieldValue.serverTimestamp(),
          });

          AppLogger.info(
            'Fixed ${cleanedHistory.length - history.length} duplicates for user ${data['userId']}',
          );
        }
      }

      AppLogger.info('Duplicate fix complete. Fixed $fixedCount entries');
      return fixedCount;
    } catch (e) {
      AppLogger.error('Error fixing duplicates', e);
      return 0;
    }
  }

  /// Verify and recalculate totalPoints for a user
  Future<void> verifyUserPoints(String userId) async {
    try {
      final userPointsRef = _firestore.collection('user_points').doc(userId);
      final doc = await userPointsRef.get();

      if (!doc.exists) {
        AppLogger.warning('User points doc not found: $userId');
        return;
      }

      final data = doc.data() ?? {};
      final history =
          (data['pointsHistory'] as List<dynamic>?) ?? [];
      final storedTotal = (data['totalPoints'] as num?)?.toDouble() ?? 0;

      // Calculate actual total
      double calculatedTotal = 0;
      for (final entry in history) {
        final points = (entry['points'] as num?)?.toDouble() ?? 0;
        calculatedTotal += points;
      }

      if ((storedTotal - calculatedTotal).abs() > 0.01) {
        AppLogger.warning(
          'Points mismatch for user $userId: stored=$storedTotal, calculated=$calculatedTotal',
        );

        // Fix the mismatch
        await userPointsRef.update({
          'totalPoints': calculatedTotal,
          'lastVerified': FieldValue.serverTimestamp(),
        });

        AppLogger.info(
          'Fixed points for user $userId: $storedTotal → $calculatedTotal',
        );
      } else {
        AppLogger.info('User $userId points verified: $calculatedTotal');
      }
    } catch (e) {
      AppLogger.error('Error verifying user points', e);
    }
  }

  /// Verify all users' points and fix mismatches
  Future<int> verifyAllPoints() async {
    try {
      AppLogger.info('Starting comprehensive points verification...');
      int fixedCount = 0;

      final userPointsSnap =
          await _firestore.collection('user_points').get();

      for (final doc in userPointsSnap.docs) {
        final userId = doc.data()['userId'] as String?;
        if (userId != null) {
          final before = (doc.data()['totalPoints'] as num?)?.toDouble() ?? 0;
          await verifyUserPoints(userId);
          final after = (await doc.reference.get()).data()?['totalPoints'] as num?;

          if ((before - (after?.toDouble() ?? 0)).abs() > 0.01) {
            fixedCount++;
          }
        }
      }

      AppLogger.info(
        'Verification complete. Fixed $fixedCount mismatches',
      );
      return fixedCount;
    } catch (e) {
      AppLogger.error('Error verifying all points', e);
      return 0;
    }
  }

  /// Fix duplicates for a specific user
  Future<bool> fixUserDuplicates(String userId) async {
    try {
      AppLogger.info('Fixing duplicates for user: $userId');

      final userPointsRef = _firestore.collection('user_points').doc(userId);
      final doc = await userPointsRef.get();

      if (!doc.exists) {
        AppLogger.warning('User points doc not found: $userId');
        return false;
      }

      final data = doc.data() ?? {};
      final history =
          (data['pointsHistory'] as List<dynamic>?) ?? [];

      if (history.isEmpty) {
        AppLogger.info('No history to clean for user: $userId');
        return true;
      }

      // Find duplicates
      final seen = <String>{};
      final cleanedHistory = <Map<String, dynamic>>[];
      int removedCount = 0;

      for (final entry in history) {
        final entryMap = Map<String, dynamic>.from(entry as Map);
        final billId = entryMap['billId'] as String?;

        if (billId == null) {
          cleanedHistory.add(entryMap);
        } else if (!seen.contains(billId)) {
          cleanedHistory.add(entryMap);
          seen.add(billId);
        } else {
          removedCount++;
          AppLogger.warning(
            'Removing duplicate for bill $billId from user $userId',
          );
        }
      }

      if (removedCount == 0) {
        AppLogger.info('No duplicates found for user: $userId');
        return true;
      }

      // Recalculate points
      double totalPoints = 0;
      for (final entry in cleanedHistory) {
        final points = (entry['points'] as num?)?.toDouble() ?? 0;
        totalPoints += points;
      }

      // Get tier based on points
      final tier = _calculateTier(totalPoints.toInt());

      // Update document
      await userPointsRef.update({
        'pointsHistory': cleanedHistory,
        'totalPoints': totalPoints,
        'tier': tier,
        'lastUpdated': FieldValue.serverTimestamp(),
        'cleanedAt': FieldValue.serverTimestamp(),
      });

      AppLogger.info(
        'Fixed user $userId: removed $removedCount duplicates, new total: $totalPoints',
      );
      return true;
    } catch (e) {
      AppLogger.error('Error fixing user duplicates', e);
      return false;
    }
  }

  /// Fix duplicates for multiple users
  Future<Map<String, bool>> fixMultipleUsers(List<String> userIds) async {
    try {
      AppLogger.info('Fixing duplicates for ${userIds.length} users...');
      final results = <String, bool>{};

      for (final userId in userIds) {
        final success = await fixUserDuplicates(userId);
        results[userId] = success;
      }

      final successCount = results.values.where((v) => v).length;
      AppLogger.info(
        'Batch fix complete: $successCount/${userIds.length} users fixed',
      );
      return results;
    } catch (e) {
      AppLogger.error('Error fixing multiple users', e);
      return {};
    }
  }

  /// Generate a report of all duplicates (detailed)
  Future<Map<String, dynamic>> generateDuplicateReport() async {
    try {
      AppLogger.info('Generating duplicate report...');

      final report = <String, dynamic>{
        'timestamp': DateTime.now().toIso8601String(),
        'totalUsersScanned': 0,
        'usersWithDuplicates': 0,
        'totalDuplicates': 0,
        'details': <String, Map<String, dynamic>>{},
      };

      final userPointsSnap =
          await _firestore.collection('user_points').get();

      report['totalUsersScanned'] = userPointsSnap.docs.length;

      for (final doc in userPointsSnap.docs) {
        final data = doc.data();
        final userId = data['userId'] as String?;
        final history =
            (data['pointsHistory'] as List<dynamic>?) ?? [];
        final storedTotal =
            (data['totalPoints'] as num?)?.toDouble() ?? 0;

        // Find duplicates
        final billCounts = <String, int>{};
        final duplicateEntries = <String, List<Map<String, dynamic>>>{};

        for (final entry in history) {
          final entryMap = entry as Map<String, dynamic>;
          final billId = entryMap['billId'] as String?;
          if (billId != null) {
            billCounts[billId] = (billCounts[billId] ?? 0) + 1;
            if (billCounts[billId]! > 1) {
              duplicateEntries
                  .putIfAbsent(billId, () => [])
                  .add(entryMap);
            }
          }
        }

        if (duplicateEntries.isNotEmpty) {
          // Calculate what the correct total should be
          final seen = <String>{};
          double correctTotal = 0;
          for (final entry in history) {
            final entryMap = entry as Map<String, dynamic>;
            final billId = entryMap['billId'] as String?;
            if (billId == null || !seen.contains(billId)) {
              correctTotal +=
                  (entryMap['points'] as num?)?.toDouble() ?? 0;
              if (billId != null) seen.add(billId);
            }
          }

          (report['details'] as Map)[userId ?? 'unknown'] = {
            'userId': userId,
            'storedTotal': storedTotal,
            'correctTotal': correctTotal,
            'pointsDifference': storedTotal - correctTotal,
            'duplicateCount': duplicateEntries.length,
            'duplicates': duplicateEntries.entries.map((e) {
              return {
                'billId': e.key,
                'occurrences': e.value.length,
                'entries': e.value,
              };
            }).toList(),
          };

          (report['usersWithDuplicates'] as int) + 1;
          (report['totalDuplicates'] as int) +
              duplicateEntries.values.fold<int>(
                0,
                (sum, entries) => sum + entries.length - 1,
              );
        }
      }

      // Recalculate counts
      report['usersWithDuplicates'] =
          (report['details'] as Map).length;
      int totalDuplicateCount = 0;
      for (final detail in (report['details'] as Map).values) {
        final dup = detail as Map<String, dynamic>;
        totalDuplicateCount += (dup['duplicateCount'] as int? ?? 0);
      }
      report['totalDuplicates'] = totalDuplicateCount;

      AppLogger.info('Report complete: ${report['usersWithDuplicates']} users with duplicates');
      return report;
    } catch (e) {
      AppLogger.error('Error generating report', e);
      return {};
    }
  }

  /// Calculate tier based on points
  static String _calculateTier(int points) {
    if (points >= 10000) return 'Platinum';
    if (points >= 5000) return 'Gold';
    if (points >= 2000) return 'Silver';
    return 'Bronze';
  }
}
