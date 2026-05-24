import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:package_info_plus/package_info_plus.dart';

import 'package:balaji_points/core/design/app_animations.dart';
import 'package:balaji_points/core/design/app_colors.dart';
import 'package:balaji_points/core/design/app_radius.dart';
import 'package:balaji_points/core/design/app_spacing.dart';
import 'package:balaji_points/core/design/app_typography.dart';
import 'package:balaji_points/core/layout/carpenter_shell_layout.dart';
import 'package:balaji_points/core/logger.dart';
import 'package:balaji_points/l10n/app_localizations.dart';
import 'package:balaji_points/providers/home_provider.dart';
import 'package:balaji_points/presentation/screens/carpenter/home/widgets/complete_profile_card.dart';
import 'package:balaji_points/presentation/widgets/carpenter/carpenter_top_nav_bar.dart';
import 'package:balaji_points/presentation/widgets/carpenter/offers_carousel.dart';
import 'package:balaji_points/presentation/widgets/shared/shimmer_loading.dart';
import 'package:balaji_points/presentation/widgets/carpenter/top_carpenters_display.dart';
import 'package:balaji_points/presentation/widgets/carpenter/top_carpenters_list.dart';
import 'package:balaji_points/services/notifications/fcm_service.dart';
import 'package:balaji_points/services/auth/session_service.dart';

int _imageCacheWidthPx(BuildContext context, double logicalWidth) {
  final dpr = MediaQuery.devicePixelRatioOf(context);
  return (logicalWidth * dpr).round().clamp(120, 2048);
}

// ---------------------------------------------------------------------------
// Data classes (unchanged)
// ---------------------------------------------------------------------------

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

// ---------------------------------------------------------------------------
// HomePage
// ---------------------------------------------------------------------------

class HomePage extends ConsumerStatefulWidget {
  const HomePage({super.key});

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage>
    with WidgetsBindingObserver, AutomaticKeepAliveClientMixin<HomePage> {
  final _fcmService = FCMService();
  final _sessionService = SessionService();

  String _appVersion = '';
  bool _greetingIconPressed = false;
  String? _confettiPlayedKey;

  late ConfettiController _confettiController;
  late final PageController _productHeroPageController;
  int _currentProductHeroPage = 0;

  static const List<_HomeProductCategory> _categories = [
    _HomeProductCategory(
      title: 'Bedroom',
      icon: Icons.bed_rounded,
      background: Color(0xFFF5F0FF),
      imageAsset: 'assets/images/furniture/luxurious_lifestyle.jpeg',
    ),
    _HomeProductCategory(
      title: 'Kitchen',
      icon: Icons.kitchen_rounded,
      background: AppColors.orangeBackground,
      imageAsset: 'assets/images/furniture/brown_kitchen_cabinet.jpeg',
    ),
    _HomeProductCategory(
      title: 'Living Room',
      icon: Icons.chair_rounded,
      background: Color(0xFFE3F2FD),
      imageAsset: 'assets/images/furniture/furniture_6.jpeg',
    ),
    _HomeProductCategory(
      title: 'Wardrobe',
      icon: Icons.checkroom_rounded,
      background: Color(0xFFE8F5E9),
      imageAsset: 'assets/images/furniture/furniture_10.jpeg',
    ),
    _HomeProductCategory(
      title: 'Office',
      icon: Icons.workspaces_rounded,
      background: Color(0xFFE8F0FE),
      imageAsset: 'assets/images/furniture/home_office.jpeg',
    ),
    _HomeProductCategory(
      title: 'Bathroom',
      icon: Icons.bathtub_rounded,
      background: Color(0xFFF3E5F5),
      imageAsset: 'assets/images/furniture/sage_green_kitchen.jpeg',
    ),
  ];

  static const List<_ProductHeroCardData> _heroCards = [
    _ProductHeroCardData(
      title: 'Surfaces that\nradiate luxury',
      subtitle: 'Decorative laminates,\nveneers and acrylic panels.',
      imageAsset: 'assets/images/furniture/brown_kitchen_cabinet.jpeg',
      icon: Icons.layers_rounded,
    ),
    _ProductHeroCardData(
      title: 'Bedroom that feels premium',
      subtitle: 'Warm finishes for\ncozy master bedrooms.',
      imageAsset: 'assets/images/furniture/luxurious_lifestyle.jpeg',
      icon: Icons.bed_rounded,
    ),
    _ProductHeroCardData(
      title: 'Kitchen that inspires',
      subtitle: 'Modern finishes for\npremium modular kitchens.',
      imageAsset: 'assets/images/furniture/sage_green_kitchen.jpeg',
      icon: Icons.kitchen_rounded,
    ),
    _ProductHeroCardData(
      title: 'Living room that welcomes',
      subtitle: 'TV units & wall panels\nfor family time.',
      imageAsset: 'assets/images/furniture/furniture_6.jpeg',
      icon: Icons.weekend_rounded,
    ),
    _ProductHeroCardData(
      title: 'Office that boosts focus',
      subtitle: 'Create productive workspaces\nwith designer surfaces.',
      imageAsset: 'assets/images/furniture/home_office.jpeg',
      icon: Icons.chair_rounded,
    ),
  ];

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _confettiController = ConfettiController(duration: const Duration(seconds: 3));
    _productHeroPageController = PageController(viewportFraction: 0.9);
    _loadAppVersion();
  }

