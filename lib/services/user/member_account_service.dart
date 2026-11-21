import 'package:cloud_functions/cloud_functions.dart';

/// Admin actions on a member account that must run on the server.
class MemberAccountService {
  MemberAccountService({FirebaseFunctions? functions})
    : _functionsOverride = functions;

  final FirebaseFunctions? _functionsOverride;

  FirebaseFunctions get _functions =>
      _functionsOverride ??
      FirebaseFunctions.instanceFor(region: 'us-central1');

  /// Permanently deletes the member `users/{userId}` with their points,
  /// history, bills, offer redemptions and sign-in. Only the admin of the
  /// member's branch (or the super admin) may do this; the server checks.
  Future<void> deleteMember(String userId) async {
    await _functions
        .httpsCallable(
          'deleteMemberAccount',
          options: HttpsCallableOptions(timeout: const Duration(minutes: 2)),
        )
        .call({'userId': userId});
  }

  /// Moves the member `users/{userId}` to [branchId] and/or [role] (one of
  /// the four member roles). A new role recalculates every bill at that
  /// role's rate; a new branch moves points, history and bills with the
  /// member. Only the member's own branch admin may do this (not the super
  /// admin); the server checks.
  Future<MemberChangeResult> changeBranchRole({
    required String userId,
    required String branchId,
    required String role,
  }) async {
    final result = await _functions
        .httpsCallable(
          'changeMemberBranchRole',
          options: HttpsCallableOptions(timeout: const Duration(minutes: 2)),
        )
        .call({'userId': userId, 'branchId': branchId, 'role': role});
    return MemberChangeResult.fromMap(
      Map<String, dynamic>.from(result.data as Map? ?? const {}),
    );
  }

  /// A short, readable reason for a failed call.
  static String errorText(Object e) {
    if (e is FirebaseFunctionsException) {
      return e.message?.trim().isNotEmpty == true ? e.message! : e.code;
    }
    return '$e';
  }
}

/// What `changeMemberBranchRole` changed.
class MemberChangeResult {
  const MemberChangeResult({
    required this.branchChanged,
    required this.roleChanged,
    required this.billsRecalculated,
    this.totalPoints,
  });

  factory MemberChangeResult.fromMap(Map<String, dynamic> m) =>
      MemberChangeResult(
        branchChanged: m['branchChanged'] == true,
        roleChanged: m['roleChanged'] == true,
        billsRecalculated: (m['billsRecalculated'] as num?)?.toInt() ?? 0,
        totalPoints: (m['totalPoints'] as num?)?.toDouble(),
      );

  final bool branchChanged;
  final bool roleChanged;
  final int billsRecalculated;

  /// New total when the role changed (points recalculated), else null.
  final double? totalPoints;
}
