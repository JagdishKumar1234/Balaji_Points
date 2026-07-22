import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:balaji_points/core/design/app_animations.dart';
import 'package:balaji_points/core/design/app_colors.dart';
import 'package:balaji_points/core/design/app_radius.dart';
import 'package:balaji_points/core/design/app_spacing.dart';
import 'package:balaji_points/core/design/app_typography.dart';
import 'package:balaji_points/l10n/app_localizations.dart';
import 'package:balaji_points/presentation/widgets/shared/auth_background.dart';
import 'package:balaji_points/presentation/widgets/shared/app_button.dart';
import 'package:balaji_points/presentation/widgets/shared/app_loader.dart';
import 'package:balaji_points/presentation/widgets/shared/app_text_field.dart';
import 'package:balaji_points/presentation/widgets/shared/professional_auth_card.dart';
import 'package:balaji_points/providers/locale_provider.dart';
import 'package:balaji_points/providers/theme_provider.dart';
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
    final l10n = AppLocalizations.of(context)!;
    final isDark = Theme.of(context).brightness == Brightness.dark;

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
                          // Header
                          Column(
                            children: [
                              // Logo
                              Container(
                                width: 80,
                                height: 80,
                                decoration: BoxDecoration(
                                  color: const Color(0xFF001F4D),
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(16),
                                  child: Image.asset(
                                    'assets/images/balaji_point_logo.png',
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, __, ___) => const Icon(
                                      Icons.home_rounded,
                                      color: Colors.white,
                                      size: 40,
                                    ),
                                  ),
                                ),
                              ).enterHero(delay: AppAnimations.stagger(1)),
                              const SizedBox(height: AppSpacing.lg),

                              // Title
                              Text(
                                l10n.createPinTitle,
                                style: AppTypography.displaySmall(
                                  color: const Color(0xFF001F4D),
                                ).copyWith(fontWeight: FontWeight.bold),
                                textAlign: TextAlign.center,
                              ).fadeIn(delay: AppAnimations.stagger(2)),
                              const SizedBox(height: 8),

                              // Subtitle
                              Text(
                                l10n.createPinSubtitle,
                                style: AppTypography.bodyMedium(
                                  color: const Color(0xFF78909C),
                                ),
                                textAlign: TextAlign.center,
                              ).fadeIn(delay: AppAnimations.stagger(3)),
                            ],
                          ),

                          const SizedBox(height: AppSpacing.xl3),

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
                          ).fadeIn(delay: AppAnimations.stagger(4)),

                          const SizedBox(height: AppSpacing.xl2),

                          // Branch picker
                          _BranchPicker(
                            branches: _branches,
                            selected: _selectedBranchId,
                            loading: _loadingBranches,
                            onChanged: (id) =>
                                setState(() => _selectedBranchId = id),
                          ).fadeIn(delay: AppAnimations.stagger(5)),

                          const SizedBox(height: AppSpacing.xl2),

                          // PIN
                          AppTextField.pin(
                            controller: _pinController,
                            label: l10n.fourDigitPin,
                            validator: (v) => (v == null || v.length != 4)
                                ? l10n.enter4Digits
                                : null,
                          ).fadeIn(delay: AppAnimations.stagger(6)),

                          const SizedBox(height: AppSpacing.xl2),

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
                          ).fadeIn(delay: AppAnimations.stagger(7)),

                          const SizedBox(height: AppSpacing.xl2),

                          // Save button
                          AppButton.secondary(
                            label: l10n.savePin,
                            isLoading: isSaving,
                            onPressed: isSaving ? null : _savePin,
                          ).fadeIn(delay: AppAnimations.stagger(8)),
                        ],
                      ),
                    ).enterCard(delay: AppAnimations.stagger(9)),

                    const SizedBox(height: AppSpacing.xl2),

                    // ── Footer ──
                    AuthFooter(
                      companyName: l10n.companyName,
                      isDark: isDark,
                    ).fadeIn(delay: AppAnimations.stagger(10)),

                    const SizedBox(height: AppSpacing.xl3),
                  ],
                ),
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

// ── Theme toggle button ───────────────────────────────────────────────────────

class _ThemeToggleButton extends ConsumerWidget {
  final bool isDark;
  const _ThemeToggleButton({required this.isDark});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: isDark
            ? AppColors.darkSurface.withValues(alpha: 0.85)
            : AppColors.white.withValues(alpha: 0.90),
        borderRadius: AppRadius.sm8,
        border: Border.all(
          color: isDark
              ? AppColors.darkBorder.withValues(alpha: 0.5)
              : context.themePrimary.withValues(alpha: 0.30),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: (isDark
                    ? AppColors.darkBorder
                    : context.themePrimary)
                .withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: IconButton(
        padding: EdgeInsets.zero,
        splashRadius: 22,
        tooltip: isDark ? 'Switch to Light' : 'Switch to Dark',
        onPressed: () => ref.read(themeModeProvider.notifier).toggleTheme(),
        icon: AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          transitionBuilder: (child, anim) =>
              RotationTransition(turns: anim, child: child),
          child: Icon(
            isDark ? Icons.wb_sunny_rounded : Icons.nightlight_round,
            key: ValueKey(isDark),
            size: 22,
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
      height: 44,
      decoration: BoxDecoration(
        color: isDark
            ? AppColors.darkSurface.withValues(alpha: 0.85)
            : AppColors.white.withValues(alpha: 0.90),
        borderRadius: AppRadius.sm8,
        border: Border.all(
          color: isDark
              ? AppColors.darkBorder.withValues(alpha: 0.5)
              : context.themePrimary.withValues(alpha: 0.30),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: (isDark
                    ? AppColors.darkBorder
                    : context.themePrimary)
                .withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<Locale>(
          value: ref.watch(localeProvider),
          style: AppTypography.bodyMedium(
            color: context.themeTextPrimary,
          ),
          dropdownColor: context.themeSurface,
          iconEnabledColor: isDark ? AppColors.white : context.themePrimary,
          icon: Icon(
            Icons.language_rounded,
            size: 22,
            color: isDark ? AppColors.white : context.themePrimary,
          ),
          onChanged: (locale) {
            if (locale != null) {
              ref.read(localeProvider.notifier).setLocale(locale);
            }
          },
          items: [
            DropdownMenuItem(
              value: const Locale('en'),
              child: Row(
                children: [
                  const Icon(Icons.language, size: 16),
                  const SizedBox(width: 8),
                  Text(l10n.languageEnglish),
                ],
              ),
            ),
            DropdownMenuItem(
              value: const Locale('hi'),
              child: Row(
                children: [
                  const Icon(Icons.language, size: 16),
                  const SizedBox(width: 8),
                  Text(l10n.languageHindi),
                ],
              ),
            ),
            DropdownMenuItem(
              value: const Locale('ta'),
              child: Row(
                children: [
                  const Icon(Icons.language, size: 16),
                  const SizedBox(width: 8),
                  Text(l10n.languageTamil),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
