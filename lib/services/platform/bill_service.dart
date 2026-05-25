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
    String? billNumber,
    String? notes,
  }) async {
    try {
      AppLogger.info('BillService: === SUBMITTING BILL ===');
      AppLogger.info('  carpenterId: $carpenterId');
      AppLogger.info('  carpenterPhone: $carpenterPhone');
      AppLogger.info('  amount: $amount');
      AppLogger.info('  storeName: $storeName');
      AppLogger.info('  billNumber: $billNumber');

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
        'storeName': storeName ?? '',
        'billNumber': billNumber ?? '',
        'notes': notes ?? '',
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
    String? billNumber,
    String? notes,
  }) async {
    try {
      AppLogger.info(
        'BillService: === ADMIN SUBMITTING BILL FOR CARPENTER ===',
      );
      AppLogger.info('  carpenterId: $carpenterId');
      AppLogger.info('  carpenterPhone: $carpenterPhone');
      AppLogger.info('  adminId: $adminId');
      AppLogger.info('  adminPhone: $adminPhone');
      AppLogger.info('  amount: $amount');
      AppLogger.info('  storeName: $storeName');
      AppLogger.info('  billNumber: $billNumber');

      final billRef = _firestore.collection('bills').doc();
      final billId = billRef.id;
      AppLogger.info('  Generated billId: $billId');

      String? imageUrl;
      if (imageFile != null) {
        AppLogger.info('  Uploading bill image...');
        imageUrl = await uploadBillImage(imageFile, billId);
        AppLogger.info('  Image uploaded: $imageUrl');
      }

      // Use carpenter's branchId (looked up from their user doc) so the bill
      // is always stamped with the correct branch — not the admin's session branch.
      String? carpenterBranchId;
      try {
        final carpenterDoc =
            await _firestore.collection('users').doc(carpenterId).get();
        carpenterBranchId = carpenterDoc.data()?['branchId'] as String?;
        if (carpenterBranchId == null) {
          final q = await _firestore
              .collection('users')
              .where('phone', isEqualTo: carpenterPhone)
              .limit(1)
              .get();
          if (q.docs.isNotEmpty) {
            carpenterBranchId = q.docs.first.data()['branchId'] as String?;
          }
        }
      } catch (_) {}
      // Fallback to admin's session branch if carpenter doc lookup fails
      carpenterBranchId ??= await _sessionService.getBranchId();

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
        'storeName': storeName ?? '',
        'billNumber': billNumber ?? '',
        'notes': notes ?? '',
        'submittedBy': 'admin',
        'adminId': adminId,
        'adminPhone': adminPhone,
        if (adminName != null) 'adminName': adminName,
        'createdAt': FieldValue.serverTimestamp(),
      };

      AppLogger.info('  Saving to Firestore: bills/$billId');
      await billRef.set(billData);

      // Verify the save by reading back
      final verifyDoc = await billRef.get();
      if (verifyDoc.exists) {
        AppLogger.info(
          'BillService: ✅ Admin bill saved and verified successfully!',
        );
        AppLogger.info(
          '  Verified data: carpenterId=${verifyDoc.data()?['carpenterId']}, status=${verifyDoc.data()?['status']}, submittedBy=${verifyDoc.data()?['submittedBy']}',
        );
      } else {
        AppLogger.error(
          'BillService: ❌ Bill document not found after save!',
          null,
        );
      }

      return true;
    } catch (e) {
      AppLogger.error('BillService: ❌ Error submitting bill for carpenter', e);
      return false;
    }
  }

  /// Approve bill (Admin)
  Future<bool> approveBill(
    String billId,
    String carpenterId,
    double amount,
  ) async {
    AppLogger.debug('═══════════════════════════════════════════════════════════');
    AppLogger.debug('🚀 APPROVE BILL START');
    AppLogger.debug('═══════════════════════════════════════════════════════════');
    AppLogger.debug('📋 Input params:');
    AppLogger.debug('   billId: "$billId"');
    AppLogger.debug('   carpenterId: "$carpenterId"');
    AppLogger.debug('   amount: $amount');
    AppLogger.debug('═══════════════════════════════════════════════════════════');

    AppLogger.info('=== APPROVE BILL START ===');
    AppLogger.info(
      'Input params: billId=$billId, carpenterId=$carpenterId, amount=$amount',
    );

    try {
      // Validate inputs
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

      final pointsEarned = (amount / 1000).floor();
      AppLogger.debug('   ✓ pointsEarned calculated: $pointsEarned');
      AppLogger.info('  ✓ pointsEarned calculated: $pointsEarned');

      // Verify bill exists
      AppLogger.debug('📄 Step 1: Fetching bill document...');
      AppLogger.info('Step 1: Fetching bill document...');
      final billRef = _firestore.collection('bills').doc(billId);
      AppLogger.debug('   Bill ref path: bills/$billId');
      AppLogger.info('  Bill ref path: bills/$billId');

      final billDoc = await billRef.get();
      AppLogger.debug('   Bill doc exists: ${billDoc.exists}');
      AppLogger.info('  Bill doc exists: ${billDoc.exists}');

      if (!billDoc.exists) {
        AppLogger.debug('❌ ERROR: Bill not found! billId: "$billId"');
        AppLogger.error('approveBill: ❌ Bill not found', billId);
        return false;
      }

      // Check if bill is already approved or rejected
      AppLogger.debug('📊 Step 2: Checking bill status...');
      AppLogger.info('Step 2: Checking bill status...');
      final billData = billDoc.data();
      AppLogger.debug('   Bill data keys: ${billData?.keys.toList()}');
      AppLogger.info('  Bill data: $billData');

      if (billData != null) {
        final currentStatus = billData['status'] as String? ?? 'pending';
        AppLogger.debug('   Current status: "$currentStatus"');
        AppLogger.info('  Current status: $currentStatus');

        if (currentStatus == 'approved') {
          AppLogger.debug('❌ ERROR: Bill already approved!');
          AppLogger.error('approveBill: ❌ Bill already approved', billId);
          return false;
        }
        if (currentStatus == 'rejected') {
          AppLogger.debug('❌ ERROR: Bill already rejected!');
          AppLogger.error('approveBill: ❌ Bill already rejected', billId);
          return false;
        }
        AppLogger.debug('   ✓ Bill status is pending, can proceed');
        AppLogger.info('  ✓ Bill status is pending, can proceed');
      } else {
        AppLogger.debug('   ⚠️ Bill data is null, assuming pending status');
        AppLogger.info('  ⚠️ Bill data is null, assuming pending status');
      }

      // If carpenterId passed is empty, try to read from bill doc
      AppLogger.info('Step 3: Resolving carpenterId...');
      String finalCarpenterId = carpenterId;
      AppLogger.info(
        '  Initial carpenterId: "$carpenterId" (isEmpty: ${carpenterId.isEmpty})',
      );

      if (finalCarpenterId.isEmpty && billData != null) {
        finalCarpenterId = billData['carpenterId'] ?? '';
        AppLogger.info('  Read carpenterId from bill: "$finalCarpenterId"');
      }

      // Validate carpenterId is not empty
      if (finalCarpenterId.isEmpty) {
        AppLogger.error(
          'approveBill: ❌ Carpenter ID is empty after resolution',
          billId,
        );
        AppLogger.error('  billData keys: ${billData?.keys.toList()}');
        return false;
      }
      AppLogger.info('  ✓ Final carpenterId: $finalCarpenterId');

      // Get admin info from session (phone+pin auth) or fallback to FirebaseAuth
      AppLogger.info('Step 4: Getting admin info...');
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

      AppLogger.info('Step 5: Fetching user document...');
      final userRef = _firestore.collection('users').doc(finalCarpenterId);
      AppLogger.info('  User ref path: users/$finalCarpenterId');

      final userDoc = await userRef.get();
      AppLogger.info('  User doc exists: ${userDoc.exists}');
      if (userDoc.exists) {
        AppLogger.info('  User data: ${userDoc.data()}');
      }

      // Determine current points (0 if user not found)
      AppLogger.info('Step 6: Calculating points...');
      final dynamic currentPointsRaw;
      if (userDoc.exists) {
        currentPointsRaw = userDoc.data()?['totalPoints'] ?? 0;
        AppLogger.info(
          '  Found totalPoints in user doc: $currentPointsRaw (type: ${currentPointsRaw.runtimeType})',
        );
      } else {
        currentPointsRaw = 0;
        AppLogger.info('  User not found, using 0 as current points');
      }

      final int currentPoints = currentPointsRaw is num
          ? currentPointsRaw.toInt()
          : int.tryParse(currentPointsRaw.toString()) ?? 0;
      AppLogger.info('  ✓ Current points (int): $currentPoints');
      AppLogger.info('  ✓ Points to add: $pointsEarned');

      // Get old tier before calculating new tier (for tier upgrade notification)
      final oldTier = userDoc.exists
          ? (userDoc.data()?['tier'] as String? ?? 'Bronze')
          : 'Bronze';

      final newTotalPoints = currentPoints + pointsEarned;
      final newTier = _calculateTier(newTotalPoints);
      AppLogger.info('  ✓ Old tier: $oldTier');
      AppLogger.info('  ✓ New total points: $newTotalPoints');
      AppLogger.info('  ✓ New tier: $newTier');

      // Points history entry
      AppLogger.debug('📝 Step 7: Creating points history entry...');
      AppLogger.info('Step 7: Creating points history entry...');
      // Use Timestamp.now() instead of FieldValue.serverTimestamp() because
      // FieldValue.serverTimestamp() cannot be used inside arrays when using batch.set()
      final newHistoryEntry = {
        'points': pointsEarned,
        'reason': 'Bill approval',
        'date': Timestamp.now(), // Changed from FieldValue.serverTimestamp()
        'billId': billId,
        'amount': amount,
      };
      AppLogger.debug('   History entry: $newHistoryEntry');
      AppLogger.info('  History entry: $newHistoryEntry');

      AppLogger.info('Step 8: Fetching user_points document...');
      final userPointsRef = _firestore
          .collection('user_points')
          .doc(finalCarpenterId);
      AppLogger.info('  User points ref path: user_points/$finalCarpenterId');

      final userPointsDoc = await userPointsRef.get();
      AppLogger.info('  User points doc exists: ${userPointsDoc.exists}');
      if (userPointsDoc.exists) {
        AppLogger.info('  User points data: ${userPointsDoc.data()}');
      }

      AppLogger.info('Step 9: Creating batch operations...');
      final batch = _firestore.batch();
      AppLogger.info('  Batch created');

      // 1. Update bill (always update)
      AppLogger.info('  Batch Operation 1: Update bill doc');
      final billUpdateData = {
        'status': 'approved',
        'pointsEarned': pointsEarned,
        'approvedBy': adminUserId,
        'approvedByPhone': adminPhone,
        'approvedAt': FieldValue.serverTimestamp(),
        'approvedDate': _getTodayDateString(),
      };
      AppLogger.info('    Bill update data: $billUpdateData');
      batch.update(billRef, billUpdateData);
      AppLogger.info('    ✓ Bill update added to batch');

      // 2. Update or create user account with merged fields
      AppLogger.info('  Batch Operation 2: Update/create users doc');
      final userUpdateData = {
        'totalPoints': newTotalPoints,
        'tier': newTier,
        'lastUpdated': FieldValue.serverTimestamp(),
      };
      AppLogger.info('    User update data: $userUpdateData');
      batch.set(userRef, userUpdateData, SetOptions(merge: true));
      AppLogger.info('    ✓ User update added to batch (merge: true)');

      // 3. Update user_points
      AppLogger.info('  Batch Operation 3: Update/create user_points doc');
      if (userPointsDoc.exists) {
        // Get existing history to merge with new entry
        final existingData = userPointsDoc.data() ?? {};
        AppLogger.info('    Existing user_points data: $existingData');

        final existingHistory =
            existingData['pointsHistory'] as List<dynamic>? ?? [];
        AppLogger.info(
          '    Existing history length: ${existingHistory.length}',
        );

        // Check if userId exists in existing document (required by Firestore rules)
        final existingUserId = existingData['userId'] as String?;
        AppLogger.info('    Existing userId: "$existingUserId"');
        AppLogger.info('    Expected userId: "$finalCarpenterId"');
        AppLogger.info(
          '    userId matches: ${existingUserId == finalCarpenterId}',
        );

        if (existingUserId == null || existingUserId != finalCarpenterId) {
          // If userId is missing or doesn't match, use set to fix it
          // Merge existing history with new entry
          AppLogger.info('    Using batch.set() (userId missing or mismatch)');
          final userPointsSetData = {
            'userId': finalCarpenterId, // Ensure userId matches document ID
            'totalPoints': newTotalPoints,
            'tier': newTier,
            'lastUpdated': FieldValue.serverTimestamp(),
            'pointsHistory': [...existingHistory, newHistoryEntry],
          };
          AppLogger.info('    User points set data: $userPointsSetData');
          final historyList = userPointsSetData['pointsHistory'] as List;
          AppLogger.info('    New history length: ${historyList.length}');
          batch.set(userPointsRef, userPointsSetData, SetOptions(merge: false));
          AppLogger.info('    ✓ User points set added to batch');
        } else {
          // userId exists and matches, can use update with arrayUnion
          AppLogger.info(
            '    Using batch.update() with arrayUnion (userId matches)',
          );
          final userPointsUpdateData = {
            'totalPoints': newTotalPoints,
            'tier': newTier,
            'lastUpdated': FieldValue.serverTimestamp(),
            'pointsHistory': FieldValue.arrayUnion([newHistoryEntry]),
          };
          AppLogger.info('    User points update data: $userPointsUpdateData');
          batch.update(userPointsRef, userPointsUpdateData);
          AppLogger.info('    ✓ User points update added to batch');
        }
      } else {
        AppLogger.info('    User points doc does not exist, creating new');
        final userPointsCreateData = {
          'userId': finalCarpenterId,
          'totalPoints': newTotalPoints,
          'tier': newTier,
          'lastUpdated': FieldValue.serverTimestamp(),
          'pointsHistory': [newHistoryEntry],
        };
        AppLogger.info('    User points create data: $userPointsCreateData');
        batch.set(userPointsRef, userPointsCreateData);
        AppLogger.info('    ✓ User points create added to batch');
      }

      AppLogger.debug('💾 Step 10: Committing batch...');
      AppLogger.debug('   Total batch operations: 3');
      AppLogger.info('Step 10: Committing batch...');
      AppLogger.info('  Total batch operations: 3');
      try {
        AppLogger.debug('   Attempting batch.commit()...');
        await batch.commit();
        AppLogger.debug('✅✅✅ BATCH COMMITTED SUCCESSFULLY! ✅✅✅');
        AppLogger.debug(
          '✅ Bill approved: $billId (Points: $pointsEarned) for user $finalCarpenterId',
        );
        AppLogger.info('✅ Batch committed successfully!');
        AppLogger.info(
          '✅ Bill approved: $billId (Points: $pointsEarned) for user $finalCarpenterId',
        );
        AppLogger.info('=== APPROVE BILL SUCCESS ===');
        AppLogger.debug('═══════════════════════════════════════════════════════════');
        AppLogger.debug('✅ APPROVE BILL SUCCESS');
        AppLogger.debug('═══════════════════════════════════════════════════════════');
        AppLogger.debug('🔔 NOTIFICATION SECTION STARTING...');
        AppLogger.debug('   Carpenter ID: $finalCarpenterId');

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

      final pointsEarned = (billData['pointsEarned'] as num?)?.toInt() ?? 0;

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

      // Step 2: Get user document
      final userRef = _firestore.collection('users').doc(carpenterId);
      final userDoc = await userRef.get();

      final currentPointsRaw = userDoc.exists
          ? (userDoc.data()?['totalPoints'] ?? 0)
          : 0;
      final int currentPoints = currentPointsRaw is num
          ? currentPointsRaw.toInt()
          : int.tryParse(currentPointsRaw.toString()) ?? 0;

      if (currentPoints < pointsEarned) {
        AppLogger.error(
          'withdrawBill: ❌ Insufficient points to withdraw (current: $currentPoints, required: $pointsEarned)',
          billId,
        );
        return false;
      }

      final newTotalPoints = currentPoints - pointsEarned;
      final newTier = _calculateTier(newTotalPoints);

      AppLogger.info('  Current points: $currentPoints');
      AppLogger.info('  Points to withdraw: $pointsEarned');
      AppLogger.info('  New total points: $newTotalPoints');
      AppLogger.info('  New tier: $newTier');

      // Step 3: Get user_points document
      final userPointsRef = _firestore
          .collection('user_points')
          .doc(carpenterId);
      final userPointsDoc = await userPointsRef.get();

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
    int newPoints,
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
