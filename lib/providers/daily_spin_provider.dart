import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import '../services/notifications/notification_service.dart';
import '../core/logger.dart';

class DailySpinState {
  final bool canSpin;
  final DateTime? lastSpinDate;
  final bool isLoading;
  final int? pointsWon;
  final bool isCarpenter;

  DailySpinState({
    required this.canSpin,
    this.lastSpinDate,
    required this.isLoading,
    this.pointsWon,
    required this.isCarpenter,
  });

  DailySpinState copyWith({
    bool? canSpin,
    DateTime? lastSpinDate,
    bool? isLoading,
    int? pointsWon,
    bool? isCarpenter,
  }) {
    return DailySpinState(
      canSpin: canSpin ?? this.canSpin,
      lastSpinDate: lastSpinDate ?? this.lastSpinDate,
      isLoading: isLoading ?? this.isLoading,
      pointsWon: pointsWon ?? this.pointsWon,
      isCarpenter: isCarpenter ?? this.isCarpenter,
    );
  }
}

class DailySpinNotifier extends Notifier<DailySpinState> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  @override
  DailySpinState build() {
    // Initialize state asynchronously
    Future.microtask(() => _initializeSpinState());
    // For testing: show widget even if not carpenter, set canSpin to true by default
    return DailySpinState(canSpin: true, isLoading: false, isCarpenter: true);
  }

  Future<void> _initializeSpinState() async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        // For testing: allow spin even without user
        state = state.copyWith(
          isLoading: false,
          isCarpenter: true,
          canSpin: true,
        );
        return;
      }

      // Check if user is a carpenter
      // final userDoc = await _firestore.collection('users').doc(user.uid).get();
      // final userData = userDoc.data();
      // final userRole = userData?['role'] as String? ?? '';
      // final isCarpenter = userRole.toLowerCase() == 'carpenter';

      // For testing: allow even if not carpenter in Firestore
      // Uncomment above and below for production
      // if (!isCarpenter) {
      //   state = state.copyWith(isLoading: false, isCarpenter: false);
      //   return;
      // }

      // Check last spin date
      final lastSpinDoc = await _firestore
          .collection('daily_spins')
          .doc(user.uid)
          .get();

      DateTime? lastSpinDate;
      if (lastSpinDoc.exists) {
        final lastSpinData = lastSpinDoc.data();
        final timestamp = lastSpinData?['lastSpinDate'] as Timestamp?;
        lastSpinDate = timestamp?.toDate();
      }

      final now = DateTime.now();
      final canSpin =
          lastSpinDate == null ||
          lastSpinDate.year != now.year ||
          lastSpinDate.month != now.month ||
          lastSpinDate.day != now.day;

      state = state.copyWith(
        canSpin: canSpin,
        lastSpinDate: lastSpinDate,
        isLoading: false,
        isCarpenter: true, // Always true for testing
      );
    } catch (e) {
      // On error, still allow spin for testing
      state = state.copyWith(
        isLoading: false,
        isCarpenter: true,
        canSpin: true,
      );
    }
  }

  Future<int> performSpin([int? pointsWon]) async {
    if (!state.canSpin) {
      return 0;
    }

    state = state.copyWith(isLoading: true);

    try {
      final user = _auth.currentUser;
      if (user == null) {
        state = state.copyWith(isLoading: false);
        return 0;
      }

      // Use provided points or generate random points as fallback
      // Ensure pointsWon is valid (not null and > 0)
      int finalPointsWon;
      if (pointsWon != null && pointsWon > 0) {
        finalPointsWon = pointsWon;
      } else {
        // Fallback: random points between 10-80
        finalPointsWon =
            ((DateTime.now().millisecondsSinceEpoch % 8) * 10 + 10);
        debugPrint(
          'WARNING: pointsWon was null or invalid ($pointsWon), using fallback: $finalPointsWon',
        );
      }

      debugPrint(
        'performSpin called with pointsWon=$pointsWon, finalPointsWon=$finalPointsWon',
      );

      // Check if this prize has already been won today
      final today = DateTime.now();
      final todayStart = DateTime(today.year, today.month, today.day);

      final prizeQuery = await _firestore
          .collection('daily_prize_winners')
          .where('prizePoints', isEqualTo: finalPointsWon)
          .where(
            'wonDate',
            isGreaterThanOrEqualTo: Timestamp.fromDate(todayStart),
          )
          .limit(1)
          .get();

      if (prizeQuery.docs.isNotEmpty) {
        // This prize was already won today, give them a consolation prize
        debugPrint(
          'Prize $finalPointsWon already won today, giving consolation prize',
        );
        finalPointsWon = 5; // Consolation prize
      }

      // Get current user data
      final userRef = _firestore.collection('users').doc(user.uid);
      final userDoc = await userRef.get();

      if (!userDoc.exists) {
        state = state.copyWith(isLoading: false);
        return 0;
      }

      final userData = userDoc.data()!;
      final currentPoints = (userData['totalPoints'] ?? 0) as int;
      final oldTier = userData['tier'] as String? ?? 'Bronze';
      final newTotalPoints = currentPoints + finalPointsWon;
      final newTier = _calculateTier(newTotalPoints);

      // Get user_points document reference
      final userPointsRef = _firestore.collection('user_points').doc(user.uid);
      final userPointsDoc = await userPointsRef.get();

      // Create history entry
      final newHistoryEntry = {
        'points': finalPointsWon,
        'reason': 'Daily spin',
        'date': FieldValue.serverTimestamp(),
        'spinDate': FieldValue.serverTimestamp(),
      };

      // Use batch for atomic operations
      final batch = _firestore.batch();

      // 1. Update daily_spins collection
      final dailySpinRef = _firestore.collection('daily_spins').doc(user.uid);
      batch.set(dailySpinRef, {
        'userId': user.uid,
        'lastSpinDate': FieldValue.serverTimestamp(),
        'pointsWon': finalPointsWon,
        'totalSpins': FieldValue.increment(1),
        'lastUpdated': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      // 2. Update user totalPoints and tier
      batch.set(userRef, {
        'totalPoints': newTotalPoints,
        'tier': newTier,
        'lastUpdated': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      // 3. Update user_points collection with history
      if (userPointsDoc.exists) {
        batch.update(userPointsRef, {
          'totalPoints': newTotalPoints,
          'tier': newTier,
          'lastUpdated': FieldValue.serverTimestamp(),
          'pointsHistory': FieldValue.arrayUnion([newHistoryEntry]),
        });
      } else {
        batch.set(userPointsRef, {
          'userId': user.uid,
          'totalPoints': newTotalPoints,
          'tier': newTier,
          'lastUpdated': FieldValue.serverTimestamp(),
          'pointsHistory': [newHistoryEntry],
        });
      }

      // 4. Record prize winner (only if not consolation prize)
      if (finalPointsWon > 5) {
        final prizeWinnerRef = _firestore
            .collection('daily_prize_winners')
            .doc();
        batch.set(prizeWinnerRef, {
          'userId': user.uid,
          'userName': userData['name'] ?? 'Unknown',
          'prizePoints': finalPointsWon,
          'wonDate': FieldValue.serverTimestamp(),
          'createdAt': FieldValue.serverTimestamp(),
        });
      }

      // Commit all changes atomically
      await batch.commit();

      debugPrint(
        'Spin completed successfully: $finalPointsWon points saved to Firebase',
      );

      // Send notification after successful spin
      try {
        final notificationService = NotificationService();
        await notificationService.sendDailySpinWonNotification(
          userId: user.uid,
          points: finalPointsWon,
        );

        // Check for tier upgrade and send notification if tier changed
        if (oldTier != newTier) {
          AppLogger.info('Tier upgraded from $oldTier to $newTier');
          await notificationService.sendTierUpgradedNotification(
            userId: user.uid,
            newTier: newTier,
            points: newTotalPoints,
          );
        }

        // Check for points milestone
        await _checkAndNotifyMilestone(
          notificationService,
          user.uid,
          newTotalPoints,
        );
      } catch (e) {
        // Don't fail the spin if notification fails
        AppLogger.warning('Failed to send notification after daily spin: $e');
      }

      state = state.copyWith(
        canSpin: false,
        lastSpinDate: DateTime.now(),
        isLoading: false,
        pointsWon: finalPointsWon,
      );

      // Always return the points that were saved
      return finalPointsWon;
    } catch (e, stackTrace) {
      debugPrint('Error performing spin: $e');
      debugPrint('Stack trace: $stackTrace');
      state = state.copyWith(isLoading: false);

      // Even on error, if we have valid points, return them
      // This ensures the UI shows the correct points even if save partially fails
      if (pointsWon != null && pointsWon > 0) {
        debugPrint('Returning points despite error: $pointsWon');
        return pointsWon;
      }

      return 0;
    }
  }

  /// Calculate tier based on points
  String _calculateTier(int points) {
    if (points >= 10000) {
      return 'Platinum';
    } else if (points >= 5000) {
      return 'Gold';
    } else if (points >= 2000) {
      return 'Silver';
    } else {
      return 'Bronze';
    }
  }

  /// Check for points milestone and send notification if reached
  Future<void> _checkAndNotifyMilestone(
    NotificationService notificationService,
    String userId,
    int newPoints,
  ) async {
    try {
      // Define milestone thresholds
      const milestones = [
        1000,
        2500,
        5000,
        7500,
        10000,
        15000,
        20000,
        25000,
        50000,
      ];

      // Check if new points crossed any milestone
      for (final milestone in milestones) {
        // Get user's last milestone from Firestore
        final userDoc = await _firestore.collection('users').doc(userId).get();
        final lastMilestone = userDoc.exists
            ? (userDoc.data()?['lastMilestone'] as int? ?? 0)
            : 0;

        // If we crossed this milestone and haven't notified for it yet
        if (newPoints >= milestone && lastMilestone < milestone) {
          // Send milestone notification
          await notificationService.sendPointsMilestoneNotification(
            userId: userId,
            points: newPoints,
            milestone: milestone,
          );

          // Update last milestone in Firestore
          await _firestore.collection('users').doc(userId).set({
            'lastMilestone': milestone,
          }, SetOptions(merge: true));

          AppLogger.info('Milestone notification sent: $milestone points');
          break; // Only notify for the highest milestone reached
        }
      }
    } catch (e) {
      AppLogger.warning('Error checking milestone: $e');
      // Don't throw - milestone checking is not critical
    }
  }

  void refresh() {
    _initializeSpinState();
  }
}

final dailySpinProvider = NotifierProvider<DailySpinNotifier, DailySpinState>(
  () => DailySpinNotifier(),
);
