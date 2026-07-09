import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import '../../core/logger.dart';
import '../auth/session_service.dart';
import '../notifications/notification_service.dart';

class BillService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final SessionService _sessionService = SessionService();

  /// Upload bill image to Firebase Storage
  Future<String?> uploadBillImage(File imageFile, String billId) async {
    try {
      final ref = _storage.ref().child('bill_images/$billId.jpg');

      AppLogger.info('Uploading bill image: bill_images/$billId.jpg');

      final uploadTask = await ref.putFile(
        imageFile,
        SettableMetadata(
          contentType: 'image/jpeg',
          customMetadata: {
            'billId': billId,
            'uploadedAt': DateTime.now().toIso8601String(),
          },
        ),
      );

      final imageUrl = await uploadTask.ref.getDownloadURL();
      AppLogger.info('Bill image uploaded: $imageUrl');
      return imageUrl;
    } on FirebaseException catch (e) {
      AppLogger.error('Firebase Storage error', '${e.code} - ${e.message}');
      throw Exception('Storage error: ${e.message}');
    } catch (e) {
      AppLogger.error('Error uploading bill image', e);
      throw Exception('Failed to upload bill image: $e');
    }
  }

  /// Submit bill
  Future<bool> submitBill({
    required String carpenterId,
    required String carpenterPhone,
    required double amount,
    File? imageFile,
    DateTime? billDate,
    String? storeName,
    String? vendorName,
  }) async {
    try {
      AppLogger.info('BillService: === SUBMITTING BILL ===');
      AppLogger.info('  carpenterId: $carpenterId');
      AppLogger.info('  carpenterPhone: $carpenterPhone');
      AppLogger.info('  amount: $amount');
      AppLogger.info('  storeName: $storeName');
      AppLogger.info('  vendorName: $vendorName');

      final billRef = _firestore.collection('bills').doc();
      final billId = billRef.id;
      AppLogger.info('  Generated billId: $billId');

      String? imageUrl;
      if (imageFile != null) {
        AppLogger.info('  Uploading bill image...');
        imageUrl = await uploadBillImage(imageFile, billId);
        AppLogger.info('  Image uploaded: $imageUrl');
      }

      final branchId = await _sessionService.getBranchId();

      final billData = {
        'billId': billId,
        'carpenterId': carpenterId,
        'carpenterPhone': carpenterPhone,
        'amount': amount,
        'imageUrl': imageUrl ?? '',
        'status': 'pending',
        'pointsEarned': 0,
        'branchId': branchId,
        'billDate': Timestamp.fromDate(billDate ?? DateTime.now()),
        'siteName': storeName ?? '',
        'vendorName': vendorName ?? '',
        'createdAt': FieldValue.serverTimestamp(),
      };

      AppLogger.info('  Saving to Firestore: bills/$billId');
      await billRef.set(billData);

      // Verify the save by reading back
      final verifyDoc = await billRef.get();
      if (verifyDoc.exists) {
        AppLogger.info('BillService: ✅ Bill saved and verified successfully!');
        AppLogger.info(
          '  Verified data: carpenterId=${verifyDoc.data()?['carpenterId']}, status=${verifyDoc.data()?['status']}',
        );

        // Send notification to all admins about new pending bill
        try {
          // Get carpenter name from users collection
          final userDoc =
              await _firestore.collection('users').doc(carpenterId).get();
          final userData = userDoc.data();
          final firstName = userData?['firstName'] as String? ?? '';
          final lastName = userData?['lastName'] as String? ?? '';
          final carpenterName = '$firstName $lastName'.trim();

          final notificationService = NotificationService();
          await notificationService.notifyAdminsNewPendingBill(
            carpenterName:
                carpenterName.isNotEmpty ? carpenterName : carpenterPhone,
            carpenterPhone: carpenterPhone,
            amount: amount,
            billId: billId,
          );
          AppLogger.info('✅ Admin notification sent for new pending bill');
        } catch (e) {
          // Don't fail the bill submission if notification fails
          AppLogger.warning('Failed to send admin notification: $e');
        }
      } else {
        AppLogger.error(
          'BillService: ❌ Bill document not found after save!',
          null,
        );
      }

      return true;
    } catch (e) {
      AppLogger.error('BillService: ❌ Error submitting bill', e);
      return false;
    }
  }

  /// Submit bill for carpenter by admin
  Future<bool> submitBillForCarpenter({
    required String carpenterId,
    required String carpenterPhone,
    required double amount,
    required String adminId,
    required String adminPhone,
    String? adminName,
    File? imageFile,
    DateTime? billDate,
    String? storeName,
    String? vendorName,
  }) async {
    try {
      AppLogger.debug('═══════════════════════════════════════════════════════════');
      AppLogger.debug('📝 ADMIN BILL SUBMISSION START');
      AppLogger.debug('═══════════════════════════════════════════════════════════');
      AppLogger.info('BillService: === ADMIN SUBMITTING BILL FOR CARPENTER ===');
      AppLogger.info('=== INPUT PARAMETERS ===');
      AppLogger.info('  carpenterId: $carpenterId');
      AppLogger.info('  carpenterPhone: $carpenterPhone');
      AppLogger.info('  adminId: $adminId');
      AppLogger.info('  adminPhone: $adminPhone');
      AppLogger.info('  amount: $amount');
      AppLogger.info('  storeName: $storeName');
      AppLogger.info('  vendorName: $vendorName');
      AppLogger.info('  billDate: $billDate');
      AppLogger.debug('   hasImage: ${imageFile != null}');

      AppLogger.debug('📝 Step 1: Generating bill ID...');
      final billRef = _firestore.collection('bills').doc();
      final billId = billRef.id;
      AppLogger.info('✅ Generated billId: $billId');
      AppLogger.debug('   billRef path: bills/$billId');

      AppLogger.debug('📝 Step 2: Handling bill image...');
      String? imageUrl;
      if (imageFile != null) {
        AppLogger.info('  Uploading bill image...');
        AppLogger.debug('   Image file size: ${imageFile.lengthSync()} bytes');
        imageUrl = await uploadBillImage(imageFile, billId);
        AppLogger.info('  ✅ Image uploaded: $imageUrl');
        AppLogger.debug('   Image URL length: ${imageUrl?.length ?? 0} chars');
      } else {
        AppLogger.debug('   No image provided, skipping upload');
      }

      AppLogger.debug('📝 Step 3: Resolving carpenter branch...');
      String? carpenterBranchId;
      try {
        final carpenterDoc =
            await _firestore.collection('users').doc(carpenterId).get();
        if (carpenterDoc.exists) {
          carpenterBranchId = carpenterDoc.data()?['branchId'] as String?;
          AppLogger.debug('   Found carpenter doc, branchId: $carpenterBranchId');
        } else {
          AppLogger.debug('   Carpenter doc by ID not found, searching by phone...');
          final q = await _firestore
              .collection('users')
              .where('phone', isEqualTo: carpenterPhone)
              .limit(1)
              .get();
          if (q.docs.isNotEmpty) {
            carpenterBranchId = q.docs.first.data()['branchId'] as String?;
            AppLogger.debug('   Found by phone, branchId: $carpenterBranchId');
          } else {
            AppLogger.debug('   Carpenter not found by phone either');
          }
        }
      } catch (e) {
        AppLogger.warning('Error looking up carpenter branch: $e');
      }
      // Fallback to admin's session branch if carpenter doc lookup fails
      final adminSessionBranch = await _sessionService.getBranchId();
      carpenterBranchId ??= adminSessionBranch;
      AppLogger.info('✅ Final carpenterBranchId: $carpenterBranchId');

      AppLogger.debug('📝 Step 4: Preparing bill data...');
      final billData = {
        'billId': billId,
        'carpenterId': carpenterId,
        'carpenterPhone': carpenterPhone,
        'amount': amount,
        'imageUrl': imageUrl ?? '',
        'status': 'pending',
        'pointsEarned': 0,
        'branchId': carpenterBranchId,
        'billDate': Timestamp.fromDate(billDate ?? DateTime.now()),
        'siteName': storeName ?? '',
        'vendorName': vendorName ?? '',
        'submittedBy': 'admin',
        'adminId': adminId,
        'adminPhone': adminPhone,
        if (adminName != null) 'adminName': adminName,
        'createdAt': FieldValue.serverTimestamp(),
      };
      AppLogger.debug('   billData keys: ${billData.keys.join(", ")}');
      AppLogger.debug('   billData ready for save');

      AppLogger.debug('📝 Step 5: Saving to Firestore...');
      AppLogger.info('  💾 Saving bill to Firestore: bills/$billId');
      final startTime = DateTime.now();
      await billRef.set(billData);
      final saveDuration = DateTime.now().difference(startTime);
      AppLogger.info('  ✅ Bill saved in ${saveDuration.inMilliseconds}ms');

      AppLogger.debug('📝 Step 6: Verifying save by reading back...');
      final verifyDoc = await billRef.get();
      if (verifyDoc.exists) {
        final verifyData = verifyDoc.data();
        AppLogger.info('BillService: ✅ Admin bill saved and verified successfully!');
        AppLogger.info('=== VERIFICATION RESULTS ===');
        AppLogger.info('  billId: ${verifyData?['billId']}');
        AppLogger.info('  carpenterId: ${verifyData?['carpenterId']}');
        AppLogger.info('  carpenterPhone: ${verifyData?['carpenterPhone']}');
        AppLogger.info('  amount: ${verifyData?['amount']}');
        AppLogger.info('  status: ${verifyData?['status']}');
        AppLogger.info('  submittedBy: ${verifyData?['submittedBy']}');
        AppLogger.info('  adminId: ${verifyData?['adminId']}');
        AppLogger.info('  adminPhone: ${verifyData?['adminPhone']}');
        AppLogger.info('  branchId: ${verifyData?['branchId']}');
        AppLogger.info('  siteName: ${verifyData?['siteName']}');
        AppLogger.info('  vendorName: ${verifyData?['vendorName']}');
        AppLogger.debug('═══════════════════════════════════════════════════════════');
        AppLogger.debug('✅ ADMIN BILL SUBMISSION SUCCESS');
        AppLogger.debug('═══════════════════════════════════════════════════════════');
      } else {
        AppLogger.error(
          'BillService: ❌ Bill document not found after save!',
          'Bill $billId was not saved properly',
        );
        AppLogger.debug('═══════════════════════════════════════════════════════════');
        AppLogger.debug('❌ ADMIN BILL SUBMISSION FAILED (VERIFICATION)');
        AppLogger.debug('═══════════════════════════════════════════════════════════');
        return false;
      }

      return true;
    } catch (e, st) {
      AppLogger.debug('═══════════════════════════════════════════════════════════');
      AppLogger.debug('❌ ADMIN BILL SUBMISSION FAILED (EXCEPTION)');
      AppLogger.debug('═══════════════════════════════════════════════════════════');
      AppLogger.error('BillService: ❌ Error submitting bill for carpenter', e);
      AppLogger.debug('  Exception type: ${e.runtimeType}');
      AppLogger.debug('  StackTrace:\n$st');
      AppLogger.debug('═══════════════════════════════════════════════════════════');
      return false;
    }
  }

  /// Approve bill (Admin) - Uses Firestore transaction for atomic, race-condition-safe approval
  Future<bool> approveBill(
    String billId,
    String carpenterId,
    double amount,
  ) async {
    final approveStartTime = DateTime.now();
    AppLogger.debug('═══════════════════════════════════════════════════════════');
    AppLogger.debug('🚀 APPROVE BILL START (TRANSACTION-BASED)');
    AppLogger.debug('═══════════════════════════════════════════════════════════');
    AppLogger.debug('📋 INPUT PARAMETERS:');
    AppLogger.debug('   billId: "$billId"');
    AppLogger.debug('   carpenterId: "$carpenterId"');
    AppLogger.debug('   amount: $amount');
    AppLogger.debug('   timestamp: $approveStartTime');
    AppLogger.debug('═══════════════════════════════════════════════════════════');

    AppLogger.info('=== APPROVE BILL START (TRANSACTION) ===');
    AppLogger.info('billId=$billId | carpenterId=$carpenterId | amount=$amount');

    try {
      // Validate inputs BEFORE transaction
      AppLogger.debug('📝 Step 0: Validating inputs...');
      AppLogger.info('Step 0: Validating inputs...');
      if (billId.isEmpty) {
        AppLogger.debug('❌ ERROR: Bill ID is empty!');
        AppLogger.error('approveBill: ❌ Bill ID is empty', '');
        return false;
      }
      AppLogger.debug('   ✓ billId is valid: "$billId"');
      AppLogger.info('  ✓ billId is valid: $billId');

      if (amount <= 0) {
        AppLogger.debug('❌ ERROR: Invalid amount: $amount');
        AppLogger.error('approveBill: ❌ Invalid amount', amount);
        return false;
      }
      AppLogger.debug('   ✓ amount is valid: $amount');
      AppLogger.info('  ✓ amount is valid: $amount');

      final pointsEarned = amount / 1000;
      AppLogger.debug('   ✓ pointsEarned calculated: $pointsEarned');
      AppLogger.info('  ✓ pointsEarned calculated: $pointsEarned');

      // Get admin info BEFORE transaction
      AppLogger.info('Step 1: Getting admin info...');
      final fbUser = FirebaseAuth.instance.currentUser;
      AppLogger.info('  FirebaseAuth currentUser: ${fbUser?.uid ?? "null"}');

      final sessionPhone = await _sessionService.getPhoneNumber();
      final sessionUserId = await _sessionService.getUserId();
      AppLogger.info('  Session phone: $sessionPhone');
      AppLogger.info('  Session userId: $sessionUserId');

      final adminPhone = sessionPhone ?? fbUser?.phoneNumber ?? 'admin';
      final adminUserId = sessionUserId ?? fbUser?.uid ?? 'admin';

      AppLogger.info('  ✓ Final adminPhone: $adminPhone');
      AppLogger.info('  ✓ Final adminUserId: $adminUserId');

      // Points history entry
      AppLogger.debug('📝 Step 2: Creating points history entry...');
      AppLogger.info('Step 2: Creating points history entry...');
      final newHistoryEntry = {
        'points': pointsEarned,
        'reason': 'Bill approval',
        'date': Timestamp.now(),
        'billId': billId,
        'amount': amount,
      };
      AppLogger.debug('   History entry: $newHistoryEntry');
      AppLogger.info('  History entry: $newHistoryEntry');

      // ATOMIC TRANSACTION - all-or-nothing approval
      AppLogger.info('Step 3: Pre-transaction carpenter ID resolution...');
      final billRef = _firestore.collection('bills').doc(billId);

      // Resolve carpenter ID first (before transaction)
      String finalCarpenterId = carpenterId;
      AppLogger.debug('   Initial carpenterId param: "$carpenterId"');
      if (finalCarpenterId.isEmpty) {
        AppLogger.debug('   carpenterId param is empty, fetching from bill doc...');
        // Need to fetch bill to get carpenter ID
        final billDocSnap = await billRef.get();
        if (!billDocSnap.exists) {
          AppLogger.error('approveBill: ❌ Bill not found', billId);
          AppLogger.debug('   Firestore path: bills/$billId');
          return false;
        }
        finalCarpenterId = billDocSnap.data()?['carpenterId'] ?? '';
        AppLogger.debug('   Extracted carpenterId from bill: "$finalCarpenterId"');
        if (finalCarpenterId.isEmpty) {
          AppLogger.error('approveBill: ❌ Carpenter ID not found in bill', billId);
          return false;
        }
      }
      AppLogger.info('✅ Final carpenterId resolved: $finalCarpenterId');

      final userRef = _firestore.collection('users').doc(finalCarpenterId);
      final userPointsRef = _firestore.collection('user_points').doc(finalCarpenterId);
      AppLogger.debug('   Will update: users/$finalCarpenterId');
      AppLogger.debug('   Will update: user_points/$finalCarpenterId');

      late double newTotalPoints;
      late String oldTier;
      late String newTier;

      try {
        AppLogger.info('Step 4: Entering Firestore transaction...');
        await _firestore.runTransaction((transaction) async {
          AppLogger.debug('   🔄 TRANSACTION STARTED');

          // Step 1: Fetch bill atomically
          AppLogger.debug('   📖 Step T1: Reading bill doc from transaction...');
          final billSnap = await transaction.get(billRef);
          if (!billSnap.exists) {
            AppLogger.error('   ❌ Bill not found in transaction', billId);
            throw Exception('Bill not found');
          }

          final billData = billSnap.data() as Map<String, dynamic>;
          final currentStatus = billData['status'] as String? ?? 'pending';
          AppLogger.debug('   ✓ Bill status: $currentStatus');
          AppLogger.debug('   ✓ Bill amount: ${billData['amount']}');
          AppLogger.debug('   ✓ Bill carpenterId: ${billData['carpenterId']}');

          // Step 2: Check if already processed (prevents double-approval)
          if (currentStatus != 'pending') {
            AppLogger.error(
              '   ❌ Bill already processed (status: $currentStatus)',
              billId,
            );
            throw Exception('Bill already processed (status: $currentStatus)');
          }
          AppLogger.debug('   ✓ Bill status check passed (status == pending)');

          // Step 3: Get current points and tier from user_points (source of truth)
          AppLogger.debug('   📖 Step T2: Reading user_points doc from transaction...');
          final userPointsSnap = await transaction.get(userPointsRef);
          final userSnap = await transaction.get(userRef);

          // Prevent duplicate credit for the same bill
          if (userPointsSnap.exists) {
            final existingHistory =
                (userPointsSnap.data()?['pointsHistory'] as List?) ?? [];
            for (final entry in existingHistory) {
              final entryMap = Map<String, dynamic>.from(entry as Map);
              if (entryMap['billId'] == billId) {
                throw Exception('Bill already credited in points history');
              }
            }
          }

          final currentPointsValue = userPointsSnap.exists
              ? (userPointsSnap.data()?['totalPoints'] ?? 0)
              : 0;
          final currentPointsDouble = (currentPointsValue as num? ?? 0).toDouble();

          oldTier = userSnap.exists
              ? (userSnap.data()?['tier'] as String? ?? 'Bronze')
              : 'Bronze';

          AppLogger.debug('   ✓ user_points exists: ${userPointsSnap.exists}');
          AppLogger.debug('   ✓ Current totalPoints (source of truth): $currentPointsDouble');
          AppLogger.debug('   ✓ Current tier: $oldTier');
          if (userPointsSnap.exists) {
            AppLogger.debug('   ✓ History entries: ${(userPointsSnap.data()?['pointsHistory'] as List?)?.length ?? 0}');
          }

          // Step 4: Calculate new total
          newTotalPoints = currentPointsDouble + pointsEarned;
          newTier = _calculateTier(newTotalPoints.toInt());

          AppLogger.debug('   📊 CALCULATION:');
          AppLogger.debug('     Current: $currentPointsDouble');
          AppLogger.debug('     + Adding: $pointsEarned');
          AppLogger.debug('     = New Total: $newTotalPoints');
          AppLogger.debug('     Tier: $oldTier → $newTier');

          AppLogger.info('  ✓ Current points: $currentPointsDouble');
          AppLogger.info('  ✓ Points to add: $pointsEarned');
          AppLogger.info('  ✓ New total: $newTotalPoints');
          AppLogger.info('  ✓ Old tier: $oldTier -> New tier: $newTier');

          // Step 5: Update bill with approval
          AppLogger.debug('   ✍️  Step T3: Updating bill doc in transaction...');
          transaction.update(billRef, {
            'status': 'approved',
            'pointsEarned': pointsEarned,
            'approvedBy': adminUserId,
            'approvedByPhone': adminPhone,
            'approvedAt': FieldValue.serverTimestamp(),
            'approvedDate': _getTodayDateString(),
          });
          AppLogger.debug('   ✓ Bill update enqueued');
          AppLogger.debug('     - status: pending → approved');
          AppLogger.debug('     - pointsEarned: $pointsEarned');
          AppLogger.debug('     - approvedBy: $adminUserId');
          AppLogger.info('  ✓ Bill updated in transaction');

          // Step 6: Keep users doc in sync with user_points (source of truth)
          AppLogger.debug('   ✍️  Step T4: Updating users doc in transaction...');
          transaction.set(
            userRef,
            {
              'totalPoints': newTotalPoints,
              'tier': newTier,
              'lastUpdated': FieldValue.serverTimestamp(),
            },
            SetOptions(merge: true),
          );
          AppLogger.debug('   ✓ Users update enqueued');
          AppLogger.debug('     - totalPoints: $currentPointsDouble → $newTotalPoints');
          AppLogger.debug('     - tier: $oldTier → $newTier (merge: true)');
          AppLogger.info('  ✓ User doc synced in transaction');

          // Step 7: Update/create user_points with new total
          AppLogger.debug('   ✍️  Step T5: Updating user_points doc in transaction...');
          if (userPointsSnap.exists) {
            AppLogger.debug('     Document exists, using UPDATE');
            transaction.update(userPointsRef, {
              'totalPoints': newTotalPoints,
              'tier': newTier,
              'lastUpdated': FieldValue.serverTimestamp(),
              'pointsHistory': FieldValue.arrayUnion([newHistoryEntry]),
            });
            AppLogger.debug('   ✓ user_points update enqueued');
            AppLogger.debug('     - totalPoints: $currentPointsDouble → $newTotalPoints');
            AppLogger.debug('     - tier: $oldTier → $newTier');
            AppLogger.debug('     - adding history entry with billId: $billId');
            AppLogger.info('  ✓ User points updated in transaction');
          } else {
            AppLogger.debug('     Document does not exist, using SET');
            transaction.set(userPointsRef, {
              'userId': finalCarpenterId,
              'totalPoints': newTotalPoints,
              'tier': newTier,
              'lastUpdated': FieldValue.serverTimestamp(),
              'pointsHistory': [newHistoryEntry],
            });
            AppLogger.debug('   ✓ user_points set enqueued (new document)');
            AppLogger.debug('     - userId: $finalCarpenterId');
            AppLogger.debug('     - totalPoints: $newTotalPoints');
            AppLogger.debug('     - tier: $newTier');
            AppLogger.debug('     - history entries: 1');
            AppLogger.info('  ✓ User points created in transaction');
          }
        });

        final transactionDuration = DateTime.now().difference(approveStartTime);
        AppLogger.debug('✅✅✅ TRANSACTION COMMITTED SUCCESSFULLY! ✅✅✅');
        AppLogger.debug('   Duration: ${transactionDuration.inMilliseconds}ms');
        AppLogger.debug('   All 3 writes applied atomically');
        AppLogger.info('✅ Transaction committed in ${transactionDuration.inMilliseconds}ms!');
        AppLogger.info('=== TRANSACTION RESULT ===');
        AppLogger.info('  Bill ID: $billId');
        AppLogger.info('  Carpenter ID: $finalCarpenterId');
        AppLogger.info('  Points Added: $pointsEarned');
        AppLogger.info('  New Total: $newTotalPoints');
        AppLogger.info('  Tier Change: $oldTier → $newTier');
        AppLogger.info('=== APPROVE BILL SUCCESS ===');
        AppLogger.debug('═══════════════════════════════════════════════════════════');
        AppLogger.debug('✅ APPROVE BILL SUCCESS (TRANSACTION PHASE)');
        AppLogger.debug('═══════════════════════════════════════════════════════════');
        AppLogger.debug('🔔 NOTIFICATION SECTION STARTING...');
        AppLogger.debug('   Carpenter ID: $finalCarpenterId');
        AppLogger.debug('   Will attempt to notify user of approval');

        // Send notification after successful approval
        try {
          AppLogger.debug('🔔 Step 1: Inside notification try block');
          AppLogger.info('📤 Attempting to send bill approved notification...');
          AppLogger.info('   userId: $finalCarpenterId');
          AppLogger.info('   amount: $amount');
          AppLogger.info('   points: $pointsEarned');
          AppLogger.info('   billId: $billId');
          AppLogger.debug('🔔 Step 2: Creating NotificationService instance...');

          final notificationService = NotificationService();
          AppLogger.debug('🔔 Step 3: Calling sendBillApprovedNotification...');
          final notificationSent = await notificationService
              .sendBillApprovedNotification(
                userId: finalCarpenterId,
                amount: amount,
                points: pointsEarned,
                billId: billId,
              );
          AppLogger.debug('🔔 Step 4: Notification call completed. Result: $notificationSent');

          if (notificationSent) {
            AppLogger.info('✅ Bill approved notification sent successfully');
            AppLogger.debug('✅ Notification queued in Firestore successfully');
          } else {
            AppLogger.warning(
              '⚠️ Bill approved notification failed to send (check logs above)',
            );
            AppLogger.debug('❌ Notification failed - user not found or no FCM token');
          }

          // Check for tier upgrade and send notification if tier changed
          if (oldTier != newTier) {
            AppLogger.info('Tier upgraded from $oldTier to $newTier');
            await notificationService.sendTierUpgradedNotification(
              userId: finalCarpenterId,
              newTier: newTier,
              points: newTotalPoints,
            );
          }

          // Check for points milestone
          await _checkAndNotifyMilestone(
            notificationService,
            finalCarpenterId,
            newTotalPoints,
          );
        } catch (e, stackTrace) {
          // Don't fail the approval if notification fails
          AppLogger.debug('❌❌❌ EXCEPTION IN NOTIFICATION CODE ❌❌❌');
          AppLogger.debug('   Error: $e');
          AppLogger.debug('   StackTrace: $stackTrace');
          AppLogger.warning(
            'Failed to send notification after bill approval: $e',
          );
          AppLogger.error('Notification error stacktrace', stackTrace);
        }
        AppLogger.debug('🔔 NOTIFICATION SECTION COMPLETED');

        return true;
      } on FirebaseException catch (fe) {
        AppLogger.debug('🔥🔥🔥 FIREBASE EXCEPTION DURING BATCH.COMMIT() 🔥🔥🔥');
        AppLogger.debug('   Code: ${fe.code}');
        AppLogger.debug('   Message: ${fe.message}');
        AppLogger.debug('   StackTrace: ${fe.stackTrace}');
        AppLogger.debug('   Bill ID: $billId');
        AppLogger.debug('   Carpenter ID: $finalCarpenterId');
        AppLogger.debug('   Amount: $amount');
        AppLogger.debug('   Points: $pointsEarned');
        AppLogger.error(
          '🔥 FirebaseException during batch.commit()',
          'Code: ${fe.code}, Message: ${fe.message}, StackTrace: ${fe.stackTrace}',
        );
        AppLogger.error('  Bill ID: $billId');
        AppLogger.error('  Carpenter ID: $finalCarpenterId');
        AppLogger.error('  Amount: $amount');
        AppLogger.error('  Points: $pointsEarned');
        AppLogger.error('=== APPROVE BILL FAILED (FirebaseException) ===');
        AppLogger.debug('═══════════════════════════════════════════════════════════');
        AppLogger.debug('❌ APPROVE BILL FAILED (FirebaseException)');
        AppLogger.debug('═══════════════════════════════════════════════════════════');
        throw Exception('Firebase error: ${fe.code} - ${fe.message}');
      }
    } catch (e, st) {
      AppLogger.debug('❌❌❌ EXCEPTION IN APPROVE BILL ❌❌❌');
      AppLogger.debug('   Error: $e');
      AppLogger.debug('   Type: ${e.runtimeType}');
      AppLogger.debug('   StackTrace:');
      AppLogger.debug('$st');
      AppLogger.debug('   Bill ID: $billId');
      AppLogger.debug('   Carpenter ID: $carpenterId');
      AppLogger.debug('   Amount: $amount');
      AppLogger.error('❌ Exception in approveBill', 'Error: $e');
      AppLogger.error('  Type: ${e.runtimeType}');
      AppLogger.error('  StackTrace:\n$st');
      AppLogger.error('  Bill ID: $billId');
      AppLogger.error('  Carpenter ID: $carpenterId');
      AppLogger.error('  Amount: $amount');
      AppLogger.error('=== APPROVE BILL FAILED (Exception) ===');
      AppLogger.debug('═══════════════════════════════════════════════════════════');
      AppLogger.debug('❌ APPROVE BILL FAILED (Exception)');
      AppLogger.debug('═══════════════════════════════════════════════════════════');
      return false;
    }
  }

  /// Reject bill
  Future<bool> rejectBill(String billId) async {
    try {
      // Get admin info from session (phone+pin auth)
      final adminPhone = await _sessionService.getPhoneNumber() ?? 'admin';
      final adminUserId = await _sessionService.getUserId() ?? 'admin';

      // Get bill data to extract amount and carpenterId
      final billDoc = await _firestore.collection('bills').doc(billId).get();
      final billData = billDoc.data();
      final carpenterId = billData?['carpenterId'] as String? ?? '';
      final amount = (billData?['amount'] as num?)?.toDouble() ?? 0.0;

      await _firestore.collection('bills').doc(billId).update({
        'status': 'rejected',
        'rejectedAt': FieldValue.serverTimestamp(),
        'rejectedBy': adminUserId,
        'rejectedByPhone': adminPhone,
      });

      AppLogger.info('Bill rejected: $billId');

      // Send notification after successful rejection
      if (carpenterId.isNotEmpty) {
        try {
          final notificationService = NotificationService();
          await notificationService.sendBillRejectedNotification(
            userId: carpenterId,
            amount: amount,
            billId: billId,
          );
        } catch (e) {
          // Don't fail the rejection if notification fails
          AppLogger.warning(
            'Failed to send notification after bill rejection: $e',
          );
        }
      }

      return true;
    } catch (e) {
      AppLogger.error('Error rejecting bill', e);
      return false;
    }
  }

  /// Withdraw/Cancel approved bill (Admin)
  /// Reverses the points that were added when the bill was approved
  Future<bool> withdrawBill(String billId) async {
    AppLogger.info('=== WITHDRAW BILL START ===');
    AppLogger.info('Input params: billId=$billId');

    try {
      // Step 1: Get bill document
      final billRef = _firestore.collection('bills').doc(billId);
      final billDoc = await billRef.get();

      if (!billDoc.exists) {
        AppLogger.error('withdrawBill: ❌ Bill not found', billId);
        return false;
      }

      final billData = billDoc.data()!;
      final status = billData['status'] as String? ?? '';
      final amount = (billData['amount'] as num?)?.toDouble() ?? 0.0;

      if (status != 'approved') {
        AppLogger.error(
          'withdrawBill: ❌ Bill is not approved (status: $status)',
          billId,
        );
        return false;
      }

      final carpenterId = billData['carpenterId'] as String? ?? '';
      if (carpenterId.isEmpty) {
        AppLogger.error('withdrawBill: ❌ Carpenter ID is empty', billId);
        return false;
      }

      final pointsEarned =
          (billData['pointsEarned'] as num?)?.toDouble() ?? 0.0;

      if (pointsEarned <= 0) {
        AppLogger.error(
          'withdrawBill: ❌ Invalid points earned: $pointsEarned',
          billId,
        );
        return false;
      }

      AppLogger.info(
        '  Bill found: carpenterId=$carpenterId, points=$pointsEarned',
      );

      // Step 2: Get user_points document (source of truth for points)
      final userRef = _firestore.collection('users').doc(carpenterId);
      final userPointsRef = _firestore.collection('user_points').doc(carpenterId);
      final userPointsDoc = await userPointsRef.get();

      final currentPointsRaw = userPointsDoc.exists
          ? (userPointsDoc.data()?['totalPoints'] ?? 0)
          : 0;
      final double currentPoints = currentPointsRaw is num
          ? currentPointsRaw.toDouble()
          : double.tryParse(currentPointsRaw.toString()) ?? 0.0;

      if (currentPoints < pointsEarned) {
        AppLogger.error(
          'withdrawBill: ❌ Insufficient points to withdraw (current: $currentPoints, required: $pointsEarned)',
          billId,
        );
        return false;
      }

      final newTotalPoints = currentPoints - pointsEarned;
      final newTier = _calculateTier(newTotalPoints.toInt());

      AppLogger.info('  Current points: $currentPoints');
      AppLogger.info('  Points to withdraw: $pointsEarned');
      AppLogger.info('  New total points: $newTotalPoints');
      AppLogger.info('  New tier: $newTier');

      // Step 4: Find and remove the history entry for this bill
      List<dynamic> updatedHistory = [];
      if (userPointsDoc.exists) {
        final existingData = userPointsDoc.data() ?? {};
        final existingHistory =
            existingData['pointsHistory'] as List<dynamic>? ?? [];

        // Remove the entry that matches this billId
        updatedHistory = existingHistory.where((entry) {
          final entryMap = entry as Map<String, dynamic>;
          final entryBillId = entryMap['billId'] as String?;
          return entryBillId != billId;
        }).toList();

        AppLogger.info(
          '  History entries: ${existingHistory.length} -> ${updatedHistory.length}',
        );
      }

      // Step 5: Get admin info
      final fbUser = FirebaseAuth.instance.currentUser;
      final sessionPhone = await _sessionService.getPhoneNumber();
      final sessionUserId = await _sessionService.getUserId();
      final adminPhone = sessionPhone ?? fbUser?.phoneNumber ?? 'admin';
      final adminUserId = sessionUserId ?? fbUser?.uid ?? 'admin';

      // Step 6: Create batch operations
      final batch = _firestore.batch();

      // 1. Update bill status to 'withdrawn'
      batch.update(billRef, {
        'status': 'withdrawn',
        'withdrawnAt': FieldValue.serverTimestamp(),
        'withdrawnBy': adminUserId,
        'withdrawnByPhone': adminPhone,
      });

      // 2. Update user document
      batch.set(userRef, {
        'totalPoints': newTotalPoints,
        'tier': newTier,
        'lastUpdated': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      // 3. Update user_points document
      if (userPointsDoc.exists) {
        batch.set(userPointsRef, {
          'userId': carpenterId,
          'totalPoints': newTotalPoints,
          'tier': newTier,
          'lastUpdated': FieldValue.serverTimestamp(),
          'pointsHistory': updatedHistory,
        }, SetOptions(merge: false));
      } else {
        // Create new document if it doesn't exist
        batch.set(userPointsRef, {
          'userId': carpenterId,
          'totalPoints': newTotalPoints,
          'tier': newTier,
          'lastUpdated': FieldValue.serverTimestamp(),
          'pointsHistory': updatedHistory,
        });
      }

      // Step 7: Commit batch
      await batch.commit();

      AppLogger.info('✅ Bill withdrawn successfully: $billId');
      AppLogger.info(
        '✅ Points withdrawn: $pointsEarned from user $carpenterId',
      );
      AppLogger.info('=== WITHDRAW BILL SUCCESS ===');

      // Send notification after successful withdrawal
      try {
        final notificationService = NotificationService();
        await notificationService.sendPointsWithdrawnNotification(
          userId: carpenterId,
          points: pointsEarned,
          amount: amount,
          billId: billId,
        );
      } catch (e) {
        // Don't fail the withdrawal if notification fails
        AppLogger.warning(
          'Failed to send notification after points withdrawal: $e',
        );
      }

      return true;
    } catch (e, st) {
      AppLogger.error('❌ Exception in withdrawBill', 'Error: $e');
      AppLogger.error('  StackTrace:\n$st');
      AppLogger.error('  Bill ID: $billId');
      AppLogger.error('=== WITHDRAW BILL FAILED ===');
      return false;
    }
  }

  /// Get today's date string in YYYY-MM-DD format
  String _getTodayDateString() {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  }

  /// Check for duplicate bill with same (vendorName, siteName, amount, billDate)
  Future<Map<String, dynamic>?> checkDuplicateBill({
    required String carpenterId,
    String? vendorName,
    required String siteName,
    required double billAmount,
    required DateTime billDate,
  }) async {
    try {
      AppLogger.info('🔍 Checking for duplicate bill:');
      AppLogger.info('   carpenterId: $carpenterId');
      AppLogger.info('   vendorName: $vendorName');
      AppLogger.info('   siteName: $siteName');
      AppLogger.info('   amount: $billAmount');
      AppLogger.info('   billDate: ${billDate.toIso8601String()}');

      // Normalize billDate to date-only (ignore time)
      final billDateOnly = DateTime(billDate.year, billDate.month, billDate.day);
      final billDateStartOfDay = Timestamp.fromDate(billDateOnly);
      final billDateEndOfDay = Timestamp.fromDate(
        billDateOnly.add(const Duration(days: 1)),
      );

      // Query for bills with exact match: carpenterId, siteName, amount, billDate (date only), not withdrawn
      final query = await _firestore
          .collection('bills')
          .where('carpenterId', isEqualTo: carpenterId)
          .where('siteName', isEqualTo: siteName)
          .where('amount', isEqualTo: billAmount)
          .where('billDate', isGreaterThanOrEqualTo: billDateStartOfDay)
          .where('billDate', isLessThan: billDateEndOfDay)
          .where('status', isNotEqualTo: 'withdrawn')
          .limit(1)
          .get();

      if (query.docs.isNotEmpty) {
        final duplicateBill = query.docs.first.data();
        AppLogger.info('❌ DUPLICATE FOUND!');
        AppLogger.info('   Existing bill ID: ${duplicateBill['billId']}');
        AppLogger.info('   Status: ${duplicateBill['status']}');

        return duplicateBill;
      }

      AppLogger.info('✅ No duplicate found');
      return null;
    } catch (e) {
      AppLogger.error('Error checking duplicate bill', e);
      // Don't throw - return null and let user retry
      return null;
    }
  }

  /// User bills
  Future<List<Map<String, dynamic>>> getUserBills(String carpenterId) async {
    try {
      final query = await _firestore
          .collection('bills')
          .where('carpenterId', isEqualTo: carpenterId)
          .orderBy('createdAt', descending: true)
          .get();

      return query.docs.map((doc) => {'id': doc.id, ...doc.data()}).toList();
    } catch (e) {
      AppLogger.error('Error getting bills', e);
      return [];
    }
  }

  /// Determine tier
  String _calculateTier(int points) {
    if (points >= 10000) return 'Platinum';
    if (points >= 5000) return 'Gold';
    if (points >= 2000) return 'Silver';
    return 'Bronze';
  }

  /// Check for points milestone and send notification if reached
  Future<void> _checkAndNotifyMilestone(
    NotificationService notificationService,
    String userId,
    double newPoints,
  ) async {
    try {
      // Define milestone thresholds
      const milestones = [
        1000,
        2500,
        5000,
        7500,
        10000,
        15000,
        20000,
        25000,
        50000,
      ];

      // Check if new points crossed any milestone
      for (final milestone in milestones) {
        // Get user's last milestone from Firestore
        final userDoc = await _firestore.collection('users').doc(userId).get();
        final lastMilestone = userDoc.exists
            ? (userDoc.data()?['lastMilestone'] as int? ?? 0)
            : 0;

        // If we crossed this milestone and haven't notified for it yet
        if (newPoints >= milestone && lastMilestone < milestone) {
          // Send milestone notification
          await notificationService.sendPointsMilestoneNotification(
            userId: userId,
            points: newPoints,
            milestone: milestone,
          );

          // Update last milestone in Firestore
          await _firestore.collection('users').doc(userId).set({
            'lastMilestone': milestone,
          }, SetOptions(merge: true));

          AppLogger.info('Milestone notification sent: $milestone points');
          break; // Only notify for the highest milestone reached
        }
      }
    } catch (e) {
      AppLogger.warning('Error checking milestone: $e');
      // Don't throw - milestone checking is not critical
    }
  }
}
