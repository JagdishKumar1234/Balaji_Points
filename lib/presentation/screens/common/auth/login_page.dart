import 'package:balaji_points/core/constants/app_constants.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:balaji_points/presentation/widgets/shared/auth_scaffold.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:balaji_points/core/design/app_colors.dart';
import 'package:balaji_points/core/design/app_radius.dart';
import 'package:balaji_points/core/design/app_typography.dart';
import 'package:balaji_points/core/utils/back_button_handler.dart';
import 'package:balaji_points/l10n/app_localizations.dart';
import 'package:balaji_points/presentation/widgets/shared/professional_auth_card.dart';
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

  /// This is the first screen after logout, so Back offers to exit the app.
  Future<void> _handleBack() async {
    final router = GoRouter.of(context);
    if (router.canPop()) {
      router.pop();
      return;
    }
    final exit = await BackButtonHandler.showExitConfirmation(context);
    if (exit == true && mounted) BackButtonHandler.exitApp();
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
    final companyName = l10n?.companyName ?? AppConstants.companyName;
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

    final compact = MediaQuery.sizeOf(context).height < 760 || bottomInset > 0;
    final gap = compact ? 10.0 : 16.0;
    final cardPadding = compact ? 20.0 : 26.0;

    return AuthScaffold(
      // There is no web "exit", and the browser has its own back button.
      showBackButton: !kIsWeb,
      onBack: _handleBack,
      child: Form(
        key: _formKey,
        child: Column(
          children: [
            Text(
              AppLocalizations.of(context)!.welcomeBack2,
              textAlign: TextAlign.center,
              style: AppTypography.title(color: context.themeTextPrimary),
            ),
            Text(
              AppLocalizations.of(context)!.signInToContinueTo('$appName'),
              textAlign: TextAlign.center,
              style: AppTypography.bodySmall(color: context.themeTextSecondary),
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
                    style: AppTypography.title(color: context.themeTextPrimary),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    AppLocalizations.of(context)!.useYourEmailAndPasswordOr,
                    style: AppTypography.bodySmall(
                      color: context.themeTextSecondary,
                    ),
                  ),
                  SizedBox(height: gap),
                  AppTextField(
                    controller: _emailController,
                    label: AppLocalizations.of(context)!.email,
                    hint: AppLocalizations.of(context)!.hintEmail,
                    prefixIcon: Icons.email_outlined,
                    keyboardType: TextInputType.emailAddress,
                    validator: (value) {
                      final v = value?.trim() ?? '';
                      if (v.isEmpty ||
                          !RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(v)) {
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
                    label: AppLocalizations.of(context)!.passwordLabel,
                    hint: AppLocalizations.of(context)!.hintPassword,
                    prefixIcon: Icons.lock_outline_rounded,
                    obscureText: !_isPasswordVisible,
                    suffix: IconButton(
                      onPressed: () => setState(
                        () => _isPasswordVisible = !_isPasswordVisible,
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
                        AppLocalizations.of(context)!.forgotPassword,
                        style: AppTypography.bodyMedium(
                          color: context.themePrimary,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: gap),
                  AppButton.primary(
                    label: AppLocalizations.of(context)!.signIn,
                    onPressed: isChecking ? null : _loginWithEmail,
                    isLoading: isChecking,
                  ),
                  SizedBox(height: compact ? 10 : 16),
                  AppButton.strong(
                    label: AppLocalizations.of(context)!.loginWithPin,
                    icon: Icons.dialpad_rounded,
                    onPressed: isChecking
                        ? null
                        : () => context.push('/phone-pin-login'),
                  ),
                  SizedBox(height: compact ? 2 : 6),
                  _GoogleSignInButton(
                    onPressed: isChecking ? null : _loginWithGoogle,
                    isLoading: isChecking,
                  ),
                  const SizedBox(height: 4),
                  Center(
                    child: Wrap(
                      alignment: WrapAlignment.center,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Text(
                          AppLocalizations.of(context)!.newToBalajiPoints,
                          style: AppTypography.bodySmall(
                            color: context.themeTextSecondary,
                          ),
                        ),
                        TextButton(
                          onPressed: () => context.go('/register'),
                          style: TextButton.styleFrom(
                            foregroundColor: context.themePrimary,
                            minimumSize: const Size(48, 40),
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                          ),
                          child: Text(
                            AppLocalizations.of(context)!.createAccount2,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Not a member yet: ask a question without logging in.
                  Center(
                    child: TextButton.icon(
                      onPressed: () => context.push('/contact-us'),
                      style: TextButton.styleFrom(
                        foregroundColor: context.themeTextSecondary,
                        minimumSize: const Size(48, 40),
                      ),
                      icon: const Icon(Icons.support_agent_rounded, size: 18),
                      label: Text(AppLocalizations.of(context)!.contactUs),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: compact ? 8 : 16),
            AuthFooter(companyName: companyName, isDark: isDark),
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
