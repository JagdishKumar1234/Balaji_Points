import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/logger.dart';

/// Centralized service for managing points operations
/// Ensures atomic operations and prevents double-counting
class PointsManagerService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Calculate tier based on total points
  String _calculateTier(int totalPoints) {
    if (totalPoints >= 50000) return 'Platinum';
    if (totalPoints >= 25000) return 'Diamond';
    if (totalPoints >= 10000) return 'Gold';
    if (totalPoints >= 5000) return 'Silver';
    return 'Bronze';
  }

  /// Add points to user (atomic operation)
  /// Returns new total points if successful, null if failed
  Future<int?> addPoints({
    required String userId,
    required int pointsToAdd,
    required String reason,
    required String billId,
    double amount = 0,
  }) async {
    AppLogger.info('═══════════════════════════════════════════════════════════');
    AppLogger.info('🎯 ADDING POINTS - CENTRAL LOGIC');
    AppLogger.info('═══════════════════════════════════════════════════════════');
    AppLogger.info('Input: userId=$userId, points=$pointsToAdd, reason=$reason');

    try {
      // Step 1: Get current points from user_points (source of truth)
      AppLogger.info('Step 1: Fetching current points from user_points...');
      final userPointsRef = _firestore.collection('user_points').doc(userId);
      final userPointsDoc = await userPointsRef.get();

      final currentPoints = userPointsDoc.exists
          ? (userPointsDoc.data()?['totalPoints'] as int? ?? 0)
          : 0;

      AppLogger.info('  Current points in user_points: $currentPoints');

      // Step 2: Calculate new total
      final newTotalPoints = currentPoints + pointsToAdd;
      final newTier = _calculateTier(newTotalPoints);

      AppLogger.info('  Points to add: $pointsToAdd');
      AppLogger.info('  New total: $newTotalPoints');
      AppLogger.info('  New tier: $newTier');

      // Step 3: Create history entry
      final historyEntry = {
        'points': pointsToAdd,
        'reason': reason,
        'billId': billId,
        'amount': amount,
        'date': Timestamp.now(),
        'timestamp': FieldValue.serverTimestamp(),
      };

      // Step 4: Atomic batch operation
      AppLogger.info('Step 2: Creating atomic batch operation...');
      final batch = _firestore.batch();

      // Update user_points (source of truth)
      AppLogger.info('  Operation 1: Update user_points document...');
      final userPointsData = userPointsDoc.exists
          ? userPointsDoc.data() ?? {}
          : {'userId': userId};

      final existingHistory =
          (userPointsData['pointsHistory'] as List<dynamic>? ?? []).toList();
      existingHistory.add(historyEntry);

      batch.set(
        userPointsRef,
        {
          'userId': userId,
          'totalPoints': newTotalPoints,
          'tier': newTier,
          'lastUpdated': FieldValue.serverTimestamp(),
          'pointsHistory': existingHistory,
        },
        SetOptions(merge: false), // Use false to ensure consistent state
      );

      // Update users collection (mirror)
      AppLogger.info('  Operation 2: Update users document (mirror)...');
      final userRef = _firestore.collection('users').doc(userId);
      batch.set(
        userRef,
        {
          'totalPoints': newTotalPoints,
          'tier': newTier,
          'lastUpdated': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );

      // Step 5: Commit atomic transaction
      AppLogger.info('Step 3: Committing batch transaction...');
      await batch.commit();
      AppLogger.info('✅ Batch committed successfully');

      // Step 6: Verify consistency
      AppLogger.info('Step 4: Verifying consistency...');
      await _verifyConsistency(userId, newTotalPoints);

      AppLogger.info('✅ Points added successfully!');
      AppLogger.info(
        'Final: $currentPoints + $pointsToAdd = $newTotalPoints',
      );
      AppLogger.info('═══════════════════════════════════════════════════════════');

      return newTotalPoints;
    } catch (e, st) {
      AppLogger.error('❌ Error adding points', e, st);
      AppLogger.info('═══════════════════════════════════════════════════════════');
      return null;
    }
  }

  /// Withdraw points from user (atomic operation)
  /// Returns new total points if successful, null if failed
  Future<int?> withdrawPoints({
    required String userId,
    required int pointsToWithdraw,
    required String reason,
    required String billId,
  }) async {
    AppLogger.info('═══════════════════════════════════════════════════════════');
    AppLogger.info('🎯 WITHDRAWING POINTS - CENTRAL LOGIC');
    AppLogger.info('═══════════════════════════════════════════════════════════');
    AppLogger.info('Input: userId=$userId, points=$pointsToWithdraw, reason=$reason');

    try {
      // Step 1: Get current points
      AppLogger.info('Step 1: Fetching current points...');
      final userPointsRef = _firestore.collection('user_points').doc(userId);
      final userPointsDoc = await userPointsRef.get();

      final currentPoints = userPointsDoc.exists
          ? (userPointsDoc.data()?['totalPoints'] as int? ?? 0)
          : 0;

      AppLogger.info('  Current points: $currentPoints');
      AppLogger.info('  Points to withdraw: $pointsToWithdraw');

      // Step 2: Validate sufficient points
      if (currentPoints < pointsToWithdraw) {
        AppLogger.error(
          '❌ Insufficient points: have $currentPoints, need $pointsToWithdraw',
          '',
        );
        return null;
      }

      // Step 3: Calculate new total
      final newTotalPoints = currentPoints - pointsToWithdraw;
      final newTier = _calculateTier(newTotalPoints);

      AppLogger.info('  New total: $newTotalPoints');
      AppLogger.info('  New tier: $newTier');

      // Step 4: Create history entry
      final historyEntry = {
        'points': -pointsToWithdraw, // Negative to indicate withdrawal
        'reason': reason,
        'billId': billId,
        'date': Timestamp.now(),
        'timestamp': FieldValue.serverTimestamp(),
      };

      // Step 5: Atomic batch operation
      AppLogger.info('Step 2: Creating atomic batch operation...');
      final batch = _firestore.batch();

      // Update user_points
      AppLogger.info('  Operation 1: Update user_points document...');
      final userPointsData = userPointsDoc.data() ?? {'userId': userId};
      final existingHistory =
          (userPointsData['pointsHistory'] as List<dynamic>? ?? []).toList();
      existingHistory.add(historyEntry);

      batch.set(
        userPointsRef,
        {
          'userId': userId,
          'totalPoints': newTotalPoints,
          'tier': newTier,
          'lastUpdated': FieldValue.serverTimestamp(),
          'pointsHistory': existingHistory,
        },
        SetOptions(merge: false),
      );

      // Update users collection
      AppLogger.info('  Operation 2: Update users document (mirror)...');
      final userRef = _firestore.collection('users').doc(userId);
      batch.set(
        userRef,
        {
          'totalPoints': newTotalPoints,
          'tier': newTier,
          'lastUpdated': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );

      // Step 6: Commit
      AppLogger.info('Step 3: Committing batch transaction...');
      await batch.commit();
      AppLogger.info('✅ Batch committed successfully');

      // Step 7: Verify
      AppLogger.info('Step 4: Verifying consistency...');
      await _verifyConsistency(userId, newTotalPoints);

      AppLogger.info('✅ Points withdrawn successfully!');
      AppLogger.info(
        'Final: $currentPoints - $pointsToWithdraw = $newTotalPoints',
      );
      AppLogger.info('═══════════════════════════════════════════════════════════');

      return newTotalPoints;
    } catch (e, st) {
      AppLogger.error('❌ Error withdrawing points', e, st);
      AppLogger.info('═══════════════════════════════════════════════════════════');
      return null;
    }
  }

  /// Get current points for user
  Future<int> getCurrentPoints(String userId) async {
    try {
      final doc = await _firestore.collection('user_points').doc(userId).get();
      if (doc.exists) {
        return (doc.data()?['totalPoints'] as int? ?? 0);
      }
      return 0;
    } catch (e) {
      AppLogger.error('Error getting current points', e);
      return 0;
    }
  }

  /// Get points history for user
  Future<List<Map<String, dynamic>>> getPointsHistory(String userId) async {
    try {
      final doc = await _firestore.collection('user_points').doc(userId).get();
      if (doc.exists) {
        final history = doc.data()?['pointsHistory'] as List<dynamic>? ?? [];
        return history.cast<Map<String, dynamic>>();
      }
      return [];
    } catch (e) {
      AppLogger.error('Error getting points history', e);
      return [];
    }
  }

  /// Verify consistency between user_points and users collections
  Future<void> _verifyConsistency(String userId, int expectedPoints) async {
    try {
      final userDoc = await _firestore.collection('users').doc(userId).get();
      final userPointsDoc =
          await _firestore.collection('user_points').doc(userId).get();

      final userPoints =
          userDoc.exists ? (userDoc.data()?['totalPoints'] as int? ?? 0) : 0;
      final userPointsPoints = userPointsDoc.exists
          ? (userPointsDoc.data()?['totalPoints'] as int? ?? 0)
          : 0;

      if (userPoints == userPointsPoints && userPoints == expectedPoints) {
        AppLogger.info(
          '✅ Consistency verified: both collections show $userPoints points',
        );
      } else {
        AppLogger.warning(
          '⚠️ Consistency check failed!\n'
          '  users.totalPoints: $userPoints\n'
          '  user_points.totalPoints: $userPointsPoints\n'
          '  expected: $expectedPoints',
        );
      }
    } catch (e) {
      AppLogger.warning('Error verifying consistency: $e');
    }
  }
}
