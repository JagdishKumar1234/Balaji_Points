import 'package:cloud_firestore/cloud_firestore.dart';

/// A section of the catalog library, e.g. Laminates, Plywood, Doors.
/// Firestore: `catalog_categories/{id}`.
class CatalogCategory {
  const CatalogCategory({
    required this.id,
    required this.name,
    this.description = '',
    this.coverUrl = '',
    this.sortOrder = 0,
    this.catalogCount = 0,
    this.active = true,
  });

  final String id;
  final String name;
  final String description;
  final String coverUrl;
  final int sortOrder;
  final int catalogCount;
  final bool active;

  factory CatalogCategory.fromMap(String id, Map<String, dynamic> d) =>
      CatalogCategory(
        id: id,
        name: (d['name'] as String? ?? id).trim(),
        description: (d['description'] as String? ?? '').trim(),
        coverUrl: d['coverUrl'] as String? ?? '',
        sortOrder: (d['sortOrder'] as num?)?.toInt() ?? 0,
        catalogCount: (d['catalogCount'] as num?)?.toInt() ?? 0,
        active: d['active'] as bool? ?? true,
      );

  factory CatalogCategory.fromDoc(DocumentSnapshot<Map<String, dynamic>> d) =>
      CatalogCategory.fromMap(d.id, d.data() ?? const {});
}

/// One PDF catalog. Firestore: `catalogs/{id}`; the file lives in Storage
/// at `catalogs/{categoryId}/{id}.pdf`, with a small cover JPEG beside it.
class Catalog {
  const Catalog({
    required this.id,
    required this.categoryId,
    required this.title,
    required this.pdfUrl,
    this.brand = '',
    this.description = '',
    this.coverUrl = '',
    this.fileName = '',
    this.pages = 0,
    this.sizeBytes = 0,
    this.year = 0,
    this.sortOrder = 0,
    this.active = true,
    this.version = 0,
    this.pdfPath = '',
    this.coverPath = '',
  });

  final String id;
  final String categoryId;
  final String title;
  final String brand;
  final String description;
  final String pdfUrl;
  final String coverUrl;
  final String fileName;
  final int pages;
  final int sizeBytes;
  final int year;
  final int sortOrder;
  final bool active;

  /// Goes up each time the PDF is replaced.
  final int version;

  /// Storage paths, so a replaced or deleted file can be removed.
  final String pdfPath;
  final String coverPath;

  factory Catalog.fromMap(String id, Map<String, dynamic> d) => Catalog(
    id: id,
    categoryId: d['categoryId'] as String? ?? '',
    title: (d['title'] as String? ?? id).trim(),
    brand: (d['brand'] as String? ?? '').trim(),
    description: (d['description'] as String? ?? '').trim(),
    pdfUrl: d['pdfUrl'] as String? ?? '',
    coverUrl: d['coverUrl'] as String? ?? '',
    fileName: d['fileName'] as String? ?? '$id.pdf',
    pages: (d['pages'] as num?)?.toInt() ?? 0,
    sizeBytes: (d['sizeBytes'] as num?)?.toInt() ?? 0,
    year: (d['year'] as num?)?.toInt() ?? 0,
    sortOrder: (d['sortOrder'] as num?)?.toInt() ?? 0,
    active: d['active'] as bool? ?? true,
    version: (d['version'] as num?)?.toInt() ?? 0,
    pdfPath: d['pdfPath'] as String? ?? '',
    coverPath: d['coverPath'] as String? ?? '',
  );

  factory Catalog.fromDoc(DocumentSnapshot<Map<String, dynamic>> d) =>
      Catalog.fromMap(d.id, d.data() ?? const {});

  /// "12.4 MB" / "850 KB"; empty when unknown.
  String get sizeLabel => formatFileSize(sizeBytes);
}

String formatFileSize(int bytes) {
  if (bytes <= 0) return '';
  if (bytes < 1024 * 1024) return '${(bytes / 1024).round()} KB';
  final mb = bytes / (1024 * 1024);
  return '${mb >= 10 ? mb.round() : mb.toStringAsFixed(1)} MB';
}
