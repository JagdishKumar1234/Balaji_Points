// lib/presentation/screens/home/home_page.dart
// Complete Home screen: Offers (dynamic) + Top 10 carpenters (dynamic) + current user rank
// Uses CarpenterRank (version A: rank, name, points, imageUrl) from top_carpenters_display.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:confetti/confetti.dart';
import 'dart:math';
import 'dart:async';

import 'package:balaji_points/l10n/app_localizations.dart';
import 'package:balaji_points/presentation/widgets/top_carpenters_display.dart'; // provides CarpenterRank
import 'package:balaji_points/presentation/widgets/top_carpenters_list.dart';
import 'package:balaji_points/presentation/widgets/shimmer_loading.dart';
import 'package:balaji_points/presentation/screens/home/widgets/complete_profile_card.dart';
import 'package:balaji_points/presentation/widgets/offers_carousel.dart';
// Daily spin removed - admin only feature now
import 'package:balaji_points/services/user_service.dart';
import 'package:balaji_points/services/session_service.dart';
import 'package:balaji_points/services/cart_service.dart';
import 'package:balaji_points/services/fcm_service.dart';
import 'package:balaji_points/services/user_points_sync_service.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:intl/intl.dart';
import 'package:balaji_points/core/theme/design_token.dart';
import 'package:balaji_points/config/theme.dart' hide AppColors;
import 'package:balaji_points/core/layout/carpenter_shell_layout.dart';
import 'package:balaji_points/core/logger.dart';
import 'package:balaji_points/presentation/widgets/carpenter/carpenter_top_nav_bar.dart';

/// Decode width in physical pixels for [Image] `cacheWidth` to cut memory & jank.
int _imageCacheWidthPx(BuildContext context, double logicalWidth) {
  final dpr = MediaQuery.devicePixelRatioOf(context);
  return (logicalWidth * dpr).round().clamp(120, 2048);
}

