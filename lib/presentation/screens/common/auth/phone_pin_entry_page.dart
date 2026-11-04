import 'package:flutter/material.dart';
import 'package:balaji_points/l10n/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:balaji_points/core/design/app_spacing.dart';
import 'package:balaji_points/presentation/widgets/shared/app_button.dart';
import 'package:balaji_points/presentation/widgets/shared/app_text_field.dart';
import 'package:balaji_points/presentation/widgets/shared/auth_background.dart';
import 'package:balaji_points/presentation/widgets/shared/professional_auth_card.dart';
import 'package:balaji_points/providers/auth_provider.dart';

class PhonePinEntryPage extends ConsumerStatefulWidget {
  const PhonePinEntryPage({super.key});

  @override
  ConsumerState<PhonePinEntryPage> createState() => _PhonePinEntryPageState();
}

class _PhonePinEntryPageState extends ConsumerState<PhonePinEntryPage> {
  final _phoneController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _checking = false;

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  void _continue() {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _checking = true);
    ref
        .read(authProvider.notifier)
        .checkPinAccount(_phoneController.text.trim());
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<AuthState>(authProvider, (_, state) {
      if (state is AuthUserExists) {
        setState(() => _checking = false);
        context.go(
          '/pin-login?phone=${Uri.encodeComponent(state.phoneNumber)}',
        );
      } else if (state is AuthUserNotFound) {
        setState(() => _checking = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context)!.noPinAccount)),
        );
      } else if (state is AuthError) {
        setState(() => _checking = false);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(state.message)));
      }
    });

    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Colors.transparent,
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
                    )!.forCurrentMobilePinAccounts,
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
                            AppLocalizations.of(context)!.signInWithMobile,
                            textAlign: TextAlign.center,
                            style: Theme.of(context).textTheme.headlineSmall,
                          ),
                          const SizedBox(height: AppSpacing.lg),
                          AppTextField.phone(
                            controller: _phoneController,
                            label: AppLocalizations.of(context)!.mobileNumber,
                            validator: (value) =>
                                value
                                        ?.replaceAll(RegExp(r'[^0-9]'), '')
                                        .length ==
                                    10
                                ? null
                                : AppLocalizations.of(
                                    context,
                                  )!.enterAValid10DigitMobile,
                          ),
                          const SizedBox(height: AppSpacing.lg),
                          AppButton.primary(
                            label: AppLocalizations.of(context)!.continueToPin,
                            isLoading: _checking,
                            onPressed: _checking ? null : _continue,
                          ),
                          TextButton(
                            onPressed: () => context.go('/login'),
                            child: Text(
                              AppLocalizations.of(context)!.backToOtherSignIn,
                              textAlign: TextAlign.center,
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
