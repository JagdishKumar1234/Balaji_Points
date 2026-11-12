// ignore_for_file: depend_on_referenced_packages
import 'dart:io';

import 'package:balaji_points/core/models/catalog.dart';
import 'package:balaji_points/services/platform/catalog_file_cache.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

class _FakePaths extends Fake
    with MockPlatformInterfaceMixin
    implements PathProviderPlatform {
  _FakePaths(this.cache);
  final String cache;
  @override
  Future<String?> getApplicationCachePath() async => cache;
}

/// Catalog PDFs are saved in the app cache so the reader opens instantly.
void main() {
  late Directory root;
  late HttpServer server;
  final pdf = List<int>.generate(50000, (i) => i % 251)
    ..setAll(0, '%PDF'.codeUnits);

  setUp(() async {
    root = await Directory.systemTemp.createTemp('catalog_cache_test');
    PathProviderPlatform.instance = _FakePaths(root.path);
    CatalogFileCache.instance.resetForTest();
    server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    server.listen((req) {
      req.response
        ..headers.contentType = ContentType('application', 'pdf')
        ..add(pdf);
      req.response.close();
    });
  });

  tearDown(() async {
    await server.close(force: true);
    if (await root.exists()) await root.delete(recursive: true);
  });

  Catalog catalog(String id, {int version = 1}) => Catalog(
    id: id,
    categoryId: 'doors',
    title: id,
    pdfUrl: 'http://127.0.0.1:${server.port}/$id.pdf',
    sizeBytes: pdf.length,
    version: version,
  );

  test('downloads once, then opens from the saved file', () async {
    final cache = CatalogFileCache.instance;
    await cache.init();
    final f = await cache.ensure(catalog('a'));
    expect(f, isNotNull);
    expect(await f!.length(), pdf.length);
    expect(cache.peek(catalog('a'))?.path, f.path);
  });

  test('still saves after the cache folder was cleared mid-session', () async {
    final cache = CatalogFileCache.instance;
    await cache.init();
    // Android (or a reinstall) wipes the cache while the app runs.
    await Directory('${root.path}/catalogs').delete(recursive: true);
    final f = await cache.ensure(catalog('b'));
    expect(f, isNotNull);
    expect(await f!.length(), pdf.length);
  });

  test(
    'a replaced PDF (new version) is fetched and the old one removed',
    () async {
      final cache = CatalogFileCache.instance;
      await cache.preload([catalog('c')]);
      expect(cache.peek(catalog('c')), isNotNull);
      await cache.preload([catalog('c', version: 2)]);
      expect(cache.peek(catalog('c', version: 2)), isNotNull);
      expect(File('${root.path}/catalogs/c_v1.pdf').existsSync(), isFalse);
    },
  );
}
