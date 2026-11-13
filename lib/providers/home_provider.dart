import 'package:balaji_points/core/profile/profile_completeness.dart';
import 'package:balaji_points/core/utils/points_utils.dart';
import 'package:balaji_points/services/platform/offer_visibility.dart';
import 'package:balaji_points/core/constants/app_constants.dart';
import 'package:balaji_points/services/branch/current_branch_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:balaji_points/services/auth/session_service.dart';
import 'package:balaji_points/services/user/user_service.dart';
import 'package:balaji_points/services/user/user_points_sync_service.dart';
import 'package:balaji_points/core/logger.dart';
import 'package:balaji_points/core/models/greeting_model.dart';
import 'package:balaji_points/presentation/widgets/carpenter/top_carpenters_display.dart';
import 'package:balaji_points/presentation/widgets/carpenter/offers_carousel.dart';

// ---------------------------------------------------------------------------
// State
// ---------------------------------------------------------------------------

class HomeState {
  final bool loading;
  final String? error;

  // User
  final Map<String, dynamic>? userData;
  final double points;
  final String? userDocId;
  final int? userRank;

  // Leaderboard
  final List<CarpenterRank> topCarpenters;
  final bool rankingsLoading;

  // Offers
  final List<OfferItem> offers;
  final bool offersLoading;

  // Greeting
  final GreetingItem? greeting;
  final bool greetingLoading;

  const HomeState({
    this.loading = true,
    this.error,
    this.userData,
    this.points = 0.0,
    this.userDocId,
    this.userRank,
    this.topCarpenters = const [],
    this.rankingsLoading = true,
    this.offers = const [],
    this.offersLoading = true,
    this.greeting,
    this.greetingLoading = true,
  });

  /// Photo, first and last name, and mobile number (see ProfileCompleteness).
  bool get isProfileComplete =>
      userData != null && ProfileCompleteness.from(userData).isReadyForBills;

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
    double? points,
    String? userDocId,
    int? userRank,
    bool clearUserRank = false,
    List<CarpenterRank>? topCarpenters,
    bool? rankingsLoading,
    List<OfferItem>? offers,
    bool? offersLoading,
    GreetingItem? greeting,
    bool? greetingLoading,
  }) => HomeState(
    loading: loading ?? this.loading,
    error: error ?? this.error,
    userData: userData ?? this.userData,
    points: points ?? this.points,
    userDocId: userDocId ?? this.userDocId,
    userRank: clearUserRank ? null : (userRank ?? this.userRank),
    topCarpenters: topCarpenters ?? this.topCarpenters,
    rankingsLoading: rankingsLoading ?? this.rankingsLoading,
    offers: offers ?? this.offers,
    offersLoading: offersLoading ?? this.offersLoading,
    greeting: greeting ?? this.greeting,
    greetingLoading: greetingLoading ?? this.greetingLoading,
  );
}

// ---------------------------------------------------------------------------
// Notifier
// ---------------------------------------------------------------------------

class HomeNotifier extends Notifier<HomeState> {
  final _firestore = FirebaseFirestore.instance;
  final _session = SessionService();
  final _userService = UserService();

  @override
  HomeState build() {
    ref.listen(carpenterPointsProvider, (prev, next) {
      if (!next.loaded) return;
      state = state.copyWith(
        points: next.totalPoints,
        userData: state.userData != null
            ? {...state.userData!, 'tier': next.tier}
            : state.userData,
      );
    });
    // Runs after build returns: state cannot be read until then.
    Future.microtask(_load);
    return const HomeState();
  }

  // ── Public API ──────────────────────────────────────────────────────────────

  /// Updates silently: what is on screen stays until the new data arrives.
  Future<void> refresh() async {
    await ref.read(carpenterPointsProvider.notifier).refresh();
    await _load();
  }

  void updatePoints(double newPoints) {
    state = state.copyWith(points: newPoints);
    _refreshRankings();
  }

  // ── Internal ────────────────────────────────────────────────────────────────

