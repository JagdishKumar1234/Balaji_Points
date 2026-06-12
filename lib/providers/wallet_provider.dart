import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:balaji_points/services/auth/session_service.dart';
import 'package:balaji_points/services/user/user_points_sync_service.dart';
import 'package:balaji_points/core/logger.dart';

// ---------------------------------------------------------------------------
// State
// ---------------------------------------------------------------------------

class WalletState {
  final bool loading;
  final String? error;

  // Points / tier
  final double totalPoints;
  final String tier;

  // Carpenter query IDs (userId + phone, for Firestore whereIn)
  final List<String> carpenterIds;
  final bool idsLoaded;

  // Bill stats (populated by Firestore streams on the screen)
  final int pendingCount;
  final int approvedCount;

  const WalletState({
    this.loading = true,
    this.error,
    this.totalPoints = 0.0,
    this.tier = 'Bronze',
    this.carpenterIds = const [],
    this.idsLoaded = false,
    this.pendingCount = 0,
    this.approvedCount = 0,
  });

  WalletState copyWith({
    bool? loading,
    String? error,
    double? totalPoints,
    String? tier,
    List<String>? carpenterIds,
    bool? idsLoaded,
    int? pendingCount,
    int? approvedCount,
  }) =>
      WalletState(
        loading: loading ?? this.loading,
        error: error ?? this.error,
        totalPoints: totalPoints ?? this.totalPoints,
        tier: tier ?? this.tier,
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
  final _syncService = UserPointsSyncService();
  VoidCallback? _pointsListener;

  @override
  WalletState build() {
    ref.onDispose(_dispose);
    _load();
    return const WalletState();
  }

  void _dispose() {
    if (_pointsListener != null) {
      _syncService.pointsData.removeListener(_pointsListener!);
    }
  }

  // ── Public API ──────────────────────────────────────────────────────────────

  Future<void> refresh() async {
    state = state.copyWith(loading: true);
    await _syncService.refresh();
    await _loadCarpenterIds();
    state = state.copyWith(loading: false);
  }

  void updatePendingCount(int n) => state = state.copyWith(pendingCount: n);
  void updateApprovedCount(int n) => state = state.copyWith(approvedCount: n);

  // ── Internal ────────────────────────────────────────────────────────────────

  Future<void> _load() async {
    try {
      await Future.wait([_loadCarpenterIds(), _startPointsSync()]);
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

  Future<void> _startPointsSync() async {
    // Create listener only once
    if (_pointsListener == null) {
      _pointsListener = () {
        final data = _syncService.pointsData.value;
        if (data == null) return;
        state = state.copyWith(
          totalPoints: _asDouble(data['totalPoints']),
          tier: data['tier'] as String? ?? state.tier,
        );
      };
      // Add listener only once (don't remove and re-add)
      _syncService.pointsData.addListener(_pointsListener!);
    }
    // Start the service (it handles duplicate subscriptions internally)
    await _syncService.start();
    // Call listener to sync current value
    _pointsListener?.call();
  }

  static double _asDouble(dynamic v) {
    if (v is num) return v.toDouble();
    return double.tryParse(v?.toString() ?? '') ?? 0.0;
  }
}

// ---------------------------------------------------------------------------
// Providers
// ---------------------------------------------------------------------------

final walletProvider = NotifierProvider<WalletNotifier, WalletState>(WalletNotifier.new);

/// Live stream of bills for the current carpenter IDs.
/// Re-created whenever [carpenterIds] changes (keyed by the sorted id list).
final billsStreamProvider = StreamProvider.family<QuerySnapshot, List<String>>(
  (ref, ids) {
    if (ids.isEmpty) return const Stream.empty();
    return FirebaseFirestore.instance
        .collection('bills')
        .where('carpenterId', whereIn: ids)
        .orderBy('createdAt', descending: true)
        .limit(20)
        .snapshots();
  },
);

final pendingBillsCountProvider = StreamProvider.family<int, List<String>>(
  (ref, ids) {
    if (ids.isEmpty) return Stream.value(0);
    return FirebaseFirestore.instance
        .collection('bills')
        .where('carpenterId', whereIn: ids)
        .where('status', isEqualTo: 'pending')
        .snapshots()
        .map((snap) => snap.docs.length);
  },
);

final approvedBillsCountProvider = StreamProvider.family<int, List<String>>(
  (ref, ids) {
    if (ids.isEmpty) return Stream.value(0);
    return FirebaseFirestore.instance
        .collection('bills')
        .where('carpenterId', whereIn: ids)
        .where('status', isEqualTo: 'approved')
        .snapshots()
        .map((snap) => snap.docs.length);
  },
);
