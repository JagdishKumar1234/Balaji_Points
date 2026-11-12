import 'dart:typed_data';

import 'package:balaji_points/core/models/catalog.dart';
import 'package:balaji_points/services/platform/catalog_admin_service.dart';
import 'package:balaji_points/services/platform/catalog_service.dart';
import 'package:balaji_points/services/platform/image_compress_service.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ImageCompressService.targetShortSide', () {
    test('portrait phone photo: long edge becomes the max', () {
      // 3000x4000 -> 1200x1600
      expect(ImageCompressService.targetShortSide(3000, 4000, 1600), 1200);
    });

    test('landscape photo gives the same result as portrait', () {
      expect(ImageCompressService.targetShortSide(4000, 3000, 1600), 1200);
    });

    test('small image is not enlarged', () {
      expect(ImageCompressService.targetShortSide(800, 600, 1600), 600);
    });

    test('very tall receipt keeps its shape', () {
      // 1000x5000 -> 320x1600
      expect(ImageCompressService.targetShortSide(1000, 5000, 1600), 320);
    });

    test('bill profile keeps text readable', () {
      const p = ImageCompressProfile.bill;
      expect(p.maxSide, greaterThanOrEqualTo(1600));
      expect(p.minQuality, greaterThanOrEqualTo(45));
    });
  });

  group('formatFileSize', () {
    test('KB, small MB and large MB', () {
      expect(formatFileSize(0), '');
      expect(formatFileSize(500 * 1024), '500 KB');
      expect(formatFileSize((4.5 * 1024 * 1024).round()), '4.5 MB');
      expect(formatFileSize(12 * 1024 * 1024 + 300000), '12 MB');
    });
  });

  group('CatalogService', () {
    late FakeFirebaseFirestore db;
    late CatalogService service;

    setUp(() async {
      db = FakeFirebaseFirestore();
      service = CatalogService(db);
      await db.collection('catalog_categories').doc('doors').set({
        'name': 'Doors',
        'sortOrder': 3,
        'catalogCount': 2,
      });
      await db.collection('catalog_categories').doc('laminates').set({
        'name': 'Laminates',
        'sortOrder': 1,
        'catalogCount': 1,
      });
      await db.collection('catalog_categories').doc('hidden').set({
        'name': 'Hidden',
        'sortOrder': 0,
        'catalogCount': 4,
        'active': false,
      });
      await db.collection('catalog_categories').doc('empty').set({
        'name': 'Empty',
        'sortOrder': 0,
        'catalogCount': 0,
      });
      for (final c in [
        {'id': 'b', 'title': 'Beta', 'sortOrder': 2, 'active': true},
        {'id': 'a', 'title': 'Alpha', 'sortOrder': 1, 'active': true},
        {'id': 'off', 'title': 'Old', 'sortOrder': 0, 'active': false},
      ]) {
        await db.collection('catalogs').doc(c['id'] as String).set({
          ...c,
          'categoryId': 'doors',
          'pdfUrl': 'https://example.com/${c['id']}.pdf',
        });
      }
      await db.collection('catalogs').doc('nofile').set({
        'categoryId': 'doors',
        'title': 'No file yet',
      });
    });

    test('lists only active categories that have catalogs, in order', () async {
      final list = await service.watchCategories().last;
      expect(list.map((c) => c.id), ['laminates', 'doors']);
    });

    test('lists active catalogs with a file, sorted', () async {
      final all = await service.watchAllCatalogs().last;
      final list = all.where((c) => c.categoryId == 'doors').toList();
      expect(list.map((c) => c.id), ['a', 'b']);
      expect(list.first.pdfUrl, 'https://example.com/a.pdf');
      expect(all.any((c) => c.id == 'nofile'), isFalse);
    });

    test(
      'category list is filtered in memory, unknown category is empty',
      () async {
        final container = ProviderContainer(
          overrides: [catalogServiceProvider.overrideWithValue(service)],
        );
        addTearDown(container.dispose);
        container.listen(allCatalogsProvider, (_, __) {});
        await container.read(allCatalogsProvider.future);
        // Let the server copy (second value) land after any cached copy.
        await Future<void>.delayed(Duration.zero);
        expect(
          container
              .read(catalogsInCategoryProvider('doors'))
              .value!
              .map((c) => c.id),
          ['a', 'b'],
        );
        expect(
          container.read(catalogsInCategoryProvider('nope')).value,
          isEmpty,
        );
      },
    );
  });

  group('CatalogAdminService helpers', () {
    test('category ids are clean and unique', () {
      expect(
        CatalogAdminService.uniqueSlug('Kan-B Doors 2024!', {}),
        'kan_b_doors_2024',
      );
      expect(CatalogAdminService.uniqueSlug('Doors', {'doors'}), 'doors_2');
      expect(
        CatalogAdminService.uniqueSlug('Doors', {'doors', 'doors_2'}),
        'doors_3',
      );
      expect(CatalogAdminService.uniqueSlug('लैमिनेट', {}), 'category');
    });

    test('download file names drop unsafe characters', () {
      expect(
        CatalogAdminService.safeFileName('Kan-B / Doors: "2024"'),
        'Kan-B Doors 2024',
      );
      expect(CatalogAdminService.safeFileName('???'), 'catalog');
    });

    test('only real PDFs up to 25 MB are accepted', () {
      final pdf = Uint8List.fromList('%PDF-1.7 rest'.codeUnits);
      expect(() => CatalogAdminService.validatePdf(pdf), returnsNormally);
      expect(
        () => CatalogAdminService.validatePdf(
          Uint8List.fromList('<html>'.codeUnits),
        ),
        throwsA(isA<CatalogNotPdf>()),
      );
      final big = Uint8List(kMaxCatalogPdfBytes + 1)
        ..setAll(0, '%PDF'.codeUnits);
      expect(
        () => CatalogAdminService.validatePdf(big),
        throwsA(isA<CatalogPdfTooLarge>()),
      );
    });
  });

  group('CatalogAdminService categories', () {
    late FakeFirebaseFirestore db;
    late CatalogAdminService admin;

    setUp(() {
      db = FakeFirebaseFirestore();
      admin = CatalogAdminService(db: db);
    });

    test('new categories go to the end and start empty', () async {
      final a = await admin.saveCategory(name: 'Laminates');
      final b = await admin.saveCategory(name: 'Doors');
      final docA = (await db.doc('catalog_categories/$a').get()).data()!;
      final docB = (await db.doc('catalog_categories/$b').get()).data()!;
      expect(a, 'laminates');
      expect(docA['sortOrder'], 1);
      expect(docB['sortOrder'], 2);
      expect(docB['catalogCount'], 0);
    });

    test('a category with catalogs cannot be deleted', () async {
      final id = await admin.saveCategory(name: 'Doors');
      await db.collection('catalogs').doc('k').set({
        'categoryId': id,
        'title': 'Kan-B',
      });
      await expectLater(
        admin.deleteCategory(id),
        throwsA(isA<CatalogCategoryNotEmpty>()),
      );
      await db.doc('catalogs/k').delete();
      await admin.deleteCategory(id);
      expect((await db.doc('catalog_categories/$id').get()).exists, isFalse);
    });

    test('hiding a catalog updates the member count', () async {
      final id = await admin.saveCategory(name: 'Doors');
      await db.collection('catalogs').doc('k').set({
        'categoryId': id,
        'title': 'Kan-B',
        'pdfUrl': 'https://x/k.pdf',
        'coverUrl': 'https://x/k.jpg',
        'active': true,
      });
      final c = Catalog.fromDoc(await db.doc('catalogs/k').get());
      await admin.setCatalogActive(c, false);
      var cat = (await db.doc('catalog_categories/$id').get()).data()!;
      expect(cat['catalogCount'], 0);
      await admin.setCatalogActive(c, true);
      cat = (await db.doc('catalog_categories/$id').get()).data()!;
      expect(cat['catalogCount'], 1);
      expect(cat['coverUrl'], 'https://x/k.jpg');
    });
  });
}
