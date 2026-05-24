import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:balaji_points/services/session_service.dart';
import 'package:balaji_points/services/user_service.dart';
import 'package:balaji_points/services/cart_service.dart';
import 'package:balaji_points/core/logger.dart';
import 'package:balaji_points/presentation/widgets/top_carpenters_display.dart';
import 'package:balaji_points/presentation/widgets/offers_carousel.dart';

// ---------------------------------------------------------------------------
// State
// ---------------------------------------------------------------------------

class HomeState {
  final bool loading;
  final String? error;

  // User
  final Map<String, dynamic>? userData;
  final int points;
  final String? userDocId;
  final int? userRank;
  final int cartCount;

  // Leaderboard
  final List<CarpenterRank> topCarpenters;
  final bool rankingsLoading;

  // Offers
  final List<OfferItem> offers;
  final bool offersLoading;

  const HomeState({
    this.loading = true,
    this.error,
    this.userData,
    this.points = 0,
    this.userDocId,
    this.userRank,
    this.cartCount = 0,
    this.topCarpenters = const [],
    this.rankingsLoading = true,
    this.offers = const [],
    this.offersLoading = true,
  });

  bool get isProfileComplete {
    if (userData == null) return false;
    final fn = (userData!['firstName'] as String? ?? '').trim();
    final ln = (userData!['lastName'] as String? ?? '').trim();
    final img = (userData!['profileImage'] as String? ?? '').trim();
    return fn.isNotEmpty && ln.isNotEmpty && img.isNotEmpty;
  }

  String get displayName {
    final fn = userData?['firstName'] ?? '';
    final ln = userData?['lastName'] ?? '';
    final name = '$fn $ln'.trim();
    return name.isEmpty ? 'User' : name;
  }

  String get tier => userData?['tier'] ?? 'Bronze';
  String? get profileImage => userData?['profileImage'] as String?;
  bool get isCarpenter => (userData?['role'] ?? '') == 'carpenter';

  HomeState copyWith({
    bool? loading,
    String? error,
    Map<String, dynamic>? userData,
    int? points,
    String? userDocId,
    int? userRank,
    bool clearUserRank = false,
    int? cartCount,
    List<CarpenterRank>? topCarpenters,
    bool? rankingsLoading,
    List<OfferItem>? offers,
    bool? offersLoading,
  }) =>
      HomeState(
        loading: loading ?? this.loading,
        error: error ?? this.error,
        userData: userData ?? this.userData,
        points: points ?? this.points,
        userDocId: userDocId ?? this.userDocId,
        userRank: clearUserRank ? null : (userRank ?? this.userRank),
        cartCount: cartCount ?? this.cartCount,
        topCarpenters: topCarpenters ?? this.topCarpenters,
        rankingsLoading: rankingsLoading ?? this.rankingsLoading,
        offers: offers ?? this.offers,
        offersLoading: offersLoading ?? this.offersLoading,
      );
}

// ---------------------------------------------------------------------------
// Notifier
// ---------------------------------------------------------------------------

class HomeNotifier extends Notifier<HomeState> {
  final _firestore = FirebaseFirestore.instance;
  final _session = SessionService();
  final _userService = UserService();
  final _cartService = CartService();

  @override
  HomeState build() {
    _load();
    return const HomeState();
  }

  // ── Public API ──────────────────────────────────────────────────────────────

  Future<void> refresh() async {
    state = state.copyWith(loading: true);
    await _load();
  }

  void updatePoints(int newPoints) {
    state = state.copyWith(points: newPoints);
    _refreshRankings();
  }

  // ── Internal ────────────────────────────────────────────────────────────────

  Future<void> _load() async {
    try {
      await _loadUser();
      await Future.wait([_loadOffers(), _refreshRankings()]);
      state = state.copyWith(loading: false);
    } catch (e, st) {
      AppLogger.error('HomeNotifier load failed', e, st);
      state = state.copyWith(loading: false, error: e.toString());
    }
  }

