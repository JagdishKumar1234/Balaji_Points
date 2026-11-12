import 'package:cloud_firestore/cloud_firestore.dart';

/// What an enquiry is about. Ids are stored in Firestore and checked by the
/// security rules, so never rename one.
enum EnquiryType {
  product('product'),
  quotation('quotation'),
  pointsBills('points_bills'),
  appHelp('app_help'),
  membership('membership'),
  other('other');

  const EnquiryType(this.id);
  final String id;

  static EnquiryType fromId(String? id) => EnquiryType.values.firstWhere(
    (t) => t.id == id,
    orElse: () => EnquiryType.other,
  );

  /// Members ask about their points and bills; guests ask how to join.
  static const List<EnquiryType> forMember = [
    product,
    quotation,
    pointsBills,
    appHelp,
    other,
  ];
  static const List<EnquiryType> forGuest = [
    product,
    quotation,
    membership,
    other,
  ];
}

/// Who sent it. A member's enquiry carries their branch and role, so it goes
/// to that branch's admin. A guest's has neither and goes to the super admin.
enum EnquirySource { member, guest }

enum EnquiryStatus {
  open('new'),
  resolved('resolved');

  const EnquiryStatus(this.id);
  final String id;

  static EnquiryStatus fromId(String? id) =>
      id == 'resolved' ? EnquiryStatus.resolved : EnquiryStatus.open;
}

/// Firestore: `enquiries/{id}`.
class Enquiry {
  const Enquiry({
    required this.id,
    required this.type,
    required this.name,
    required this.phone,
    required this.message,
    required this.source,
    this.status = EnquiryStatus.open,
    this.branchId,
    this.branchName = '',
    this.role,
    this.userId,
    this.city = '',
    this.createdAt,
    this.resolvedAt,
  });

  final String id;
  final EnquiryType type;
  final String name;
  final String phone;
  final String message;
  final EnquirySource source;
  final EnquiryStatus status;
  final String? branchId;
  final String branchName;
  final String? role;
  final String? userId;
  final String city;
  final DateTime? createdAt;
  final DateTime? resolvedAt;

  bool get isGuest => source == EnquirySource.guest;
  bool get isOpen => status == EnquiryStatus.open;

  factory Enquiry.fromMap(String id, Map<String, dynamic> d) => Enquiry(
    id: id,
    type: EnquiryType.fromId(d['type'] as String?),
    name: (d['name'] as String? ?? '').trim(),
    phone: (d['phone'] as String? ?? '').trim(),
    message: (d['message'] as String? ?? '').trim(),
    source: d['source'] == 'member'
        ? EnquirySource.member
        : EnquirySource.guest,
    status: EnquiryStatus.fromId(d['status'] as String?),
    branchId: d['branchId'] as String?,
    branchName: d['branchName'] as String? ?? '',
    role: d['role'] as String?,
    userId: d['userId'] as String?,
    city: d['city'] as String? ?? '',
    createdAt: (d['createdAt'] as Timestamp?)?.toDate(),
    resolvedAt: (d['resolvedAt'] as Timestamp?)?.toDate(),
  );

  factory Enquiry.fromDoc(DocumentSnapshot<Map<String, dynamic>> d) =>
      Enquiry.fromMap(d.id, d.data() ?? const {});
}
