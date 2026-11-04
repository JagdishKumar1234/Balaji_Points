import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:balaji_points/services/branch/branch_celebration_service.dart';

/// Whether the Diwali popup has been shown since this user logged in. It lives
/// here because the home screen is rebuilt every time the user returns to it.
class CelebrationPopupShown extends Notifier<bool> {
  @override
  bool build() => false;

  void mark(bool shown) => state = shown;
}

final celebrationPopupShownProvider =
    NotifierProvider<CelebrationPopupShown, bool>(CelebrationPopupShown.new);

final branchCelebrationEnabledProvider = StreamProvider<bool>((ref) {
  return BranchCelebrationService().watchCurrentBranchEnabled();
});

/// Loads the logged-in carpenter's prize and the top 3 before the Diwali dialog
/// opens.
final branchCelebrationSummaryProvider = FutureProvider.autoDispose
    .family<BranchCelebrationSummary, String>((ref, branchId) {
      return BranchCelebrationService().loadCelebrationSummary(branchId);
    });
