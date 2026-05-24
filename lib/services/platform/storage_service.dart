import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import '../../core/logger.dart';

class StorageService {
  final FirebaseStorage _storage = FirebaseStorage.instance;

  /// Upload user profile image to Firebase Storage
  /// Returns the download URL of the uploaded image
  Future<String?> uploadProfileImage({
    required String phoneNumber,
    required File imageFile,
  }) async {
    try {
      // Create a unique filename using phone number and timestamp
      final String fileName =
          'profile_${phoneNumber}_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final String filePath = 'profile_images/$fileName';

      AppLogger.info('Uploading profile image: $filePath');
      AppLogger.info('Storage bucket: ${_storage.bucket}');

      // Create reference to storage location
      final Reference ref = _storage.ref().child(filePath);

      // Upload file with metadata
      final UploadTask uploadTask = ref.putFile(
        imageFile,
        SettableMetadata(
          contentType: 'image/jpeg',
          customMetadata: {
            'userId': phoneNumber,
            'uploadedAt': DateTime.now().toIso8601String(),
          },
        ),
      );

      // Wait for upload to complete
      final TaskSnapshot snapshot = await uploadTask;

      // Get download URL
      final String downloadUrl = await snapshot.ref.getDownloadURL();

      AppLogger.info('Profile image uploaded successfully: $downloadUrl');
      return downloadUrl;
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
      throw Exception('Failed to upload image: ${e.message}');
    } catch (e) {
      AppLogger.error('Error uploading profile image', e);
      throw Exception('Failed to upload image: $e');
    }
  }

  /// Delete user profile image from Firebase Storage
  Future<bool> deleteProfileImage(String imageUrl) async {
    try {
      // Extract file path from URL
      final Uri uri = Uri.parse(imageUrl);
      final String path = uri.pathSegments.last;

      AppLogger.info('Deleting profile image: $path');

      // Create reference and delete
      final Reference ref = _storage.ref().child('profile_images/$path');
      await ref.delete();

      AppLogger.info('Profile image deleted successfully');
      return true;
    } catch (e) {
      AppLogger.error('Error deleting profile image', e);
      return false;
    }
  }

  /// Delete old profile image before uploading new one
  Future<void> deleteOldProfileImageIfExists(String? oldImageUrl) async {
    if (oldImageUrl != null && oldImageUrl.isNotEmpty) {
      try {
        // Only delete if it's a Firebase Storage URL
        if (oldImageUrl.contains('firebasestorage.googleapis.com')) {
          await deleteProfileImage(oldImageUrl);
        }
      } catch (e) {
        AppLogger.warning('Could not delete old profile image: $e');
        // Don't throw error - continue with upload even if old image deletion fails
      }
    }
  }

  /// Get profile image reference for a user
  Reference getProfileImageRef(String userId) {
    return _storage.ref().child('profile_images/profile_$userId');
  }

  /// Check if user has a profile image
  Future<bool> hasProfileImage(String userId) async {
    try {
      final ref = getProfileImageRef(userId);
      await ref.getDownloadURL();
      return true;
    } catch (e) {
      return false;
    }
  }
}
