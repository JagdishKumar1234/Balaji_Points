import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:balaji_points/core/utils/points_utils.dart';
import 'package:balaji_points/services/user/user_points_service.dart';

/// Global singleton that keeps one live points subscription for the app.
/// All screens (home/wallet/profile) listen here — never read [users.totalPoints].
class UserPointsSyncService {
  UserPointsSyncService._internal();
  static final UserPointsSyncService _instance = UserPointsSyncService._internal();
  factory UserPointsSyncService() => _instance;

  final UserPointsService _userPointsService = UserPointsService();

  final ValueNotifier<Map<String, dynamic>?> pointsData =
      ValueNotifier<Map<String, dynamic>?>(null);

  StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>? _subscription;
  String? _subscribedDocPath;
  bool _isSyncing = false;

  /// Canonical total from [user_points] (history-aware if field is stale).
  double get totalPoints {
    final data = pointsData.value;
    if (data == null) return 0;
    return PointsUtils.resolveTotalPoints(data);
  }

  String get tier => pointsData.value?['tier'] as String? ?? 'Bronze';

  String get formattedPoints => PointsUtils.formatPoints(totalPoints);

  /// Fetch latest points from Firestore (server-first), then listen for updates.
  Future<void> syncNow({bool force = false}) async {
    if (_isSyncing && !force) return;
    _isSyncing = true;
    try {
      final pointsDocRef = await _userPointsService.resolveCurrentUserPointsDocRef();
      if (pointsDocRef == null) {
        pointsData.value = null;
        return;
      }

      Map<String, dynamic>? latest;
      try {
        final serverSnap = await pointsDocRef.get(
          const GetOptions(source: Source.server),
        );
        if (serverSnap.exists) {
          latest = serverSnap.data();
        }
      } catch (_) {
        final cacheSnap = await pointsDocRef.get();
        if (cacheSnap.exists) {
          latest = cacheSnap.data();
        }
      }

      pointsData.value = latest;

      if (force ||
          _subscribedDocPath != pointsDocRef.path ||
          _subscription == null) {
        await _subscription?.cancel();
        _subscribedDocPath = pointsDocRef.path;
        _subscription = pointsDocRef.snapshots().listen((snapshot) {
          pointsData.value = snapshot.data();
        });
      }
    } finally {
      _isSyncing = false;
    }
  }

  Future<void> refresh() async {
    await _subscription?.cancel();
    _subscription = null;
    _subscribedDocPath = null;
    await syncNow(force: true);
  }

  void reset() {
    _subscription?.cancel();
    _subscription = null;
    _subscribedDocPath = null;
    pointsData.value = null;
    _isSyncing = false;
  }
}

// ---------------------------------------------------------------------------
// Riverpod — single carpenter points stream for the whole app
// ---------------------------------------------------------------------------

class CarpenterPointsState {
  final double totalPoints;
  final String tier;
  final bool loaded;

  const CarpenterPointsState({
    this.totalPoints = 0,
    this.tier = 'Bronze',
    this.loaded = false,
  });

  String get formattedPoints => PointsUtils.formatPoints(totalPoints);

  CarpenterPointsState copyWith({
    double? totalPoints,
    String? tier,
    bool? loaded,
  }) =>
      CarpenterPointsState(
        totalPoints: totalPoints ?? this.totalPoints,
        tier: tier ?? this.tier,
        loaded: loaded ?? this.loaded,
      );
}

class CarpenterPointsNotifier extends Notifier<CarpenterPointsState> {
  final _syncService = UserPointsSyncService();
  VoidCallback? _listener;

  @override
  CarpenterPointsState build() {
    ref.onDispose(_dispose);
    _attach();
    return const CarpenterPointsState();
  }

  void _dispose() {
    if (_listener != null) {
      _syncService.pointsData.removeListener(_listener!);
      _listener = null;
    }
  }

  /// Call after login / before opening carpenter home so points are fresh.
  Future<void> prepareForSession() async {
    state = const CarpenterPointsState();
    _syncService.reset();
    await _syncService.syncNow(force: true);
    _apply();
  }

  /// Block until the first server sync for this session completes.
  Future<void> ensureLoaded() async {
    if (state.loaded) return;
    await _syncService.syncNow(force: true);
    _apply();
  }

  Future<void> refresh() async {
    state = state.copyWith(loaded: false);
    await _syncService.refresh();
    _apply();
  }

  void resetForLogout() {
    _syncService.reset();
    state = const CarpenterPointsState();
  }

  void _attach() {
    if (_listener == null) {
      _listener = _apply;
      _syncService.pointsData.addListener(_listener!);
    }
    if (_syncService.pointsData.value != null) {
      _apply();
    }
    unawaited(_syncService.syncNow(force: true).then((_) => _apply()));
  }

  void _apply() {
    final data = _syncService.pointsData.value;
    if (data == null) {
      state = const CarpenterPointsState(loaded: true);
      return;
    }
    state = CarpenterPointsState(
      totalPoints: PointsUtils.resolveTotalPoints(data),
      tier: data['tier'] as String? ?? 'Bronze',
      loaded: true,
    );
  }
}

final carpenterPointsProvider =
    NotifierProvider<CarpenterPointsNotifier, CarpenterPointsState>(
  CarpenterPointsNotifier.new,
);
