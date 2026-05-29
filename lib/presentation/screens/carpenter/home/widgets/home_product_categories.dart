import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';

import 'package:balaji_points/core/design/app_colors.dart';
import 'package:balaji_points/core/design/app_typography.dart';

// ---------------------------------------------------------------------------
// Icon / accent helpers
// ---------------------------------------------------------------------------

IconData _categoryIcon(String category) {
  final k = category.toLowerCase();
  if (k.contains('plywood')) return Icons.layers_rounded;
  if (k.contains('laminat')) return Icons.view_quilt_rounded;
  if (k.contains('hardware')) return Icons.build_rounded;
  if (k.contains('veneer')) return Icons.texture_rounded;
  if (k.contains('accessori')) return Icons.category_rounded;
  if (k.contains('bedroom')) return Icons.bed_rounded;
  if (k.contains('kitchen')) return Icons.kitchen_rounded;
  if (k.contains('living')) return Icons.chair_rounded;
  if (k.contains('wardrobe')) return Icons.checkroom_rounded;
  if (k.contains('office')) return Icons.workspaces_rounded;
  if (k.contains('bathroom')) return Icons.bathtub_rounded;
  return Icons.widgets_rounded;
}

const List<Color> _kAccents = [
  Color(0xFF2563EB),
  Color(0xFFD97706),
  Color(0xFF7C3AED),
  Color(0xFF0891B2),
  Color(0xFF16A34A),
  Color(0xFFDC2626),
  Color(0xFF9333EA),
  Color(0xFF0D9488),
];

Color _categoryAccent(String category) =>
    _kAccents[category.length % _kAccents.length];

// ---------------------------------------------------------------------------
// HomeProductCategories
// ---------------------------------------------------------------------------

class HomeProductCategories extends StatefulWidget {
  const HomeProductCategories({super.key});

  @override
  State<HomeProductCategories> createState() => _HomeProductCategoriesState();
}

class _HomeProductCategoriesState extends State<HomeProductCategories> {
  String? _selectedCategory; // null = All

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? const Color(0xFF171A22) : AppColors.white;

    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('products')
          .where('isActive', isEqualTo: true)
          .snapshots(),
      builder: (context, snapshot) {
        final isLoading = snapshot.connectionState == ConnectionState.waiting;
        final docs = snapshot.data?.docs ?? [];

        // Collect unique categories
        final categories = <String>[];
        for (final doc in docs) {
          final cat = ((doc.data()['mainCategory'] as String?) ??
                  (doc.data()['category'] as String?) ??
                  '')
              .trim();
          if (cat.isNotEmpty && !categories.contains(cat)) {
            categories.add(cat);
          }
        }

        // Filter products
        final filtered = _selectedCategory == null
            ? docs
            : docs.where((d) {
                final cat = ((d.data()['mainCategory'] as String?) ??
                        (d.data()['category'] as String?) ??
                        '')
                    .trim();
                return cat == _selectedCategory;
              }).toList();

        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: cardBg,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: AppColors.black.withValues(alpha: isDark ? 0.25 : 0.07),
                blurRadius: 16,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Header ──────────────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                child: Row(
                  children: [
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: context.themePrimary.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(Icons.inventory_2_rounded,
                          size: 18, color: context.themePrimary),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Products',
                        style:
                            AppTypography.h5(color: context.themeTextPrimary),
                      ),
                    ),
                    GestureDetector(
                      onTap: () => context.push('/products'),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text('View All',
                              style: AppTypography.labelMedium(
                                  color: context.themePrimary)),
                          const SizedBox(width: 2),
                          Icon(Icons.arrow_forward_rounded,
                              size: 14, color: context.themePrimary),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 12),

              // ── Category chips ───────────────────────────────────────────
              if (!isLoading && categories.isNotEmpty)
                SizedBox(
                  height: 34,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    children: [
                      _CategoryChip(
                        label: 'All',
                        selected: _selectedCategory == null,
                        accent: context.themePrimary,
                        isDark: isDark,
                        onTap: () =>
                            setState(() => _selectedCategory = null),
                      ),
                      ...categories.map((cat) => Padding(
                            padding: const EdgeInsets.only(left: 8),
                            child: _CategoryChip(
                              label: cat,
                              selected: _selectedCategory == cat,
                              accent: _categoryAccent(cat),
                              isDark: isDark,
                              onTap: () =>
                                  setState(() => _selectedCategory = cat),
                            ),
                          )),
                    ],
                  ),
                ),

              const SizedBox(height: 12),

