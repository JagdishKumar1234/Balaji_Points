import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:go_router/go_router.dart';
import 'package:balaji_points/core/design/app_colors.dart';
import 'package:balaji_points/core/design/app_typography.dart';
import 'package:balaji_points/core/layout/carpenter_shell_layout.dart';
import 'package:balaji_points/l10n/app_localizations.dart';
import 'package:balaji_points/services/platform/bill_service.dart';
import 'package:balaji_points/services/user/user_service.dart';
import 'package:balaji_points/services/auth/session_service.dart';
import 'package:balaji_points/core/logger.dart';
import 'package:balaji_points/core/utils/back_button_handler.dart';
import 'package:balaji_points/presentation/widgets/carpenter/home_nav_bar.dart';

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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.orangeBackground,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.person_add_alt_1,
                color: AppColors.orangeDark,
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                l10n?.profileIncomplete ?? 'Profile Incomplete',
                style: AppTypography.h4(),
              ),
            ),
          ],
        ),
        content: Text(
          l10n?.completeProfileMessage ??
              'Please complete your profile (first name, last name, and profile picture) to add bills and earn points.',
          style: AppTypography.bodyMedium(color: AppColors.lightTextSecondary),
        ),
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              context.go('/');
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.grey600,
              foregroundColor: AppColors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text(
              l10n?.back ?? 'Go Back',
              style: AppTypography.labelLarge(color: AppColors.white),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              context.push('/edit-profile');
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.orange,
              foregroundColor: AppColors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text(
              l10n?.completeProfile ?? 'Complete Profile',
              style: AppTypography.labelLarge(color: AppColors.white),
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
            colorScheme: const ColorScheme.light(
              primary: AppColors.lightPrimary,
              onPrimary: AppColors.white,
              surface: AppColors.white,
              onSurface: AppColors.lightTextPrimary,
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
      if (image != null) setState(() => _selectedImage = File(image.path));
    } catch (e) {
      AppLogger.error('Error picking image', e);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Error: ${e.toString()}'),
          backgroundColor: AppColors.error,
        ));
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
      if (image != null) setState(() => _selectedImage = File(image.path));
    } catch (e) {
      AppLogger.error('Error taking photo', e);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Error: ${e.toString()}'),
          backgroundColor: AppColors.error,
        ));
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
              leading: const Icon(Icons.photo_library, color: AppColors.lightPrimary),
              title: Text(l10n?.selectImage ?? 'Choose from Gallery'),
              onTap: () { Navigator.pop(context); _pickImage(); },
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt, color: AppColors.lightPrimary),
              title: Text(l10n?.selectImage ?? 'Take Photo'),
              onTap: () { Navigator.pop(context); _takePhoto(); },
            ),
            ListTile(
              leading: const Icon(Icons.cancel, color: AppColors.error),
              title: Text(l10n?.cancel ?? 'Cancel'),
              onTap: () => Navigator.pop(context),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _submitBill() async {
    if (!_formKey.currentState!.validate()) return;

    final billDate = _billDate ?? DateTime.now();
    final l10n = AppLocalizations.of(context);
    final amount = double.tryParse(_amountController.text.trim());
    if (amount == null || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(l10n?.enterValidAmount ?? 'Please enter a valid amount'),
        backgroundColor: AppColors.error,
      ));
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final phoneNumber = await _sessionService.getPhoneNumber();
      if (phoneNumber == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(l10n?.sessionExpired ?? 'Please login to submit bills'),
            backgroundColor: AppColors.error,
          ));
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
        setState(() => _isSubmitting = false);
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(
              l10n?.billSubmitted ?? 'Bill submitted successfully! Admin will review it.',
            ),
            backgroundColor: AppColors.success,
            duration: const Duration(seconds: 3),
          ));
          Future.delayed(const Duration(seconds: 1), () {
            if (mounted) context.pop();
          });
        } else {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(
              l10n?.billSubmitError ?? 'Failed to submit bill. Please try again.',
            ),
            backgroundColor: AppColors.error,
          ));
        }
      }
    } catch (e) {
      AppLogger.error('Error submitting bill', e);
      if (mounted) {
        setState(() => _isSubmitting = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Error: ${e.toString()}'),
          backgroundColor: AppColors.error,
        ));
      }
    }
  }

  InputDecoration _fieldDecoration({
    required String hint,
    required IconData icon,
  }) {
    return InputDecoration(
      filled: true,
      fillColor: AppColors.white,
      hintText: hint,
      hintStyle: AppTypography.bodyMedium(color: AppColors.grey400),
      prefixIcon: Container(
        margin: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.lightPrimary.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: AppColors.lightPrimary),
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: AppColors.lightPrimary.withValues(alpha: 0.3)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: AppColors.lightPrimary.withValues(alpha: 0.3)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: AppColors.lightPrimary, width: 2),
      ),
    );
  }

  Widget _sectionLabel(String label) => Text(
        label,
        style: AppTypography.labelLarge(color: AppColors.lightPrimary)
            .copyWith(fontWeight: FontWeight.w600),
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
              customMessage: l10n?.discardBillMessage ??
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
                  24, 24, 24,
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
                            color: AppColors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: AppColors.lightPrimary.withValues(alpha: 0.3),
                              width: 2,
                            ),
                          ),
                          child: _selectedImage != null
                              ? ClipRRect(
                                  borderRadius: BorderRadius.circular(14),
                                  child: Image.file(_selectedImage!, fit: BoxFit.cover),
                                )
                              : Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.add_photo_alternate,
                                      size: 64,
                                      color: AppColors.lightPrimary.withValues(alpha: 0.5),
                                    ),
                                    const SizedBox(height: 12),
                                    Text(
                                      l10n?.tapToAddBillImage ?? 'Tap to add bill image',
                                      style: AppTypography.bodyMedium(
                                        color: AppColors.lightTextSecondary,
                                      ),
                                    ),
                                  ],
                                ),
                        ),
                      ),

                      const SizedBox(height: 24),

                      // Amount
                      _sectionLabel(l10n?.billAmount ?? 'Bill Amount (₹)'),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _amountController,
                        keyboardType: TextInputType.number,
                        style: AppTypography.bodyMedium(color: AppColors.lightTextPrimary),
                        decoration: _fieldDecoration(
                          hint: l10n?.enterBillAmount ?? 'Enter bill amount',
                          icon: Icons.currency_rupee,
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return l10n?.enterBillAmount ?? 'Please enter bill amount';
                          }
                          final amt = double.tryParse(value.trim());
                          if (amt == null || amt <= 0) {
                            return l10n?.enterValidAmount ?? 'Please enter a valid amount';
                          }
                          return null;
                        },
                      ),

                      const SizedBox(height: 32),

                      // Bill Date
                      _sectionLabel(l10n?.billDateOptional ?? 'Bill Date (Optional)'),
                      const SizedBox(height: 12),
                      GestureDetector(
                        onTap: _selectDate,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
                          decoration: BoxDecoration(
                            color: AppColors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: AppColors.lightPrimary.withValues(alpha: 0.3),
                            ),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.calendar_today, color: AppColors.lightPrimary, size: 24),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  _billDate != null
                                      ? '${_billDate!.day}/${_billDate!.month}/${_billDate!.year}'
                                      : (l10n?.selectBillDateOptional ?? 'Select bill date (optional)'),
                                  style: AppTypography.bodyMedium(
                                    color: _billDate != null
                                        ? AppColors.lightTextPrimary
                                        : AppColors.grey400,
                                  ),
                                ),
                              ),
                              Icon(
                                Icons.arrow_forward_ios,
                                color: AppColors.lightPrimary.withValues(alpha: 0.5),
                                size: 16,
                              ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 24),

                      // Store Name
                      _sectionLabel(
                        l10n?.storeVendorNameOptional ?? 'Store/Vendor Name (Optional)',
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _storeNameController,
                        style: AppTypography.bodyMedium(color: AppColors.lightTextPrimary),
                        decoration: _fieldDecoration(
                          hint: l10n?.enterStoreOrVendorNameOptional ??
                              'Enter store or vendor name (optional)',
                          icon: Icons.store,
                        ),
                      ),

                      const SizedBox(height: 24),

                      // Bill Number
                      _sectionLabel(
                        l10n?.billInvoiceNumberOptional ?? 'Bill/Invoice Number (Optional)',
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _billNumberController,
                        style: AppTypography.bodyMedium(color: AppColors.lightTextPrimary),
                        decoration: _fieldDecoration(
                          hint: l10n?.enterBillOrInvoiceNumberOptional ??
                              'Enter bill or invoice number (optional)',
                          icon: Icons.receipt,
                        ),
                      ),

                      const SizedBox(height: 24),

                      // Notes
                      _sectionLabel(l10n?.notesOptional ?? 'Notes (Optional)'),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _notesController,
                        maxLines: 3,
                        style: AppTypography.bodyMedium(color: AppColors.lightTextPrimary),
                        decoration: _fieldDecoration(
                          hint: l10n?.addAnyAdditionalNotes ?? 'Add any additional notes...',
                          icon: Icons.note,
                        ),
                      ),

                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
            ),

            // Fixed Submit Button
            Container(
              margin: EdgeInsets.only(bottom: CarpenterShellLayout.scrollEndMargin),
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppColors.white,
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
                child: SizedBox(
                  width: double.infinity,
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.lightSecondary.withValues(alpha: 0.3),
                          blurRadius: 15,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: ElevatedButton(
                      onPressed: _isSubmitting ? null : _submitBill,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.lightSecondary,
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
                                valueColor: AlwaysStoppedAnimation<Color>(AppColors.white),
                              ),
                            )
                          : Text(
                              l10n?.submitBill ?? 'Submit Bill',
                              style: AppTypography.buttonLarge(color: AppColors.white),
                            ),
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
}
