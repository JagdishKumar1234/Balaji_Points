import 'dart:ui' as ui;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pdfrx/pdfrx.dart';

import '../../core/logger.dart';
import '../../core/models/catalog.dart';
import 'image_compress_service.dart';

/// Largest PDF an admin can upload. Catalogs from brands are often 50-150 MB
/// print files; those must be compressed first so members on mobile data
/// can open them.
const int kMaxCatalogPdfBytes = 25 * 1024 * 1024;

class CatalogPdfTooLarge implements Exception {
  const CatalogPdfTooLarge(this.bytes);
  final int bytes;
}

class CatalogNotPdf implements Exception {
  const CatalogNotPdf();
}

class CatalogCategoryNotEmpty implements Exception {
  const CatalogCategoryNotEmpty();
}

/// Page count and a first-page cover, read on the admin's device.
class CatalogPdfInfo {
  const CatalogPdfInfo({required this.pages, this.cover});
  final int pages;
  final Uint8List? cover;
}

/// Admin side of the catalog library (admins and super admin). Files go to
/// Firebase Storage, records to Firestore; members only ever read them.
///
/// Storage layout: `catalogs/{catalogId}/v{version}.pdf` and
/// `catalogs/{catalogId}/cover_{stamp}.{jpg|png}`. A new file gets a new
/// path, so phones and browsers never show a stale cached copy, and the old
/// file is deleted after the record points at the new one.
class CatalogAdminService {
  CatalogAdminService({FirebaseFirestore? db, FirebaseStorage? storage})
    : _db = db ?? FirebaseFirestore.instance,
      _storage = storage;

  final FirebaseFirestore _db;
  final FirebaseStorage? _storage;
  FirebaseStorage get _bucket => _storage ?? FirebaseStorage.instance;

  CollectionReference<Map<String, dynamic>> get _categories =>
      _db.collection('catalog_categories');
  CollectionReference<Map<String, dynamic>> get _catalogs =>
      _db.collection('catalogs');

  // ── Reading (admin sees hidden items too) ───────────────────────────────

  Stream<List<CatalogCategory>> watchCategories() =>
      _categories.snapshots().map(
        (s) => s.docs.map(CatalogCategory.fromDoc).toList()
          ..sort(
            (a, b) => a.sortOrder != b.sortOrder
                ? a.sortOrder.compareTo(b.sortOrder)
                : a.name.toLowerCase().compareTo(b.name.toLowerCase()),
          ),
      );

  Stream<List<Catalog>> watchCatalogs() => _catalogs.snapshots().map(
    (s) => s.docs.map(Catalog.fromDoc).toList()
      ..sort(
        (a, b) => a.sortOrder != b.sortOrder
            ? a.sortOrder.compareTo(b.sortOrder)
            : a.title.toLowerCase().compareTo(b.title.toLowerCase()),
      ),
  );

  // ── Categories ──────────────────────────────────────────────────────────

