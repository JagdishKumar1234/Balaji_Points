import 'package:balaji_points/core/design/app_colors.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:balaji_points/core/layout/carpenter_shell_layout.dart';
import 'package:balaji_points/presentation/widgets/shared/app_button.dart';
import 'package:balaji_points/presentation/widgets/shared/app_card.dart';
import 'package:balaji_points/presentation/widgets/shared/app_loader.dart';
import 'package:balaji_points/presentation/widgets/shared/app_text.dart';
import 'package:balaji_points/services/platform/cart_service.dart';
import 'package:balaji_points/services/auth/session_service.dart';

class ProductDetailPage extends StatefulWidget {
  final String productId;

  const ProductDetailPage({super.key, required this.productId});

  @override
  State<ProductDetailPage> createState() => _ProductDetailPageState();
}

class _ProductDetailPageState extends State<ProductDetailPage> {
  final CartService _cartService = CartService();
  final SessionService _sessionService = SessionService();
  int _currentImageIndex = 0;

  Future<void> _addToCart(Map<String, dynamic> data) async {
    final userId = await _sessionService.getUserId();
    if (!mounted) return;
    if (userId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please log in to add items to cart.'),
          backgroundColor: context.themeError,
        ),
      );
      return;
    }

    final name = (data['name'] ?? '') as String;
    final mainCategory =
        (data['mainCategory'] ?? data['category'] ?? '') as String;
    final subCategory = (data['subCategory'] ?? '') as String;
    final imageUrl = (data['imageUrl'] ?? '') as String;
    final priceNum = (data['price'] ?? 0) as num;
    final price = priceNum.toDouble();

    await _cartService.addToCart(
      userId: userId,
      productId: widget.productId,
      name: name.isNotEmpty ? name : 'Product',
      price: price,
      mainCategory: mainCategory,
      subCategory: subCategory.isEmpty ? null : subCategory,
      imageUrl: imageUrl,
      quantity: 1,
    );

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Added to cart'),
      ),
    );
  }

  Future<void> _shareProduct(Map<String, dynamic> data) async {
    final name = (data['name'] ?? '') as String;
    final mainCategory =
        (data['mainCategory'] ?? data['category'] ?? '') as String;
    final subCategory = (data['subCategory'] ?? '') as String;
    final size = (data['size'] ?? '') as String;
    final thickness = (data['thickness'] ?? '') as String;
    final quality = (data['quality'] ?? '') as String;
    final description = (data['description'] ?? '') as String;
    final priceNum = (data['price'] ?? 0) as num;
    final price = priceNum.toDouble();

    final buffer = StringBuffer();
    buffer.writeln(name.isNotEmpty ? name : 'Product');
    buffer.writeln(
      subCategory.isNotEmpty ? '$mainCategory • $subCategory' : mainCategory,
    );
    if (size.isNotEmpty) buffer.writeln('Size: $size');
    if (thickness.isNotEmpty) buffer.writeln('Thickness: $thickness');
    if (quality.isNotEmpty) buffer.writeln('Quality: $quality');
    if (price > 0) buffer.writeln('Price: ₹${price.toStringAsFixed(0)}');
    if (description.isNotEmpty) buffer.writeln('\n$description');

    final message = buffer.toString();
    final uri = Uri.parse(
      'https://wa.me/?text=${Uri.encodeComponent(message)}',
    );
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Unable to open share app.'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final appBarFill =
        theme.appBarTheme.backgroundColor ?? theme.scaffoldBackgroundColor;
    final borderColor = isDark
        ? AppColors.white.withValues(alpha: 0.12)
        : AppColors.black.withValues(alpha: 0.08);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: appBarFill,
        foregroundColor: context.themeTextPrimary,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 22),
          onPressed: () => context.pop(),
        ),
        title: const Text('Product Details'),
        centerTitle: true,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(
            height: 1,
            color: borderColor,
          ),
        ),
        actions: [
          FutureBuilder<String?>(
            future: _sessionService.getUserId(),
            builder: (context, snapshot) {
              final userId = snapshot.data;
              if (snapshot.connectionState == ConnectionState.waiting ||
                  userId == null) {
                return IconButton(
                  icon: const Icon(Icons.shopping_cart_outlined),
                  onPressed: () => context.push('/cart'),
                  tooltip: 'Cart',
                );
              }
              return StreamBuilder<int>(
                stream: _cartService.watchCartCount(userId),
                builder: (context, snap) {
                  final count = snap.data ?? 0;
                  return _DetailCartIconButton(
                    count: count,
                    onTap: () => context.push('/cart'),
                  );
                },
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.ios_share),
            onPressed: () async {
              final snap = await FirebaseFirestore.instance
                  .collection('products')
                  .doc(widget.productId)
                  .get();
              if (!mounted) return;
              if (snap.exists && snap.data() != null) {
                _shareProduct(snap.data()!);
              }
            },
            tooltip: 'Share',
          ),
        ],
      ),
      body: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance
            .collection('products')
            .doc(widget.productId)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: AppText.body(
                  'Error loading product:\n${snapshot.error}',
                  color: context.themeError,
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }

          if (snapshot.connectionState == ConnectionState.waiting ||
              !snapshot.hasData ||
              !snapshot.data!.exists) {
            return const Center(child: AppLoader());
          }

          final data = snapshot.data!.data() ?? {};
          final name = (data['name'] ?? '') as String;
          final mainCategory =
              (data['mainCategory'] ?? data['category'] ?? '') as String;
          final subCategory = (data['subCategory'] ?? '') as String;
          final size = (data['size'] ?? '') as String;
          final thickness = (data['thickness'] ?? '') as String;
          final quality = (data['quality'] ?? '') as String;
          final description = (data['description'] ?? '') as String;
          final catalogPdfUrl = (data['catalogPdfUrl'] ?? '') as String;
          final priceNum = (data['price'] ?? 0) as num;
          final price = priceNum.toDouble();
          final imageUrlsRaw = data['imageUrls'];
          List<String> imageUrls = [];
          if (imageUrlsRaw is List) {
            imageUrls = imageUrlsRaw
                .whereType<String>()
                .where((e) => e.isNotEmpty)
                .toList();
          }
          if (imageUrls.isEmpty) {
            final single = (data['imageUrl'] ?? '') as String;
            if (single.isNotEmpty) imageUrls = [single];
          }

          return Padding(
            padding: CarpenterShellLayout.scrollViewPadding(
              MediaQuery.of(context),
            ),
            child: Column(
              children: [
                SizedBox(
                  height: 260,
                child: Stack(
                  children: [
                    PageView.builder(
                      itemCount: imageUrls.isEmpty ? 1 : imageUrls.length,
                      onPageChanged: (i) {
                        setState(() => _currentImageIndex = i);
                      },
                      itemBuilder: (context, index) {
                        final url = imageUrls.isNotEmpty
                            ? imageUrls[index]
                            : (data['imageUrl'] ?? '') as String;
                        if (url.isEmpty) {
                          return Container(
                            margin: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(20),
                              gradient: LinearGradient(
                                colors: [
                                  const Color(0xFF2196F3),
                                  context.themePrimary,
                                ],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                            ),
                            child: const Center(
                              child: Icon(
                                Icons.layers_rounded,
                                size: 64,
                                color: AppColors.white,
                              ),
                            ),
                          );
                        }
                        return Container(
                          margin: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(20),
                            child: Image.network(
                              url,
                              fit: BoxFit.cover,
                              width: double.infinity,
                            ),
                          ),
                        );
                      },
                    ),
                    if (imageUrls.length > 1)
                      Positioned(
                        bottom: 16,
                        left: 0,
                        right: 0,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: List.generate(imageUrls.length, (index) {
                            final active = index == _currentImageIndex;
                            return AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              margin:
                                  const EdgeInsets.symmetric(horizontal: 3),
                              width: active ? 16 : 6,
                              height: 6,
                              decoration: BoxDecoration(
                                color: active
                                    ? AppColors.white
                                    : AppColors.white.withValues(alpha: 0.5),
                                borderRadius: BorderRadius.circular(999),
                              ),
                            );
                          }),
                        ),
                      ),
                  ],
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.only(
                    left: 16,
                    right: 16,
                    top: 12,
                    bottom: 24,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      AppText.button(
                        name.isNotEmpty ? name : 'Product',
                      ),
                      const SizedBox(height: 4),
                      AppText.muted(
                        subCategory.isNotEmpty
                            ? '$mainCategory • $subCategory'
                            : mainCategory,
                      ),
                      const SizedBox(height: 12),
                      if (price > 0)
                        AppText.button(
                          '₹${price.toStringAsFixed(0)}',
                          color: context.themePrimary,
                        ),
                      const SizedBox(height: 16),
                      if (size.isNotEmpty ||
                          thickness.isNotEmpty ||
                          quality.isNotEmpty)
                        Wrap(
                          spacing: 8,
                          runSpacing: 6,
                          children: [
                            if (size.isNotEmpty)
                              _DetailChip(
                                icon: Icons.straighten,
                                label: 'Size',
                                value: size,
                              ),
                            if (thickness.isNotEmpty)
                              _DetailChip(
                                icon: Icons.line_weight,
                                label: 'Thickness',
                                value: thickness,
                              ),
                            if (quality.isNotEmpty)
                              _DetailChip(
                                icon: Icons.verified,
                                label: 'Quality',
                                value: quality,
                              ),
                          ],
                        ),
                      if (description.isNotEmpty) ...[
                        const SizedBox(height: 16),
                        const AppText.label('Description'),
                        const SizedBox(height: 4),
                        AppText.muted(description),
                      ],
                      if (catalogPdfUrl.isNotEmpty) ...[
                        const SizedBox(height: 16),
                        AppButton.outline(
                          label: 'View catalog PDF',
                          icon: Icons.picture_as_pdf,
                          verticalPadding: 12,
                          onPressed: () async {
                            final uri = Uri.parse(catalogPdfUrl);
                            if (!await launchUrl(
                              uri,
                              mode: LaunchMode.externalApplication,
                            )) {
                              if (!mounted) return;
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Unable to open catalog PDF.'),
                                ),
                              );
                            }
                          },
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surface,
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.black.withValues(alpha: 0.06),
                      blurRadius: 8,
                      offset: const Offset(0, -2),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: AppButton.outline(
                        label: 'Share',
                        icon: Icons.ios_share,
                        verticalPadding: 12,
                        onPressed: () => _shareProduct(data),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: AppButton.secondary(
                        label: 'Add to cart',
                        icon: Icons.add_shopping_cart,
                        verticalPadding: 12,
                        onPressed: () => _addToCart(data),
                      ),
                    ),
                  ],
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

class _DetailChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _DetailChip({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      borderRadius: 999,
      color: context.themeSoftSurface,
      showShadow: false,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: context.themeTextSecondary),
          const SizedBox(width: 4),
          AppText.label('$label:', color: context.themeTextPrimary),
          const SizedBox(width: 4),
          AppText.body(value, color: context.themeTextPrimary),
        ],
      ),
    );
  }
}

class _DetailCartIconButton extends StatelessWidget {
  final int count;
  final VoidCallback onTap;

  const _DetailCartIconButton({
    required this.count,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        IconButton(
          icon: const Icon(Icons.shopping_cart_outlined),
          onPressed: onTap,
          tooltip: 'Cart',
        ),
        if (count > 0)
          Positioned(
            right: 6,
            top: 6,
            child: Container(
              constraints: const BoxConstraints(
                minWidth: 16,
                minHeight: 16,
              ),
              padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 1),
              decoration: BoxDecoration(
                color: context.themeError,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: AppColors.white,
                  width: 1,
                ),
              ),
              child: Text(
                count > 99 ? '99+' : '$count',
                style: const TextStyle(
                  color: AppColors.white,
                  fontSize: 9,
                  fontWeight: FontWeight.bold,
                  height: 1,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
      ],
    );
  }
}

