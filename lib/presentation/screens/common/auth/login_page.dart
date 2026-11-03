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

    final appName = l10n?.appName ?? AppLocalizations.of(context)!.appName;
    final errorLabel = l10n?.error ?? AppLocalizations.of(context)!.error;
    final companyName = l10n?.companyName ?? 'Aajii Tech Studio';
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
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final compact =
                      constraints.maxHeight < 760 || bottomInset > 0;
                  final gap = compact ? 10.0 : 16.0;
                  final cardPadding = compact ? 20.0 : 26.0;
                  return SingleChildScrollView(
                    padding: EdgeInsets.only(bottom: bottomInset + 12),
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        minHeight: constraints.maxHeight,
                      ),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          children: [
                            AuthTopControls(
                              themeToggle: _ThemeToggleButton(isDark: isDark),
                              languagePicker: _LanguagePicker(),
                            ),
                            SizedBox(height: compact ? 8 : 14),
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 24,
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    width: 52,
                                    height: 52,
                                    decoration: BoxDecoration(
                                      color: context.themeCard,
                                      borderRadius: AppRadius.all16,
                                      boxShadow: context.themeShadow,
                                    ),
                                    padding: const EdgeInsets.all(8),
                                    child: Image.asset(
                                      'assets/images/balaji_point_logo.png',
                                      fit: BoxFit.contain,
                                      errorBuilder: (_, __, ___) => Icon(
                                        Icons.workspace_premium_rounded,
                                        color: context.themePrimary,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          AppLocalizations.of(
                                            context,
                                          )!.welcomeBack2,
                                          style: AppTypography.title(
                                            color: context.themeTextPrimary,
                                          ),
                                        ),
                                        Text(
                                          AppLocalizations.of(
                                            context,
                                          )!.signInToContinueTo('$appName'),
                                          style: AppTypography.bodySmall(
                                            color: context.themeTextSecondary,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            SizedBox(height: gap),
                            ProfessionalAuthCard(
                              isDark: isDark,
                              padding: EdgeInsets.all(cardPadding),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  Text(
                                    AppLocalizations.of(context)!.signIn,
                                    style: AppTypography.title(
                                      color: context.themeTextPrimary,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    AppLocalizations.of(
                                      context,
                                    )!.useYourEmailAndPasswordOr,
                                    style: AppTypography.bodySmall(
                                      color: context.themeTextSecondary,
                                    ),
                                  ),
                                  SizedBox(height: gap),
                                  AppTextField(
                                    controller: _emailController,
                                    label: AppLocalizations.of(context)!.email,
                                    prefixIcon: Icons.email_outlined,
                                    keyboardType: TextInputType.emailAddress,
                                    validator: (value) {
                                      final v = value?.trim() ?? '';
                                      if (v.isEmpty ||
                                          !RegExp(
                                            r'^[^@\s]+@[^@\s]+\.[^@\s]+$',
                                          ).hasMatch(v)) {
                                        return AppLocalizations.of(
                                          context,
                                        )!.pleaseEnterAValidEmailAddress;
                                      }
                                      return null;
                                    },
                                  ),
                                  SizedBox(height: gap),
                                  AppTextField(
                                    controller: _passwordController,
                                    label: AppLocalizations.of(
                                      context,
                                    )!.passwordLabel,
                                    prefixIcon: Icons.lock_outline_rounded,
                                    obscureText: !_isPasswordVisible,
                                    suffix: IconButton(
                                      onPressed: () => setState(
                                        () => _isPasswordVisible =
                                            !_isPasswordVisible,
                                      ),
                                      icon: Icon(
                                        _isPasswordVisible
                                            ? Icons.visibility_off_rounded
                                            : Icons.visibility_rounded,
                                        color: context.themePrimary,
                                      ),
                                    ),
                                    validator: (value) {
                                      final v = value ?? '';
                                      if (v.isEmpty || v.length < 6) {
                                        return AppLocalizations.of(
                                          context,
                                        )!.passwordMustBeAtLeast6;
                                      }
                                      return null;
                                    },
                                  ),
                                  const SizedBox(height: 2),
                                  Align(
                                    alignment: Alignment.centerRight,
                                    child: TextButton(
                                      onPressed: () => context.push(
                                        '/forgot-password',
                                        extra: _emailController.text.trim(),
                                      ),
                                      child: Text(
                                        AppLocalizations.of(
                                          context,
                                        )!.forgotPassword,
                                        style: AppTypography.bodyMedium(
                                          color: context.themePrimary,
                                        ),
                                      ),
                                    ),
                                  ),
                                  SizedBox(height: gap),
                                  AppButton.primary(
                                    label: AppLocalizations.of(context)!.signIn,
                                    onPressed: isChecking
                                        ? null
                                        : _loginWithEmail,
                                    isLoading: isChecking,
                                  ),
                                  SizedBox(height: compact ? 10 : 16),
                                  TextButton.icon(
                                    onPressed: isChecking
                                        ? null
                                        : () =>
                                              context.push('/phone-pin-login'),
                                    icon: const Icon(
                                      Icons.dialpad_rounded,
                                      size: 18,
                                    ),
                                    label: Text(
                                      AppLocalizations.of(
                                        context,
                                      )!.loginWithPin,
                                    ),
                                    style: TextButton.styleFrom(
                                      foregroundColor: context.themePrimary,
                                      minimumSize: const Size(48, 44),
                                    ),
                                  ),
                                  SizedBox(height: compact ? 2 : 6),
                                  _GoogleSignInButton(
                                    onPressed: isChecking
                                        ? null
                                        : _loginWithGoogle,
                                    isLoading: isChecking,
                                  ),
                                  const SizedBox(height: 4),
                                  Center(
                                    child: Wrap(
                                      alignment: WrapAlignment.center,
                                      crossAxisAlignment:
                                          WrapCrossAlignment.center,
                                      children: [
                                        Text(
                                          AppLocalizations.of(
                                            context,
                                          )!.newToBalajiPoints,
                                          style: AppTypography.bodySmall(
                                            color: context.themeTextSecondary,
                                          ),
                                        ),
                                        TextButton(
                                          onPressed: () =>
                                              context.go('/register'),
                                          style: TextButton.styleFrom(
                                            foregroundColor:
                                                context.themePrimary,
                                            minimumSize: const Size(48, 40),
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 8,
                                            ),
                                          ),
                                          child: Text(
                                            AppLocalizations.of(
                                              context,
                                            )!.createAccount2,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            SizedBox(height: compact ? 8 : 16),
                            Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: Text(
                                AppLocalizations.of(
                                  context,
                                )!.designedAndDevelopedBy('$companyName'),
                                textAlign: TextAlign.center,
                                style: AppTypography.bodySmall(
                                  color: context.themeTextSecondary,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _GoogleSignInButton extends StatelessWidget {
  const _GoogleSignInButton({required this.onPressed, required this.isLoading});

  final VoidCallback? onPressed;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return SizedBox(
      height: 50,
      width: double.infinity,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          backgroundColor: Colors.white,
          foregroundColor: const Color(0xFF3C4043),
          side: BorderSide(color: scheme.outlineVariant),
          shape: RoundedRectangleBorder(borderRadius: AppRadius.all16),
          textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
        ),
        child: isLoading
            ? SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: scheme.primary,
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox(
                    width: 20,
                    height: 20,
                    child: CustomPaint(painter: _GoogleMarkPainter()),
                  ),
                  const SizedBox(width: 12),
                  Text(AppLocalizations.of(context)!.signInWithGoogle),
                ],
              ),
      ),
    );
  }
}

class _GoogleMarkPainter extends CustomPainter {
  const _GoogleMarkPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final stroke = size.width * .22;
    final colors = <Color>[
      const Color(0xFF4285F4),
      const Color(0xFF34A853),
      const Color(0xFFFBBC05),
      const Color(0xFFEA4335),
    ];
    final starts = <double>[-.55, .95, 2.45, 3.95];
    for (var i = 0; i < colors.length; i++) {
      canvas.drawArc(
        rect.deflate(stroke / 2),
        starts[i],
        1.28,
        false,
        Paint()
          ..color = colors[i]
          ..style = PaintingStyle.stroke
          ..strokeWidth = stroke
          ..strokeCap = StrokeCap.butt,
      );
    }
    canvas.drawRect(
      Rect.fromLTWH(
        size.width * .51,
        size.height * .43,
        size.width * .49,
        stroke,
      ),
      Paint()..color = const Color(0xFF4285F4),
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
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
        tooltip: isDark
            ? AppLocalizations.of(context)!.switchToLight
            : AppLocalizations.of(context)!.switchToDark,
        onPressed: () => ref.read(themeModeProvider.notifier).toggleTheme(),
        icon: AnimatedSwitcher(
          duration: const Duration(milliseconds: 250),
          transitionBuilder: (child, anim) =>
              RotationTransition(turns: anim, child: child),
          child: Icon(
            isDark ? Icons.wb_sunny_rounded : Icons.nightlight_round_rounded,
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
              child: Text(
                l10n?.languageEnglish ??
                    AppLocalizations.of(context)!.languageEnglish,
              ),
            ),
            DropdownMenuItem(
              value: const Locale('hi'),
              child: Text(
                l10n?.languageHindi ?? AppLocalizations.of(context)!.hindi,
              ),
            ),
            DropdownMenuItem(
              value: const Locale('ta'),
              child: Text(
                l10n?.languageTamil ?? AppLocalizations.of(context)!.tamil,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
