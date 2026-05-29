import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io';
import '../../core/logger.dart';
import '../auth/session_service.dart';
import '../notifications/notification_service.dart';

class OfferService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final SessionService _sessionService = SessionService();

  /// Upload offer banner to Firebase Storage
  Future<String?> uploadOfferBanner(File imageFile) async {
    try {
      final offerId = _firestore.collection('offers').doc().id;
      final ref = _storage.ref().child('offer_banners/$offerId.jpg');

      AppLogger.info('Uploading offer banner: offer_banners/$offerId.jpg');

      final uploadTask = await ref.putFile(
        imageFile,
        SettableMetadata(
          contentType: 'image/jpeg',
          customMetadata: {
            'offerId': offerId,
            'uploadedAt': DateTime.now().toIso8601String(),
          },
        ),
      );

      final imageUrl = await uploadTask.ref.getDownloadURL();
      AppLogger.info('Offer banner uploaded: $imageUrl');
      return imageUrl;
    } on FirebaseException catch (e) {
      AppLogger.error(
        'Firebase Storage error',
        'Code: ${e.code}, Message: ${e.message}',
      );
      if (e.code == 'storage/unauthorized') {
        throw Exception(
          'Storage access denied. Please check Firebase Storage rules.',
        );
      } else if (e.code == 'storage/canceled') {
        throw Exception('Upload was cancelled');
      } else if (e.code == 'storage/unknown') {
        throw Exception(
          'Firebase Storage is not configured. Please enable Storage in Firebase Console.',
        );
      }
      throw Exception('Failed to upload banner: ${e.message}');
    } catch (e) {
      AppLogger.error('Error uploading offer banner', e);
      throw Exception('Failed to upload banner: $e');
    }
  }

  /// Delete banner from Firebase Storage
  Future<void> _deleteBannerIfExists(String? bannerUrl) async {
    if (bannerUrl == null || bannerUrl.isEmpty) return;

    try {
      // Extract path from URL and delete
      final ref = _storage.refFromURL(bannerUrl);
      await ref.delete();
      AppLogger.info('Deleted old banner: $bannerUrl');
    } catch (e) {
      AppLogger.error('Error deleting banner', e);
      // Don't throw - banner deletion is not critical
    }
  }

  /// Create a new offer
  Future<bool> createOffer({
    required String title,
    String? description,
    int points = 0,
    String? bannerUrl,
    bool isActive = true,
    DateTime? validUntil,
  }) async {
    try {
      AppLogger.info('Creating offer: $title with $points points');

      final offerRef = _firestore.collection('offers').doc();
      final offerId = offerRef.id;

      // Get admin info from session (phone+pin auth)
      final adminPhone = await _sessionService.getPhoneNumber() ?? 'admin';
      final adminUserId = await _sessionService.getUserId() ?? 'admin';

      await offerRef.set({
        'offerId': offerId, // Add offerId field for consistency
        'title': title,
        'description': description ?? '',
        'points': points,
        'bannerUrl': bannerUrl ?? '',
        'isActive': isActive,
        'validUntil': validUntil != null
            ? Timestamp.fromDate(validUntil)
            : null,
        'createdBy': adminUserId,
        'createdByPhone': adminPhone,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      AppLogger.info('Offer created successfully: $offerId');

      // Send broadcast notification to all users if offer is active
      if (isActive) {
        try {
          final notificationService = NotificationService();
          await notificationService.sendBroadcastNewOfferNotification(
            offerTitle: title,
            points: points,
          );
        } catch (e) {
          // Don't fail offer creation if notification fails
          AppLogger.warning(
            'Failed to send broadcast notification for new offer: $e',
          );
        }
      }

      return true;
    } on FirebaseException catch (e) {
      AppLogger.error(
        'Firebase error creating offer',
        'Code: ${e.code}, Message: ${e.message}',
      );
      return false;
    } catch (e) {
      AppLogger.error('Error creating offer', e.toString());
      return false;
    }
  }

  /// Update an existing offer
  Future<bool> updateOffer({
    required String offerId,
    required String title,
    String? description,
    int? points,
    String? bannerUrl,
    bool isActive = true,
    DateTime? validUntil,
    String? oldBannerUrl,
  }) async {
    try {
      AppLogger.info('Updating offer: $offerId');

      // Delete old banner if a new one is uploaded
      if (bannerUrl != null &&
          oldBannerUrl != null &&
          bannerUrl != oldBannerUrl) {
        await _deleteBannerIfExists(oldBannerUrl);
      }

      final offerRef = _firestore.collection('offers').doc(offerId);

      // Get admin info from session (phone+pin auth)
      final adminPhone = await _sessionService.getPhoneNumber() ?? 'admin';
      final adminUserId = await _sessionService.getUserId() ?? 'admin';

      final updateData = <String, dynamic>{
        'title': title,
        'isActive': isActive,
        'updatedAt': FieldValue.serverTimestamp(),
        'updatedBy': adminUserId,
        'updatedByPhone': adminPhone,
      };

      // Only update description if provided
      if (description != null) {
        updateData['description'] = description;
      }

      // Only update points if provided
      if (points != null) {
        updateData['points'] = points;
      }

      // Only update bannerUrl if provided
      if (bannerUrl != null) {
        updateData['bannerUrl'] = bannerUrl;
      }

      // Update validUntil (can be null to remove the date)
      if (validUntil != null) {
        updateData['validUntil'] = Timestamp.fromDate(validUntil);
      } else {
        updateData['validUntil'] = null;
      }

      await offerRef.update(updateData);

      AppLogger.info('Offer updated successfully: $offerId');
      return true;
    } on FirebaseException catch (e) {
      AppLogger.error(
        'Firebase error updating offer',
        'Code: ${e.code}, Message: ${e.message}',
      );
      return false;
    } catch (e) {
      AppLogger.error('Error updating offer', e.toString());
      return false;
    }
  }

  /// Delete an offer
  Future<bool> deleteOffer(String offerId, String? bannerUrl) async {
    try {
      AppLogger.info('Deleting offer: $offerId');

      // Delete banner from storage
      await _deleteBannerIfExists(bannerUrl);

      // Delete offer document
      await _firestore.collection('offers').doc(offerId).delete();

      AppLogger.info('Offer deleted successfully: $offerId');
      return true;
    } on FirebaseException catch (e) {
      AppLogger.error(
        'Firebase error deleting offer',
        'Code: ${e.code}, Message: ${e.message}',
      );
      return false;
    } catch (e) {
      AppLogger.error('Error deleting offer', e.toString());
      return false;
    }
  }

  /// Get all active offers for carpenters
  Future<List<Map<String, dynamic>>> getActiveOffers() async {
    try {
      final now = Timestamp.now();

      final query = await _firestore
          .collection('offers')
          .where('isActive', isEqualTo: true)
          .get();

      // Filter out expired offers
      final offers = query.docs
          .map((doc) => {'id': doc.id, ...doc.data()})
          .where((offer) {
            final validUntil = offer['validUntil'] as Timestamp?;
            if (validUntil == null) return true; // No expiry date
            return validUntil.compareTo(now) > 0; // Not expired
          })
          .toList();

      return offers;
    } catch (e) {
      AppLogger.error('Error getting active offers', e);
      return [];
    }
  }

  /// Get all offers (for admin)
  Future<List<Map<String, dynamic>>> getAllOffers() async {
    try {
      final query = await _firestore
          .collection('offers')
          .get();

      final docs = query.docs.toList()
        ..sort((a, b) {
          final at = a.data()['createdAt'];
          final bt = b.data()['createdAt'];
          if (at == null && bt == null) return 0;
          if (at == null) return 1;
          if (bt == null) return -1;
          return (bt as dynamic).compareTo(at as dynamic);
        });
      return docs.map((doc) => {'id': doc.id, ...doc.data()}).toList();
    } catch (e) {
      AppLogger.error('Error getting all offers', e);
      return [];
    }
  }

  /// Redeem an offer (deduct points from carpenter)
  Future<bool> redeemOffer({
    required String offerId,
    required String carpenterId,
    required int pointsRequired,
  }) async {
    try {
      AppLogger.info('Redeeming offer: $offerId for carpenter: $carpenterId');

      // Get carpenter's current points
      final userRef = _firestore.collection('users').doc(carpenterId);
      final userDoc = await userRef.get();

      if (!userDoc.exists) {
        AppLogger.error('User not found', 'carpenterId: $carpenterId');
        throw Exception('Carpenter not found');
      }

      final userData = userDoc.data()!;
      final currentPoints = (userData['totalPoints'] ?? 0) as int;

      if (currentPoints < pointsRequired) {
        AppLogger.error(
          'Insufficient points',
          'Required: $pointsRequired, Available: $currentPoints',
        );
        throw Exception('Insufficient points');
      }

      final newTotalPoints = currentPoints - pointsRequired;
      final newTier = _calculateTier(newTotalPoints);

      // Get offer details for notification
      final offerDoc = await _firestore.collection('offers').doc(offerId).get();
      final offerTitle = offerDoc.exists
          ? (offerDoc.data()?['title'] as String? ?? 'Offer')
          : 'Offer';

      // Use batch for atomic operations
      final batch = _firestore.batch();

      // 1. Update user points and tier
      batch.set(userRef, {
        'totalPoints': newTotalPoints,
        'tier': newTier,
        'lastUpdated': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      // 2. Create redemption record
      final redemptionRef = _firestore.collection('offer_redemptions').doc();
      batch.set(redemptionRef, {
        'offerId': offerId,
        'carpenterId': carpenterId,
        'pointsUsed': pointsRequired,
        'redeemedAt': FieldValue.serverTimestamp(),
        'status': 'redeemed',
      });

      // 3. Update user_points collection
      final userPointsRef = _firestore
          .collection('user_points')
          .doc(carpenterId);
      final newHistoryEntry = {
        'points': -pointsRequired,
        'reason': 'Offer redemption',
        'date': FieldValue.serverTimestamp(),
        'offerId': offerId,
      };

      final userPointsDoc = await userPointsRef.get();
      if (userPointsDoc.exists) {
        batch.update(userPointsRef, {
          'totalPoints': newTotalPoints,
          'tier': newTier,
          'lastUpdated': FieldValue.serverTimestamp(),
          'pointsHistory': FieldValue.arrayUnion([newHistoryEntry]),
        });
      } else {
        batch.set(userPointsRef, {
          'userId': carpenterId,
          'totalPoints': newTotalPoints,
          'tier': newTier,
          'lastUpdated': FieldValue.serverTimestamp(),
          'pointsHistory': [newHistoryEntry],
        });
      }

      await batch.commit();

      AppLogger.info('Offer redeemed successfully: $offerId');

      // Send notification after successful redemption
      try {
        final notificationService = NotificationService();
        await notificationService.sendOfferRedeemedNotification(
          userId: carpenterId,
          offerTitle: offerTitle,
          points: pointsRequired,
        );

        // Check for tier downgrade (unlikely but possible) - we don't notify on downgrade
        // Tier upgrade is already handled in bill approval
      } catch (e) {
        // Don't fail the redemption if notification fails
        AppLogger.warning(
          'Failed to send notification after offer redemption: $e',
        );
      }

      return true;
    } on FirebaseException catch (e) {
      AppLogger.error(
        'Firebase error redeeming offer',
        'Code: ${e.code}, Message: ${e.message}',
      );
      return false;
    } catch (e) {
      AppLogger.error('Error redeeming offer', e.toString());
      return false;
    }
  }

  /// Get carpenter's redemption history
  Future<List<Map<String, dynamic>>> getRedemptionHistory(
    String carpenterId,
  ) async {
    try {
      final query = await _firestore
          .collection('offer_redemptions')
          .where('carpenterId', isEqualTo: carpenterId)
          .orderBy('redeemedAt', descending: true)
          .get();

      return query.docs.map((doc) => {'id': doc.id, ...doc.data()}).toList();
    } catch (e) {
      AppLogger.error('Error getting redemption history', e);
      return [];
    }
  }

  /// Calculate tier based on points
  String _calculateTier(int points) {
    if (points >= 10000) {
      return 'Platinum';
    } else if (points >= 5000) {
      return 'Gold';
    } else if (points >= 2000) {
      return 'Silver';
    } else {
      return 'Bronze';
    }
  }
}