  Future<void> _loadAppVersion() async {
    try {
      final info = await PackageInfo.fromPlatform();
      if (!mounted) return;
      setState(() => _appVersion = 'Version ${info.version} (${info.buildNumber})');
    } catch (_) {
      if (!mounted) return;
      setState(() => _appVersion = 'Version 1.0.0');
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      ref.read(homeProvider.notifier).refresh();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _confettiController.dispose();
    _productHeroPageController.dispose();
    super.dispose();
  }

  // ---------------------------------------------------------------------------
  // Build
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    super.build(context);

    final homeState = ref.watch(homeProvider);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final mq = MediaQuery.of(context);
    final canvas = isDark ? theme.colorScheme.surface : AppColors.carpenterAppBackground;
    final bottomPadding = CarpenterShellLayout.bottomPaddingForScrollView(mq);

    final top3 = homeState.topCarpenters.take(3).toList();

    // Confetti on rank #1
    final topKey = homeState.topCarpenters.isNotEmpty ? homeState.topCarpenters.first.userId : null;
    if (topKey != null && topKey == homeState.userDocId && topKey != _confettiPlayedKey) {
      _confettiPlayedKey = topKey;
      WidgetsBinding.instance.addPostFrameCallback((_) => _confettiController.play());
    }

    AppLogger.data('Home build · loading=${homeState.loading}');

    return Scaffold(
      backgroundColor: canvas,
      drawer: _buildDrawer(context, homeState, isDark, theme),
      appBar: _buildAppBar(context, homeState, isDark, mq),
      body: Stack(
        children: [
          RefreshIndicator(
            onRefresh: () => ref.read(homeProvider.notifier).refresh(),
            color: AppColors.lightPrimary,
            backgroundColor: canvas,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: EdgeInsets.only(bottom: bottomPadding),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: AppSpacing.sm),

                  // Hero card
                  RepaintBoundary(
                    child: homeState.loading
                        ? _shimmerHeroCard()
                        : _buildHeroCard(context, homeState, isDark, theme),
                  ).fadeIn(),

                  const SizedBox(height: AppSpacing.md),

                  // Complete profile card
                  if (!homeState.loading && !homeState.isProfileComplete) ...[
                    const RepaintBoundary(child: CompleteProfileCard())
                        .enterCard(delay: AppAnimations.stagger(1)),
                    const SizedBox(height: AppSpacing.sectionGap),
                  ],

                  // Offers
                  Padding(
                    padding: AppSpacing.screenHorizontal,
                    child: Text(
                      AppLocalizations.of(context)!.latestOffers,
                      style: AppTypography.h5(
                        color: isDark ? theme.colorScheme.onSurface : AppColors.lightTextPrimary,
                      ),
                    ),
                  ).fadeIn(delay: AppAnimations.stagger(1)),
                  const SizedBox(height: AppSpacing.xs),
                  RepaintBoundary(
                    child: homeState.offersLoading
                        ? const ShimmerOfferCard()
                        : OffersCarousel(offers: homeState.offers),
                  ).fadeIn(delay: AppAnimations.stagger(2)),

                  const SizedBox(height: AppSpacing.sectionGap),

                  // Products
                  RepaintBoundary(
                    child: _buildProductsSection(context, isDark, theme),
                  ).enterCard(delay: AppAnimations.stagger(3)),

                  const SizedBox(height: AppSpacing.sectionGap),

                  // Rankings
                  _buildRankingsSection(context, homeState, isDark, theme, top3)
                      .enterCard(delay: AppAnimations.stagger(4)),

                  const SizedBox(height: AppSpacing.sectionGap),
                ],
              ),
            ),
          ),

