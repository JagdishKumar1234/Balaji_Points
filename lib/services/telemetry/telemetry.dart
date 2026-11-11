import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';

/// Where analytics and crash data go. Swapped for a fake in tests.
abstract class TelemetrySink {
  Future<void> logEvent(String name, Map<String, Object> parameters);
  Future<void> logScreen(String screenName);
  Future<void> setUserId(String? id);
  Future<void> setUserProperty(String name, String? value);
  Future<void> recordError(
    Object error,
    StackTrace? stack, {
    String? reason,
    bool fatal = false,
  });
  Future<void> breadcrumb(String message);
  Future<void> setCustomKey(String key, String value);
}

class _NoTelemetry implements TelemetrySink {
  const _NoTelemetry();
  @override
  Future<void> logEvent(String name, Map<String, Object> parameters) async {}
  @override
  Future<void> logScreen(String screenName) async {}
  @override
  Future<void> setUserId(String? id) async {}
  @override
  Future<void> setUserProperty(String name, String? value) async {}
  @override
  Future<void> recordError(
    Object error,
    StackTrace? stack, {
    String? reason,
    bool fatal = false,
  }) async {}
  @override
  Future<void> breadcrumb(String message) async {}
  @override
  Future<void> setCustomKey(String key, String value) async {}
}

/// Firebase Analytics + Crashlytics. Crashlytics does not run on the web.
class FirebaseTelemetrySink implements TelemetrySink {
  FirebaseTelemetrySink()
    : _analytics = FirebaseAnalytics.instance,
      _crashlytics = kIsWeb ? null : FirebaseCrashlytics.instance;

  final FirebaseAnalytics _analytics;
  final FirebaseCrashlytics? _crashlytics;

  /// Debug builds send nothing, so testing never pollutes live reports.
  /// Run with `--dart-define=TELEMETRY_IN_DEBUG=true` to check DebugView.
  static const _sendInDebug = bool.fromEnvironment('TELEMETRY_IN_DEBUG');

  static bool get enabled => !kDebugMode || _sendInDebug;

  Future<void> start() async {
    await _analytics.setAnalyticsCollectionEnabled(enabled);
    await _crashlytics?.setCrashlyticsCollectionEnabled(enabled);
  }

  @override
  Future<void> logEvent(String name, Map<String, Object> parameters) =>
      _analytics.logEvent(name: name, parameters: parameters);

  @override
  Future<void> logScreen(String screenName) =>
      _analytics.logScreenView(screenName: screenName, screenClass: screenName);

  @override
  Future<void> setUserId(String? id) async {
    await _analytics.setUserId(id: id);
    await _crashlytics?.setUserIdentifier(id ?? '');
  }

  @override
  Future<void> setUserProperty(String name, String? value) async {
    await _analytics.setUserProperty(name: name, value: value);
    await _crashlytics?.setCustomKey(name, value ?? '');
  }

  @override
  Future<void> recordError(
    Object error,
    StackTrace? stack, {
    String? reason,
    bool fatal = false,
  }) async {
    await _crashlytics?.recordError(error, stack, reason: reason, fatal: fatal);
  }

  @override
  Future<void> breadcrumb(String message) async => _crashlytics?.log(message);

  @override
  Future<void> setCustomKey(String key, String value) async =>
      _crashlytics?.setCustomKey(key, value);
}

/// An error whose text has had personal details removed before it is sent.
class RedactedError {
  RedactedError(Object error) : message = Telemetry.redact('$error');
  final String message;
  @override
  String toString() => message;
}

/// The app's single entry point for analytics and crash reporting.
///
/// Nothing personal leaves the phone: phone numbers and emails are removed
/// from every text, and users are identified only by a one-way hash.
class Telemetry {
  Telemetry._();

  static TelemetrySink _sink = const _NoTelemetry();
  static String? _lastScreen;

  static void use(TelemetrySink sink) {
    _sink = sink;
    _lastScreen = null;
  }

  /// Back to sending nothing (tests).
  static void reset() => use(const _NoTelemetry());

  // ── Events ────────────────────────────────────────────────────────────────

  static void login({required String method}) =>
      event('login', {'method': method});

  static void signUp({required String method}) =>
      event('sign_up', {'method': method});

  static void billSubmitted({required double amount, required bool byAdmin}) =>
      event('bill_submitted', {
        'amount': amount,
        'submitted_by': byAdmin ? 'admin' : 'member',
      });

  static void billReviewed({required bool approved}) =>
      event(approved ? 'bill_approved' : 'bill_rejected', const {});

