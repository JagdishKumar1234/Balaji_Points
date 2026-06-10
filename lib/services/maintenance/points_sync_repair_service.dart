import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/logger.dart';

/// Service to repair and sync points data across all collections
/// Fixes: duplicate history entries, inconsistent totalPoints, tier mismatches
class PointsSyncRepairService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Generate comprehensive report of data issues
  Future<Map<String, dynamic>> generateRepairReport() async {
    AppLogger.info('═══════════════════════════════════════════════════════════');
    AppLogger.info('📊 GENERATING POINTS REPAIR REPORT');
    AppLogger.info('═══════════════════════════════════════════════════════════');

    try {
      final usersSnapshot = await _firestore.collection('user_points').get();
      final docs = usersSnapshot.docs;

      int totalIssues = 0;
      int usersWithDuplicates = 0;
      int totalDuplicatesFound = 0;
      int pointsMismatches = 0;
      double totalPointsDifference = 0;

      final issues = <String, Map<String, dynamic>>{};

      for (final doc in docs) {
        final data = doc.data();
        final userId = data['userId'] as String? ?? doc.id;
        final totalPoints = (data['totalPoints'] as num?)?.toInt() ?? 0;
        final history = (data['pointsHistory'] as List<dynamic>?) ?? [];

        // Check 1: Duplicate entries
        final billIds = <String, int>{};
        int duplicatesInThisUser = 0;

        for (final entry in history) {
          final entryMap = entry as Map<String, dynamic>;
          final billId = entryMap['billId'] as String? ?? '';
          if (billId.isNotEmpty) {
            billIds[billId] = (billIds[billId] ?? 0) + 1;
            if (billIds[billId]! > 1) {
              duplicatesInThisUser++;
            }
          }
        }

        // Check 2: Points mismatch (history sum vs totalPoints)
        double historySum = 0;
        for (final entry in history) {
          final entryMap = entry as Map<String, dynamic>;
          final points = (entryMap['points'] as num?)?.toDouble() ?? 0;
          historySum += points;
        }

        final pointsDiff = (historySum - totalPoints).abs();

        if (duplicatesInThisUser > 0 || pointsDiff > 0.1) {
          totalIssues++;
          if (duplicatesInThisUser > 0) usersWithDuplicates++;
          totalDuplicatesFound += duplicatesInThisUser;
          if (pointsDiff > 0.1) pointsMismatches++;
          totalPointsDifference += pointsDiff;

          issues[userId] = {
            'duplicateCount': duplicatesInThisUser,
            'historySum': historySum,
            'totalPoints': totalPoints,
            'pointsDifference': pointsDiff,
            'historyLength': history.length,
            'uniqueBills': billIds.length,
            'duplicateBillIds': billIds
                .entries
                .where((e) => e.value > 1)
                .map((e) => '${e.key} (${e.value}x)')
                .toList(),
          };
        }
      }

      AppLogger.info('📊 REPORT SUMMARY');
      AppLogger.info('═══════════════════════════════════════════════════════════');
      AppLogger.info('Total users scanned: ${docs.length}');
      AppLogger.info('Users with issues: $totalIssues');
      AppLogger.info('Users with duplicates: $usersWithDuplicates');
      AppLogger.info('Total duplicate entries: $totalDuplicatesFound');
      AppLogger.info('Users with points mismatch: $pointsMismatches');
      AppLogger.info('Total points difference: $totalPointsDifference');
      AppLogger.info('═══════════════════════════════════════════════════════════');

      return {
        'success': true,
        'totalUsersScanned': docs.length,
        'usersWithIssues': totalIssues,
        'usersWithDuplicates': usersWithDuplicates,
        'totalDuplicates': totalDuplicatesFound,
        'pointsMismatches': pointsMismatches,
        'totalPointsDifference': totalPointsDifference,
        'issues': issues,
      };
    } catch (e, st) {
      AppLogger.error('Error generating report', e, st);
      return {'success': false, 'error': e.toString()};
    }
  }

  /// Repair a specific user's points data
  /// Returns the new correct total points, or null if failed
  Future<int?> repairUserPoints(String userId) async {
    AppLogger.info('═══════════════════════════════════════════════════════════');
    AppLogger.info('🔧 REPAIRING POINTS FOR USER: $userId');
    AppLogger.info('═══════════════════════════════════════════════════════════');

    try {
      final userPointsRef = _firestore.collection('user_points').doc(userId);
      final userPointsDoc = await userPointsRef.get();

      if (!userPointsDoc.exists) {
        AppLogger.warning('User $userId not found in user_points');
        return null;
      }

      final data = userPointsDoc.data() ?? {};
      final history = (data['pointsHistory'] as List<dynamic>? ?? []).toList();

      if (history.isEmpty) {
        AppLogger.info('No history for user $userId');
        return 0;
      }

      // Step 1: Remove duplicates (keep first occurrence of each billId)
      AppLogger.info('Step 1: Removing duplicate entries...');
      final seenBills = <String>{};
      final cleanedHistory = <Map<String, dynamic>>[];

      for (final entry in history) {
        final entryMap = Map<String, dynamic>.from(entry as Map);
        final billId = entryMap['billId'] as String? ?? '';

        if (billId.isEmpty || !seenBills.contains(billId)) {
          cleanedHistory.add(entryMap);
          if (billId.isNotEmpty) {
            seenBills.add(billId);
          }
        }
      }

      AppLogger.info('  Removed ${history.length - cleanedHistory.length} duplicates');
      AppLogger.info('  Kept ${cleanedHistory.length} unique entries');

      // Step 2: Calculate correct total from cleaned history
      AppLogger.info('Step 2: Calculating correct total...');
      double correctTotal = 0;
      for (final entry in cleanedHistory) {
        final points = (entry['points'] as num?)?.toDouble() ?? 0;
        correctTotal += points;
      }

      final newTotal = correctTotal.toInt();
      AppLogger.info('  Calculated total: $newTotal');

      // Step 3: Calculate new tier
      final newTier = _calculateTier(newTotal);
      AppLogger.info('  New tier: $newTier');

      // Step 4: Update both collections atomically
      AppLogger.info('Step 3: Updating Firestore...');
      final batch = _firestore.batch();

      // Update user_points (source of truth)
      batch.set(
        userPointsRef,
        {
          'userId': userId,
          'totalPoints': newTotal,
          'tier': newTier,
          'lastUpdated': FieldValue.serverTimestamp(),
          'pointsHistory': cleanedHistory,
          'repaired': true,
          'repairedAt': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: false),
      );

      // Update users collection (mirror)
      final userRef = _firestore.collection('users').doc(userId);
      batch.set(
        userRef,
        {
          'totalPoints': newTotal,
          'tier': newTier,
          'lastUpdated': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );

      await batch.commit();
      AppLogger.info('✅ Firestore updated successfully');

      AppLogger.info('═══════════════════════════════════════════════════════════');
      AppLogger.info('✅ REPAIR COMPLETE FOR USER: $userId');
      AppLogger.info('  History entries: ${history.length} → ${cleanedHistory.length}');
      AppLogger.info('  Total points: ${data['totalPoints']} → $newTotal');
      AppLogger.info('═══════════════════════════════════════════════════════════');

      return newTotal;
    } catch (e, st) {
      AppLogger.error('Error repairing user points', e, st);
      AppLogger.info('═══════════════════════════════════════════════════════════');
      return null;
    }
  }

  /// Repair multiple users
  Future<Map<String, int?>> repairMultipleUsers(List<String> userIds) async {
    AppLogger.info('═══════════════════════════════════════════════════════════');
    AppLogger.info('🔧 REPAIRING ${userIds.length} USERS');
    AppLogger.info('═══════════════════════════════════════════════════════════');

    final results = <String, int?>{};

    for (final userId in userIds) {
      final newTotal = await repairUserPoints(userId);
      results[userId] = newTotal;
    }

    final successCount = results.values.where((v) => v != null).length;
    AppLogger.info('✅ Repaired $successCount/${userIds.length} users');
    AppLogger.info('═══════════════════════════════════════════════════════════');

    return results;
  }

  /// Repair all users with issues
  Future<Map<String, dynamic>> repairAllUsers() async {
    AppLogger.info('═══════════════════════════════════════════════════════════');
    AppLogger.info('🔧 REPAIRING ALL USERS WITH ISSUES');
    AppLogger.info('═══════════════════════════════════════════════════════════');

    try {
      final report = await generateRepairReport();

      if (!report['success']) {
        return {'success': false, 'error': 'Failed to generate report'};
      }

      final issues = (report['issues'] as Map<String, dynamic>?) ?? {};
      if (issues.isEmpty) {
        AppLogger.info('No issues found!');
        return {'success': true, 'repaired': 0, 'message': 'No issues found'};
      }

      final results = <String, int?>{};
      for (final userId in issues.keys) {
        final newTotal = await repairUserPoints(userId);
        results[userId] = newTotal;
      }

      final successCount = results.values.where((v) => v != null).length;

      AppLogger.info('═══════════════════════════════════════════════════════════');
      AppLogger.info('✅ REPAIR SUMMARY');
      AppLogger.info('Total users with issues: ${issues.length}');
      AppLogger.info('Successfully repaired: $successCount');
      AppLogger.info('═══════════════════════════════════════════════════════════');

      return {
        'success': true,
        'repaired': successCount,
        'total': issues.length,
        'results': results,
      };
    } catch (e, st) {
      AppLogger.error('Error repairing all users', e, st);
      return {'success': false, 'error': e.toString()};
    }
  }

  /// Verify that data is now correct
  Future<bool> verifyUserPoints(String userId) async {
    AppLogger.info('═══════════════════════════════════════════════════════════');
    AppLogger.info('✅ VERIFYING POINTS FOR USER: $userId');
    AppLogger.info('═══════════════════════════════════════════════════════════');

    try {
      final userPointsDoc =
          await _firestore.collection('user_points').doc(userId).get();
      final userDoc = await _firestore.collection('users').doc(userId).get();

      if (!userPointsDoc.exists) {
        AppLogger.info('User $userId not found');
        return false;
      }

      final userPointsData = userPointsDoc.data() ?? {};
      final userData = userDoc.data() ?? {};

      final userPointsTotal =
          (userPointsData['totalPoints'] as num?)?.toInt() ?? 0;
      final userTotal = (userData['totalPoints'] as num?)?.toInt() ?? 0;
      final history =
          (userPointsData['pointsHistory'] as List<dynamic>? ?? []);

      // Calculate history sum
      double historySum = 0;
      final billIds = <String>{};
      for (final entry in history) {
        final entryMap = entry as Map<String, dynamic>;
        final points = (entryMap['points'] as num?)?.toDouble() ?? 0;
        final billId = entryMap['billId'] as String? ?? '';
        historySum += points;
        if (billId.isNotEmpty) billIds.add(billId);
      }

      final isConsistent = (userPointsTotal == userTotal) &&
          ((historySum - userPointsTotal).abs() < 0.1);
      final hasDuplicates = history.length != billIds.length;

      AppLogger.info('user_points.totalPoints: $userPointsTotal');
      AppLogger.info('users.totalPoints: $userTotal');
      AppLogger.info('History sum: ${historySum.toInt()}');
      AppLogger.info('History entries: ${history.length}');
      AppLogger.info('Unique bills: ${billIds.length}');
      AppLogger.info('Has duplicates: $hasDuplicates');
      AppLogger.info('Consistent: $isConsistent');
      AppLogger.info('═══════════════════════════════════════════════════════════');

      if (isConsistent && !hasDuplicates) {
        AppLogger.info('✅ VERIFICATION PASSED');
        return true;
      } else {
        AppLogger.warning('⚠️ VERIFICATION FAILED - Data still has issues');
        return false;
      }
    } catch (e, st) {
      AppLogger.error('Error verifying points', e, st);
      return false;
    }
  }

  String _calculateTier(int totalPoints) {
    if (totalPoints >= 50000) return 'Platinum';
    if (totalPoints >= 25000) return 'Diamond';
    if (totalPoints >= 10000) return 'Gold';
    if (totalPoints >= 5000) return 'Silver';
    return 'Bronze';
  }
}
