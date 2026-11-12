import 'package:balaji_points/core/points/points_rate.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:balaji_points/core/constants/app_constants.dart';
import 'package:balaji_points/core/firebase/app_firestore.dart';

/// A selectable account role (carpenter, architect, custom roles…).
///
/// Roles live in the `roles` collection (doc id == [id]). The four built-in
/// roles work even before their documents exist; a stored document only
/// overrides their name / short form / active flag.
class AppRole {
  const AppRole({
    required this.id,
    required this.name,
    this.abbreviation = '',
    this.isActive = true,
    this.isBuiltIn = false,
    int? rupeesPerPoint,
  }) : _rupeesPerPoint = rupeesPerPoint;

  final String id;
  final String name;
  final String abbreviation;
  final bool isActive;
  final bool isBuiltIn;
  final int? _rupeesPerPoint;

  /// Rupees of approved purchases per point for this role (the built-in
  /// default when the role record sets none).
  int get rupeesPerPoint => _rupeesPerPoint ?? PointsRate.defaultFor(id);

  /// Carpenter is the core role of the rewards program and can never be
  /// removed from registration (enforced in Firestore rules as well).
  bool get isProtected => id == AppConstants.roleCarpenter;

  String get selectionLabel =>
      abbreviation.isEmpty ? name : '$name · $abbreviation';

  static const builtInIds = <String>[
    AppConstants.roleCarpenter,
    AppConstants.roleArchitect,
    AppConstants.roleEngineer,
    AppConstants.roleInteriorDesigner,
  ];

  static const defaults = <AppRole>[
    AppRole(id: AppConstants.roleCarpenter, name: 'Carpenter', isBuiltIn: true),
    AppRole(
      id: AppConstants.roleArchitect,
      name: 'Architect',
      abbreviation: 'Ar.',
      isBuiltIn: true,
    ),
    AppRole(
      id: AppConstants.roleEngineer,
      name: 'Engineer',
      abbreviation: 'Er.',
      isBuiltIn: true,
    ),
    AppRole(
      id: AppConstants.roleInteriorDesigner,
      name: 'Interior designer',
      isBuiltIn: true,
    ),
  ];

  static AppRole? builtInDefault(String id) {
    for (final role in defaults) {
      if (role.id == id) return role;
    }
    return null;
  }
}

/// Why a role write was refused. The UI maps each code to a translated
/// message; Firestore rules enforce the same constraints server-side.
enum RoleErrorCode { invalidName, reserved, builtInId, duplicate, protected }

class RoleException implements Exception {
  const RoleException(this.code);
  final RoleErrorCode code;

  @override
  String toString() => 'RoleException(${code.name})';
}

class RoleService {
  RoleService({FirebaseFirestore? firestore})
    : _firestore = firestore ?? appFirestore;

  final FirebaseFirestore _firestore;

  /// Limits shared with the Add role form and `firestore.rules`.
  static const nameMinLength = 2;
  static const nameMaxLength = 40;
  static const abbreviationMaxLength = 10;
  static const idMaxLength = 40;

  CollectionReference<Map<String, dynamic>> get _roles =>
      _firestore.collection('roles');

  // ── Reading ────────────────────────────────────────────────────────────────

  /// Live list of roles — every device updates as soon as a role is added,
  /// deleted or restored.
  Stream<List<AppRole>> watchRoles({bool includeInactive = true}) {
    return _roles.snapshots().map(
      (snapshot) => _merge(snapshot.docs, includeInactive: includeInactive),
    );
  }

  Future<List<AppRole>> listRoles({bool includeInactive = true}) async {
    final snapshot = await _roles.get();
    return _merge(snapshot.docs, includeInactive: includeInactive);
  }

