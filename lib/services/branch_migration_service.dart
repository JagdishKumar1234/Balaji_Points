import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:balaji_points/core/logger.dart';
import 'package:balaji_points/services/branch_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// One-time migration: stamps branchId = 'erode_main' on every document in
/// users, bills, orders, points_history, user_points that lacks a branchId.
///
/// Uses SharedPreferences to record completion so it never runs twice.
class BranchMigrationService {
  static final BranchMigrationService _i = BranchMigrationService._();
  factory BranchMigrationService() => _i;
  BranchMigrationService._();

  static const String _prefKey = 'branch_migration_v1_done';
  static const String _branchId = kDefaultBranchId;
  static const int _batchSize = 400;

  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Future<void> runIfNeeded() async {
    final prefs = await SharedPreferences.getInstance();
    if (prefs.getBool(_prefKey) == true) return;

    AppLogger.info('BranchMigration: starting backfill to $_branchId');
    try {
      await Future.wait([
        _backfill('users'),
        _backfill('bills'),
        _backfill('orders'),
        _backfill('points_history'),
        _backfill('user_points'),
      ]);
      await prefs.setBool(_prefKey, true);
      AppLogger.info('BranchMigration: complete');
    } catch (e) {
      AppLogger.error('BranchMigration: failed', e);
      // Do NOT mark done — retry on next launch.
    }
  }

  Future<void> _backfill(String collection) async {
    // Only touch docs that have no branchId field yet.
    // Firestore doesn't support "field does not exist" queries directly,
    // so we read in pages and skip docs that already have branchId.
    DocumentSnapshot? lastDoc;
    int updated = 0;

    while (true) {
      Query<Map<String, dynamic>> query =
          _db.collection(collection).limit(_batchSize);
      if (lastDoc != null) query = query.startAfterDocument(lastDoc);

      final snap = await query.get();
      if (snap.docs.isEmpty) break;

      final batch = _db.batch();
      int batchCount = 0;

      for (final doc in snap.docs) {
        final data = doc.data();
        if (data['branchId'] == null) {
          batch.update(doc.reference, {'branchId': _branchId});
          batchCount++;
          updated++;
        }
      }

      if (batchCount > 0) await batch.commit();
      lastDoc = snap.docs.last;

      if (snap.docs.length < _batchSize) break;
    }

    AppLogger.info('BranchMigration: $collection → $updated docs updated');
  }
}
