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
import 'package:balaji_points/presentation/widgets/shared/app_button.dart';
import 'package:balaji_points/presentation/widgets/shared/app_text.dart';
import 'package:balaji_points/presentation/widgets/shared/app_text_field.dart';
import 'package:balaji_points/services/auth/biometric_service.dart';
import 'package:balaji_points/services/auth/session_service.dart';
import 'package:balaji_points/services/notifications/fcm_service.dart';
import '../../../../providers/auth_provider.dart';

class LoginPage extends ConsumerStatefulWidget {
  const LoginPage({super.key});

  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage> {
  final _phoneController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  final SessionService _sessionService = SessionService();
  bool _canUseDeviceAuth = false;
  bool _isDeviceAuthLoading = false;
  String? _rememberedPhone;

  @override
  void initState() {
    super.initState();
    _loadStoredSession();
  }

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

  Future<void> _loadStoredSession() async {
    final isLoggedIn = await _sessionService.isLoggedIn();
    if (!isLoggedIn) return;

    final savedPhone = await _sessionService.getPhoneNumber();
    final biometricEnabled = await _sessionService.isBiometricEnabled();
    final deviceAvailable =
        biometricEnabled && await BiometricService().isAvailable();

    if (!mounted) return;
    setState(() {
      _rememberedPhone = savedPhone;
      _canUseDeviceAuth =
          deviceAvailable && savedPhone != null && savedPhone.isNotEmpty;
    });
  }

  Future<void> _authenticateWithDevice() async {
    setState(() => _isDeviceAuthLoading = true);
    final authenticated = await BiometricService().authenticate(
      localizedReason: 'Verify your identity to open Balaji Points',
    );

    if (!mounted) return;
    setState(() => _isDeviceAuthLoading = false);

    final messenger = ScaffoldMessenger.of(context);
    final errorColor = context.themeError;

    if (!authenticated) {
      messenger.showSnackBar(
        SnackBar(
          content: const Text('Authentication failed. Please try again.'),
          backgroundColor: errorColor,
        ),
      );
      return;
    }

    final isLoggedIn = await _sessionService.isLoggedIn();
    if (!isLoggedIn) {
      messenger.showSnackBar(
        SnackBar(
          content: const Text(
            'No stored session found. Please login with PIN.',
          ),
          backgroundColor: errorColor,
        ),
      );
      return;
    }

    final role = await _sessionService.getUserRole();
    FCMService().processPendingNavigation();
    if (!mounted) return;

    if (role?.trim().toLowerCase() == 'admin') {
      context.go('/admin');
    } else {
      context.go('/');
    }
  }

  Widget _buildDeviceAuthCard(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.xl3),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.white.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(AppRadius.sm),
        border: Border.all(color: context.themePrimary.withValues(alpha: 0.18)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Use device authentication',
            style: AppTypography.bodyLarge(
              color: context.themePrimary,
            ).copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            _rememberedPhone != null
                ? '+91 $_rememberedPhone'
                : 'Use your saved session',
            style: AppTypography.bodyMedium(color: context.themeTextSecondary),
          ),
          const SizedBox(height: AppSpacing.md),
          AppButton.secondary(
            label: 'Login with device authentication',
            icon: Icons.fingerprint,
            onPressed: _isDeviceAuthLoading ? null : _authenticateWithDevice,
            isLoading: _isDeviceAuthLoading,
          ),
        ],
      ),
    );
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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${l10n.error}: ${state.message}'),
            backgroundColor: context.themeError,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    });

    final isChecking = ref.watch(authProvider) is AuthCheckingUser;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
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
            Image.asset(
              'assets/images/background_image.png',
              fit: BoxFit.cover,
            ),

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
                        AppText.h2(
                          'Balaji Points',
                          color: context.themePrimary,
                        ).enterHero(delay: AppAnimations.stagger(2)),

                        const SizedBox(height: AppSpacing.xl2),

                        AppText.bodyLarge(
                          l10n.enterPhoneNumber,
                          color: context.themeTextSecondary,
                        ).fadeIn(delay: AppAnimations.stagger(3)),

                        const SizedBox(height: AppSpacing.xl3),
                        if (_canUseDeviceAuth) ...[
                          _buildDeviceAuthCard(context),
                        ],

                        // ── Glass card ──
                        _GlassCard(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              // Phone field
                              AppTextField.phone(
                                controller: _phoneController,
                                label: l10n.mobileNumber,
                                validator: (value) {
                                  final v = value?.trim() ?? '';
                                  if (v.length != 10 ||
                                      !RegExp(r'^[0-9]+$').hasMatch(v)) {
                                    return l10n.enterValidTenDigit;
                                  }
                                  return null;
                                },
                              ),

                              const SizedBox(height: AppSpacing.xl),

                              // Continue button
                              AppButton.secondary(
                                label: l10n.continueWithPin,
                                onPressed: isChecking
                                    ? null
                                    : _checkUserAndNavigate,
                                isLoading: isChecking,
                              ),
                            ],
                          ),
                        ).enterCard(delay: AppAnimations.stagger(4)),

                        const SizedBox(height: AppSpacing.xl),

                        // ── Footer ──
                        AppText.label(
                          '${l10n.poweredBy} ${l10n.companyName}',
                          color: context.themePrimary,
                          shadows: [
                            Shadow(
                              color: AppColors.white.withValues(alpha: 0.8),
                              blurRadius: 10,
                            ),
                          ],
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
        border: Border.all(color: context.themePrimary.withValues(alpha: 0.3)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<Locale>(
          value: ref.watch(localeProvider),
          style: AppTypography.bodyMedium(color: context.themeTextPrimary),
          onChanged: (locale) {
            if (locale != null) {
              ref.read(localeProvider.notifier).setLocale(locale);
            }
          },
          items: [
            DropdownMenuItem(
              value: const Locale('en'),
              child: Text(l10n.languageEnglish),
            ),
            DropdownMenuItem(
              value: const Locale('hi'),
              child: Text(l10n.languageHindi),
            ),
            DropdownMenuItem(
              value: const Locale('ta'),
              child: Text(l10n.languageTamil),
            ),
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
