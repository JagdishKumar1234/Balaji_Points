import 'dart:io';

import 'package:balaji_points/core/logger.dart';
import 'package:balaji_points/services/telemetry/telemetry.dart';
import 'package:flutter_test/flutter_test.dart';

class _Recorder implements TelemetrySink {
  final events = <String, Map<String, Object>>{};
  final screens = <String>[];
  final userIds = <String?>[];
  final properties = <String, String?>{};
  final errors = <({String error, String? reason, bool fatal})>[];
  final crumbs = <String>[];

  @override
  Future<void> logEvent(String name, Map<String, Object> parameters) async =>
      events[name] = parameters;
  @override
  Future<void> logScreen(String screenName) async => screens.add(screenName);
  @override
  Future<void> setUserId(String? id) async => userIds.add(id);
  @override
  Future<void> setUserProperty(String name, String? value) async =>
      properties[name] = value;
  @override
  Future<void> recordError(
    Object error,
    StackTrace? stack, {
    String? reason,
    bool fatal = false,
  }) async => errors.add((error: '$error', reason: reason, fatal: fatal));
  @override
  Future<void> breadcrumb(String message) async => crumbs.add(message);
  @override
  Future<void> setCustomKey(String key, String value) async {}
}

void main() {
  late _Recorder sink;
  setUp(() {
    sink = _Recorder();
    Telemetry.use(sink);
  });
  tearDown(() {
    Telemetry.reset();
    AppLogger.errorReporter = null;
    AppLogger.breadcrumbs = null;
  });

  group('nothing personal leaves the phone', () {
    test('phone numbers and emails are removed', () {
      expect(
        Telemetry.redact('Login 9758812345 · +91 9758812345 · a.b@x.com'),
        'Login [phone] · [phone] · [email]',
      );
    });

    test('ordinary numbers are kept', () {
      expect(
        Telemetry.redact('Approved bill of 125000 rupees'),
        'Approved bill of 125000 rupees',
      );
    });

    test('users are known only by a one-way hash', () {
      Telemetry.identify(userId: '9758812345', role: 'carpenter');
      final id = sink.userIds.single!;
      expect(id, isNot(contains('9758812345')));
      expect(id, hasLength(20));
      expect(Telemetry.pseudonymousId('9758812345'), id, reason: 'stable');
      expect(sink.properties['role'], 'carpenter');
    });

    test('event text is cleaned too', () {
      Telemetry.event('test_event', {'note': 'call 9758812345'});
      expect(sink.events['test_event']!['note'], 'call [phone]');
    });

    test('errors and breadcrumbs are cleaned', () {
      Telemetry.recordError(
        Exception('no user 9758812345'),
        StackTrace.current,
        reason: 'lookup for a.b@x.com',
      );
      Telemetry.breadcrumb('NAV /pin-login?phone=9758812345');
      expect(sink.errors.single.error, isNot(contains('9758812345')));
      expect(sink.errors.single.reason, 'lookup for [email]');
      expect(sink.crumbs.single, 'NAV /pin-login?phone=[phone]');
    });

    test('logout forgets the user', () {
      Telemetry.identify(userId: 'abc', role: 'admin', branchId: 'erode_main');
      Telemetry.logout();
      expect(sink.events, contains('logout'));
      expect(sink.userIds.last, isNull);
      expect(sink.properties['role'], isNull);
      expect(sink.properties['branch_id'], isNull);
    });
  });

  group('Analytics rules', () {
    test('invalid names are rejected', () {
      expect(Telemetry.isValidName('bill_submitted'), isTrue);
      expect(Telemetry.isValidName('1bad'), isFalse);
      expect(Telemetry.isValidName('has space'), isFalse);
      expect(Telemetry.isValidName('firebase_x'), isFalse);
      expect(Telemetry.isValidName('a' * 41), isFalse);
    });

    test('parameters: numbers kept, flags as 0/1, long text shortened', () {
      final cleaned = Telemetry.cleanParameters({
        'amount': 2500.5,
        'forced': true,
        'note': 'x' * 150,
        'bad key': 'dropped',
      });
      expect(cleaned['amount'], 2500.5);
      expect(cleaned['forced'], 1);
      expect((cleaned['note'] as String).length, 100);
      expect(cleaned.containsKey('bad key'), isFalse);
    });

    test('screen names come from route patterns, never real ids', () {
      expect(Telemetry.screenNameFor('/'), 'home');
      expect(Telemetry.screenNameFor('/add-bill'), 'add_bill');
      expect(
        Telemetry.screenNameFor('/admin/carpenter-profile/:carpenterId'),
        'admin_carpenter_profile',
      );
    });

    test('the same screen is not logged twice in a row', () {
      Telemetry.screen('/wallet');
      Telemetry.screen('/wallet');
      Telemetry.screen('/');
      expect(sink.screens, ['wallet', 'home']);
    });

    test('key events carry their details', () {
      Telemetry.login(method: 'pin');
      Telemetry.billSubmitted(amount: 1200, byAdmin: false);
      Telemetry.updatePromptShown(forced: true, to: '1.1.1');
      expect(sink.events['login'], {'method': 'pin'});
      expect(sink.events['bill_submitted'], {
        'amount': 1200,
        'submitted_by': 'member',
      });
      expect(sink.events['update_prompt_shown'], {'forced': 1, 'to': '1.1.1'});
    });
  });

  group('crash reporting', () {
    test('logged errors reach Crashlytics as non-fatal', () {
      AppLogger.errorReporter = (message, error, stack) =>
          Telemetry.recordError(error ?? message, stack, reason: message);
      AppLogger.error('Bill upload failed', StateError('timeout'));
      expect(sink.errors.single.reason, 'Bill upload failed');
      expect(sink.errors.single.fatal, isFalse);
    });

    test('a failing sink never breaks the app', () {
      Telemetry.use(_Throwing());
      expect(() => Telemetry.login(method: 'pin'), returnsNormally);
      expect(() => Telemetry.screen('/'), returnsNormally);
    });
  });

  group('wired into the app', () {
    String read(String path) => File(path).readAsStringSync();

    test('startup installs crash handlers and starts telemetry', () {
      final main = read('lib/main.dart');
      expect(main, contains('await _startTelemetry();'));
      expect(main, contains('FlutterError.onError'));
      expect(main, contains('PlatformDispatcher.instance.onError'));
    });

    test('debug builds send nothing unless asked', () {
      final source = read('lib/services/telemetry/telemetry.dart');
      expect(source, contains("bool.fromEnvironment('TELEMETRY_IN_DEBUG')"));
      expect(source, contains('!kDebugMode || _sendInDebug'));
    });

    test('every login path and logout is tracked', () {
      final auth = read('lib/providers/auth_provider.dart');
      expect(auth, contains("Telemetry.login(method: 'pin')"));
      expect(auth, contains("loginMethod: 'email'"));
      expect(auth, contains("loginMethod: 'google'"));
      expect(auth, contains("Telemetry.signUp(method: 'email')"));
      expect(auth, contains("Telemetry.signUp(method: 'google')"));
      // Sign-in paths only: a new sign-up is not signed in until the
      // branch admin approves it.
      expect('Telemetry.identify('.allMatches(auth), hasLength(3));
      expect(
        read('lib/services/auth/session_service.dart'),
        contains('Telemetry.logout();'),
      );
    });

    test('bill actions are tracked', () {
      final bills = read('lib/services/platform/bill_service.dart');
      for (final call in [
        'byAdmin: false',
        'byAdmin: true',
        'approved: true',
        'approved: false',
        'Telemetry.billWithdrawn()',
      ]) {
        expect(bills, contains(call), reason: call);
      }
    });

    test('screens are tracked from route patterns', () {
      expect(
        read('lib/config/routes.dart'),
        contains('currentConfiguration.fullPath'),
      );
    });

    test('Android uploads R8 mappings for readable crashes', () {
      expect(
        read('android/app/build.gradle.kts'),
        contains('id("com.google.firebase.crashlytics")'),
      );
    });
  });
}

class _Throwing implements TelemetrySink {
  @override
  dynamic noSuchMethod(Invocation invocation) => throw StateError('down');
}