          // Confetti
          Align(
            alignment: Alignment.topCenter,
            child: RepaintBoundary(
              child: IgnorePointer(
                child: ConfettiWidget(
                  confettiController: _confettiController,
                  blastDirection: pi / 2,
                  maxBlastForce: 5,
                  minBlastForce: 2,
                  emissionFrequency: 0.05,
                  numberOfParticles: 20,
                  gravity: 0.3,
                  shouldLoop: false,
                  colors: const [
                    AppColors.amber,
                    AppColors.orange,
                    AppColors.error,
                    AppColors.lightSecondary,
                    AppColors.lightPrimary,
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // AppBar
  // ---------------------------------------------------------------------------

  PreferredSizeWidget _buildAppBar(
    BuildContext context,
    HomeState homeState,
    bool isDark,
    MediaQueryData mq,
  ) {
    final fg = isDark ? AppColors.white : AppColors.lightTextPrimary;
    final fgMuted = fg.withValues(alpha: 0.70);
    final l10n = AppLocalizations.of(context)!;

    return CarpenterTopNavBar(
      topInset: CarpenterShellLayout.topInset(mq),
      title: 'Balaji Points',
      backgroundColor: isDark ? const Color(0xFF0F1115) : AppColors.carpenterAppBackground,
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
            errorBuilder: (_, __, ___) => Icon(Icons.storefront_rounded, color: fg, size: 24),
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
                  style: AppTypography.bodyLarge(color: fg).copyWith(fontWeight: FontWeight.w700),
                ),
                Text(
                  '${l10n.companyName} · ${l10n.homeStoreBranch}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.bodySmall(color: fgMuted),
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
              if (homeState.cartCount > 0)
                Positioned(
                  top: -4,
                  right: -4,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: AppColors.error,
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      homeState.cartCount > 99 ? '99+' : '${homeState.cartCount}',
                      style: const TextStyle(color: AppColors.white, fontSize: 9, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // Hero card
  // ---------------------------------------------------------------------------

  Widget _shimmerHeroCard() {
    return Container(
      margin: AppSpacing.screenHorizontal,
      height: 140,
      decoration: BoxDecoration(
        color: AppColors.grey100,
        borderRadius: AppRadius.forCard,
      ),
    ).animate(onPlay: (c) => c.repeat()).shimmer(duration: 1200.ms);
  }

  Widget _buildHeroCard(BuildContext context, HomeState homeState, bool isDark, ThemeData theme) {
    final l10n = AppLocalizations.of(context)!;
    final hour = DateTime.now().hour;
    final isDayTime = hour >= 6 && hour < 18;
    final greeting = hour < 12
        ? l10n.goodMorningGreeting
        : (hour < 17 ? l10n.goodAfternoonGreeting : l10n.goodEveningGreeting);

    final profileImage = homeState.profileImage;
    final hasValidImage = profileImage != null &&
        (profileImage.startsWith('http://') || profileImage.startsWith('https://'));
    final nf = NumberFormat.decimalPattern();

    if (!isDark) {
      return Container(
        margin: AppSpacing.screenHorizontal,
        padding: const EdgeInsets.all(AppSpacing.cardPadding),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: AppRadius.forCard,
          border: Border.all(color: AppColors.grey200),
          boxShadow: [
            BoxShadow(
              color: AppColors.lightPrimary.withValues(alpha: 0.06),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.grey200),
                  ),
                  child: CircleAvatar(
                    radius: 17,
                    backgroundColor: AppColors.grey100,
                    backgroundImage: hasValidImage ? NetworkImage(profileImage) : null,
                    child: !hasValidImage
                        ? Icon(Icons.person, size: 22, color: AppColors.lightTextSecondary)
                        : null,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text.rich(
                    TextSpan(
                      style: AppTypography.bodySmall(color: AppColors.lightTextSecondary),
                      children: [
                        TextSpan(text: '$greeting,\n'),
                        TextSpan(
                          text: homeState.displayName,
                          style: AppTypography.bodyLarge(color: AppColors.lightTextPrimary)
                              .copyWith(fontWeight: FontWeight.w700, height: 1.15),
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
                  onPressedChanged: (v) => setState(() => _greetingIconPressed = v),
                  useLightStyle: true,
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.xs),
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                _PointsCoin(onDark: false),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        l10n.totalPointsLabel,
                        style: AppTypography.labelSmall(color: AppColors.lightTextSecondary),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        nf.format(homeState.points),
                        style: AppTypography.pointsHero(color: AppColors.lightTextPrimary),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.xs),
            Row(
              children: [
                Icon(Icons.star_rounded, color: AppColors.amber.withValues(alpha: 0.88), size: 18),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    '${homeState.tier} ${l10n.homeTierSuffix}',
                    style: AppTypography.bodySmall(color: AppColors.lightTextSecondary),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Icon(
                  Icons.account_balance_wallet_outlined,
                  size: 16,
                  color: AppColors.lightTextSecondary.withValues(alpha: 0.55),
                ),
              ],
            ),
          ],
        ),
      );
    }

    // Dark mode — gradient card
    return Container(
      margin: AppSpacing.screenHorizontal,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.darkPrimary, AppColors.darkSecondary],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: AppRadius.forCard,
        border: Border.all(color: AppColors.white.withValues(alpha: 0.18)),
        boxShadow: [
          BoxShadow(
            color: AppColors.darkPrimary.withValues(alpha: 0.22),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.cardPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.white.withValues(alpha: 0.45)),
                  ),
                  child: CircleAvatar(
                    radius: 17,
                    backgroundColor: AppColors.white.withValues(alpha: 0.18),
                    backgroundImage: hasValidImage ? NetworkImage(profileImage) : null,
                    child: !hasValidImage
                        ? const Icon(Icons.person, size: 22, color: AppColors.white)
                        : null,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text.rich(
                    TextSpan(
                      style: AppTypography.bodySmall(color: AppColors.white.withValues(alpha: 0.82)),
                      children: [
                        TextSpan(text: '$greeting,\n'),
                        TextSpan(
                          text: homeState.displayName,
                          style: AppTypography.bodyLarge(color: AppColors.white)
                              .copyWith(fontWeight: FontWeight.w700, height: 1.15),
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
                  onPressedChanged: (v) => setState(() => _greetingIconPressed = v),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.xs),
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                _PointsCoin(onDark: true),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        l10n.totalPointsLabel,
                        style: AppTypography.labelSmall(color: AppColors.white.withValues(alpha: 0.78)),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        nf.format(homeState.points),
                        style: AppTypography.pointsHero(color: AppColors.white),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.xs),
            Row(
              children: [
                const Icon(Icons.star_rounded, color: AppColors.amber, size: 18),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    '${homeState.tier} ${l10n.homeTierSuffix}',
                    style: AppTypography.bodySmall(color: AppColors.white.withValues(alpha: 0.92)),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Icon(
                  Icons.account_balance_wallet_outlined,
                  size: 16,
                  color: AppColors.white.withValues(alpha: 0.55),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Products section
  // ---------------------------------------------------------------------------

  Widget _buildProductsSection(BuildContext context, bool isDark, ThemeData theme) {
    final l10n = AppLocalizations.of(context)!;
    final titleColor = isDark ? AppColors.white : AppColors.lightTextPrimary;
    final subtitleColor = isDark ? AppColors.white.withValues(alpha: 0.72) : AppColors.lightTextSecondary;
    final surfaceColor = theme.colorScheme.surface;
    final heroDecodeW = MediaQuery.sizeOf(context).width * 0.92;
    final dotActive = isDark ? AppColors.white.withValues(alpha: 0.95) : AppColors.lightPrimary;
    final dotInactive = isDark
        ? AppColors.white.withValues(alpha: 0.45)
        : AppColors.lightTextSecondary.withValues(alpha: 0.35);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: AppSpacing.screenHorizontal,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        colors: [AppColors.tierGold, Color(0xFF8B5E3C)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                    child: const Icon(Icons.layers_rounded, size: 18, color: Color(0xFF4E2C0A)),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.homeBrowseProductsTitle,
                        style: AppTypography.bodyMedium(color: titleColor)
                            .copyWith(fontWeight: FontWeight.w600),
                      ),
                      Text(
                        l10n.homeBrowseProductsSubtitle,
                        style: AppTypography.bodySmall(color: subtitleColor),
                      ),
                    ],
                  ),
                ],
              ),
              TextButton(
                onPressed: () => context.push('/products'),
                child: Text(
                  l10n.viewAll,
                  style: AppTypography.bodySmall(color: AppColors.lightPrimary),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        SizedBox(
          height: 190,
          child: PageView.builder(
            controller: _productHeroPageController,
            itemCount: _heroCards.length,
            onPageChanged: (i) => setState(() => _currentProductHeroPage = i),
            itemBuilder: (context, index) {
              final hero = _heroCards[index];
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF4E2C0A).withValues(alpha: 0.18),
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
                                AppColors.black.withValues(alpha: 0.10),
                                AppColors.black.withValues(alpha: 0.65),
                              ],
                            ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(AppSpacing.cardPadding),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                width: 34,
                                height: 34,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: AppColors.white.withValues(alpha: 0.92),
                                ),
                                child: Icon(hero.icon, size: 20, color: const Color(0xFF4E2C0A)),
                              ),
                              const SizedBox(height: AppSpacing.md),
                              Text(
                                hero.title,
                                style: AppTypography.bodyLarge(color: AppColors.white)
                                    .copyWith(fontWeight: FontWeight.w700),
                              ),
                              const SizedBox(height: AppSpacing.sm),
                              Text(
                                hero.subtitle,
                                style: AppTypography.bodySmall(
                                  color: AppColors.white.withValues(alpha: 0.92),
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
        const SizedBox(height: AppSpacing.sm),
        Center(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: List.generate(_heroCards.length, (i) {
              final isActive = i == _currentProductHeroPage;
              return AnimatedContainer(
                duration: 200.ms,
                margin: const EdgeInsets.symmetric(horizontal: 3),
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
        const SizedBox(height: AppSpacing.xs),
        SizedBox(
          height: 124,
          child: ListView.separated(
            padding: AppSpacing.screenHorizontal,
            scrollDirection: Axis.horizontal,
            itemCount: _categories.length,
            separatorBuilder: (_, __) => const SizedBox(width: AppSpacing.xs),
            itemBuilder: (context, index) {
              final cat = _categories[index];
              return _ProductCategoryCard(
                category: cat,
                surfaceColor: surfaceColor,
                textColor: titleColor,
                onTap: () => context.push(
                  '/products?category=${Uri.encodeComponent(cat.title)}',
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // Rankings section
  // ---------------------------------------------------------------------------

  Widget _buildRankingsSection(
    BuildContext context,
    HomeState homeState,
    bool isDark,
    ThemeData theme,
    List<CarpenterRank> top3,
  ) {
    final l10n = AppLocalizations.of(context)!;
    final titleColor = isDark ? theme.colorScheme.onSurface : AppColors.lightTextPrimary;
    final subtitleColor = isDark
        ? theme.colorScheme.onSurface.withValues(alpha: 0.65)
        : AppColors.lightTextSecondary;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: AppSpacing.screenHorizontal,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.homeRankingsSectionTitle,
                style: AppTypography.bodyLarge(color: titleColor)
                    .copyWith(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                l10n.homeRankingsSectionSubtitle,
                style: AppTypography.bodySmall(color: subtitleColor),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.xs),

        // Today's winner
        RepaintBoundary(child: _buildTodaysWinner(context, theme, isDark)),
        const SizedBox(height: AppSpacing.md),

        // Current user position
        if (homeState.userRank != null)
          RepaintBoundary(
            child: _buildUserPositionCard(context, homeState),
          ),
        if (homeState.userRank != null) const SizedBox(height: AppSpacing.md),

        // Top carpenters
        if (homeState.rankingsLoading)
          const RepaintBoundary(child: ShimmerTopCarpenters())
        else if (homeState.topCarpenters.isNotEmpty) ...[
          RepaintBoundary(
            child: Container(
              margin: AppSpacing.screenHorizontal,
              padding: const EdgeInsets.all(AppSpacing.cardPadding),
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                borderRadius: AppRadius.forCard,
                border: isDark ? null : Border.all(color: AppColors.grey200),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.black.withValues(alpha: 0.05),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: TopCarpentersDisplay(
                topCarpenters: top3,
                currentUser: homeState.topCarpenters.cast<CarpenterRank?>().firstWhere(
                  (c) => c?.userId == homeState.userDocId,
                  orElse: () => null,
                ),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          RepaintBoundary(
            child: Padding(
              padding: AppSpacing.screenHorizontal,
              child: TopCarpentersList(
                carpenters: homeState.topCarpenters,
                showViewAll: false,
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildTodaysWinner(BuildContext context, ThemeData theme, bool isDark) {
    final today = DateTime.now();
    final todayStr =
        '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';

    return Padding(
      padding: AppSpacing.screenHorizontal,
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
            return Container(
              padding: const EdgeInsets.all(AppSpacing.cardPadding),
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: AppColors.lightSecondary.withValues(alpha: 0.2),
                  width: 2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.black.withValues(alpha: 0.05),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    decoration: BoxDecoration(
                      color: AppColors.lightSecondary.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.emoji_events_outlined,
                      size: 28,
                      color: AppColors.lightSecondary.withValues(alpha: 0.6),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.cardPadding),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          AppLocalizations.of(context)!.todaysWinnerLabel,
                          style: AppTypography.bodyMedium(color: AppColors.lightSecondary)
                              .copyWith(fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          AppLocalizations.of(context)!.noWinnerYetToday,
                          style: AppTypography.bodySmall(color: AppColors.grey600),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          }

          final winnerData = snapshot.data!.docs.first.data() as Map<String, dynamic>;
          final winnerName = winnerData['userName'] as String? ?? 'Winner';
          final winnerPoints = winnerData['points'] as int? ?? 0;
          final winnerImage = winnerData['userImage'] as String?;
          final hasImg = winnerImage != null &&
              (winnerImage.startsWith('http://') || winnerImage.startsWith('https://'));

          return Container(
            padding: const EdgeInsets.all(AppSpacing.cardPadding),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppColors.tierGold, Color(0xFF8B5E3C)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: AppColors.tierGold.withValues(alpha: 0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 26,
                  backgroundImage: hasImg ? NetworkImage(winnerImage) : null,
                  child: !hasImg ? const Icon(Icons.person, color: AppColors.white) : null,
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        AppLocalizations.of(context)!.todaysWinnerLabel,
                        style: AppTypography.labelSmall(color: AppColors.white.withValues(alpha: 0.85)),
                      ),
                      Text(
                        winnerName,
                        style: AppTypography.bodyLarge(color: AppColors.white)
                            .copyWith(fontWeight: FontWeight.w700),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        '$winnerPoints pts',
                        style: AppTypography.bodySmall(color: AppColors.white.withValues(alpha: 0.9)),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.emoji_events, color: AppColors.white, size: 32),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildUserPositionCard(BuildContext context, HomeState homeState) {
    return Container(
      margin: AppSpacing.screenHorizontal,
      padding: const EdgeInsets.all(AppSpacing.cardPadding),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1A3B8F), Color(0xFF6A3FBF)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1A3B8F).withValues(alpha: 0.3),
            blurRadius: 15,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 70,
            height: 70,
            decoration: BoxDecoration(
              color: AppColors.white,
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.amber, width: 3),
              boxShadow: [
                BoxShadow(
                  color: AppColors.amber.withValues(alpha: 0.4),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  '#${homeState.userRank}',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1A3B8F),
                  ),
                ),
                Text(
                  AppLocalizations.of(context)!.rankShort,
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: AppColors.grey500,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.cardPadding),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  AppLocalizations.of(context)!.yourPosition,
                  style: AppTypography.labelSmall(color: AppColors.white.withValues(alpha: 0.75)),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  homeState.displayName,
                  style: AppTypography.bodyLarge(color: AppColors.white)
                      .copyWith(fontWeight: FontWeight.w700),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: AppSpacing.sm),
                Row(
                  children: [
                    const Icon(Icons.stars, color: AppColors.amber, size: 18),
                    const SizedBox(width: AppSpacing.sm),
                    Text(
                      '${homeState.points} Points',
                      style: AppTypography.bodyMedium(color: AppColors.white)
                          .copyWith(fontWeight: FontWeight.w700),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: AppColors.white.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.emoji_events, color: AppColors.amber, size: 28),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Drawer
  // ---------------------------------------------------------------------------

  Drawer _buildDrawer(BuildContext context, HomeState homeState, bool isDark, ThemeData theme) {
    final mq = MediaQuery.of(context);
    final topInset = mq.padding.top;
    final drawerFooterBottom = CarpenterShellLayout.chromeHeight(mq) + AppSpacing.sm;
    final titleColor = isDark ? AppColors.white : AppColors.lightTextPrimary;
    final subtitleColor = isDark
        ? AppColors.white.withValues(alpha: 0.80)
        : AppColors.lightTextPrimary.withValues(alpha: 0.70);

    final phone = homeState.userData?['phone'] as String? ?? '';
    final profileImage = homeState.profileImage;
    final hasImg = profileImage != null &&
        (profileImage.startsWith('http://') || profileImage.startsWith('https://'));
    final l10n = AppLocalizations.of(context)!;

    final drawerBase = theme.colorScheme.surface;
    final drawerTintSoft = isDark
        ? AppColors.darkPrimary.withValues(alpha: 0.10)
        : AppColors.lightSecondary.withValues(alpha: 0.06);
    final drawerTintAccent = isDark
        ? const Color(0xFF2563EB).withValues(alpha: 0.16)
        : AppColors.amber.withValues(alpha: 0.30);

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
              // Header
              Container(
                padding: EdgeInsets.fromLTRB(20, 20 + topInset, 20, 20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      isDark
                          ? const Color(0xFF2563EB).withValues(alpha: 0.6)
                          : AppColors.lightSecondary.withValues(alpha: 0.15),
                      isDark
                          ? const Color(0xFF7C3AED).withValues(alpha: 0.7)
                          : AppColors.amber.withValues(alpha: 0.9),
                    ],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.black.withValues(alpha: 0.15),
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
                        border: Border.all(color: AppColors.white.withValues(alpha: 0.9), width: 2),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.black.withValues(alpha: 0.25),
                            blurRadius: 12,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: ClipOval(
                        child: hasImg
                            ? Image.network(
                                profileImage,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => const ColoredBox(
                                  color: AppColors.white,
                                  child: Icon(Icons.person, color: AppColors.lightPrimary),
                                ),
                              )
                            : const ColoredBox(
                                color: AppColors.white,
                                child: Icon(Icons.person, color: AppColors.lightPrimary),
                              ),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.cardPadding),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            homeState.displayName,
                            style: AppTypography.bodyLarge(color: AppColors.white)
                                .copyWith(fontWeight: FontWeight.w600),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: AppSpacing.xs),
                          if (phone.isNotEmpty)
                            Text(
                              phone,
                              style: AppTypography.bodySmall(
                                  color: AppColors.white.withValues(alpha: 0.85)),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.xs),

              // Nav items
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                  children: [
                    _DrawerSectionLabel(label: l10n.drawerSectionMainNav, color: subtitleColor),
                    _DrawerNavItem(
                      icon: Icons.home_rounded,
                      label: l10n.home,
                      titleColor: titleColor,
                      onTap: () { Navigator.of(context).pop(); context.go('/'); },
                    ),
                    _DrawerNavItem(
                      icon: Icons.account_balance_wallet_outlined,
                      label: l10n.earn,
                      titleColor: titleColor,
                      onTap: () { Navigator.of(context).pop(); context.go('/wallet'); },
                    ),
                    _DrawerNavItem(
                      icon: Icons.notifications_outlined,
                      label: l10n.notifications,
                      titleColor: titleColor,
                      onTap: () { Navigator.of(context).pop(); context.go('/notifications'); },
                    ),
                    _DrawerNavItem(
                      icon: Icons.person_outline,
                      label: l10n.profile,
                      titleColor: titleColor,
                      onTap: () { Navigator.of(context).pop(); context.go('/profile'); },
                    ),
                    Padding(
                      padding: AppSpacing.screenHorizontal,
                      child: Divider(height: 24, color: subtitleColor.withValues(alpha: 0.22)),
                    ),
                    _DrawerSectionLabel(label: l10n.drawerSectionMore, color: subtitleColor),
                    _DrawerNavItem(
                      icon: Icons.layers_rounded,
                      label: l10n.drawerProductsTitle,
                      subtitle: l10n.drawerProductsSubtitle,
                      titleColor: titleColor,
                      subtitleColor: subtitleColor,
                      onTap: () { Navigator.of(context).pop(); context.push('/products'); },
                    ),
                    _DrawerNavItem(
                      icon: Icons.shopping_cart_outlined,
                      label: l10n.drawerCart,
                      titleColor: titleColor,
                      onTap: () { Navigator.of(context).pop(); context.push('/cart'); },
                    ),
                    _DrawerNavItem(
                      icon: Icons.receipt_long_rounded,
                      label: l10n.myOrders,
                      titleColor: titleColor,
                      onTap: () { Navigator.of(context).pop(); context.push('/orders'); },
                    ),
                    _DrawerNavItem(
                      icon: Icons.info_outline_rounded,
                      label: l10n.aboutUs,
                      subtitle: l10n.aboutUsMenuSubtitle,
                      titleColor: titleColor,
                      subtitleColor: subtitleColor,
                      onTap: () { Navigator.of(context).pop(); context.push('/about-us'); },
                    ),
                  ],
                ),
              ),

              // Footer
              Padding(
                padding: AppSpacing.screenHorizontal,
                child: const Divider(),
              ),
              Padding(
                padding: EdgeInsets.fromLTRB(
                  AppSpacing.cardPadding,
                  AppSpacing.sm,
                  AppSpacing.cardPadding,
                  drawerFooterBottom,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (_appVersion.isNotEmpty) ...[
                      Center(
                        child: Text(
                          _appVersion,
                          style: AppTypography.labelSmall(
                            color: AppColors.lightTextSecondary.withValues(alpha: 0.5),
                          ),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.md),
                    ],
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.error,
                        foregroundColor: AppColors.white,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      icon: const Icon(Icons.logout_rounded, size: 22),
                      label: Text(
                        l10n.logout,
                        style: AppTypography.bodyMedium(color: AppColors.white)
                            .copyWith(fontWeight: FontWeight.w700),
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

  // ---------------------------------------------------------------------------
  // Logout
  // ---------------------------------------------------------------------------

  Future<void> _handleLogout(BuildContext context) async {
    final l10n = AppLocalizations.of(context)!;
    final shouldLogout = await showDialog<bool>(
      context: context,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        insetPadding: const EdgeInsets.symmetric(horizontal: 32, vertical: 32),
        backgroundColor: Theme.of(ctx).colorScheme.surface,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(32, 32, 32, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.error.withValues(alpha: 0.08),
                ),
                child: const Icon(Icons.logout_rounded, color: AppColors.error, size: 26),
              ),
              const SizedBox(height: 20),
              Text(
                l10n.logout,
                style: AppTypography.h4(color: AppColors.lightTextPrimary),
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                l10n.logoutConfirmation,
                textAlign: TextAlign.center,
                style: AppTypography.bodyMedium(
                    color: AppColors.lightTextPrimary.withValues(alpha: 0.75)),
              ),
              const SizedBox(height: AppSpacing.sectionGap),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(ctx).pop(false),
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: AppColors.grey500.withValues(alpha: 0.8)),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: Text(
                        l10n.no,
                        style: AppTypography.bodyMedium(color: AppColors.lightTextPrimary),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => Navigator.of(ctx).pop(true),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.error,
                        foregroundColor: AppColors.white,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      child: Text(
                        l10n.yes,
                        style: AppTypography.bodyMedium(color: AppColors.white)
                            .copyWith(fontWeight: FontWeight.w600),
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
        if (context.mounted) context.go('/login');
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('${l10n.logoutFailed}: $e'),
            backgroundColor: AppColors.error,
          ));
        }
      }
    }
  }
}

// ---------------------------------------------------------------------------
// Private sub-widgets
// ---------------------------------------------------------------------------

class _SunMoonBadge extends StatelessWidget {
  final bool isDayTime;
  final bool pressed;
  final ValueChanged<bool> onPressedChanged;
  final bool useLightStyle;

  const _SunMoonBadge({
    required this.isDayTime,
    required this.pressed,
    required this.onPressedChanged,
    this.useLightStyle = false,
  });

  @override
  Widget build(BuildContext context) {
    final icon = isDayTime ? Icons.wb_sunny_outlined : Icons.nightlight_round;

    if (useLightStyle) {
      return GestureDetector(
        onTapDown: (_) => onPressedChanged(true),
        onTapUp: (_) => onPressedChanged(false),
        onTapCancel: () => onPressedChanged(false),
        child: AnimatedScale(
          duration: 200.ms,
          scale: pressed ? 0.9 : 1.0,
          child: Container(
            padding: const EdgeInsets.all(10),
            decoration: const BoxDecoration(
              color: Color(0xFFE8F0FE),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: AppColors.lightTextSecondary, size: 20),
          ),
        ),
      );
    }

    return GestureDetector(
      onTapDown: (_) => onPressedChanged(true),
      onTapUp: (_) => onPressedChanged(false),
      onTapCancel: () => onPressedChanged(false),
      child: AnimatedScale(
        duration: 200.ms,
        scale: pressed ? 0.9 : 1.0,
        child: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: isDayTime
                  ? [const Color(0xFFFCD34D), AppColors.warning]
                  : [const Color(0xFF2563EB), const Color(0xFF7C3AED)],
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.black.withValues(alpha: 0.15),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Icon(icon, color: AppColors.white, size: 22),
        ),
      ),
    );
  }
}

class _PointsCoin extends StatelessWidget {
  final bool onDark;
  const _PointsCoin({required this.onDark});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 46,
      height: 46,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          colors: onDark
              ? [const Color(0xFFFCD34D), const Color(0xFF92400E)]
              : [const Color(0xFFFDE68A), const Color(0xFFB45309)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(
          color: AppColors.white.withValues(alpha: onDark ? 0.4 : 0.55),
          width: 1.25,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF92400E).withValues(alpha: onDark ? 0.22 : 0.12),
            blurRadius: onDark ? 8 : 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      alignment: Alignment.center,
      child: Icon(
        Icons.toll_rounded,
        size: 26,
        color: AppColors.white.withValues(alpha: 0.95),
      ),
    );
  }
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
        width: 84,
        padding: const EdgeInsets.all(AppSpacing.sm),
        decoration: BoxDecoration(
          color: surfaceColor,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: AppColors.black.withValues(alpha: 0.06),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: category.background,
                borderRadius: BorderRadius.circular(12),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.asset(
                  category.imageAsset,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Icon(category.icon, color: AppColors.lightPrimary),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              category.title,
              style: AppTypography.labelSmall(color: textColor),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

class _DrawerSectionLabel extends StatelessWidget {
  final String label;
  final Color color;
  const _DrawerSectionLabel({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, AppSpacing.md, 20, AppSpacing.xs),
      child: Text(
        label,
        style: AppTypography.labelSmall(color: color)
            .copyWith(letterSpacing: 0.35, fontWeight: FontWeight.w600),
      ),
    );
  }
}

class _DrawerNavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String? subtitle;
  final Color titleColor;
  final Color? subtitleColor;
  final VoidCallback onTap;

  const _DrawerNavItem({
    required this.icon,
    required this.label,
    required this.titleColor,
    required this.onTap,
    this.subtitle,
    this.subtitleColor,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: AppColors.lightSecondary),
      title: Text(label, style: AppTypography.bodyMedium(color: titleColor)),
      subtitle: subtitle != null
          ? Text(
              subtitle!,
              style: AppTypography.bodySmall(color: subtitleColor ?? titleColor.withValues(alpha: 0.65)),
            )
          : null,
      onTap: onTap,
    );
  }
}
