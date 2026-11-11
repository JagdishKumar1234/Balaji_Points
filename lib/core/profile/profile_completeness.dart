/// What a member's profile has and what it still needs.
///
/// The same rule for every member role (carpenter, architect, engineer,
/// interior designer): submitting a bill needs a profile photo, first name,
/// last name and mobile number. Email is shown on the checklist but is not
/// needed for bills.
class ProfileCompleteness {
  const ProfileCompleteness({
    required this.hasPhoto,
    required this.hasFirstName,
    required this.hasLastName,
    required this.hasPhone,
    required this.hasEmail,
  });

  factory ProfileCompleteness.from(Map<String, dynamic>? data) {
    String s(String key) => (data?[key] as String? ?? '').trim();
    final phone = s('phone').isNotEmpty ? s('phone') : s('phoneNumber');
    return ProfileCompleteness(
      hasPhoto: s('profileImage').isNotEmpty,
      hasFirstName: s('firstName').isNotEmpty,
      hasLastName: s('lastName').isNotEmpty,
      hasPhone: phone.replaceAll(RegExp(r'[^0-9]'), '').length >= 10,
      hasEmail: s('email').contains('@'),
    );
  }

  final bool hasPhoto;
  final bool hasFirstName;
  final bool hasLastName;
  final bool hasPhone;
  final bool hasEmail;

  bool get hasFullName => hasFirstName && hasLastName;

  /// Photo, first and last name, and mobile number.
  bool get isReadyForBills => hasPhoto && hasFullName && hasPhone;

  /// The items still missing for bills, in the order shown to the member.
  List<ProfileItem> get missingForBills => [
    if (!hasPhoto) ProfileItem.photo,
    if (!hasFullName) ProfileItem.name,
    if (!hasPhone) ProfileItem.phone,
  ];

  /// 0–4: phone, email, name, photo.
  int get completedCount =>
      (hasPhone ? 1 : 0) +
      (hasEmail ? 1 : 0) +
      (hasFullName ? 1 : 0) +
      (hasPhoto ? 1 : 0);
}

enum ProfileItem { phone, email, name, photo }
