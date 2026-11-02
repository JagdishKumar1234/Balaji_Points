import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:balaji_points/core/design/app_colors.dart';
import 'package:balaji_points/core/design/app_radius.dart';
import 'package:balaji_points/core/design/app_spacing.dart';
import 'package:balaji_points/core/design/app_typography.dart';
import 'package:balaji_points/core/utils/back_button_handler.dart';
import 'package:balaji_points/l10n/app_localizations.dart';
import 'package:balaji_points/presentation/widgets/shared/auth_background.dart';
import 'package:balaji_points/presentation/widgets/shared/professional_auth_card.dart';
import 'package:balaji_points/providers/locale_provider.dart';
import 'package:balaji_points/providers/theme_provider.dart';
import 'package:balaji_points/presentation/widgets/shared/app_button.dart';
import 'package:balaji_points/presentation/widgets/shared/app_text_field.dart';
import '../../../../providers/auth_provider.dart';

class LoginPage extends ConsumerStatefulWidget {
  const LoginPage({super.key});

  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isPasswordVisible = false;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _loginWithEmail() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);
    try {
      await ref
          .read(authProvider.notifier)
          .loginWithEmailAndPassword(
            email: _emailController.text,
            password: _passwordController.text,
          );
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  Future<void> _loginWithGoogle() async {
    setState(() => _isSubmitting = true);
    try {
      await ref.read(authProvider.notifier).loginWithGoogle();
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    AppLocalizations? l10n;
    try {
      l10n = AppLocalizations.of(context);
    } catch (_) {
      l10n = null;
    }

    final appName = l10n?.appName ?? 'Balaji Points';
    final errorLabel = l10n?.error ?? 'Error';
    final companyName = l10n?.companyName ?? 'Balaji Points';
    final subtitle = l10n?.enterPhoneNumber ?? 'Sign in with your email';
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    ref.listen<AuthState>(authProvider, (_, state) {
      if (state is AuthAuthenticated) {
        final destination = switch (state.role) {
          'super_admin' => '/super-admin',
          'admin' => '/admin',
          _ => '/',
        };
        context.go(destination);
      } else if (state is AuthProfileCompletionRequired) {
        context.go(
          '/complete-registration',
          extra: {
            'email': state.email,
            'displayName': state.displayName,
            'existingRole': state.existingRole,
          },
        );
      } else if (state is AuthError) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$errorLabel: ${state.message}'),
            backgroundColor: context.themeError,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    });

    final isChecking = _isSubmitting;

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
            AuthBackground(isDark: isDark),
            SafeArea(
              bottom: false,
              child: SingleChildScrollView(
                padding: EdgeInsets.only(bottom: bottomInset + AppSpacing.xl),
                child: Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      AuthTopControls(
                        themeToggle: _ThemeToggleButton(isDark: isDark),
                        languagePicker: _LanguagePicker(),
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      Stack(
                        children: [
                          ProfessionalAuthCard(
                            isDark: isDark,
                            securityMessage: 'Your data is 100% secure with us',
                            child: Column(
                              children: [
                                AuthHeader(
                                  logoPath:
                                      'assets/images/balaji_point_logo.png',
                                  title: appName,
                                  subtitle: subtitle,
                                  isDark: isDark,
                                ),
                                const SizedBox(height: AppSpacing.xl3),
                                AppTextField(
                                  controller: _emailController,
                                  label: 'Email',
                                  prefixIcon: Icons.email_outlined,
                                  keyboardType: TextInputType.emailAddress,
                                  validator: (value) {
                                    final v = value?.trim() ?? '';
                                    if (v.isEmpty ||
                                        !RegExp(
                                          r'^[^@\s]+@[^@\s]+\.[^@\s]+$',
                                        ).hasMatch(v)) {
                                      return 'Please enter a valid email address';
                                    }
                                    return null;
                                  },
                                ),
                                const SizedBox(height: AppSpacing.lg),
                                AppTextField(
                                  controller: _passwordController,
                                  label: 'Password',
                                  prefixIcon: Icons.lock_outline,
                                  obscureText: !_isPasswordVisible,
                                  suffix: IconButton(
                                    onPressed: () => setState(
                                      () => _isPasswordVisible =
                                          !_isPasswordVisible,
                                    ),
                                    icon: Icon(
                                      _isPasswordVisible
                                          ? Icons.visibility_off
                                          : Icons.visibility,
                                      color: context.themePrimary,
                                    ),
                                  ),
                                  validator: (value) {
                                    final v = value ?? '';
                                    if (v.isEmpty || v.length < 6) {
                                      return 'Password must be at least 6 characters';
                                    }
                                    return null;
                                  },
                                ),
                                const SizedBox(height: AppSpacing.md),
                                Align(
                                  alignment: Alignment.centerRight,
                                  child: TextButton(
                                    onPressed: () => context.push(
                                      '/forgot-password',
                                      extra: _emailController.text.trim(),
                                    ),
                                    child: Text(
                                      'Forgot password?',
                                      style: AppTypography.bodyMedium(
                                        color: context.themePrimary,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: AppSpacing.xl2),
                                AppButton.primary(
                                  label: 'Sign in',
                                  onPressed: isChecking
                                      ? null
                                      : _loginWithEmail,
                                  isLoading: isChecking,
                                ),
                                const SizedBox(height: AppSpacing.md),
                                AppButton.secondary(
                                  label: 'Login with PIN',
                                  icon: Icons.dialpad_rounded,
                                  onPressed: isChecking
                                      ? null
                                      : () => context.push('/phone-pin-login'),
                                ),
                                const SizedBox(height: AppSpacing.xs),
                                Text(
                                  'For existing users with a mobile number and PIN',
                                  textAlign: TextAlign.center,
                                  style: AppTypography.bodySmall(
                                    color: context.themeTextSecondary,
                                  ),
                                ),
                                const SizedBox(height: AppSpacing.md),
                                AppButton.secondary(
                                  label: 'Sign in with Google',
                                  icon: Icons.g_mobiledata_rounded,
                                  onPressed: isChecking
                                      ? null
                                      : _loginWithGoogle,
                                ),
                                const SizedBox(height: AppSpacing.sm),
                                TextButton(
                                  onPressed: () => context.go('/register'),
                                  child: const Text('Create an account'),
                                ),
                              ],
                            ),
                          ),
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
                                borderRadius: const BorderRadius.all(
                                  Radius.circular(99),
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.all(8),
                                  child: Icon(
                                    Icons.arrow_back_rounded,
                                    color: context.themePrimary,
                                    size: 24,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.xl2),
                      AuthFooter(companyName: companyName, isDark: isDark),
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

class _LanguagePicker extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    AppLocalizations? l10n;
    try {
      l10n = AppLocalizations.of(context);
    } catch (_) {
      l10n = null;
    }

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
              child: Text(l10n?.languageEnglish ?? 'English'),
            ),
            DropdownMenuItem(
              value: const Locale('hi'),
              child: Text(l10n?.languageHindi ?? 'Hindi'),
            ),
            DropdownMenuItem(
              value: const Locale('ta'),
              child: Text(l10n?.languageTamil ?? 'Tamil'),
            ),
          ],
        ),
      ),
    );
  }
}
