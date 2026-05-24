import 'dart:io';
import 'package:flutter/material.dart';
import 'package:balaji_points/core/design/app_colors.dart';
import 'package:balaji_points/core/design/app_typography.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:balaji_points/services/offer_service.dart';
import 'package:balaji_points/l10n/app_localizations.dart';
import 'package:intl/intl.dart';

class OffersManagement extends StatefulWidget {
  const OffersManagement({super.key});

  @override
  State<OffersManagement> createState() => _OffersManagementState();
}

class _OffersManagementState extends State<OffersManagement> {
  final OfferService _offerService = OfferService();

  void _showCreateOfferDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const CreateOfferDialog(),
    );
  }

  void _showEditOfferDialog(Map<String, dynamic> offer) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => CreateOfferDialog(offer: offer),
    );
  }

  Future<void> _deleteOffer(String offerId, String? bannerUrl) async {
    final l10n = AppLocalizations.of(context)!;
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
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
            child: Text(
              l10n.cancel,
              style: AppTypography.bodySmall().copyWith(
                color: Colors.grey[600],
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
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
            backgroundColor: success ? Colors.green : Colors.red,
          ),
        );
      }
    }
  }

  void _viewBannerImage(String imageUrl) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
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
                      color: Colors.white,
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
                icon: const Icon(Icons.close, color: Colors.white, size: 30),
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
      backgroundColor: AppColors.woodenBackground,
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('offers')
            .orderBy('createdAt', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
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
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            );
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: AppColors.lightPrimary),
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
                    color: Colors.grey[300],
                  ),
                  const SizedBox(height: 20),
                  Text(
                    l10n.noOffersCreated,
                    style: AppTypography.labelLarge().copyWith(
                      fontSize: 20,
                      color: AppColors.lightPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    l10n.createFirstOffer,
                    style: AppTypography.bodyMedium().copyWith(
                      fontSize: 14,
                      color: Colors.grey[600],
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
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
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
                                color: Colors.grey[200],
                                child: const Center(
                                  child: Icon(
                                    Icons.broken_image,
                                    size: 50,
                                    color: Colors.grey,
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
                              Expanded(
                                child: Text(
                                  title,
                                  style: AppTypography.labelLarge().copyWith(
                                    fontSize: 18,
                                    color: AppColors.lightPrimary,
                                  ),
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: isActive
                                      ? Colors.green[100]
                                      : Colors.grey[200],
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  isActive ? l10n.active : l10n.inactive,
                                  style: AppTypography.labelLarge().copyWith(
                                    fontSize: 12,
                                    color: isActive
                                        ? Colors.green[900]
                                        : Colors.grey[700],
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
                                color: Colors.grey[700],
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
                              gradient: LinearGradient(
                                colors: [
                                  AppColors.lightPrimary,
                                  AppColors.lightSecondary,
                                ],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.stars,
                                  color: Colors.white,
                                  size: 20,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  l10n.points(points),
                                  style: AppTypography.labelLarge().copyWith(
                                    fontSize: 16,
                                    color: Colors.white,
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
                                color: Colors.grey[600],
                              ),
                              const SizedBox(width: 6),
                              Text(
                                createdAt != null
                                    ? '${l10n.createdLabel}: ${DateFormat('dd MMM yyyy').format(createdAt.toDate())}'
                                    : l10n.noDate,
                                style: AppTypography.bodyMedium().copyWith(
                                  fontSize: 12,
                                  color: Colors.grey[600],
                                ),
                              ),
                              if (validUntil != null) ...[
                                const SizedBox(width: 12),
                                Icon(
                                  Icons.event_busy,
                                  size: 14,
                                  color: Colors.orange[700],
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
                                    color: Colors.orange[700],
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
                                    foregroundColor: AppColors.lightPrimary,
                                    side: const BorderSide(
                                      color: AppColors.lightPrimary,
                                    ),
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 12,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
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
                                    foregroundColor: Colors.red,
                                    side: BorderSide(color: Colors.red[300]!),
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 12,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
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
        onPressed: _showCreateOfferDialog,
        backgroundColor: AppColors.lightSecondary,
        icon: const Icon(Icons.add),
        label: Text(
          l10n.createOffer,
          style: AppTypography.labelLarge().copyWith(fontSize: 16),
        ),
      ),
    );
  }
}

// Create/Edit Offer Dialog
class CreateOfferDialog extends StatefulWidget {
  final Map<String, dynamic>? offer;

  const CreateOfferDialog({super.key, this.offer});

  @override
  State<CreateOfferDialog> createState() => _CreateOfferDialogState();
}

class _CreateOfferDialogState extends State<CreateOfferDialog> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _pointsController = TextEditingController();

  final OfferService _offerService = OfferService();

  File? _bannerFile;
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
        setState(() {
          _bannerFile = File(image.path);
        });
      }
    } catch (e) {
      if (mounted) {
        final l10n = AppLocalizations.of(context)!;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${l10n.failedToPickImage}: ${e.toString()}'),
            backgroundColor: Colors.red,
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
              primary: AppColors.lightPrimary,
              onPrimary: Colors.white,
              onSurface: AppColors.lightPrimary,
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
      if (!isEditMode && _bannerFile == null && bannerUrl == null) {
        throw Exception('Please upload a banner image');
      }

      // Upload new banner if selected
      if (_bannerFile != null) {
        setState(() {
          _isUploadingBanner = true;
        });

        final uploadedUrl = await _offerService.uploadOfferBanner(_bannerFile!);
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
              backgroundColor: Colors.green,
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
            backgroundColor: Colors.red,
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

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 500, maxHeight: 700),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppColors.lightPrimary, AppColors.lightSecondary],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.local_offer, color: Colors.white, size: 28),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      isEditMode ? l10n.editOffer : l10n.createNewOffer,
                      style: AppTypography.labelLarge().copyWith(
                        fontSize: 20,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white),
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
                            color: Colors.grey[100],
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.grey[300]!),
                          ),
                          child: _bannerFile != null
                              ? ClipRRect(
                                  borderRadius: BorderRadius.circular(12),
                                  child: Image.file(
                                    _bannerFile!,
                                    fit: BoxFit.cover,
                                    width: double.infinity,
                                  ),
                                )
                              : _existingBannerUrl != null
                              ? ClipRRect(
                                  borderRadius: BorderRadius.circular(12),
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
                                      color: Colors.grey[400],
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      l10n.tapToUploadBanner,
                                      style: AppTypography.bodySmall()
                                          .copyWith(
                                            fontSize: 14,
                                            color: Colors.grey[600],
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
                        style: AppTypography.bodyMedium().copyWith(
                          fontSize: 16,
                        ),
                        decoration: InputDecoration(
                          labelText: l10n.offerTitleLabel,
                          labelStyle: AppTypography.bodySmall().copyWith(
                            color: AppColors.lightPrimary,
                          ),
                          hintText: l10n.offerTitleHint,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                              color: AppColors.lightPrimary,
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
                        style: AppTypography.bodyMedium().copyWith(
                          fontSize: 16,
                        ),
                        maxLines: 3,
                        decoration: InputDecoration(
                          labelText: l10n.descriptionLabel,
                          labelStyle: AppTypography.bodySmall().copyWith(
                            color: AppColors.lightPrimary,
                          ),
                          hintText: l10n.descriptionHint,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                              color: AppColors.lightPrimary,
                              width: 2,
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 16),

                      // Points (Optional)
                      TextFormField(
                        controller: _pointsController,
                        style: AppTypography.bodyMedium().copyWith(
                          fontSize: 16,
                        ),
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          labelText: l10n.pointsRequiredLabel.replaceAll('*', '').trim(),
                          labelStyle: AppTypography.bodySmall().copyWith(
                            color: AppColors.lightPrimary,
                          ),
                          hintText: l10n.pointsHint,
                          prefixIcon: const Icon(
                            Icons.stars,
                            color: AppColors.lightSecondary,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                              color: AppColors.lightPrimary,
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
                            border: Border.all(color: Colors.grey[400]!),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.event,
                                color: AppColors.lightPrimary,
                              ),
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
                                        ? AppColors.lightPrimary
                                        : Colors.grey[600],
                                  ),
                                ),
                              ),
                              if (_validUntil != null)
                                IconButton(
                                  icon: Icon(
                                    Icons.clear,
                                    size: 20,
                                    color: Colors.grey[600],
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
                          color: Colors.grey[100],
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.visibility,
                              color: AppColors.lightPrimary,
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
                              activeTrackColor: AppColors.lightSecondary,
                              activeColor: Colors.white,
                            ),
                            Text(
                              _isActive ? l10n.active : l10n.inactive,
                              style: AppTypography.labelLarge().copyWith(
                                fontSize: 14,
                                color: _isActive ? Colors.green : Colors.grey,
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
                              const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    AppColors.lightPrimary,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Text(
                                l10n.uploadingBanner,
                                style: AppTypography.bodySmall().copyWith(
                                  fontSize: 14,
                                  color: AppColors.lightPrimary,
                                ),
                              ),
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
                            backgroundColor: AppColors.lightSecondary,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: _isSaving
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      Colors.white,
                                    ),
                                  ),
                                )
                              : Text(
                                  isEditMode
                                      ? l10n.updateOffer
                                      : l10n.createOffer,
                                  style: AppTypography.labelLarge().copyWith(
                                    fontSize: 16,
                                    color: Colors.white,
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
      ),
    );
  }
}
