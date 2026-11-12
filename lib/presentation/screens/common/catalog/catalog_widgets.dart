import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:balaji_points/core/design/app_colors.dart';
import 'package:balaji_points/core/design/app_radius.dart';
import 'package:balaji_points/core/logger.dart';
import 'package:balaji_points/core/models/catalog.dart';
import 'package:balaji_points/l10n/app_localizations.dart';
import 'package:balaji_points/presentation/widgets/carpenter/home_nav_bar.dart';

/// Width covers are decoded at, shared by the grid and the cover precache
/// (same image-cache key, so preloaded covers show at once).
const double kCatalogGridDecodeWidth = 200;

/// App bar used by every catalog screen. Back pops when there is a screen
/// behind; on a fresh web link it goes to [fallback] instead.
class CatalogNavBar extends StatelessWidget {
  const CatalogNavBar({
    super.key,
    required this.title,
    this.subtitle,
    this.fallback = '/',
    this.actions,
  });

  final String title;
  final String? subtitle;
  final String fallback;
  final List<Widget>? actions;

  @override
  Widget build(BuildContext context) => HomeNavBar(
    title: title,
    subtitle: subtitle,
    showLogo: false,
    showProfileButton: false,
    showBackButton: true,
    onBackTap: () => context.canPop() ? context.pop() : context.go(fallback),
    actions: actions,
  );
}

/// Small cover JPEG (about 30-60 KB). Shows a book icon while loading or
/// when there is no cover, so the list never waits on images.
class CatalogCover extends StatelessWidget {
  const CatalogCover({
    super.key,
    required this.url,
    this.width,
    this.height,
    this.decodeWidth,
    this.radius = AppRadius.md12,
    this.fit = BoxFit.cover,
  });

  final String url;
  final double? width;
  final double? height;

  /// Decode size when [width] is not fixed (grid tiles).
  final double? decodeWidth;
  final BorderRadius radius;
  final BoxFit fit;

  @override
  Widget build(BuildContext context) {
    final placeholder = Container(
      width: width,
      height: height,
      color: context.themePrimary.withValues(alpha: 0.08),
      alignment: Alignment.center,
      child: Icon(
        Icons.menu_book_rounded,
        color: context.themePrimary.withValues(alpha: 0.5),
        size: 28,
      ),
    );
    return ClipRRect(
      borderRadius: radius,
      child: url.isEmpty
          ? placeholder
          : Image.network(
              url,
              width: width,
              height: height,
              fit: fit,
              // Decode at display size, not the file's full size.
              cacheWidth: (width ?? decodeWidth) == null
                  ? null
                  : ((width ?? decodeWidth)! *
                            MediaQuery.devicePixelRatioOf(context))
                        .round(),
              loadingBuilder: (_, child, progress) =>
                  progress == null ? child : placeholder,
              errorBuilder: (_, __, ___) => placeholder,
            ),
    );
  }
}

/// Warms the in-memory image cache with cover JPEGs at the exact size
/// [CatalogCover] decodes them at (same cache key), so covers show at once
/// when the list opens. Memory only: nothing is written to the phone.
void precacheCatalogCovers(
  BuildContext context,
  Iterable<String> urls, {
  required double width,
}) {
  final w = (width * MediaQuery.devicePixelRatioOf(context)).round();
  for (final url in urls.where((u) => u.isNotEmpty).toSet()) {
    precacheImage(
      ResizeImage(NetworkImage(url), width: w),
      context,
      onError: (_, __) {},
    );
  }
}

/// Share sends the catalog's link (not the file), so nothing is saved on
/// the phone. The receiver opens it in any browser or PDF app.
Future<void> shareCatalog(BuildContext context, Catalog catalog) async {
  final l10n = AppLocalizations.of(context)!;
  final box = context.findRenderObject() as RenderBox?;
  try {
    await SharePlus.instance.share(
      ShareParams(
        text: l10n.catalogShareText(catalog.title, catalog.pdfUrl),
        subject: catalog.title,
        sharePositionOrigin: box == null || !box.hasSize
            ? null
            : box.localToGlobal(Offset.zero) & box.size,
      ),
    );
  } catch (e) {
    AppLogger.error('Catalog share failed', e);
  }
}

/// Download hands the PDF link to the phone's browser / download manager,
/// which saves it to Downloads. The app itself keeps no copy.
Future<void> downloadCatalog(BuildContext context, Catalog catalog) async {
  final l10n = AppLocalizations.of(context)!;
  final messenger = ScaffoldMessenger.of(context);
  final errorColor = context.themeError;
  var opened = false;
  try {
    opened = await launchUrl(
      Uri.parse(catalog.pdfUrl),
      mode: LaunchMode.externalApplication,
      webOnlyWindowName: '_blank',
    );
  } catch (e) {
    AppLogger.error('Catalog download failed', e);
  }
  if (!opened) {
    messenger.showSnackBar(
      SnackBar(
        content: Text(l10n.catalogOpenError),
        backgroundColor: errorColor,
      ),
    );
  }
}

/// "86 pages · 12 MB · 2024"
String catalogMeta(AppLocalizations l10n, Catalog c) => [
  if (c.pages > 0) l10n.catalogPages(c.pages),
  if (c.sizeLabel.isNotEmpty) c.sizeLabel,
  if (c.year > 0) '${c.year}',
].join('  ·  ');
