import 'dart:io';
import 'package:flutter/material.dart';
import 'package:balaji_points/core/design/app_colors.dart';
import 'package:balaji_points/core/design/app_typography.dart';
import 'package:image_picker/image_picker.dart';
import 'package:go_router/go_router.dart';
import 'package:balaji_points/l10n/app_localizations.dart';
import 'package:balaji_points/services/platform/bill_service.dart';
import 'package:balaji_points/services/auth/session_service.dart';
import 'package:balaji_points/services/user/user_service.dart';
import 'package:balaji_points/core/logger.dart';
import 'package:balaji_points/core/utils/back_button_handler.dart';
import 'package:balaji_points/presentation/widgets/admin/carpenter_selection_widget.dart';
import 'package:intl/intl.dart';

class AdminAddBillPage extends StatefulWidget {
  const AdminAddBillPage({super.key});

  @override
  State<AdminAddBillPage> createState() => _AdminAddBillPageState();
}

class _AdminAddBillPageState extends State<AdminAddBillPage> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _storeNameController = TextEditingController();
  final _billNumberController = TextEditingController();
  final _notesController = TextEditingController();
  final ImagePicker _picker = ImagePicker();
  final BillService _billService = BillService();
  final SessionService _sessionService = SessionService();
  final UserService _userService = UserService();

  Map<String, dynamic>? _selectedCarpenter;
  File? _selectedImage;
  DateTime _billDate = DateTime.now();
  bool _isSubmitting = false;
  Map<String, dynamic>? _adminData;

  bool _hasFormData() {
    return _selectedCarpenter != null ||
        _amountController.text.trim().isNotEmpty ||
        _storeNameController.text.trim().isNotEmpty ||
        _billNumberController.text.trim().isNotEmpty ||
        _notesController.text.trim().isNotEmpty ||
        _selectedImage != null;
  }

  @override
  void initState() {
    super.initState();
    _loadAdminData();
  }

  Future<void> _loadAdminData() async {
    try {
      _adminData = await _userService.getCurrentUserData();
    } catch (e) {
      AppLogger.error('Error loading admin data', e);
    }
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
      initialDate: _billDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: context.themePrimary,
              onPrimary: AppColors.white,
              surface: AppColors.white,
              onSurface: context.themePrimary,
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
              leading: Icon(
                Icons.photo_library,
                color: context.themePrimary,
              ),
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

  int _calculatePoints(double amount) {
    return (amount / 1000).floor();
  }

  Future<void> _submitBill() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_selectedCarpenter == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Please select a carpenter'),
          backgroundColor: context.themeError,
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
            l10n?.enterValidAmount ?? 'Please enter a valid amount',
          ),
          backgroundColor: context.themeError,
        ),
      );
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      // Get admin phone number from session
      final adminPhone = await _sessionService.getPhoneNumber();
      if (adminPhone == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                l10n?.sessionExpired ?? 'Please login to submit bills',
              ),
              backgroundColor: context.themeError,
            ),
          );
        }
        setState(() {
          _isSubmitting = false;
        });
        return;
      }

      final carpenterId = _selectedCarpenter!['userId'] as String? ??
          _selectedCarpenter!['phone'] as String;
      final carpenterPhone = _selectedCarpenter!['phone'] as String;

      // Get admin name if available
      String? adminName;
      if (_adminData != null) {
        final firstName = _adminData!['firstName'] ?? '';
        final lastName = _adminData!['lastName'] ?? '';
        adminName = ('$firstName $lastName').trim();
        if (adminName.isEmpty) {
          adminName = null;
        }
      }

      final success = await _billService.submitBillForCarpenter(
        carpenterId: carpenterId,
        carpenterPhone: carpenterPhone,
        amount: amount,
        adminId: adminPhone,
        adminPhone: adminPhone,
        adminName: adminName,
        imageFile: _selectedImage,
        billDate: _billDate,
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
                    'Bill submitted successfully! It will be reviewed.',
              ),
              backgroundColor: AppColors.success,
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
              backgroundColor: context.themeError,
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
            backgroundColor: context.themeError,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !_hasFormData(),
      onPopInvokedWithResult: (didPop, result) async {
        if (!didPop) {
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
          final amount = double.tryParse(_amountController.text.trim()) ?? 0;
          final points = _calculatePoints(amount);

          return Scaffold(
            backgroundColor: context.themeSoftSurface,
            appBar: AppBar(
              backgroundColor: AppColors.white,
              foregroundColor: context.themePrimary,
              elevation: 0,
              leading: IconButton(
                icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 22),
                onPressed: () => context.pop(),
              ),
              title: Text(
                'Add Bill for Carpenter',
                style: AppTypography.labelLarge().copyWith(
                  color: context.themePrimary,
                  fontSize: 18,
                ),
              ),
              centerTitle: true,
            ),
            body: Column(
              children: [
                // Scrollable Form Content
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(24),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const SizedBox(height: 20),

                          // Carpenter Selection
                          Text(
                            'Carpenter *',
                            style: AppTypography.labelLarge().copyWith(
                              fontSize: 16,
                              color: context.themePrimary,
                            ),
                          ),
                          const SizedBox(height: 12),
                          CarpenterSelectionWidget(
                            selectedCarpenter: _selectedCarpenter,
                            onCarpenterSelected: (carpenter) {
                              setState(() {
                                _selectedCarpenter = carpenter;
                              });
                            },
                          ),

                          const SizedBox(height: 32),

                          // Amount Field
                          Text(
                            l10n?.billAmount ?? 'Bill Amount (₹) *',
                            style: AppTypography.labelLarge().copyWith(
                              fontSize: 16,
                              color: context.themePrimary,
                            ),
                          ),
                          const SizedBox(height: 12),

                          TextFormField(
                            controller: _amountController,
                            keyboardType: TextInputType.number,
                            onChanged: (_) => setState(() {}),
                            style: AppTypography.bodyMedium().copyWith(
                              color: context.themePrimary,
                              fontSize: 18,
                            ),
                            decoration: InputDecoration(
                              filled: true,
                              fillColor: AppColors.white,
                              hintText:
                                  l10n?.enterBillAmount ?? 'Enter bill amount',
                              hintStyle: AppTypography.bodyMedium().copyWith(
                                color: context.themeTextMuted,
                              ),
                              prefixIcon: Container(
                                margin: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: context.themePrimary.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Icon(
                                  Icons.currency_rupee,
                                  color: context.themePrimary,
                                ),
                              ),
                              suffixText: amount > 0 ? '$points pts' : null,
                              suffixStyle: AppTypography.labelLarge().copyWith(
                                color: context.themeSecondary,
                                fontSize: 14,
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16),
                                borderSide: BorderSide(
                                  color: context.themePrimary.withValues(alpha: 0.3),
                                ),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16),
                                borderSide: BorderSide(
                                  color: context.themePrimary.withValues(alpha: 0.3),
                                ),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16),
                                borderSide: BorderSide(
                                  color: context.themePrimary,
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
                            l10n?.billDate ?? 'Bill Date *',
                            style: AppTypography.labelLarge().copyWith(
                              fontSize: 16,
                              color: context.themePrimary,
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
                                color: AppColors.white,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: context.themePrimary.withValues(alpha: 0.3),
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
                                    child: Text(
                                      DateFormat('dd MMM yyyy').format(_billDate),
                                      style: AppTypography.bodyMedium()
                                          .copyWith(
                                            color: context.themePrimary,
                                            fontSize: 16,
                                          ),
                                    ),
                                  ),
                                  Icon(
                                    Icons.arrow_forward_ios,
                                    color: context.themePrimary.withValues(alpha: 0.5),
                                    size: 16,
                                  ),
                                ],
                              ),
                            ),
                          ),

                          const SizedBox(height: 32),

                          // Bill Image Section
                          Text(
                            l10n?.billImage ?? 'Bill Image (Optional)',
                            style: AppTypography.labelLarge().copyWith(
                              fontSize: 16,
                              color: context.themePrimary,
                            ),
                          ),
                          const SizedBox(height: 12),

                          GestureDetector(
                            onTap: _showImageSourceDialog,
                            child: Container(
                              height: 200,
                              decoration: BoxDecoration(
                                color: AppColors.white,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: context.themePrimary.withValues(alpha: 0.3),
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
                                          color: context.themePrimary
                                              .withValues(alpha: 0.5),
                                        ),
                                        const SizedBox(height: 12),
                                        Text(
                                          l10n?.tapToAddBillImage ??
                                              'Tap to add bill image',
                                          style: AppTypography.bodyMedium()
                                              .copyWith(
                                                color: context.themePrimary
                                                    .withValues(alpha: 0.6),
                                                fontSize: 14,
                                              ),
                                        ),
                                      ],
                                    ),
                            ),
                          ),

                          const SizedBox(height: 32),

                          // Store Name Field
                          Text(
                            l10n?.storeVendorNameOptional ??
                                'Store/Vendor Name (Optional)',
                            style: AppTypography.labelLarge().copyWith(
                              fontSize: 16,
                              color: context.themePrimary,
                            ),
                          ),
                          const SizedBox(height: 12),

                          TextFormField(
                            controller: _storeNameController,
                            style: AppTypography.bodyMedium().copyWith(
                              color: context.themePrimary,
                              fontSize: 16,
                            ),
                            decoration: InputDecoration(
                              filled: true,
                              fillColor: AppColors.white,
                              hintText:
                                  l10n?.enterStoreOrVendorNameOptional ??
                                  'Enter store or vendor name (optional)',
                              hintStyle: AppTypography.bodyMedium().copyWith(
                                color: context.themeTextMuted,
                              ),
                              prefixIcon: Container(
                                margin: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: context.themePrimary.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Icon(
                                  Icons.store,
                                  color: context.themePrimary,
                                ),
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16),
                                borderSide: BorderSide(
                                  color: context.themePrimary.withValues(alpha: 0.3),
                                ),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16),
                                borderSide: BorderSide(
                                  color: context.themePrimary.withValues(alpha: 0.3),
                                ),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16),
                                borderSide: BorderSide(
                                  color: context.themePrimary,
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
                            style: AppTypography.labelLarge().copyWith(
                              fontSize: 16,
                              color: context.themePrimary,
                            ),
                          ),
                          const SizedBox(height: 12),

                          TextFormField(
                            controller: _billNumberController,
                            style: AppTypography.bodyMedium().copyWith(
                              color: context.themePrimary,
                              fontSize: 16,
                            ),
                            decoration: InputDecoration(
                              filled: true,
                              fillColor: AppColors.white,
                              hintText:
                                  l10n?.enterBillOrInvoiceNumberOptional ??
                                  'Enter bill or invoice number (optional)',
                              hintStyle: AppTypography.bodyMedium().copyWith(
                                color: context.themeTextMuted,
                              ),
                              prefixIcon: Container(
                                margin: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: context.themePrimary.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Icon(
                                  Icons.receipt,
                                  color: context.themePrimary,
                                ),
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16),
                                borderSide: BorderSide(
                                  color: context.themePrimary.withValues(alpha: 0.3),
                                ),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16),
                                borderSide: BorderSide(
                                  color: context.themePrimary.withValues(alpha: 0.3),
                                ),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16),
                                borderSide: BorderSide(
                                  color: context.themePrimary,
                                  width: 2,
                                ),
                              ),
                            ),
                          ),

                          const SizedBox(height: 24),

                          // Notes Field (Optional)
                          Text(
                            l10n?.notesOptional ?? 'Notes (Optional)',
                            style: AppTypography.labelLarge().copyWith(
                              fontSize: 16,
                              color: context.themePrimary,
                            ),
                          ),
                          const SizedBox(height: 12),

                          TextFormField(
                            controller: _notesController,
                            maxLines: 3,
                            style: AppTypography.bodyMedium().copyWith(
                              color: context.themePrimary,
                              fontSize: 16,
                            ),
                            decoration: InputDecoration(
                              filled: true,
                              fillColor: AppColors.white,
                              hintText:
                                  l10n?.addAnyAdditionalNotes ??
                                  'Add any additional notes...',
                              hintStyle: AppTypography.bodyMedium().copyWith(
                                color: context.themeTextMuted,
                              ),
                              prefixIcon: Container(
                                margin: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: context.themePrimary.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Icon(
                                  Icons.note,
                                  color: context.themePrimary,
                                ),
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16),
                                borderSide: BorderSide(
                                  color: context.themePrimary.withValues(alpha: 0.3),
                                ),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16),
                                borderSide: BorderSide(
                                  color: context.themePrimary.withValues(alpha: 0.3),
                                ),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16),
                                borderSide: BorderSide(
                                  color: context.themePrimary,
                                  width: 2,
                                ),
                              ),
                            ),
                          ),

                          const SizedBox(height: 24),
                        ],
                      ),
                    ),
                  ),
                ),

                // Fixed Submit Button at Bottom
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: AppColors.white,
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.black.withValues(alpha: 0.1),
                        blurRadius: 10,
                        offset: const Offset(0, -2),
                      ),
                    ],
                  ),
                  child: SafeArea(
                    child: SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _isSubmitting ? null : _submitBill,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: context.themePrimary,
                          foregroundColor: AppColors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          elevation: 2,
                        ),
                        child: _isSubmitting
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    AppColors.white,
                                  ),
                                ),
                              )
                            : Text(
                                'Submit Bill',
                                style: AppTypography.labelLarge().copyWith(
                                  fontSize: 18,
                                  color: AppColors.white,
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

