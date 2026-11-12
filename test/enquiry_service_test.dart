import 'package:balaji_points/core/models/enquiry.dart';
import 'package:balaji_points/services/platform/enquiry_service.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Contact Us: members' enquiries carry branch and role; guests' do not.
void main() {
  late FakeFirebaseFirestore db;
  late EnquiryService service;
  const member = EnquirySender.member(
    name: 'Ravi Kumar',
    phone: '9876543210',
    userId: 'u9',
    branchId: 'erode',
    branchName: 'Erode',
    role: 'architect',
  );

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    db = FakeFirebaseFirestore();
    service = EnquiryService(db: db);
  });

  Future<Map<String, dynamic>> only() async =>
      (await db.collection('enquiries').get()).docs.single.data();

  test('member enquiry is saved with branch, role and user', () async {
    await service.submit(
      sender: member,
      type: EnquiryType.pointsBills,
      name: ' Ravi Kumar ',
      phone: '9876543210',
      message: 'My bill is still pending',
      city: 'ignored for members',
    );
    final d = await only();
    expect(d['source'], 'member');
    expect(d['branchId'], 'erode');
    expect(d['branchName'], 'Erode');
    expect(d['role'], 'architect');
    expect(d['userId'], 'u9');
    expect(d['type'], 'points_bills');
    expect(d['name'], 'Ravi Kumar');
    expect(d['status'], 'new');
    expect(d.containsKey('city'), isFalse);
  });

  test('guest enquiry has no branch, role or user', () async {
    await service.submit(
      sender: const EnquirySender.guest(),
      type: EnquiryType.membership,
      name: 'Suresh',
      phone: '9123456780',
      message: 'How can I become a member?',
      city: 'Salem',
    );
    final d = await only();
    expect(d['source'], 'guest');
    expect(d['city'], 'Salem');
    for (final k in ['branchId', 'branchName', 'role', 'userId']) {
      expect(d.containsKey(k), isFalse, reason: k);
    }
  });

  test('a second enquiry within the cooldown is refused', () async {
    final t = DateTime(2026, 11, 12, 10);
    Future<void> send(DateTime now) => service.submit(
      sender: member,
      type: EnquiryType.product,
      name: 'Ravi',
      phone: '9876543210',
      message: 'Need laminate rates',
      now: now,
    );
    await send(t);
    await expectLater(
      send(t.add(const Duration(seconds: 30))),
      throwsA(isA<EnquiryTooSoon>()),
    );
    await send(t.add(EnquiryService.cooldown));
    expect((await db.collection('enquiries').get()).docs.length, 2);
  });

  test('admin inbox: branch filter and resolve', () async {
    await service.submit(
      sender: member,
      type: EnquiryType.product,
      name: 'Ravi',
      phone: '9876543210',
      message: 'Need laminate rates',
    );
    final mine = await service.watch(branchId: 'erode').first;
    expect(mine, hasLength(1));
    expect(await service.watch(branchId: 'salem').first, isEmpty);
    expect(mine.single.isOpen, isTrue);
  });

  test(
    'branch inbox gets members only; super admin inbox gets guests only',
    () async {
      final t = DateTime(2026, 11, 12, 10);
      await service.submit(
        sender: member,
        type: EnquiryType.product,
        name: 'Ravi',
        phone: '9876543210',
        message: 'Need laminate rates',
        now: t,
      );
      await service.submit(
        sender: const EnquirySender.guest(),
        type: EnquiryType.membership,
        name: 'Suresh',
        phone: '9123456780',
        message: 'How do I join Balaji Points?',
        now: t.add(EnquiryService.cooldown),
      );
      final branch = await service.watch(branchId: 'erode').first;
      final guests = await service.watch().first;
      expect(branch.map((e) => e.name), ['Ravi']);
      expect(guests.map((e) => e.name), ['Suresh']);
      expect(guests.single.branchId, isNull);
    },
  );
}
