import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:balaji_points/core/design/app_colors.dart';
import 'package:balaji_points/core/design/app_radius.dart';
import 'package:balaji_points/core/design/app_spacing.dart';
import 'package:balaji_points/core/design/app_typography.dart';
import 'package:balaji_points/core/design/auth_design.dart';
import 'package:balaji_points/l10n/app_localizations.dart';
import 'package:balaji_points/presentation/widgets/shared/auth_background.dart';
import 'package:balaji_points/presentation/widgets/shared/app_button.dart';
import 'package:balaji_points/presentation/widgets/shared/app_loader.dart';
import 'package:balaji_points/presentation/widgets/shared/app_text.dart';
import 'package:balaji_points/presentation/widgets/shared/app_text_field.dart';
import 'package:balaji_points/services/branch/branch_service.dart';
import '../../../../providers/auth_provider.dart';

class PINSetupPage extends ConsumerStatefulWidget {
  final String? phoneNumber;
  const PINSetupPage({super.key, this.phoneNumber});

  @override
  ConsumerState<PINSetupPage> createState() => _PINSetupPageState();
}

class _PINSetupPageState extends ConsumerState<PINSetupPage> {
  final _phoneController = TextEditingController();
  final _pinController = TextEditingController();
  final _confirmPinController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  // Branch selection state
  List<Map<String, dynamic>> _branches = [];
  String? _selectedBranchId;
  bool _loadingBranches = true;

  @override
  void initState() {
    super.initState();
    if (widget.phoneNumber != null && widget.phoneNumber!.isNotEmpty) {
      _phoneController.text = widget.phoneNumber!;
    }
    _loadBranches();
  }

  Future<void> _loadBranches() async {
    final branches = await BranchService().listActiveBranches();
    if (mounted) {
      setState(() {
        _branches = branches;
        // Auto-select if only one branch
        if (branches.length == 1) {
          _selectedBranchId = branches.first['id'] as String;
        }
        _loadingBranches = false;
      });
    }
  }

  @override
  void dispose() {
    _phoneController.dispose();
    _pinController.dispose();
    _confirmPinController.dispose();
    super.dispose();
  }

