import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:balaji_points/core/design/app_animations.dart';
import 'package:balaji_points/core/design/app_colors.dart';
import 'package:balaji_points/core/design/app_spacing.dart';
import 'package:balaji_points/core/design/app_typography.dart';
import 'package:balaji_points/l10n/app_localizations.dart';
import 'package:balaji_points/services/auth/biometric_service.dart';
import 'package:balaji_points/services/auth/session_service.dart';
import 'package:balaji_points/services/notifications/fcm_service.dart';
import 'package:balaji_points/services/platform/app_startup_service.dart';
import 'package:balaji_points/services/platform/onboarding_prefs.dart';

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
    // Let entrance animations complete (600 ms hero + small buffer)
    await Future<void>.delayed(const Duration(milliseconds: 800));
    if (!mounted) return;

    final blockedByStartup = await AppStartupService().runPreLaunchChecks(context);
    if (!mounted || blockedByStartup) return;

    await _checkAuthAndNavigate();
  }

  Future<void> _checkAuthAndNavigate() async {
    if (!mounted) return;
    try {
      final isLoggedIn = await _sessionService.isLoggedIn();
      if (!mounted) return;

      if (isLoggedIn) {
        final bioEnabled = await _sessionService.isBiometricEnabled();
        if (bioEnabled) {
          final authenticated = await BiometricService().authenticate(
            localizedReason: 'Verify your identity to open Balaji Points',
          );
          if (!mounted) return;
          if (!authenticated) {
            // Biometric failed/cancelled — fall back to login screen
            context.go('/login');
            return;
          }
        }

        FCMService().processPendingNavigation();
        await Future<void>.delayed(const Duration(milliseconds: 120));
        if (!mounted) return;

        final role = await _sessionService.getUserRole();
        if (!mounted) return;

        final normalizedRole = role?.trim().toLowerCase();
        if (normalizedRole == 'super_admin') {
          context.go('/super-admin');
        } else if (normalizedRole == 'admin') {
          context.go('/admin');
        } else {
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
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: AppColors.transparent,
        body: Stack(
          fit: StackFit.expand,
          children: [
            // Background
            Image.asset(
              'assets/images/background_image.png',
              fit: BoxFit.cover,
            ),

            // Dark overlay for readability (light on dark bg)
            if (isDark)
              Container(color: AppColors.black.withValues(alpha: 0.4)),

            // Content
            SafeArea(
              child: Column(
                children: [
                  const Spacer(flex: 3),

                  // ── Logo ──
                  _Logo().enterHero(),

                  const SizedBox(height: AppSpacing.xl2),

                  // ── App name ──
                  Text(
                    l10n?.appName ?? 'Balaji Points',
                    style: AppTypography.displaySmall(
                      color: context.themePrimary,
                    ).copyWith(letterSpacing: 1.2),
                  ).enterHero(delay: AppAnimations.stagger(1)),

                  const SizedBox(height: AppSpacing.sm),

                  // ── Tagline ──
                  Text(
                    l10n?.rewardsLoyaltyProgram ?? 'Rewards & Loyalty Program',
                    style: AppTypography.bodyLarge(
                      color: context.themeTextSecondary,
                    ),
                  ).fadeIn(
                    delay: AppAnimations.stagger(2),
                    duration: AppAnimations.medium,
                  ),

                  const Spacer(flex: 4),

                  // ── Loading indicator ──
                  SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      color: context.themePrimary.withValues(alpha: 0.7),
                    ),
                  ).fadeIn(delay: AppAnimations.stagger(3)),

                  const SizedBox(height: AppSpacing.xl),

                  // ── Footer ──
                  Text(
                    '${l10n?.poweredBy ?? 'Powered by'}\n'
                    '${l10n?.companyName ?? 'Shri Balaji Plywood & Hardware'}',
                    textAlign: TextAlign.center,
                    style: AppTypography.labelMedium(
                      color: context.themePrimary,
                    ).copyWith(height: 1.5),
                  ).fadeIn(delay: AppAnimations.stagger(4)),

                  const SizedBox(height: AppSpacing.xl3),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Logo extends StatelessWidget {
  const _Logo();

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: Image.asset(
        'assets/images/balaji_point_logo.png',
        width: 100,
        height: 100,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => Container(
          width: 100,
          height: 100,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [context.themePrimary, context.themeSecondary],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: const Icon(Icons.star_rounded, color: AppColors.white, size: 52),
        ),
      ),
    );
  }
}
