import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:balaji_points/core/design/app_animations.dart';
import 'package:balaji_points/core/design/app_colors.dart';
import 'package:balaji_points/core/design/app_radius.dart';
import 'package:balaji_points/core/design/app_spacing.dart';
import 'package:balaji_points/core/design/app_typography.dart';
import 'package:balaji_points/l10n/app_localizations.dart';
import 'package:balaji_points/presentation/widgets/shared/app_button.dart';
import 'package:balaji_points/presentation/widgets/shared/app_text.dart';
import 'package:balaji_points/presentation/widgets/shared/app_text_field.dart';
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
    final topInset = MediaQuery.of(context).padding.top;

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
      child: Scaffold(
        backgroundColor: AppColors.transparent,
        extendBodyBehindAppBar: true,
        appBar: AppBar(
          backgroundColor: AppColors.transparent,
          elevation: 0,
          leading: BackButton(
            color: context.themePrimary,
            onPressed: () => context.pop(),
          ),
        ),
        body: Stack(
          fit: StackFit.expand,
          children: [
            // ── Background ──
            Image.asset(
              'assets/images/background_image.png',
              fit: BoxFit.cover,
            ),

            // ── Scrollable content ──
            SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(
                AppSpacing.xl,
                topInset + kToolbarHeight + AppSpacing.sm,
                AppSpacing.xl,
                bottomInset + AppSpacing.xl,
              ),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // ── Logo ──
                    ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: Image.asset(
                        'assets/images/balaji_point_logo.png',
                        width: 88,
                        height: 88,
                        fit: BoxFit.cover,
                      ),
                    ).enterHero(),

                    const SizedBox(height: AppSpacing.md),

                    // ── App name ──
                    AppText.h2(
                      l10n.appName,
                      color: context.themePrimary,
                    ).enterHero(delay: AppAnimations.stagger(1)),

                    const SizedBox(height: AppSpacing.xs),

                    AppText.h4(
                      l10n.enter4DigitPin,
                      color: context.themePrimary,
                    ).fadeIn(delay: AppAnimations.stagger(2)),

                    const SizedBox(height: AppSpacing.xs),

                    AppText.body(
                      '+91 ${widget.phoneNumber}',
                      color: context.themeTextSecondary,
                    ).fadeIn(delay: AppAnimations.stagger(3)),

                    const SizedBox(height: AppSpacing.xl3),

                    // ── Glass card ──
                    _GlassCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // PIN field
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
                          ),

                          const SizedBox(height: AppSpacing.md),

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
                          ),

                          const SizedBox(height: AppSpacing.lg),

                          // Login button
                          AppButton.secondary(
                            label: l10n.login,
                            onPressed: isLoggingIn ? null : _login,
                            isLoading: isLoggingIn,
                          ),

                          const SizedBox(height: AppSpacing.md),

                          // Forgot PIN
                          AppButton.outline(
                            label: l10n.forgotPin,
                            onPressed: () => context.push(
                              '/pin-reset?phone=${widget.phoneNumber}',
                            ),
                          ),

                          const SizedBox(height: AppSpacing.sm),

                          // New user
                          AppButton.outline(
                            label: l10n.newUserSetPin,
                            onPressed: () => context.push(
                              '/pin-setup?phone=${widget.phoneNumber}',
                            ),
                          ),
                        ],
                      ),
                    ).enterCard(delay: AppAnimations.stagger(4)),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Shared glass-morphism card ──────────────────────────────────────────────

class _GlassCard extends StatelessWidget {
  final Widget child;
  const _GlassCard({required this.child});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return ClipRRect(
      borderRadius: AppRadius.forCard,
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.xl3),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: isDark
                  ? [
                      AppColors.darkSurface.withValues(alpha: 0.82),
                      AppColors.darkBackground.withValues(alpha: 0.72),
                    ]
                  : [
                      AppColors.white.withValues(alpha: 0.92),
                      AppColors.white.withValues(alpha: 0.72),
                    ],
            ),
            borderRadius: AppRadius.forCard,
            border: Border.all(
              color: isDark
                  ? AppColors.darkBorder.withValues(alpha: 0.55)
                  : AppColors.white.withValues(alpha: 0.50),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: isDark
                    ? AppColors.black.withValues(alpha: 0.40)
                    : context.themePrimary.withValues(alpha: 0.10),
                blurRadius: 24,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: child,
        ),
      ),
    );
  }
}