  void _savePin() {
    if (!_formKey.currentState!.validate()) return;

    final l10n = AppLocalizations.of(context)!;
    final pin = _pinController.text.trim();
    final confirm = _confirmPinController.text.trim();

    if (pin != confirm) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.pinsDoNotMatch),
          backgroundColor: context.themeError,
        ),
      );
      return;
    }

    if (_selectedBranchId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please select a branch to continue.'),
          backgroundColor: context.themeError,
        ),
      );
      return;
    }

    ref
        .read(authProvider.notifier)
        .setupPin(
          phoneNumber: _phoneController.text.trim(),
          pin: pin,
          firstName: '',
          branchId: _selectedBranchId,
        );
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final topInset = MediaQuery.of(context).padding.top;
    final l10n = AppLocalizations.of(context)!;

    ref.listen<AuthState>(authProvider, (_, state) {
      if (state is PinSetupSuccess) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.pinCreatedSuccess),
            backgroundColor: AppColors.success,
          ),
        );
        context.go('/');
      } else if (state is PinSetupError) {
        ScaffoldMessenger.of(context).clearSnackBars();
        String msg = state.message;
        if (msg.contains('already exists') ||
            msg.contains('User already exists')) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(l10n.accountExistsUseReset),
              backgroundColor: AppColors.warning,
              duration: const Duration(seconds: 6),
              behavior: SnackBarBehavior.floating,
              action: SnackBarAction(
                label: l10n.resetPin,
                textColor: AppColors.white,
                onPressed: () {
                  ScaffoldMessenger.of(context).hideCurrentSnackBar();
                  context.push(
                    '/reset-pin',
                    extra: _phoneController.text.trim(),
                  );
                },
              ),
            ),
          );
        } else {
          if (msg.contains('permission-denied')) {
            msg = 'Permission denied. Please check Firebase configuration.';
          } else if (msg.contains('network')) {
            msg = l10n.networkError;
          }
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(msg),
              backgroundColor: context.themeError,
              duration: const Duration(seconds: 5),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    });

    final isSaving = ref.watch(authProvider) is PinSetupLoading;

    return Scaffold(
      backgroundColor: AppColors.transparent,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: AppColors.transparent,
        elevation: 0,
        leading: BackButton(
          color: context.themePrimary,
          onPressed: () => context.pop(),
        ),
      ),
      body: Stack(
        fit: StackFit.expand,
        children: [
          AuthBackground(
            isDark: Theme.of(context).brightness == Brightness.dark,
          ),
          SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(
              AppSpacing.xl,
              topInset + kToolbarHeight + AppSpacing.sm,
              AppSpacing.xl,
              bottomInset + AppSpacing.xl,
            ),
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  const SizedBox(height: AppSpacing.sm),
                  ClipRRect(
                    borderRadius: AppRadius.all16,
                    child: Image.asset(
                      'assets/images/balaji_point_logo.png',
                      width: 80,
                      height: 80,
                      fit: BoxFit.cover,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  AppText.h3(l10n.createPinTitle, color: context.themePrimary),
                  const SizedBox(height: AppSpacing.xs),
                  AppText.body(
                    l10n.createPinSubtitle,
                    color: context.themePrimary.withValues(alpha: 0.7),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: AppSpacing.xl2),

                  // ── Glass card ──
                  _GlassCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Phone
                        AppTextField.phone(
                          controller: _phoneController,
                          label: l10n.mobileNumber,
                          validator: (v) {
                            final s = v?.trim() ?? '';
                            if (s.length != 10 ||
                                !RegExp(r'^[0-9]+$').hasMatch(s)) {
                              return l10n.enterValidTenDigit;
                            }
                            return null;
                          },
                        ),

                        const SizedBox(height: AppSpacing.md),

                        // Branch picker
                        _BranchPicker(
                          branches: _branches,
                          selected: _selectedBranchId,
                          loading: _loadingBranches,
                          onChanged: (id) =>
                              setState(() => _selectedBranchId = id),
                        ),

                        const SizedBox(height: AppSpacing.md),

                        // PIN
                        AppTextField.pin(
                          controller: _pinController,
                          label: l10n.fourDigitPin,
                          validator: (v) => (v == null || v.length != 4)
                              ? l10n.enter4Digits
                              : null,
                        ),

                        const SizedBox(height: AppSpacing.md),

                        // Confirm PIN
                        AppTextField.pin(
                          controller: _confirmPinController,
                          label: l10n.confirmPin,
                          validator: (v) {
                            if (v == null || v.length != 4) {
                              return l10n.enter4Digits;
                            }
                            if (v != _pinController.text.trim()) {
                              return l10n.pinsDoNotMatch;
                            }
                            return null;
                          },
                        ),

                        const SizedBox(height: AppSpacing.xl),

                        // Save button
                        AppButton.secondary(
                          label: l10n.savePin,
                          isLoading: isSaving,
                          onPressed: isSaving ? null : _savePin,
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: AppSpacing.xl),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Branch picker ─────────────────────────────────────────────────────────────

class _BranchPicker extends StatelessWidget {
  final List<Map<String, dynamic>> branches;
  final String? selected;
  final bool loading;
  final ValueChanged<String?> onChanged;

  const _BranchPicker({
    required this.branches,
    required this.selected,
    required this.loading,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Branch *',
          style: AppTypography.bodyMedium(color: context.themeTextSecondary),
        ),
        const SizedBox(height: AppSpacing.xs),
        Container(
          decoration: BoxDecoration(
            color: context.themePrimary.withValues(alpha: 0.05),
            borderRadius: AppRadius.forInput,
            border: Border.all(
              color: context.themePrimary.withValues(alpha: 0.2),
              width: 1.5,
            ),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: loading
              ? SizedBox(
                  height: 48,
                  child: Center(child: AppLoader(size: 20, strokeWidth: 2)),
                )
              : DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: selected,
                    isExpanded: true,
                    dropdownColor: context.themeSurface,
                    hint: Text(
                      'Select your branch',
                      style: AppTypography.bodyMedium(
                        color: context.themeTextSecondary,
                      ),
                    ),
                    icon: Icon(
                      Icons.arrow_drop_down,
                      color: context.themePrimary,
                    ),
                    style: AppTypography.bodyMedium(
                      color: context.themeTextPrimary,
                    ),
                    onChanged: onChanged,
                    items: branches.map((b) {
                      return DropdownMenuItem<String>(
                        value: b['id'] as String,
                        child: Text(b['name'] as String? ?? b['id'] as String),
                      );
                    }).toList(),
                  ),
                ),
        ),
      ],
    );
  }
}

// ── Glass card ────────────────────────────────────────────────────────────────

class _GlassCard extends StatelessWidget {
  final Widget child;
  const _GlassCard({required this.child});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return ClipRRect(
      borderRadius: AppRadius.forCard,
      child: BackdropFilter(
        filter: ImageFilter.blur(
          sigmaX: AuthDesign.cardBlurSigma,
          sigmaY: AuthDesign.cardBlurSigma,
        ),
        child: Container(
          padding: AuthDesign.cardPadding,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: isDark
                  ? [
                      AppColors.darkSurface
                          .withValues(alpha: AuthDesign.darkCardMainOpacity),
                      AppColors.darkBackground.withValues(
                          alpha: AuthDesign.darkCardSecondaryOpacity),
                    ]
                  : [
                      AppColors.white.withValues(
                          alpha: AuthDesign.lightCardMainOpacity),
                      AppColors.white.withValues(
                          alpha: AuthDesign.lightCardSecondaryOpacity),
                    ],
            ),
            borderRadius: AppRadius.forCard,
            border: Border.all(
              color: isDark
                  ? AppColors.darkBorder
                      .withValues(alpha: AuthDesign.darkCardBorderOpacity)
                  : AppColors.white
                      .withValues(alpha: AuthDesign.lightCardBorderOpacity),
              width: AuthDesign.cardBorderWidth,
            ),
            boxShadow: [
              BoxShadow(
                color: isDark
                    ? AppColors.black
                        .withValues(alpha: AuthDesign.darkCardShadowOpacity)
                    : context.themePrimary.withValues(
                        alpha: AuthDesign.lightCardShadowOpacity),
                blurRadius: AuthDesign.cardShadowBlurRadius,
                offset: AuthDesign.cardShadowOffset,
              ),
            ],
          ),
          child: child,
        ),
      ),
    );
  }
}
