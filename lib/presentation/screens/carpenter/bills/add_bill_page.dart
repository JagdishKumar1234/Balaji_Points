import 'package:balaji_points/core/design/app_radius.dart';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:go_router/go_router.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:balaji_points/core/design/app_colors.dart';
import 'package:balaji_points/core/layout/carpenter_shell_layout.dart';
import 'package:balaji_points/l10n/app_localizations.dart';
import 'package:balaji_points/services/platform/bill_service.dart';
import 'package:balaji_points/services/user/user_service.dart';
import 'package:balaji_points/services/auth/session_service.dart';
import 'package:balaji_points/core/logger.dart';
import 'package:balaji_points/core/utils/back_button_handler.dart';
import 'package:balaji_points/presentation/widgets/carpenter/home_nav_bar.dart';
import 'package:balaji_points/presentation/widgets/shared/app_button.dart';
import 'package:balaji_points/presentation/widgets/shared/app_text.dart';
import 'package:balaji_points/presentation/widgets/shared/app_text_field.dart';

class AddBillPage extends StatefulWidget {
  const AddBillPage({super.key});

  @override
  State<AddBillPage> createState() => _AddBillPageState();
}

class _AddBillPageState extends State<AddBillPage> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _siteNameController = TextEditingController();
  final _vendorNameController = TextEditingController();
  final ImagePicker _picker = ImagePicker();
  final BillService _billService = BillService();
  final UserService _userService = UserService();
  final SessionService _sessionService = SessionService();

  Uint8List? _selectedImageBytes;
  DateTime? _billDate;
  bool _isSubmitting = false;

  bool _hasFormData() {
    return _amountController.text.trim().isNotEmpty ||
        _siteNameController.text.trim().isNotEmpty ||
        _vendorNameController.text.trim().isNotEmpty ||
        _selectedImageBytes != null ||
        _billDate != null;
  }

  @override
  void initState() {
    super.initState();
    _billDate = DateTime.now();
    _checkProfileCompletion();
  }

  Future<void> _checkProfileCompletion() async {
    try {
      final userData = await _userService.getCurrentUserData();
      final firstName = (userData?['firstName'] as String? ?? '').trim();
      final lastName = (userData?['lastName'] as String? ?? '').trim();
      final profileImage = (userData?['profileImage'] as String? ?? '').trim();
      if (firstName.isEmpty || lastName.isEmpty || profileImage.isEmpty) {
        if (mounted) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _showProfileIncompleteDialog();
          });
        }
      }
    } catch (e) {
      AppLogger.error('Error checking profile completion', e);
    }
  }

  void _showProfileIncompleteDialog() {
    final l10n = AppLocalizations.of(context);
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: AppRadius.all16),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: context.themeSoftSurface,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.person_add_alt_1,
                color: context.themeSecondary,
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: AppText.h4(
                l10n?.profileIncomplete ?? 'Profile Incomplete',
              ),
            ),
          ],
        ),
        content: AppText.body(
          l10n?.completeProfileMessage ??
              'Please complete your profile (first name, last name, and profile picture) to add bills and earn points.',
          color: context.themeTextSecondary,
        ),
        actions: [
          AppButton.secondary(
            label: l10n?.back ?? 'Go Back',
            fullWidth: false,
            verticalPadding: 10,
            onPressed: () {
              Navigator.of(context).pop();
              context.go('/');
            },
          ),
          AppButton.primary(
            label: l10n?.completeProfile ?? 'Complete Profile',
            fullWidth: false,
            verticalPadding: 10,
            onPressed: () {
              Navigator.of(context).pop();
              context.push('/edit-profile');
            },
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _amountController.dispose();
    _siteNameController.dispose();
    _vendorNameController.dispose();
    super.dispose();
  }

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _billDate ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).colorScheme.copyWith(
              primary: context.themePrimary,
              onPrimary: AppColors.white,
              surface: context.themeSurface,
              onSurface: context.themeTextPrimary,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _billDate) {
      setState(() => _billDate = picked);
    }
  }

  Future<void> _pickImage() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1920,
        maxHeight: 1920,
        imageQuality: 85,
      );
      if (image != null) {
        final bytes = await image.readAsBytes();
        setState(() => _selectedImageBytes = bytes);
      }
    } catch (e) {
      AppLogger.error('Error picking image', e);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: context.themeError,
          ),
        );
      }
    }
  }

  Future<void> _takePhoto() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1920,
        maxHeight: 1920,
        imageQuality: 85,
      );
      if (image != null) {
        final bytes = await image.readAsBytes();
        setState(() => _selectedImageBytes = bytes);
      }
    } catch (e) {
      AppLogger.error('Error taking photo', e);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: context.themeError,
          ),
        );
      }
    }
  }

  Future<void> _showImageSourceDialog() async {
    final l10n = AppLocalizations.of(context);
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: Icon(Icons.photo_library, color: context.themePrimary),
              title: Text(l10n?.selectImage ?? 'Choose from Gallery'),
              onTap: () {
                Navigator.pop(context);
                _pickImage();
              },
            ),
            ListTile(
              leading: Icon(Icons.camera_alt, color: context.themePrimary),
              title: Text(l10n?.selectImage ?? 'Take Photo'),
              onTap: () {
                Navigator.pop(context);
                _takePhoto();
              },
            ),
            ListTile(
              leading: Icon(Icons.cancel, color: context.themeError),
              title: Text(l10n?.cancel ?? 'Cancel'),
              onTap: () => Navigator.pop(context),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _submitBill() async {
    // Validate form fields
    if (!_formKey.currentState!.validate()) return;

    // Validate site name (compulsory)
    final siteName = _siteNameController.text.trim();
    if (siteName.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('❌ Site name is required'),
          backgroundColor: context.themeError,
          duration: const Duration(seconds: 3),
        ),
      );
      return;
    }

    // Validate bill date
    final billDate = _billDate;
    if (billDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('❌ Please select a bill date'),
          backgroundColor: context.themeError,
          duration: const Duration(seconds: 3),
        ),
      );
      return;
    }

    // Validate date is not in future
    if (billDate.isAfter(DateTime.now())) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('❌ Bill date cannot be in the future'),
          backgroundColor: context.themeError,
          duration: const Duration(seconds: 3),
        ),
      );
      return;
    }

    final l10n = AppLocalizations.of(context);
    final amount = double.tryParse(_amountController.text.trim());
    if (amount == null || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '❌ ${l10n?.enterValidAmount ?? 'Please enter a valid amount'}',
          ),
          backgroundColor: context.themeError,
          duration: const Duration(seconds: 3),
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final phoneNumber = await _sessionService.getPhoneNumber();
      if (phoneNumber == null) {
        if (mounted) {
          setState(() => _isSubmitting = false);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                l10n?.sessionExpired ?? 'Please login to submit bills',
              ),
              backgroundColor: context.themeError,
              duration: const Duration(seconds: 3),
            ),
          );
        }
        return;
      }

      final carpenterId = await _sessionService.getUserId() ?? phoneNumber;

      // Get vendor name (optional)
      final vendorName = _vendorNameController.text.trim().isEmpty
          ? null
          : _vendorNameController.text.trim();

      // CHECK FOR DUPLICATE BILL - FRONTEND VALIDATION
      AppLogger.info('🔍 Checking for duplicate bill...');
      AppLogger.info('   Site: $siteName, Amount: $amount, Date: ${billDate.toIso8601String()}');

      final duplicateBill = await _billService.checkDuplicateBill(
        carpenterId: carpenterId,
        vendorName: vendorName,
        siteName: siteName,
        billAmount: amount,
        billDate: billDate,
      );

      if (mounted) {
        if (duplicateBill != null) {
          AppLogger.warning('⚠️ Duplicate bill detected! Showing warning dialog...');
          setState(() => _isSubmitting = false);
          // Show duplicate warning dialog
          _showDuplicateWarningDialog(
            duplicateBill,
            carpenterId,
            phoneNumber,
            amount,
            billDate,
            siteName,
            vendorName,
          );
          return;
        }

        AppLogger.info('✅ No duplicate found, proceeding with submission...');

        // No duplicate, proceed with submission
        final success = await _billService.submitBill(
          carpenterId: carpenterId,
          carpenterPhone: phoneNumber,
          amount: amount,
          imageBytes: _selectedImageBytes,
          billDate: billDate,
          storeName: siteName,
          vendorName: vendorName,
        );

        if (mounted) {
          setState(() => _isSubmitting = false);
          if (success) {
            AppLogger.info('✅ Bill submitted successfully!');
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  l10n?.billSubmitted ??
                      'Bill submitted successfully! Admin will review it.',
                ),
                backgroundColor: AppColors.success,
                duration: const Duration(seconds: 3),
              ),
            );
            Future.delayed(const Duration(seconds: 1), () {
              if (mounted) context.pop();
            });
          } else {
            AppLogger.error('Failed to submit bill', 'Unknown error');
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  l10n?.billSubmitError ??
                      'Failed to submit bill. Please try again.',
                ),
                backgroundColor: context.themeError,
                duration: const Duration(seconds: 3),
              ),
            );
          }
        }
      }
    } catch (e) {
      AppLogger.error('Error submitting bill', e);
      if (mounted) {
        setState(() => _isSubmitting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Error: ${e.toString()}'),
            backgroundColor: context.themeError,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  void _showDuplicateWarningDialog(
    Map<String, dynamic> duplicateBill,
    String carpenterId,
    String phoneNumber,
    double amount,
    DateTime billDate,
    String siteName,
    String? vendorName,
  ) {
    final l10n = AppLocalizations.of(context);
    final duplicateAmount = (duplicateBill['amount'] ?? 0).toDouble();
    final duplicatePoints = duplicateAmount / 1000;
    final duplicateDate = duplicateBill['billDate'] as Timestamp?;
    final duplicateDateStr = duplicateDate != null
        ? '${duplicateDate.toDate().day}/${duplicateDate.toDate().month}/${duplicateDate.toDate().year}'
        : 'N/A';

    AppLogger.warning('⚠️ Duplicate Warning Dialog shown to user');

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: context.themeError.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.warning_amber,
                color: context.themeError,
                size: 28,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                '⚠️ Duplicate Bill Detected',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: context.themeError,
                ),
              ),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'A bill with the SAME site, amount, and date already exists:',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 16),

              // Existing Bill Details
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: context.themeSoftSurface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: context.themeError.withValues(alpha: 0.2),
                    width: 1.5,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.location_on,
                          size: 16,
                          color: context.themeError,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Site Name',
                                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                  color: context.themeTextSecondary,
                                ),
                              ),
                              Text(
                                siteName,
                                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Icon(
                          Icons.currency_rupee,
                          size: 16,
                          color: AppColors.success,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Amount',
                                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                  color: context.themeTextSecondary,
                                ),
                              ),
                              Text(
                                '₹${duplicateAmount.toStringAsFixed(0)}',
                                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.success,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Icon(
                          Icons.stars,
                          size: 16,
                          color: context.themePrimary,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Points',
                                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                  color: context.themeTextSecondary,
                                ),
                              ),
                              Text(
                                '${duplicatePoints.toStringAsFixed(2)} pts',
                                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  fontWeight: FontWeight.w600,
                                  color: context.themePrimary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Icon(
                          Icons.calendar_today,
                          size: 16,
                          color: context.themeTextSecondary,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Date',
                                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                  color: context.themeTextSecondary,
                                ),
                              ),
                              Text(
                                duplicateDateStr,
                                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.warning.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.info,
                      size: 18,
                      color: AppColors.warning,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'This might be a duplicate entry. Please verify before adding.',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.warning,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),
              Text(
                'Do you want to add this bill anyway?',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              AppLogger.info('User cancelled duplicate bill submission');
              Navigator.pop(context);
            },
            child: Text(
              'Cancel',
              style: TextStyle(
                color: context.themePrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              AppLogger.warning('User chose to add duplicate bill anyway');
              Navigator.pop(context);
              setState(() => _isSubmitting = true);

              try {
                final success = await _billService.submitBill(
                  carpenterId: carpenterId,
                  carpenterPhone: phoneNumber,
                  amount: amount,
                  imageBytes: _selectedImageBytes,
                  billDate: billDate,
                  storeName: siteName,
                  vendorName: vendorName,
                );

                if (mounted) {
                  setState(() => _isSubmitting = false);
                  if (success) {
                    AppLogger.info('✅ Duplicate bill submitted successfully');
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          l10n?.billSubmitted ??
                              'Bill submitted successfully! Admin will review it.',
                        ),
                        backgroundColor: AppColors.success,
                        duration: const Duration(seconds: 3),
                      ),
                    );
                    Future.delayed(const Duration(seconds: 1), () {
                      if (mounted) context.pop();
                    });
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          l10n?.billSubmitError ??
                              'Failed to submit bill. Please try again.',
                        ),
                        backgroundColor: context.themeError,
                        duration: const Duration(seconds: 3),
                      ),
                    );
                  }
                }
              } catch (e) {
                AppLogger.error('Error submitting duplicate bill', e);
                if (mounted) {
                  setState(() => _isSubmitting = false);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('❌ Error: ${e.toString()}'),
                      backgroundColor: context.themeError,
                      duration: const Duration(seconds: 3),
                    ),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: context.themeSecondary,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            ),
            child: Text(
              'Add Anyway',
              style: TextStyle(
                color: AppColors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionLabel(String label) => AppText.label(
    label,
    color: context.themePrimary,
  );

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final borderColor = isDark
        ? AppColors.white.withValues(alpha: 0.12)
        : AppColors.black.withValues(alpha: 0.08);

    return PopScope(
      canPop: !_hasFormData(),
      onPopInvokedWithResult: (didPop, _) async {
        if (!didPop) {
          if (Navigator.of(context).canPop()) {
            Navigator.of(context).pop();
            return;
          }
          if (_hasFormData()) {
            final shouldDiscard = await BackButtonHandler.showDiscardDialog(
              context,
              customMessage:
                  l10n?.discardBillMessage ??
                  'You have unsaved bill data. Do you want to discard it?',
            );
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
              title: l10n?.addBill ?? 'Add Bill',
              showLogo: false,
              showProfileButton: false,
              showBackButton: true,
            ),
            Container(height: 1, color: borderColor),
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.fromLTRB(
                  24,
                  24,
                  24,
                  MediaQuery.of(context).padding.bottom + 160,
                ),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const SizedBox(height: 12),

                      // Bill Image
                      _sectionLabel(l10n?.billImage ?? 'Bill Image'),
                      const SizedBox(height: 12),
                      GestureDetector(
                        onTap: _showImageSourceDialog,
                        child: Container(
                          height: 180,
                          decoration: BoxDecoration(
                            color: context.themeSurface,
                            borderRadius: AppRadius.all16,
                            border: Border.all(
                              color: context.themePrimary.withValues(
                                alpha: 0.3,
                              ),
                              width: 2,
                            ),
                          ),
                          child: _selectedImageBytes != null
                              ? ClipRRect(
                                  borderRadius: AppRadius.all16,
                                  child: Image.memory(
                                    _selectedImageBytes!,
                                    fit: BoxFit.cover,
                                  ),
                                )
                              : Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.add_photo_alternate,
                                      size: 64,
                                      color: context.themePrimary.withValues(
                                        alpha: 0.5,
                                      ),
                                    ),
                                    const SizedBox(height: 12),
                                    AppText.body(
                                      l10n?.tapToAddBillImage ??
                                          'Tap to add bill image',
                                      color: context.themeTextSecondary,
                                    ),
                                  ],
                                ),
                        ),
                      ),

                      const SizedBox(height: 24),

                      // Amount
                      _sectionLabel(l10n?.billAmount ?? 'Bill Amount (₹)'),
                      const SizedBox(height: 12),
                      AppTextField(
                        controller: _amountController,
                        label: l10n?.enterBillAmount ?? 'Enter bill amount',
                        hint: l10n?.enterBillAmount ?? 'Enter bill amount',
                        prefixIcon: Icons.currency_rupee,
                        keyboardType: TextInputType.number,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return l10n?.enterBillAmount ??
                                'Please enter bill amount';
                          }
                          final amt = double.tryParse(value.trim());
                          if (amt == null || amt <= 0) {
                            return l10n?.enterValidAmount ??
                                'Please enter a valid amount';
                          }
                          return null;
                        },
                      ),

                      const SizedBox(height: 12),
                      ValueListenableBuilder(
                        valueListenable: _amountController,
                        builder: (context, value, _) {
                          final amount = double.tryParse(value.text.trim());
                          if (amount != null && amount > 0) {
                            final estimatedPoints = amount / 1000;
                            final pointsDisplay = estimatedPoints.toStringAsFixed(2);
                            return Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: context.themePrimary.withValues(alpha: 0.1),
                                borderRadius: AppRadius.md12,
                                border: Border.all(
                                  color: context.themePrimary.withValues(alpha: 0.3),
                                ),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.star,
                                    color: context.themePrimary,
                                    size: 18,
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: AppText.label(
                                      'You will earn $pointsDisplay points when approved',
                                      color: context.themePrimary,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }
                          return const SizedBox.shrink();
                        },
                      ),

                      const SizedBox(height: 32),

                      // Bill Date (Required)
                      _sectionLabel(
                        l10n?.billDate ?? 'Bill Date *',
                      ),
                      const SizedBox(height: 12),
                      GestureDetector(
                        onTap: _selectDate,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 18,
                          ),
                          decoration: BoxDecoration(
                            color: context.themeSurface,
                            borderRadius: AppRadius.all16,
                            border: Border.all(
                              color: context.themePrimary.withValues(
                                alpha: 0.3,
                              ),
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.calendar_today,
                                color: context.themePrimary,
                                size: 24,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: AppText.body(
                                  _billDate != null
                                      ? '${_billDate!.day}/${_billDate!.month}/${_billDate!.year}'
                                      : (l10n?.selectBillDate ??
                                            'Select bill date'),
                                  color: _billDate != null
                                      ? context.themeTextPrimary
                                      : context.themeTextMuted,
                                ),
                              ),
                              Icon(
                                Icons.arrow_forward_ios,
                                color: context.themePrimary.withValues(
                                  alpha: 0.5,
                                ),
                                size: 16,
                              ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 24),

                      // Site Name (Required)
                      _sectionLabel(
                        'Site Name *',
                      ),
                      const SizedBox(height: 12),
                      AppTextField(
                        controller: _siteNameController,
                        label: 'Site Name',
                        hint: 'Enter site/location name',
                        prefixIcon: Icons.location_on,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Site name is required';
                          }
                          return null;
                        },
                      ),

                      const SizedBox(height: 24),

                      // Vendor Name (Optional)
                      _sectionLabel(
                        'Vendor Name (Optional)',
                      ),
                      const SizedBox(height: 12),
                      AppTextField(
                        controller: _vendorNameController,
                        label: 'Vendor Name',
                        hint: 'Enter vendor/store name (optional)',
                        prefixIcon: Icons.store,
                      ),

                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
            ),

            // Fixed Submit Button
            Container(
              margin: EdgeInsets.only(
                bottom: CarpenterShellLayout.scrollEndMargin,
              ),
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: context.themeSurface,
                boxShadow: [
                  BoxShadow(
                    color: AppColors.black.withValues(alpha: 0.05),
                    blurRadius: 10,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: SafeArea(
                top: false,
                bottom: false,
                child: AppButton.secondary(
                  label: l10n?.submitBill ?? 'Submit Bill',
                  onPressed: _isSubmitting ? null : _submitBill,
                  isLoading: _isSubmitting,
                  verticalPadding: 16,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
