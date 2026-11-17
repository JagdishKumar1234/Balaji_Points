import 'package:cloud_functions/cloud_functions.dart';

import 'package:balaji_points/core/constants/app_constants.dart';

/// Result of one send: members it went to, and phones the push reached.
class RoleBroadcastResult {
  const RoleBroadcastResult({required this.recipients, required this.pushed});
  final int recipients;
  final int pushed;
}

/// Sends an admin's notification to chosen member roles of one branch
/// (Cloud Function `sendRoleBroadcast`): a push to every phone, and one
/// entry in each member's Notifications list.
class RoleBroadcastService {
  RoleBroadcastService({FirebaseFunctions? functions})
    : _functions =
          functions ?? FirebaseFunctions.instanceFor(region: 'us-central1');

  final FirebaseFunctions _functions;

  /// The four member roles, in the order the admin screen shows them.
  static const memberRoles = [
    AppConstants.roleCarpenter,
    AppConstants.roleInteriorDesigner,
    AppConstants.roleArchitect,
    AppConstants.roleEngineer,
  ];

  static const maxTitle = 80;
  static const maxBody = 500;

  /// The member role of a profile; older accounts with no role are
  /// carpenters. Null for admins and unknown roles.
  static String? memberRoleOf(String? role) {
    final id = role?.trim().toLowerCase() ?? '';
    if (id.isEmpty) return AppConstants.roleCarpenter;
    return memberRoles.contains(id) ? id : null;
  }

  Future<RoleBroadcastResult> send({
    required String branchId,
    required Set<String> roles,
    required String category,
    required String title,
    required String body,
  }) async {
    final res = await _functions.httpsCallable('sendRoleBroadcast').call({
      'branchId': branchId,
      'roles': roles.toList(),
      'category': category,
      'title': title.trim(),
      'body': body.trim(),
    });
    final data = Map<String, dynamic>.from(res.data as Map);
    return RoleBroadcastResult(
      recipients: (data['recipients'] as num?)?.toInt() ?? 0,
      pushed: (data['pushed'] as num?)?.toInt() ?? 0,
    );
  }
}
