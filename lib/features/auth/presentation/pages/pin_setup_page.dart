import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:balaji_points/core/design/app_colors.dart';
import 'package:balaji_points/core/design/app_radius.dart';
import 'package:balaji_points/core/design/app_spacing.dart';
import 'package:balaji_points/core/design/app_typography.dart';
import 'package:balaji_points/l10n/app_localizations.dart';
import 'package:balaji_points/services/branch/branch_service.dart';
import '../providers/auth_provider.dart';

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
        if (branches.length == 1) _selectedBranchId = branches.first['id'] as String;
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
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(l10n.pinsDoNotMatch),
        backgroundColor: AppColors.error,
      ));
      return;
    }

    if (_selectedBranchId == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Please select a branch to continue.'),
        backgroundColor: AppColors.error,
      ));
      return;
    }

    ref.read(authProvider.notifier).setupPin(
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
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(l10n.pinCreatedSuccess),
          backgroundColor: AppColors.success,
        ));
        context.go('/');
      } else if (state is PinSetupError) {
        ScaffoldMessenger.of(context).clearSnackBars();
        String msg = state.message;
        if (msg.contains('already exists') || msg.contains('User already exists')) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(l10n.accountExistsUseReset),
            backgroundColor: AppColors.warning,
            duration: const Duration(seconds: 6),
            behavior: SnackBarBehavior.floating,
            action: SnackBarAction(
              label: l10n.resetPin,
              textColor: AppColors.white,
              onPressed: () {
                ScaffoldMessenger.of(context).hideCurrentSnackBar();
                context.push('/reset-pin', extra: _phoneController.text.trim());
              },
            ),
          ));
        } else {
          if (msg.contains('permission-denied')) {
            msg = 'Permission denied. Please check Firebase configuration.';
          } else if (msg.contains('network')) {
            msg = l10n.networkError;
          }
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(msg),
            backgroundColor: AppColors.error,
            duration: const Duration(seconds: 5),
            behavior: SnackBarBehavior.floating,
          ));
        }
      }
    });

    final isSaving = ref.watch(authProvider) is PinSetupLoading;

    return Scaffold(
      backgroundColor: Colors.transparent,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: BackButton(
          color: AppColors.lightPrimary,
          onPressed: () => context.pop(),
        ),
      ),
      body: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset('assets/images/background_image.png', fit: BoxFit.cover),
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
                    borderRadius: BorderRadius.circular(16),
                    child: Image.asset(
                      'assets/images/balaji_point_logo.png',
                      width: 80,
                      height: 80,
                      fit: BoxFit.cover,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Text(
                    l10n.createPinTitle,
                    style: AppTypography.h3(color: AppColors.lightPrimary),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    l10n.createPinSubtitle,
                    style: AppTypography.bodyMedium(
                      color: AppColors.lightPrimary.withValues(alpha: 0.7),
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: AppSpacing.xl2),

                  // ── Glass card ──
                  _GlassCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Phone
                        TextFormField(
                          controller: _phoneController,
                          keyboardType: TextInputType.phone,
                          maxLength: 10,
                          style: AppTypography.labelLarge(color: AppColors.lightPrimary),
                          decoration: _inputDecoration(
                            label: l10n.mobileNumber,
                            prefix: '+91 ',
                          ),
                          validator: (v) {
                            final s = v?.trim() ?? '';
                            if (s.length != 10 || !RegExp(r'^[0-9]+$').hasMatch(s)) {
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
                          onChanged: (id) => setState(() => _selectedBranchId = id),
                        ),

                        const SizedBox(height: AppSpacing.md),

                        // PIN
                        TextFormField(
                          controller: _pinController,
                          keyboardType: TextInputType.number,
                          obscureText: true,
                          maxLength: 4,
                          textAlign: TextAlign.center,
                          style: AppTypography.h2(color: AppColors.lightPrimary)
                              .copyWith(letterSpacing: 12),
                          decoration: _inputDecoration(label: l10n.fourDigitPin),
                          validator: (v) => (v == null || v.length != 4)
                              ? l10n.enter4Digits
                              : null,
                        ),

                        const SizedBox(height: AppSpacing.md),

                        // Confirm PIN
                        TextFormField(
                          controller: _confirmPinController,
                          keyboardType: TextInputType.number,
                          obscureText: true,
                          maxLength: 4,
                          textAlign: TextAlign.center,
                          style: AppTypography.h2(color: AppColors.lightPrimary)
                              .copyWith(letterSpacing: 12),
                          decoration: _inputDecoration(label: l10n.confirmPin),
                          validator: (v) {
                            if (v == null || v.length != 4) return l10n.enter4Digits;
                            if (v != _pinController.text.trim()) return l10n.pinsDoNotMatch;
                            return null;
                          },
                        ),

                        const SizedBox(height: AppSpacing.xl),

                        // Save button
                        _GradientButton(
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

  InputDecoration _inputDecoration({required String label, String? prefix}) {
    return InputDecoration(
      labelText: label,
      prefixText: prefix,
      counterText: '',
      filled: true,
      fillColor: AppColors.lightPrimary.withValues(alpha: 0.05),
      labelStyle: AppTypography.bodyMedium(color: AppColors.lightTextSecondary),
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
        borderSide: const BorderSide(color: AppColors.lightPrimary, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: AppRadius.forInput,
        borderSide: const BorderSide(color: AppColors.error, width: 1.5),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: AppRadius.forInput,
        borderSide: const BorderSide(color: AppColors.error, width: 2),
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
          style: AppTypography.bodyMedium(color: AppColors.lightTextSecondary),
        ),
        const SizedBox(height: AppSpacing.xs),
        Container(
          decoration: BoxDecoration(
            color: AppColors.lightPrimary.withValues(alpha: 0.05),
            borderRadius: AppRadius.forInput,
            border: Border.all(
              color: AppColors.lightPrimary.withValues(alpha: 0.2),
              width: 1.5,
            ),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: loading
              ? const SizedBox(
                  height: 48,
                  child: Center(
                    child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppColors.lightPrimary,
                      ),
                    ),
                  ),
                )
              : DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: selected,
                    isExpanded: true,
                    hint: Text(
                      'Select your branch',
                      style: AppTypography.bodyMedium(
                        color: AppColors.lightTextSecondary,
                      ),
                    ),
                    icon: const Icon(Icons.arrow_drop_down,
                        color: AppColors.lightPrimary),
                    style: AppTypography.bodyMedium(color: AppColors.lightPrimary),
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
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
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
            : Text(label,
                style: AppTypography.buttonLarge(color: AppColors.white)),
      ),
    );
  }
}

