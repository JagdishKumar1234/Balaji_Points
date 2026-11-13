import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';

import 'package:balaji_points/core/constants/app_constants.dart';
import 'package:balaji_points/core/firebase/app_firestore.dart';
import 'package:balaji_points/core/points/leaderboard_group.dart';

/// Why a member may not sign in yet, with who to contact.
class AccountGate {
  const AccountGate({
    required this.status,
    this.branchName = '',
    this.branchPhone = '',
    this.rejectReason = '',
  });

  /// [AccountApproval.pending] or [AccountApproval.rejected].
  final String status;
  final String branchName;
  final String branchPhone;
  final String rejectReason;

  bool get isRejected => status == AccountApproval.rejected;
}

/// What happens when someone tries to register a phone number.
enum PhoneSignupCheck {
  /// Nobody has this number: sign-up may continue.
  free,

  /// Same branch, still waiting for approval.
  pendingSameBranch,

  /// Same branch, rejected by the admin.
  rejectedSameBranch,

  /// Same branch, an approved account already exists.
  approvedSameBranch,

  /// Registered with another branch (never named to the user).
  otherBranch,
}

class PhoneSignupResult {
  const PhoneSignupResult(
    this.check, {
    this.branchName = '',
    this.branchPhone = '',
  });

  final PhoneSignupCheck check;
  final String branchName;
  final String branchPhone;

  bool get isFree => check == PhoneSignupCheck.free;
}

/// One account request on the admin Requests screen.
class AccountRequest {
  const AccountRequest({required this.id, required this.data});

  final String id;
  final Map<String, dynamic> data;

  String get status => AccountApproval.statusOf(data);
  String get role => (data['role'] as String? ?? '').trim().toLowerCase();
  String get phone => (data['phone'] as String? ?? '').trim();
  String get branchId => (data['branchId'] as String? ?? '').trim();

  String get name {
    final n =
        '${(data['firstName'] as String? ?? '').trim()} '
                '${(data['lastName'] as String? ?? '').trim()}'
            .trim();
    if (n.isNotEmpty) return n;
    return (data['displayName'] as String? ?? '').trim();
  }

  DateTime? get requestedAt {
    final t = data['approvalRequestedAt'] ?? data['createdAt'];
    return t is Timestamp ? t.toDate() : null;
  }
}

/// New-account approval: sign-in gate, duplicate-phone check at sign-up,
/// and the admin review actions.
class AccountApprovalService {
  AccountApprovalService({
    FirebaseFirestore? firestore,
    FirebaseFunctions? functions,
  }) : _firestore = firestore ?? appFirestore,
       _functionsOverride = functions;

  final FirebaseFirestore _firestore;
  final FirebaseFunctions? _functionsOverride;

  FirebaseFunctions get _functions =>
      _functionsOverride ??
      FirebaseFunctions.instanceFor(region: 'us-central1');

  static String normalizePhone(String phone) {
    final digits = phone.replaceAll(RegExp(r'[^0-9]'), '');
    return digits.length > 10 ? digits.substring(digits.length - 10) : digits;
  }

  /// Null when [profile] may sign in. Admins and the super admin are never
  /// blocked; member accounts need `profile_verified == true`.
  Future<AccountGate?> gateFor(Map<String, dynamic>? profile) async {
    if (profile == null) return null;
    final role = (profile['role'] as String? ?? profile['roleId'] as String?)
        ?.trim()
        .toLowerCase();
    if (!AppConstants.isMemberRole(role)) return null;
    if (AccountApproval.isVerified(profile)) return null;
    final branch = await _branchContact(profile['branchId'] as String?);
    return AccountGate(
      status: AccountApproval.statusOf(profile),
      branchName: branch.$1,
      branchPhone: branch.$2,
      rejectReason: (profile['rejectReason'] as String? ?? '').trim(),
    );
  }

  /// The gate for a saved session (app start). Reads the member's own
  /// record; if it cannot be read (offline), the member is let in rather
  /// than locked out.
  Future<AccountGate?> gateForSession({String? userId, String? phone}) async {
    try {
      Map<String, dynamic>? profile;
      final id = userId?.trim() ?? '';
      if (id.isNotEmpty) {
        profile = (await _firestore.collection('users').doc(id).get()).data();
      }
      final p = normalizePhone(phone ?? '');
      if (profile == null && p.length == 10) {
        final q = await _firestore
            .collection('users')
            .where('phone', isEqualTo: p)
            .limit(1)
            .get();
        if (q.docs.isNotEmpty) profile = q.docs.first.data();
      }
      return gateFor(profile);
    } catch (_) {
      return null;
    }
  }