  /// Merges stored role documents over the built-in defaults.
  List<AppRole> _merge(
    List<QueryDocumentSnapshot<Map<String, dynamic>>> docs, {
    required bool includeInactive,
  }) {
    final stored = {for (final doc in docs) doc.id: doc.data()};
    final rolesById = <String, AppRole>{};

    for (final builtIn in AppRole.defaults) {
      final data = stored.remove(builtIn.id);
      rolesById[builtIn.id] = data == null
          ? builtIn
          : AppRole(
              id: builtIn.id,
              name: _clean(data['name']) ?? builtIn.name,
              abbreviation: data['abbreviation'] is String
                  ? (data['abbreviation'] as String).trim()
                  : builtIn.abbreviation,
              // The protected role is always active, whatever the document.
              isActive: builtIn.isProtected || _isActive(data),
              isBuiltIn: true,
              rupeesPerPoint: PointsRate.sanitize(
                data['rupeesPerPoint'],
                fallback: builtIn.rupeesPerPoint,
              ),
            );
    }

    for (final entry in stored.entries) {
      final id = entry.key;
      final data = entry.value;
      if (_isReserved(id)) continue;
      final name = _clean(data['name']);
      if (name == null) continue;
      rolesById[id] = AppRole(
        id: id,
        name: name,
        abbreviation: _clean(data['abbreviation']) ?? '',
        isActive: _isActive(data),
        rupeesPerPoint: PointsRate.sanitize(
          data['rupeesPerPoint'],
          fallback: PointsRate.defaultRupeesPerPoint,
        ),
      );
    }

    final result = rolesById.values
        .where((role) => includeInactive || role.isActive)
        .toList();
    result.sort((a, b) {
      final aIndex = AppRole.builtInIds.indexOf(a.id);
      final bIndex = AppRole.builtInIds.indexOf(b.id);
      if (aIndex >= 0 && bIndex >= 0) return aIndex.compareTo(bIndex);
      if (aIndex >= 0) return -1;
      if (bIndex >= 0) return 1;
      return a.name.toLowerCase().compareTo(b.name.toLowerCase());
    });
    return result;
  }

  Future<List<AppRole>> listSignupRoles() async {
    try {
      return await listRoles(includeInactive: false);
    } catch (_) {
      // Keep account creation available with the four built-in roles if the
      // roles collection is temporarily unreachable.
      return AppRole.defaults;
    }
  }

  /// Mirrors `isActiveSignupRole` in firestore.rules — keep them in sync.
  Future<bool> isActiveSignupRole(String roleId) async {
    if (roleId.trim().isEmpty || _isReserved(roleId)) return false;
    final builtIn = AppRole.builtInDefault(roleId);
    try {
      final snapshot = await _roles.doc(roleId).get();
      if (!snapshot.exists) return builtIn != null;
      if (builtIn?.isProtected ?? false) return true;
      final data = snapshot.data()!;
      return data['roleId'] == roleId && data['isActive'] == true;
    } catch (_) {
      return builtIn != null;
    }
  }

  // ── Writing (super admin only — see firestore.rules /roles) ────────────────

  /// Creates a custom role in a transaction so two admins cannot create the
  /// same role ID at the same moment.
  /// Rates by role ID, cached for a few minutes; used wherever points are
  /// previewed or credited.
  static Map<String, int>? _rateCache;
  static DateTime? _rateCacheAt;

  static Map<String, int> ratesFrom(List<AppRole> roles) => {
    for (final r in roles) r.id: r.rupeesPerPoint,
  };

  /// Rupees per point for [roleId] (the role's default when unknown).
  Future<int> rateForRole(String? roleId) async {
    final id = (roleId ?? '').trim().toLowerCase();
    final stale =
        _rateCacheAt == null ||
        DateTime.now().difference(_rateCacheAt!) > const Duration(minutes: 5);
    if (_rateCache == null || stale) {
      try {
        _rateCache = ratesFrom(await listRoles());
        _rateCacheAt = DateTime.now();
      } catch (_) {
        // Offline or denied: keep any old cache, else role defaults.
      }
    }
    return _rateCache?[id] ?? PointsRate.defaultFor(id);
  }

  static void clearRateCache() {
    _rateCache = null;
    _rateCacheAt = null;
  }