  Future<void> _load() async {
    try {
      await _seedFromSession();
      // Nothing waits on anything it does not need, so each card appears as
      // soon as its own data does. The points card does not wait for rankings.
      await Future.wait([
        _loadProfileThenRankings(),
        _loadOffers(),
        _loadGreeting(),
        _showCachedRankings(),
      ]);
    } catch (e, st) {
      AppLogger.error('HomeNotifier load failed', e, st);
    } finally {
      // Whatever failed, never leave the screen on its loader forever.
      state = state.copyWith(
        loading: false,
        offersLoading: false,
        greetingLoading: false,
        rankingsLoading: false,
      );
    }
  }

  /// The name saved at login, so the points card can show straight away.
  Future<void> _seedFromSession() async {
    if (state.userData != null) return;
    try {
      final first = (await _session.getFirstName())?.trim() ?? '';
      final last = (await _session.getLastName())?.trim() ?? '';
      if (first.isEmpty && last.isEmpty) return;
      state = state.copyWith(
        loading: false,
        userData: {
          'firstName': first,
          'lastName': last,
          'profileImage': await _session.getProfileImage() ?? '',
          'phone': await _session.getPhoneNumber() ?? '',
          'role': await _session.getUserRole() ?? '',
          'branchId': await _session.getBranchId() ?? '',
        },
      );
    } catch (e) {
      AppLogger.warning('Could not read the saved profile: $e');
    }
  }

  Future<void> _loadProfileThenRankings() async {
    try {
      // Points and profile load side by side; the points listener in build()
      // fills in the tier if points land after the profile.
      await Future.wait([
        ref.read(carpenterPointsProvider.notifier).ensureLoaded(),
        _loadUser(),
      ]);
    } catch (e, st) {
      AppLogger.error('HomeNotifier load failed', e, st);
      state = state.copyWith(error: e.toString());
    } finally {
      state = state.copyWith(loading: false);
    }
    await _refreshRankings();
  }

  /// Last known rankings from this phone, shown until the server replies.
  Future<void> _showCachedRankings() async {
    try {
      final ranked = await _fetchRanked(source: Source.cache);
      if (ranked.isEmpty || state.topCarpenters.isNotEmpty) return;
      state = state.copyWith(
        topCarpenters: ranked.take(10).toList(),
        rankingsLoading: false,
      );
    } catch (_) {
      // Nothing saved yet (first launch): the loader stays until the server.
    }
  }

  Future<void> _loadUser() async {
    // The copy saved on the phone first, so the card fills in at once.
    try {
      final cached = await _userService.getCurrentUserData(cacheOnly: true);
      if (cached != null) {
        final c = Map<String, dynamic>.from(cached)..remove('totalPoints');
        final points = ref.read(carpenterPointsProvider);
        if (points.loaded) c['tier'] = points.tier;
        state = state.copyWith(userData: c, loading: false);
      }
    } catch (_) {}
    try {
      final data = await _userService.getCurrentUserData();
      final docId = await _resolveDocId();
      final carpenterPoints = ref.read(carpenterPointsProvider);

      // Profile fields from users; points/tier always from user_points.
      final profileData = data != null ? Map<String, dynamic>.from(data) : null;
      profileData?.remove('totalPoints');

      state = state.copyWith(
        userData: profileData != null
            ? {
                ...profileData,
                if (carpenterPoints.loaded) 'tier': carpenterPoints.tier,
              }
            : profileData,
        points: carpenterPoints.loaded
            ? carpenterPoints.totalPoints
            : state.points,
        userDocId: docId,
      );
    } catch (e) {
      AppLogger.error('HomeNotifier _loadUser failed', e);
    }
  }

  Future<void> _loadOffers() async {
    final query = _firestore
        .collection('offers')
        .where('isActive', isEqualTo: true)
        .limit(50); // filtered to this branch below
    // Offers are per branch, so the branch must be known before showing any.
    _myBranchId ??= await CurrentBranchService().resolveBranchId();
    if (state.offers.isEmpty) {
      try {
        final cached = await query.get(const GetOptions(source: Source.cache));
        if (cached.docs.isNotEmpty) _applyOffers(cached);
      } catch (_) {
        // Nothing saved yet: the loader stays until the server replies.
      }
    }
    try {
      _applyOffers(await query.get());
    } catch (e, st) {
      AppLogger.error('HomeNotifier offers load failed', e, st);
      state = state.copyWith(offersLoading: false);
    }
  }