/// ---------------------------------------------------------------------------
/// OFFERS CAROUSEL & CARDS
/// - horizontal list for banner offers with page indicators
/// - vertical list with full-width cards when no banners
/// ---------------------------------------------------------------------------
/// ---------------------------------------------------------------------------
/// HOME PAGE
/// ---------------------------------------------------------------------------
class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage>
    with WidgetsBindingObserver, AutomaticKeepAliveClientMixin<HomePage> {
  final UserService _userService = UserService();
  final SessionService _sessionService = SessionService();
  final CartService _cartService = CartService();
  final FCMService _fcmService = FCMService();

  // Offers
  List<OfferItem> _offers = [];
  bool _isLoadingOffers = true;

  // Cart count for header badge
  int _cartItemCount = 0;
  StreamSubscription<int>? _cartSubscription;

  final UserPointsSyncService _userPointsSyncService = UserPointsSyncService();
  VoidCallback? _userPointsListener;

  // App version (mirrors profile page)
  String _appVersion = '';

  // Top carpenters
  List<CarpenterRank> _topCarpenters = [];
  bool _isLoadingCarpenters = true;

  /// Cached future so [FutureBuilder] is not recreated every frame (was causing jank).
  Future<CarpenterRank?>? _currentUserRankFuture;

  /// Avoid replaying confetti on every StreamBuilder/FutureBuilder rebuild.
  String? _confettiPlayedKey;

  // current user
  Map<String, dynamic>? _currentUserData;
  int? _currentUserRank;
  int _currentUserPoints = 0;
  bool _isCarpenter = false;
  // ignore: unused_field
  String? _currentUserId;
  String? _currentUserDocId;
  // ignore: unused_field
  String? _userRole;

  bool _greetingIconPressed = false;

  // Confetti controller for celebration
  late ConfettiController _confettiController;

  // Product hero carousel
  late final PageController _productHeroPageController;
  int _currentProductHeroPage = 0;

  static const List<_HomeProductCategory> _categories = <_HomeProductCategory>[
    _HomeProductCategory(
      title: 'Bedroom',
      icon: Icons.bed_rounded,
      background: Color(0xFFF5F0FF),
      imageAsset: 'docs/furnitures_pics/luxirous lifestyle.jpeg',
    ),
    _HomeProductCategory(
      title: 'Kitchen',
      icon: Icons.kitchen_rounded,
      background: Color(0xFFFFF3E0),
      imageAsset:
          'docs/furnitures_pics/22 Gorgeous Brown Kitchen Cabinet Designs.jpeg',
    ),
    _HomeProductCategory(
      title: 'Living Room',
      icon: Icons.chair_rounded,
      background: Color(0xFFE3F2FD),
      imageAsset: 'docs/furnitures_pics/_ (6).jpeg',
    ),
    _HomeProductCategory(
      title: 'Wardrobe',
      icon: Icons.checkroom_rounded,
      background: Color(0xFFE8F5E9),
      imageAsset: 'docs/furnitures_pics/_ (10).jpeg',
    ),
    _HomeProductCategory(
      title: 'Office',
      icon: Icons.workspaces_rounded,
      background: Color(0xFFE8F0FE),
      imageAsset:
          'docs/furnitures_pics/Home Office_Todos os direitos da autoria e imagem são reservados aos responsáveis_.jpeg',
    ),
    _HomeProductCategory(
      title: 'Bathroom',
      icon: Icons.bathtub_rounded,
      background: Color(0xFFF3E5F5),
      imageAsset:
          'docs/furnitures_pics/Elegant Sage Green Kitchen with Brass Accents & Marble Island.jpeg',
    ),
  ];

  static const List<_ProductHeroCardData> _heroCards = <_ProductHeroCardData>[
    _ProductHeroCardData(
      title: 'Surfaces that\nradiate luxury',
      subtitle: 'Decorative laminates,\nveneers and acrylic panels.',
      imageAsset:
          'docs/furnitures_pics/22 Gorgeous Brown Kitchen Cabinet Designs.jpeg',
      icon: Icons.layers_rounded,
    ),
    _ProductHeroCardData(
      title: 'Bedroom that feels premium',
      subtitle: 'Warm finishes for\ncozy master bedrooms.',
      imageAsset: 'docs/furnitures_pics/luxirous lifestyle.jpeg',
      icon: Icons.bed_rounded,
    ),
    _ProductHeroCardData(
      title: 'Kitchen that inspires',
      subtitle: 'Modern finishes for\npremium modular kitchens.',
      imageAsset:
          'docs/furnitures_pics/Elegant Sage Green Kitchen with Brass Accents & Marble Island.jpeg',
      icon: Icons.kitchen_rounded,
    ),
    _ProductHeroCardData(
      title: 'Living room that welcomes',
      subtitle: 'TV units & wall panels\nfor family time.',
      imageAsset: 'docs/furnitures_pics/_ (6).jpeg',
      icon: Icons.weekend_rounded,
    ),
    _ProductHeroCardData(
      title: 'Office that boosts focus',
      subtitle: 'Create productive workspaces\nwith designer surfaces.',
      imageAsset:
          'docs/furnitures_pics/Home Office_Todos os direitos da autoria e imagem são reservados aos responsáveis_.jpeg',
      icon: Icons.chair_rounded,
    ),
  ];

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    _confettiController = ConfettiController(
      duration: const Duration(seconds: 3),
    );

    _productHeroPageController = PageController(viewportFraction: 0.9);

    _loadAppVersion();
    _startGlobalPointsSync();
    _loadInitialData();
  }

  Future<void> _loadAppVersion() async {
    try {
      final packageInfo = await PackageInfo.fromPlatform();
      if (!mounted) return;
      setState(() {
        _appVersion =
            'Version ${packageInfo.version} (${packageInfo.buildNumber})';
      });
    } catch (e) {
      debugPrint('HomePage: Error loading app version: $e');
      if (!mounted) return;
      setState(() {
        _appVersion = 'Version 1.0.0';
      });
    }
  }

  Future<void> _loadInitialData() async {
    await _loadUserData();
    await Future.wait([_loadOffers(), _refreshRankings()]);
    _refreshCurrentUserRankFuture();
    AppLogger.data(
      'Home ready · offers=${_offers.length} · carpenters=${_topCarpenters.length}',
    );
  }

  void _refreshCurrentUserRankFuture() {
    if (!mounted) return;
    setState(() {
      _currentUserRankFuture = _buildCurrentUserAsCarpenterRank();
    });
  }

  Future<void> _reloadOnResume() async {
    await _loadUserData();
    await Future.wait([_loadOffers(), _refreshRankings()]);
    _refreshCurrentUserRankFuture();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      unawaited(_reloadOnResume());
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _cartSubscription?.cancel();
    if (_userPointsListener != null) {
      _userPointsSyncService.pointsData.removeListener(_userPointsListener!);
    }
    _confettiController.dispose();
    _productHeroPageController.dispose();
    super.dispose();
  }

  Future<void> _startGlobalPointsSync() async {
    _userPointsListener ??= () {
      if (!mounted) return;
      final data = _userPointsSyncService.pointsData.value;
      if (data == null) return;
      final newPoints = _asInt(data['totalPoints']);
      setState(() {
        _currentUserPoints = newPoints;
        _currentUserData = {...?_currentUserData, ...data};
      });
      unawaited(() async {
        await _refreshRankings();
        _refreshCurrentUserRankFuture();
      }());
    };
    _userPointsSyncService.pointsData.removeListener(_userPointsListener!);
    _userPointsSyncService.pointsData.addListener(_userPointsListener!);
    await _userPointsSyncService.start();
    _userPointsListener?.call();
  }

  // ------------------ Offers ------------------
  Future<void> _loadOffers() async {
    setState(() => _isLoadingOffers = true);
    AppLogger.data('Fetching offers…');
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('offers')
          .where('isActive', isEqualTo: true)
          .orderBy('createdAt', descending: true)
          .limit(10) // Limit to 10 offers for performance
          .get();
      final list = snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>? ?? {};
        return OfferItem(
          title: data['title'] as String? ?? '',
          description: data['description'] as String? ?? '',
          actionText: (data['bannerUrl'] != null && data['bannerUrl'] != '')
              ? 'View Offer'
              : 'Learn More',
          imageUrl: data['bannerUrl'] as String? ?? '',
        );
      }).toList();
      if (mounted) {
        setState(() {
          _offers = list;
          _isLoadingOffers = false;
        });
      }
    } catch (e, st) {
      AppLogger.error('Offers load failed', e, st);
      if (mounted) {
        setState(() => _isLoadingOffers = false);
      }
    }
  }

  // ------------------ Top Carpenters ------------------
  Future<void> _loadTopCarpenters() async {
    setState(() => _isLoadingCarpenters = true);
    try {
      final rankedCarpenters = await _fetchRankedCarpenters();
      final top10 = rankedCarpenters.take(10).toList();

      if (mounted) {
        setState(() {
          _topCarpenters = top10;
          _isLoadingCarpenters = false;
        });
      }
    } catch (e, st) {
      AppLogger.error('Top carpenters load failed', e, st);
      if (mounted) setState(() => _isLoadingCarpenters = false);
    }
  }

  Future<List<CarpenterRank>> _fetchRankedCarpenters() async {
    final qs = await FirebaseFirestore.instance.collection('users').get();

    final resolvedCurrentUserDocId =
        _currentUserDocId ?? (await _resolveCurrentUserDoc())?.id;
    final carpenters = <CarpenterRank>[];

    for (final doc in qs.docs) {
      final data = doc.data();
      final role = data['role'] as String?;
      if (role == 'admin') {
        continue;
      }
      if (role != null && role.isNotEmpty && role != 'carpenter') {
        continue;
      }

      final firstName = (data['firstName'] as String? ?? '').trim();
      final lastName = (data['lastName'] as String? ?? '').trim();
      final displayName = ('$firstName $lastName').trim();

      carpenters.add(
        CarpenterRank(
          rank: 0,
          name: displayName.isEmpty ? 'Carpenter' : displayName,
          points: _asInt(data['totalPoints']),
          imageUrl: data['profileImage'] as String?,
          userId: doc.id,
          isCurrentUser: doc.id == resolvedCurrentUserDocId,
        ),
      );
    }

    carpenters.sort((a, b) => b.points.compareTo(a.points));

    return List<CarpenterRank>.generate(carpenters.length, (index) {
      final carpenter = carpenters[index];
      return CarpenterRank(
        rank: index + 1,
        name: carpenter.name,
        points: carpenter.points,
        imageUrl: carpenter.imageUrl,
        userId: carpenter.userId,
        isCurrentUser: carpenter.isCurrentUser,
      );
    });
  }

  Future<void> _refreshRankings() async {
    await _loadTopCarpenters();
    await _loadCurrentUserRank();
  }

  // ------------------ Current user data ------------------
  Future<void> _loadUserData() async {
    try {
      // Prefer unified UserService so Home/Profile use same source of truth
      final data = await _user_service_getCurrentUserDataSafe();
      final userId = await _sessionService.getUserId();
      final currentUserDoc = await _resolveCurrentUserDoc();

      if (mounted) {
        setState(() {
          _currentUserData = data;
          _isCarpenter = (data?['role'] ?? '') == 'carpenter';
          _userRole = (data?['role'] ?? '') as String?;
          _currentUserId = userId;
          _currentUserDocId = currentUserDoc?.id ?? userId;
          _currentUserPoints = _asInt(data?['totalPoints']);
        });
        if (userId != null) {
          _subscribeCartCount(userId);
        }
        await _startGlobalPointsSync();
      }
    } catch (e) {
      debugPrint('Error loading current user data: $e');
      // Fallback to service method on error
      try {
        final data = await _user_service_getCurrentUserDataSafe();
        final errorFallbackUserId = await _sessionService.getUserId();
        final currentUserDoc = await _resolveCurrentUserDoc();
        if (mounted) {
          setState(() {
            _currentUserData = data;
            _isCarpenter = (data?['role'] ?? '') == 'carpenter';
            _userRole = (data?['role'] ?? '') as String?;
            _currentUserId = errorFallbackUserId;
            _currentUserDocId = currentUserDoc?.id ?? errorFallbackUserId;
            _currentUserPoints = _asInt(data?['totalPoints']);
          });
          if (errorFallbackUserId != null) {
            _subscribeCartCount(errorFallbackUserId);
          }
          await _startGlobalPointsSync();
        }
      } catch (e2) {
        debugPrint('Error in fallback user data load: $e2');
      }
    }
  }

  Future<Map<String, dynamic>?> _user_service_getCurrentUserDataSafe() async {
    try {
      return await _userService.getCurrentUserData();
    } catch (_) {
      return null;
    }
  }

  void _subscribeCartCount(String userId) {
    _cartSubscription?.cancel();
    _cartSubscription = _cartService.watchCartCount(userId).listen((count) {
      if (!mounted) return;
      setState(() {
        _cartItemCount = count;
      });
    });
  }

  Future<DocumentSnapshot<Map<String, dynamic>>?> _resolveCurrentUserDoc() async {
    final firestore = FirebaseFirestore.instance;
    final userId = await _sessionService.getUserId();
    final phoneNumber = await _sessionService.getPhoneNumber();
    final candidateIds = <String>{
      if (userId != null && userId.isNotEmpty) userId,
      if (phoneNumber != null && phoneNumber.isNotEmpty) phoneNumber,
    };

    for (final candidateId in candidateIds) {
      final doc = await firestore.collection('users').doc(candidateId).get();
      if (doc.exists) return doc;
    }

    if (phoneNumber != null && phoneNumber.isNotEmpty) {
      final query = await firestore
          .collection('users')
          .where('phone', isEqualTo: phoneNumber)
          .limit(1)
          .get();
      if (query.docs.isNotEmpty) {
        return query.docs.first;
      }
    }

    return null;
  }

  // ------------------ Current user rank ------------------
  Future<void> _loadCurrentUserRank() async {
    try {
      final currentUserDocId =
          _currentUserDocId ?? (await _resolveCurrentUserDoc())?.id;
      if (currentUserDocId == null) {
        if (mounted) setState(() => _currentUserRank = null);
        return;
      }

      final rankedCarpenters = await _fetchRankedCarpenters();
      final currentUserRank = rankedCarpenters.firstWhere(
        (carpenter) => carpenter.userId == currentUserDocId,
        orElse: () => CarpenterRank(rank: -1, name: '', points: 0, userId: ''),
      );

      if (currentUserRank.rank <= 0) {
        if (mounted) setState(() => _currentUserRank = null);
        return;
      }

      if (mounted)
        setState(() {
          _currentUserRank = currentUserRank.rank;
        });
    } catch (e, st) {
      debugPrint('Error computing user rank: $e\n$st');
      if (mounted) setState(() => _currentUserRank = null);
    }
  }

  // ------------------ UI helper getters ------------------
  String _getUserDisplayName() {
    final fn = _currentUserData?['firstName'] ?? '';
    final ln = _currentUserData?['lastName'] ?? '';
    final name = '$fn $ln'.trim();
    return name.isEmpty ? 'User' : name;
  }

  String _getUserTier() => _currentUserData?['tier'] ?? 'Bronze';
  String? _getUserProfileImage() =>
      _currentUserData?['profileImage'] as String?;

  int _asInt(dynamic value) {
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  /// Check if user profile is complete (has firstName, lastName, and profileImage)
  bool _isProfileComplete() {
    if (_currentUserData == null) return false;

    final firstName = (_currentUserData!['firstName'] as String? ?? '').trim();
    final lastName = (_currentUserData!['lastName'] as String? ?? '').trim();
    final profileImage = (_currentUserData!['profileImage'] as String? ?? '')
        .trim();

    return firstName.isNotEmpty &&
        lastName.isNotEmpty &&
        profileImage.isNotEmpty;
  }

  /// Check if URL is valid for NetworkImage (http or https)
  bool _isValidImageUrl(String? url) {
    if (url == null || url.isEmpty) return false;
    final trimmed = url.trim();
    return trimmed.startsWith('http://') || trimmed.startsWith('https://');
  }

  /// Large formatted points for light “Total Points” summary (blueprint §4).
  Widget _buildHomePointsBigValue({
    double fontSize = DesignToken.fontSize4XL,
    Color? color,
  }) {
    final nf = NumberFormat.decimalPattern();
    final valueStyle = AppTextStyles.nunitoBold.copyWith(
      color: color ?? DesignToken.homeTextPrimary,
      fontSize: fontSize,
      height: 1.05,
    );

    return Text(nf.format(_currentUserPoints), style: valueStyle);
  }

  /// Static gold coin beside hero points (no animation — avoids jank & hot-reload init issues).
  Widget _buildHomePointsCoin({required bool onDarkCard}) {
    return Container(
      width: 46,
      height: 46,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          colors: onDarkCard
              ? <Color>[
                  DesignToken.amberShade400,
                  DesignToken.amberShade800,
                ]
              : <Color>[
                  DesignToken.amberShade200,
                  DesignToken.amberShade700,
                ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(
          color: DesignToken.white.withValues(alpha: onDarkCard ? 0.4 : 0.55),
          width: 1.25,
        ),
        boxShadow: [
          BoxShadow(
            color: DesignToken.amberShade800.withValues(
              alpha: onDarkCard ? 0.22 : 0.12,
            ),
            blurRadius: onDarkCard ? 8 : 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      alignment: Alignment.center,
      child: Icon(
        Icons.toll_rounded,
        color: DesignToken.white,
        size: DesignToken.iconSizeLG + 2,
      ),
    );
  }

  Future<CarpenterRank?> _buildCurrentUserAsCarpenterRank() async {
    final currentUserId = _currentUserDocId ?? await _sessionService.getUserId();
    if (currentUserId == null || _currentUserRank == null) return null;

    // Check if current user is already in top 10
    final existingUser = _topCarpenters.firstWhere(
      (c) => c.userId == currentUserId,
      orElse: () => CarpenterRank(rank: -1, name: '', points: 0, userId: ''),
    );

    if (existingUser.rank > 0) {
      // User is in top 10, return the existing one
      return existingUser;
    }

    // User is not in top 10, create a new entry
    return CarpenterRank(
      rank: _currentUserRank!,
      name: _getUserDisplayName(),
      points: _currentUserPoints,
      imageUrl: _getUserProfileImage(),
      userId: currentUserId,
      isCurrentUser: true,
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    // Note: currentUserRankObj is now async, handled in FutureBuilder below
    final top3 = _topCarpenters.take(3).toList();

    final theme = Theme.of(context);
    final mq = MediaQuery.of(context);
    final bottomContentPadding =
        CarpenterShellLayout.bottomPaddingForScrollView(mq);

    final isDark = theme.brightness == Brightness.dark;
    final canvas = isDark
        ? theme.colorScheme.surface
        : DesignToken.carpenterAppBackground;

    return Scaffold(
      backgroundColor: canvas,
      drawer: _buildHomeDrawer(context),
      appBar: _buildHomeAppBar(context, theme),
      body: Stack(
        children: [
          Container(
            color: canvas,
            child: RefreshIndicator(
              onRefresh: _loadInitialData,
              color: DesignToken.primary,
              backgroundColor: canvas,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: EdgeInsets.only(bottom: bottomContentPadding),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(height: DesignToken.layoutSectionGapTight),
                    RepaintBoundary(child: _buildHomeHeroCard(context)),
                    SizedBox(height: DesignToken.layoutCardGap),
                    // Complete Profile Card (shown if profile is incomplete)
                    if (!_isProfileComplete()) ...[
                      const RepaintBoundary(child: CompleteProfileCard()),
                      SizedBox(height: DesignToken.layoutSectionGap),
                    ],
                    SizedBox(height: DesignToken.layoutCardGap),
                    // Offers (blueprint: section title styling — copy unchanged)
                    Padding(
                      padding: DesignToken.layoutScreenHorizontal,
                      child: Text(
                        AppLocalizations.of(context)!.latestOffers,
                        style: AppTextStyles.nunitoSemiBold.copyWith(
                          color: isDark
                              ? theme.colorScheme.onSurface
                              : DesignToken.homeTextPrimary,
                          fontSize: DesignToken.fontSizeMD,
                        ),
                      ),
                    ),
                    SizedBox(height: DesignToken.layoutCardGapTight),
                    // Offers carousel
                    RepaintBoundary(
                      child: _isLoadingOffers
                          ? const ShimmerOfferCard()
                          : OffersCarousel(offers: _offers),
                    ),
                    SizedBox(height: DesignToken.layoutSectionGap),
                    // Products section (horizontal carousel)
                    RepaintBoundary(child: _buildProductsSection(context)),
                    SizedBox(height: DesignToken.layoutSectionGap),
                    _buildRankingsSection(context, theme, top3),
                    SizedBox(height: DesignToken.layoutSectionGap),
                  ],
                ),
              ),
            ),
          ),
          // Confetti widget for celebration (isolated repaint; ignores taps)
          Align(
            alignment: Alignment.topCenter,
            child: RepaintBoundary(
              child: IgnorePointer(
                child: ConfettiWidget(
                  confettiController: _confettiController,
                  blastDirection: pi / 2, // Down
                  maxBlastForce: 5,
                  minBlastForce: 2,
                  emissionFrequency: 0.05,
                  numberOfParticles: 20,
                  gravity: 0.3,
                  shouldLoop: false,
                  colors: const [
                    DesignToken.amber,
                    DesignToken.orange,
                    DesignToken.red,
                    DesignToken.pink,
                    DesignToken.purple,
                    DesignToken.blue500,
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRankingsSection(
    BuildContext context,
    ThemeData theme,
    List<CarpenterRank> top3,
  ) {
    final l10n = AppLocalizations.of(context)!;
    final isDark = theme.brightness == Brightness.dark;
    final titleColor = isDark
        ? theme.colorScheme.onSurface
        : DesignToken.homeTextPrimary;
    final subtitleColor = isDark
        ? theme.colorScheme.onSurface.withValues(alpha: 0.65)
        : DesignToken.homeTextMuted;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section heading only (no card chrome).
        Padding(
          padding: DesignToken.layoutScreenHorizontal,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.homeRankingsSectionTitle,
                style: AppTextStyles.nunitoSemiBold.copyWith(
                  fontSize: DesignToken.fontSizeMD,
                  color: titleColor,
                ),
              ),
              SizedBox(height: DesignToken.spacingXS),
              Text(
                l10n.homeRankingsSectionSubtitle,
                style: AppTextStyles.nunitoRegular.copyWith(
                  fontSize: DesignToken.fontSizeSM,
                  color: subtitleColor,
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: DesignToken.layoutCardGapTight),
        RepaintBoundary(child: _buildTodaysWinner()),
        SizedBox(height: DesignToken.layoutCardGap),
        RepaintBoundary(child: _buildCurrentUserPositionCard()),
        SizedBox(height: DesignToken.layoutCardGap),
        if (_isLoadingCarpenters)
          const RepaintBoundary(child: ShimmerTopCarpenters())
        else if (_topCarpenters.isNotEmpty) ...[
          RepaintBoundary(
            child: Container(
              margin: DesignToken.layoutScreenHorizontal,
              padding: const EdgeInsets.all(DesignToken.layoutScreenPaddingXLoose),
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                borderRadius: BorderRadius.circular(DesignToken.radiusXL),
                border: isDark
                    ? null
                    : Border.all(color: DesignToken.homeCardBorder),
                boxShadow: [
                  BoxShadow(
                    color: DesignToken.black.withValues(alpha: 0.05),
                    blurRadius: DesignToken.offerCarouselShadowBlur,
                    offset: Offset(0, DesignToken.offerCarouselShadowDy),
                  ),
                ],
              ),
              child: FutureBuilder<CarpenterRank?>(
                future: _currentUserRankFuture,
                builder: (context, snapshot) {
                  return TopCarpentersDisplay(
                    topCarpenters: top3,
                    currentUser: snapshot.data,
                  );
                },
              ),
            ),
          ),
          SizedBox(height: DesignToken.layoutCardGap),
          RepaintBoundary(
            child: Padding(
              padding: DesignToken.layoutScreenHorizontal,
              child: TopCarpentersList(
                carpenters: _topCarpenters,
                showViewAll: false,
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _drawerSectionLabel(String label, Color color) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        DesignToken.layoutScreenPaddingXLoose,
        DesignToken.spacingMD,
        DesignToken.layoutScreenPaddingXLoose,
        DesignToken.spacingXS,
      ),
      child: Text(
        label,
        style: AppTextStyles.nunitoSemiBold.copyWith(
          fontSize: 12,
          letterSpacing: 0.35,
          color: color,
        ),
      ),
    );
  }

  Drawer _buildHomeDrawer(BuildContext context) {
    final theme = Theme.of(context);
    final mediaQuery = MediaQuery.of(context);
    final topInset = mediaQuery.padding.top;
    final drawerFooterBottom =
        CarpenterShellLayout.chromeHeight(mediaQuery) + DesignToken.spacingSM;
    final bool isDarkTheme = theme.brightness == Brightness.dark;
    final Color titleColor = isDarkTheme
        ? DesignToken.white
        : DesignToken.textDark;
    final Color subtitleColor = isDarkTheme
        ? DesignToken.white.withValues(alpha: 0.80)
        : DesignToken.textDark.withValues(alpha: 0.70);

    final String name = _getUserDisplayName();
    final String phone = (_currentUserData?['phone'] as String?) ?? '';
    final String? profileImageUrl = _getUserProfileImage();

    final l10n = AppLocalizations.of(context)!;

    // Light, modern background that adapts to theme, with a subtle pattern‑like gradient
    final Color drawerBase = theme.colorScheme.surface;
    final Color drawerTintSoft = isDarkTheme
        ? DesignToken.primary.withValues(alpha: 0.10)
        : DesignToken.secondary.withValues(alpha: 0.06);
    final Color drawerTintAccent = isDarkTheme
        ? DesignToken.blueShade600.withValues(alpha: 0.16)
        : DesignToken.amberShade200.withValues(alpha: 0.30);

    return Drawer(
      elevation: 8,
      child: SafeArea(
        top: false,
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [drawerBase, drawerTintSoft, drawerTintAccent],
              stops: const [0.0, 0.45, 1.0],
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header (including top safe area)
              Container(
                padding: EdgeInsets.fromLTRB(
                  DesignToken.layoutScreenPaddingXLoose,
                  DesignToken.layoutScreenPaddingXLoose + topInset,
                  DesignToken.layoutScreenPaddingXLoose,
                  DesignToken.layoutScreenPaddingXLoose,
                ),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      isDarkTheme
                          ? DesignToken.blueShade600.withValues(alpha: 0.6)
                          : DesignToken.secondary.withValues(alpha: 0.15),
                      isDarkTheme
                          ? DesignToken.purpleShade600.withValues(alpha: 0.7)
                          : DesignToken.amberShade100.withValues(alpha: 0.9),
                    ],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: DesignToken.black.withValues(alpha: 0.15),
                      blurRadius: 18,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: DesignToken.white.withValues(alpha: 0.9),
                          width: 2,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: DesignToken.black.withValues(alpha: 0.25),
                            blurRadius: 12,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: ClipOval(
                        child: _isValidImageUrl(profileImageUrl)
                            ? Image.network(
                                profileImageUrl!,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) {
                                  return const ColoredBox(
                                    color: DesignToken.white,
                                    child: Icon(
                                      Icons.person,
                                      color: DesignToken.primary,
                                    ),
                                  );
                                },
                              )
                            : const ColoredBox(
                                color: DesignToken.white,
                                child: Icon(
                                  Icons.person,
                                  color: DesignToken.primary,
                                ),
                              ),
                      ),
                    ),
                    SizedBox(width: DesignToken.layoutScreenPaddingX),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            name,
                            style: AppTextStyles.nunitoSemiBold.copyWith(
                              color: DesignToken.white,
                              fontSize: DesignToken.fontSizeLG,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          SizedBox(height: DesignToken.spacingXS),
                          if (phone.isNotEmpty)
                            Text(
                              phone,
                              style: AppTextStyles.nunitoRegular.copyWith(
                                color: DesignToken.white.withValues(
                                  alpha: 0.85,
                                ),
                                fontSize: DesignToken.fontSizeSM,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: DesignToken.spacingXS),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.only(bottom: DesignToken.spacingSM),
                  children: [
                    _drawerSectionLabel(
                      l10n.drawerSectionMainNav,
                      subtitleColor,
                    ),
                    ListTile(
                      leading: const Icon(
                        Icons.home_rounded,
                        color: DesignToken.secondary,
                      ),
                      title: Text(
                        l10n.home,
                        style: AppTextStyles.nunitoRegular.copyWith(
                          color: titleColor,
                        ),
                      ),
                      onTap: () {
                        Navigator.of(context).pop();
                        context.go('/');
                      },
                    ),
                    ListTile(
                      leading: const Icon(
                        Icons.account_balance_wallet_outlined,
                        color: DesignToken.secondary,
                      ),
                      title: Text(
                        l10n.earn,
                        style: AppTextStyles.nunitoRegular.copyWith(
                          color: titleColor,
                        ),
                      ),
                      onTap: () {
                        Navigator.of(context).pop();
                        context.go('/wallet');
                      },
                    ),
                    ListTile(
                      leading: const Icon(
                        Icons.notifications_outlined,
                        color: DesignToken.secondary,
                      ),
                      title: Text(
                        l10n.notifications,
                        style: AppTextStyles.nunitoRegular.copyWith(
                          color: titleColor,
                        ),
                      ),
                      onTap: () {
                        Navigator.of(context).pop();
                        context.go('/notifications');
                      },
                    ),
                    ListTile(
                      leading: const Icon(
                        Icons.person_outline,
                        color: DesignToken.secondary,
                      ),
                      title: Text(
                        l10n.profile,
                        style: AppTextStyles.nunitoRegular.copyWith(
                          color: titleColor,
                        ),
                      ),
                      onTap: () {
                        Navigator.of(context).pop();
                        context.go('/profile');
                      },
                    ),
                    Padding(
                      padding: DesignToken.layoutScreenHorizontal,
                      child: Divider(
                        height: 24,
                        color: subtitleColor.withValues(alpha: 0.22),
                      ),
                    ),
                    _drawerSectionLabel(l10n.drawerSectionMore, subtitleColor),
                    ListTile(
                      leading: const Icon(
                        Icons.layers_rounded,
                        color: DesignToken.secondary,
                      ),
                      title: Text(
                        l10n.drawerProductsTitle,
                        style: AppTextStyles.nunitoRegular.copyWith(
                          color: titleColor,
                        ),
                      ),
                      subtitle: Text(
                        l10n.drawerProductsSubtitle,
                        style: AppTextStyles.nunitoRegular.copyWith(
                          color: subtitleColor,
                          fontSize: DesignToken.fontSizeSM,
                        ),
                      ),
                      onTap: () {
                        Navigator.of(context).pop();
                        context.push('/products');
                      },
                    ),
                    ListTile(
                      leading: const Icon(
                        Icons.shopping_cart_outlined,
                        color: DesignToken.secondary,
                      ),
                      title: Text(
                        l10n.drawerCart,
                        style: AppTextStyles.nunitoRegular.copyWith(
                          color: titleColor,
                        ),
                      ),
                      onTap: () {
                        Navigator.of(context).pop();
                        context.push('/cart');
                      },
                    ),
                    ListTile(
                      leading: const Icon(
                        Icons.receipt_long_rounded,
                        color: DesignToken.secondary,
                      ),
                      title: Text(
                        l10n.myOrders,
                        style: AppTextStyles.nunitoRegular.copyWith(
                          color: titleColor,
                        ),
                      ),
                      onTap: () {
                        Navigator.of(context).pop();
                        context.push('/orders');
                      },
                    ),
                    ListTile(
                      leading: const Icon(
                        Icons.info_outline_rounded,
                        color: DesignToken.secondary,
                      ),
                      title: Text(
                        l10n.aboutUs,
                        style: AppTextStyles.nunitoRegular.copyWith(
                          color: titleColor,
                        ),
                      ),
                      subtitle: Text(
                        l10n.aboutUsMenuSubtitle,
                        style: AppTextStyles.nunitoRegular.copyWith(
                          color: subtitleColor,
                          fontSize: DesignToken.fontSizeSM,
                        ),
                      ),
                      onTap: () {
                        Navigator.of(context).pop();
                        context.push('/about-us');
                      },
                    ),
                  ],
                ),
              ),
              Padding(
                padding: DesignToken.layoutScreenHorizontal,
                child: const Divider(),
              ),
              // Logout + version
              Padding(
                padding: EdgeInsets.fromLTRB(
                  DesignToken.layoutScreenPaddingX,
                  DesignToken.spacingSM,
                  DesignToken.layoutScreenPaddingX,
                  drawerFooterBottom,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (_appVersion.isNotEmpty) ...[
                      Center(
                        child: Text(
                          _appVersion,
                          style: AppTextStyles.nunitoRegular.copyWith(
                            fontSize: 12,
                            color: DesignToken.textDark.withValues(alpha: 0.5),
                          ),
                        ),
                      ),
                      SizedBox(height: DesignToken.spacingMD),
                    ],
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: DesignToken.redShade600,
                        foregroundColor: DesignToken.white,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(
                          vertical: DesignToken.paddingMD + 2,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      icon: const Icon(Icons.logout_rounded, size: 22),
                      label: Text(
                        l10n.logout,
                        style: AppTextStyles.nunitoBold.copyWith(
                          fontSize: 16,
                          color: DesignToken.white,
                        ),
                      ),
                      onPressed: () => _handleLogout(context),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _handleLogout(BuildContext context) async {
    final l10n = AppLocalizations.of(context)!;

    final shouldLogout = await showDialog<bool>(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        insetPadding: const EdgeInsets.symmetric(
          horizontal: DesignToken.padding2XL,
          vertical: DesignToken.padding2XL,
        ),
        backgroundColor: Theme.of(context).colorScheme.surface,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            DesignToken.padding2XL,
            DesignToken.padding2XL,
            DesignToken.padding2XL,
            DesignToken.layoutScreenPaddingX,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: DesignToken.error.withValues(alpha: 0.08),
                ),
                child: const Icon(
                  Icons.logout_rounded,
                  color: DesignToken.error,
                  size: 26,
                ),
              ),
              SizedBox(height: DesignToken.layoutScreenPaddingX),
              Text(
                l10n.logout,
                style: AppTextStyles.nunitoBold.copyWith(
                  fontSize: 20,
                  color: DesignToken.textDark,
                ),
              ),
              SizedBox(height: DesignToken.spacingSM),
              Text(
                l10n.logoutConfirmation,
                textAlign: TextAlign.center,
                style: AppTextStyles.nunitoRegular.copyWith(
                  fontSize: 15,
                  color: DesignToken.textDark.withValues(alpha: 0.75),
                ),
              ),
              SizedBox(height: DesignToken.layoutSectionGapTight),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(context).pop(false),
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(
                          color: DesignToken.grey400.withValues(alpha: 0.8),
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: Text(
                        l10n.no,
                        style: AppTextStyles.nunitoMedium.copyWith(
                          fontSize: 15,
                          color: DesignToken.textDark,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => Navigator.of(context).pop(true),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: DesignToken.error,
                        foregroundColor: DesignToken.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: Text(
                        l10n.yes,
                        style: AppTextStyles.nunitoSemiBold.copyWith(
                          fontSize: 15,
                          color: DesignToken.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );

    if (shouldLogout == true && context.mounted) {
      try {
        await _fcmService.deleteToken();
        await _sessionService.clearSession();
        if (context.mounted) {
          context.go('/login');
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${l10n.logoutFailed}: ${e.toString()}'),
              backgroundColor: DesignToken.error,
            ),
          );
        }
      }
    }
  }

  Widget _buildProductsSection(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    final isDark = theme.brightness == Brightness.dark;
    final Color titleColor = isDark
        ? DesignToken.white
        : DesignToken.homeTextPrimary;
    final Color subtitleColor = isDark
        ? DesignToken.white.withValues(alpha: 0.72)
        : DesignToken.homeTextMuted;
    final surfaceColor = theme.colorScheme.surface;
    final heroDecodeW = MediaQuery.sizeOf(context).width * 0.92;
    final Color dotActive = isDark
        ? DesignToken.white.withValues(alpha: 0.95)
        : DesignToken.primary;
    final Color dotInactive = isDark
        ? DesignToken.white.withValues(alpha: 0.45)
        : DesignToken.homeTextMuted.withValues(alpha: 0.35);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: DesignToken.layoutScreenHorizontal,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: const LinearGradient(
                        colors: DesignToken.woodenGradient,
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                    child: const Icon(
                      Icons.layers_rounded,
                      size: 18,
                      color: DesignToken.brownShade800,
                    ),
                  ),
                  SizedBox(width: DesignToken.spacingSM),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.homeBrowseProductsTitle,
                        style: AppTextStyles.nunitoSemiBold.copyWith(
                          color: titleColor,
                          fontSize: DesignToken.fontSizeMD,
                        ),
                      ),
                      Text(
                        l10n.homeBrowseProductsSubtitle,
                        style: AppTextStyles.nunitoRegular.copyWith(
                          color: subtitleColor,
                          fontSize: DesignToken.fontSizeSM,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              TextButton(
                onPressed: () => context.push('/products'),
                child: Text(
                  l10n.viewAll,
                  style: AppTextStyles.nunitoRegular.copyWith(
                    color: DesignToken.primary,
                    fontSize: DesignToken.fontSizeSM,
                  ),
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: DesignToken.layoutCardGapTight),
        SizedBox(
          height: 190,
          child: PageView.builder(
            controller: _productHeroPageController,
            itemCount: _heroCards.length,
            onPageChanged: (index) {
              setState(() => _currentProductHeroPage = index);
            },
            itemBuilder: (context, index) {
              final hero = _heroCards[index];
              return Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: DesignToken.layoutCardGapTight,
                ),
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(DesignToken.radiusXL),
                    boxShadow: [
                      BoxShadow(
                        color: DesignToken.brownShade800.withValues(
                          alpha: 0.18,
                        ),
                        blurRadius: 16,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        Image.asset(
                          hero.imageAsset,
                          fit: BoxFit.cover,
                          cacheWidth: _imageCacheWidthPx(context, heroDecodeW),
                        ),
                        DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                Colors.black.withValues(alpha: 0.10),
                                Colors.black.withValues(alpha: 0.65),
                              ],
                            ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(
                            DesignToken.layoutScreenPaddingXLoose,
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                width: 34,
                                height: 34,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: DesignToken.white.withValues(
                                    alpha: 0.92,
                                  ),
                                ),
                                child: Icon(
                                  hero.icon,
                                  size: 20,
                                  color: DesignToken.brownShade800,
                                ),
                              ),
                              SizedBox(height: DesignToken.spacingMD),
                              Text(
                                hero.title,
                                style: AppTextStyles.nunitoBold.copyWith(
                                  color: DesignToken.white,
                                  fontSize: DesignToken.fontSizeLG,
                                ),
                              ),
                              SizedBox(height: DesignToken.spacingSM),
                              Text(
                                hero.subtitle,
                                style: AppTextStyles.nunitoRegular.copyWith(
                                  color: DesignToken.white.withValues(
                                    alpha: 0.92,
                                  ),
                                  fontSize: DesignToken.fontSizeSM,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        SizedBox(height: DesignToken.spacingSM),
        Center(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: List.generate(_heroCards.length, (index) {
              final isActive = index == _currentProductHeroPage;
              return AnimatedContainer(
                duration: DesignToken.animationDurationFast,
                margin: const EdgeInsets.symmetric(
                  horizontal: DesignToken.spacingXS,
                ),
                height: 6,
                width: isActive ? 18 : 6,
                decoration: BoxDecoration(
                  color: isActive ? dotActive : dotInactive,
                  borderRadius: BorderRadius.circular(999),
                ),
              );
            }),
          ),
        ),
        SizedBox(height: DesignToken.layoutCardGapTight),
        SizedBox(
          height: 124,
          child: ListView.separated(
            padding: DesignToken.layoutScreenHorizontal,
            scrollDirection: Axis.horizontal,
            itemCount: _categories.length,
            separatorBuilder: (_, __) =>
                SizedBox(width: DesignToken.layoutCardGapTight),
            itemBuilder: (context, index) {
              final category = _categories[index];
              return _ProductCategoryCard(
                category: category,
                surfaceColor: surfaceColor,
                textColor: titleColor,
                onTap: () => context.push(
                  '/products?category=${Uri.encodeComponent(category.title)}',
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  PreferredSizeWidget _buildHomeAppBar(BuildContext context, ThemeData theme) {
    final l10n = AppLocalizations.of(context)!;
    final isDark = theme.brightness == Brightness.dark;
    final mq = MediaQuery.of(context);
    final fg = isDark ? DesignToken.white : DesignToken.textDark;
    final fgMuted = isDark
        ? DesignToken.white.withValues(alpha: 0.85)
        : DesignToken.textDark.withValues(alpha: 0.70);

    return CarpenterTopNavBar(
      topInset: CarpenterShellLayout.topInset(mq),
      title: 'Balaji Points',
      backgroundColor: isDark
          ? DesignToken.navyBackground
          : DesignToken.carpenterAppBackground,
      foregroundColor: fg,
      leading: Builder(
        builder: (ctx) => IconButton(
          icon: Icon(Icons.menu_rounded, color: fg),
          onPressed: () => Scaffold.of(ctx).openDrawer(),
        ),
      ),
      center: Row(
        children: [
          Image.asset(
            'assets/images/balaji_point_logo.png',
            width: 28,
            height: 28,
            errorBuilder: (_, __, ___) =>
                Icon(Icons.storefront_rounded, color: fg, size: 24),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Balaji Points',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.nunitoBold.copyWith(
                    color: fg,
                    fontSize: DesignToken.fontSizeLG,
                  ),
                ),
                Text(
                  '${l10n.companyName} · ${l10n.homeStoreBranch}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.nunitoRegular.copyWith(
                    color: fgMuted,
                    fontSize: DesignToken.fontSizeSM - 1,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      actions: [
        IconButton(
          onPressed: () => context.push('/cart'),
          icon: Stack(
            clipBehavior: Clip.none,
            children: [
              Icon(Icons.shopping_cart_outlined, color: fg),
              if (_cartItemCount > 0)
                Positioned(
                  top: -4,
                  right: -4,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: DesignToken.error,
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      _cartItemCount > 99 ? '99+' : '$_cartItemCount',
                      style: const TextStyle(
                        color: DesignToken.white,
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildHomeHeroCard(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final l10n = AppLocalizations.of(context)!;
    final now = DateTime.now();
    final hour = now.hour;
    final isDayTime = hour >= 6 && hour < 18;
    final String greeting = hour < 12
        ? l10n.goodMorningGreeting
        : (hour < 17 ? l10n.goodAfternoonGreeting : l10n.goodEveningGreeting);

    final profileImage = _getUserProfileImage();
    final hasValidImage =
        profileImage != null &&
        (profileImage.startsWith('http://') ||
            profileImage.startsWith('https://'));

    // Light: soft border card; avatar + greeting; points + animated coin; tier row.
    if (!isDark) {
      return Container(
        margin: DesignToken.layoutScreenHorizontal,
        padding: const EdgeInsets.all(DesignToken.layoutScreenPaddingX),
        decoration: DesignToken.homeSummaryCardDecoration(
          isDark: false,
          surfaceColor: theme.colorScheme.surface,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(
                  width: DesignToken.height4XL,
                  height: DesignToken.height4XL,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: DesignToken.homeCardBorder,
                      width: 1,
                    ),
                  ),
                  child: CircleAvatar(
                    radius: 17,
                    backgroundColor: DesignToken.grey100,
                    backgroundImage: hasValidImage
                        ? NetworkImage(profileImage)
                        : null,
                    child: !hasValidImage
                        ? Icon(
                            Icons.person,
                            size: DesignToken.iconSizeMD + 2,
                            color: DesignToken.homeTextMuted,
                          )
                        : null,
                  ),
                ),
                SizedBox(width: DesignToken.spacingSM + 2),
                Expanded(
                  child: Text.rich(
                    TextSpan(
                      style: AppTextStyles.nunitoRegular.copyWith(
                        fontSize: DesignToken.fontSizeSM,
                        color: DesignToken.homeTextMuted,
                        height: 1.15,
                      ),
                      children: [
                        TextSpan(text: '$greeting,\n'),
                        TextSpan(
                          text: _getUserDisplayName(),
                          style: AppTextStyles.nunitoBold.copyWith(
                            fontSize: DesignToken.fontSizeMD,
                            color: DesignToken.homeTextPrimary,
                            height: 1.15,
                          ),
                        ),
                      ],
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                _SunMoonBadge(
                  isDayTime: isDayTime,
                  pressed: _greetingIconPressed,
                  onPressedChanged: (v) =>
                      setState(() => _greetingIconPressed = v),
                  usePremiumLightStyle: true,
                ),
              ],
            ),
            SizedBox(height: DesignToken.layoutCardGapTight),
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                _buildHomePointsCoin(onDarkCard: false),
                SizedBox(width: DesignToken.spacingMD),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        l10n.totalPointsLabel,
                        style: AppTextStyles.nunitoRegular.copyWith(
                          fontSize: DesignToken.fontSizeXS + 1,
                          color: DesignToken.homeTextMuted,
                          height: 1.1,
                        ),
                      ),
                      SizedBox(height: DesignToken.heightXS / 2),
                      _buildHomePointsBigValue(
                        fontSize: DesignToken.fontSize3XL,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            SizedBox(height: DesignToken.layoutCardGapTight),
            Row(
              children: [
                Icon(
                  Icons.star_rounded,
                  color: DesignToken.amberShade300.withValues(alpha: 0.88),
                  size: DesignToken.iconSizeMD,
                ),
                SizedBox(width: DesignToken.spacingSM),
                Expanded(
                  child: Text(
                    '${_getUserTier()} ${l10n.homeTierSuffix}',
                    style: AppTextStyles.nunitoMedium.copyWith(
                      color: DesignToken.homeTextMuted,
                      fontSize: DesignToken.fontSizeSM,
                      height: 1.2,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Icon(
                  Icons.account_balance_wallet_outlined,
                  size: DesignToken.iconSizeSM + 2,
                  color: DesignToken.homeTextMuted.withValues(alpha: 0.55),
                ),
              ],
            ),
          ],
        ),
      );
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: DesignToken.paddingLG),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: <Color>[DesignToken.primary, DesignToken.secondary],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: DesignToken.borderRadiusXL,
        border: Border.all(
          color: DesignToken.white.withValues(alpha: 0.18),
          width: 1,
        ),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: DesignToken.primary.withValues(alpha: 0.22),
            blurRadius: 16,
            spreadRadius: 0,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(DesignToken.layoutScreenPaddingX),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: <Widget>[
                Container(
                  width: DesignToken.height4XL,
                  height: DesignToken.height4XL,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: DesignToken.white.withValues(alpha: 0.45),
                      width: 1,
                    ),
                  ),
                  child: CircleAvatar(
                    radius: 17,
                    backgroundColor: DesignToken.white.withValues(alpha: 0.18),
                    backgroundImage: hasValidImage
                        ? NetworkImage(profileImage)
                        : null,
                    child: !hasValidImage
                        ? const Icon(
                            Icons.person,
                            size: 22,
                            color: DesignToken.white,
                          )
                        : null,
                  ),
                ),
                SizedBox(width: DesignToken.spacingSM + 2),
                Expanded(
                  child: Text.rich(
                    TextSpan(
                      style: AppTextStyles.nunitoRegular.copyWith(
                        fontSize: DesignToken.fontSizeSM,
                        color: DesignToken.white.withValues(alpha: 0.82),
                        height: 1.15,
                      ),
                      children: <InlineSpan>[
                        TextSpan(text: '$greeting,\n'),
                        TextSpan(
                          text: _getUserDisplayName(),
                          style: AppTextStyles.nunitoBold.copyWith(
                            fontSize: DesignToken.fontSizeMD,
                            color: DesignToken.white,
                            height: 1.15,
                          ),
                        ),
                      ],
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                _SunMoonBadge(
                  isDayTime: isDayTime,
                  pressed: _greetingIconPressed,
                  onPressedChanged: (v) =>
                      setState(() => _greetingIconPressed = v),
                ),
              ],
            ),
            SizedBox(height: DesignToken.layoutCardGapTight),
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: <Widget>[
                _buildHomePointsCoin(onDarkCard: true),
                SizedBox(width: DesignToken.spacingMD),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      Text(
                        l10n.totalPointsLabel,
                        style: AppTextStyles.nunitoRegular.copyWith(
                          fontSize: DesignToken.fontSizeXS + 1,
                          color: DesignToken.white.withValues(alpha: 0.78),
                          height: 1.1,
                        ),
                      ),
                      SizedBox(height: DesignToken.heightXS / 2),
                      _buildHomePointsBigValue(
                        fontSize: DesignToken.fontSize3XL,
                        color: DesignToken.white,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            SizedBox(height: DesignToken.layoutCardGapTight),
            Row(
              children: <Widget>[
                Icon(
                  Icons.star_rounded,
                  color: DesignToken.amberShade300,
                  size: DesignToken.iconSizeMD,
                ),
                SizedBox(width: DesignToken.spacingSM),
                Expanded(
                  child: Text(
                    '${_getUserTier()} ${l10n.homeTierSuffix}',
                    style: AppTextStyles.nunitoMedium.copyWith(
                      color: DesignToken.white.withValues(alpha: 0.92),
                      fontSize: DesignToken.fontSizeSM,
                      height: 1.2,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Icon(
                  Icons.account_balance_wallet_outlined,
                  size: DesignToken.iconSizeSM + 2,
                  color: DesignToken.white.withValues(alpha: 0.55),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _SunMoonBadge({
    required bool isDayTime,
    required bool pressed,
    required ValueChanged<bool> onPressedChanged,
    bool usePremiumLightStyle = false,
  }) {
    final icon = isDayTime ? Icons.wb_sunny_outlined : Icons.nightlight_round;

    if (usePremiumLightStyle) {
      return GestureDetector(
        onTapDown: (_) => onPressedChanged(true),
        onTapUp: (_) => onPressedChanged(false),
        onTapCancel: () => onPressedChanged(false),
        child: AnimatedScale(
          duration: DesignToken.animationDurationFast,
          scale: pressed ? 0.9 : 1.0,
          child: Container(
            padding: const EdgeInsets.all(DesignToken.paddingSM + 2),
            decoration: const BoxDecoration(
              color: DesignToken.homeIconCircleBlue,
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              color: DesignToken.homeTextMuted,
              size: DesignToken.iconSizeMD + 2,
            ),
          ),
        ),
      );
    }

    return GestureDetector(
      onTapDown: (_) => onPressedChanged(true),
      onTapUp: (_) => onPressedChanged(false),
      onTapCancel: () => onPressedChanged(false),
      child: AnimatedScale(
        duration: DesignToken.animationDurationFast,
        scale: pressed ? 0.9 : 1.0,
        child: Container(
          padding: const EdgeInsets.all(DesignToken.paddingSM + 2),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: isDayTime
                  ? [DesignToken.amberShade300, DesignToken.amberShade500]
                  : [DesignToken.blueShade600, DesignToken.purpleShade600],
            ),
            boxShadow: [
              BoxShadow(
                color: DesignToken.black.withValues(alpha: 0.15),
                blurRadius: DesignToken.offerCarouselShadowBlur,
                offset: Offset(0, DesignToken.offerCarouselShadowDy),
              ),
            ],
          ),
          child: Icon(
            icon,
            color: DesignToken.white,
            size: DesignToken.iconSizeMD + 4,
          ),
        ),
      ),
    );
  }

  // Build CarpenterRank object for current user to pass to TopCarpentersDisplay
  // Note: currentUserRankObj is now async - use FutureBuilder where needed

  List<CarpenterRank> get remaining =>
      _topCarpenters.length > 3 ? _topCarpenters.sublist(3) : <CarpenterRank>[];

  // Current User Position Card
  Widget _buildCurrentUserPositionCard() {
    if (_currentUserRank == null) {
      return const SizedBox.shrink();
    }

    return Container(
      margin: DesignToken.layoutScreenHorizontal,
      padding: const EdgeInsets.all(DesignToken.layoutScreenPaddingXLoose),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [DesignToken.blue700, DesignToken.purpleShade600],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: DesignToken.blue500.withValues(alpha: 0.3),
            blurRadius: 15,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          // Rank Badge
          Container(
            width: 70,
            height: 70,
            decoration: BoxDecoration(
              color: DesignToken.white,
              shape: BoxShape.circle,
              border: Border.all(color: DesignToken.amberShade400, width: 3),
              boxShadow: [
                BoxShadow(
                  color: DesignToken.amber.withValues(alpha: 0.4),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  '#$_currentUserRank',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: DesignToken.blue700,
                  ),
                ),
                Text(
                  AppLocalizations.of(context)!.rankShort,
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: DesignToken.grey500,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(width: DesignToken.layoutScreenPaddingX),

          // User Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  AppLocalizations.of(context)!.yourPosition,
                  style: const TextStyle(
                    color: DesignToken.white70,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                SizedBox(height: DesignToken.spacingXS),
                Text(
                  _getUserDisplayName(),
                  style: const TextStyle(
                    color: DesignToken.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: DesignToken.spacingSM),
                Row(
                  children: [
                    const Icon(Icons.stars, color: DesignToken.amber, size: 18),
                    SizedBox(width: DesignToken.spacingSM),
                    Text(
                      '$_currentUserPoints Points',
                      style: const TextStyle(
                        color: DesignToken.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Trophy Icon
          Container(
            padding: const EdgeInsets.all(DesignToken.paddingMD),
            decoration: BoxDecoration(
              color: DesignToken.white.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.emoji_events,
              color: DesignToken.amber,
              size: 28,
            ),
          ),
        ],
      ),
    );
  }

  // Today's Winner Display Card
  Widget _buildTodaysWinner() {
    final today = DateTime.now();
    final todayStr =
        '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';

    return Padding(
      padding: DesignToken.layoutScreenHorizontal,
      child: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('daily_prize_winners')
            .where('date', isEqualTo: todayStr)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const ShimmerWinnerCard();
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            final theme = Theme.of(context);
            return Container(
              padding: const EdgeInsets.all(DesignToken.layoutScreenPaddingX),
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: DesignToken.secondary.withValues(alpha: 0.2),
                  width: 2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: DesignToken.black.withValues(alpha: 0.05),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  // Trophy Icon
                  Container(
                    padding: const EdgeInsets.all(DesignToken.spacingMD),
                    decoration: BoxDecoration(
                      color: DesignToken.secondary.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.emoji_events_outlined,
                      size: 28,
                      color: DesignToken.secondary.withValues(alpha: 0.6),
                    ),
                  ),
                  SizedBox(width: DesignToken.layoutScreenPaddingX),

                  // No Winner Text
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          AppLocalizations.of(context)!.todaysWinnerLabel,
                          style: AppTextStyles.nunitoBold.copyWith(
                            fontSize: 14,
                            color: DesignToken.secondary,
                          ),
                        ),
                        SizedBox(height: DesignToken.spacingXS / 2),
                        Text(
                          AppLocalizations.of(context)!.noWinnerYetToday,
                          style: AppTextStyles.nunitoRegular.copyWith(
                            fontSize: 14,
                            color: DesignToken.grey600,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Info Icon
                  const Icon(
                    Icons.info_outline,
                    size: 24,
                    color: DesignToken.grey400,
                  ),
                ],
              ),
            );
          }

          final winnerDoc = snapshot.data!.docs.first;
          final winnerData = winnerDoc.data() as Map<String, dynamic>;
          final winnerName = winnerData['carpenterName'] ?? 'Unknown';
          final winnerPhoto = winnerData['carpenterPhoto'] ?? '';
          final prizePoints = winnerData['prizePoints'] ?? 0;
          final winnerId = winnerData['carpenterId'] as String?;

          // Check if current user is the winner (using FutureBuilder for async check)
          return FutureBuilder<String?>(
            future: _sessionService.getUserId(),
            builder: (context, userIdSnapshot) {
              final currentUserId = userIdSnapshot.data;
              final isCurrentUserWinner =
                  currentUserId != null && winnerId == currentUserId;

              // Trigger confetti once per day + user (avoid replay on rebuilds)
              if (isCurrentUserWinner) {
                final confettiKey = '$todayStr|$currentUserId';
                if (_confettiPlayedKey != confettiKey) {
                  _confettiPlayedKey = confettiKey;
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    if (mounted) _confettiController.play();
                  });
                }
              }

              final theme = Theme.of(context);
              return Container(
                padding: const EdgeInsets.all(DesignToken.layoutScreenPaddingX),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isCurrentUserWinner
                        ? DesignToken.amberShade300
                        : DesignToken.secondary.withValues(alpha: 0.3),
                    width: 2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: DesignToken.black.withValues(alpha: 0.08),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    // Trophy Icon
                    Container(
                      padding: const EdgeInsets.all(DesignToken.spacingMD),
                      decoration: BoxDecoration(
                        color: isCurrentUserWinner
                            ? DesignToken.amberShade50
                            : DesignToken.secondary.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.emoji_events,
                        size: 28,
                        color: isCurrentUserWinner
                            ? DesignToken.amberShade700
                            : DesignToken.secondary,
                      ),
                    ),
                    SizedBox(width: DesignToken.layoutCardGapTight),

                    // Profile Image
                    Container(
                      width: 45,
                      height: 45,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: isCurrentUserWinner
                              ? DesignToken.amberShade300
                              : DesignToken.secondary.withValues(alpha: 0.3),
                          width: 2,
                        ),
                      ),
                      child: ClipOval(
                        child: _isValidImageUrl(winnerPhoto)
                            ? Image.network(
                                winnerPhoto,
                                fit: BoxFit.cover,
                                cacheWidth: _imageCacheWidthPx(context, 45),
                                errorBuilder: (context, error, stackTrace) {
                                  return Container(
                                    color: DesignToken.secondary.withValues(
                                      alpha: 0.1,
                                    ),
                                    child: Icon(
                                      Icons.person,
                                      size: 25,
                                      color: DesignToken.secondary,
                                    ),
                                  );
                                },
                              )
                            : Container(
                                color: DesignToken.secondary.withValues(
                                  alpha: 0.1,
                                ),
                                child: Icon(
                                  Icons.person,
                                  size: 25,
                                  color: DesignToken.secondary,
                                ),
                              ),
                      ),
                    ),
                    SizedBox(width: DesignToken.layoutCardGapTight),

                    // Winner Info
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            isCurrentUserWinner
                                ? AppLocalizations.of(context)!.youWonPrize
                                : AppLocalizations.of(
                                    context,
                                  )!.todaysWinnerLabel,
                            style: AppTextStyles.nunitoBold.copyWith(
                              fontSize: 14,
                              color: isCurrentUserWinner
                                  ? DesignToken.amberShade800
                                  : DesignToken.secondary,
                            ),
                          ),
                          SizedBox(height: DesignToken.spacingXS / 2),
                          Text(
                            winnerName,
                            style: AppTextStyles.nunitoSemiBold.copyWith(
                              fontSize: 16,
                              color: theme.colorScheme.onSurface,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),

                    // Points Badge
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: DesignToken.spacingMD,
                        vertical: DesignToken.spacingSM,
                      ),
                      decoration: BoxDecoration(
                        color: DesignToken.amberShade50,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: DesignToken.amberShade200,
                          width: 1,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.monetization_on,
                            size: 16,
                            color: DesignToken.amberShade700,
                          ),
                          SizedBox(width: DesignToken.spacingXS),
                          Text(
                            '$prizePoints',
                            style: AppTextStyles.nunitoBold.copyWith(
                              fontSize: 14,
                              color: DesignToken.amberShade900,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class _HomeProductCategory {
  final String title;
  final IconData icon;
  final Color background;
  final String imageAsset;

  const _HomeProductCategory({
    required this.title,
    required this.icon,
    required this.background,
    required this.imageAsset,
  });
}

class _ProductHeroCardData {
  final String title;
  final String subtitle;
  final String imageAsset;
  final IconData icon;

  const _ProductHeroCardData({
    required this.title,
    required this.subtitle,
    required this.imageAsset,
    required this.icon,
  });
}

class _ProductCategoryCard extends StatelessWidget {
  final _HomeProductCategory category;
  final Color surfaceColor;
  final Color textColor;
  final VoidCallback onTap;

  const _ProductCategoryCard({
    required this.category,
    required this.surfaceColor,
    required this.textColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 140,
        decoration: BoxDecoration(
          color: category.background,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: DesignToken.black.withValues(alpha: 0.04),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          children: [
            // Furniture photo background
            Positioned.fill(
              child: Image.asset(
                category.imageAsset,
                fit: BoxFit.cover,
                cacheWidth: _imageCacheWidthPx(context, 140),
              ),
            ),
            // Dark gradient at bottom for readable text
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black.withValues(alpha: 0.10),
                      Colors.black.withValues(alpha: 0.55),
                    ],
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(DesignToken.spacingMD),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 30,
                    height: 30,
                    decoration: BoxDecoration(
                      color: surfaceColor.withValues(alpha: 0.9),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      category.icon,
                      color: DesignToken.primary,
                      size: 18,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    category.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.nunitoSemiBold.copyWith(
                      color: DesignToken.white,
                      fontSize: DesignToken.fontSizeMD,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
