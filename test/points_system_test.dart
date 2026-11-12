import 'package:balaji_points/services/platform/bill_service.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';

/// Bill approval credits the right points once, keeps the tier in step,
/// logs it, and rejection credits nothing.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late FakeFirebaseFirestore db;
  late BillService service;

  Future<void> member(String id, String role, num total) async {
    await db.doc('users/$id').set({
      'role': role,
      'branchId': 'erode_main',
      'phone': '98765432${id.hashCode % 90 + 10}',
      'totalPoints': total,
    });
    await db.doc('user_points/$id').set({
      'userId': id,
      'totalPoints': total,
      'tier': total >= 2000 ? 'Silver' : 'Bronze',
      'pointsHistory': [],
    });
  }

  Future<void> bill(String id, String memberId, num amount, int rate) =>
      db.doc('bills/$id').set({
        'carpenterId': memberId,
        'amount': amount,
        'status': 'pending',
        'rupeesPerPoint': rate,
        'branchId': 'erode_main',
      });

  Future<Map<String, dynamic>> points(String id) async =>
      (await db.doc('user_points/$id').get()).data()!;

  setUp(() async {
    FlutterSecureStorage.setMockInitialValues({
      'user_id': 'admin1',
      'phone_number': '9600609121',
      'user_role': 'admin',
      'branch_id': 'erode_main',
    });
    db = FakeFirebaseFirestore();
    service = BillService(firestore: db);
    await member('carp', 'carpenter', 1990);
    await member('arch', 'architect', 0);
  });

  test(
    'approval credits points at the bill rate and upgrades the tier',
    () async {
      await bill('b1', 'carp', 15000, 1000); // 15 points
      expect(await service.approveBill('b1', 'carp', 15000), isTrue);

      final p = await points('carp');
      expect(p['totalPoints'], closeTo(2005, 0.001));
      expect(p['tier'], 'Silver'); // crossed 2,000
      final history = (p['pointsHistory'] as List).cast<Map>();
      expect(history.single['billId'], 'b1');
      expect(history.single['points'], closeTo(15, 0.001));
      expect((await db.doc('bills/b1').get()).data()!['status'], 'approved');
    },
  );

  test('a bill can never be credited twice', () async {
    await bill('b2', 'carp', 5000, 1000); // 5 points
    expect(await service.approveBill('b2', 'carp', 5000), isTrue);
    expect(await service.approveBill('b2', 'carp', 5000), isFalse);
    final p = await points('carp');
    expect(p['totalPoints'], closeTo(1995, 0.001));
    expect((p['pointsHistory'] as List).length, 1);
  });

  test('architects earn at their own rate (5,000 per point)', () async {
    await bill('b3', 'arch', 12500, 5000); // 2.5 points
    expect(await service.approveBill('b3', 'arch', 12500), isTrue);
    expect((await points('arch'))['totalPoints'], closeTo(2.5, 0.001));
  });

  test('rejecting a bill credits nothing', () async {
    await bill('b4', 'carp', 9000, 1000);
    expect(await service.rejectBill('b4'), isTrue);
    expect((await db.doc('bills/b4').get()).data()!['status'], 'rejected');
    final p = await points('carp');
    expect(p['totalPoints'], 1990);
    expect(p['pointsHistory'], isEmpty);
    // And a rejected bill cannot be approved afterwards.
    expect(await service.approveBill('b4', 'carp', 9000), isFalse);
    expect((await points('carp'))['totalPoints'], 1990);
  });
}
