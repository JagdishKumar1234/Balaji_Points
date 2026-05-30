import 'package:balaji_points/core/design/app_radius.dart';
import 'package:balaji_points/presentation/widgets/shared/app_button.dart';
import 'package:balaji_points/presentation/widgets/shared/app_text.dart';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:balaji_points/core/design/app_colors.dart';
import 'package:balaji_points/core/design/app_typography.dart';
import 'package:file_picker/file_picker.dart';
import 'package:image_picker/image_picker.dart';

import '../../../services/platform/product_service.dart';

class ProductsManagement extends StatefulWidget {
  const ProductsManagement({super.key});

  @override
  State<ProductsManagement> createState() => _ProductsManagementState();
}

class _ProductsManagementState extends State<ProductsManagement> {
  final ProductService _productService = ProductService();

  static const List<String> _mainCategories = [
    'Laminates',
    'Veneers',
    'Acrylic',
    'Plywood',
    'MDF',
    'Doors',
    'Wardrobe',
    'Hardware',
    'Others',
  ];

  static const List<String> _subCategories = [
    'Bedroom',
    'Kitchen',
    'Living Room',
    'Wardrobe',
    'Bathroom',
    'Office',
    'TV Unit',
    'Wall Panel',
    'Display Unit',
  ];

  void _showCreateProductDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const _CreateEditProductDialog(),
    );
  }

  void _showEditProductDialog(String productId, Map<String, dynamic> product) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) =>
          _CreateEditProductDialog(productId: productId, product: product),
    );
  }

  Future<void> _deleteProduct(String productId, String? imageUrl) async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: AppRadius.all16),
        title: Text('Delete product', style: AppTypography.labelLarge()),
        content: Text(
          'Are you sure you want to delete this product?\nThis action cannot be undone.',
          style: AppTypography.bodyMedium(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          AppButton(
            label: "action",
            onPressed: () => Navigator.of(context).pop(true),
            variant: AppButtonVariant.danger,
            fullWidth: false,
          ),
        ],
      ),
    );

    if (shouldDelete == true) {
      final success = await _productService.deleteProduct(productId, imageUrl);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            success
                ? 'Product deleted successfully'
                : 'Failed to delete product',
          ),
          backgroundColor: success ? AppColors.success : context.themeError,
        ),
      );
    }
  }

  void _viewProductImage(String imageUrl) {
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
    return Scaffold(
      backgroundColor: context.themeSoftSurface,
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('products')
            .orderBy('createdAt', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  'Error loading products:\n${snapshot.error}',
                  textAlign: TextAlign.center,
                  style: AppTypography.bodyMedium().copyWith(
                    fontSize: 14,
                    color: context.themeError,
                  ),
                ),
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

          final products = snapshot.data?.docs ?? [];

          if (products.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.inventory_2_outlined,
                    size: 80,
                    color: context.themeBorder,
                  ),
                  const SizedBox(height: 20),
                  AppText.label('No products added yet'),
                  const SizedBox(height: 8),
                  Text(
                    'Tap on "Add product" to create your first product.',
                    style: AppTypography.bodyMedium().copyWith(
                      fontSize: 14,
                      color: context.themeTextSecondary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: products.length,
            itemBuilder: (context, index) {
              final doc = products[index];
              final data = doc.data() as Map<String, dynamic>;

              final productId = doc.id;
              final name = (data['name'] ?? '') as String;
              final mainCategory =
                  (data['mainCategory'] ?? data['category'] ?? '') as String;
              final subCategory = (data['subCategory'] ?? '') as String;
              final size = (data['size'] ?? '') as String;
              final thickness = (data['thickness'] ?? '') as String;
              final quality = (data['quality'] ?? '') as String;
              final imageUrl = (data['imageUrl'] ?? '') as String;
              final isActive = (data['isActive'] ?? true) as bool;

              return Card(
                margin: const EdgeInsets.only(bottom: 16),
                elevation: 2,
                shape: RoundedRectangleBorder(borderRadius: AppRadius.all16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (imageUrl.isNotEmpty)
                      GestureDetector(
                        onTap: () => _viewProductImage(imageUrl),
                        child: ClipRRect(
                          borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(16),
                          ),
                          child: Image.network(
                            imageUrl,
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
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: AppText.label(
                                  name.isNotEmpty ? name : 'Unnamed product',
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: isActive
                                      ? AppColors.success
                                      : context.themeBorder,
                                  borderRadius: BorderRadius.circular(999),
                                ),
                                child: Text(
                                  isActive ? 'Active' : 'Hidden',
                                  style: AppTypography.labelLarge().copyWith(
                                    fontSize: 11,
                                    color: isActive
                                        ? AppColors.success
                                        : context.themeTextSecondary,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          if (mainCategory.isNotEmpty)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: context.themePrimary.withValues(
                                  alpha: 0.08,
                                ),
                                borderRadius: BorderRadius.circular(999),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.category_outlined,
                                    size: 16,
                                    color: context.themeContentColor,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    subCategory.isNotEmpty
                                        ? '$mainCategory • $subCategory'
                                        : mainCategory,
                                    style: AppTypography.labelLarge().copyWith(
                                      fontSize: 12,
                                      color: context.themeContentColor,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          const SizedBox(height: 12),
                          Wrap(
                            spacing: 10,
                            runSpacing: 6,
                            children: [
                              if (size.isNotEmpty)
                                _ProductInfoChip(
                                  label: 'Size',
                                  value: size,
                                  icon: Icons.straighten,
                                ),
                              if (thickness.isNotEmpty)
                                _ProductInfoChip(
                                  label: 'Thickness',
                                  value: thickness,
                                  icon: Icons.line_weight,
                                ),
                              if (quality.isNotEmpty)
                                _ProductInfoChip(
                                  label: 'Quality',
                                  value: quality,
                                  icon: Icons.verified,
                                ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Expanded(
                                child: OutlinedButton.icon(
                                  onPressed: () =>
                                      _showEditProductDialog(productId, data),
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
                                  label: const Text('Edit'),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: OutlinedButton.icon(
                                  onPressed: () =>
                                      _deleteProduct(productId, imageUrl),
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
                                  label: const Text('Delete'),
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
        onPressed: _showCreateProductDialog,
        backgroundColor: context.themeSecondary,
        foregroundColor: AppColors.white,
        shape: RoundedRectangleBorder(borderRadius: AppRadius.all16),
        icon: const Icon(Icons.add),
        label: Text('Add product', style: AppTypography.labelLarge()),
      ),
    );
  }
}

class _ProductInfoChip extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;

  const _ProductInfoChip({
    required this.label,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: context.themeSoftSurface,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: context.themeBorder),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: context.themeTextSecondary),
          const SizedBox(width: 4),
          AppText.label('$label:'),
          const SizedBox(width: 4),
          AppText.body(value),
        ],
      ),
    );
  }
}

class _CreateEditProductDialog extends StatefulWidget {
  final String? productId;
  final Map<String, dynamic>? product;

  const _CreateEditProductDialog({this.productId, this.product});

  bool get isEditMode => productId != null && product != null;

  @override
  State<_CreateEditProductDialog> createState() =>
      _CreateEditProductDialogState();
}

class _CreateEditProductDialogState extends State<_CreateEditProductDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _priceController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _sizeController = TextEditingController();
  final _thicknessController = TextEditingController();
  final _qualityController = TextEditingController();

  final ProductService _productService = ProductService();

  final List<File> _newImageFiles = [];
  List<String> _existingImageUrls = [];
  String _selectedMainCategory = _ProductsManagementState._mainCategories.first;
  String _selectedSubCategory = '';
  bool _isActive = true;
  bool _isSaving = false;
  bool _isUploadingImage = false;
  File? _newCatalogPdfFile;
  String _existingCatalogPdfUrl = '';
  String? _selectedCatalogPdfName;
  bool _isUploadingCatalogPdf = false;

  bool get _isEditMode => widget.isEditMode;

  @override
  void initState() {
    super.initState();
    if (_isEditMode) {
      final product = widget.product!;
      _nameController.text = (product['name'] ?? '') as String;
      final priceNum = (product['price'] ?? 0) as num;
      _priceController.text = priceNum == 0 ? '' : priceNum.toStringAsFixed(0);
      _descriptionController.text = (product['description'] ?? '') as String;
      _sizeController.text = (product['size'] ?? '') as String;
      _thicknessController.text = (product['thickness'] ?? '') as String;
      _qualityController.text = (product['quality'] ?? '') as String;
      final rawList = product['imageUrls'];
      if (rawList is List) {
        _existingImageUrls = rawList
            .whereType<String>()
            .where((url) => url.isNotEmpty)
            .toList();
      }
      if (_existingImageUrls.isEmpty) {
        final single = (product['imageUrl'] ?? '') as String?;
        if (single != null && single.isNotEmpty) {
          _existingImageUrls = [single];
        }
      }
      _selectedMainCategory =
          (product['mainCategory'] ??
                  product['category'] ??
                  _selectedMainCategory)
              as String;
      _selectedSubCategory =
          (product['subCategory'] ?? _selectedSubCategory) as String;
      _isActive = (product['isActive'] ?? true) as bool;
      final rawCatalogPdfUrl = product['catalogPdfUrl'];
      if (rawCatalogPdfUrl is String) {
        _existingCatalogPdfUrl = rawCatalogPdfUrl;
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _priceController.dispose();
    _descriptionController.dispose();
    _sizeController.dispose();
    _thicknessController.dispose();
    _qualityController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    try {
      final picker = ImagePicker();
      final images = await picker.pickMultiImage(
        maxWidth: 1600,
        maxHeight: 1600,
        imageQuality: 85,
      );
      if (images.isNotEmpty) {
        setState(() {
          _newImageFiles.addAll(images.map((x) => File(x.path)));
        });
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to pick image: $e'),
          backgroundColor: context.themeError,
        ),
      );
    }
  }

  Future<void> _pickCatalogPdf() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf'],
      );

      if (result == null || result.files.isEmpty) return;

      final picked = result.files.first;
      final path = picked.path;
      if (path == null || path.isEmpty) return;

      setState(() {
        _newCatalogPdfFile = File(path);
        _selectedCatalogPdfName = picked.name;
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to pick PDF: $e'),
          backgroundColor: context.themeError,
        ),
      );
    }
  }

  Future<void> _saveProduct() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSaving = true;
    });

    try {
      final name = _nameController.text.trim();
      final priceText = _priceController.text.trim();
      final description = _descriptionController.text.trim();
      final size = _sizeController.text.trim();
      final thickness = _thicknessController.text.trim();
      final quality = _qualityController.text.trim();

      if (priceText.isEmpty) {
        throw Exception('Please enter product price');
      }
      final parsedPrice = double.tryParse(priceText);
      if (parsedPrice == null || parsedPrice <= 0) {
        throw Exception('Please enter a valid price');
      }

      if (!_isEditMode &&
          _newImageFiles.isEmpty &&
          _existingImageUrls.isEmpty) {
        throw Exception('Please upload at least one product image');
      }

      // Upload any newly added images
      final allImageUrls = <String>[..._existingImageUrls];

      if (_newImageFiles.isNotEmpty) {
        setState(() {
          _isUploadingImage = true;
        });

        for (final file in _newImageFiles) {
          final uploadedUrl = await _productService.uploadProductImage(file);
          if (uploadedUrl != null && uploadedUrl.isNotEmpty) {
            allImageUrls.add(uploadedUrl);
          }
        }

        setState(() {
          _isUploadingImage = false;
        });
      }

      String? finalCatalogPdfUrl = _existingCatalogPdfUrl;
      if (_newCatalogPdfFile != null) {
        setState(() {
          _isUploadingCatalogPdf = true;
        });
        finalCatalogPdfUrl = await _productService.uploadProductCatalogPdf(
          _newCatalogPdfFile!,
        );
        setState(() {
          _isUploadingCatalogPdf = false;
        });
      }

      bool success;
      if (_isEditMode) {
        success = await _productService.updateProduct(
          productId: widget.productId!,
          name: name,
          mainCategory: _selectedMainCategory,
          subCategory: _selectedSubCategory.isEmpty
              ? null
              : _selectedSubCategory,
          price: parsedPrice,
          description: description.isEmpty ? null : description,
          size: size.isEmpty ? null : size,
          thickness: thickness.isEmpty ? null : thickness,
          quality: quality.isEmpty ? null : quality,
          imageUrls: allImageUrls,
          isActive: _isActive,
          oldImageUrl: _existingImageUrls.isNotEmpty
              ? _existingImageUrls.first
              : null,
          catalogPdfUrl:
              finalCatalogPdfUrl != null && finalCatalogPdfUrl.isNotEmpty
              ? finalCatalogPdfUrl
              : null,
          oldCatalogPdfUrl: _existingCatalogPdfUrl.isNotEmpty
              ? _existingCatalogPdfUrl
              : null,
        );
      } else {
        success = await _productService.createProduct(
          name: name,
          mainCategory: _selectedMainCategory,
          subCategory: _selectedSubCategory.isEmpty
              ? null
              : _selectedSubCategory,
          price: parsedPrice,
          description: description.isEmpty ? null : description,
          size: size.isEmpty ? null : size,
          thickness: thickness.isEmpty ? null : thickness,
          quality: quality.isEmpty ? null : quality,
          imageUrls: allImageUrls,
          catalogPdfUrl:
              finalCatalogPdfUrl != null && finalCatalogPdfUrl.isNotEmpty
              ? finalCatalogPdfUrl
              : null,
          isActive: _isActive,
        );
      }

      if (!mounted) return;

      if (success) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _isEditMode
                  ? 'Product updated successfully'
                  : 'Product created successfully',
            ),
            backgroundColor: AppColors.success,
          ),
        );
      } else {
        throw Exception('Failed to save product');
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: context.themeError,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
          _isUploadingImage = false;
          _isUploadingCatalogPdf = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final title = _isEditMode ? 'Edit product' : 'Add new product';

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: AppRadius.all16),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 500, maxHeight: 720),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
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
                  const Icon(
                    Icons.inventory_2,
                    color: AppColors.white,
                    size: 26,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      title,
                      style: AppTypography.labelLarge().copyWith(
                        fontSize: 20,
                        color: AppColors.white,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: AppColors.white),
                    onPressed:
                        (_isSaving ||
                            _isUploadingImage ||
                            _isUploadingCatalogPdf)
                        ? null
                        : () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      GestureDetector(
                        onTap: _pickImage,
                        child: Container(
                          height: 170,
                          decoration: BoxDecoration(
                            color: context.themeSoftSurface,
                            borderRadius: AppRadius.all16,
                            border: Border.all(color: context.themeBorder),
                          ),
                          child: Builder(
                            builder: (context) {
                              if (_newImageFiles.isNotEmpty) {
                                return ClipRRect(
                                  borderRadius: AppRadius.all16,
                                  child: Image.file(
                                    _newImageFiles.first,
                                    fit: BoxFit.cover,
                                    width: double.infinity,
                                  ),
                                );
                              }
                              if (_existingImageUrls.isNotEmpty) {
                                return ClipRRect(
                                  borderRadius: AppRadius.all16,
                                  child: Image.network(
                                    _existingImageUrls.first,
                                    fit: BoxFit.cover,
                                    width: double.infinity,
                                  ),
                                );
                              }
                              return Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.add_photo_alternate,
                                    size: 48,
                                    color: context.themeTextMuted,
                                  ),
                                  const SizedBox(height: 8),
                                  AppText.bodySmall(
                                    'Tap to upload product images',
                                  ),
                                ],
                              );
                            },
                          ),
                        ),
                      ),
                      if (_existingImageUrls.length + _newImageFiles.length > 1)
                        Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(
                            'Total photos: ${_existingImageUrls.length + _newImageFiles.length}',
                            style: AppTypography.bodyMedium().copyWith(
                              fontSize: 12,
                              color: context.themeTextSecondary,
                            ),
                          ),
                        ),
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: context.themeSoftSurface,
                          borderRadius: AppRadius.md12,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Icons.picture_as_pdf,
                                  color: context.themeContentColor,
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: AppText.bodySmall(
                                    'Catalog PDF (optional)',
                                  ),
                                ),
                                if (_existingCatalogPdfUrl.isNotEmpty &&
                                    _newCatalogPdfFile == null)
                                  const Icon(
                                    Icons.check_circle,
                                    color: AppColors.success,
                                    size: 20,
                                  ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    _selectedCatalogPdfName ??
                                        (_existingCatalogPdfUrl.isNotEmpty
                                            ? 'PDF attached'
                                            : 'No PDF selected'),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: AppTypography.bodyMedium().copyWith(
                                      fontSize: 13,
                                      color: context.themeTextSecondary,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                OutlinedButton.icon(
                                  onPressed:
                                      (_isSaving ||
                                          _isUploadingImage ||
                                          _isUploadingCatalogPdf)
                                      ? null
                                      : _pickCatalogPdf,
                                  icon: const Icon(Icons.upload_file),
                                  label: Text(
                                    _selectedCatalogPdfName != null ||
                                            _existingCatalogPdfUrl.isNotEmpty
                                        ? 'Change'
                                        : 'Upload',
                                  ),
                                  style: OutlinedButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 10,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: AppRadius.sm8,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            if (_isUploadingCatalogPdf)
                              Padding(
                                padding: const EdgeInsets.only(top: 10),
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
                                              context.themePrimary,
                                            ),
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    AppText.bodySmall('Uploading PDF...'),
                                  ],
                                ),
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _nameController,
                        style: AppTypography.bodyMedium().copyWith(
                          fontSize: 16,
                        ),
                        decoration: InputDecoration(
                          labelText: 'Product name',
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
                            return 'Enter product name';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _priceController,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        style: AppTypography.bodyMedium().copyWith(
                          fontSize: 16,
                        ),
                        decoration: InputDecoration(
                          labelText: 'Price for carpenter (₹)',
                          border: OutlineInputBorder(
                            borderRadius: AppRadius.md12,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _descriptionController,
                        maxLines: 3,
                        style: AppTypography.bodyMedium().copyWith(
                          fontSize: 16,
                        ),
                        decoration: InputDecoration(
                          labelText: 'Description (optional)',
                          hintText: 'Short description visible in details',
                          border: OutlineInputBorder(
                            borderRadius: AppRadius.md12,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      DropdownButtonFormField<String>(
                        initialValue:
                            _ProductsManagementState._mainCategories.contains(
                              _selectedMainCategory,
                            )
                            ? _selectedMainCategory
                            : _ProductsManagementState._mainCategories.first,
                        items: _ProductsManagementState._mainCategories
                            .map(
                              (c) => DropdownMenuItem<String>(
                                value: c,
                                child: Text(c),
                              ),
                            )
                            .toList(),
                        decoration: InputDecoration(
                          labelText: 'Main category (e.g. Laminates)',
                          border: OutlineInputBorder(
                            borderRadius: AppRadius.md12,
                          ),
                        ),
                        onChanged: (value) {
                          if (value == null) return;
                          setState(() {
                            _selectedMainCategory = value;
                          });
                        },
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<String>(
                        initialValue: _selectedSubCategory.isEmpty
                            ? null
                            : _selectedSubCategory,
                        items: [
                          const DropdownMenuItem<String>(
                            value: '',
                            child: Text('All applications'),
                          ),
                          ..._ProductsManagementState._subCategories.map(
                            (c) => DropdownMenuItem<String>(
                              value: c,
                              child: Text(c),
                            ),
                          ),
                        ],
                        decoration: InputDecoration(
                          labelText: 'Application / space (optional)',
                          border: OutlineInputBorder(
                            borderRadius: AppRadius.md12,
                          ),
                        ),
                        onChanged: (value) {
                          setState(() {
                            _selectedSubCategory = value ?? '';
                          });
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _sizeController,
                        style: AppTypography.bodyMedium().copyWith(
                          fontSize: 16,
                        ),
                        decoration: InputDecoration(
                          labelText: 'Size (optional)',
                          hintText: 'e.g. 8ft x 4ft',
                          border: OutlineInputBorder(
                            borderRadius: AppRadius.md12,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _thicknessController,
                        style: AppTypography.bodyMedium().copyWith(
                          fontSize: 16,
                        ),
                        decoration: InputDecoration(
                          labelText: 'Thickness (optional)',
                          hintText: 'e.g. 19mm, 0.8mm',
                          border: OutlineInputBorder(
                            borderRadius: AppRadius.md12,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _qualityController,
                        style: AppTypography.bodyMedium().copyWith(
                          fontSize: 16,
                        ),
                        decoration: InputDecoration(
                          labelText: 'Quality / Grade (optional)',
                          hintText: 'e.g. Premium, BWR, BWP',
                          border: OutlineInputBorder(
                            borderRadius: AppRadius.md12,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
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
                                'Show product to carpenters',
                                style: AppTypography.bodySmall(),
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
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
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
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    context.themePrimary,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              AppText.bodySmall('Uploading image...'),
                            ],
                          ),
                        ),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed:
                              (_isSaving ||
                                  _isUploadingImage ||
                                  _isUploadingCatalogPdf)
                              ? null
                              : _saveProduct,
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
                                  _isEditMode
                                      ? 'Update product'
                                      : 'Save product',
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
      ),
    );
  }
}
