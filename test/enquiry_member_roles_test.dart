import 'package:balaji_points/core/models/enquiry.dart';
import 'package:balaji_points/services/platform/enquiry_service.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Contact Us from every member role reaches that member's own branch admin.
void main() {
  late FakeFirebaseFirestore db;

  setUp(() async {
    db = FakeFirebaseFirestore();
    await db.doc('branches/erode_main').set({
      'name': 'E Road',
      'isActive': true,
    });
    SharedPreferences.setMockInitialValues({});
  });

  /// Logs in (secure session) as [role] in the Erode branch.
  void loginAs(String? role) => FlutterSecureStorage.setMockInitialValues({
    'is_logged_in': 'true',
    'user_id': 'u1',
    'phone_number': '9876543210',
    'first_name': 'Ravi',
    'branch_id': 'erode_main',
    if (role != null) 'user_role': role,
  });

  for (final (saved, expected) in [
    ('carpenter', 'carpenter'),
    ('architect', 'architect'),
    ('engineer', 'engineer'),
    ('interior_designer', 'interior_designer'),
    // Older accounts with no role saved count as carpenters.
    (null, 'carpenter'),
    // Custom roles from the super admin are members too.
    ('mason', 'mason'),
  ]) {
    test('role ${saved ?? '(none)'}: enquiry goes to own branch', () async {
      loginAs(saved);
      final service = EnquiryService(db: db);
      final sender = await service.currentSender();
      expect(sender.isMember, isTrue);
      expect(sender.branchId, 'erode_main');
      expect(sender.branchName, 'E Road');
      expect(sender.role, expected);

      await service.submit(
        sender: sender,
        type: EnquiryType.product,
        name: sender.name,
        phone: sender.phone,
        message: 'Need laminate rates',
      );
      final inbox = await service.watch(branchId: 'erode_main').first;
      expect(inbox.single.source, EnquirySource.member);
      expect(inbox.single.role, expected);
      expect(inbox.single.userId, 'u1');
    });
  }

  for (final role in ['admin', 'super_admin']) {
    test('$role is not sent as a member', () async {
      loginAs(role);
      final sender = await EnquiryService(db: db).currentSender();
      expect(sender.isMember, isFalse);
    });
  }
}
