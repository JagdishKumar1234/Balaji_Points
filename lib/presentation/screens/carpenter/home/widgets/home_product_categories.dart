import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';

import 'package:balaji_points/core/design/app_colors.dart';
import 'package:balaji_points/core/design/app_typography.dart';

// ---------------------------------------------------------------------------
// Category helpers
// ---------------------------------------------------------------------------

IconData _categoryIcon(String category) {
  final key = category.toLowerCase();
  if (key.contains('plywood')) return Icons.layers_rounded;
  if (key.contains('laminat')) return Icons.view_quilt_rounded;
  if (key.contains('hardware')) return Icons.build_rounded;
  if (key.contains('veneer')) return Icons.texture_rounded;
  if (key.contains('accessori')) return Icons.category_rounded;
  if (key.contains('bedroom')) return Icons.bed_rounded;
  if (key.contains('kitchen')) return Icons.kitchen_rounded;
  if (key.contains('living')) return Icons.chair_rounded;
  if (key.contains('wardrobe')) return Icons.checkroom_rounded;
  if (key.contains('office')) return Icons.workspaces_rounded;
  if (key.contains('bathroom')) return Icons.bathtub_rounded;
  return Icons.widgets_rounded;
}

Color _categoryAccent(String category) {
  const colors = [
    Color(0xFF2563EB),
    Color(0xFFD97706),
    Color(0xFF7C3AED),
    Color(0xFF0891B2),
    Color(0xFF16A34A),
    Color(0xFFDC2626),
    Color(0xFF9333EA),
    Color(0xFF0D9488),
  ];
  return colors[category.length % colors.length];
}

// ---------------------------------------------------------------------------
// HomeProductCategories
// ---------------------------------------------------------------------------

class HomeProductCategories extends StatelessWidget {
  const HomeProductCategories({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? const Color(0xFF171A22) : AppColors.white;
    final sectionBg = isDark ? const Color(0xFF0F1115) : const Color(0xFFF4F6FA);

    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('products')
          .where('isActive', isEqualTo: true)
          .snapshots(),
      builder: (context, snapshot) {
        final categories = <String>[];
        if (snapshot.hasData) {
          for (final doc in snapshot.data!.docs) {
            final cat = (doc.data()['mainCategory'] as String? ??
                    doc.data()['category'] as String? ??
                    '')
                .trim();
            if (cat.isNotEmpty && !categories.contains(cat)) {
              categories.add(cat);
            }
          }
        }

        final isLoading = snapshot.connectionState == ConnectionState.waiting;

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
              // Section header
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
                      child: Icon(Icons.layers_rounded,
                          size: 18, color: context.themePrimary),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Product Categories',
                        style: AppTypography.h5(
                            color: context.themeTextPrimary),
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

              const SizedBox(height: 14),

              // Category grid / shimmer
              if (isLoading)
                _ShimmerGrid(isDark: isDark)
              else if (categories.isEmpty)
                Padding(
                  padding: const EdgeInsets.all(24),
                  child: Center(
                    child: Text('No products yet',
                        style: AppTypography.bodySmall(
                            color: context.themeTextSecondary)),
                  ),
                )
              else
                _CategoryGrid(
                  categories: categories,
                  isDark: isDark,
                  sectionBg: sectionBg,
                ),

              const SizedBox(height: 4),
            ],
          ),
        );
      },
    );
  }
}

// ---------------------------------------------------------------------------
// _CategoryGrid — wrapped rows, no horizontal scroll
// ---------------------------------------------------------------------------

class _CategoryGrid extends StatelessWidget {
  final List<String> categories;
  final bool isDark;
  final Color sectionBg;

  const _CategoryGrid({
    required this.categories,
    required this.isDark,
    required this.sectionBg,
  });

  @override
  Widget build(BuildContext context) {
    // Fixed 4-per-row grid
    const crossCount = 4;
    final rows = (categories.length / crossCount).ceil();

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
      child: Column(
        children: List.generate(rows, (row) {
          final start = row * crossCount;
          final end = (start + crossCount).clamp(0, categories.length);
          final rowCats = categories.sublist(start, end);

          return Padding(
            padding: EdgeInsets.only(top: row == 0 ? 0 : 8),
            child: Row(
              children: [
                for (int i = 0; i < crossCount; i++)
                  Expanded(
                    child: i < rowCats.length
                        ? _CategoryTile(
                            title: rowCats[i],
                            isDark: isDark,
                            onTap: () => context.push(
                              '/products?category=${Uri.encodeComponent(rowCats[i])}',
                            ),
                          )
                        : const SizedBox(),
                  ),
              ],
            ),
          );
        }),
      ),
    );
  }
}

class _CategoryTile extends StatelessWidget {
  final String title;
  final bool isDark;
  final VoidCallback onTap;

  const _CategoryTile({
    required this.title,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final accent = _categoryAccent(title);
    final icon = _categoryIcon(title);
    final bgColor = isDark
        ? accent.withValues(alpha: 0.15)
        : accent.withValues(alpha: 0.10);

    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: double.infinity,
              height: 62,
              decoration: BoxDecoration(
                color: bgColor,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: accent.withValues(alpha: isDark ? 0.25 : 0.15),
                  width: 1,
                ),
              ),
              child: Icon(icon, size: 28, color: accent),
            ),
            const SizedBox(height: 5),
            Text(
              title,
              style: AppTypography.caption(color: context.themeTextPrimary),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

class _ShimmerGrid extends StatelessWidget {
  final bool isDark;
  const _ShimmerGrid({required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
      child: Row(
        children: List.generate(
          4,
          (_) => Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Container(
                height: 62,
                decoration: BoxDecoration(
                  color: context.themeSoftSurface,
                  borderRadius: BorderRadius.circular(14),
                ),
              )
                  .animate(onPlay: (c) => c.repeat())
                  .shimmer(duration: 1200.ms),
            ),
          ),
        ),
      ),
    );
  }
}
