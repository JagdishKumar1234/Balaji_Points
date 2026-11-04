import 'dart:io';

import 'package:balaji_points/providers/wallet_provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class _KnownMembers extends WalletNotifier {
  _KnownMembers(this.ids);
  final List<String> ids;

  @override
  WalletState build() =>
      WalletState(loading: false, carpenterIds: ids, idsLoaded: true);

  void switchTo(List<String> next) =>
      state = state.copyWith(carpenterIds: next);
}

Future<FakeFirebaseFirestore> _bills() async {
  final db = FakeFirebaseFirestore();
  var day = 1;
  for (final (owner, status) in [
    ('me', 'pending'),
    ('me', 'approved'),
    ('me', 'approved'),
    ('me', 'rejected'),
    ('someone-else', 'approved'),
  ]) {
    await db.collection('bills').add({
      'carpenterId': owner,
      'status': status,
      'createdAt': Timestamp.fromDate(DateTime(2026, 11, day++)),
    });
  }
  return db;
}

ProviderContainer _container(FirebaseFirestore db, List<String> ids) {
  final container = ProviderContainer(
    overrides: [
      walletFirestoreProvider.overrideWithValue(db),
      walletProvider.overrideWith(() => _KnownMembers(ids)),
    ],
  );
  addTearDown(container.dispose);
  // Providers only run while something listens, as the wallet screen does.
  container.listen(currentWalletBillsProvider, (_, __) {});
  return container;
}

String _source(String path) => File(path).readAsStringSync();

const _screens = 'lib/presentation/screens/carpenter';

