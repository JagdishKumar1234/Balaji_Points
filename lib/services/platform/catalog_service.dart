import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/logger.dart';
import '../../core/models/catalog.dart';

/// Reads the product catalog library. Catalogs change about once a year, so
/// the screens must open instantly:
///
/// * Cache first: the copy Firestore already has on the phone is shown at
///   once, then the server copy replaces it quietly (no spinner).
/// * The whole `catalogs` collection is read once (it is small: tens of
///   records), so opening a category filters in memory with no wait.
/// * Home prefetches both lists in the background (see [prefetchCatalogs]),
///   so even the first open after install is usually already loaded.
///
/// No PDF is ever loaded here; only the small records. A PDF is fetched only
/// when the member taps View, and is not kept by the app.
class CatalogService {
  CatalogService([FirebaseFirestore? db])
    : _db = db ?? FirebaseFirestore.instance;

  final FirebaseFirestore _db;

  CollectionReference<Map<String, dynamic>> get _categories =>
      _db.collection('catalog_categories');
  CollectionReference<Map<String, dynamic>> get _catalogs =>
      _db.collection('catalogs');

  /// Cached categories first (if the phone has any), then the server copy.
  Stream<List<CatalogCategory>> watchCategories() =>
      _cacheThenServer(_categories, _toCategories);

  /// Cached catalogs first (if any), then the server copy.
  Stream<List<Catalog>> watchAllCatalogs() =>
      _cacheThenServer(_catalogs, _toCatalogs);

  Future<List<CatalogCategory>> fetchCategories() async => _toCategories(
    await _categories.get(const GetOptions(source: Source.server)),
  );

  Future<List<Catalog>> fetchAllCatalogs() async =>
      _toCatalogs(await _catalogs.get(const GetOptions(source: Source.server)));

  Stream<List<T>> _cacheThenServer<T>(
    CollectionReference<Map<String, dynamic>> col,
    List<T> Function(QuerySnapshot<Map<String, dynamic>>) map,
  ) async* {
    var shownCache = false;
    try {
      final cached = await col.get(const GetOptions(source: Source.cache));
      if (cached.docs.isNotEmpty) {
        shownCache = true;
        yield map(cached);
      }
    } catch (_) {
      // Nothing cached yet (first open, or web without persistence).
    }
    try {
      yield map(await col.get());
    } catch (e) {
      // Offline with a cached copy on screen: keep showing it.
      if (!shownCache) rethrow;
      AppLogger.warning('Catalog refresh failed, showing cached copy: $e');
    }
  }

  static List<CatalogCategory> _toCategories(
    QuerySnapshot<Map<String, dynamic>> snap,
  ) =>
      snap.docs
          .map(CatalogCategory.fromDoc)
          .where((c) => c.active && c.catalogCount > 0)
          .toList()
        ..sort(_byOrderThenName((c) => c.sortOrder, (c) => c.name));

  static List<Catalog> _toCatalogs(QuerySnapshot<Map<String, dynamic>> snap) =>
      snap.docs
          .map(Catalog.fromDoc)
          .where((c) => c.active && c.pdfUrl.isNotEmpty)
          .toList()
        ..sort(_byOrderThenName((c) => c.sortOrder, (c) => c.title));

  static int Function(T, T) _byOrderThenName<T>(
    int Function(T) order,
    String Function(T) name,
  ) => (a, b) {
    final o = order(a).compareTo(order(b));
    return o != 0 ? o : name(a).toLowerCase().compareTo(name(b).toLowerCase());
  };
}

final catalogServiceProvider = Provider<CatalogService>(
  (ref) => CatalogService(),
);

/// Kept for the app session. [CatalogCategoriesNotifier.refresh] is for
/// pull-to-refresh: it keeps the list on screen while the server answers.
final catalogCategoriesProvider =
    StreamNotifierProvider<CatalogCategoriesNotifier, List<CatalogCategory>>(
      CatalogCategoriesNotifier.new,
    );

class CatalogCategoriesNotifier extends StreamNotifier<List<CatalogCategory>> {
  @override
  Stream<List<CatalogCategory>> build() =>
      ref.watch(catalogServiceProvider).watchCategories();

  Future<void> refresh() async {
    try {
      state = AsyncData(
        await ref.read(catalogServiceProvider).fetchCategories(),
      );
    } catch (e, st) {
      if (!state.hasValue) state = AsyncError(e, st);
    }
  }
}

/// Every active catalog, read once for the app session.
final allCatalogsProvider =
    StreamNotifierProvider<AllCatalogsNotifier, List<Catalog>>(
      AllCatalogsNotifier.new,
    );

class AllCatalogsNotifier extends StreamNotifier<List<Catalog>> {
  @override
  Stream<List<Catalog>> build() =>
      ref.watch(catalogServiceProvider).watchAllCatalogs();

  Future<void> refresh() async {
    try {
      state = AsyncData(
        await ref.read(catalogServiceProvider).fetchAllCatalogs(),
      );
    } catch (e, st) {
      if (!state.hasValue) state = AsyncError(e, st);
    }
  }
}

/// Catalogs in one category, filtered in memory from [allCatalogsProvider]
/// (synchronous, so the screen never shows a spinner once loaded).
final catalogsInCategoryProvider =
    Provider.family<AsyncValue<List<Catalog>>, String>(
      (ref, categoryId) => ref
          .watch(allCatalogsProvider)
          .whenData(
            (all) => all.where((c) => c.categoryId == categoryId).toList(),
          ),
    );

/// Starts loading both lists in the background (called from Home), so the
/// Catalogs screen is ready before the member taps it. Riverpod 3 pauses a
/// provider nobody listens to, so Home holds these listeners for its life.
void prefetchCatalogs(WidgetRef ref) {
  ref.listenManual(catalogCategoriesProvider, (_, __) {});
  ref.listenManual(allCatalogsProvider, (_, __) {});
}
