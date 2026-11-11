/// User entity for authentication
///
/// This is a plain Dart class with no dependencies on external packages.
/// It represents the authenticated user in the business logic.
class User {
  final String id;
  final String email;
  final String? phoneNumber;
  final String? displayName;
  final String? photoUrl;
  final String
  role; // 'super_admin', 'admin', 'carpenter', 'architect', 'interior_designer'
  final String? branchId;
  final String? tenantId;
  final String status; // 'active', 'pending', 'deactivated'
  final bool isEmailVerified;
  final DateTime? createdAt;
  final DateTime? lastLoginAt;

  User({
    required this.id,
    required this.email,
    this.phoneNumber,
    this.displayName,
    this.photoUrl,
    required this.role,
    this.branchId,
    this.tenantId,
    this.status = 'active',
    required this.isEmailVerified,
    this.createdAt,
    this.lastLoginAt,
  });

  bool get isSuperAdmin => role == 'super_admin';
  bool get isAdmin => role == 'admin';
  bool get isCarpenter => role == 'carpenter';
  bool get isArchitect => role == 'architect';
  bool get isInteriorDesigner => role == 'interior_designer';

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is User && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  User copyWith({
    String? id,
    String? email,
    String? phoneNumber,
    String? displayName,
    String? photoUrl,
    String? role,
    String? branchId,
    String? tenantId,
    String? status,
    bool? isEmailVerified,
    DateTime? createdAt,
    DateTime? lastLoginAt,
  }) {
    return User(
      id: id ?? this.id,
      email: email ?? this.email,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      displayName: displayName ?? this.displayName,
      photoUrl: photoUrl ?? this.photoUrl,
      role: role ?? this.role,
      branchId: branchId ?? this.branchId,
      tenantId: tenantId ?? this.tenantId,
      status: status ?? this.status,
      isEmailVerified: isEmailVerified ?? this.isEmailVerified,
      createdAt: createdAt ?? this.createdAt,
      lastLoginAt: lastLoginAt ?? this.lastLoginAt,
    );
  }
}
