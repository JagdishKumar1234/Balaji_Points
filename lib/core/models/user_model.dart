import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:balaji_points/core/models/user.dart';

/// Data model for User
/// 
/// Extends the domain entity and adds JSON serialization.
/// Handles conversion between Firestore and domain entities.
class UserModel extends User {
  UserModel({
    required super.id,
    required super.email,
    super.phoneNumber,
    super.displayName,
    super.photoUrl,
    required super.role,
    required super.isEmailVerified,
    super.createdAt,
    super.lastLoginAt,
  });
  
  /// Convert from Firestore document
  factory UserModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return UserModel.fromJson(data, doc.id);
  }
  
  /// Convert from JSON
  factory UserModel.fromJson(Map<String, dynamic> json, [String? id]) {
    return UserModel(
      id: id ?? json['id'] as String,
      email: json['email'] as String,
      phoneNumber: json['phoneNumber'] as String?,
      displayName: json['displayName'] as String?,
      photoUrl: json['photoUrl'] as String?,
      role: json['role'] as String? ?? 'carpenter',
      isEmailVerified: json['isEmailVerified'] as bool? ?? false,
      createdAt: json['createdAt'] != null
          ? (json['createdAt'] as Timestamp).toDate()
          : null,
      lastLoginAt: json['lastLoginAt'] != null
          ? (json['lastLoginAt'] as Timestamp).toDate()
          : null,
    );
  }
  
  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'phoneNumber': phoneNumber,
      'displayName': displayName,
      'photoUrl': photoUrl,
      'role': role,
      'isEmailVerified': isEmailVerified,
      'createdAt': createdAt != null ? Timestamp.fromDate(createdAt!) : null,
      'lastLoginAt': lastLoginAt != null ? Timestamp.fromDate(lastLoginAt!) : null,
    };
  }
  
  /// Convert from domain entity
  factory UserModel.fromEntity(User user) {
    return UserModel(
      id: user.id,
      email: user.email,
      phoneNumber: user.phoneNumber,
      displayName: user.displayName,
      photoUrl: user.photoUrl,
      role: user.role,
      isEmailVerified: user.isEmailVerified,
      createdAt: user.createdAt,
      lastLoginAt: user.lastLoginAt,
    );
  }
  
  /// Convert to domain entity
  User toEntity() {
    return User(
      id: id,
      email: email,
      phoneNumber: phoneNumber,
      displayName: displayName,
      photoUrl: photoUrl,
      role: role,
      isEmailVerified: isEmailVerified,
      createdAt: createdAt,
      lastLoginAt: lastLoginAt,
    );
  }
}
