import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:balaji_points/core/design/app_colors.dart';
import 'package:balaji_points/core/design/app_typography.dart';
import 'package:balaji_points/core/utils/back_button_handler.dart';
import 'package:balaji_points/l10n/app_localizations.dart';
import 'package:balaji_points/presentation/widgets/carpenter/home_nav_bar.dart';
import 'package:balaji_points/services/auth/session_service.dart';
import 'package:balaji_points/services/platform/storage_service.dart';
import 'package:balaji_points/services/user/user_migration_service.dart';
import 'package:balaji_points/services/user/user_service.dart';

class EditProfilePage extends ConsumerStatefulWidget {
  final bool isFirstTime;

  const EditProfilePage({super.key, this.isFirstTime = false});

  @override
  ConsumerState<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends ConsumerState<EditProfilePage> {
  final _formKey = GlobalKey<FormState>();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final UserService _userService = UserService();
  final StorageService _storageService = StorageService();
  final SessionService _sessionService = SessionService();
  final UserMigrationService _userMigrationService = UserMigrationService();

  File? _imageFile;
  String? _existingImageUrl;
  bool _isLoading = true;
  bool _isSaving = false;
  bool _isUploadingImage = false;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    super.dispose();
  }

  Future<void> _loadUserData() async {
    try {
      final userData = await _userService.getCurrentUserData(forceRefresh: true);
      if (userData != null && mounted) {
        setState(() {
          _firstNameController.text = userData['firstName'] as String? ?? '';
          _lastNameController.text = userData['lastName'] as String? ?? '';
          _existingImageUrl = userData['profileImage'] as String?;
          _isLoading = false;
        });
      } else {
        if (mounted) setState(() => _isLoading = false);
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _pickImage() async {
    try {
      final picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 75,
      );
      if (image != null) setState(() => _imageFile = File(image.path));
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Failed to pick image: $e'),
          backgroundColor: context.themeError,
        ));
      }
    }
  }

  bool _hasUnsavedChanges() {
    if (_isLoading || _isSaving) return false;
    return _firstNameController.text.trim().isNotEmpty ||
        _lastNameController.text.trim().isNotEmpty ||
        _imageFile != null;
  }

  String _sanitizeInput(String input) =>
      input.replaceAll(RegExp(r'[\x00-\x1F\x7F]'), '').trim();

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);

    try {
      final phoneNumber = await _sessionService.getPhoneNumber();
      if (phoneNumber == null) throw Exception('No user logged in');

      final firstName = _firstNameController.text.trim();
      final lastName = _lastNameController.text.trim();

      if (firstName.isEmpty || firstName.length < 2) {
        throw Exception('First name must be at least 2 characters');
      }
      if (firstName.length > 50) {
        throw Exception('First name is too long (max 50 characters)');
      }
      if (lastName.isEmpty || lastName.length < 2) {
        throw Exception('Last name must be at least 2 characters');
      }
      if (lastName.length > 50) {
        throw Exception('Last name is too long (max 50 characters)');
      }

      final sanitizedFirst = _sanitizeInput(firstName);
      final sanitizedLast = _sanitizeInput(lastName);

      // Require a profile image
      final hasImage = _imageFile != null ||
          (_existingImageUrl != null && _existingImageUrl!.isNotEmpty);
      if (!hasImage) {
        setState(() => _isSaving = false);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('Please add a profile photo'),
            backgroundColor: context.themeError,
          ));
        }
        return;
      }

      String? profileImageUrl = _existingImageUrl;
      String? oldImageUrlToDelete;

      if (_imageFile != null) {
        setState(() => _isUploadingImage = true);
        try {
          final newUrl = await _storageService.uploadProfileImage(
            phoneNumber: phoneNumber,
            imageFile: _imageFile!,
          );
          if (newUrl == null || newUrl.isEmpty) {
            throw Exception('Failed to upload profile image');
          }
          if (_existingImageUrl != null && _existingImageUrl!.isNotEmpty) {
            oldImageUrlToDelete = _existingImageUrl;
          }
          profileImageUrl = newUrl;
          setState(() => _isUploadingImage = false);
        } catch (e) {
          setState(() => _isUploadingImage = false);
          throw Exception('Failed to upload profile image: $e');
        }
      }

      final updateData = <String, dynamic>{
        'firstName': sanitizedFirst,
        'lastName': sanitizedLast,
        'updatedAt': FieldValue.serverTimestamp(),
        'phone': phoneNumber,
      };
      if (profileImageUrl != null && profileImageUrl.isNotEmpty) {
        updateData['profileImage'] = profileImageUrl;
      }

      final canonicalRef = await _userMigrationService.resolveCanonicalUserRef(
        phone: phoneNumber,
      );
      final primarySnapshot = await canonicalRef.get();
      final currentData = primarySnapshot.data();

      await canonicalRef.set(updateData, SetOptions(merge: true));

      final verifyDoc =
          await canonicalRef.get(GetOptions(source: Source.server));
      final savedData = verifyDoc.data();

      if (savedData == null) {
        throw Exception('Failed to verify saved data - document not found');
      }
      if (savedData['firstName'] != sanitizedFirst) {
        if (currentData != null) {
          await canonicalRef.set(currentData, SetOptions(merge: true));
        }
        throw Exception('Data verification failed - firstName mismatch');
      }
      if (savedData['phone'] != phoneNumber) {
        throw Exception('Data verification failed - phone number mismatch');
      }

      await _sessionService.updateProfile(
        firstName: sanitizedFirst,
        lastName: sanitizedLast.isNotEmpty ? sanitizedLast : null,
      );

      if (oldImageUrlToDelete != null && oldImageUrlToDelete.isNotEmpty) {
        try {
          await _storageService.deleteOldProfileImageIfExists(
              oldImageUrlToDelete);
        } catch (_) {}
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Profile updated successfully'),
          backgroundColor: AppColors.success,
          duration: Duration(seconds: 2),
        ));

        await Future.delayed(const Duration(milliseconds: 1000));
        if (!mounted) return;

        if (widget.isFirstTime) {
          final freshData = await _userService.getCurrentUserData();
          final role = (freshData?['role'] as String?)?.toLowerCase();
          if (!mounted) return;
          if (role == 'admin') {
            context.go('/admin');
          } else {
            context.go('/');
          }
        } else {
          if (context.canPop()) {
            context.pop();
          } else {
            context.go('/');
          }
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Failed to update profile: $e'),
          backgroundColor: context.themeError,
          duration: const Duration(seconds: 5),
        ));
      }
    } finally {
      if (mounted) setState(() { _isSaving = false; _isUploadingImage = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final borderColor = isDark
        ? AppColors.white.withValues(alpha: 0.12)
        : AppColors.black.withValues(alpha: 0.08);

    return PopScope(
      canPop: !widget.isFirstTime && !_hasUnsavedChanges(),
      onPopInvokedWithResult: (didPop, _) async {
        if (!didPop) {
          if (Navigator.of(context).canPop()) {
            Navigator.of(context).pop();
            return;
          }
          if (widget.isFirstTime) {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              content: Text('Please complete your profile'),
              backgroundColor: AppColors.warning,
            ));
          } else if (_hasUnsavedChanges()) {
            final shouldDiscard =
                await BackButtonHandler.showDiscardDialog(context);
            if (shouldDiscard == true && mounted) {
              // ignore: use_build_context_synchronously
              context.pop();
            }
          } else {
            context.pop();
          }
        }
      },
      child: Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        body: Column(
          children: [
            HomeNavBar(
              title: widget.isFirstTime ? l10n.completeProfile : l10n.editProfile,
              showLogo: false,
              showProfileButton: false,
              showBackButton: !widget.isFirstTime,
            ),
            Container(height: 1, color: borderColor),
            Expanded(
              child: Container(
                color: theme.colorScheme.surface,
                child: _isLoading
                    ? Center(
                        child: CircularProgressIndicator(
                            color: context.themePrimary))
                    : SingleChildScrollView(
                        padding: const EdgeInsets.all(24),
                        child: Form(
                          key: _formKey,
                          child: Column(
                            children: [
                              const SizedBox(height: 24),

                              // Avatar picker
                              GestureDetector(
                                onTap: _pickImage,
                                child: Stack(
                                  children: [
                                    Container(
                                      width: 120,
                                      height: 120,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: AppColors.white,
                                        border: Border.all(
                                          color: context.themePrimary,
                                          width: 3,
                                        ),
                                        boxShadow: [
                                          BoxShadow(
                                            color: AppColors.black
                                                .withValues(alpha: 0.1),
                                            blurRadius: 10,
                                            offset: const Offset(0, 4),
                                          ),
                                        ],
                                      ),
                                      child: ClipOval(
                                        child: _imageFile != null
                                            ? Image.file(_imageFile!,
                                                fit: BoxFit.cover)
                                            : _existingImageUrl != null &&
                                                    _existingImageUrl!.isNotEmpty
                                                ? Image.network(
                                                    _existingImageUrl!,
                                                    fit: BoxFit.cover,
                                                    loadingBuilder: (context,
                                                        child, progress) {
                                                      if (progress == null) {
                                                        return child;
                                                      }
                                                      return Container(
                                                        color: AppColors
                                                            .lightSecondary
                                                            .withValues(
                                                                alpha: 0.2),
                                                        child: Center(
                                                          child: CircularProgressIndicator(
                                                            value: progress
                                                                        .expectedTotalBytes !=
                                                                    null
                                                                ? progress
                                                                        .cumulativeBytesLoaded /
                                                                    progress
                                                                        .expectedTotalBytes!
                                                                : null,
                                                            valueColor:
                                                                const AlwaysStoppedAnimation<
                                                                    Color>(
                                                                  AppColors
                                                                      .lightPrimary,
                                                                ),
                                                          ),
                                                        ),
                                                      );
                                                    },
                                                    errorBuilder:
                                                        (context, _, __) =>
                                                            const Icon(
                                                              Icons.person,
                                                              size: 60,
                                                              color: AppColors
                                                                  .lightSecondary,
                                                            ),
                                                  )
                                                : Icon(
                                                    Icons.person,
                                                    size: 60,
                                                    color:
                                                        context.themeSecondary,
                                                  ),
                                      ),
                                    ),
                                    Positioned(
                                      bottom: 0,
                                      right: 0,
                                      child: Container(
                                        width: 36,
                                        height: 36,
                                        decoration: BoxDecoration(
                                          color: context.themeSecondary,
                                          shape: BoxShape.circle,
                                          border: Border.all(
                                            color: AppColors.white,
                                            width: 2,
                                          ),
                                        ),
                                        child: const Icon(Icons.camera_alt,
                                            size: 18, color: AppColors.white),
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                              const SizedBox(height: 12),
                              Text(
                                'Tap to change photo',
                                style: AppTypography.bodySmall(
                                    color: context.themeTextSecondary),
                              ),

                              const SizedBox(height: 40),

                              // First name
                              _buildTextField(
                                controller: _firstNameController,
                                label: 'First Name *',
                                hint: 'Enter your first name',
                                validator: (v) {
                                  if (v == null || v.trim().isEmpty) {
                                    return 'Please enter your first name';
                                  }
                                  if (v.trim().length < 2) {
                                    return 'First name must be at least 2 characters';
                                  }
                                  return null;
                                },
                              ),

                              const SizedBox(height: 20),

                              // Last name
                              _buildTextField(
                                controller: _lastNameController,
                                label: 'Last Name *',
                                hint: 'Enter your last name',
                                validator: (v) {
                                  if (v == null || v.trim().isEmpty) {
                                    return 'Please enter your last name';
                                  }
                                  if (v.trim().length < 2) {
                                    return 'Last name must be at least 2 characters';
                                  }
                                  return null;
                                },
                              ),

                              const SizedBox(height: 40),

                              // Upload status
                              if (_isUploadingImage)
                                Padding(
                                  padding: const EdgeInsets.only(bottom: 16),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      SizedBox(
                                        width: 16,
                                        height: 16,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          valueColor:
                                              AlwaysStoppedAnimation<Color>(
                                                  context.themePrimary),
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Text('Uploading image...',
                                          style: AppTypography.bodySmall(
                                              color: context.themePrimary)),
                                    ],
                                  ),
                                ),

                              // Save button
                              Container(
                                width: double.infinity,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(16),
                                  boxShadow: [
                                    BoxShadow(
                                      color: context.themeSecondary
                                          .withValues(alpha: 0.3),
                                      blurRadius: 15,
                                      offset: const Offset(0, 6),
                                    ),
                                  ],
                                ),
                                child: ElevatedButton(
                                  onPressed: (_isSaving || _isUploadingImage)
                                      ? null
                                      : _saveProfile,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: context.themeSecondary,
                                    foregroundColor: AppColors.white,
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 18),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                    elevation: 0,
                                  ),
                                  child: _isSaving
                                      ? const SizedBox(
                                          height: 20,
                                          width: 20,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            valueColor:
                                                AlwaysStoppedAnimation<Color>(
                                                    AppColors.white),
                                          ),
                                        )
                                      : Text(
                                          widget.isFirstTime
                                              ? 'Complete Profile'
                                              : 'Save Changes',
                                          style: AppTypography.buttonLarge(
                                              color: AppColors.white),
                                        ),
                                ),
                              ),

                              if (widget.isFirstTime) ...[
                                const SizedBox(height: 16),
                                Text(
                                  'You need to complete your profile to continue',
                                  textAlign: TextAlign.center,
                                  style: AppTypography.bodySmall(
                                      color: context.themeTextSecondary),
                                ),
                              ],

                              const SizedBox(height: 80),
                            ],
                          ),
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required String? Function(String?) validator,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TextFormField(
        controller: controller,
        style: AppTypography.bodyMedium(color: context.themeTextPrimary),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: AppTypography.labelMedium(color: context.themePrimary),
          hintText: hint,
          hintStyle: AppTypography.bodyMedium(color: context.themeTextMuted),
          prefixIcon: Icon(Icons.person_outline, color: context.themePrimary),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
          filled: true,
          fillColor: AppColors.white,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        ),
        validator: validator,
      ),
    );
  }
}
