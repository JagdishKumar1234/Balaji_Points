import 'package:balaji_points/core/constants/app_constants.dart';

/// Members compete (rankings, daily spin) only inside their own group, in
/// their own branch. The groups are a fixed role mapping, never worked out
/// from points rates: the super admin can edit rates, and grouping by rate
/// would silently split a board when one role's rate changed.
enum LeaderboardGroup {
  /// Carpenters and interior designers (₹1,000 = 1 pt by default).
  trade,

  /// Architects and engineers (₹5,000 = 1 pt by default).
  professional;

  /// Stored on winner records (`group` field) and in winner document IDs.
  String get id => name;

  static LeaderboardGroup? fromId(String? id) {
    for (final g in values) {
      if (g.id == id) return g;
    }
    return null;
  }
}

class LeaderboardGroups {
  LeaderboardGroups._();

  static const Set<String> trade = {
    AppConstants.roleCarpenter,
    AppConstants.roleInteriorDesigner,
  };

  static const Set<String> professional = {
    AppConstants.roleArchitect,
    AppConstants.roleEngineer,
  };

  /// The group for [role], or null for admins and unknown roles.
  /// Old accounts with no role saved count as carpenters.
  static LeaderboardGroup? of(String? role) {
    final id = role?.trim().toLowerCase() ?? '';
    if (id.isEmpty || trade.contains(id)) return LeaderboardGroup.trade;
    if (professional.contains(id)) return LeaderboardGroup.professional;
    return null;
  }

  static Set<String> rolesOf(LeaderboardGroup group) =>
      group == LeaderboardGroup.trade ? trade : professional;
}

/// Account approval states for member accounts (see account approval plan).
class AccountApproval {
  AccountApproval._();

  static const String fieldVerified = 'profile_verified';
  static const String fieldStatus = 'approvalStatus';

  static const String pending = 'pending';
  static const String approved = 'approved';
  static const String rejected = 'rejected';

  /// Whether a member account may sign in and appear in lists. A missing
  /// `profile_verified` counts as not verified: every live account is marked
  /// verified by the migration, so only new sign-ups lack it.
  static bool isVerified(Map<String, dynamic>? data) =>
      data?[fieldVerified] == true;

  /// `pending`, `approved` or `rejected` for a member account.
  static String statusOf(Map<String, dynamic>? data) {
    if (isVerified(data)) return approved;
    final s = (data?[fieldStatus] as String? ?? '').trim();
    return s == rejected ? rejected : pending;
  }
}

class MemberFilter {
  MemberFilter._();

  /// An approved, non-deleted member in one of the two groups.
  static bool isActiveMember(Map<String, dynamic> data) {
    if (LeaderboardGroups.of(data['role'] as String?) == null) return false;
    if (data['status'] == 'deleted') return false;
    return AccountApproval.isVerified(data);
  }

  /// [isActiveMember] and in [group].
  static bool isActiveMemberOf(
    Map<String, dynamic> data,
    LeaderboardGroup group,
  ) =>
      isActiveMember(data) &&
      LeaderboardGroups.of(data['role'] as String?) == group;
}

/// Admin list filter: everyone, one group, or one role.
/// Stored as a short id: `all`, `group:trade`, `role:architect`, ...
class MemberRoleFilter {
  const MemberRoleFilter._(this.id);

  final String id;

  static const all = MemberRoleFilter._('all');
  static MemberRoleFilter group(LeaderboardGroup g) =>
      MemberRoleFilter._('group:${g.id}');
  static MemberRoleFilter role(String roleId) =>
      MemberRoleFilter._('role:$roleId');

  static MemberRoleFilter fromId(String? id) =>
      id == null || id.isEmpty ? all : MemberRoleFilter._(id);

  /// Dropdown order: All, then each group followed by its roles.
  static List<MemberRoleFilter> get options => [
    all,
    for (final g in LeaderboardGroup.values) ...[
      group(g),
      for (final r in LeaderboardGroups.rolesOf(g)) role(r),
    ],
  ];

  LeaderboardGroup? get groupValue => id.startsWith('group:')
      ? LeaderboardGroup.fromId(id.substring(6))
      : null;

  String? get roleValue => id.startsWith('role:') ? id.substring(5) : null;

  /// Whether a member with [role] passes. Old accounts with no role are
  /// carpenters.
  bool matches(String? role) {
    if (id == 'all') return true;
    final g = groupValue;
    if (g != null) return LeaderboardGroups.of(role) == g;
    final wanted = roleValue;
    if (wanted == null) return true;
    final r = (role ?? '').trim().toLowerCase();
    return (r.isEmpty ? AppConstants.roleCarpenter : r) == wanted;
  }

  @override
  bool operator ==(Object other) => other is MemberRoleFilter && other.id == id;

  @override
  int get hashCode => id.hashCode;
}
