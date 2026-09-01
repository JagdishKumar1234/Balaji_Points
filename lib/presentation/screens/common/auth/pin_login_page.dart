import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:balaji_points/core/design/app_animations.dart';
import 'package:balaji_points/core/design/app_colors.dart';
import 'package:balaji_points/core/design/app_radius.dart';
import 'package:balaji_points/core/design/app_spacing.dart';
import 'package:balaji_points/core/design/app_typography.dart';
import 'package:balaji_points/core/design/auth_design.dart';
import 'package:balaji_points/l10n/app_localizations.dart';
import 'package:balaji_points/presentation/widgets/shared/app_button.dart';
import 'package:balaji_points/presentation/widgets/shared/app_text_field.dart';
import 'package:balaji_points/presentation/widgets/shared/auth_background.dart';
import 'package:balaji_points/presentation/widgets/shared/professional_auth_card.dart';
import 'package:balaji_points/providers/locale_provider.dart';
import 'package:balaji_points/providers/theme_provider.dart';
import '../../../../providers/auth_provider.dart';

class PINLoginPage extends ConsumerStatefulWidget {
  final String phoneNumber;
  const PINLoginPage({super.key, required this.phoneNumber});

  @override
  ConsumerState<PINLoginPage> createState() => _PINLoginPageState();
}

class _PINLoginPageState extends ConsumerState<PINLoginPage> {
  final _pinController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _rememberMe = true;
  bool _obscure = true;

  @override
  void dispose() {
    _pinController.dispose();
    super.dispose();
  }

  void _login() {
    if (!_formKey.currentState!.validate()) return;
    ref
        .read(authProvider.notifier)
        .loginWithPin(
          phoneNumber: widget.phoneNumber,
          pin: _pinController.text.trim(),
          rememberMe: _rememberMe,
        );
  }

