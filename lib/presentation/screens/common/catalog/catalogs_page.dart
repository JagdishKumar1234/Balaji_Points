import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:balaji_points/core/design/app_colors.dart';
import 'package:balaji_points/core/design/app_radius.dart';
import 'package:balaji_points/core/design/app_typography.dart';
import 'package:balaji_points/core/models/catalog.dart';
import 'package:balaji_points/l10n/app_localizations.dart';
import 'package:balaji_points/presentation/screens/common/catalog/catalog_widgets.dart';
import 'package:balaji_points/presentation/widgets/shared/app_loader.dart';
import 'package:balaji_points/presentation/widgets/shared/empty_state.dart';
import 'package:balaji_points/services/platform/catalog_service.dart';

/// The one Catalogs screen: category chips on top (All, Laminates, Doors...)
/// and every catalog cover below. Tapping a cover opens the PDF directly,
/// so Home -> Catalogs -> catalog is two taps.
class CatalogsPage extends ConsumerStatefulWidget {
  const CatalogsPage({super.key, this.initialCategoryId, this.inTab = false});

  /// Shown as a tab (guest mode): no back arrow.
  final bool inTab;

  /// Pre-selected chip (old `/catalogs/{categoryId}` links).
  final String? initialCategoryId;

  @override
  ConsumerState<CatalogsPage> createState() => _CatalogsPageState();
}

class _CatalogsPageState extends ConsumerState<CatalogsPage> {
  /// Null = All.
  String? _selected;

  @override
  void initState() {
    super.initState();
    _selected = widget.initialCategoryId;
  }

  Future<void> _refresh() => Future.wait([
    ref.read(catalogCategoriesProvider.notifier).refresh(),
    ref.read(allCatalogsProvider.notifier).refresh(),
  ]);

