import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:balaji_points/services/branch/branch_celebration_service.dart';

final branchCelebrationEnabledProvider = StreamProvider<bool>((ref) {
  return BranchCelebrationService().watchCurrentBranchEnabled();
});

/// Loads the full branch carpenter leaderboard before the Diwali dialog opens.
final branchCelebrationLeaderboardProvider = FutureProvider.autoDispose
    .family<List<BranchCelebrationEntry>, String>((ref, branchId) {
      return BranchCelebrationService().loadBranchCarpenters(branchId);
    });
