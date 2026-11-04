import 'package:balaji_points/core/design/app_radius.dart';
import 'dart:typed_data';
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
import 'package:balaji_points/core/layout/responsive.dart';
import 'package:intl/intl.dart';

class AdminAddBillPage extends StatefulWidget {
  const AdminAddBillPage({super.key});

  @override
  State<AdminAddBillPage> createState() => _AdminAddBillPageState();
}

class _AdminAddBillPageState extends State<AdminAddBillPage> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _siteNameController = TextEditingController();
  final _vendorNameController = TextEditingController();
  final ImagePicker _picker = ImagePicker();
  final BillService _billService = BillService();
  final SessionService _sessionService = SessionService();
  final UserService _userService = UserService();

  Map<String, dynamic>? _selectedCarpenter;
  Uint8List? _selectedImageBytes;
  DateTime _billDate = DateTime.now();
  bool _isSubmitting = false;
  Map<String, dynamic>? _adminData;

  bool _hasFormData() {
    return _selectedCarpenter != null ||
        _amountController.text.trim().isNotEmpty ||
        _siteNameController.text.trim().isNotEmpty ||
        _vendorNameController.text.trim().isNotEmpty ||
        _selectedImageBytes != null;
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
    _siteNameController.dispose();
    _vendorNameController.dispose();
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
        final bytes = await image.readAsBytes();
        setState(() {
          _selectedImageBytes = bytes;
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
        final bytes = await image.readAsBytes();
        setState(() {
          _selectedImageBytes = bytes;
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
                Icons.photo_library_rounded,
                color: context.themeContentColor,
              ),
              title: Text(
                l10n?.selectImage ??
                    AppLocalizations.of(context)!.chooseFromGallery,
              ),
              onTap: () {
                Navigator.pop(context);
                _pickImage();
              },
            ),
            ListTile(
              leading: Icon(
                Icons.camera_alt_rounded,
                color: context.themeContentColor,
              ),
              title: Text(
                l10n?.selectImage ?? AppLocalizations.of(context)!.takePhoto,
              ),
              onTap: () {
                Navigator.pop(context);
                _takePhoto();
              },
            ),
            ListTile(
              leading: Icon(Icons.cancel_rounded, color: context.themeError),
              title: Text(l10n?.cancel ?? AppLocalizations.of(context)!.cancel),
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
          content: Text(AppLocalizations.of(context)!.pleaseSelectACarpenter),
          backgroundColor: context.themeError,
          duration: const Duration(seconds: 3),
        ),
      );
      return;
    }

    final siteName = _siteNameController.text.trim();
    if (siteName.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context)!.siteNameRequired),
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
          content: AppText.label(
            '${l10n?.enterValidAmount ?? 'Please enter a valid amount'}',
          ),
          backgroundColor: context.themeError,
          duration: const Duration(seconds: 3),
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
          setState(() {
            _isSubmitting = false;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                l10n?.sessionExpired ??
                    AppLocalizations.of(context)!.pleaseLoginToSubmitBills,
              ),
              backgroundColor: context.themeError,
              duration: const Duration(seconds: 3),
            ),
          );
        }
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

      final vendorName = _vendorNameController.text.trim().isEmpty
          ? null
          : _vendorNameController.text.trim();

      // CHECK FOR DUPLICATE BILL - FRONTEND VALIDATION
      AppLogger.info('🔍 Admin: Checking for duplicate bill...');
      AppLogger.info(
        '   Carpenter: $carpenterId, Site: $siteName, Amount: $amount',
      );

      final duplicateBill = await _billService.checkDuplicateBill(
        carpenterId: carpenterId,
        vendorName: vendorName,
        siteName: siteName,
        billAmount: amount,
        billDate: _billDate,
      );

      if (mounted) {
        if (duplicateBill != null) {
          AppLogger.warning('⚠️ Duplicate bill detected for admin submission!');
          setState(() => _isSubmitting = false);
          // Show duplicate warning dialog
          _showDuplicateWarningDialog(
            duplicateBill,
            carpenterId,
            carpenterPhone,
            amount,
            adminPhone,
            adminName,
            siteName,
            vendorName,
          );
          return;
        }

        AppLogger.info(
          '✅ No duplicate found, proceeding with admin submission...',
        );

        final success = await _billService.submitBillForCarpenter(
          carpenterId: carpenterId,
          carpenterPhone: carpenterPhone,
          amount: amount,
          adminId: adminPhone,
          adminPhone: adminPhone,
          adminName: adminName,
          imageBytes: _selectedImageBytes,
          billDate: _billDate,
          storeName: siteName,
          vendorName: vendorName,
        );

        if (mounted) {
          setState(() {
            _isSubmitting = false;
          });

          if (success) {
            AppLogger.info('✅ Bill submitted successfully by admin!');
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  l10n?.billSubmitted ??
                      AppLocalizations.of(
                        context,
                      )!.billSubmittedSuccessfullyItWillBe,
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
            AppLogger.error('Failed to submit bill by admin', 'Unknown error');
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  l10n?.billSubmitError ??
                      AppLocalizations.of(context)!.failedToSubmitBillPleaseTry,
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

  void _showDuplicateWarningDialog(
    Map<String, dynamic> duplicateBill,
    String carpenterId,
    String carpenterPhone,
    double amount,
    String adminPhone,
    String? adminName,
    String siteName,
    String? vendorName,
  ) {
    final l10n = AppLocalizations.of(context);
    final duplicateAmount = (duplicateBill['amount'] ?? 0).toDouble();
    final duplicatePoints = duplicateAmount / 1000;

    AppLogger.warning('⚠️ Duplicate Warning Dialog shown to admin');

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
                color: context.themeError.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.warning_amber_rounded,
                color: context.themeError,
                size: 28,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                AppLocalizations.of(context)!.duplicateBill,
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(color: context.themeError),
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
                AppLocalizations.of(context)!.aBillWithTheSameSite,
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500),
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
                          Icons.location_on_rounded,
                          size: 16,
                          color: context.themeError,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                AppLocalizations.of(context)!.site,
                                style: Theme.of(context).textTheme.labelSmall
                                    ?.copyWith(
                                      color: context.themeTextSecondary,
                                    ),
                              ),
                              Text(
                                siteName,
                                style: Theme.of(context).textTheme.bodyMedium
                                    ?.copyWith(fontWeight: FontWeight.w600),
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
                          Icons.currency_rupee_rounded,
                          size: 16,
                          color: AppColors.success,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                AppLocalizations.of(context)!.amountLabel,
                                style: Theme.of(context).textTheme.labelSmall
                                    ?.copyWith(
                                      color: context.themeTextSecondary,
                                    ),
                              ),
                              Text(
                                '₹${duplicateAmount.toStringAsFixed(0)}',
                                style: Theme.of(context).textTheme.bodyMedium
                                    ?.copyWith(
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
                          Icons.stars_rounded,
                          size: 16,
                          color: context.themePrimary,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                AppLocalizations.of(context)!.pointsLabel,
                                style: Theme.of(context).textTheme.labelSmall
                                    ?.copyWith(
                                      color: context.themeTextSecondary,
                                    ),
                              ),
                              Text(
                                AppLocalizations.of(context)!.pts2(
                                  '${duplicatePoints.toStringAsFixed(2)}',
                                ),
                                style: Theme.of(context).textTheme.bodyMedium
                                    ?.copyWith(
                                      fontWeight: FontWeight.w600,
                                      color: context.themePrimary,
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
                      Icons.info_rounded,
                      size: 18,
                      color: AppColors.warning,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        AppLocalizations.of(context)!.pleaseVerifyThisIsNotA,
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
                AppLocalizations.of(context)!.addBillAnywayQuestion,
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              AppLogger.info('Admin cancelled duplicate bill submission');
              Navigator.pop(context);
            },
            child: Text(
              AppLocalizations.of(context)!.cancel,
              style: TextStyle(
                color: context.themePrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              AppLogger.warning('Admin chose to add duplicate bill anyway');
              Navigator.pop(context);
              setState(() => _isSubmitting = true);

              try {
                final success = await _billService.submitBillForCarpenter(
                  carpenterId: carpenterId,
                  carpenterPhone: carpenterPhone,
                  amount: amount,
                  adminId: adminPhone,
                  adminPhone: adminPhone,
                  adminName: adminName,
                  imageBytes: _selectedImageBytes,
                  billDate: _billDate,
                  storeName: siteName,
                  vendorName: vendorName,
                );

                if (mounted) {
                  setState(() => _isSubmitting = false);
                  if (success) {
                    AppLogger.info(
                      '✅ Duplicate bill submitted successfully by admin',
                    );
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          l10n?.billSubmitted ??
                              AppLocalizations.of(
                                context,
                              )!.billSubmittedSuccessfullyItWillBe,
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
                              AppLocalizations.of(
                                context,
                              )!.failedToSubmitBillPleaseTry,
                        ),
                        backgroundColor: context.themeError,
                        duration: const Duration(seconds: 3),
                      ),
                    );
                  }
                }
              } catch (e) {
                AppLogger.error('Error submitting duplicate bill by admin', e);
                if (mounted) {
                  setState(() => _isSubmitting = false);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        AppLocalizations.of(context)!.error2('${e.toString()}'),
                      ),
                      backgroundColor: context.themeError,
                      duration: const Duration(seconds: 3),
                    ),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: context.themeSecondary,
              foregroundColor: context.themeOnSecondary,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            ),
            child: Text(
              AppLocalizations.of(context)!.addAnyway2,
              style: TextStyle(
                color: context.themeOnSecondary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
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
                  AppLocalizations.of(context)!.discardBillMessage,
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
                AppLocalizations.of(context)!.addBillForCarpenter,
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
                    child: ResponsiveContainer(
                      maxWidth: 700,
                      padding: EdgeInsets.zero,
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            const SizedBox(height: 20),

                            // Carpenter Selection
                            AppText.label(
                              AppLocalizations.of(context)!.carpenter2,
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
                              l10n?.billAmount ??
                                  AppLocalizations.of(context)!.billAmount2,
                              color: context.themeContentColor,
                            ),
                            const SizedBox(height: 12),

                            AppTextField(
                              controller: _amountController,
                              label:
                                  l10n?.enterBillAmount ??
                                  AppLocalizations.of(context)!.enterBillAmount, hint: AppLocalizations.of(context)!.hintAmount,
                              keyboardType: TextInputType.number,
                              onChanged: (_) => setState(() {}),
                              prefixIcon: Icons.currency_rupee_rounded,
                              suffix: amount > 0
                                  ? Padding(
                                      padding: const EdgeInsets.only(right: 12),
                                      child: AppText.labelSmall(
                                        AppLocalizations.of(context)!.ptsValue(
                                          '${points.toStringAsFixed(2)}',
                                        ),
                                        color: context.themeContentColor,
                                      ),
                                    )
                                  : null,
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return l10n?.enterBillAmount ??
                                      AppLocalizations.of(
                                        context,
                                      )!.pleaseEnterBillAmount;
                                }
                                final amount = double.tryParse(value.trim());
                                if (amount == null || amount <= 0) {
                                  return l10n?.enterValidAmount ??
                                      AppLocalizations.of(
                                        context,
                                      )!.invalidAmount;
                                }
                                return null;
                              },
                            ),

                            const SizedBox(height: 32),

                            // Bill Date Field
                            AppText.label(
                              l10n?.billDate ??
                                  AppLocalizations.of(context)!.billDate2,
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
                                      Icons.calendar_today_rounded,
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
                                      Icons.arrow_forward_ios_rounded,
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
                              l10n?.billImage ??
                                  AppLocalizations.of(
                                    context,
                                  )!.billImageOptional,
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
                                child: _selectedImageBytes != null
                                    ? ClipRRect(
                                        borderRadius: AppRadius.all16,
                                        child: Image.memory(
                                          _selectedImageBytes!,
                                          fit: BoxFit.cover,
                                        ),
                                      )
                                    : Column(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          Icon(
                                            Icons.add_photo_alternate_rounded,
                                            size: 64,
                                            color: context.themeContentColor
                                                .withValues(alpha: 0.5),
                                          ),
                                          const SizedBox(height: 12),
                                          AppText.bodySmall(
                                            l10n?.tapToAddBillImage ??
                                                AppLocalizations.of(
                                                  context,
                                                )!.tapToAddBillImage,
                                            color: context.themeContentColor
                                                .withValues(alpha: 0.6),
                                          ),
                                        ],
                                      ),
                              ),
                            ),

                            const SizedBox(height: 32),

                            // Site Name Field (Required)
                            AppText.label(
                              AppLocalizations.of(context)!.siteName,
                              color: context.themeContentColor,
                            ),
                            const SizedBox(height: 12),

                            AppTextField(
                              controller: _siteNameController,
                              label: AppLocalizations.of(context)!.siteName2,
                              hint: AppLocalizations.of(
                                context,
                              )!.enterSiteLocationName,
                              prefixIcon: Icons.location_on_rounded,
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return AppLocalizations.of(
                                    context,
                                  )!.siteNameRequired;
                                }
                                return null;
                              },
                            ),

                            const SizedBox(height: 24),

                            // Vendor Name Field (Optional)
                            AppText.label(
                              AppLocalizations.of(context)!.vendorNameOptional,
                              color: context.themeContentColor,
                            ),
                            const SizedBox(height: 12),

                            AppTextField(
                              controller: _vendorNameController,
                              label: AppLocalizations.of(context)!.vendorName,
                              hint: AppLocalizations.of(
                                context,
                              )!.enterVendorStoreNameOptional,
                              prefixIcon: Icons.store_rounded,
                            ),

                            const SizedBox(height: 24),
                          ],
                        ),
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
                    child: ResponsiveContainer(
                      maxWidth: 700,
                      padding: EdgeInsets.zero,
                      child: AppButton.primary(
                        label: AppLocalizations.of(context)!.submitBill,
                        onPressed: _isSubmitting ? null : _submitBill,
                        isLoading: _isSubmitting,
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
