import 'package:balaji_points/core/design/app_radius.dart';
import 'dart:math';

import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:package_info_plus/package_info_plus.dart';

import 'package:balaji_points/core/design/app_animations.dart';
import 'package:balaji_points/core/design/app_colors.dart';
import 'package:balaji_points/core/design/app_spacing.dart';
import 'package:balaji_points/core/design/app_typography.dart';
import 'package:balaji_points/core/layout/carpenter_shell_layout.dart';
import 'package:balaji_points/core/logger.dart';
import 'package:balaji_points/l10n/app_localizations.dart';
import 'package:balaji_points/providers/home_provider.dart';
import 'package:balaji_points/providers/theme_provider.dart';
import 'package:balaji_points/presentation/screens/carpenter/home/widgets/home_drawer.dart';
import 'package:balaji_points/presentation/screens/carpenter/home/widgets/home_feature_highlights.dart';
import 'package:balaji_points/presentation/screens/carpenter/home/widgets/home_hero_card.dart';
import 'package:balaji_points/presentation/screens/carpenter/home/widgets/home_product_categories.dart';
import 'package:balaji_points/presentation/screens/carpenter/home/widgets/home_quick_actions.dart';
import 'package:balaji_points/presentation/screens/carpenter/home/widgets/home_top_carpenters.dart';
import 'package:balaji_points/presentation/widgets/carpenter/carpenter_top_nav_bar.dart';
import 'package:balaji_points/presentation/widgets/carpenter/offers_carousel.dart';
import 'package:balaji_points/presentation/widgets/shared/app_button.dart';
import 'package:balaji_points/presentation/widgets/shared/app_text.dart';
import 'package:balaji_points/presentation/widgets/shared/shimmer_loading.dart';
import 'package:balaji_points/services/notifications/fcm_service.dart';
import 'package:balaji_points/services/auth/session_service.dart';

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
  String? _confettiPlayedKey;
  late ConfettiController _confettiController;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _confettiController =
        ConfettiController(duration: const Duration(seconds: 3));
    _loadAppVersion();
  }

  Future<void> _loadAppVersion() async {
    try {
      final info = await PackageInfo.fromPlatform();
      if (!mounted) return;
      setState(() =>
          _appVersion = 'Version ${info.version} (${info.buildNumber})');
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
    super.dispose();
  }

  Future<void> _handleLogout(BuildContext context) async {
    final l10n = AppLocalizations.of(context)!;
    final shouldLogout = await showDialog<bool>(
      context: context,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: AppRadius.all24),
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
                  color: context.themeError.withValues(alpha: 0.08),
                ),
                child: Icon(Icons.logout_rounded,
                    color: context.themeError, size: 26),
              ),
              const SizedBox(height: 20),
              AppText.h4(l10n.logout),
              const SizedBox(height: AppSpacing.sm),
              AppText.body(
                l10n.logoutConfirmation,
                textAlign: TextAlign.center,
                color: context.themeTextPrimary.withValues(alpha: 0.75),
              ),
              const SizedBox(height: AppSpacing.sectionGap),
              Row(
                children: [
                  Expanded(
                    child: AppButton.outline(
                      label: l10n.no,
                      onPressed: () => Navigator.of(ctx).pop(false),
                      verticalPadding: 12,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: AppButton(
                      label: l10n.yes,
                      onPressed: () => Navigator.of(ctx).pop(true),
                      variant: AppButtonVariant.danger,
                      verticalPadding: 12,
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
            backgroundColor: context.themeError,
          ));
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    final homeState = ref.watch(homeProvider);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final mq = MediaQuery.of(context);
    final canvas =
        context.themeBackground;
    final bottomPadding = CarpenterShellLayout.bottomPaddingForScrollView(mq);
    final fg = isDark ? AppColors.white : context.themeTextPrimary;
    final bg = canvas; // transparent — same as scaffold background
    final l10n = AppLocalizations.of(context)!;

    // Confetti on rank #1
    final topKey = homeState.topCarpenters.isNotEmpty
        ? homeState.topCarpenters.first.userId
        : null;
    if (topKey != null &&
        topKey == homeState.userDocId &&
        topKey != _confettiPlayedKey) {
      _confettiPlayedKey = topKey;
      WidgetsBinding.instance
          .addPostFrameCallback((_) => _confettiController.play());
    }

    AppLogger.data('Home build · loading=${homeState.loading}');

    return Scaffold(
      backgroundColor: canvas,
      drawer: HomeDrawer(
        homeState: homeState,
        appVersion: _appVersion,
        onLogout: _handleLogout,
      ),
      appBar: CarpenterTopNavBar(
        topInset: CarpenterShellLayout.topInset(mq),
        title: 'Balaji Points',
        backgroundColor: bg,
        foregroundColor: fg,
        leading: Builder(
          builder: (ctx) => IconButton(
            icon: Icon(Icons.menu_rounded, color: fg),
            onPressed: () => Scaffold.of(ctx).openDrawer(),
            tooltip: 'Menu',
          ),
        ),
        center: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: context.themePrimary.withValues(alpha: 0.10),
                borderRadius: AppRadius.sm8,
                border: Border.all(
                    color: context.themePrimary.withValues(alpha: 0.18)),
              ),
              child: ClipRRect(
                borderRadius: AppRadius.sm8,
                child: Image.asset(
                  'assets/images/balaji_point_logo.png',
                  width: 36,
                  height: 36,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Icon(
                      Icons.storefront_rounded,
                      color: context.themePrimary,
                      size: 20),
                ),
              ),
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
                    style: AppTypography.h5(color: fg),
                  ),
                  Text(
                    '${l10n.companyName} · ${l10n.homeStoreBranch}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.caption(color: fg.withValues(alpha: 0.55)),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          // Theme toggle
          _ThemeToggleButton(fg: fg),
          // Cart with badge
          _NavBarIconButton(
            icon: Icons.shopping_cart_outlined,
            fg: fg,
            badge: homeState.cartCount > 0 ? homeState.cartCount : null,
            badgeColor: context.themeError,
            tooltip: l10n.drawerCart,
            onTap: () => context.push('/cart'),
          ),
        ],
      ),
      body: Stack(
        children: [
          RefreshIndicator(
            onRefresh: () => ref.read(homeProvider.notifier).refresh(),
            color: context.themePrimary,
            backgroundColor: context.themeSurface,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: EdgeInsets.only(bottom: bottomPadding),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Hero card
                  RepaintBoundary(
                    child: homeState.loading
                        ? const HomeHeroCardShimmer()
                        : HomeHeroCard(homeState: homeState),
                  ).fadeIn(),

                  const SizedBox(height: AppSpacing.md),

                  // Quick actions
                  const RepaintBoundary(child: HomeQuickActions())
                      .fadeIn(delay: AppAnimations.stagger(1)),

                  const SizedBox(height: AppSpacing.md),

                  // Offers
                  if (homeState.offersLoading ||
                      homeState.offers.isNotEmpty) ...[
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Text(l10n.latestOffers,
                          style: AppTypography.h5(
                              color: context.themeTextPrimary)),
                    ).fadeIn(delay: AppAnimations.stagger(2)),
                    const SizedBox(height: AppSpacing.sm),
                    RepaintBoundary(
                      child: homeState.offersLoading
                          ? const SizedBox(
                              height: 220,
                              child: ShimmerOfferCard(),
                            )
                          : OffersCarousel(offers: homeState.offers),
                    ).fadeIn(delay: AppAnimations.stagger(2)),
                    const SizedBox(height: AppSpacing.md),
                  ],

                  // Product categories + real product cards
                  RepaintBoundary(child: HomeProductCategories())
                      .enterCard(delay: AppAnimations.stagger(3)),

                  const SizedBox(height: AppSpacing.md),

                  // Today's Winner — standalone card
                  RepaintBoundary(
                    child: const HomeTodaysWinnerCard(),
                  ).enterCard(delay: AppAnimations.stagger(4)),

                  if (homeState.topCarpenters.isNotEmpty)
                    const SizedBox(height: AppSpacing.md),

                  // Your Position — standalone card
                  RepaintBoundary(
                    child: HomeYourPositionCard(homeState: homeState),
                  ).enterCard(delay: AppAnimations.stagger(5)),

                  if (homeState.userRank != null)
                    const SizedBox(height: AppSpacing.md),

                  // Top Carpenters podium + top-10 list
                  RepaintBoundary(
                    child: HomeTopCarpenters(homeState: homeState),
                  ).enterCard(delay: AppAnimations.stagger(6)),

                  const SizedBox(height: AppSpacing.md),

                  // Feature highlights
                  const RepaintBoundary(child: HomeFeatureHighlights())
                      .enterCard(delay: AppAnimations.stagger(7)),

                  const SizedBox(height: AppSpacing.sectionGap),
                ],
              ),
            ),
          ),

          // Confetti overlay
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
                  colors: [
                    AppColors.warning,
                    AppColors.warning,
                    context.themeError,
                    context.themeSecondary,
                    context.themePrimary,
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// _NavBarIconButton — kept here as it's AppBar-specific
// ---------------------------------------------------------------------------

class _NavBarIconButton extends StatelessWidget {
  final IconData icon;
  final Color fg;
  final int? badge;
  final Color? badgeColor;
  final String? tooltip;
  final VoidCallback onTap;

  const _NavBarIconButton({
    required this.icon,
    required this.fg,
    required this.onTap,
    this.badge,
    this.badgeColor,
    this.tooltip,
  });

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: onTap,
      tooltip: tooltip,
      icon: Stack(
        clipBehavior: Clip.none,
        children: [
          Icon(icon, color: fg),
          if (badge != null && badge! > 0)
            Positioned(
              top: -4,
              right: -4,
              child: Container(
                padding: const EdgeInsets.all(3),
                decoration: BoxDecoration(
                  color: badgeColor ?? context.themeError,
                  shape: BoxShape.circle,
                  border: Border.all(color: context.themeBackground, width: 1),
                ),
                constraints:
                    const BoxConstraints(minWidth: 16, minHeight: 16),
                child: Text(
                  badge! > 99 ? '99+' : '$badge',
                  style: AppTypography.overline(color: AppColors.white),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// _ThemeToggleButton
// ---------------------------------------------------------------------------

class _ThemeToggleButton extends ConsumerWidget {
  final Color fg;
  const _ThemeToggleButton({required this.fg});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return IconButton(
      tooltip: isDark ? 'Switch to Light' : 'Switch to Dark',
      onPressed: () => ref.read(themeModeProvider.notifier).toggleTheme(),
      icon: AnimatedSwitcher(
        duration: const Duration(milliseconds: 250),
        transitionBuilder: (child, anim) =>
            RotationTransition(turns: anim, child: child),
        child: Icon(
          isDark ? Icons.wb_sunny_rounded : Icons.nightlight_round,
          key: ValueKey(isDark),
          color: fg,
        ),
      ),
    );
  }
}
