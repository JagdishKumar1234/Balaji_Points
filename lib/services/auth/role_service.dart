import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:balaji_points/core/constants/app_constants.dart';

class AppRole {
  const AppRole({
    required this.id,
    required this.name,
    this.abbreviation = '',
    this.isActive = true,
    this.isBuiltIn = false,
  });

  final String id;
  final String name;
  final String abbreviation;
  final bool isActive;
  final bool isBuiltIn;

  String get selectionLabel =>
      abbreviation.isEmpty ? name : '$name · $abbreviation';

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
}

class RoleService {
  RoleService({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _roles =>
      _firestore.collection('roles');

  Future<List<AppRole>> listRoles({bool includeInactive = true}) async {
    final snapshot = await _roles.get();
    final stored = {for (final doc in snapshot.docs) doc.id: doc.data()};
    final rolesById = <String, AppRole>{};

    for (final builtIn in AppRole.defaults) {
      final data = stored.remove(builtIn.id);
      rolesById[builtIn.id] = data == null
          ? builtIn
          : AppRole(
              id: builtIn.id,
              name: data['name'] as String? ?? builtIn.name,
              abbreviation:
                  data['abbreviation'] as String? ?? builtIn.abbreviation,
              isActive: data['isActive'] as bool? ?? true,
              isBuiltIn: true,
            );
    }

    for (final entry in stored.entries) {
      final data = entry.value;
      final id = entry.key;
      if (id == AppConstants.roleAdmin ||
          id == AppConstants.roleSuperAdmin ||
          data['isBuiltIn'] == true) {
        continue;
      }
      final name = (data['name'] as String? ?? '').trim();
      if (name.isEmpty) continue;
      rolesById[id] = AppRole(
        id: id,
        name: name,
        abbreviation: (data['abbreviation'] as String? ?? '').trim(),
        isActive: data['isActive'] as bool? ?? true,
      );
    }

    final result = rolesById.values
        .where((role) => includeInactive || role.isActive)
        .toList();
    result.sort((a, b) {
      final aIndex = AppRole.defaults.indexWhere((role) => role.id == a.id);
      final bIndex = AppRole.defaults.indexWhere((role) => role.id == b.id);
      if (aIndex >= 0 && bIndex >= 0) return aIndex.compareTo(bIndex);
      if (aIndex >= 0) return -1;
      if (bIndex >= 0) return 1;
      return a.name.toLowerCase().compareTo(b.name.toLowerCase());
    });
    return result;
  }

  Future<List<AppRole>> listSignupRoles() async {
    try {
      return (await listRoles(
        includeInactive: false,
      )).where((role) => role.id != AppConstants.roleAdmin).toList();
    } catch (_) {
      // Keep account creation available with the four built-in roles if the
      // roles collection has not been initialized or is temporarily offline.
      return AppRole.defaults;
    }
  }

  Future<bool> isActiveSignupRole(String roleId) async {
    if (roleId == AppConstants.roleAdmin ||
        roleId == AppConstants.roleSuperAdmin ||
        roleId.trim().isEmpty) {
      return false;
    }
    try {
      final snapshot = await _roles.doc(roleId).get();
      if (snapshot.exists) {
        final data = snapshot.data()!;
        return data['roleId'] == roleId && data['isActive'] == true;
      }
      return AppRole.defaults.any((role) => role.id == roleId);
    } catch (_) {
      return AppRole.defaults.any((role) => role.id == roleId);
    }
  }

  Future<AppRole> createRole({
    required String name,
    required String abbreviation,
  }) async {
    final cleanName = name.trim();
    final id = createRoleId(cleanName);
    if (cleanName.isEmpty || id.isEmpty) {
      throw ArgumentError('Enter a valid role name.');
    }
    if (id == AppConstants.roleAdmin || id == AppConstants.roleSuperAdmin) {
      throw ArgumentError('This role ID is reserved.');
    }
    if (AppRole.defaults.any((role) => role.id == id)) {
      throw StateError('This role ID is already used by a built-in role.');
    }
    final ref = _roles.doc(id);
    if ((await ref.get()).exists) {
      throw StateError('A role with this ID already exists.');
    }
    final role = AppRole(
      id: id,
      name: cleanName,
      abbreviation: abbreviation.trim(),
    );
    await ref.set({
      'roleId': role.id,
      'name': role.name,
      'abbreviation': role.abbreviation,
      'isActive': true,
      'isBuiltIn': false,
      'createdAt': FieldValue.serverTimestamp(),
    });
    return role;
  }

  Future<void> setRoleActive(AppRole role, bool isActive) async {
    await _roles.doc(role.id).set({
      'roleId': role.id,
      'name': role.name,
      'abbreviation': role.abbreviation,
      'isActive': isActive,
      'isBuiltIn': role.isBuiltIn,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  String createRoleId(String name) {
    final value = name
        .trim()
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]+'), '_')
        .replaceAll(RegExp(r'^_+|_+$'), '');
    return value;
  }
}