  Future<AppRole> createRole({
    required String name,
    required String abbreviation,
    int rupeesPerPoint = PointsRate.defaultRupeesPerPoint,
  }) async {
    final cleanName = name.trim().replaceAll(RegExp(r'\s+'), ' ');
    final cleanAbbreviation = abbreviation.trim();
    final id = createRoleId(cleanName);
    if (cleanName.length < nameMinLength ||
        cleanName.length > nameMaxLength ||
        cleanAbbreviation.length > abbreviationMaxLength ||
        id.length < 2 ||
        id.length > idMaxLength) {
      throw const RoleException(RoleErrorCode.invalidName);
    }
    if (_isReserved(id)) throw const RoleException(RoleErrorCode.reserved);
    if (AppRole.builtInIds.contains(id)) {
      throw const RoleException(RoleErrorCode.builtInId);
    }

    if (rupeesPerPoint < PointsRate.minRupeesPerPoint ||
        rupeesPerPoint > PointsRate.maxRupeesPerPoint) {
      throw const RoleException(RoleErrorCode.invalidName);
    }
    final ref = _roles.doc(id);
    final role = AppRole(
      id: id,
      name: cleanName,
      abbreviation: cleanAbbreviation,
      rupeesPerPoint: rupeesPerPoint,
    );
    await _firestore.runTransaction((tx) async {
      final existing = await tx.get(ref);
      if (existing.exists) throw const RoleException(RoleErrorCode.duplicate);
      tx.set(ref, {
        'roleId': role.id,
        'name': role.name,
        'abbreviation': role.abbreviation,
        'isActive': true,
        'isBuiltIn': false,
        'rupeesPerPoint': role.rupeesPerPoint,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    });
    clearRateCache();
    return role;
  }

  /// Renames a role / changes its short form. The ID never changes (it is
  /// stored on user accounts); a Cloud Function copies the new name onto
  /// existing users' `roleName` / `roleAbbreviation`.
  Future<AppRole> updateRole(
    AppRole role, {
    required String name,
    required String abbreviation,
    int? rupeesPerPoint,
  }) async {
    final cleanName = name.trim().replaceAll(RegExp(r'\s+'), ' ');
    final cleanAbbreviation = abbreviation.trim();
    final rate = rupeesPerPoint ?? role.rupeesPerPoint;
    if (cleanName.length < nameMinLength ||
        cleanName.length > nameMaxLength ||
        cleanAbbreviation.length > abbreviationMaxLength ||
        rate < PointsRate.minRupeesPerPoint ||
        rate > PointsRate.maxRupeesPerPoint) {
      throw const RoleException(RoleErrorCode.invalidName);
    }
    final ref = _roles.doc(role.id);
    await _firestore.runTransaction((tx) async {
      final existing = await tx.get(ref);
      if (existing.exists) {
        tx.update(ref, {
          'name': cleanName,
          'abbreviation': cleanAbbreviation,
          'rupeesPerPoint': rate,
          'updatedAt': FieldValue.serverTimestamp(),
        });
      } else {
        // First edit of a built-in role creates its override document.
        tx.set(ref, {
          'roleId': role.id,
          'name': cleanName,
          'abbreviation': cleanAbbreviation,
          'isActive': role.isActive,
          'isBuiltIn': AppRole.builtInIds.contains(role.id),
          'rupeesPerPoint': rate,
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }
    });
    clearRateCache();
    return AppRole(
      id: role.id,
      name: cleanName,
      abbreviation: cleanAbbreviation,
      isActive: role.isActive,
      isBuiltIn: role.isBuiltIn,
      rupeesPerPoint: rate,
    );
  }

  /// Soft delete / restore. Role documents are never removed, so users who
  /// already hold a role keep a valid role ID.
  Future<void> setRoleActive(AppRole role, bool isActive) async {
    if (role.isProtected && !isActive) {
      throw const RoleException(RoleErrorCode.protected);
    }
    final ref = _roles.doc(role.id);
    await _firestore.runTransaction((tx) async {
      final existing = await tx.get(ref);
      if (existing.exists) {
        // Only the flag changes; roleId / isBuiltIn / createdAt stay as stored.
        tx.update(ref, {
          'isActive': isActive,
          'updatedAt': FieldValue.serverTimestamp(),
        });
      } else {
        // First change to a built-in role creates its override document.
        tx.set(ref, {
          'roleId': role.id,
          'name': role.name,
          'abbreviation': role.abbreviation,
          'rupeesPerPoint': role.rupeesPerPoint,
          'isActive': isActive,
          'isBuiltIn': AppRole.builtInIds.contains(role.id),
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }
    });
  }

  /// Lower-case, underscore-separated ASCII id (matches the rules regex
  /// `^[a-z0-9]+(_[a-z0-9]+)*$`). Non-Latin names produce an empty id.
  String createRoleId(String name) {
    return name
        .trim()
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]+'), '_')
        .replaceAll(RegExp(r'^_+|_+$'), '');
  }

  static bool _isReserved(String id) =>
      id == AppConstants.roleAdmin || id == AppConstants.roleSuperAdmin;

  static bool _isActive(Map<String, dynamic> data) => data['isActive'] != false;

  static String? _clean(Object? value) {
    if (value is! String) return null;
    final trimmed = value.trim();
    return trimmed.isEmpty ? null : trimmed;
  }
}
