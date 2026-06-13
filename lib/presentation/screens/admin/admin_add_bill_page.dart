import 'package:balaji_points/core/design/app_radius.dart';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:balaji_points/core/design/app_colors.dart';
import 'package:balaji_points/presentation/widgets/shared/app_button.dart';
import 'package:balaji_points/presentation/widgets/shared/app_text.dart';
import 'package:balaji_points/presentation/widgets/shared/app_text_field.dart';
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
                color: context.themeContentColor,
              ),
              title: Text(l10n?.selectImage ?? 'Choose from Gallery'),
              onTap: () {
                Navigator.pop(context);
                _pickImage();
              },
            ),
            ListTile(
              leading: Icon(Icons.camera_alt, color: context.themeContentColor),
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

  double _calculatePoints(double amount) {
    return amount / 1000;
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
          content: AppText.label(
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

      final carpenterId =
          _selectedCarpenter!['userId'] as String? ??
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
              backgroundColor: context.themeBackground,
              foregroundColor: context.themePrimary,
              elevation: 0,
              leading: IconButton(
                icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 22),
                onPressed: () => context.pop(),
              ),
              title: AppText.label(
                'Add Bill for Carpenter',
                color: context.themeContentColor,
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
                          AppText.label(
                            'Carpenter *',
                            color: context.themeContentColor,
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
                          AppText.label(
                            l10n?.billAmount ?? 'Bill Amount (₹) *',
                            color: context.themeContentColor,
                          ),
                          const SizedBox(height: 12),

                          AppTextField(
                            controller: _amountController,
                            label: l10n?.enterBillAmount ?? 'Enter bill amount',
                            keyboardType: TextInputType.number,
                            onChanged: (_) => setState(() {}),
                            prefixIcon: Icons.currency_rupee,
                            suffix: amount > 0
                                ? Padding(
                                    padding: const EdgeInsets.only(right: 12),
                                    child: AppText.labelSmall('${points.toStringAsFixed(2)} pts', color: context.themeContentColor),
                                  )
                                : null,
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
                          AppText.label(
                            l10n?.billDate ?? 'Bill Date *',
                            color: context.themeContentColor,
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
                                    color: context.themeContentColor,
                                    size: 24,
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: AppText.body(
                                      DateFormat(
                                        'dd MMM yyyy',
                                      ).format(_billDate),
                                      color: context.themeContentColor,
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

                          const SizedBox(height: 32),

                          // Bill Image Section
                          AppText.label(
                            l10n?.billImage ?? 'Bill Image (Optional)',
                            color: context.themeContentColor,
                          ),
                          const SizedBox(height: 12),

                          GestureDetector(
                            onTap: _showImageSourceDialog,
                            child: Container(
                              height: 200,
                              decoration: BoxDecoration(
                                color: context.themeSurface,
                                borderRadius: AppRadius.all16,
                                border: Border.all(
                                  color: context.themePrimary.withValues(
                                    alpha: 0.3,
                                  ),
                                  width: 2,
                                  style: BorderStyle.solid,
                                ),
                              ),
                              child: _selectedImage != null
                                  ? ClipRRect(
                                      borderRadius: AppRadius.all16,
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
                                          color: context.themeContentColor
                                              .withValues(alpha: 0.5),
                                        ),
                                        const SizedBox(height: 12),
                                        AppText.bodySmall(
                                          l10n?.tapToAddBillImage ??
                                              'Tap to add bill image',
                                          color: context.themeContentColor
                                              .withValues(alpha: 0.6),
                                        ),
                                      ],
                                    ),
                            ),
                          ),

                          const SizedBox(height: 32),

                          // Store Name Field
                          AppText.label(
                            l10n?.storeVendorNameOptional ??
                                'Store/Vendor Name (Optional)',
                            color: context.themeContentColor,
                          ),
                          const SizedBox(height: 12),

                          AppTextField(
                            controller: _storeNameController,
                            label:
                                l10n?.enterStoreOrVendorNameOptional ??
                                'Enter store or vendor name (optional)',
                            prefixIcon: Icons.store,
                          ),

                          const SizedBox(height: 24),

                          // Bill Number Field
                          AppText.label(
                            l10n?.billInvoiceNumberOptional ??
                                'Bill/Invoice Number (Optional)',
                            color: context.themeContentColor,
                          ),
                          const SizedBox(height: 12),

                          AppTextField(
                            controller: _billNumberController,
                            label:
                                l10n?.enterBillOrInvoiceNumberOptional ??
                                'Enter bill or invoice number (optional)',
                            prefixIcon: Icons.receipt,
                          ),

                          const SizedBox(height: 24),

                          // Notes Field (Optional)
                          AppText.label(
                            l10n?.notesOptional ?? 'Notes (Optional)',
                            color: context.themeContentColor,
                          ),
                          const SizedBox(height: 12),

                          AppTextField(
                            controller: _notesController,
                            label:
                                l10n?.addAnyAdditionalNotes ??
                                'Add any additional notes...',
                            prefixIcon: Icons.note,
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
                    color: context.themeBackground,
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.black.withValues(alpha: 0.1),
                        blurRadius: 10,
                        offset: const Offset(0, -2),
                      ),
                    ],
                  ),
                  child: SafeArea(
                    child: AppButton.primary(
                      label: 'Submit Bill',
                      onPressed: _isSubmitting ? null : _submitBill,
                      isLoading: _isSubmitting,
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
