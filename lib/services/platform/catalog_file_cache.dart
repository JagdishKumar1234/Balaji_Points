import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

import '../../core/logger.dart';
import '../../core/models/catalog.dart';

/// Keeps catalog PDFs in the app's private cache folder so the reader opens
/// them instantly, with no page-by-page network wait.
///
/// * Home preloads every catalog in the background after login, smallest
///   first, one at a time ([preload]).
/// * Each file is downloaded once per catalog version
///   (`<cache>/catalogs/{id}_v{version}.pdf`). When an admin replaces a PDF
///   the version changes, the new file is fetched and the old one deleted.
/// * The folder is private to the app (not Downloads or the gallery) and
///   Android may clear it when the phone is low on space; the reader then
///   simply downloads the file again.
/// * Web keeps streaming from Storage (no file system).
class CatalogFileCache {
  CatalogFileCache._();
  static final CatalogFileCache instance = CatalogFileCache._();

  Directory? _dir;
  final Map<String, Future<File?>> _downloads = {};
  final Map<String, ValueNotifier<int>> _received = {};
  bool _preloading = false;

  /// Tests point the cache at a fresh folder.
  @visibleForTesting
  void resetForTest() {
    _dir = null;
    _downloads.clear();
    _received.clear();
    _queued = null;
  }

  List<Catalog>? _queued;

  static String _name(Catalog c) => '${c.id}_v${c.version}.pdf';

  /// The folder, created again if Android (or a reinstall) cleared the
  /// cache while the app was running.
  Future<Directory> _folder() async {
    final dir =
        _dir ??
        Directory('${(await getApplicationCacheDirectory()).path}/catalogs');
    _dir = dir;
    if (!await dir.exists()) await dir.create(recursive: true);
    return dir;
  }

  /// Prepares the folder so [peek] can answer without waiting.
  Future<void> init() async {
    if (kIsWeb) return;
    try {
      await _folder();
    } catch (e) {
      AppLogger.warning('Catalog cache folder unavailable: $e');
    }
  }

  bool _complete(File f, Catalog c) {
    if (!f.existsSync()) return false;
    return c.sizeBytes <= 0 || f.lengthSync() == c.sizeBytes;
  }

  /// The saved file, if it is already complete. Synchronous, so the reader
  /// can open it on its first frame.
  File? peek(Catalog c) {
    final dir = _dir;
    if (kIsWeb || dir == null) return null;
    final f = File('${dir.path}/${_name(c)}');
    return _complete(f, c) ? f : null;
  }

  /// Bytes received so far for [c] while it downloads (for a progress bar).
  ValueListenable<int> progressOf(Catalog c) =>
      _received.putIfAbsent(_name(c), () => ValueNotifier(0));

  /// The saved file, downloading it first if needed. Callers asking for the
  /// same catalog share one download. Returns null when it cannot be saved.
  Future<File?> ensure(Catalog c) async {
    if (kIsWeb || c.pdfUrl.isEmpty) return null;
    final dir = await _folder();
    final f = File('${dir.path}/${_name(c)}');
    if (_complete(f, c)) return f;
    final key = _name(c);
    return _downloads.putIfAbsent(
      key,
      // Block body on purpose: `=> _downloads.remove(key)` would return this
      // very future to whenComplete, which then waits on itself forever and
      // the reader never opens the finished file.
      () => _download(c, f).whenComplete(() {
        _downloads.remove(key);
      }),
    );
  }

  Future<File?> _download(Catalog c, File target) async {
    final part = File('${target.path}.part');
    final progress = _received.putIfAbsent(_name(c), () => ValueNotifier(0))
      ..value = 0;
    final client = HttpClient()
      ..connectionTimeout = const Duration(seconds: 20);
    IOSink? sink;
    try {
      final res = await (await client.getUrl(Uri.parse(c.pdfUrl))).close();
      if (res.statusCode != HttpStatus.ok) {
        throw HttpException('HTTP ${res.statusCode}');
      }
      // The cache can be cleared at any moment; make sure the folder is
      // there right before writing, and create the file up front so an
      // open error is caught here instead of escaping as an unhandled one.
      await part.create(recursive: true);
      sink = part.openWrite();
      var got = 0;
      await for (final chunk in res.timeout(const Duration(seconds: 30))) {
        sink.add(chunk);
        got += chunk.length;
        progress.value = got;
      }
      await sink.close();
      sink = null;
      if (c.sizeBytes > 0 && got != c.sizeBytes) {
        throw StateError('Got $got of ${c.sizeBytes} bytes');
      }
      return await part.rename(target.path);
    } catch (e) {
      AppLogger.warning('Catalog download failed (${c.title}): $e');
      try {
        await sink?.close();
      } catch (_) {}
      try {
        if (await part.exists()) await part.delete();
      } catch (_) {}
      return null;
    } finally {
      client.close(force: true);
    }
  }

  /// Saves every catalog in the background, smallest first, and removes
  /// files for catalogs that were deleted or replaced. Safe to call often:
  /// a call made while one is running is queued and runs after it.
  Future<void> preload(List<Catalog> catalogs) async {
    if (kIsWeb) return;
    if (_preloading) {
      _queued = catalogs;
      return;
    }
    _preloading = true;
    try {
      var list = catalogs;
      while (true) {
        await _removeStale(list);
        final ordered = [...list]
          ..sort((a, b) => a.sizeBytes.compareTo(b.sizeBytes));
        for (final c in ordered) {
          if (_queued != null) break;
          await ensure(c);
        }
        final next = _queued;
        if (next == null) break;
        _queued = null;
        list = next;
      }
    } catch (e) {
      AppLogger.warning('Catalog preload stopped: $e');
    } finally {
      _preloading = false;
    }
  }

  Future<void> _removeStale(List<Catalog> current) async {
    final keep = current.map(_name).toSet();
    final dir = await _folder();
    await for (final e in dir.list()) {
      if (e is! File) continue;
      final name = e.uri.pathSegments.last;
      final base = name.endsWith('.part')
          ? name.substring(0, name.length - 5)
          : name;
      if (keep.contains(base) || _downloads.containsKey(base)) continue;
      try {
        await e.delete();
      } catch (_) {}
    }
  }
}
