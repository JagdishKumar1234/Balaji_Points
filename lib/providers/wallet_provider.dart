import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:balaji_points/core/logger.dart';
import 'package:balaji_points/services/auth/session_service.dart';

// ---------------------------------------------------------------------------
// State
// ---------------------------------------------------------------------------

class WalletState {
  final bool loading;
  final String? error;

  // Carpenter query IDs (userId + phone, for Firestore whereIn)
  final List<String> carpenterIds;
  final bool idsLoaded;

  // Bill stats (populated by Firestore streams on the screen)
  final int pendingCount;
  final int approvedCount;

  const WalletState({
    this.loading = true,
    this.error,
    this.carpenterIds = const [],
    this.idsLoaded = false,
    this.pendingCount = 0,
    this.approvedCount = 0,
  });

  WalletState copyWith({
    bool? loading,
    String? error,
    List<String>? carpenterIds,
    bool? idsLoaded,
    int? pendingCount,
    int? approvedCount,
  }) => WalletState(
    loading: loading ?? this.loading,
    error: error ?? this.error,
    carpenterIds: carpenterIds ?? this.carpenterIds,
    idsLoaded: idsLoaded ?? this.idsLoaded,
    pendingCount: pendingCount ?? this.pendingCount,
    approvedCount: approvedCount ?? this.approvedCount,
  );
}

// ---------------------------------------------------------------------------
// Notifier
// ---------------------------------------------------------------------------

class WalletNotifier extends Notifier<WalletState> {
  final _session = SessionService();

  @override
  WalletState build() {
    _load();
    return const WalletState();
  }

  Future<void> refresh() async {
    await _loadCarpenterIds();
    state = state.copyWith(loading: false);
  }

  void updatePendingCount(int n) => state = state.copyWith(pendingCount: n);
  void updateApprovedCount(int n) => state = state.copyWith(approvedCount: n);

  Future<void> _load() async {
    try {
      await _loadCarpenterIds();
      state = state.copyWith(loading: false);
    } catch (e, st) {
      AppLogger.error('WalletNotifier load failed', e, st);
      state = state.copyWith(loading: false, error: e.toString());
    }
  }

  Future<void> _loadCarpenterIds() async {
    try {
      final ids = await _session.getCarpenterQueryIds();
      state = state.copyWith(carpenterIds: ids, idsLoaded: true);
    } catch (e) {
      AppLogger.error('WalletNotifier ids load failed', e);
      state = state.copyWith(idsLoaded: true);
    }
  }
}

// ---------------------------------------------------------------------------
// Providers
// ---------------------------------------------------------------------------

final walletProvider = NotifierProvider<WalletNotifier, WalletState>(
  WalletNotifier.new,
);

final walletFirestoreProvider = Provider<FirebaseFirestore>(
  (ref) => FirebaseFirestore.instance,
);

/// One member's bills, live, kept for the whole session: coming back to the
/// wallet shows them at once, and new data arrives silently.
///
/// Separate per member (the key is their ids), so nobody can ever see a list
/// left over from the previous login. Must be invalidated on logout.
final walletBillsProvider = StreamProvider.family<QuerySnapshot, String>((
  ref,
  key,
) {
  return ref
      .watch(walletFirestoreProvider)
      .collection('bills')
      .where('carpenterId', whereIn: key.split('|'))
      .orderBy('createdAt', descending: true)
      .snapshots();
});

/// The logged-in member's bills.
final currentWalletBillsProvider = Provider<AsyncValue<QuerySnapshot>>((ref) {
  final key = ref.watch(
    walletProvider.select((wallet) => wallet.carpenterIds.join('|')),
  );
  if (key.isEmpty) return const AsyncLoading();
  return ref.watch(walletBillsProvider(key));
});

/// Bills with [status], or all of them for `all`.
List<QueryDocumentSnapshot> billsWithStatus(
  List<QueryDocumentSnapshot> bills,
  String status,
) => status == 'all'
    ? bills
    : bills
          .where(
            (bill) => (bill.data() as Map<String, dynamic>)['status'] == status,
          )
          .toList();
