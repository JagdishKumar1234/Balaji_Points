import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:balaji_points/core/logger.dart';
import 'package:balaji_points/core/firebase/app_firestore.dart';

/// The fixed document ID for the seed branch.
const String kDefaultBranchId = 'erode_main';

class BranchService {
  static final BranchService _instance = BranchService._internal();
  factory BranchService() => _instance;
  BranchService._internal();

  FirebaseFirestore get _db => appFirestore;

  CollectionReference<Map<String, dynamic>> get _branches =>
      _db.collection('branches');

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

  /// Checks whether a branch already has an assigned Admin (Constraint: Only 1 Admin per branch).
  Future<bool> hasAdmin(String branchId) async {
    try {
      final snap = await _db
          .collection('users')
          .where('branchId', isEqualTo: branchId)
          .where('role', isEqualTo: 'admin')
          .limit(1)
          .get();
      return snap.docs.isNotEmpty;
    } catch (e) {
      AppLogger.error('BranchService.hasAdmin', e);
      return false;
    }
  }

  Future<List<Map<String, dynamic>>> listActiveBranches() async {
    try {
      final snap = await _branches
          .where('isActive', isEqualTo: true)
          .orderBy('name')
          .get();
      return snap.docs
          .map(
            (d) => {
              ...d.data(),
              'id': d.id,
              'branchCode': d.data()['branchCode'] as String? ?? d.id,
            },
          )
          .toList();
    } catch (e) {
      // Index may still be building — fall back to full fetch + in-memory filter
      AppLogger.error('BranchService.listActiveBranches (indexed)', e);
      try {
        final snap = await _branches.get();
        final results = snap.docs
            .where((d) => d.data()['isActive'] == true)
            .map(
              (d) => {
                ...d.data(),
                'id': d.id,
                'branchCode': d.data()['branchCode'] as String? ?? d.id,
              },
            )
            .toList();
        results.sort(
          (a, b) => (a['name'] as String).compareTo(b['name'] as String),
        );
        return results;
      } catch (e2) {
        AppLogger.error('BranchService.listActiveBranches (fallback)', e2);
        return [];
      }
    }
  }

  // ── Writes (super admin only — enforced at app level) ──────────────────────

  Future<String?> createBranch({
    required String name,
    required String shortName,
    required String branchCode,
    required String address,
    required String phone,
    required String createdBy,
    String mapsUrl = '',
  }) async {
    try {
      final duplicate = await _branches
          .where('name', isEqualTo: name.trim())
          .limit(1)
          .get();
      if (duplicate.docs.isNotEmpty) {
        AppLogger.warning(
          'BranchService: branch already exists: ${name.trim()}',
        );
        return null;
      }

      final normalizedCode = branchCode.trim().toUpperCase();
      final duplicateCode = await _branches
          .where('branchCode', isEqualTo: normalizedCode)
          .limit(1)
          .get();
      if (duplicateCode.docs.isNotEmpty) {
        AppLogger.warning('BranchService: branch code already exists');
        return null;
      }

      final ref = await _branches.add({
        'name': name,
        'shortName': shortName,
        'branchCode': normalizedCode,
        'diwaliCelebrationEnabled': false,
        'address': address,
        'phone': phone,
        if (mapsUrl.trim().isNotEmpty) 'mapsUrl': mapsUrl.trim(),
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
    String? mapsUrl,
    bool? isActive,
    bool? diwaliCelebrationEnabled,
  }) async {
    try {
      final data = <String, dynamic>{};
      if (name != null) data['name'] = name;
      if (shortName != null) data['shortName'] = shortName;
      if (address != null) data['address'] = address;
      if (phone != null) data['phone'] = phone;
      if (mapsUrl != null) data['mapsUrl'] = mapsUrl.trim();
      if (isActive != null) data['isActive'] = isActive;
      if (diwaliCelebrationEnabled != null) {
        data['diwaliCelebrationEnabled'] = diwaliCelebrationEnabled;
      }
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