  void _retry() {
    ref.invalidate(catalogCategoriesProvider);
    ref.invalidate(allCatalogsProvider);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final categoriesAsync = ref.watch(catalogCategoriesProvider);
    final catalogsAsync = ref.watch(allCatalogsProvider);
    final categories = categoriesAsync.asData?.value;
    final catalogs = catalogsAsync.asData?.value;

    Widget body;
    if (categories != null && catalogs != null) {
      body = _content(context, categories, catalogs);
    } else if (categoriesAsync.hasError || catalogsAsync.hasError) {
      body = Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: EmptyState(
            icon: Icons.wifi_off_rounded,
            title: l10n.catalogLoadError,
            actionLabel: l10n.retry,
            onAction: _retry,
          ),
        ),
      );
    } else {
      body = const Center(child: AppLoader());
    }

    return Scaffold(
      backgroundColor: context.themeBackground,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          CatalogNavBar(
            showBack: !widget.inTab,
            title: l10n.catalogs,
            subtitle: catalogs == null
                ? l10n.catalogsSubtitle
                : l10n.catalogCount(catalogs.length),
          ),
          Expanded(child: body),
        ],
      ),
    );
  }

  Widget _content(
    BuildContext context,
    List<CatalogCategory> categories,
    List<Catalog> catalogs,
  ) {
    final l10n = AppLocalizations.of(context)!;
    // Only categories that members can see and that have catalogs.
    final byCategory = <String, List<Catalog>>{
      for (final c in categories)
        c.id: catalogs.where((x) => x.categoryId == c.id).toList(),
    }..removeWhere((_, list) => list.isEmpty);
    final shown = categories
        .where((c) => byCategory.containsKey(c.id))
        .toList();
    final selected = byCategory.containsKey(_selected) ? _selected : null;

    if (shown.isEmpty) {
      return RefreshIndicator(
        onRefresh: _refresh,
        color: context.themePrimary,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: [
            const SizedBox(height: 48),
            EmptyState(
              icon: Icons.menu_book_rounded,
              title: l10n.catalogsEmpty,
              message: l10n.catalogsEmptyMessage,
            ),
          ],
        ),
      );
    }

    final total = byCategory.values.fold<int>(0, (n, l) => n + l.length);
    final sections = selected == null
        ? shown
        : shown.where((c) => c.id == selected).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (shown.length > 1)
          SizedBox(
            height: 52,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 6),
              children: [
                _Chip(
                  label: l10n.all,
                  count: total,
                  selected: selected == null,
                  onTap: () => setState(() => _selected = null),
                ),
                for (final c in shown)
                  _Chip(
                    label: c.name,
                    count: byCategory[c.id]!.length,
                    selected: selected == c.id,
                    onTap: () => setState(() => _selected = c.id),
                  ),
              ],
            ),
          ),
        Expanded(
          child: LayoutBuilder(
            builder: (context, box) {
              const pad = 16.0;
              const gap = 12.0;
              final cols = ((box.maxWidth - pad * 2 + gap) / (160 + gap))
                  .floor()
                  .clamp(2, 6);
              final tileW = (box.maxWidth - pad * 2 - gap * (cols - 1)) / cols;
              final delegate = SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: cols,
                crossAxisSpacing: gap,
                mainAxisSpacing: 16,
                // Room for the text at the phone's font size, so large
                // system fonts never overflow the tile.
                mainAxisExtent:
                    tileW * 4 / 3 +
                    _CatalogTile.textHeight(MediaQuery.textScalerOf(context)),
              );
              return RefreshIndicator(
                onRefresh: _refresh,
                color: context.themePrimary,
                child: CustomScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  slivers: [
                    for (final cat in sections) ...[
                      // Section titles only in "All"; a chip already names
                      // the one category on screen.
                      if (selected == null)
                        SliverPadding(
                          padding: const EdgeInsets.fromLTRB(pad, 14, pad, 10),
                          sliver: SliverToBoxAdapter(
                            child: Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    cat.name,
                                    style: AppTypography.h5(
                                      color: context.themeTextPrimary,
                                    ),
                                  ),
                                ),
                                Text(
                                  l10n.catalogCount(byCategory[cat.id]!.length),
                                  style: AppTypography.caption(
                                    color: context.themeTextSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        )
                      else
                        const SliverToBoxAdapter(child: SizedBox(height: 10)),
                      SliverPadding(
                        padding: const EdgeInsets.symmetric(horizontal: pad),
                        sliver: SliverGrid.builder(
                          gridDelegate: delegate,
                          itemCount: byCategory[cat.id]!.length,
                          itemBuilder: (_, i) =>
                              _CatalogTile(catalog: byCategory[cat.id]![i]),
                        ),
                      ),
                    ],
                    SliverToBoxAdapter(
                      child: SizedBox(
                        height: 24 + MediaQuery.paddingOf(context).bottom,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({
    required this.label,
    required this.count,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final int count;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final fg = selected ? context.themeOnPrimary : context.themeTextPrimary;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: Material(
        color: selected ? context.themePrimary : context.themeCard,
        borderRadius: AppRadius.pill,
        child: InkWell(
          borderRadius: AppRadius.pill,
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              borderRadius: AppRadius.pill,
              border: Border.all(
                color: selected ? context.themePrimary : context.themeBorder,
              ),
            ),
            child: Text(
              '$label  $count',
              style: AppTypography.labelMedium(color: fg),
            ),
          ),
        ),
      ),
    );
  }
}

/// Cover + title + "86 pages · 11 MB". The whole tile opens the reader.
class _CatalogTile extends StatelessWidget {
  const _CatalogTile({required this.catalog});

  final Catalog catalog;

  /// Height under the cover: padding, two title lines and the meta line,
  /// scaled with the phone's font size.
  static double textHeight(TextScaler scaler) => 14 + scaler.scale(58);

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return InkWell(
      borderRadius: AppRadius.forCard,
      onTap: () =>
          context.push('/catalogs/${catalog.categoryId}/${catalog.id}'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: AppRadius.md12,
                border: Border.all(color: context.themeBorder),
              ),
              child: CatalogCover(
                url: catalog.coverUrl,
                decodeWidth: kCatalogGridDecodeWidth,
              ),
            ),
          ),
          // Natural height; the cover above flexes, so nothing overflows.
          Padding(
            padding: const EdgeInsets.only(top: 6, bottom: 4),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  catalog.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.labelMedium(
                    color: context.themeTextPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  catalogMeta(l10n, catalog),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.caption(
                    color: context.themeTextSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
