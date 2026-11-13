import 'package:balaji_points/services/branch/current_branch_service.dart';
import 'package:balaji_points/services/platform/offer_visibility.dart';
import 'package:balaji_points/presentation/widgets/shared/full_screen_image_viewer.dart';
import 'package:balaji_points/core/design/app_radius.dart';
import 'package:balaji_points/presentation/widgets/shared/app_text.dart';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:balaji_points/presentation/widgets/shared/app_button.dart';
import 'package:balaji_points/presentation/widgets/shared/app_loader.dart';
import 'package:balaji_points/presentation/widgets/shared/admin_form_footer.dart';
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
  late final OfferService _offerService = OfferService();

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
              foregroundColor: context.themeOnError,
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
    showFullScreenImage(context, imageUrl);
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
                    Icons.error_outline_rounded,
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
            return Center(child: AppLoader(color: context.themeContentColor));
          }

          // Only this admin's branch's offers, in the order members see.
          final offers =
              (snapshot.data?.docs ?? [])
                  .where(
                    (doc) => OfferVisibility.adminCanSee(
                      doc.data() as Map<String, dynamic>?,
                      CurrentBranchService.adminBranchId,
                    ),
                  )
                  .toList()
                ..sort(
                  (a, b) => OfferVisibility.compare(
                    a.data() as Map<String, dynamic>,
                    b.data() as Map<String, dynamic>,
                  ),
                );

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
            // First row: "Arrange order" when there is more than one offer.
            itemCount: offers.length + (offers.length > 1 ? 1 : 0),
            itemBuilder: (context, rowIndex) {
              if (offers.length > 1 && rowIndex == 0) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Align(
                    alignment: Alignment.centerRight,
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.swap_vert_rounded),
                      label: Text(l10n.offersArrange),
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ArrangeOffersPage(
                            offers: [
                              for (final d in offers)
                                (
                                  id: d.id,
                                  data: d.data() as Map<String, dynamic>,
                                ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              }
              final index = offers.length > 1 ? rowIndex - 1 : rowIndex;
              final offer = offers[index].data() as Map<String, dynamic>;
              final offerId = offers[index].id;

              final title =
                  offer['title'] ?? AppLocalizations.of(context)!.untitled;
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
                                    Icons.broken_image_rounded,
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
                                  Icons.stars_rounded,
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
                                Icons.calendar_today_rounded,
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
                                  Icons.event_busy_rounded,
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
                                  icon: const Icon(
                                    Icons.edit_rounded,
                                    size: 18,
                                  ),
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
                                  icon: const Icon(
                                    Icons.delete_rounded,
                                    size: 18,
                                  ),
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
        foregroundColor: context.themeOnSecondary,
        shape: RoundedRectangleBorder(borderRadius: AppRadius.all16),
        icon: const Icon(Icons.add_rounded),
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
  Widget build(BuildContext context) => const CreateOfferForm(asPage: true);
}

// Create/Edit Offer Form
class CreateOfferForm extends StatefulWidget {
  final Map<String, dynamic>? offer;

  /// Full-screen page (own app bar and fixed Save footer) instead of the
  /// card used in the Edit dialog.
  final bool asPage;

  const CreateOfferForm({super.key, this.offer, this.asPage = false});

  @override
  State<CreateOfferForm> createState() => _CreateOfferFormState();
}

class _CreateOfferFormState extends State<CreateOfferForm> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _pointsController = TextEditingController();

  late final OfferService _offerService = OfferService();

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
          throw Exception(
            AppLocalizations.of(context)!.pleaseEnterAValidNumberFor,
          );
        }
      }
      // If points is empty and in edit mode, we'll pass null to preserve existing value
      // If points is empty and in create mode, we'll use 0

      String? bannerUrl = _existingBannerUrl;

      // Banner is mandatory for new offers - check if we have one
      if (!isEditMode && _bannerBytes == null && bannerUrl == null) {
        throw Exception(AppLocalizations.of(context)!.pleaseUploadABannerImage);
      }

      // Upload new banner if selected
      if (_bannerBytes != null) {
        setState(() {
          _isUploadingBanner = true;
        });

        final uploadedUrl = await _offerService.uploadOfferBanner(
          _bannerBytes!,
        );
        if (uploadedUrl != null) {
          bannerUrl = uploadedUrl;
        } else {
          throw Exception(
            AppLocalizations.of(context)!.failedToUploadBannerImage,
          );
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
    final title = isEditMode ? l10n.editOffer : l10n.createNewOffer;

    if (widget.asPage) {
      // One app bar, fields in one scroll, Save fixed at the bottom (above
      // Android's navigation bar and the keyboard).
      return Scaffold(
        backgroundColor: context.themeBackground,
        appBar: AppBar(title: Text(title)),
        body: SafeArea(
          bottom: false,
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 560),
                child: _fields(context),
              ),
            ),
          ),
        ),
        bottomNavigationBar: AdminFormFooter(child: _saveButton(context)),
      );
    }

    // Edit dialog: compact header, scrolling fields, Save pinned below.
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 520, maxHeight: 720),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 8, 4),
            child: Row(
              children: [
                Icon(Icons.local_offer_rounded, color: context.themePrimary),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    title,
                    style: AppTypography.h5(color: context.themeTextPrimary),
                  ),
                ),
                IconButton(
                  tooltip: MaterialLocalizations.of(context).closeButtonTooltip,
                  icon: const Icon(Icons.close_rounded),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
          ),
          Divider(height: 1, color: context.themeBorder),
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
              child: _fields(context),
            ),
          ),
          Container(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
            decoration: BoxDecoration(
              border: Border(top: BorderSide(color: context.themeBorder)),
            ),
            child: _saveButton(context),
          ),
        ],
      ),
    );
  }

  InputDecoration _input(
    BuildContext context, {
    required String label,
    String? hint,
    IconData? icon,
  }) => InputDecoration(
    labelText: label,
    hintText: hint,
    prefixIcon: icon == null ? null : Icon(icon, size: 20),
    filled: true,
    fillColor: context.themeCard,
    border: OutlineInputBorder(borderRadius: AppRadius.md12),
  );

  Widget _fields(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final hasBanner = _bannerBytes != null || _existingBannerUrl != null;
    const gap = SizedBox(height: 16);
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Banner in banner proportions; tap to pick or change.
          Material(
            color: context.themeSoftSurface,
            borderRadius: AppRadius.md12,
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              onTap: _isUploadingBanner ? null : _pickBanner,
              child: AspectRatio(
                aspectRatio: 16 / 9,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    if (_bannerBytes != null)
                      Image.memory(_bannerBytes!, fit: BoxFit.cover)
                    else if (_existingBannerUrl != null)
                      Image.network(
                        _existingBannerUrl!,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                      )
                    else
                      DecoratedBox(
                        decoration: BoxDecoration(
                          borderRadius: AppRadius.md12,
                          border: Border.all(color: context.themeBorder),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.add_photo_alternate_rounded,
                              size: 40,
                              color: context.themeTextMuted,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              l10n.tapToUploadBanner,
                              style: AppTypography.bodySmall(
                                color: context.themeTextSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    if (hasBanner)
                      Positioned(
                        right: 10,
                        bottom: 10,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.black.withValues(alpha: 0.6),
                            borderRadius: AppRadius.pill,
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.edit_rounded,
                                size: 14,
                                color: AppColors.white,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                l10n.offerBannerChange,
                                style: AppTypography.labelSmall(
                                  color: AppColors.white,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    if (_isUploadingBanner)
                      ColoredBox(
                        color: AppColors.black.withValues(alpha: 0.35),
                        child: const Center(child: AppLoader()),
                      ),
                  ],
                ),
              ),
            ),
          ),
          gap,
          TextFormField(
            controller: _titleController,
            textCapitalization: TextCapitalization.sentences,
            decoration: _input(
              context,
              label: l10n.offerTitleLabel,
              hint: l10n.offerTitleHint,
            ),
            validator: (value) => value == null || value.trim().isEmpty
                ? l10n.enterOfferTitle
                : null,
          ),
          gap,
          TextFormField(
            controller: _descriptionController,
            textCapitalization: TextCapitalization.sentences,
            minLines: 3,
            maxLines: 5,
            decoration: _input(
              context,
              label: l10n.descriptionLabel,
              hint: l10n.descriptionHint,
            ).copyWith(alignLabelWithHint: true),
          ),
          gap,
          TextFormField(
            controller: _pointsController,
            keyboardType: TextInputType.number,
            decoration: _input(
              context,
              label: l10n.pointsRequiredLabel.replaceAll('*', '').trim(),
              hint: l10n.pointsHint,
              icon: Icons.stars_rounded,
            ),
            validator: (value) {
              // Points is optional, but if provided, must be a valid number.
              if (value != null && value.trim().isNotEmpty) {
                if (int.tryParse(value) == null) return l10n.enterValidNumber;
              }
              return null;
            },
          ),
          gap,
          // Same look as the text fields above.
          InkWell(
            onTap: _selectValidUntilDate,
            borderRadius: AppRadius.md12,
            child: InputDecorator(
              decoration:
                  _input(
                    context,
                    label: l10n.setValidUntilDate,
                    icon: Icons.event_rounded,
                  ).copyWith(
                    suffixIcon: _validUntil == null
                        ? null
                        : IconButton(
                            icon: const Icon(Icons.clear_rounded, size: 20),
                            onPressed: () => setState(() => _validUntil = null),
                          ),
                  ),
              isEmpty: _validUntil == null,
              child: _validUntil == null
                  ? null
                  : Text(
                      DateFormat('dd MMM yyyy').format(_validUntil!),
                      style: AppTypography.bodyMedium(
                        color: context.themeTextPrimary,
                      ),
                    ),
            ),
          ),
          gap,
          // Status: label and state on the left, switch on the right.
          Container(
            padding: const EdgeInsets.fromLTRB(14, 6, 6, 6),
            decoration: BoxDecoration(
              color: context.themeCard,
              borderRadius: AppRadius.md12,
              border: Border.all(color: context.themeBorder),
            ),
            child: Row(
              children: [
                Icon(
                  _isActive
                      ? Icons.visibility_rounded
                      : Icons.visibility_off_rounded,
                  size: 20,
                  color: context.themeTextSecondary,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.offerStatus,
                        style: AppTypography.labelLarge(
                          color: context.themeTextPrimary,
                        ),
                      ),
                      Text(
                        _isActive ? l10n.active : l10n.inactive,
                        style: AppTypography.caption(
                          color: _isActive
                              ? AppColors.success
                              : context.themeTextSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                Switch(
                  value: _isActive,
                  onChanged: (value) => setState(() => _isActive = value),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _saveButton(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return AppButton.primary(
      label: isEditMode ? l10n.updateOffer : l10n.createOffer,
      icon: isEditMode ? Icons.check_rounded : Icons.add_rounded,
      isLoading: _isSaving,
      onPressed: (_isSaving || _isUploadingBanner) ? null : _saveOffer,
    );
  }
}

/// Drag offers into the order members see them (top = first), then Save.
/// Saves `sortOrder` 1, 2, 3... for this branch's offers.
class ArrangeOffersPage extends StatefulWidget {
  const ArrangeOffersPage({super.key, required this.offers, this.service});

  final List<({String id, Map<String, dynamic> data})> offers;

  /// Tests pass a service on a fake database.
  final OfferService? service;

  @override
  State<ArrangeOffersPage> createState() => _ArrangeOffersPageState();
}

class _ArrangeOffersPageState extends State<ArrangeOffersPage> {
  late final List<({String id, Map<String, dynamic> data})> _items = [
    ...widget.offers,
  ];
  bool _saving = false;

  Future<void> _save() async {
    final l10n = AppLocalizations.of(context)!;
    final messenger = ScaffoldMessenger.of(context);
    final errorColor = context.themeError;
    setState(() => _saving = true);
    final ok = await (widget.service ?? OfferService()).saveOrder([
      for (final o in _items) o.id,
    ]);
    if (!mounted) return;
    setState(() => _saving = false);
    messenger.showSnackBar(
      SnackBar(
        content: Text(ok ? l10n.offersOrderSaved : l10n.offersOrderFailed),
        backgroundColor: ok ? null : errorColor,
      ),
    );
    if (ok) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      backgroundColor: context.themeBackground,
      appBar: AppBar(title: Text(l10n.offersArrange)),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: Text(
              l10n.offersArrangeHint,
              style: AppTypography.bodySmall().copyWith(
                color: context.themeTextSecondary,
              ),
            ),
          ),
          Expanded(
            child: ReorderableListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              itemCount: _items.length,
              onReorder: (from, to) => setState(() {
                if (to > from) to -= 1;
                _items.insert(to, _items.removeAt(from));
              }),
              itemBuilder: (context, i) {
                final o = _items[i];
                final banner = (o.data['bannerUrl'] as String? ?? '');
                return Card(
                  key: ValueKey(o.id),
                  margin: const EdgeInsets.only(bottom: 8),
                  shape: RoundedRectangleBorder(borderRadius: AppRadius.md12),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: context.themePrimary,
                      foregroundColor: AppColors.white,
                      child: Text('${i + 1}'),
                    ),
                    title: Text(
                      (o.data['title'] as String?) ?? '',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    subtitle: Text(
                      l10n.pts3('${o.data['points'] ?? 0}'),
                      style: AppTypography.caption(),
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (banner.isNotEmpty)
                          ClipRRect(
                            borderRadius: AppRadius.sm8,
                            child: Image.network(
                              banner,
                              width: 44,
                              height: 44,
                              fit: BoxFit.cover,
                              cacheWidth: 132,
                              errorBuilder: (_, __, ___) =>
                                  const SizedBox(width: 44),
                            ),
                          ),
                        const SizedBox(width: 8),
                        ReorderableDragStartListener(
                          index: i,
                          child: const Icon(Icons.drag_handle_rounded),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
          child: FilledButton.icon(
            onPressed: _saving ? null : _save,
            icon: _saving
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: AppLoader(strokeWidth: 2),
                  )
                : const Icon(Icons.check_rounded),
            label: Text(l10n.save),
          ),
        ),
      ),
    );
  }
}
