import 'package:balaji_points/presentation/widgets/shared/auth_scaffold.dart';
import 'package:flutter/material.dart';
import 'package:balaji_points/l10n/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:balaji_points/core/design/app_colors.dart';
import 'package:balaji_points/core/design/app_spacing.dart';
import 'package:balaji_points/core/design/app_typography.dart';
import 'package:balaji_points/presentation/widgets/shared/app_button.dart';
import 'package:balaji_points/presentation/widgets/shared/app_text_field.dart';
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

    return AuthScaffold(
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
              if (_emailSent) ...[
                const Icon(
                  Icons.mark_email_read_outlined,
                  size: 52,
                  color: AppColors.success,
                ),
                const SizedBox(height: AppSpacing.md),
              ],
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
                    ? AppLocalizations.of(context)!.ifAnAccountExistsForThis
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
                hint: AppLocalizations.of(context)!.hintEmail,
                prefixIcon: Icons.email_outlined,
                keyboardType: TextInputType.emailAddress,
                validator: (value) {
                  final email = value?.trim() ?? '';
                  if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(email)) {
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
                    ? AppLocalizations.of(context)!.sendAnotherResetLink
                    : AppLocalizations.of(context)!.sendResetLink,
                isLoading: _isSubmitting,
                onPressed: _isSubmitting ? null : _sendResetEmail,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
