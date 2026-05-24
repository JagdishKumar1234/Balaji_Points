import 'package:flutter/foundation.dart';

/// Debug-only logging. Only [startup], [auth], [nav], [data], [update], [warning],
/// and [error] print by default. Use [verbose] for service-level [info]/[debug].
class AppLogger {
  AppLogger._();

  static const String _app = 'BalajiPoints';

  static bool get _enabled => kDebugMode;

  /// Set true to show [info] / [debug] from services (FCM, notifications, etc.).
  static bool verbose = false;

  static void startup(String message) => _emit('STARTUP', message);

  static void auth(String message) => _emit('AUTH', message);

  static void nav(String message) => _emit('NAV', message);

  static void data(String message) => _emit('DATA', message);

  static void update(String message) => _emit('UPDATE', message);

  /// No output unless [verbose] is true (keeps terminal clean).
  static void info(String message) {
    if (verbose) _emit('INFO', message);
  }

  static void warning(String message) => _emit('WARN', message);

  static void debug(String message) {
    if (verbose) _emit('DEBUG', message);
  }

  static void error(String message, [Object? error, StackTrace? stackTrace]) {
    _emit('ERROR', message);
    if (!_enabled) return;
    if (error != null) debugPrint('       ↳ $error');
    if (stackTrace != null && verbose) debugPrint('       ↳ $stackTrace');
  }

  /// One-line launch banner (no extra blank lines).
  static void appLaunchBanner({required String version, required int build}) {
    if (!_enabled) return;
    debugPrint('[$_app] v$version ($build)');
  }

  /// Optional section header — off by default.
  static void section(String title) {
    if (!_enabled || !verbose) return;
    debugPrint('── $title ──');
  }

  static void _emit(String category, String message) {
    if (!_enabled) return;
    debugPrint('[$_app][$category] $message');
  }
}