void main() {
  group('wallet bills', () {
    test('only the member\'s own bills, newest first', () async {
      final container = _container(await _bills(), ['me']);
      final bills = await container.read(walletBillsProvider('me').future);
      expect(bills.docs, hasLength(4));
      final dates = [
        for (final bill in bills.docs)
          ((bill.data() as Map)['createdAt'] as Timestamp).toDate().day,
      ];
      expect(dates, [4, 3, 2, 1]);
    });

    test('filters and counts match each status', () async {
      final container = _container(await _bills(), ['me']);
      final docs = (await container.read(
        walletBillsProvider('me').future,
      )).docs;
      expect(billsWithStatus(docs, 'all'), hasLength(4));
      expect(billsWithStatus(docs, 'pending'), hasLength(1));
      expect(billsWithStatus(docs, 'approved'), hasLength(2));
      expect(billsWithStatus(docs, 'rejected'), hasLength(1));
    });

    test('a new bill arrives without any reload', () async {
      final db = await _bills();
      final container = _container(db, ['me']);
      await container.read(walletBillsProvider('me').future);

      await db.collection('bills').add({
        'carpenterId': 'me',
        'status': 'pending',
        'createdAt': Timestamp.fromDate(DateTime(2026, 11, 20)),
      });
      await pumpEventQueue();

      final bills = container.read(currentWalletBillsProvider).asData!.value;
      expect(bills.docs, hasLength(5));
    });

    test('leaving the wallet keeps the data ready for coming back', () async {
      final db = await _bills();
      final container = ProviderContainer(
        overrides: [
          walletFirestoreProvider.overrideWithValue(db),
          walletProvider.overrideWith(() => _KnownMembers(['me'])),
        ],
      );
      addTearDown(container.dispose);
      final onWallet = container.listen(currentWalletBillsProvider, (_, __) {});
      await container.read(walletBillsProvider('me').future);
      onWallet.close();
      await pumpEventQueue();

      // Back on the wallet: no loading state at all.
      final back = container.listen(currentWalletBillsProvider, (_, __) {});
      expect(back.read().asData?.value.docs, hasLength(4));
    });

    test(
      'a different member never sees the previous member\'s bills',
      () async {
        final db = await _bills();
        final container = _container(db, ['me']);
        await container.read(walletBillsProvider('me').future);

        (container.read(walletProvider.notifier) as _KnownMembers).switchTo([
          'someone-else',
        ]);

        // The screen reads asData: nothing of the old list, even for one frame.
        expect(container.read(currentWalletBillsProvider).asData, isNull);
        final next = await container.read(
          walletBillsProvider('someone-else').future,
        );
        expect(next.docs, hasLength(1));
        expect((next.docs.single.data() as Map)['carpenterId'], 'someone-else');
      },
    );

    test('logout resets every member\'s kept list', () async {
      final container = _container(await _bills(), ['me']);
      await container.read(walletBillsProvider('me').future);
      container.invalidate(walletBillsProvider);
      await pumpEventQueue();
      expect(
        (await container.read(walletBillsProvider('me').future)).docs,
        hasLength(4),
      );
    });

    test('with no member yet, nothing is requested or shown', () async {
      final container = _container(await _bills(), []);
      final state = container.read(currentWalletBillsProvider);
      expect(state.isLoading, isTrue);
      expect(state.asData, isNull);
    });
  });

  group('no loader over data that is already on screen', () {
    test('home refresh keeps its cards', () {
      final source = _source('lib/providers/home_provider.dart');
      expect(source, isNot(contains('loading: true')));
      expect(source, isNot(contains('offersLoading: true')));
      expect(source, isNot(contains('greetingLoading: true')));
      expect(source, isNot(contains('rankingsLoading: true')));
    });

    test('home starts loading only after it has finished building', () {
      final source = _source('lib/providers/home_provider.dart');
      final build = source.substring(
        source.indexOf('HomeState build() {'),
        source.indexOf('// ── Public API'),
      );
      // Calling _load() directly reads state too early, and home sticks on its
      // loader with no visible error.
      expect(build, contains('Future.microtask(_load)'));
      expect(build, isNot(contains('    _load();')));
    });

    test('a failed load can never leave home on its loader', () {
      final source = _source('lib/providers/home_provider.dart');
      final load = source.substring(
        source.indexOf('Future<void> _load() async {'),
        source.indexOf('Future<void> _seedFromSession()'),
      );
      expect(load, contains('finally'));
      expect(load, contains('loading: false'));
      expect(load, contains('rankingsLoading: false'));
    });

    test('the points card does not wait for the rankings', () {
      final source = _source('lib/providers/home_provider.dart');
      final loading = source.indexOf(
        'state = state.copyWith(loading: false);\n    }\n    await _refreshRankings();',
      );
      expect(loading, greaterThan(0));
    });

    test('points refresh keeps the current points', () {
      final source = _source('lib/services/user/user_points_sync_service.dart');
      expect(source, isNot(contains('copyWith(loaded: false)')));
    });

    test('splash does not wait for the points', () {
      expect(
        _source('lib/presentation/screens/common/splash/splash_page.dart'),
        contains('unawaited(UserPointsSyncService().syncNow(force: true));'),
      );
    });

    test('wallet uses the one kept list, not a query per widget', () {
      final source = _source('$_screens/wallet/wallet_page.dart');
      final active = source.substring(
        0,
        source.indexOf('Old Bill History Table (Deprecated)'),
      );
      expect(active, isNot(contains('FirebaseFirestore.instance')));
      expect(active, contains('ref.watch(currentWalletBillsProvider)'));
      expect(active, isNot(contains('AppAnimations.stagger')));
    });

    test('logout closes the kept bill list on both logout paths', () {
      for (final page in ['home/home_page', 'profile/profile_page']) {
        expect(
          _source('$_screens/$page.dart'),
          contains('ref.invalidate(walletBillsProvider);'),
          reason: page,
        );
      }
    });

    test('profile opens from what the app already has', () {
      final source = _source('$_screens/profile/profile_page.dart');
      expect(source, contains('ref.read(homeProvider).userData'));
      expect(source, contains('const Center(child: AppLoader())'));
    });

    test('add bill reuses the known celebration state', () {
      final source = _source('$_screens/bills/add_bill_page.dart');
      expect(
        source,
        contains('ref\n        .read(branchCelebrationEnabledProvider)'),
      );
      expect(source, isNot(contains('CircularProgressIndicator')));
    });

    test('notifications only reuse a list for the same logged-in user', () {
      final source = _source('$_screens/notifications/notifications_page.dart');
      expect(source, contains('_savedKey == _listKey ? _savedList : null'));
      expect(source, isNot(contains('CircularProgressIndicator')));
    });
  });
}
