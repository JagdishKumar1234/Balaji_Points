import 'package:balaji_points/core/design/app_radius.dart';
import 'package:balaji_points/core/design/app_colors.dart';
import 'package:balaji_points/core/design/app_typography.dart';
import 'package:balaji_points/core/design/responsive_typography.dart';
import 'package:balaji_points/core/layout/responsive.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:balaji_points/l10n/app_localizations.dart';
import 'package:balaji_points/services/platform/onboarding_prefs.dart';

/// First-install intro shown after splash, before login (one-time per install).
class OnboardingPage extends StatefulWidget {
  const OnboardingPage({super.key});

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage> {
  final PageController _pageController = PageController();
  int _pageIndex = 0;
  static const int _pageCount = 3;

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
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final slides = [
      _SlideData(
        icon: Icons.receipt_long_rounded,
        title: l10n.onboardingSlide1Title,
        body: l10n.onboardingSlide1Body,
      ),
      _SlideData(
        icon: Icons.emoji_events_rounded,
        title: l10n.onboardingSlide2Title,
        body: l10n.onboardingSlide2Body,
      ),
      _SlideData(
        icon: Icons.notifications_active_rounded,
        title: l10n.onboardingSlide3Title,
        body: l10n.onboardingSlide3Body,
      ),
    ];

    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: AppColors.transparent,
        body: Stack(
          fit: StackFit.expand,
          children: [
            // Professional gradient background (works on web & mobile)
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: isDark
                      ? [
                          const Color(0xFF1A237E).withValues(alpha: 0.95),
                          const Color(0xFF0D47A1).withValues(alpha: 0.95),
                        ]
                      : [
                          const Color(0xFFF5F7FA),
                          const Color(0xFFFFFFFF),
                          const Color(0xFFF0F4F8),
                        ],
                  stops: const [0.0, 0.5, 1.0],
                ),
              ),
            ),

            // Optional: Try loading background image with error handling
            Positioned.fill(
              child: Image.asset(
                'assets/images/background_image.png',
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  // If image fails to load, gradient background shows through
                  return const SizedBox.expand();
                },
              ),
            ),

            SafeArea(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Skip button with proper styling
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: _finish,
                      child: Text(
                        l10n.onboardingSkip,
                        style: AppTypography.labelLarge().copyWith(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: context.themePrimary,
                        ),
                      ),
                    ),
                  ),

                  // Slides PageView
                  Expanded(
                    child: PageView.builder(
                      controller: _pageController,
                      itemCount: _pageCount,
                      onPageChanged: (i) => setState(() => _pageIndex = i),
                      itemBuilder: (context, index) {
                        final s = slides[index];

                        // Get responsive sizes based on device type
                        final iconContainerSize = context.responsiveLogoSize * 1.2; // Slightly larger than logo
                        final iconSize = iconContainerSize * 0.5;
                        final titleFontSize = context.responsiveTitleSize * 0.85;
                        final bodyFontSize = context.responsiveBodySize;
                        final lineHeight = context.responsiveLineHeight;

                        return Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 28),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              // Icon container - responsive sizing
                              Container(
                                width: iconContainerSize,
                                height: iconContainerSize,
                                padding: EdgeInsets.all(iconContainerSize * 0.2),
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: isDark
                                      ? AppColors.darkSurface.withValues(alpha: 0.85)
                                      : AppColors.white.withValues(alpha: 0.92),
                                  boxShadow: [
                                    BoxShadow(
                                      color: isDark
                                          ? AppColors.black.withValues(alpha: 0.3)
                                          : AppColors.black.withValues(alpha: 0.08),
                                      blurRadius: 24,
                                      offset: const Offset(0, 8),
                                    ),
                                  ],
                                ),
                                child: Icon(
                                  s.icon,
                                  size: iconSize,
                                  color: context.themePrimary,
                                ),
                              ),
                              SizedBox(height: context.responsiveHeaderSpacing * 0.8),

                              // Title - responsive font size
                              Text(
                                s.title,
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: titleFontSize,
                                  height: lineHeight,
                                  fontWeight: FontWeight.bold,
                                  color: context.themeTextPrimary,
                                  letterSpacing: context.responsiveLetterSpacing,
                                ),
                              ),
                              const SizedBox(height: 16),

                              // Body text - responsive font size
                              Text(
                                s.body,
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: bodyFontSize,
                                  height: lineHeight,
                                  color: context.themeTextPrimary.withValues(
                                    alpha: 0.78,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),

                  // Dot indicators with proper sizing
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(
                      _pageCount,
                      (i) => AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        width: i == _pageIndex ? 24 : 8,
                        height: 8,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(999),
                          color: i == _pageIndex
                              ? context.themePrimary
                              : context.themeTextMuted.withValues(alpha: 0.5),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
                    child: SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton(
                        onPressed: _next,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: context.themePrimary,
                          foregroundColor: AppColors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: AppRadius.all16,
                          ),
                        ),
                        child: Text(
                          _pageIndex < _pageCount - 1
                              ? l10n.next
                              : l10n.onboardingGetStarted,
                          style: AppTypography.buttonMedium().copyWith(
                            fontSize: 17,
                            color: AppColors.white,
                          ),
                        ),
                      ),
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

class _SlideData {
  const _SlideData({
    required this.icon,
    required this.title,
    required this.body,
  });
  final IconData icon;
  final String title;
  final String body;
}
