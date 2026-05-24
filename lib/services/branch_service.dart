import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:balaji_points/core/logger.dart';

/// The fixed document ID for the seed branch.
const String kDefaultBranchId = 'erode_main';

class BranchService {
  static final BranchService _instance = BranchService._internal();
  factory BranchService() => _instance;
  BranchService._internal();

  final FirebaseFirestore _db = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _branches =>
      _db.collection('branches');

  // ── Seed ───────────────────────────────────────────────────────────────────

  static const String _seedName =
      'Sri Balaji Plywood and Hardware - E Road';

  /// Idempotent seed: creates the default branch doc if missing, or corrects
  /// the name if it was previously saved with a different value.
  Future<void> seedDefaultBranch() async {
    try {
      final ref = _branches.doc(kDefaultBranchId);
      final snap = await ref.get();
      if (!snap.exists) {
        await ref.set({
          'name': _seedName,
          'shortName': 'E Road Branch',
          'address': '150 VCTV Main Road, Erode',
          'phone': '96006-09121',
          'isActive': true,
          'createdAt': FieldValue.serverTimestamp(),
          'createdBy': 'system',
        });
        AppLogger.info('BranchService: seeded default branch erode_main');
      } else if (snap.data()?['name'] != _seedName) {
        // Correct the name if it was saved differently in a prior version.
        await ref.update({'name': _seedName});
        AppLogger.info('BranchService: updated erode_main branch name');
      }
    } catch (e) {
      AppLogger.error('BranchService.seedDefaultBranch', e);
    }
  }

  // ── Reads ──────────────────────────────────────────────────────────────────

  Stream<QuerySnapshot<Map<String, dynamic>>> watchAllBranches() =>
      _branches.orderBy('name').snapshots();

  Future<Map<String, dynamic>?> getBranch(String branchId) async {
    try {
      final snap = await _branches.doc(branchId).get();
      if (!snap.exists) return null;
      return {'id': snap.id, ...snap.data()!};
    } catch (e) {
      AppLogger.error('BranchService.getBranch', e);
      return null;
    }
  }

  Future<List<Map<String, dynamic>>> listActiveBranches() async {
    try {
      final snap = await _branches
          .where('isActive', isEqualTo: true)
          .orderBy('name')
          .get();
      return snap.docs.map((d) => {'id': d.id, ...d.data()}).toList();
    } catch (e) {
      AppLogger.error('BranchService.listActiveBranches', e);
      return [];
    }
  }

  // ── Writes (super admin only — enforced at app level) ──────────────────────

  Future<String?> createBranch({
    required String name,
    required String shortName,
    required String address,
    required String phone,
    required String createdBy,
  }) async {
    try {
      final ref = await _branches.add({
        'name': name,
        'shortName': shortName,
        'address': address,
        'phone': phone,
        'isActive': true,
        'createdAt': FieldValue.serverTimestamp(),
        'createdBy': createdBy,
      });
      AppLogger.info('BranchService: created branch ${ref.id}');
      return ref.id;
    } catch (e) {
      AppLogger.error('BranchService.createBranch', e);
      return null;
    }
  }

  Future<bool> updateBranch(
    String branchId, {
    String? name,
    String? shortName,
    String? address,
    String? phone,
    bool? isActive,
  }) async {
    try {
      final data = <String, dynamic>{};
      if (name != null) data['name'] = name;
      if (shortName != null) data['shortName'] = shortName;
      if (address != null) data['address'] = address;
      if (phone != null) data['phone'] = phone;
      if (isActive != null) data['isActive'] = isActive;
      await _branches.doc(branchId).update(data);
      return true;
    } catch (e) {
      AppLogger.error('BranchService.updateBranch', e);
      return false;
    }
  }

  // ── Super admin: promote user roles ──────────────────────────────────────

  Future<bool> assignAdminToBranch({
    required String userId,
    required String branchId,
  }) async {
    try {
      await _db.collection('users').doc(userId).update({
        'role': 'admin',
        'branchId': branchId,
      });
      AppLogger.info('BranchService: assigned $userId as admin for $branchId');
      return true;
    } catch (e) {
      AppLogger.error('BranchService.assignAdminToBranch', e);
      return false;
    }
  }

}
