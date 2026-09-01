import 'package:cloud_firestore/cloud_firestore.dart';

class GreetingItem {
  final String id;
  final String message;
  final DateTime createdAt;
  final String createdBy;
  final bool active;
  final DateTime? expiresAt;
  final String? imageUrl;

  GreetingItem({
    required this.id,
    required this.message,
    required this.createdAt,
    required this.createdBy,
    required this.active,
    this.expiresAt,
    this.imageUrl,
  });

  factory GreetingItem.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return GreetingItem.fromJson(data, doc.id);
  }

  factory GreetingItem.fromJson(Map<String, dynamic> json, [String? id]) {
    return GreetingItem(
      id: id ?? json['id'] as String,
      message: json['message'] as String,
      createdAt: json['createdAt'] != null
          ? (json['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
      createdBy: json['createdBy'] as String? ?? '',
      active: json['active'] as bool? ?? false,
      expiresAt: json['expiresAt'] != null
          ? (json['expiresAt'] as Timestamp).toDate()
          : null,
      imageUrl: json['imageUrl'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'message': message,
      'createdAt': Timestamp.fromDate(createdAt),
      'createdBy': createdBy,
      'active': active,
      'expiresAt': expiresAt != null ? Timestamp.fromDate(expiresAt!) : null,
      'imageUrl': imageUrl,
    };
  }

  GreetingItem copyWith({
    String? id,
    String? message,
    DateTime? createdAt,
    String? createdBy,
    bool? active,
    DateTime? expiresAt,
    String? imageUrl,
  }) {
    return GreetingItem(
      id: id ?? this.id,
      message: message ?? this.message,
      createdAt: createdAt ?? this.createdAt,
      createdBy: createdBy ?? this.createdBy,
      active: active ?? this.active,
      expiresAt: expiresAt ?? this.expiresAt,
      imageUrl: imageUrl ?? this.imageUrl,
    );
  }
}
