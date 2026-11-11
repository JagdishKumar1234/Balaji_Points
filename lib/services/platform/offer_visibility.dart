/// Which offers each role sees. An offer with a branch belongs to that branch;
/// an offer with no branch (made by the super admin) is for every branch.
class OfferVisibility {
  OfferVisibility._();

  static String _branchOf(Map<String, dynamic>? data) =>
      (data?['branchId'] as String? ?? '').trim();

  /// Members see their own branch's offers and the all-branch ones.
  static bool memberCanSee(Map<String, dynamic>? data, String? myBranchId) {
    if (data == null) return false;
    final branch = _branchOf(data);
    return branch.isEmpty || (myBranchId != null && branch == myBranchId);
  }

  /// A branch admin manages only their own branch's offers, never another
  /// branch's and never the super admin's all-branch ones.
  static bool adminCanSee(Map<String, dynamic>? data, String? adminBranchId) {
    if (data == null || adminBranchId == null || adminBranchId.isEmpty) {
      return false;
    }
    return _branchOf(data) == adminBranchId;
  }
}
