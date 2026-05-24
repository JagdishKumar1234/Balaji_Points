import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:go_router/go_router.dart';
import 'package:balaji_points/core/layout/carpenter_shell_layout.dart';
import 'package:balaji_points/core/theme/design_token.dart';
import 'package:balaji_points/config/theme.dart' hide AppColors;
import 'package:balaji_points/l10n/app_localizations.dart';
import 'package:balaji_points/services/bill_service.dart';
import 'package:balaji_points/services/user_service.dart';
import 'package:balaji_points/services/session_service.dart';
import 'package:balaji_points/core/logger.dart';
import 'package:balaji_points/core/utils/back_button_handler.dart';
import 'package:balaji_points/presentation/widgets/home_nav_bar.dart';

class AddBillPage extends StatefulWidget {
  const AddBillPage({super.key});

  @override
  State<AddBillPage> createState() => _AddBillPageState();
}

class _AddBillPageState extends State<AddBillPage> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _storeNameController = TextEditingController();
  final _billNumberController = TextEditingController();
  final _notesController = TextEditingController();
  final ImagePicker _picker = ImagePicker();
  final BillService _billService = BillService();
  final UserService _userService = UserService();
  final SessionService _sessionService = SessionService();

  File? _selectedImage;
  DateTime? _billDate;
  bool _isSubmitting = false;
  Map<String, dynamic>? _userData;

  bool _hasFormData() {
    return _amountController.text.trim().isNotEmpty ||
        _storeNameController.text.trim().isNotEmpty ||
        _billNumberController.text.trim().isNotEmpty ||
        _notesController.text.trim().isNotEmpty ||
        _selectedImage != null ||
        _billDate != null;
  }

  @override
  void initState() {
    super.initState();
    _checkProfileCompletion();
  }

  /// Check if profile is complete, redirect to edit profile if not
  Future<void> _checkProfileCompletion() async {
    try {
      _userData = await _userService.getCurrentUserData();

      final firstName = (_userData?['firstName'] as String? ?? '').trim();
      final lastName = (_userData?['lastName'] as String? ?? '').trim();
      final profileImage = (_userData?['profileImage'] as String? ?? '').trim();

      if (firstName.isEmpty || lastName.isEmpty || profileImage.isEmpty) {
        if (mounted) {
          // Show dialog and redirect to edit profile
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: DesignToken.orangeShade50,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.person_add_alt_1,
                color: DesignToken.orangeShade700,
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                l10n?.profileIncomplete ?? 'Profile Incomplete',
                style: AppTextStyles.nunitoBold.copyWith(fontSize: 20),
              ),
            ),
          ],
        ),
        content: Text(
          l10n?.completeProfileMessage ??
              'Please complete your profile (first name, last name, and profile picture) to add bills and earn points.',
          style: AppTextStyles.nunitoRegular.copyWith(fontSize: 16),
        ),
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              context.go('/'); // Go back to home
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: DesignToken.grey600,
              foregroundColor: DesignToken.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text(
              l10n?.back ?? 'Go Back',
              style: AppTextStyles.nunitoSemiBold.copyWith(fontSize: 16),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              context.push('/edit-profile');
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: DesignToken.orangeShade600,
              foregroundColor: DesignToken.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text(
              l10n?.completeProfile ?? 'Complete Profile',
              style: AppTextStyles.nunitoSemiBold.copyWith(fontSize: 16),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _amountController.dispose();
    _storeNameController.dispose();
    _billNumberController.dispose();
    _notesController.dispose();
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
            colorScheme: ColorScheme.light(
              primary: DesignToken.primary,
              onPrimary: DesignToken.white,
              surface: DesignToken.white,
              onSurface: DesignToken.textDark,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _billDate) {
      setState(() {
        _billDate = picked;
      });
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
        setState(() {
          _selectedImage = File(image.path);
        });
      }
    } catch (e) {
      AppLogger.error('Error picking image', e);
      if (mounted) {
        final l10n = AppLocalizations.of(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${l10n?.errorOccurred ?? 'Error'}: ${e.toString()}'),
            backgroundColor: DesignToken.error,
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
        setState(() {
          _selectedImage = File(image.path);
        });
      }
    } catch (e) {
      AppLogger.error('Error taking photo', e);
      if (mounted) {
        final l10n = AppLocalizations.of(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${l10n?.errorOccurred ?? 'Error'}: ${e.toString()}'),
            backgroundColor: DesignToken.error,
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
              leading: const Icon(
                Icons.photo_library,
                color: DesignToken.primary,
              ),
              title: Text(l10n?.selectImage ?? 'Choose from Gallery'),
              onTap: () {
                Navigator.pop(context);
                _pickImage();
              },
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt, color: DesignToken.primary),
              title: Text(l10n?.selectImage ?? 'Take Photo'),
              onTap: () {
                Navigator.pop(context);
                _takePhoto();
              },
            ),
            ListTile(
              leading: const Icon(Icons.cancel, color: DesignToken.error),
              title: Text(l10n?.cancel ?? 'Cancel'),
              onTap: () => Navigator.pop(context),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _submitBill() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    // Use current date if bill date not selected
    final billDate = _billDate ?? DateTime.now();

    final l10n = AppLocalizations.of(context);
    final amount = double.tryParse(_amountController.text.trim());
    if (amount == null || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            l10n?.enterValidAmount ?? 'Please enter a valid amount',
          ),
          backgroundColor: DesignToken.error,
        ),
      );
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      // Get user phone number from session (PIN-based auth)
      final phoneNumber = await _sessionService.getPhoneNumber();
      if (phoneNumber == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                l10n?.sessionExpired ?? 'Please login to submit bills',
              ),
              backgroundColor: DesignToken.error,
            ),
          );
        }
        return;
      }

      final carpenterId = await _sessionService.getUserId() ?? phoneNumber;

      final success = await _billService.submitBill(
        carpenterId: carpenterId,
        carpenterPhone: phoneNumber,
        amount: amount,
        imageFile: _selectedImage,
        billDate: billDate,
        storeName: _storeNameController.text.trim().isEmpty
            ? null
            : _storeNameController.text.trim(),
        billNumber: _billNumberController.text.trim().isEmpty
            ? null
            : _billNumberController.text.trim(),
        notes: _notesController.text.trim().isEmpty
            ? null
            : _notesController.text.trim(),
      );

      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });

        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                l10n?.billSubmitted ??
                    'Bill submitted successfully! Admin will review it.',
              ),
              backgroundColor: DesignToken.success,
              duration: const Duration(seconds: 3),
            ),
          );

          // Navigate back after a short delay
          Future.delayed(const Duration(seconds: 1), () {
            if (mounted) {
              context.pop();
            }
          });
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                l10n?.billSubmitError ??
                    'Failed to submit bill. Please try again.',
              ),
              backgroundColor: DesignToken.error,
            ),
          );
        }
      }
    } catch (e) {
      AppLogger.error('Error submitting bill', e);
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${l10n?.errorOccurred ?? 'Error'}: ${e.toString()}'),
            backgroundColor: DesignToken.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !_hasFormData(),
      onPopInvoked: (didPop) async {
        if (!didPop) {
          // Check for dialogs first
          if (Navigator.of(context).canPop()) {
            Navigator.of(context).pop();
            return;
          }

          if (_hasFormData()) {
            final l10n = AppLocalizations.of(context);
            final shouldDiscard = await BackButtonHandler.showDiscardDialog(
              context,
              customMessage:
                  l10n?.discardBillMessage ??
                  'You have unsaved bill data. Do you want to discard it?',
            );
            if (shouldDiscard == true && mounted) {
              context.pop();
            }
          } else {
            context.pop();
          }
        }
      },
      child: Builder(
        builder: (context) {
          final l10n = AppLocalizations.of(context);
          final theme = Theme.of(context);
          final isDark = theme.brightness == Brightness.dark;
          final borderColor = isDark
              ? Colors.white.withValues(alpha: 0.12)
              : Colors.black.withValues(alpha: 0.08);
          return Scaffold(
            backgroundColor: theme.scaffoldBackgroundColor,
            body: Column(
              children: [
                // Top nav bar consistent with Profile/Add Profile screens
                HomeNavBar(
                  title: l10n?.addBill ?? 'Add Bill',
                  showLogo: false,
                  showProfileButton: false,
                  showBackButton: true,
                ),
                // Light divider under nav bar
                Container(
                  height: 1,
                  color: borderColor,
                ),
                // Scrollable Form Content
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

                          // Bill Image Section
                          Text(
                            l10n?.billImage ?? 'Bill Image',
                            style: AppTextStyles.nunitoSemiBold.copyWith(
                              fontSize: 14,
                              color: DesignToken.primary,
                            ),
                          ),
                          const SizedBox(height: 12),

                          GestureDetector(
                            onTap: _showImageSourceDialog,
                            child: Container(
                              height: 180,
                              decoration: BoxDecoration(
                                color: DesignToken.white,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: DesignToken.primary.withOpacity(0.3),
                                  width: 2,
                                  style: BorderStyle.solid,
                                ),
                              ),
                              child: _selectedImage != null
                                  ? ClipRRect(
                                      borderRadius: BorderRadius.circular(14),
                                      child: Image.file(
                                        _selectedImage!,
                                        fit: BoxFit.cover,
                                      ),
                                    )
                                  : Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          Icons.add_photo_alternate,
                                          size: 64,
                                          color: DesignToken.primary
                                              .withOpacity(0.5),
                                        ),
                                        const SizedBox(height: 12),
                                        Text(
                                          l10n?.tapToAddBillImage ??
                                              'Tap to add bill image',
                                          style: AppTextStyles.nunitoRegular
                                              .copyWith(
                                                color: DesignToken.textDark
                                                    .withOpacity(0.6),
                                                fontSize: 14,
                                              ),
                                        ),
                                      ],
                                    ),
                            ),
                          ),

                          const SizedBox(height: 24),

                          // Amount Field (moved to top)
                          Text(
                            l10n?.billAmount ?? 'Bill Amount (₹)',
                            style: AppTextStyles.nunitoSemiBold.copyWith(
                              fontSize: 14,
                              color: DesignToken.primary,
                            ),
                          ),
                          const SizedBox(height: 12),

                          TextFormField(
                            controller: _amountController,
                            keyboardType: TextInputType.number,
                            style: AppTextStyles.nunitoRegular.copyWith(
                              color: DesignToken.textDark,
                              fontSize: 16,
                            ),
                            decoration: InputDecoration(
                              filled: true,
                              fillColor: DesignToken.white,
                              hintText:
                                  l10n?.enterBillAmount ?? 'Enter bill amount',
                              hintStyle: AppTextStyles.nunitoRegular.copyWith(
                                color: DesignToken.grey400,
                              ),
                              prefixIcon: Container(
                                margin: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: DesignToken.primary.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Icon(
                                  Icons.currency_rupee,
                                  color: DesignToken.primary,
                                ),
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16),
                                borderSide: BorderSide(
                                  color: DesignToken.primary.withOpacity(0.3),
                                ),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16),
                                borderSide: BorderSide(
                                  color: DesignToken.primary.withOpacity(0.3),
                                ),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16),
                                borderSide: const BorderSide(
                                  color: DesignToken.primary,
                                  width: 2,
                                ),
                              ),
                            ),
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return l10n?.enterBillAmount ??
                                    'Please enter bill amount';
                              }
                              final amount = double.tryParse(value.trim());
                              if (amount == null || amount <= 0) {
                                return l10n?.enterValidAmount ??
                                    'Please enter a valid amount';
                              }
                              return null;
                            },
                          ),

                          const SizedBox(height: 32),

                          // Bill Date Field
                          Text(
                            l10n?.billDateOptional ?? 'Bill Date (Optional)',
                            style: AppTextStyles.nunitoSemiBold.copyWith(
                              fontSize: 16,
                              color: DesignToken.primary,
                            ),
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
                                color: DesignToken.white,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: DesignToken.primary.withOpacity(0.3),
                                ),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.calendar_today,
                                    color: DesignToken.primary,
                                    size: 24,
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      _billDate != null
                                          ? '${_billDate!.day}/${_billDate!.month}/${_billDate!.year}'
                                          : (l10n?.selectBillDateOptional ??
                                                'Select bill date (optional)'),
                                      style: AppTextStyles.nunitoRegular
                                          .copyWith(
                                            color: _billDate != null
                                                ? DesignToken.textDark
                                                : DesignToken.grey400,
                                            fontSize: 16,
                                          ),
                                    ),
                                  ),
                                  Icon(
                                    Icons.arrow_forward_ios,
                                    color: DesignToken.primary.withOpacity(0.5),
                                    size: 16,
                                  ),
                                ],
                              ),
                            ),
                          ),

                          const SizedBox(height: 24),

                          // Store Name Field
                          Text(
                            l10n?.storeVendorNameOptional ??
                                'Store/Vendor Name (Optional)',
                            style: AppTextStyles.nunitoSemiBold.copyWith(
                              fontSize: 16,
                              color: DesignToken.primary,
                            ),
                          ),
                          const SizedBox(height: 12),

                          TextFormField(
                            controller: _storeNameController,
                            style: AppTextStyles.nunitoRegular.copyWith(
                              color: DesignToken.textDark,
                              fontSize: 16,
                            ),
                            decoration: InputDecoration(
                              filled: true,
                              fillColor: DesignToken.white,
                              hintText:
                                  l10n?.enterStoreOrVendorNameOptional ??
                                  'Enter store or vendor name (optional)',
                              hintStyle: AppTextStyles.nunitoRegular.copyWith(
                                color: DesignToken.grey400,
                              ),
                              prefixIcon: Container(
                                margin: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: DesignToken.primary.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Icon(
                                  Icons.store,
                                  color: DesignToken.primary,
                                ),
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16),
                                borderSide: BorderSide(
                                  color: DesignToken.primary.withOpacity(0.3),
                                ),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16),
                                borderSide: BorderSide(
                                  color: DesignToken.primary.withOpacity(0.3),
                                ),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16),
                                borderSide: const BorderSide(
                                  color: DesignToken.primary,
                                  width: 2,
                                ),
                              ),
                            ),
                          ),

                          const SizedBox(height: 24),

                          // Bill Number Field
                          Text(
                            l10n?.billInvoiceNumberOptional ??
                                'Bill/Invoice Number (Optional)',
                            style: AppTextStyles.nunitoSemiBold.copyWith(
                              fontSize: 16,
                              color: DesignToken.primary,
                            ),
                          ),
                          const SizedBox(height: 12),

                          TextFormField(
                            controller: _billNumberController,
                            style: AppTextStyles.nunitoRegular.copyWith(
                              color: DesignToken.textDark,
                              fontSize: 16,
                            ),
                            decoration: InputDecoration(
                              filled: true,
                              fillColor: DesignToken.white,
                              hintText:
                                  l10n?.enterBillOrInvoiceNumberOptional ??
                                  'Enter bill or invoice number (optional)',
                              hintStyle: AppTextStyles.nunitoRegular.copyWith(
                                color: DesignToken.grey400,
                              ),
                              prefixIcon: Container(
                                margin: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: DesignToken.primary.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Icon(
                                  Icons.receipt,
                                  color: DesignToken.primary,
                                ),
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16),
                                borderSide: BorderSide(
                                  color: DesignToken.primary.withOpacity(0.3),
                                ),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16),
                                borderSide: BorderSide(
                                  color: DesignToken.primary.withOpacity(0.3),
                                ),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16),
                                borderSide: const BorderSide(
                                  color: DesignToken.primary,
                                  width: 2,
                                ),
                              ),
                            ),
                          ),

                          const SizedBox(height: 24),

                          // Notes Field (Optional)
                          Text(
                            l10n?.notesOptional ?? 'Notes (Optional)',
                            style: AppTextStyles.nunitoSemiBold.copyWith(
                              fontSize: 16,
                              color: DesignToken.primary,
                            ),
                          ),
                          const SizedBox(height: 12),

                          TextFormField(
                            controller: _notesController,
                            maxLines: 3,
                            style: AppTextStyles.nunitoRegular.copyWith(
                              color: DesignToken.textDark,
                              fontSize: 16,
                            ),
                            decoration: InputDecoration(
                              filled: true,
                              fillColor: DesignToken.white,
                              hintText:
                                  l10n?.addAnyAdditionalNotes ??
                                  'Add any additional notes...',
                              hintStyle: AppTextStyles.nunitoRegular.copyWith(
                                color: DesignToken.grey400,
                              ),
                              prefixIcon: Container(
                                margin: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: DesignToken.primary.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Icon(
                                  Icons.note,
                                  color: DesignToken.primary,
                                ),
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16),
                                borderSide: BorderSide(
                                  color: DesignToken.primary.withOpacity(0.3),
                                ),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16),
                                borderSide: BorderSide(
                                  color: DesignToken.primary.withOpacity(0.3),
                                ),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16),
                                borderSide: const BorderSide(
                                  color: DesignToken.primary,
                                  width: 2,
                                ),
                              ),
                            ),
                          ),

                          const SizedBox(height: 24),

                          // Info Text
                          const SizedBox(height: 24),
                        ],
                      ),
                    ),
                  ),
                ),

                // Fixed Submit Button at Bottom (shell reserves tab bar space)
                Container(
                  margin: EdgeInsets.only(
                    bottom: CarpenterShellLayout.scrollEndMargin,
                  ),
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: DesignToken.white,
                    boxShadow: [
                      BoxShadow(
                        color: DesignToken.black.withOpacity(0.05),
                        blurRadius: 10,
                        offset: const Offset(0, -2),
                      ),
                    ],
                  ),
                  child: SafeArea(
                    top: false,
                    bottom: false,
                    child: SizedBox(
                      width: double.infinity,
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: DesignToken.secondary.withOpacity(0.3),
                              blurRadius: 15,
                              offset: const Offset(0, 6),
                            ),
                          ],
                        ),
                        child: ElevatedButton(
                          onPressed: _isSubmitting ? null : _submitBill,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: DesignToken.secondary,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            minimumSize: const Size(double.infinity, 56),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            elevation: 0,
                          ),
                          child: _isSubmitting
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      DesignToken.white,
                                    ),
                                  ),
                                )
                              : Text(
                                  l10n?.submitBill ?? 'Submit Bill',
                                  style: AppTextStyles.nunitoBold.copyWith(
                                    fontSize: 18,
                                    color: DesignToken.white,
                                  ),
                                ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
