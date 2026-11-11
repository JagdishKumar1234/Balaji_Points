import 'package:balaji_points/core/constants/app_constants.dart';
import 'package:balaji_points/core/firebase/app_firestore.dart';
import 'package:balaji_points/services/branch/current_branch_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Who a member contacts for their own branch: the store phone and the
/// branch admin's phone and email.
class BranchSupport {
  const BranchSupport({
    required this.branch,
    this.adminName = '',
    this.adminPhone = '',
    this.adminEmail = '',
  });

  final CurrentBranch branch;
  final String adminName;
  final String adminPhone;
  final String adminEmail;

  bool get hasAnyContact =>
      branch.phone.isNotEmpty || adminPhone.isNotEmpty || adminEmail.isNotEmpty;

  /// A phone as shown ("96006-09121", "+91 ...") made dialable.
  static String dialable(String phone) {
    final digits = phone.replaceAll(RegExp(r'[^0-9+]'), '');
    if (digits.startsWith('+')) return digits;
    if (digits.length == 10) return '+91$digits';
    return digits;
  }

  /// Picks the branch admin from the accounts in the branch: the linked one
  /// when the branch has `adminUid`, else the first `admin` account that is
  /// not the super admin's own number.
  static Map<String, dynamic>? pickAdmin(
    List<Map<String, dynamic>> users, {
    String? adminUid,
  }) {
    if (adminUid != null && adminUid.isNotEmpty) {
      for (final u in users) {
        if (u['_id'] == adminUid || u['uid'] == adminUid) return u;
      }
    }
    for (final u in users) {
      if ((u['role'] as String?)?.trim().toLowerCase() != 'admin') continue;
      final phone = (u['phone'] as String?)?.trim() ?? '';
      if (phone == AppConstants.superAdminPhone) continue;
      if (u['active'] == false || u['migratedToUid'] != null) continue;
      return u;
    }
    return null;
  }

  static BranchSupport fromAdmin(
    CurrentBranch branch,
    Map<String, dynamic>? admin,
  ) {
    if (admin == null) return BranchSupport(branch: branch);
    final name =
        '${(admin['firstName'] as String? ?? '').trim()} '
                '${(admin['lastName'] as String? ?? '').trim()}'
            .trim();
    return BranchSupport(
      branch: branch,
      adminName: name,
      adminPhone: (admin['phone'] as String? ?? '').trim(),
      adminEmail: (admin['email'] as String? ?? '').trim(),
    );
  }
}

/// Resolves the signed-in member's branch contacts.
class BranchSupportService {
  Stream<BranchSupport?> watch() async* {
    await for (final branch in CurrentBranchService().watch()) {
      if (branch == null) {
        yield null;
        continue;
      }
      final users = await appFirestore
          .collection('users')
          .where('branchId', isEqualTo: branch.id)
          .where('role', isEqualTo: 'admin')
          .limit(10)
          .get();
      final rows = users.docs.map((d) => {...d.data(), '_id': d.id}).toList();
      var admin = BranchSupport.pickAdmin(rows, adminUid: branch.adminUid);
      if (admin == null && branch.adminUid != null) {
        final linked = await appFirestore
            .collection('users')
            .doc(branch.adminUid!)
            .get();
        if (linked.exists) admin = linked.data();
      }
      yield BranchSupport.fromAdmin(branch, admin);
    }
  }
}

final branchSupportProvider = StreamProvider.autoDispose<BranchSupport?>(
  (ref) => BranchSupportService().watch(),
);
