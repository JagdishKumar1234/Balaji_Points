import 'package:balaji_points/core/design/app_radius.dart';
import 'package:balaji_points/presentation/widgets/shared/app_text.dart';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:balaji_points/core/design/app_colors.dart';
import 'package:balaji_points/core/design/app_typography.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:balaji_points/services/platform/offer_service.dart';
import 'package:balaji_points/l10n/app_localizations.dart';
import 'package:intl/intl.dart';

class OffersManagement extends StatefulWidget {
  const OffersManagement({super.key});

  @override
  State<OffersManagement> createState() => _OffersManagementState();
}

class _OffersManagementState extends State<OffersManagement> {
  final OfferService _offerService = OfferService();

  void _navigateToCreateOfferPage() {
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (context) => const CreateOfferPage()));
  }

  void _showEditOfferDialog(Map<String, dynamic> offer) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: AppRadius.all16),
        child: CreateOfferForm(offer: offer),
      ),
    );
  }

  Future<void> _deleteOffer(String offerId, String? bannerUrl) async {
    final l10n = AppLocalizations.of(context)!;
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: AppRadius.all16),
        title: Text(
          l10n.deleteOffer,
          style: AppTypography.labelLarge().copyWith(fontSize: 20),
        ),
        content: Text(
          l10n.deleteOfferConfirmation,
          style: AppTypography.bodyMedium().copyWith(fontSize: 16),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: AppText.bodySmall(l10n.cancel),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: context.themeError,
              shape: RoundedRectangleBorder(borderRadius: AppRadius.md12),
            ),
            child: Text(l10n.delete, style: AppTypography.labelLarge()),
          ),
        ],
      ),
    );

    if (shouldDelete == true) {
      final success = await _offerService.deleteOffer(offerId, bannerUrl);

      if (mounted) {
        final l10n = AppLocalizations.of(context)!;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              success ? l10n.offerDeletedSuccess : l10n.failedToDeleteOffer,
            ),
            backgroundColor: success ? AppColors.success : context.themeError,
          ),
        );
      }
    }
  }

  void _viewBannerImage(String imageUrl) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: AppColors.transparent,
        child: Stack(
          children: [
            Center(
              child: InteractiveViewer(
                child: Image.network(
                  imageUrl,
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      padding: const EdgeInsets.all(20),
                      color: context.themeSoftSurface,
                      child: const Text('Failed to load image'),
                    );
                  },
                ),
              ),
            ),
            Positioned(
              top: 40,
              right: 20,
              child: IconButton(
                icon: const Icon(Icons.close, color: AppColors.white, size: 30),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: context.themeSoftSurface,
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('offers').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.error_outline,
                    size: 64,
                    color: context.themeError,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    l10n.errorLoadingOffers,
                    style: AppTypography.labelLarge().copyWith(fontSize: 18),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    snapshot.error.toString(),
                    textAlign: TextAlign.center,
                    style: AppTypography.bodyMedium().copyWith(
                      fontSize: 14,
                      color: context.themeTextSecondary,
                    ),
                  ),
                ],
              ),
            );
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(
              child: CircularProgressIndicator(
                color: context.themeContentColor,
              ),
            );
          }

          final offers = snapshot.data?.docs ?? [];

          if (offers.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.local_offer_outlined,
                    size: 80,
                    color: context.themeBorder,
                  ),
                  const SizedBox(height: 20),
                  AppText.label(l10n.noOffersCreated),
                  const SizedBox(height: 8),
                  Text(
                    l10n.createFirstOffer,
                    style: AppTypography.bodyMedium().copyWith(
                      fontSize: 14,
                      color: context.themeTextSecondary,
                    ),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: offers.length,
            itemBuilder: (context, index) {
              final offer = offers[index].data() as Map<String, dynamic>;
              final offerId = offers[index].id;

              final title = offer['title'] ?? 'Untitled';
              final description = offer['description'] ?? '';
              final points = offer['points'] ?? 0;
              final bannerUrl = offer['bannerUrl'] ?? '';
              final isActive = offer['isActive'] ?? true;
              final createdAt = offer['createdAt'] as Timestamp?;
              final validUntil = offer['validUntil'] as Timestamp?;

              return Card(
                margin: const EdgeInsets.only(bottom: 16),
                elevation: 2,
                shape: RoundedRectangleBorder(borderRadius: AppRadius.all16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Banner Image
                    if (bannerUrl.isNotEmpty)
                      GestureDetector(
                        onTap: () => _viewBannerImage(bannerUrl),
                        child: ClipRRect(
                          borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(16),
                          ),
                          child: Image.network(
                            bannerUrl,
                            height: 180,
                            width: double.infinity,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return Container(
                                height: 180,
                                color: context.themeBorder,
                                child: Center(
                                  child: Icon(
                                    Icons.broken_image,
                                    size: 50,
                                    color: context.themeTextSecondary,
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ),

                    // Offer Details
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Title and Status
                          Row(
                            children: [
                              Expanded(child: AppText.label(title)),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: isActive
                                      ? AppColors.success
                                      : context.themeBorder,
                                  borderRadius: AppRadius.sm8,
                                ),
                                child: Text(
                                  isActive ? l10n.active : l10n.inactive,
                                  style: AppTypography.labelLarge().copyWith(
                                    fontSize: 12,
                                    color: isActive
                                        ? AppColors.white
                                        : context.themeTextSecondary,
                                  ),
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 8),

                          // Description
                          if (description.isNotEmpty)
                            Text(
                              description,
                              style: AppTypography.bodyMedium().copyWith(
                                fontSize: 14,
                                color: context.themeTextSecondary,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),

                          const SizedBox(height: 12),

                          // Points Badge
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: context.themePrimary,
                              borderRadius: AppRadius.md12,
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.stars,
                                  color: AppColors.white,
                                  size: 20,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  l10n.points(points),
                                  style: AppTypography.labelLarge().copyWith(
                                    fontSize: 16,
                                    color: AppColors.white,
                                  ),
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 12),

                          // Dates
                          Row(
                            children: [
                              Icon(
                                Icons.calendar_today,
                                size: 14,
                                color: context.themeTextSecondary,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                createdAt != null
                                    ? '${l10n.createdLabel}: ${DateFormat('dd MMM yyyy').format(createdAt.toDate())}'
                                    : l10n.noDate,
                                style: AppTypography.bodyMedium().copyWith(
                                  fontSize: 12,
                                  color: context.themeTextSecondary,
                                ),
                              ),
                              if (validUntil != null) ...[
                                const SizedBox(width: 12),
                                Icon(
                                  Icons.event_busy,
                                  size: 14,
                                  color: context.themeContentColor,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  l10n.validUntilDisplay(
                                    DateFormat(
                                      'dd MMM',
                                    ).format(validUntil.toDate()),
                                  ),
                                  style: AppTypography.bodyMedium().copyWith(
                                    fontSize: 12,
                                    color: context.themeContentColor,
                                  ),
                                ),
                              ],
                            ],
                          ),

                          const SizedBox(height: 16),

                          // Action Buttons
                          Row(
                            children: [
                              Expanded(
                                child: OutlinedButton.icon(
                                  onPressed: () {
                                    offer['offerId'] = offerId;
                                    _showEditOfferDialog(offer);
                                  },
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: context.themePrimary,
                                    side: BorderSide(
                                      color: context.themeContentColor,
                                    ),
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 12,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: AppRadius.md12,
                                    ),
                                  ),
                                  icon: const Icon(Icons.edit, size: 18),
                                  label: Text(
                                    l10n.edit,
                                    style: AppTypography.labelLarge(),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: OutlinedButton.icon(
                                  onPressed: () =>
                                      _deleteOffer(offerId, bannerUrl),
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: context.themeError,
                                    side: BorderSide(color: context.themeError),
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 12,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: AppRadius.md12,
                                    ),
                                  ),
                                  icon: const Icon(Icons.delete, size: 18),
                                  label: Text(
                                    l10n.delete,
                                    style: AppTypography.labelLarge(),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _navigateToCreateOfferPage,
        backgroundColor: context.themeSecondary,
        foregroundColor: AppColors.white,
        shape: RoundedRectangleBorder(borderRadius: AppRadius.all16),
        icon: const Icon(Icons.add),
        label: Text(
          l10n.createOffer,
          style: AppTypography.labelLarge().copyWith(fontSize: 16),
        ),
      ),
    );
  }
}

class CreateOfferPage extends StatelessWidget {
  const CreateOfferPage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          l10n.createNewOffer,
          style: AppTypography.labelLarge().copyWith(fontSize: 20),
        ),
        titleTextStyle: AppTypography.labelLarge().copyWith(
          fontSize: 20,
          color: AppColors.white,
        ),
        backgroundColor: context.themeContentColor,
        iconTheme: const IconThemeData(color: AppColors.white),
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
            child: CreateOfferForm(),
          ),
        ),
      ),
    );
  }
}

// Create/Edit Offer Form
class CreateOfferForm extends StatefulWidget {
  final Map<String, dynamic>? offer;

  const CreateOfferForm({super.key, this.offer});

  @override
  State<CreateOfferForm> createState() => _CreateOfferFormState();
}

class _CreateOfferFormState extends State<CreateOfferForm> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _pointsController = TextEditingController();

  final OfferService _offerService = OfferService();

  Uint8List? _bannerBytes;
  String? _existingBannerUrl;
  bool _isActive = true;
  DateTime? _validUntil;
  bool _isSaving = false;
  bool _isUploadingBanner = false;

  bool get isEditMode => widget.offer != null;

  @override
  void initState() {
    super.initState();
    if (isEditMode) {
      _titleController.text = widget.offer!['title'] ?? '';
      _descriptionController.text = widget.offer!['description'] ?? '';
      _pointsController.text = (widget.offer!['points'] ?? 0).toString();
      _existingBannerUrl = widget.offer!['bannerUrl'];
      _isActive = widget.offer!['isActive'] ?? true;
      final validUntilTimestamp = widget.offer!['validUntil'] as Timestamp?;
      _validUntil = validUntilTimestamp?.toDate();
    }
  }

  Future<void> _pickBanner() async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1200,
        maxHeight: 800,
        imageQuality: 85,
      );

      if (image != null) {
        final bytes = await image.readAsBytes();
        setState(() {
          _bannerBytes = bytes;
        });
      }
    } catch (e) {
      if (mounted) {
        final l10n = AppLocalizations.of(context)!;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${l10n.failedToPickImage}: ${e.toString()}'),
            backgroundColor: context.themeError,
          ),
        );
      }
    }
  }

  Future<void> _selectValidUntilDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _validUntil ?? DateTime.now().add(const Duration(days: 30)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: context.themePrimary,
              onPrimary: AppColors.white,
              onSurface: context.themePrimary,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _validUntil = picked;
      });
    }
  }

  Future<void> _saveOffer() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      final title = _titleController.text.trim();
      final description = _descriptionController.text.trim();

      // Points is optional
      final pointsText = _pointsController.text.trim();
      int? points;
      if (pointsText.isNotEmpty) {
        points = int.tryParse(pointsText);
        if (points == null) {
          throw Exception('Please enter a valid number for points');
        }
      }
      // If points is empty and in edit mode, we'll pass null to preserve existing value
      // If points is empty and in create mode, we'll use 0

      String? bannerUrl = _existingBannerUrl;

      // Banner is mandatory for new offers - check if we have one
      if (!isEditMode && _bannerBytes == null && bannerUrl == null) {
        throw Exception('Please upload a banner image');
      }

      // Upload new banner if selected
      if (_bannerBytes != null) {
        setState(() {
          _isUploadingBanner = true;
        });

        final uploadedUrl = await _offerService.uploadOfferBanner(_bannerBytes!);
        if (uploadedUrl != null) {
          bannerUrl = uploadedUrl;
        } else {
          throw Exception('Failed to upload banner image');
        }

        setState(() {
          _isUploadingBanner = false;
        });
      }

      bool success;
      if (isEditMode) {
        success = await _offerService.updateOffer(
          offerId: widget.offer!['offerId'],
          title: title,
          description: description.isEmpty ? null : description,
          points: points,
          bannerUrl: bannerUrl,
          isActive: _isActive,
          validUntil: _validUntil,
          oldBannerUrl: _existingBannerUrl,
        );
      } else {
        success = await _offerService.createOffer(
          title: title,
          description: description.isEmpty ? null : description,
          points: points ?? 0,
          bannerUrl: bannerUrl,
          isActive: _isActive,
          validUntil: _validUntil,
        );
      }

      if (mounted) {
        final l10n = AppLocalizations.of(context)!;
        if (success) {
          Navigator.of(context).pop();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                isEditMode
                    ? l10n.offerUpdatedSuccess
                    : l10n.offerCreatedSuccess,
              ),
              backgroundColor: AppColors.success,
            ),
          );
        } else {
          throw Exception(l10n.failedToSaveOffer);
        }
      }
    } catch (e) {
      if (mounted) {
        final l10n = AppLocalizations.of(context)!;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${l10n.error}: ${e.toString()}'),
            backgroundColor: context.themeError,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
          _isUploadingBanner = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _pointsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Container(
      constraints: const BoxConstraints(maxWidth: 500, maxHeight: 700),
      decoration: BoxDecoration(
        borderRadius: AppRadius.all16,
        color: context.themeSurface,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: context.themeContentColor,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(20),
              ),
            ),
            child: Row(
              children: [
                const Icon(Icons.local_offer, color: AppColors.white, size: 28),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    isEditMode ? l10n.editOffer : l10n.createNewOffer,
                    style: AppTypography.labelLarge().copyWith(
                      fontSize: 20,
                      color: AppColors.white,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: AppColors.white),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
          ),

          // Form Content
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Banner Image Picker
                    GestureDetector(
                      onTap: _pickBanner,
                      child: Container(
                        height: 160,
                        decoration: BoxDecoration(
                          color: context.themeSoftSurface,
                          borderRadius: AppRadius.md12,
                          border: Border.all(color: context.themeBorder),
                        ),
                        child: _bannerBytes != null
                            ? ClipRRect(
                                borderRadius: AppRadius.md12,
                                child: Image.memory(
                                  _bannerBytes!,
                                  fit: BoxFit.cover,
                                  width: double.infinity,
                                ),
                              )
                            : _existingBannerUrl != null
                            ? ClipRRect(
                                borderRadius: AppRadius.md12,
                                child: Image.network(
                                  _existingBannerUrl!,
                                  fit: BoxFit.cover,
                                  width: double.infinity,
                                ),
                              )
                            : Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.add_photo_alternate,
                                    size: 48,
                                    color: context.themeTextMuted,
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    l10n.tapToUploadBanner,
                                    style: AppTypography.bodySmall().copyWith(
                                      fontSize: 14,
                                      color: context.themeTextSecondary,
                                    ),
                                  ),
                                ],
                              ),
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Title
                    TextFormField(
                      controller: _titleController,
                      style: AppTypography.bodyMedium().copyWith(fontSize: 16),
                      decoration: InputDecoration(
                        labelText: l10n.offerTitleLabel,
                        labelStyle: AppTypography.bodySmall().copyWith(
                          color: context.themeContentColor,
                        ),
                        hintText: l10n.offerTitleHint,
                        border: OutlineInputBorder(
                          borderRadius: AppRadius.md12,
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: AppRadius.md12,
                          borderSide: BorderSide(
                            color: context.themeContentColor,
                            width: 2,
                          ),
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return l10n.enterOfferTitle;
                        }
                        return null;
                      },
                    ),

                    const SizedBox(height: 16),

                    // Description
                    TextFormField(
                      controller: _descriptionController,
                      style: AppTypography.bodyMedium().copyWith(fontSize: 16),
                      maxLines: 3,
                      decoration: InputDecoration(
                        labelText: l10n.descriptionLabel,
                        labelStyle: AppTypography.bodySmall().copyWith(
                          color: context.themeContentColor,
                        ),
                        hintText: l10n.descriptionHint,
                        border: OutlineInputBorder(
                          borderRadius: AppRadius.md12,
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: AppRadius.md12,
                          borderSide: BorderSide(
                            color: context.themeContentColor,
                            width: 2,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Points (Optional)
                    TextFormField(
                      controller: _pointsController,
                      style: AppTypography.bodyMedium().copyWith(fontSize: 16),
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: l10n.pointsRequiredLabel
                            .replaceAll('*', '')
                            .trim(),
                        labelStyle: AppTypography.bodySmall().copyWith(
                          color: context.themeContentColor,
                        ),
                        hintText: l10n.pointsHint,
                        prefixIcon: Icon(
                          Icons.stars,
                          color: context.themeContentColor,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: AppRadius.md12,
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: AppRadius.md12,
                          borderSide: BorderSide(
                            color: context.themeContentColor,
                            width: 2,
                          ),
                        ),
                      ),
                      validator: (value) {
                        // Points is optional, but if provided, must be a valid number
                        if (value != null && value.trim().isNotEmpty) {
                          if (int.tryParse(value) == null) {
                            return l10n.enterValidNumber;
                          }
                        }
                        return null;
                      },
                    ),

                    const SizedBox(height: 16),

                    // Valid Until Date
                    InkWell(
                      onTap: _selectValidUntilDate,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 14,
                        ),
                        decoration: BoxDecoration(
                          border: Border.all(color: context.themeTextMuted),
                          borderRadius: AppRadius.md12,
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.event, color: context.themeContentColor),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                _validUntil != null
                                    ? l10n.validUntilDisplay(
                                        DateFormat(
                                          'dd MMM yyyy',
                                        ).format(_validUntil!),
                                      )
                                    : l10n.setValidUntilDate,
                                style: AppTypography.bodyMedium().copyWith(
                                  fontSize: 16,
                                  color: _validUntil != null
                                      ? context.themePrimary
                                      : context.themeTextSecondary,
                                ),
                              ),
                            ),
                            if (_validUntil != null)
                              IconButton(
                                icon: Icon(
                                  Icons.clear,
                                  size: 20,
                                  color: context.themeTextSecondary,
                                ),
                                onPressed: () {
                                  setState(() {
                                    _validUntil = null;
                                  });
                                },
                              ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Active Status Toggle
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: context.themeSoftSurface,
                        borderRadius: AppRadius.md12,
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.visibility,
                            color: context.themeContentColor,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              l10n.offerStatus,
                              style: AppTypography.bodySmall().copyWith(
                                fontSize: 16,
                              ),
                            ),
                          ),
                          Switch(
                            value: _isActive,
                            onChanged: (value) {
                              setState(() {
                                _isActive = value;
                              });
                            },
                            activeTrackColor: context.themeSecondary,
                            activeThumbColor: AppColors.white,
                          ),
                          Text(
                            _isActive ? l10n.active : l10n.inactive,
                            style: AppTypography.labelLarge().copyWith(
                              fontSize: 14,
                              color: _isActive
                                  ? AppColors.success
                                  : context.themeTextSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Upload Status
                    if (_isUploadingBanner)
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
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  context.themePrimary,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            AppText.bodySmall(l10n.uploadingBanner),
                          ],
                        ),
                      ),

                    // Save Button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: (_isSaving || _isUploadingBanner)
                            ? null
                            : _saveOffer,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: context.themeSecondary,
                          foregroundColor: AppColors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: AppRadius.md12,
                          ),
                        ),
                        child: _isSaving
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
                                isEditMode
                                    ? l10n.updateOffer
                                    : l10n.createOffer,
                                style: AppTypography.labelLarge().copyWith(
                                  fontSize: 16,
                                  color: AppColors.white,
                                ),
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