              // ── Product cards row ────────────────────────────────────────
              if (isLoading)
                _ProductShimmerRow(isDark: isDark)
              else if (filtered.isEmpty)
                Padding(
                  padding:
                      const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
                  child: Center(
                    child: Text('No products yet',
                        style: AppTypography.bodySmall(
                            color: context.themeTextSecondary)),
                  ),
                )
              else
                SizedBox(
                  height: 200,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: filtered.length,
                    itemBuilder: (context, i) {
                      final data = filtered[i].data();
                      final id = filtered[i].id;
                      return Padding(
                        padding: EdgeInsets.only(
                            right: i < filtered.length - 1 ? 12 : 0),
                        child: _ProductCard(
                          id: id,
                          data: data,
                          isDark: isDark,
                        ),
                      );
                    },
                  ),
                ),

              const SizedBox(height: 12),
            ],
          ),
        );
      },
    );
  }
}

// ---------------------------------------------------------------------------
// Category chip
// ---------------------------------------------------------------------------

class _CategoryChip extends StatelessWidget {
  final String label;
  final bool selected;
  final Color accent;
  final bool isDark;
  final VoidCallback onTap;

  const _CategoryChip({
    required this.label,
    required this.selected,
    required this.accent,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: selected
              ? accent
              : accent.withValues(alpha: isDark ? 0.15 : 0.10),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: accent.withValues(alpha: selected ? 0 : 0.30),
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (selected) ...[
              Icon(_categoryIcon(label),
                  size: 12, color: AppColors.white),
              const SizedBox(width: 4),
            ],
            Text(
              label,
              style: AppTypography.labelSmall(
                color: selected
                    ? AppColors.white
                    : accent,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Product card
// ---------------------------------------------------------------------------

class _ProductCard extends StatelessWidget {
  final String id;
  final Map<String, dynamic> data;
  final bool isDark;

  const _ProductCard({
    required this.id,
    required this.data,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final name = (data['name'] as String? ?? data['productName'] as String? ?? 'Product').trim();
    final price = data['price'] ?? data['mrp'] ?? data['rate'];
    final imageUrl = data['imageUrl'] as String? ?? data['image'] as String?;
    final cat = ((data['mainCategory'] as String?) ??
            (data['category'] as String?) ??
            '')
        .trim();
    final accent = cat.isNotEmpty ? _categoryAccent(cat) : context.themePrimary;
    final surfaceBg = isDark ? const Color(0xFF1E2130) : const Color(0xFFF8F9FB);

    return GestureDetector(
      onTap: () => context.push(
          '/products?category=${Uri.encodeComponent(cat)}'),
      child: Container(
        width: 148,
        decoration: BoxDecoration(
          color: surfaceBg,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: accent.withValues(alpha: isDark ? 0.25 : 0.15),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.black.withValues(alpha: isDark ? 0.20 : 0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image
            ClipRRect(
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(15)),
              child: SizedBox(
                height: 108,
                width: double.infinity,
                child: imageUrl != null && imageUrl.isNotEmpty
                    ? Image.network(
                        imageUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) =>
                            _ProductImageFallback(accent: accent, cat: cat),
                      )
                    : _ProductImageFallback(accent: accent, cat: cat),
              ),
            ),

            // Info
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.labelMedium(
                        color: context.themeTextPrimary),
                  ),
                  const SizedBox(height: 4),
                  if (price != null)
                    Text(
                      '₹${price.toString()}',
                      style: AppTypography.labelSmall(color: accent).copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    )
                  else
                    Text(
                      cat.isNotEmpty ? cat : 'View details',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.caption(
                          color: context.themeTextSecondary),
                    ),
                ],
              ),
            ),
          ],
        ),
      ).animate().fadeIn(duration: 300.ms).slideX(begin: 0.08, end: 0),
    );
  }
}

class _ProductImageFallback extends StatelessWidget {
  final Color accent;
  final String cat;
  const _ProductImageFallback({required this.accent, required this.cat});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: accent.withValues(alpha: 0.10),
      child: Center(
        child: Icon(
          _categoryIcon(cat),
          size: 40,
          color: accent.withValues(alpha: 0.60),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Shimmer placeholder row
// ---------------------------------------------------------------------------

class _ProductShimmerRow extends StatelessWidget {
  final bool isDark;
  const _ProductShimmerRow({required this.isDark});

  @override
  Widget build(BuildContext context) {
    final shimmerBg = isDark ? const Color(0xFF1E2130) : const Color(0xFFF0F2F5);
    return SizedBox(
      height: 200,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: 4,
        itemBuilder: (_, i) => Padding(
          padding: EdgeInsets.only(right: i < 3 ? 12 : 0),
          child: Container(
            width: 148,
            decoration: BoxDecoration(
              color: shimmerBg,
              borderRadius: BorderRadius.circular(16),
            ),
          )
              .animate(onPlay: (c) => c.repeat())
              .shimmer(duration: 1200.ms),
        ),
      ),
    );
  }
}
