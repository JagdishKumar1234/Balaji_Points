import 'package:balaji_points/core/constants/app_constants.dart';
import 'dart:async';
import 'package:balaji_points/presentation/widgets/shared/auth_scaffold.dart';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';

import 'package:balaji_points/core/design/app_animations.dart';
import 'package:balaji_points/core/design/app_colors.dart';
import 'package:balaji_points/core/design/app_spacing.dart';
import 'package:balaji_points/core/design/app_typography.dart';
import 'package:balaji_points/core/design/responsive_typography.dart';
import 'package:balaji_points/core/logger.dart';
import 'package:balaji_points/l10n/app_localizations.dart';
import 'package:balaji_points/presentation/widgets/shared/auth_background.dart';
import 'package:balaji_points/services/auth/biometric_service.dart';
import 'package:balaji_points/services/auth/session_service.dart';
import 'package:balaji_points/services/notifications/fcm_service.dart';
import 'package:balaji_points/services/platform/app_startup_service.dart';
import 'package:balaji_points/services/platform/onboarding_prefs.dart';
import 'package:balaji_points/services/user/user_points_sync_service.dart';

class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> {
  final _sessionService = SessionService();

  @override
  void initState() {
    super.initState();
    unawaited(_runSplashSequence());
  }

  Future<void> _runSplashSequence() async {
    // No fixed wait: the app moves on as soon as the update check is done.

    // Check for blocking updates only (must complete before navigation)
    AppLogger.startup('Splash: checking installed version and update policy.');
    final forceUpdatePending = await AppStartupService().checkForBlockingUpdate(
      context,
    );
    if (!mounted) {
      AppLogger.startup('Splash: disposed while update check was running.');
      return;
    }
    if (forceUpdatePending) {
      AppLogger.startup(
        'Splash: force update required; navigation blocked until app is updated.',
      );
      return;
    }
    AppLogger.startup(
      'Splash: update gate passed; continuing to authentication.',
    );

    // Proceed to navigation immediately
    await _checkAuthAndNavigate();

    // Start non-blocking startup tasks in background (doesn't block navigation)
    if (mounted) {
      unawaited(AppStartupService().runBackgroundStartupTasks(context));
    }
  }

  Future<void> _checkAuthAndNavigate() async {
    if (!mounted) return;
    try {
      final isLoggedIn = await _sessionService.isLoggedIn();
      if (!mounted) return;

      if (isLoggedIn) {
        final bioEnabled = await _sessionService.isBiometricEnabled();
        if (!mounted) return;
        if (bioEnabled) {
          final authenticated = await BiometricService().authenticate(
            localizedReason: AppLocalizations.of(
              context,
            )!.verifyYourIdentityToOpenBalaji,
          );
          if (!mounted) return;
          if (!authenticated) {
            // Biometric failed/cancelled — fall back to login screen
            context.go('/login');
            return;
          }
        }

        FCMService().processPendingNavigation();

        final role = await _sessionService.getUserRole();
        if (!mounted) return;

        final normalizedRole = role?.trim().toLowerCase();
        if (normalizedRole == 'super_admin') {
          context.go('/super-admin');
        } else if (normalizedRole == 'admin') {
          context.go('/admin');
        } else {
          // Not awaited: home opens now and fills in as the data arrives.
          unawaited(UserPointsSyncService().syncNow(force: true));
          context.go('/');
        }
      } else {
        final onboardingDone = await OnboardingPrefs.isCompleted();
        if (!mounted) return;
        context.go(onboardingDone ? '/login' : '/onboarding');
      }
    } catch (_) {
      if (mounted) context.go('/login');
    }
  }

  @override
  Widget build(BuildContext context) => const SplashView();
}

/// The splash screen's appearance, with no startup logic.
class SplashView extends StatelessWidget {
  const SplashView({super.key});

  static const Duration _stagger = Duration(milliseconds: 90);

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final animate = !MediaQuery.disableAnimationsOf(context);

    Widget entrance(Widget child, int step) => animate
        ? child.enterHero(delay: AppAnimations.stagger(step, step: _stagger))
        : child;

    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: AppColors.transparent,
        body: Stack(
          fit: StackFit.expand,
          children: [
            AuthBackground(isDark: isDark),
            SafeArea(
              // Scrolls only when the content cannot fit, such as on a short
              // screen with large text.
              child: CustomScrollView(
                slivers: [
                  SliverFillRemaining(
                    hasScrollBody: false,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.lg,
                        vertical: AppSpacing.md,
                      ),
                      // Equal space above and below keeps the logo at the exact
                      // centre, where the native launch logo was.
                      child: Column(
                        children: [
                          const Expanded(child: SizedBox.shrink()),
                          _AnimatedLogo(animate: animate),
                          Expanded(
                            child: Column(
                              children: [
                                const SizedBox(height: AppSpacing.md),
                                entrance(
                                  Text(
                                    l10n?.appName ?? 'Balaji Points',
                                    textAlign: TextAlign.center,
                                    style: AppTypography.displaySmall(
                                      color: context.themePrimary,
                                    ).copyWith(letterSpacing: 1.2),
                                  ),
                                  2,
                                ),
                                const SizedBox(height: AppSpacing.sm),
                                entrance(
                                  Text(
                                    l10n?.rewardsLoyaltyProgram ??
                                        'Rewards & Loyalty Program',
                                    textAlign: TextAlign.center,
                                    style: AppTypography.bodyLarge(
                                      color: context.themeTextSecondary,
                                    ),
                                  ),
                                  3,
                                ),
                                const SizedBox(height: AppSpacing.lg),
                                entrance(
                                  SizedBox.square(
                                    dimension: 22,
                                    child: CircularProgressIndicator(
                                      key: const ValueKey('splash-loader'),
                                      strokeWidth: 2.5,
                                      strokeCap: StrokeCap.round,
                                      color: context.themeGold,
                                    ),
                                  ),
                                  4,
                                ),
                                const Spacer(),
                                const SizedBox(height: AppSpacing.md),
                                entrance(
                                  Text(
                                    '${l10n?.poweredBy ?? 'Powered by'}\n'
                                    '${l10n?.companyName ?? AppConstants.companyName}',
                                    textAlign: TextAlign.center,
                                    // Sits on the navy curve of AuthBackground.
                                    style: AppTypography.labelMedium(
                                      color: AppColors.white,
                                    ).copyWith(height: 1.5),
                                  ),
                                  5,
                                ),
                              ],
                            ),
                          ),
                        ],
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

/// The logo settles into place at the centre of the screen.
class _AnimatedLogo extends StatelessWidget {
  const _AnimatedLogo({required this.animate});

  final bool animate;

  @override
  Widget build(BuildContext context) {
    final logo = BrandLogo(
      size: ResponsiveTypography.getLogoSize(context) * 1.4,
    );
    if (!animate) return logo;
    return logo
        .animate()
        .fadeIn(duration: const Duration(milliseconds: 220))
        .scaleXY(
          begin: 0.86,
          end: 1,
          duration: const Duration(milliseconds: 520),
          curve: Curves.easeOutBack,
        );
  }
}