  static void billWithdrawn() => event('bill_withdrawn', const {});

  static void dailySpin({required int points}) =>
      event('daily_spin', {'points': points});

  static void imageOpened() => event('image_opened', const {});

  static void celebrationPopupShown() =>
      event('celebration_popup_shown', const {});

  static void updatePromptShown({required bool forced, required String to}) =>
      event('update_prompt_shown', {'forced': forced ? 1 : 0, 'to': to});

  static void settingChanged(String setting, String value) =>
      event('setting_changed', {'setting': setting, 'value': value});

  /// Logs any event, dropping anything Analytics would reject.
  static void event(String name, Map<String, Object> parameters) {
    if (!isValidName(name)) {
      assert(false, 'Invalid analytics event name: $name');
      return;
    }
    _guard(() => _sink.logEvent(name, cleanParameters(parameters)));
  }

  // ── Screens and user ──────────────────────────────────────────────────────

  /// Records a screen view for a route pattern, once per change.
  static void screen(String routePattern) {
    final name = screenNameFor(routePattern);
    if (name == _lastScreen) return;
    _lastScreen = name;
    _guard(() => _sink.logScreen(name));
    _guard(() => _sink.setCustomKey('screen', name));
  }

  /// Tags reports with who is using the app, without saying who they are.
  static void identify({
    required String userId,
    required String role,
    String? branchId,
  }) {
    _guard(() => _sink.setUserId(pseudonymousId(userId)));
    _guard(() => _sink.setUserProperty('role', role));
    _guard(() => _sink.setUserProperty('branch_id', branchId));
  }

  static void language(String code) =>
      _guard(() => _sink.setUserProperty('app_language', code));

  static void logout() {
    event('logout', const {});
    _guard(() => _sink.setUserId(null));
    _guard(() => _sink.setUserProperty('role', null));
    _guard(() => _sink.setUserProperty('branch_id', null));
  }

  // ── Crashes ───────────────────────────────────────────────────────────────

  static void recordError(
    Object error,
    StackTrace? stack, {
    String? reason,
    bool fatal = false,
  }) {
    _guard(
      () => _sink.recordError(
        RedactedError(error),
        stack,
        reason: reason == null ? null : redact(reason),
        fatal: fatal,
      ),
    );
  }

  static void breadcrumb(String message) =>
      _guard(() => _sink.breadcrumb(redact(message)));

  // ── Rules ─────────────────────────────────────────────────────────────────

  static final _phone = RegExp(r'(?<!\d)(?:\+?91[\s-]?)?\d{10}(?!\d)');
  static final _email = RegExp(r'[\w.+-]+@[\w-]+\.[\w.-]+');

  /// Removes phone numbers and emails.
  static String redact(String text) =>
      text.replaceAll(_email, '[email]').replaceAll(_phone, '[phone]');

  /// A stable id that cannot be turned back into the account id. Some older
  /// account ids are phone numbers, so the real id is never sent.
  static String pseudonymousId(String id) => sha256
      .convert(utf8.encode('balaji-points:$id'))
      .toString()
      .substring(0, 20);

  static final _validName = RegExp(r'^[a-zA-Z][a-zA-Z0-9_]{0,39}$');

  /// Analytics names: letters, digits and underscores, up to 40 characters,
  /// not using a reserved prefix.
  static bool isValidName(String name) =>
      _validName.hasMatch(name) &&
      !name.startsWith('firebase_') &&
      !name.startsWith('google_') &&
      !name.startsWith('ga_');

  /// Keeps valid names; text is redacted and shortened to 100 characters.
  static Map<String, Object> cleanParameters(Map<String, Object> parameters) {
    return {
      for (final entry in parameters.entries)
        if (isValidName(entry.key))
          entry.key: switch (entry.value) {
            final num number => number,
            final bool flag => flag ? 1 : 0,
            final Object other => _shorten(redact('$other')),
          },
    };
  }

  static String _shorten(String text) =>
      text.length <= 100 ? text : text.substring(0, 100);

  /// `/admin/carpenter-profile/:carpenterId` → `admin_carpenter_profile`.
  static String screenNameFor(String routePattern) {
    final parts = routePattern
        .split('/')
        .where((part) => part.isNotEmpty && !part.startsWith(':'))
        .map((part) => part.replaceAll('-', '_'));
    final name = parts.join('_');
    return name.isEmpty ? 'home' : name;
  }

  /// Telemetry must never break the app.
  static void _guard(Future<void> Function() send) {
    try {
      send().catchError((Object _) {});
    } catch (_) {}
  }
}
