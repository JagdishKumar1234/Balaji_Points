import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:balaji_points/core/design/app_animations.dart';
import 'package:balaji_points/core/design/app_colors.dart';
import 'package:balaji_points/core/design/app_radius.dart';
import 'package:balaji_points/core/design/app_spacing.dart';
import 'package:balaji_points/core/design/app_typography.dart';
import 'package:balaji_points/core/utils/back_button_handler.dart';
import 'package:balaji_points/l10n/app_localizations.dart';
import 'package:balaji_points/providers/locale_provider.dart';
import '../../../../providers/auth_provider.dart';

class LoginPage extends ConsumerStatefulWidget {
  const LoginPage({super.key});

  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage> {
  final _phoneController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  void _checkUserAndNavigate() {
    if (!_formKey.currentState!.validate()) return;
    final phone = _phoneController.text.trim();
    if (phone.isEmpty) return;
    ref.read(authProvider.notifier).checkUserExists(phone);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    ref.listen<AuthState>(authProvider, (_, state) {
      if (state is AuthUserExists) {
        context.push('/pin-login?phone=${state.phoneNumber}');
      } else if (state is AuthUserNotFound) {
        context.push('/pin-setup?phone=${state.phoneNumber}');
      } else if (state is AuthError) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('${l10n.error}: ${state.message}'),
          backgroundColor: AppColors.error,
          duration: const Duration(seconds: 3),
        ));
      }
    });

    final isChecking = ref.watch(authProvider) is AuthCheckingUser;

    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) async {
        if (!didPop) {
          if (Navigator.of(context).canPop()) {
            Navigator.of(context).pop();
            return;
          }
          final exit = await BackButtonHandler.showExitConfirmation(context);
          if (exit == true && mounted) BackButtonHandler.exitApp();
        }
      },
      child: Scaffold(
        backgroundColor: AppColors.transparent,
        body: Stack(
          fit: StackFit.expand,
          children: [
            // ── Background ──
            Image.asset('assets/images/background_image.png', fit: BoxFit.cover),

            // ── Content ──
            SafeArea(
              bottom: false,
              child: SingleChildScrollView(
                padding: EdgeInsets.only(bottom: bottomInset + AppSpacing.xl),
                child: Padding(
                  padding: AppSpacing.screenHorizontal,
                  child: Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        const SizedBox(height: AppSpacing.lg),

                        // ── Language switcher ──
                        Align(
                          alignment: Alignment.centerRight,
                          child: _LanguagePicker(),
                        ).fadeIn(delay: AppAnimations.stagger(0)),

                        const SizedBox(height: AppSpacing.xl),

                        // ── Logo ──
                        ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: Image.asset(
                            'assets/images/balaji_point_logo.png',
                            width: 96,
                            height: 96,
                            fit: BoxFit.cover,
                          ),
                        ).enterHero(delay: AppAnimations.stagger(1)),

                        const SizedBox(height: AppSpacing.md),

                        // ── Title ──
                        Text(
                          'Balaji Points',
                          style: AppTypography.displaySmall(
                            color: AppColors.lightPrimary,
                          ),
                        ).enterHero(delay: AppAnimations.stagger(2)),

                        const SizedBox(height: AppSpacing.xl2),

                        Text(
                          l10n.enterPhoneNumber,
                          style: AppTypography.bodyLarge(
                            color: AppColors.lightTextSecondary,
                          ),
                        ).fadeIn(delay: AppAnimations.stagger(3)),

                        const SizedBox(height: AppSpacing.xl3),

                        // ── Glass card ──
                        _GlassCard(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              // Phone field
                              TextFormField(
                                controller: _phoneController,
                                maxLength: 10,
                                keyboardType: TextInputType.phone,
                                style: AppTypography.h5(color: AppColors.lightTextPrimary),
                                decoration: InputDecoration(
                                  labelText: l10n.mobileNumber,
                                  labelStyle: AppTypography.bodyMedium(
                                    color: AppColors.lightTextSecondary,
                                  ),
                                  prefixText: '+91 ',
                                  prefixStyle: AppTypography.h5(color: AppColors.lightPrimary),
                                  counterText: '',
                                  filled: true,
                                  fillColor: AppColors.lightPrimary.withValues(alpha: 0.05),
                                  border: OutlineInputBorder(
                                    borderRadius: AppRadius.forInput,
                                    borderSide: BorderSide(
                                      color: AppColors.lightPrimary.withValues(alpha: 0.3),
                                      width: 1.5,
                                    ),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: AppRadius.forInput,
                                    borderSide: BorderSide(
                                      color: AppColors.lightPrimary.withValues(alpha: 0.2),
                                      width: 1.5,
                                    ),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: AppRadius.forInput,
                                    borderSide: const BorderSide(
                                      color: AppColors.lightPrimary,
                                      width: 2,
                                    ),
                                  ),
                                ),
                                validator: (value) {
                                  final v = value?.trim() ?? '';
                                  if (v.length != 10 || !RegExp(r'^[0-9]+$').hasMatch(v)) {
                                    return l10n.enterValidTenDigit;
                                  }
                                  return null;
                                },
                              ),

                              const SizedBox(height: AppSpacing.xl),

                              // Continue button
                              _GradientButton(
                                onPressed: isChecking ? null : _checkUserAndNavigate,
                                isLoading: isChecking,
                                label: l10n.continueWithPin,
                              ),
                            ],
                          ),
                        ).enterCard(delay: AppAnimations.stagger(4)),

                        const SizedBox(height: AppSpacing.xl),

                        // ── Footer ──
                        Text(
                          '${l10n.poweredBy} ${l10n.companyName}',
                          style: AppTypography.labelMedium(
                            color: AppColors.lightPrimary,
                          ).copyWith(
                            fontWeight: FontWeight.w700,
                            shadows: [
                              Shadow(
                                color: AppColors.white.withValues(alpha: 0.8),
                                blurRadius: 10,
                              ),
                            ],
                          ),
                        ).fadeIn(delay: AppAnimations.stagger(5)),

                        const SizedBox(height: AppSpacing.xl3),
                      ],
                    ),
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

// ── Language picker ──────────────────────────────────────────────────────────

class _LanguagePicker extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
      height: 40,
      decoration: BoxDecoration(
        color: AppColors.white.withValues(alpha: 0.9),
        borderRadius: AppRadius.sm8,
        border: Border.all(color: AppColors.lightPrimary.withValues(alpha: 0.3)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<Locale>(
          value: ref.watch(localeProvider),
          style: AppTypography.bodyMedium(color: AppColors.lightTextPrimary),
          onChanged: (locale) {
            if (locale != null) ref.read(localeProvider.notifier).setLocale(locale);
          },
          items: [
            DropdownMenuItem(value: const Locale('en'), child: Text(l10n.languageEnglish)),
            DropdownMenuItem(value: const Locale('hi'), child: Text(l10n.languageHindi)),
            DropdownMenuItem(value: const Locale('ta'), child: Text(l10n.languageTamil)),
          ],
        ),
      ),
    );
  }
}

// ── Glass-morphism card ───────────────────────────────────────────────────────

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
                color: AppColors.lightPrimary.withValues(alpha: 0.10),
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

// ── Gradient button ───────────────────────────────────────────────────────────

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
            AppColors.lightSecondary,
            AppColors.lightSecondary.withValues(alpha: 0.82),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: AppRadius.forButton,
        boxShadow: [
          BoxShadow(
            color: AppColors.lightSecondary.withValues(alpha: 0.35),
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
