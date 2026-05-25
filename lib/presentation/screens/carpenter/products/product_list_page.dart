import 'package:balaji_points/core/design/app_colors.dart';
import 'package:balaji_points/core/design/app_typography.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:balaji_points/services/platform/cart_service.dart';
import 'package:balaji_points/services/auth/session_service.dart';

class ProductListPage extends StatelessWidget {
  final String? initialCategory;

  const ProductListPage({super.key, this.initialCategory});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final appBarFill =
        theme.appBarTheme.backgroundColor ?? theme.scaffoldBackgroundColor;
    final sessionService = SessionService();
    final cartService = CartService();

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: appBarFill,
        foregroundColor: context.themeTextPrimary,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 22),
          onPressed: () {
            // If there's a route to pop, pop it; otherwise go home.
            if (Navigator.of(context).canPop()) {
              context.pop();
            } else {
              context.go('/');
            }
          },
        ),
        title: const Text('Products'),
        centerTitle: true,
        actions: [
          FutureBuilder<String?>(
            future: sessionService.getUserId(),
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
                stream: cartService.watchCartCount(userId),
                builder: (context, snap) {
                  final count = snap.data ?? 0;
                  return _CartIconButton(
                    count: count,
                    onTap: () => context.push('/cart'),
                  );
                },
              );
            },
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('products')
            .where('isActive', isEqualTo: true)
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
              child: CircularProgressIndicator(color: context.themePrimary),
            );
          }

          final docs = snapshot.data?.docs ?? [];

          if (docs.isEmpty) {
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
                  Text(
                    'No Product Added',
                    style: AppTypography.buttonMedium().copyWith(
                      fontSize: 20,
                      color: context.themeTextPrimary,
                    ),
                  ),
                ],
              ),
            );
          }

          final categorySet = <String>{};
          for (final doc in docs) {
            final data = doc.data() as Map<String, dynamic>;
            final cat =
                (data['mainCategory'] ?? data['category'] ?? '') as String;
            if (cat.isNotEmpty) categorySet.add(cat);
          }

          final categories = categorySet.toList()..sort();
          final hasCategories = categories.isNotEmpty;

          final selectedCategory =
              (initialCategory != null &&
                  initialCategory != 'All' &&
                  hasCategories &&
                  categories.contains(initialCategory))
              ? initialCategory!
              : 'All';

          final filteredDocs = selectedCategory == 'All' || !hasCategories
              ? docs
              : docs.where((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  final cat =
                      (data['mainCategory'] ?? data['category'] ?? '')
                          as String;
                  return cat == selectedCategory;
                }).toList();

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 8),
              if (hasCategories)
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 4,
                  ),
                  child: Row(
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: ChoiceChip(
                          label: const Text('All'),
                          selected: selectedCategory == 'All',
                          onSelected: (_) {
                            context.go('/products');
                          },
                        ),
                      ),
                      for (final category in categories)
                        Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: ChoiceChip(
                            label: Text(category),
                            selected: selectedCategory == category,
                            onSelected: (_) {
                              context.go(
                                '/products?category=${Uri.encodeComponent(category)}',
                              );
                            },
                          ),
                        ),
                    ],
                  ),
                ),
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  hasCategories ? selectedCategory : 'Products',
                  style: AppTypography.labelLarge().copyWith(
                    fontSize: 16.0,
                    color: isDark ? AppColors.white : context.themeTextPrimary,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: GridView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 120),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                    childAspectRatio: 3 / 4,
                  ),
                  itemCount: filteredDocs.length,
                  itemBuilder: (context, index) {
                    final doc = filteredDocs[index];
                    final data = doc.data() as Map<String, dynamic>;

                    final productId = doc.id;
                    final name = (data['name'] ?? '') as String;
                    final mainCategory =
                        (data['mainCategory'] ?? data['category'] ?? '')
                            as String;
                    final subCategory = (data['subCategory'] ?? '') as String;
                    final size = (data['size'] ?? '') as String;
                    final thickness = (data['thickness'] ?? '') as String;
                    final quality = (data['quality'] ?? '') as String;
                    final imageUrl = (data['imageUrl'] ?? '') as String;
                    final priceNum = (data['price'] ?? 0) as num;
                    final price = priceNum.toDouble();

                    return _ProductCard(
                      productId: productId,
                      name: name.isNotEmpty ? name : 'Product',
                      subtitle: subCategory.isNotEmpty
                          ? '$mainCategory • $subCategory'
                          : (mainCategory.isNotEmpty
                                ? mainCategory
                                : 'Furniture'),
                      price: price,
                      size: size,
                      thickness: thickness,
                      quality: quality,
                      imageUrl: imageUrl,
                      mainCategory: mainCategory,
                      subCategory: subCategory,
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _ProductCard extends StatelessWidget {
  final String productId;
  final String name;
  final String subtitle;
  final double price;
  final String size;
  final String thickness;
  final String quality;
  final String imageUrl;
  final String mainCategory;
  final String subCategory;

  const _ProductCard({
    required this.productId,
    required this.name,
    required this.subtitle,
    required this.price,
    required this.size,
    required this.thickness,
    required this.quality,
    required this.imageUrl,
    required this.mainCategory,
    required this.subCategory,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final Color titleColor = isDark ? AppColors.white : context.themeTextPrimary;
    final Color subtitleColor = isDark
        ? AppColors.white.withValues(alpha: 0.80)
        : context.themeTextPrimary.withValues(alpha: 0.70);

    final cartService = CartService();
    final sessionService = SessionService();

    Future<void> addToCart() async {
      final userId = await sessionService.getUserId();
      if (userId == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Please log in to add items to cart.'),
            backgroundColor: context.themeError,
          ),
        );
        return;
      }

      await cartService.addToCart(
        userId: userId,
        productId: productId,
        name: name,
        price: price,
        mainCategory: mainCategory,
        subCategory: subCategory.isEmpty ? null : subCategory,
        imageUrl: imageUrl,
      );

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Added to cart')));
    }

    void openDetails() {
      context.push('/product-detail/$productId');
    }

    return GestureDetector(
      onTap: openDetails,
      child: Container(
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: AppColors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Stack(
                children: [
                  Positioned.fill(
                    child: ClipRRect(
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(18),
                      ),
                      child: imageUrl.isNotEmpty
                          ? Image.network(
                              imageUrl,
                              fit: BoxFit.cover,
                              width: double.infinity,
                            )
                          : Container(
                              decoration: BoxDecoration(
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
                                  size: 40,
                                  color: AppColors.white,
                                ),
                              ),
                            ),
                    ),
                  ),
                  Positioned(
                    right: 8,
                    bottom: 8,
                    child: Material(
                      color: AppColors.black.withValues(alpha: 0.55),
                      borderRadius: BorderRadius.circular(999),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(999),
                        onTap: () {
                          addToCart();
                        },
                        child: const Padding(
                          padding: EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.add_shopping_cart,
                                size: 16,
                                color: AppColors.white,
                              ),
                              SizedBox(width: 4),
                              Text(
                                'Add',
                                style: TextStyle(
                                  color: AppColors.white,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 12,
              ).copyWith(top: 8),
              child: Text(
                name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTypography.labelLarge().copyWith(
                  color: titleColor,
                  fontSize: 14.0,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 12,
              ).copyWith(top: 2),
              child: Text(
                subtitle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTypography.bodyMedium().copyWith(
                  color: subtitleColor,
                  fontSize: 12.0,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 12,
              ).copyWith(top: 4),
              child: Text(
                price > 0 ? '₹${price.toStringAsFixed(0)}' : '',
                style: AppTypography.buttonMedium().copyWith(
                  color: context.themePrimary,
                  fontSize: 14.0,
                ),
              ),
            ),
            if (size.isNotEmpty || thickness.isNotEmpty || quality.isNotEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                ).copyWith(bottom: 4),
                child: Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  children: [
                    if (size.isNotEmpty)
                      _SmallChip(icon: Icons.straighten, label: size),
                    if (thickness.isNotEmpty)
                      _SmallChip(icon: Icons.line_weight, label: thickness),
                    if (quality.isNotEmpty)
                      _SmallChip(icon: Icons.verified, label: quality),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _SmallChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _SmallChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: context.themeSoftSurface,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: context.themeBorder),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 10, color: context.themeTextSecondary),
          const SizedBox(width: 2),
          Text(
            label,
            style: AppTypography.bodyMedium().copyWith(
              fontSize: 9,
              color: context.themeTextPrimary,
            ),
          ),
        ],
      ),
    );
  }
}

class _CartIconButton extends StatelessWidget {
  final int count;
  final VoidCallback onTap;

  const _CartIconButton({required this.count, required this.onTap});

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
              constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
              padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 1),
              decoration: BoxDecoration(
                color: context.themeError,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.white, width: 1),
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
