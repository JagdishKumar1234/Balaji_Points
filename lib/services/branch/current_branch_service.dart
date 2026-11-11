import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:balaji_points/core/constants/app_constants.dart';
import 'package:balaji_points/core/firebase/app_firestore.dart';
import 'package:balaji_points/services/auth/session_service.dart';

/// The branch the signed-in user belongs to.
class CurrentBranch {
  const CurrentBranch({
    required this.id,
    required this.name,
    required this.shortName,
    required this.code,
    this.address = '',
    this.phone = '',
    this.adminUid,
  });

  final String id;

  /// Full branch name, e.g. "<store name> - Erode".
  final String name;
  final String shortName;
  final String code;

  /// Store address and phone, as entered by the super admin (may be empty).
  final String address;
  final String phone;

  /// The branch admin's account, when linked.
  final String? adminUid;
}

/// Resolves and watches the signed-in user's branch.
///
/// Super admins have no branch (they manage all of them) → `null`.
class CurrentBranchService {
  CurrentBranchService({SessionService? session})
    : _session = session ?? SessionService();

  final SessionService _session;

  /// Branch that branch-admin screens are scoped to. Set by the admin shell
  /// once resolved; read by [BranchScopedQuery.forAdminBranch].
  static String? _adminBranchId;
  static String? get adminBranchId => _adminBranchId;
  static void setAdminBranch(String? branchId) => _adminBranchId = branchId;

  Future<bool> isSuperAdmin() async =>
      (await _session.getUserRole())?.toLowerCase() ==
      AppConstants.roleSuperAdmin;

  /// The signed-in user's profile is authoritative; the local session is a
  /// fallback for legacy profiles that do not contain a branch assignment.
  Future<String?> resolveBranchId() async {
    final userId = (await _session.getUserId())?.trim();
    if (userId != null && userId.isNotEmpty) {
      final user = await appFirestore.collection('users').doc(userId).get();
      final id = (user.data()?['branchId'] as String?)?.trim();
      if (id != null && id.isNotEmpty) return id;
    }
    final phone = (await _session.getPhoneNumber())?.trim();
    if (phone != null && phone.isNotEmpty) {
      final users = await appFirestore
          .collection('users')
          .where('phone', isEqualTo: phone)
          .limit(1)
          .get();
      if (users.docs.isNotEmpty) {
        final id = (users.docs.first.data()['branchId'] as String?)?.trim();
        if (id != null && id.isNotEmpty) return id;
      }
    }

    final stored = (await _session.getBranchId())?.trim();
    if (stored != null && stored.isNotEmpty) return stored;
    return null;
  }

  /// Live branch details (name edits by the super admin show up instantly).
  Stream<CurrentBranch?> watch() async* {
    if (await isSuperAdmin()) {
      yield null;
      return;
    }
    final branchId = await resolveBranchId();
    if (branchId == null) {
      yield null;
      return;
    }
    yield* appFirestore.collection('branches').doc(branchId).snapshots().map((
      snapshot,
    ) {
      final data = snapshot.data() ?? const <String, dynamic>{};
      final name = (data['name'] as String?)?.trim();
      final shortName = (data['shortName'] as String?)?.trim();
      return CurrentBranch(
        id: branchId,
        name: (name == null || name.isEmpty) ? branchId : name,
        shortName: (shortName == null || shortName.isEmpty)
            ? ((name == null || name.isEmpty) ? branchId : name)
            : shortName,
        code: (data['branchCode'] as String?) ?? branchId,
        address: (data['address'] as String?)?.trim() ?? '',
        phone: (data['phone'] as String?)?.trim() ?? '',
        adminUid: (data['adminUid'] as String?)?.trim(),
      );
    });
  }
}

/// The signed-in user's branch, or `null` for super admins / unknown.
final currentBranchProvider = StreamProvider.autoDispose<CurrentBranch?>(
  (ref) => CurrentBranchService().watch(),
);

/// Branch admins only see their own branch's data.
extension BranchScopedQuery on Query<Map<String, dynamic>> {
  /// Adds `branchId == <admin's branch>`. Fails closed: if the branch is not
  /// known yet, matches nothing instead of every branch.
  Query<Map<String, dynamic>> forAdminBranch() => where(
    'branchId',
    isEqualTo: CurrentBranchService.adminBranchId ?? '__no_branch__',
  );
}

/// For collections where older documents have no `branchId` (e.g.
/// notification logs): keep this admin's branch plus legacy documents.
extension AdminBranchDocs<T extends Object?>
    on Iterable<QueryDocumentSnapshot<T>> {
  List<QueryDocumentSnapshot<T>> inAdminBranch() {
    final mine = CurrentBranchService.adminBranchId;
    return where((doc) {
      final data = doc.data();
      final branchId = data is Map ? data['branchId'] : null;
      return branchId == null || branchId == '' || branchId == mine;
    }).toList();
  }
}