  /// Run before any profile is written at sign-up. [branchId] is the branch
  /// being registered with; [selfId] is the signing-up user's own uid (a
  /// half-finished Google profile is not a duplicate of itself).
  Future<PhoneSignupResult> checkPhoneForSignup(
    String phone, {
    required String branchId,
    String? selfId,
  }) async {
    final p = normalizePhone(phone);
    final found = <QueryDocumentSnapshot<Map<String, dynamic>>>[];
    for (final value in {p, '+91$p'}) {
      for (final field in ['phone', 'phoneNumber']) {
        final q = await _firestore
            .collection('users')
            .where(field, isEqualTo: value)
            .limit(3)
            .get();
        found.addAll(q.docs.where((d) => d.id != selfId));
      }
    }
    if (found.isEmpty) {
      final byId = await _firestore.collection('users').doc(p).get();
      if (byId.exists && byId.id != selfId) {
        return _resultFor(byId.data()!, branchId);
      }
      return const PhoneSignupResult(PhoneSignupCheck.free);
    }
    // Prefer a record in the same branch, if there is one.
    final same = found.where(
      (d) => (d.data()['branchId'] as String? ?? '').trim() == branchId,
    );
    return _resultFor(
      (same.isNotEmpty ? same.first : found.first).data(),
      branchId,
    );
  }

  Future<PhoneSignupResult> _resultFor(
    Map<String, dynamic> existing,
    String branchId,
  ) async {
    final theirs = (existing['branchId'] as String? ?? '').trim();
    if (theirs.isEmpty || theirs != branchId) {
      return const PhoneSignupResult(PhoneSignupCheck.otherBranch);
    }
    final contact = await _branchContact(theirs);
    final role = (existing['role'] as String?)?.trim().toLowerCase();
    final check = !AppConstants.isMemberRole(role)
        ? PhoneSignupCheck.approvedSameBranch
        : switch (AccountApproval.statusOf(existing)) {
            AccountApproval.approved => PhoneSignupCheck.approvedSameBranch,
            AccountApproval.rejected => PhoneSignupCheck.rejectedSameBranch,
            _ => PhoneSignupCheck.pendingSameBranch,
          };
    return PhoneSignupResult(
      check,
      branchName: contact.$1,
      branchPhone: contact.$2,
    );
  }

  /// The branch's display name (its id when it has none).
  Future<String> branchName(String branchId) async =>
      (await _branchContact(branchId)).$1;

  /// (branch name, branch phone).
  Future<(String, String)> _branchContact(String? branchId) async {
    final id = branchId?.trim() ?? '';
    if (id.isEmpty) return ('', '');
    try {
      final b = (await _firestore.collection('branches').doc(id).get()).data();
      return (
        (b?['name'] as String? ?? id).trim(),
        (b?['phone'] as String? ?? '').trim(),
      );
    } catch (_) {
      return (id, '');
    }
  }

  /// Fields a self sign-up writes on its new profile.
  static Map<String, dynamic> pendingFields() => {
    AccountApproval.fieldVerified: false,
    AccountApproval.fieldStatus: AccountApproval.pending,
    'approvalRequestedAt': FieldValue.serverTimestamp(),
  };

  /// Member sign-ups of [branchId] that are not approved, newest first.
  Stream<List<AccountRequest>> watchRequests(String? branchId) {
    final id = branchId?.trim() ?? '';
    if (id.isEmpty) return Stream.value(const []);
    return _firestore
        .collection('users')
        .where('branchId', isEqualTo: id)
        .snapshots()
        .map((snap) {
          final list = <AccountRequest>[];
          for (final doc in snap.docs) {
            final d = doc.data();
            if ((d['branchId'] as String? ?? '').trim() != id) continue;
            if (LeaderboardGroups.of(d['role'] as String?) == null) continue;
            if (d['status'] == 'deleted') continue;
            if (AccountApproval.isVerified(d)) continue;
            list.add(AccountRequest(id: doc.id, data: d));
          }
          list.sort((a, b) {
            final ta = a.requestedAt ?? DateTime(2000);
            final tb = b.requestedAt ?? DateTime(2000);
            return tb.compareTo(ta);
          });
          return list;
        });
  }

  /// Approves or rejects a member sign-up (checked again on the server:
  /// only the admin of the member's own branch; never the super admin).
  Future<void> review({
    required String userId,
    required bool approve,
    String? reason,
  }) async {
    await _functions.httpsCallable('reviewMemberAccount').call({
      'userId': userId,
      'action': approve ? 'approve' : 'reject',
      if (reason != null && reason.trim().isNotEmpty) 'reason': reason.trim(),
    });
  }
}
