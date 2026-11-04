import 'package:balaji_points/presentation/widgets/shared/auth_scaffold.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:balaji_points/core/design/app_animations.dart';
import 'package:balaji_points/core/design/app_colors.dart';
import 'package:balaji_points/core/design/app_spacing.dart';
import 'package:balaji_points/core/design/app_typography.dart';
import 'package:balaji_points/l10n/app_localizations.dart';
import 'package:balaji_points/presentation/widgets/shared/app_button.dart';
import 'package:balaji_points/presentation/widgets/shared/app_text_field.dart';
import 'package:balaji_points/presentation/widgets/shared/professional_auth_card.dart';
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
    final role = state.role.trim().toLowerCase();
    context.go(
      role == 'super_admin'
          ? '/super-admin'
          : role == 'admin'
          ? '/admin'
          : '/',
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
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

    return AuthScaffold(
      fallbackRoute: '/phone-pin-login',
      child: Form(
        key: _formKey,
        child: Column(
          children: [
            ProfessionalAuthCard(
              isDark: isDark,
              securityMessage: AppLocalizations.of(
                context,
              )!.yourDataIs100SecureWith,
              child: Column(
                children: [
                  // Header with phone number
                  Column(
                    children: [
                      // Title
                      Text(
                        l10n.enter4DigitPin,
                        style: AppTypography.displaySmall(
                          color: context.themeTextPrimary,
                        ).copyWith(fontWeight: FontWeight.bold),
                        textAlign: TextAlign.center,
                      ).fadeIn(delay: AppAnimations.stagger(2)),
                      const SizedBox(height: 8),

                      // Phone number
                      Text(
                        '+91 ${widget.phoneNumber}',
                        style: AppTypography.bodyMedium(
                          color: context.themeTextSecondary,
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
                    hint: AppLocalizations.of(context)!.hintPin,
                    keyboardType: TextInputType.number,
                    obscureText: _obscure,
                    maxLength: 4,
                    textAlign: TextAlign.center,
                    letterSpacing: 14,
                    suffix: IconButton(
                      icon: Icon(
                        _obscure
                            ? Icons.visibility_off_rounded
                            : Icons.visibility_rounded,
                        color: context.themeTextSecondary,
                      ),
                      onPressed: () => setState(() => _obscure = !_obscure),
                    ),
                    validator: (v) =>
                        (v == null || v.length != 4) ? l10n.enter4Digits : null,
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
                          onTap: () =>
                              setState(() => _rememberMe = !_rememberMe),
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
                  AppButton.primary(
                    label: l10n.login,
                    onPressed: isLoggingIn ? null : _login,
                    isLoading: isLoggingIn,
                  ).fadeIn(delay: AppAnimations.stagger(6)),

                  const SizedBox(height: AppSpacing.md),

                  // Forgot PIN
                  AppButton.outline(
                    label: l10n.forgotPin,
                    onPressed: () =>
                        context.push('/pin-reset?phone=${widget.phoneNumber}'),
                  ).fadeIn(delay: AppAnimations.stagger(7)),
                ],
              ),
            ).enterCard(delay: AppAnimations.stagger(9)),
            const SizedBox(height: AppSpacing.xl2),
            AuthFooter(
              companyName: l10n.companyName,
              isDark: isDark,
            ).fadeIn(delay: AppAnimations.stagger(10)),
          ],
        ),
      ),
    );
  }
}
