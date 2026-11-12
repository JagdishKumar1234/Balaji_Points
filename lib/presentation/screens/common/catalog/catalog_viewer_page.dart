import 'dart:async';
import 'dart:io' show Directory, File;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdfrx/pdfrx.dart';

import 'package:balaji_points/core/design/app_colors.dart';
import 'package:balaji_points/core/design/app_radius.dart';
import 'package:balaji_points/core/design/app_typography.dart';
import 'package:balaji_points/core/logger.dart';
import 'package:balaji_points/core/models/catalog.dart';
import 'package:balaji_points/l10n/app_localizations.dart';
import 'package:balaji_points/services/platform/catalog_file_cache.dart';
import 'package:balaji_points/services/platform/catalog_service.dart';
import 'package:balaji_points/presentation/screens/common/catalog/catalog_widgets.dart';
import 'package:balaji_points/presentation/widgets/shared/app_loader.dart';
import 'package:balaji_points/presentation/widgets/shared/empty_state.dart';

/// Looks a catalog up from the (already loaded) catalog list, so the reader
/// opens with no extra network call.
final catalogByIdProvider =
    Provider.family<AsyncValue<Catalog?>, ({String categoryId, String id})>(
      (ref, key) => ref
          .watch(catalogsInCategoryProvider(key.categoryId))
          .whenData((list) => list.where((c) => c.id == key.id).firstOrNull),
    );

/// Zoom used by double-tap and the + button's first step.
const double _kTapZoom = 2.5;

/// Full-screen PDF reader, opened straight from the catalog list (no detail
/// screen in between). Share and Download sit in the top bar; pinch,
/// double-tap or the +/- buttons zoom.
/// The PDF streams from Firebase Storage: pdfrx
/// fetches only the parts it needs and draws only the pages on screen, so
/// large catalogs stay light on memory. Its temporary download is deleted
/// when the reader closes, so nothing stays on the phone.
class CatalogViewerPage extends ConsumerStatefulWidget {
  const CatalogViewerPage({
    super.key,
    required this.categoryId,
    required this.catalogId,
  });

  final String categoryId;
  final String catalogId;

  @override
  ConsumerState<CatalogViewerPage> createState() => _CatalogViewerPageState();
}

class _CatalogViewerPageState extends ConsumerState<CatalogViewerPage> {
  final _controller = PdfViewerController();
  int _page = 1;
  int _total = 0;

  /// The saved PDF (instant open). Null while it downloads, or on web.
  File? _file;
  String? _openedKey;
  bool _stream = false;

  /// Opens the saved copy if Home already preloaded it; otherwise downloads
  /// the whole file once (much faster than fetching page by page) and keeps
  /// it for next time. If saving fails, falls back to streaming.
  void _prepare(Catalog c) {
    final key = '${c.id}_${c.version}';
    if (_openedKey == key) return;
    _openedKey = key;
    if (kIsWeb) {
      _stream = true;
      return;
    }
    final cache = CatalogFileCache.instance;
    final saved = cache.peek(c);
    if (saved != null) {
      _file = saved;
      return;
    }
    cache.ensure(c).then((f) {
      if (!mounted || _openedKey != key) return;
      setState(() => f == null ? _stream = true : _file = f);
    });
  }