  /// Creates (when [id] is null) or updates a category. Returns its id.
  Future<String> saveCategory({
    String? id,
    required String name,
    String description = '',
    bool active = true,
  }) async {
    final clean = name.trim();
    if (id == null) {
      final all = await _categories.get();
      final taken = all.docs.map((d) => d.id).toSet();
      final newId = uniqueSlug(clean, taken);
      final maxOrder = all.docs.fold<int>(
        0,
        (m, d) => ((d.data()['sortOrder'] as num?)?.toInt() ?? 0) > m
            ? (d.data()['sortOrder'] as num).toInt()
            : m,
      );
      await _categories.doc(newId).set({
        'categoryId': newId,
        'name': clean,
        'description': description.trim(),
        'sortOrder': maxOrder + 1,
        'catalogCount': 0,
        'coverUrl': '',
        'active': active,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
      return newId;
    }
    await _categories.doc(id).update({
      'name': clean,
      'description': description.trim(),
      'active': active,
      'updatedAt': FieldValue.serverTimestamp(),
    });
    return id;
  }

  Future<void> setCategoryActive(String id, bool active) => _categories
      .doc(id)
      .update({'active': active, 'updatedAt': FieldValue.serverTimestamp()});

  /// Only empty categories can be deleted, so no PDF is ever orphaned.
  Future<void> deleteCategory(String id) async {
    final inside = await _catalogs
        .where('categoryId', isEqualTo: id)
        .limit(1)
        .get();
    if (inside.docs.isNotEmpty) throw const CatalogCategoryNotEmpty();
    await _categories.doc(id).delete();
  }

  // ── Catalogs ────────────────────────────────────────────────────────────

  /// Adds a catalog ([existing] null; [pdfBytes] required) or edits one.
  /// Passing [pdfBytes] when editing replaces the PDF. [coverBytes] is an
  /// optional photo; without it a new PDF's first page becomes the cover.
  Future<String> saveCatalog({
    Catalog? existing,
    required String categoryId,
    required String title,
    String brand = '',
    String description = '',
    int year = 0,
    int? sortOrder,
    Uint8List? pdfBytes,
    Uint8List? coverBytes,
    void Function(double progress)? onProgress,
  }) async {
    if (existing == null && pdfBytes == null) {
      throw ArgumentError('A new catalog needs a PDF');
    }
    if (pdfBytes != null) validatePdf(pdfBytes);

    final id = existing?.id ?? _catalogs.doc().id;
    final version = (existing?.version ?? 0) + (pdfBytes != null ? 1 : 0);
    final stamp = DateTime.now().millisecondsSinceEpoch;
    final cleanTitle = title.trim();
    final data = <String, dynamic>{
      'catalogId': id,
      'categoryId': categoryId,
      'title': cleanTitle,
      'brand': brand.trim(),
      'description': description.trim(),
      'year': year,
      'version': version,
      'updatedAt': FieldValue.serverTimestamp(),
    };
    if (sortOrder != null) {
      data['sortOrder'] = sortOrder;
    } else if (existing == null) {
      final count = await _catalogs
          .where('categoryId', isEqualTo: categoryId)
          .count()
          .get();
      data['sortOrder'] = (count.count ?? 0) + 1;
    }
    if (existing == null) {
      data['active'] = true;
      data['createdAt'] = FieldValue.serverTimestamp();
    }

    final oldPaths = <String>[];
    Uint8List? cover = coverBytes;

    if (pdfBytes != null) {
      onProgress?.call(0);
      final info = await inspectPdf(pdfBytes);
      cover ??= info.cover;
      final path = 'catalogs/$id/v$version.pdf';
      final fileName = '${safeFileName(cleanTitle)}.pdf';
      data['pdfUrl'] = await _upload(
        path,
        pdfBytes,
        SettableMetadata(
          contentType: 'application/pdf',
          contentDisposition: 'attachment; filename="$fileName"',
          cacheControl: 'public, max-age=86400',
        ),
        onProgress: onProgress == null ? null : (p) => onProgress(p * 0.95),
      );
      data['pdfPath'] = path;
      data['fileName'] = fileName;
      data['sizeBytes'] = pdfBytes.length;
      data['pages'] = info.pages;
      if (existing != null && existing.pdfPath.isNotEmpty) {
        oldPaths.add(existing.pdfPath);
      }
    }

    if (cover != null) {
      final small = await ImageCompressService.compress(
        cover,
        profile: ImageCompressProfile.cover,
      );
      final png = isPng(small);
      final path = 'catalogs/$id/cover_$stamp.${png ? 'png' : 'jpg'}';
      data['coverUrl'] = await _upload(
        path,
        small,
        SettableMetadata(
          contentType: png ? 'image/png' : 'image/jpeg',
          cacheControl: 'public, max-age=86400',
        ),
      );
      data['coverPath'] = path;
      if (existing != null && existing.coverPath.isNotEmpty) {
        oldPaths.add(existing.coverPath);
      }
    }

    await _catalogs.doc(id).set(data, SetOptions(merge: true));
    onProgress?.call(1);

    await _recount(categoryId);
    if (existing != null && existing.categoryId != categoryId) {
      await _recount(existing.categoryId);
    }
    for (final p in oldPaths) {
      await _deleteFile(p);
    }
    return id;
  }

  Future<void> setCatalogActive(Catalog c, bool active) async {
    await _catalogs.doc(c.id).update({
      'active': active,
      'updatedAt': FieldValue.serverTimestamp(),
    });
    await _recount(c.categoryId);
  }

  Future<void> deleteCatalog(Catalog c) async {
    await _catalogs.doc(c.id).delete();
    await _recount(c.categoryId);
    for (final p in [c.pdfPath, c.coverPath]) {
      if (p.isNotEmpty) await _deleteFile(p);
    }
  }

  /// Keeps the category's member-facing count and cover in step.
  Future<void> _recount(String categoryId) async {
    final snap = await _catalogs
        .where('categoryId', isEqualTo: categoryId)
        .get();
    final active =
        snap.docs
            .map(Catalog.fromDoc)
            .where((c) => c.active && c.pdfUrl.isNotEmpty)
            .toList()
          ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
    final ref = _categories.doc(categoryId);
    if (!(await ref.get()).exists) return;
    await ref.update({
      'catalogCount': active.length,
      'coverUrl': active.isEmpty ? '' : active.first.coverUrl,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  // ── Storage ─────────────────────────────────────────────────────────────

  Future<String> _upload(
    String path,
    Uint8List bytes,
    SettableMetadata meta, {
    void Function(double)? onProgress,
  }) async {
    final ref = _bucket.ref(path);
    final task = ref.putData(bytes, meta);
    final sub = onProgress == null
        ? null
        : task.snapshotEvents.listen((s) {
            if (s.totalBytes > 0) onProgress(s.bytesTransferred / s.totalBytes);
          });
    try {
      await task;
    } finally {
      await sub?.cancel();
    }
    return ref.getDownloadURL();
  }

  Future<void> _deleteFile(String path) async {
    try {
      await _bucket.ref(path).delete();
    } catch (e) {
      AppLogger.warning('Could not delete old catalog file $path: $e');
    }
  }

  // ── Helpers ─────────────────────────────────────────────────────────────

  static void validatePdf(Uint8List bytes) {
    if (!isPdf(bytes)) throw const CatalogNotPdf();
    if (bytes.length > kMaxCatalogPdfBytes) {
      throw CatalogPdfTooLarge(bytes.length);
    }
  }

  /// Opens the PDF on this device to count pages and draw page 1 as the
  /// cover. A PDF that cannot be read is rejected before any upload.
  static Future<CatalogPdfInfo> inspectPdf(Uint8List bytes) async {
    await pdfrxFlutterInitialize(dismissPdfiumWasmWarnings: true);
    final PdfDocument doc;
    try {
      doc = await PdfDocument.openData(bytes, sourceName: 'catalog-upload');
    } catch (e) {
      AppLogger.error('Catalog PDF could not be opened', e);
      throw const CatalogNotPdf();
    }
    try {
      Uint8List? cover;
      if (doc.pages.isNotEmpty) {
        try {
          final page = doc.pages.first;
          const longSide = 480.0;
          final scale =
              longSide / (page.width > page.height ? page.width : page.height);
          final w = (page.width * scale).round();
          final h = (page.height * scale).round();
          final img = await page.render(
            fullWidth: w.toDouble(),
            fullHeight: h.toDouble(),
            width: w,
            height: h,
            backgroundColor: 0xFFFFFFFF,
          );
          if (img != null) {
            final uiImage = await img.createImage();
            img.dispose();
            final data = await uiImage.toByteData(
              format: ui.ImageByteFormat.png,
            );
            uiImage.dispose();
            cover = data?.buffer.asUint8List();
          }
        } catch (e) {
          AppLogger.warning('Could not draw catalog cover: $e');
        }
      }
      return CatalogPdfInfo(pages: doc.pages.length, cover: cover);
    } finally {
      await doc.dispose();
    }
  }

  static bool isPdf(Uint8List b) =>
      b.length > 4 &&
      b[0] == 0x25 && // %
      b[1] == 0x50 && // P
      b[2] == 0x44 && // D
      b[3] == 0x46; // F

  static bool isPng(Uint8List b) =>
      b.length > 4 && b[0] == 0x89 && b[1] == 0x50 && b[2] == 0x4E;

  /// "Kan-B Doors 2024!" -> "kan_b_doors_2024", made unique against [taken].
  @visibleForTesting
  static String uniqueSlug(String name, Set<String> taken) {
    var base = name
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]+'), '_')
        .replaceAll(RegExp(r'^_+|_+$'), '');
    if (base.isEmpty) base = 'category';
    if (base.length > 40) base = base.substring(0, 40);
    var slug = base;
    var n = 2;
    while (taken.contains(slug)) {
      slug = '${base}_${n++}';
    }
    return slug;
  }

  /// File name for the Download button: letters, digits, space, . _ -
  @visibleForTesting
  static String safeFileName(String title) {
    final s = title
        .replaceAll(RegExp(r'[^A-Za-z0-9 ._-]'), '')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
    return s.isEmpty ? 'catalog' : s;
  }
}

final catalogAdminServiceProvider = Provider<CatalogAdminService>(
  (ref) => CatalogAdminService(),
);

final adminCatalogCategoriesProvider =
    StreamProvider.autoDispose<List<CatalogCategory>>(
      (ref) => ref.watch(catalogAdminServiceProvider).watchCategories(),
    );

final adminCatalogsProvider = StreamProvider.autoDispose<List<Catalog>>(
  (ref) => ref.watch(catalogAdminServiceProvider).watchCatalogs(),
);