  String? _myBranchId;

  void _applyOffers(QuerySnapshot<Map<String, dynamic>> snap) {
    // The order the branch admin arranged (same rule as the admin list).
    final sorted = snap.docs.toList()
      ..sort((a, b) => OfferVisibility.compare(a.data(), b.data()));

    // This member's branch's offers, plus the super admin's all-branch ones.
    final offers = sorted
        .where((doc) => OfferVisibility.memberCanSee(doc.data(), _myBranchId))
        // Offers past their "valid until" day are no longer shown.
        .where((doc) {
          final until = doc.data()['validUntil'];
          if (until is! Timestamp) return true;
          final end = until.toDate();
          return !DateTime(
            end.year,
            end.month,
            end.day + 1,
          ).isBefore(DateTime.now());
        })
        .map((doc) {
          final d = doc.data();
          final validUntil = d['validUntil'];
          return OfferItem(
            id: doc.id,
            title: d['title'] as String? ?? '',
            description: d['description'] as String? ?? '',
            imageUrl: d['bannerUrl'] as String?,
            pointsTarget: PointsUtils.asDouble(d['points']),
            validUntil: validUntil is Timestamp ? validUntil.toDate() : null,
          );
        })
        .toList();

    state = state.copyWith(offers: offers, offersLoading: false);
  }

  Future<void> _loadGreeting() async {
    try {
      final snap = await _firestore
          .collection('greetings')
          .where('active', isEqualTo: true)
          .orderBy('createdAt', descending: true)
          .limit(10)
          .get();
      // Newest greeting for this carpenter's branch (or an all-branch one).
      final branchId = await CurrentBranchService().resolveBranchId();
      final match = snap.docs.where((doc) {
        final b = doc.data()['branchId'];
        return b == null || b == '' || b == branchId;
      });

      if (match.isEmpty) {
        state = state.copyWith(greeting: null, greetingLoading: false);
        return;
      }

      final greeting = GreetingItem.fromFirestore(match.first);
      state = state.copyWith(greeting: greeting, greetingLoading: false);
    } catch (e, st) {
      AppLogger.error('HomeNotifier greeting load failed', e, st);
      state = state.copyWith(greetingLoading: false);
    }
  }

  Future<void> _refreshRankings() async {
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

  Future<List<CarpenterRank>> _fetchRanked({
    Source source = Source.serverAndCache,
  }) async {
    // Leaderboard is per branch: all member roles compete within their store.
    final branchId = await CurrentBranchService().resolveBranchId();
    final options = GetOptions(source: source);
    final qs = branchId == null
        ? await _firestore.collection('users').get(options)
        : await _firestore
              .collection('users')
              .where('branchId', isEqualTo: branchId)
              .get(options);
    final docId = state.userDocId;

    final carpenters = <CarpenterRank>[];
    for (final doc in qs.docs) {
      final d = doc.data();
      if (!AppConstants.isMemberRole(d['role'] as String?)) continue;

      final fn = (d['firstName'] as String? ?? '').trim();
      final ln = (d['lastName'] as String? ?? '').trim();
      final name = '$fn $ln'.trim();

      carpenters.add(
        CarpenterRank(
          rank: 0,
          name: name.isEmpty ? 'Member' : name,
          points: PointsUtils.asDouble(d['totalPoints']),
          imageUrl: d['profileImage'] as String?,
          userId: doc.id,
          isCurrentUser: doc.id == docId,
        ),
      );
    }

    carpenters.sort((a, b) => b.points.compareTo(a.points));

    return List.generate(
      carpenters.length,
      (i) => CarpenterRank(
        rank: i + 1,
        name: carpenters[i].name,
        points: carpenters[i].points,
        imageUrl: carpenters[i].imageUrl,
        userId: carpenters[i].userId,
        isCurrentUser: carpenters[i].isCurrentUser,
      ),
    );
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
}

// ---------------------------------------------------------------------------
// Provider
// ---------------------------------------------------------------------------

final homeProvider = NotifierProvider<HomeNotifier, HomeState>(
  HomeNotifier.new,
);
