import 'package:balaji_points/core/constants/app_constants.dart';
import 'package:balaji_points/core/design/app_colors.dart';
import 'package:balaji_points/core/design/app_radius.dart';
import 'package:balaji_points/core/design/app_typography.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:balaji_points/l10n/app_localizations.dart';
import 'package:balaji_points/services/platform/onboarding_prefs.dart';

/// First-install intro shown after splash, before login (one-time per install).
///
/// Navy panel with the logo and a simple illustration on top, a calm sheet
/// with the text and one button below. Navy and gold only.
class OnboardingPage extends StatefulWidget {
  const OnboardingPage({super.key});

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage> {
  final PageController _pageController = PageController();
  int _pageIndex = 0;
  static const int _pageCount = 3;

  static const _art = [
    _SlideArt(
      main: Icons.receipt_long_rounded,
      badgeA: Icons.add_rounded,
      badgeB: Icons.star_rounded,
    ),
    _SlideArt(
      main: Icons.emoji_events_rounded,
      badgeA: Icons.leaderboard_rounded,
      badgeB: Icons.card_giftcard_rounded,
    ),
    _SlideArt(
      main: Icons.notifications_active_rounded,
      badgeA: Icons.check_rounded,
      badgeB: Icons.person_rounded,
    ),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (await OnboardingPrefs.isCompleted() && mounted) {
        context.go('/login');
      }
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _finish() async {
    await OnboardingPrefs.setCompleted();
    if (!mounted) return;
    context.go('/login');
  }

  void _next() {
    if (_pageIndex < _pageCount - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 320),
        curve: Curves.easeOutCubic,
      );
    } else {
      _finish();
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final titles = [
      l10n.onboardingSlide1Title,
      l10n.onboardingSlide2Title,
      l10n.onboardingSlide3Title,
    ];
    final bodies = [
      l10n.onboardingSlide1Body,
      l10n.onboardingSlide2Body,
      l10n.onboardingSlide3Body,
    ];
    final isLast = _pageIndex == _pageCount - 1;

    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: context.themeBackground,
        body: LayoutBuilder(
          builder: (context, constraints) {
            // The navy panel takes a bit over half the screen; less on
            // short or landscape screens so the text always has room.
            final panelHeight = (constraints.maxHeight * 0.52).clamp(
              240.0,
              520.0,
            );
            return Column(
              children: [
                SizedBox(
                  height: panelHeight,
                  child: _TopPanel(
                    controller: _pageController,
                    art: _art,
                    onPageChanged: (i) => setState(() => _pageIndex = i),
                    onSkip: isLast ? null : _finish,
                    skipLabel: l10n.onboardingSkip,
                  ),
                ),
                Expanded(
                  child: SafeArea(
                    top: false,
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: SingleChildScrollView(
                              child: AnimatedSwitcher(
                                duration: const Duration(milliseconds: 220),
                                child: _SlideText(
                                  key: ValueKey(_pageIndex),
                                  step: '${_pageIndex + 1} / $_pageCount',
                                  title: titles[_pageIndex],
                                  body: bodies[_pageIndex],
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              _Dots(count: _pageCount, index: _pageIndex),
                              const Spacer(),
                              _NextButton(
                                label: isLast
                                    ? l10n.onboardingGetStarted
                                    : l10n.next,
                                wide: isLast,
                                onPressed: _next,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _SlideArt {
  const _SlideArt({
    required this.main,
    required this.badgeA,
    required this.badgeB,
  });
  final IconData main;
  final IconData badgeA;
  final IconData badgeB;
}

/// Navy panel: logo and Skip on top, swipeable illustrations below.
class _TopPanel extends StatelessWidget {
  const _TopPanel({
    required this.controller,
    required this.art,
    required this.onPageChanged,
    required this.onSkip,
    required this.skipLabel,
  });

  final PageController controller;
  final List<_SlideArt> art;
  final ValueChanged<int> onPageChanged;
  final VoidCallback? onSkip;
  final String skipLabel;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(32)),
      ),
      child: SafeArea(
        bottom: false,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 8, 0),
              child: Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(9),
                    child: Image.asset(
                      AppConstants.logoPath,
                      width: 40,
                      height: 40,
                      cacheWidth: 120,
                    ),
                  ),
                  const Spacer(),
                  // Kept in place on the last slide so nothing jumps.
                  Opacity(
                    opacity: onSkip == null ? 0 : 1,
                    child: TextButton(
                      onPressed: onSkip,
                      style: TextButton.styleFrom(
                        foregroundColor: AppColors.white,
                        minimumSize: const Size(64, 48),
                      ),
                      child: Text(
                        skipLabel,
                        style: AppTypography.labelLarge(color: AppColors.white),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: PageView.builder(
                controller: controller,
                itemCount: art.length,
                onPageChanged: onPageChanged,
                itemBuilder: (context, i) => _Illustration(art: art[i]),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// A large gold-ringed icon with two small floating badges.
class _Illustration extends StatelessWidget {
  const _Illustration({required this.art});

  final _SlideArt art;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, c) {
        final size = (c.biggest.shortestSide * 0.62).clamp(120.0, 240.0);
        final badge = size * 0.3;
        return Center(
          child: SizedBox(
            width: size + badge,
            height: size + badge * 0.6,
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Soft rings
                Container(
                  width: size,
                  height: size,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.white.withValues(alpha: 0.06),
                  ),
                ),
                Container(
                  width: size * 0.72,
                  height: size * 0.72,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.white,
                    border: Border.all(color: AppColors.gold, width: 3),
                  ),
                  child: Icon(
                    art.main,
                    size: size * 0.32,
                    color: AppColors.primary,
                  ),
                ),
                Positioned(
                  top: 0,
                  right: badge * 0.2,
                  child: _Badge(icon: art.badgeA, size: badge, gold: true),
                ),
                Positioned(
                  bottom: 0,
                  left: badge * 0.2,
                  child: _Badge(icon: art.badgeB, size: badge, gold: false),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge({required this.icon, required this.size, required this.gold});

  final IconData icon;
  final double size;
  final bool gold;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: gold ? AppColors.gold : AppColors.white,
        borderRadius: BorderRadius.circular(size * 0.3),
        boxShadow: [
          BoxShadow(
            color: AppColors.black.withValues(alpha: 0.18),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Icon(icon, size: size * 0.5, color: AppColors.primary),
    );
  }
}

class _SlideText extends StatelessWidget {
  const _SlideText({
    super.key,
    required this.step,
    required this.title,
    required this.body,
  });

  final String step;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: context.themeGoldSoft,
            borderRadius: AppRadius.all16,
          ),
          child: Text(
            step,
            style: AppTypography.labelMedium(color: context.themeTextPrimary),
          ),
        ),
        const SizedBox(height: 14),
        Text(
          title,
          style: AppTypography.title(color: context.themeTextPrimary),
        ),
        const SizedBox(height: 10),
        Text(
          body,
          style: AppTypography.bodyLarge(
            color: context.themeTextSecondary,
          ).copyWith(height: 1.5),
        ),
      ],
    );
  }
}

class _Dots extends StatelessWidget {
  const _Dots({required this.count, required this.index});

  final int count;
  final int index;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(
        count,
        (i) => AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          margin: const EdgeInsets.only(right: 6),
          width: i == index ? 22 : 8,
          height: 8,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(999),
            color: i == index ? AppColors.gold : context.themeBorderStrong,
          ),
        ),
      ),
    );
  }
}

class _NextButton extends StatelessWidget {
  const _NextButton({
    required this.label,
    required this.wide,
    required this.onPressed,
  });

  final String label;
  final bool wide;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Flexible(
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        constraints: BoxConstraints(minWidth: wide ? 200 : 120),
        height: 52,
        child: ElevatedButton(
          onPressed: onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: AppColors.white,
            elevation: 0,
            padding: const EdgeInsets.symmetric(horizontal: 22),
            shape: RoundedRectangleBorder(borderRadius: AppRadius.all16),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.buttonMedium(color: AppColors.white),
                ),
              ),
              const SizedBox(width: 8),
              const Icon(Icons.arrow_forward_rounded, size: 20),
            ],
          ),
        ),
      ),
    );
  }
}