  Future<void> _loadUser() async {
    try {
      final data = await _userService.getCurrentUserData();
      final docId = await _resolveDocId();
      final userId = await _session.getUserId();

      final pts = _asInt(data?['totalPoints']);

      state = state.copyWith(
        userData: data,
        points: pts,
        userDocId: docId,
      );

      // Subscribe cart count
      if (userId != null) {
        _cartService.watchCartCount(userId).listen((n) {
          if (state.userDocId != null) {
            state = state.copyWith(cartCount: n);
          }
        });
      }
    } catch (e) {
      AppLogger.error('HomeNotifier _loadUser failed', e);
    }
  }

  Future<void> _loadOffers() async {
    state = state.copyWith(offersLoading: true);
    try {
      final snap = await _firestore
          .collection('offers')
          .where('isActive', isEqualTo: true)
          .orderBy('createdAt', descending: true)
          .limit(10)
          .get();

      final offers = snap.docs.map((doc) {
        final d = doc.data();
        return OfferItem(
          title: d['title'] as String? ?? '',
          description: d['description'] as String? ?? '',
          actionText: (d['bannerUrl'] != null && d['bannerUrl'] != '')
              ? 'View Offer'
              : 'Learn More',
          imageUrl: d['bannerUrl'] as String?,
        );
      }).toList();

      state = state.copyWith(offers: offers, offersLoading: false);
    } catch (e, st) {
      AppLogger.error('HomeNotifier offers load failed', e, st);
      state = state.copyWith(offersLoading: false);
    }
  }

  Future<void> _refreshRankings() async {
    state = state.copyWith(rankingsLoading: true);
    try {
      final ranked = await _fetchRanked();
      final docId = state.userDocId;

      int? userRank;
      if (docId != null) {
        final match = ranked.where((c) => c.userId == docId);
        if (match.isNotEmpty) userRank = match.first.rank;
      }

      state = state.copyWith(
        topCarpenters: ranked.take(10).toList(),
        rankingsLoading: false,
        userRank: userRank,
        clearUserRank: userRank == null,
      );
    } catch (e, st) {
      AppLogger.error('HomeNotifier rankings failed', e, st);
      state = state.copyWith(rankingsLoading: false);
    }
  }

  Future<List<CarpenterRank>> _fetchRanked() async {
    final qs = await _firestore.collection('users').get();
    final docId = state.userDocId;

    final carpenters = <CarpenterRank>[];
    for (final doc in qs.docs) {
      final d = doc.data();
      final role = d['role'] as String?;
      if (role == 'admin') continue;
      if (role != null && role.isNotEmpty && role != 'carpenter') continue;

      final fn = (d['firstName'] as String? ?? '').trim();
      final ln = (d['lastName'] as String? ?? '').trim();
      final name = '$fn $ln'.trim();

      carpenters.add(CarpenterRank(
        rank: 0,
        name: name.isEmpty ? 'Carpenter' : name,
        points: _asInt(d['totalPoints']),
        imageUrl: d['profileImage'] as String?,
        userId: doc.id,
        isCurrentUser: doc.id == docId,
      ));
    }

    carpenters.sort((a, b) => b.points.compareTo(a.points));

    return List.generate(carpenters.length, (i) => CarpenterRank(
      rank: i + 1,
      name: carpenters[i].name,
      points: carpenters[i].points,
      imageUrl: carpenters[i].imageUrl,
      userId: carpenters[i].userId,
      isCurrentUser: carpenters[i].isCurrentUser,
    ));
  }

  Future<String?> _resolveDocId() async {
    final userId = await _session.getUserId();
    final phone = await _session.getPhoneNumber();

    for (final id in [userId, phone].whereType<String>()) {
      if (id.isEmpty) continue;
      final doc = await _firestore.collection('users').doc(id).get();
      if (doc.exists) return doc.id;
    }
    if (phone != null && phone.isNotEmpty) {
      final q = await _firestore
          .collection('users')
          .where('phone', isEqualTo: phone)
          .limit(1)
          .get();
      if (q.docs.isNotEmpty) return q.docs.first.id;
    }
    return userId;
  }

  static int _asInt(dynamic v) {
    if (v is num) return v.toInt();
    return int.tryParse(v?.toString() ?? '') ?? 0;
  }
}

// ---------------------------------------------------------------------------
// Provider
// ---------------------------------------------------------------------------

final homeProvider = NotifierProvider<HomeNotifier, HomeState>(HomeNotifier.new);
