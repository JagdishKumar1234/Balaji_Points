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
import 'package:balaji_points/core/utils/back_button_handler.dart';
import 'package:balaji_points/l10n/app_localizations.dart';
import 'package:balaji_points/presentation/widgets/shared/auth_background.dart';
import 'package:balaji_points/presentation/widgets/shared/professional_auth_card.dart';
import 'package:balaji_points/providers/locale_provider.dart';
import 'package:balaji_points/providers/theme_provider.dart';
import 'package:balaji_points/presentation/widgets/shared/app_button.dart';
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

  Widget _buildDeviceAuthCard(BuildContext context, bool isDark) {
    return Container(
      margin: EdgeInsets.only(bottom: AuthDesign.largeSpacing),
      padding: EdgeInsets.all(AuthDesign.cardSpacing),
      decoration: BoxDecoration(
        color: isDark
            ? AppColors.darkSurface.withValues(alpha: 0.88)
            : AppColors.white.withValues(alpha: 0.90),
        borderRadius: BorderRadius.circular(AppRadius.sm),
        border: Border.all(
          color: isDark
              ? AppColors.darkBorder.withValues(alpha: 0.5)
              : context.themePrimary.withValues(alpha: 0.18),
          width: AuthDesign.textFieldBorderWidth,
        ),
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
    final isDark = Theme.of(context).brightness == Brightness.dark;

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

                      // ── Professional Auth Card ──
                      ProfessionalAuthCard(
                        isDark: isDark,
                        securityMessage: 'Your data is 100% secure with us',
                        child: Column(
                          children: [
                            // Header with logo
                            AuthHeader(
                              logoPath: 'assets/images/balaji_point_logo.png',
                              title: l10n.appName,
                              subtitle: l10n.enterPhoneNumber,
                              isDark: isDark,
                            ).enterHero(delay: AppAnimations.stagger(1)),

                            const SizedBox(height: AppSpacing.xl3),

                            // Phone input
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
                            ).fadeIn(delay: AppAnimations.stagger(2)),

                            const SizedBox(height: AppSpacing.xl2),

                            // Continue button
                            AppButton.secondary(
                              label: l10n.continueWithPin,
                              onPressed: isChecking
                                  ? null
                                  : _checkUserAndNavigate,
                              isLoading: isChecking,
                            ).fadeIn(delay: AppAnimations.stagger(3)),
                          ],
                        ),
                      ).enterCard(delay: AppAnimations.stagger(4)),

                      const SizedBox(height: AppSpacing.xl2),

                      // ── Footer ──
                      AuthFooter(
                        companyName: l10n.companyName,
                        isDark: isDark,
                      ).fadeIn(delay: AppAnimations.stagger(5)),

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
      height: 40,
      width: 40,
      decoration: BoxDecoration(
        color: isDark
            ? AppColors.darkSurface.withValues(alpha: 0.85)
            : AppColors.white.withValues(alpha: 0.90),
        borderRadius: AppRadius.sm8,
        border: Border.all(
          color: isDark
              ? AppColors.darkBorder.withValues(alpha: 0.5)
              : context.themePrimary.withValues(alpha: 0.30),
        ),
      ),
      child: IconButton(
        padding: EdgeInsets.zero,
        tooltip: isDark ? 'Switch to Light' : 'Switch to Dark',
        onPressed: () => ref.read(themeModeProvider.notifier).toggleTheme(),
        icon: AnimatedSwitcher(
          duration: const Duration(milliseconds: 250),
          transitionBuilder: (child, anim) =>
              RotationTransition(turns: anim, child: child),
          child: Icon(
            isDark ? Icons.wb_sunny_rounded : Icons.nightlight_round,
            key: ValueKey(isDark),
            size: 20,
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
      height: 40,
      decoration: BoxDecoration(
        color: isDark
            ? AppColors.darkSurface.withValues(alpha: 0.85)
            : AppColors.white.withValues(alpha: 0.90),
        borderRadius: AppRadius.sm8,
        border: Border.all(
          color: isDark
              ? AppColors.darkBorder.withValues(alpha: 0.5)
              : context.themePrimary.withValues(alpha: 0.30),
        ),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<Locale>(
          value: ref.watch(localeProvider),
          style: AppTypography.bodyMedium(color: context.themeTextPrimary),
          dropdownColor: context.themeSurface,
          iconEnabledColor: isDark ? AppColors.white : context.themePrimary,
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
  final bool isDark;
  const _GlassCard({required this.child, required this.isDark});

  @override
  Widget build(BuildContext context) {
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
