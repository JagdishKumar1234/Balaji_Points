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
import 'package:balaji_points/services/auth/biometric_service.dart';
import 'package:balaji_points/services/auth/session_service.dart';
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
    ref.read(authProvider.notifier).loginWithPin(
      phoneNumber: widget.phoneNumber,
      pin: _pinController.text.trim(),
      rememberMe: _rememberMe,
    );
  }

  Future<void> _onAuthenticated(AuthAuthenticated state) async {
    final session = SessionService();
    final bio = BiometricService();
    final asked = await session.hasAskedBiometric();
    if (!asked && await bio.isAvailable()) {
      if (!mounted) return;
      final enable = await showDialog<bool>(
        context: context,
        barrierDismissible: false,
        builder: (_) => const _BiometricOptInDialog(),
      );
      await session.setBiometricEnabled(enabled: enable ?? false);
      await session.markAskedBiometric();
    }
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
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(state.message),
          backgroundColor: context.themeError,
          duration: const Duration(seconds: 3),
        ));
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
            Image.asset('assets/images/background_image.png', fit: BoxFit.cover),

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
                    Text(
                      l10n.appName,
                      style: AppTypography.h2(color: context.themePrimary),
                    ).enterHero(delay: AppAnimations.stagger(1)),

                    const SizedBox(height: AppSpacing.xs),

                    Text(
                      l10n.enter4DigitPin,
                      style: AppTypography.h5(color: context.themePrimary),
                    ).fadeIn(delay: AppAnimations.stagger(2)),

                    const SizedBox(height: AppSpacing.xs),

                    Text(
                      '+91 ${widget.phoneNumber}',
                      style: AppTypography.bodyMedium(
                        color: context.themeTextSecondary,
                      ),
                    ).fadeIn(delay: AppAnimations.stagger(3)),

                    const SizedBox(height: AppSpacing.xl3),

                    // ── Glass card ──
                    _GlassCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // PIN field
                          TextFormField(
                            controller: _pinController,
                            keyboardType: TextInputType.number,
                            obscureText: _obscure,
                            maxLength: 4,
                            textAlign: TextAlign.center,
                            style: AppTypography.h2(
                              color: context.themePrimary,
                            ).copyWith(letterSpacing: 14),
                            decoration: InputDecoration(
                              labelText: l10n.fourDigitPin,
                              labelStyle: AppTypography.bodyMedium(
                                color: context.themeTextSecondary,
                              ),
                              counterText: '',
                              filled: true,
                              fillColor: context.themePrimary.withValues(alpha: 0.05),
                              border: OutlineInputBorder(
                                borderRadius: AppRadius.forInput,
                                borderSide: BorderSide(
                                  color: context.themePrimary.withValues(alpha: 0.3),
                                  width: 1.5,
                                ),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: AppRadius.forInput,
                                borderSide: BorderSide(
                                  color: context.themePrimary.withValues(alpha: 0.2),
                                  width: 1.5,
                                ),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: AppRadius.forInput,
                                borderSide: BorderSide(
                                  color: context.themePrimary,
                                  width: 2,
                                ),
                              ),
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _obscure ? Icons.visibility_off : Icons.visibility,
                                  color: context.themeTextSecondary,
                                ),
                                onPressed: () => setState(() => _obscure = !_obscure),
                              ),
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
                                onChanged: (v) => setState(() => _rememberMe = v ?? true),
                              ),
                              Expanded(
                                child: GestureDetector(
                                  onTap: () => setState(() => _rememberMe = !_rememberMe),
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
                          _GradientButton(
                            onPressed: isLoggingIn ? null : _login,
                            isLoading: isLoggingIn,
                            label: l10n.login,
                          ),

                          const SizedBox(height: AppSpacing.xs),

                          // Forgot PIN
                          TextButton(
                            onPressed: () => context.push('/pin-reset?phone=${widget.phoneNumber}'),
                            child: Text(
                              l10n.forgotPin,
                              style: AppTypography.labelLarge(
                                color: context.themeSecondary,
                              ),
                            ),
                          ),

                          // New user
                          TextButton(
                            onPressed: () => context.push('/pin-setup?phone=${widget.phoneNumber}'),
                            child: Text(
                              l10n.newUserSetPin,
                              style: AppTypography.bodySmall(
                                color: context.themeTextSecondary,
                              ),
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
    return ClipRRect(
      borderRadius: AppRadius.forCard,
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.xl3),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppColors.white.withValues(alpha: 0.92),
                AppColors.white.withValues(alpha: 0.72),
              ],
            ),
            borderRadius: AppRadius.forCard,
            border: Border.all(
              color: AppColors.white.withValues(alpha: 0.5),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: context.themePrimary.withValues(alpha: 0.10),
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

// ── Gradient action button ───────────────────────────────────────────────────

class _GradientButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final bool isLoading;
  final String label;

  const _GradientButton({
    required this.onPressed,
    required this.isLoading,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: AppSpacing.buttonHeight,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            context.themeSecondary,
            context.themeSecondary.withValues(alpha: 0.82),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: AppRadius.forButton,
        boxShadow: [
          BoxShadow(
            color: context.themeSecondary.withValues(alpha: 0.35),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.transparent,
          shadowColor: AppColors.transparent,
          minimumSize: const Size(double.infinity, AppSpacing.buttonHeight),
          shape: RoundedRectangleBorder(borderRadius: AppRadius.forButton),
        ),
        child: isLoading
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  color: AppColors.white,
                  strokeWidth: 2.5,
                ),
              )
            : Text(
                label,
                style: AppTypography.buttonLarge(color: AppColors.white),
              ),
      ),
    );
  }
}

// ── Biometric opt-in dialog ──────────────────────────────────────────────────

class _BiometricOptInDialog extends StatelessWidget {
  const _BiometricOptInDialog();

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: AppRadius.forCard),
      title: Row(
        children: [
          Icon(Icons.fingerprint, color: context.themeSecondary, size: 28),
          const SizedBox(width: AppSpacing.sm),
          Text(
            'Enable Biometrics',
            style: AppTypography.h5(color: context.themePrimary),
          ),
        ],
      ),
      content: Text(
        'Use fingerprint or face unlock to sign in faster next time.',
        style: AppTypography.bodyMedium(color: context.themeTextSecondary),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: Text(
            'Not Now',
            style: AppTypography.labelLarge(color: context.themeTextSecondary),
          ),
        ),
        ElevatedButton(
          onPressed: () => Navigator.of(context).pop(true),
          style: ElevatedButton.styleFrom(
            backgroundColor: context.themeSecondary,
            foregroundColor: AppColors.white,
            shape: RoundedRectangleBorder(borderRadius: AppRadius.forButton),
          ),
          child: Text(
            'Enable',
            style: AppTypography.labelLarge(color: AppColors.white),
          ),
        ),
      ],
    );
  }
}
