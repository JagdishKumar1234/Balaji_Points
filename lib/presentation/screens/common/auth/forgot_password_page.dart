import 'package:flutter/material.dart';
import 'package:balaji_points/l10n/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:balaji_points/core/design/app_colors.dart';
import 'package:balaji_points/core/design/app_spacing.dart';
import 'package:balaji_points/core/design/app_typography.dart';
import 'package:balaji_points/presentation/widgets/shared/app_button.dart';
import 'package:balaji_points/presentation/widgets/shared/app_text_field.dart';
import 'package:balaji_points/presentation/widgets/shared/auth_background.dart';
import 'package:balaji_points/presentation/widgets/shared/professional_auth_card.dart';
import '../../../../providers/auth_provider.dart';

class ForgotPasswordPage extends ConsumerStatefulWidget {
  const ForgotPasswordPage({super.key, this.initialEmail});

  final String? initialEmail;

  @override
  ConsumerState<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends ConsumerState<ForgotPasswordPage> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _emailController;
  bool _isSubmitting = false;
  bool _emailSent = false;

  @override
  void initState() {
    super.initState();
    _emailController = TextEditingController(text: widget.initialEmail ?? '');
  }

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _sendResetEmail() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSubmitting = true;
      _emailSent = false;
    });
    try {
      await ref
          .read(authProvider.notifier)
          .resetPassword(email: _emailController.text.trim());
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    ref.listen<AuthState>(authProvider, (_, state) {
      if (state is AuthPasswordResetSent) {
        setState(() => _emailSent = true);
      } else if (state is AuthError) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(state.message),
            backgroundColor: context.themeError,
          ),
        );
      }
    });

    return Scaffold(
      backgroundColor: AppColors.transparent,
      body: Stack(
        fit: StackFit.expand,
        children: [
          AuthBackground(isDark: isDark),
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 520),
                  child: ProfessionalAuthCard(
                    isDark: isDark,
                    securityMessage: AppLocalizations.of(
                      context,
                    )!.passwordResetLinksAreSentSecurely,
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Align(
                            alignment: Alignment.centerLeft,
                            child: IconButton(
                              tooltip: AppLocalizations.of(
                                context,
                              )!.backToSignIn,
                              onPressed: () => context.go('/login'),
                              icon: const Icon(Icons.arrow_back_rounded),
                            ),
                          ),
                          const SizedBox(height: AppSpacing.sm),
                          Icon(
                            _emailSent
                                ? Icons.mark_email_read_outlined
                                : Icons.lock_reset_rounded,
                            size: 52,
                            color: _emailSent
                                ? AppColors.success
                                : context.themePrimary,
                          ),
                          const SizedBox(height: AppSpacing.md),
                          Text(
                            _emailSent
                                ? AppLocalizations.of(context)!.checkYourEmail
                                : AppLocalizations.of(context)!.forgotPassword,
                            textAlign: TextAlign.center,
                            style: AppTypography.displaySmall(
                              color: context.themeTextPrimary,
                            ),
                          ),
                          const SizedBox(height: AppSpacing.sm),
                          Text(
                            _emailSent
                                ? AppLocalizations.of(
                                    context,
                                  )!.ifAnAccountExistsForThis
                                : AppLocalizations.of(
                                    context,
                                  )!.enterTheEmailAddressLinkedTo,
                            textAlign: TextAlign.center,
                            style: AppTypography.bodyMedium(
                              color: context.themeTextSecondary,
                            ),
                          ),
                          const SizedBox(height: AppSpacing.xl2),
                          AppTextField(
                            controller: _emailController,
                            label: AppLocalizations.of(context)!.email,
                            prefixIcon: Icons.email_outlined,
                            keyboardType: TextInputType.emailAddress,
                            validator: (value) {
                              final email = value?.trim() ?? '';
                              if (!RegExp(
                                r'^[^@\s]+@[^@\s]+\.[^@\s]+$',
                              ).hasMatch(email)) {
                                return AppLocalizations.of(
                                  context,
                                )!.enterAValidEmailAddress;
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: AppSpacing.lg),
                          AppButton.primary(
                            label: _emailSent
                                ? AppLocalizations.of(
                                    context,
                                  )!.sendAnotherResetLink
                                : AppLocalizations.of(context)!.sendResetLink,
                            isLoading: _isSubmitting,
                            onPressed: _isSubmitting ? null : _sendResetEmail,
                          ),
                          const SizedBox(height: AppSpacing.md),
                          TextButton(
                            onPressed: () => context.go('/login'),
                            child: Text(
                              AppLocalizations.of(context)!.backToSignIn,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