  Future<void> _onAuthenticated(AuthAuthenticated state) async {
    if (!mounted) return;
    context.go(state.role.trim().toLowerCase() == 'admin' ? '/admin' : '/');
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    ref.listen<AuthState>(authProvider, (_, state) {
      if (state is AuthAuthenticated) {
        _onAuthenticated(state);
      } else if (state is AuthError) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(state.message),
            backgroundColor: context.themeError,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    });

    final isLoggingIn = ref.watch(authProvider) is AuthLoading;

    return PopScope(
      canPop: true,
      onPopInvokedWithResult: (didPop, result) async {
        if (!didPop) {
          if (Navigator.of(context).canPop()) {
            Navigator.of(context).pop();
            return;
          }
        }
      },
      child: Scaffold(
        backgroundColor: AppColors.transparent,
        body: Stack(
          fit: StackFit.expand,
          children: [
            // ── Modern gradient background ──
            AuthBackground(isDark: isDark),

            // ── Content ──
            SafeArea(
              bottom: false,
              child: SingleChildScrollView(
                padding: EdgeInsets.only(bottom: bottomInset + AppSpacing.xl),
                child: Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      // ── Top Controls ──
                      AuthTopControls(
                        themeToggle: _ThemeToggleButton(isDark: isDark)
                            .fadeIn(delay: AppAnimations.stagger(0)),
                        languagePicker: _LanguagePicker()
                            .fadeIn(delay: AppAnimations.stagger(0)),
                      ),

                      const SizedBox(height: AppSpacing.lg),

                      // ── Professional Auth Card with Back Button ──
                      Stack(
                        children: [
                          ProfessionalAuthCard(
                            isDark: isDark,
                            securityMessage: 'Your data is 100% secure with us',
                            child: Column(
                              children: [
                                // Header with phone number
                                Column(
                                  children: [
                                    // Logo
                                Container(
                                  width: 80,
                                  height: 80,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF001F4D),
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(16),
                                    child: Image.asset(
                                      'assets/images/balaji_point_logo.png',
                                      fit: BoxFit.cover,
                                      errorBuilder: (_, __, ___) => const Icon(
                                        Icons.home_rounded,
                                        color: Colors.white,
                                        size: 40,
                                      ),
                                    ),
                                  ),
                                ).enterHero(delay: AppAnimations.stagger(1)),
                                const SizedBox(height: AppSpacing.lg),

                                // Title
                                Text(
                                  l10n.enter4DigitPin,
                                  style: AppTypography.displaySmall(
                                    color: const Color(0xFF001F4D),
                                  ).copyWith(fontWeight: FontWeight.bold),
                                  textAlign: TextAlign.center,
                                ).fadeIn(delay: AppAnimations.stagger(2)),
                                const SizedBox(height: 8),

                                // Phone number
                                Text(
                                  '+91 ${widget.phoneNumber}',
                                  style: AppTypography.bodyMedium(
                                    color: const Color(0xFF78909C),
                                  ),
                                  textAlign: TextAlign.center,
                                ).fadeIn(delay: AppAnimations.stagger(3)),
                              ],
                            ),

                            const SizedBox(height: AppSpacing.xl3),

                            // PIN input
                            AppTextField(
                              controller: _pinController,
                              label: l10n.fourDigitPin,
                              keyboardType: TextInputType.number,
                              obscureText: _obscure,
                              maxLength: 4,
                              textAlign: TextAlign.center,
                              letterSpacing: 14,
                              suffix: IconButton(
                                icon: Icon(
                                  _obscure
                                      ? Icons.visibility_off
                                      : Icons.visibility,
                                  color: context.themeTextSecondary,
                                ),
                                onPressed: () =>
                                    setState(() => _obscure = !_obscure),
                              ),
                              validator: (v) => (v == null || v.length != 4)
                                  ? l10n.enter4Digits
                                  : null,
                            ).fadeIn(delay: AppAnimations.stagger(4)),

                            const SizedBox(height: AppSpacing.xl2),

                            // Remember me
                            Row(
                              children: [
                                Checkbox(
                                  value: _rememberMe,
                                  activeColor: context.themeSecondary,
                                  onChanged: (v) =>
                                      setState(() => _rememberMe = v ?? true),
                                ),
                                Expanded(
                                  child: GestureDetector(
                                    onTap: () => setState(
                                      () => _rememberMe = !_rememberMe,
                                    ),
                                    child: Text(
                                      l10n.rememberMe,
                                      style: AppTypography.bodyMedium(
                                        color: context.themeTextSecondary,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ).fadeIn(delay: AppAnimations.stagger(5)),

                            const SizedBox(height: AppSpacing.xl2),

                            // Login button
                            AppButton.secondary(
                              label: l10n.login,
                              onPressed: isLoggingIn ? null : _login,
                              isLoading: isLoggingIn,
                            ).fadeIn(delay: AppAnimations.stagger(6)),

                            const SizedBox(height: AppSpacing.md),

                            // Forgot PIN
                            AppButton.outline(
                              label: l10n.forgotPin,
                              onPressed: () => context.push(
                                '/pin-reset?phone=${widget.phoneNumber}',
                              ),
                            ).fadeIn(delay: AppAnimations.stagger(7)),

                            const SizedBox(height: AppSpacing.md),

                            // New user
                            AppButton.outline(
                              label: l10n.newUserSetPin,
                              onPressed: () => context.push(
                                '/pin-setup?phone=${widget.phoneNumber}',
                              ),
                            ).fadeIn(delay: AppAnimations.stagger(8)),
                          ],
                        ),
                      ).enterCard(delay: AppAnimations.stagger(9)),
                          // Back button (top-left, not scrollable - icon only)
                          Positioned(
                            top: 12,
                            left: 12,
                            child: Material(
                              color: Colors.transparent,
                              child: InkWell(
                                onTap: () {
                                  if (Navigator.of(context).canPop()) {
                                    Navigator.of(context).pop();
                                  } else {
                                    context.go('/login');
                                  }
                                },
                                borderRadius: const BorderRadius.all(Radius.circular(99)),
                                child: Padding(
                                  padding: const EdgeInsets.all(8),
                                  child: Icon(
                                    Icons.arrow_back_rounded,
                                    color: context.themePrimary,
                                    size: 24,
                                  ),
                                ),
                              ),
                            ).fadeIn(delay: AppAnimations.stagger(0)),
                          ),
                        ],
                      ),

                      const SizedBox(height: AppSpacing.xl2),

                      // ── Footer ──
                      AuthFooter(
                        companyName: l10n.companyName,
                        isDark: isDark,
                      ).fadeIn(delay: AppAnimations.stagger(10)),

                      const SizedBox(height: AppSpacing.xl3),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Theme toggle button ───────────────────────────────────────────────────────

class _ThemeToggleButton extends ConsumerWidget {
  final bool isDark;
  const _ThemeToggleButton({required this.isDark});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: isDark
            ? AppColors.darkSurface.withValues(alpha: 0.85)
            : AppColors.white.withValues(alpha: 0.90),
        borderRadius: AppRadius.sm8,
        border: Border.all(
          color: isDark
              ? AppColors.darkBorder.withValues(alpha: 0.5)
              : context.themePrimary.withValues(alpha: 0.30),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: (isDark
                    ? AppColors.darkBorder
                    : context.themePrimary)
                .withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: IconButton(
        padding: EdgeInsets.zero,
        splashRadius: 22,
        tooltip: isDark ? 'Switch to Light' : 'Switch to Dark',
        onPressed: () => ref.read(themeModeProvider.notifier).toggleTheme(),
        icon: AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          transitionBuilder: (child, anim) =>
              RotationTransition(turns: anim, child: child),
          child: Icon(
            isDark ? Icons.wb_sunny_rounded : Icons.nightlight_round,
            key: ValueKey(isDark),
            size: 22,
            color: isDark ? AppColors.warning : context.themePrimary,
          ),
        ),
      ),
    );
  }
}

// ── Language picker ──────────────────────────────────────────────────────────

class _LanguagePicker extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final l10n = AppLocalizations.of(context)!;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
      height: 44,
      decoration: BoxDecoration(
        color: isDark
            ? AppColors.darkSurface.withValues(alpha: 0.85)
            : AppColors.white.withValues(alpha: 0.90),
        borderRadius: AppRadius.sm8,
        border: Border.all(
          color: isDark
              ? AppColors.darkBorder.withValues(alpha: 0.5)
              : context.themePrimary.withValues(alpha: 0.30),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: (isDark
                    ? AppColors.darkBorder
                    : context.themePrimary)
                .withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<Locale>(
          value: ref.watch(localeProvider),
          style: AppTypography.bodyMedium(
            color: context.themeTextPrimary,
          ),
          dropdownColor: context.themeSurface,
          iconEnabledColor: isDark ? AppColors.white : context.themePrimary,
          icon: Icon(
            Icons.language_rounded,
            size: 22,
            color: isDark ? AppColors.white : context.themePrimary,
          ),
          onChanged: (locale) {
            if (locale != null) {
              ref.read(localeProvider.notifier).setLocale(locale);
            }
          },
          items: [
            DropdownMenuItem(
              value: const Locale('en'),
              child: Row(
                children: [
                  const Icon(Icons.language, size: 16),
                  const SizedBox(width: 8),
                  Text(l10n.languageEnglish),
                ],
              ),
            ),
            DropdownMenuItem(
              value: const Locale('hi'),
              child: Row(
                children: [
                  const Icon(Icons.language, size: 16),
                  const SizedBox(width: 8),
                  Text(l10n.languageHindi),
                ],
              ),
            ),
            DropdownMenuItem(
              value: const Locale('ta'),
              child: Row(
                children: [
                  const Icon(Icons.language, size: 16),
                  const SizedBox(width: 8),
                  Text(l10n.languageTamil),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