  @override
  void dispose() {
    // Give pdfrx a moment to close the file, then remove it.
    Future.delayed(const Duration(seconds: 1), clearCatalogViewerCache);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final async = ref.watch(
      catalogByIdProvider((
        categoryId: widget.categoryId,
        id: widget.catalogId,
      )),
    );
    final catalog = async.asData?.value;

    return Scaffold(
      backgroundColor: context.themeSoftSurface,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          CatalogNavBar(
            title: catalog?.title ?? l10n.catalogs,
            subtitle: _total > 0
                ? l10n.catalogPageOf(_page, _total)
                : catalog?.brand,
            fallback: '/catalogs',
            actions: catalog == null
                ? null
                : [
                    Builder(
                      builder: (ctx) => IconButton(
                        tooltip: l10n.catalogShare,
                        icon: const Icon(Icons.share_rounded),
                        onPressed: () => shareCatalog(ctx, catalog),
                      ),
                    ),
                    IconButton(
                      tooltip: l10n.catalogDownload,
                      icon: const Icon(Icons.download_rounded),
                      onPressed: () => downloadCatalog(context, catalog),
                    ),
                  ],
          ),
          Expanded(
            child: async.when(
              loading: () => const Center(child: AppLoader()),
              error: (_, __) => Center(
                child: EmptyState(
                  icon: Icons.wifi_off_rounded,
                  title: l10n.catalogLoadError,
                ),
              ),
              data: (c) => c == null
                  ? Center(
                      child: EmptyState(
                        icon: Icons.menu_book_rounded,
                        title: l10n.catalogsEmpty,
                      ),
                    )
                  : Stack(
                      children: [
                        Positioned.fill(child: _viewer(context, c)),
                        if (_total > 0)
                          Positioned(
                            // Left of the page-number scroll thumb on the right edge.
                            right: 56,
                            bottom: 16 + MediaQuery.paddingOf(context).bottom,
                            child: _ZoomControls(controller: _controller),
                          ),
                      ],
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _viewer(BuildContext context, Catalog c) {
    _prepare(c);
    final file = _file;
    if (file != null) {
      return PdfViewer.file(
        file.path,
        controller: _controller,
        params: _params(context, c),
      );
    }
    if (_stream) {
      return PdfViewer.uri(
        Uri.parse(c.pdfUrl),
        controller: _controller,
        params: _params(context, c),
      );
    }
    return ValueListenableBuilder<int>(
      valueListenable: CatalogFileCache.instance.progressOf(c),
      builder: (_, done, __) => _LoadingBanner(done: done, total: c.sizeBytes),
    );
  }

  PdfViewerParams _params(BuildContext context, Catalog c) {
    final l10n = AppLocalizations.of(context)!;
    return PdfViewerParams(
      backgroundColor: context.themeSoftSurface,
      margin: 8,
      maxScale: 8,
      // Double-tap: zoom in on that spot; double-tap again: back to fit.
      onGeneralTap: (ctx, controller, d) {
        if (d.type != PdfViewerGeneralTapType.doubleTap) return false;
        final zoomedIn = controller.currentZoom > controller.minScale * 1.05;
        controller.zoomOnLocalPosition(
          localPosition: d.localPosition,
          newZoom: zoomedIn ? controller.minScale : _kTapZoom,
        );
        return true;
      },
      onViewerReady: (doc, _) {
        if (mounted) setState(() => _total = doc.pages.length);
      },
      onPageChanged: (p) {
        if (p != null && p != _page && mounted) setState(() => _page = p);
      },
      loadingBannerBuilder: (ctx, done, total) =>
          _LoadingBanner(done: done, total: total ?? c.sizeBytes),
      errorBannerBuilder: (ctx, error, _, __) {
        AppLogger.error('Catalog PDF failed to open', error);
        return Center(
          child: EmptyState(
            icon: Icons.wifi_off_rounded,
            title: l10n.catalogOpenError,
          ),
        );
      },
      viewerOverlayBuilder: (ctx, size, _) => [
        PdfViewerScrollThumb(
          controller: _controller,
          orientation: ScrollbarOrientation.right,
          thumbSize: const Size(44, 28),
          thumbBuilder: (ctx, thumbSize, pageNumber, controller) => Container(
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: AppRadius.sm8,
            ),
            alignment: Alignment.center,
            child: Text(
              '${pageNumber ?? ''}',
              style: AppTypography.labelSmall(color: AppColors.white),
            ),
          ),
        ),
      ],
    );
  }
}

/// Floating + / fit / - buttons, for members who find pinch hard. The fit
/// button shows the current zoom and resets to the whole page.
class _ZoomControls extends StatelessWidget {
  const _ZoomControls({required this.controller});

  final PdfViewerController controller;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        if (!controller.isReady) return const SizedBox.shrink();
        final zoom = controller.currentZoom;
        final min = controller.minScale;
        final canZoomOut = zoom > min * 1.01;
        final canZoomIn = zoom < 7.99;
        return Material(
          color: context.themeCard,
          elevation: 3,
          shadowColor: Colors.black26,
          borderRadius: AppRadius.md12,
          clipBehavior: Clip.antiAlias,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                tooltip: l10n.catalogZoomIn,
                icon: const Icon(Icons.add_rounded),
                color: context.themePrimary,
                onPressed: canZoomIn ? () => controller.zoomUp() : null,
              ),
              InkWell(
                onTap: canZoomOut
                    ? () => controller.setZoom(controller.centerPosition, min)
                    : null,
                child: Tooltip(
                  message: l10n.catalogZoomFit,
                  child: SizedBox(
                    width: 48,
                    height: 28,
                    child: Center(
                      child: Text(
                        '${(zoom / min * 100).round()}%',
                        style: AppTypography.labelSmall(
                          color: context.themeTextSecondary,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              IconButton(
                tooltip: l10n.catalogZoomOut,
                icon: const Icon(Icons.remove_rounded),
                color: context.themePrimary,
                onPressed: canZoomOut ? () => controller.zoomDown() : null,
              ),
            ],
          ),
        );
      },
    );
  }
}

class _LoadingBanner extends StatelessWidget {
  const _LoadingBanner({required this.done, required this.total});

  final int done;
  final int total;

  @override
  Widget build(BuildContext context) {
    final progress = total > 0 ? (done / total).clamp(0.0, 1.0) : null;
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 180,
            child: LinearProgressIndicator(
              value: progress,
              color: context.themePrimary,
              backgroundColor: context.themeBorder,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            total > 0
                ? '${formatFileSize(done)} / ${formatFileSize(total)}'
                : formatFileSize(done),
            style: AppTypography.caption(color: context.themeTextSecondary),
          ),
        ],
      ),
    );
  }
}

/// Deletes pdfrx's temporary download folder (`<temp>/pdfrx.cache`).
Future<void> clearCatalogViewerCache() async {
  if (kIsWeb) return;
  try {
    final tmp = await getTemporaryDirectory();
    final dir = Directory('${tmp.path}/pdfrx.cache');
    if (await dir.exists()) await dir.delete(recursive: true);
  } catch (e) {
    AppLogger.warning('Could not clear catalog viewer cache: $e');
  }
}
