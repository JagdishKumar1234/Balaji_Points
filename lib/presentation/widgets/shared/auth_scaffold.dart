import 'package:balaji_points/core/design/app_colors.dart';
import 'package:balaji_points/core/design/app_spacing.dart';
import 'package:balaji_points/core/design/responsive_typography.dart';
import 'package:balaji_points/presentation/widgets/shared/auth_background.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// The app's square logo, as shown on the splash screen.
class BrandLogo extends StatelessWidget {
  const BrandLogo({super.key, required this.size});

  final double size;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(size * 0.22);
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        borderRadius: radius,
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.22),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Image.asset(
        'assets/images/splash_logo.png',
        width: size,
        height: size,
        fit: BoxFit.contain,
        errorBuilder: (context, error, stackTrace) => DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: radius,
            color: AppColors.primary,
          ),
          child: Icon(
            Icons.card_giftcard_rounded,
            color: AppColors.white,
            size: size * 0.5,
          ),
        ),
      ),
    );
  }
}

/// Frame for every auth screen: background, square logo at top centre, and a
/// back button that stays on screen while the form scrolls.
///
/// The back button and the device Back key always do the same thing: [onBack]
/// if given, otherwise return to the previous screen, or [fallbackRoute] when
/// there is none (screens opened with `context.go`).
class AuthScaffold extends StatelessWidget {
  const AuthScaffold({
    super.key,
    required this.child,
    this.fallbackRoute = '/login',
    this.onBack,
    this.showBackButton = true,
  });

  final Widget child;
  final String fallbackRoute;
  final VoidCallback? onBack;
  final bool showBackButton;

  void _goBack(BuildContext context) {
    if (onBack != null) {
      onBack!();
      return;
    }
    final router = GoRouter.of(context);
    if (router.canPop()) {
      router.pop();
    } else {
      router.go(fallbackRoute);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isShort = MediaQuery.sizeOf(context).height < 700;
    final logoSize = isShort
        ? 72.0
        : ResponsiveTypography.getLogoSize(context) * 1.2;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _goBack(context);
      },
      child: Scaffold(
        backgroundColor: AppColors.transparent,
        body: Stack(
          fit: StackFit.expand,
          children: [
            AuthBackground(isDark: isDark),
            SafeArea(
              child: Stack(
                fit: StackFit.expand,
                children: [
                  SingleChildScrollView(
                    padding: const EdgeInsets.only(
                      top: AppSpacing.md,
                      bottom: AppSpacing.xl,
                    ),
                    child: Column(
                      children: [
                        BrandLogo(size: logoSize),
                        const SizedBox(height: AppSpacing.lg),
                        child,
                      ],
                    ),
                  ),
                  if (showBackButton)
                    Positioned(
                      top: AppSpacing.sm,
                      left: AppSpacing.sm,
                      child: IconButton(
                        key: const ValueKey('auth-back-button'),
                        tooltip: MaterialLocalizations.of(
                          context,
                        ).backButtonTooltip,
                        onPressed: () => _goBack(context),
                        icon: const Icon(Icons.arrow_back_rounded),
                        style: IconButton.styleFrom(
                          backgroundColor: context.themeCard,
                          foregroundColor: context.themeContentColor,
                          minimumSize: const Size(44, 44),
                          elevation: 2,
                          shadowColor: AppColors.primary.withValues(alpha: 0.3),
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
