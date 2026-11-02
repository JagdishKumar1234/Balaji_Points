import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;

import 'package:balaji_points/core/constants/app_constants.dart';
import 'package:balaji_points/core/design/app_colors.dart';
import 'package:balaji_points/core/design/app_spacing.dart';
import 'package:balaji_points/core/design/app_typography.dart';
import 'package:balaji_points/presentation/widgets/shared/app_button.dart';
import 'package:balaji_points/presentation/widgets/shared/app_text_field.dart';
import 'package:balaji_points/presentation/widgets/shared/auth_background.dart';
import 'package:balaji_points/presentation/widgets/shared/professional_auth_card.dart';
import 'package:balaji_points/services/branch/branch_service.dart';
import '../../../../providers/auth_provider.dart';

class RegisterPage extends ConsumerStatefulWidget {
  const RegisterPage({
    super.key,
    this.completeGoogleProfile = false,
    this.googleProfile,
  });

  final bool completeGoogleProfile;
  final Map<String, dynamic>? googleProfile;

  @override
  ConsumerState<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends ConsumerState<RegisterPage> {
  final _formKey = GlobalKey<FormState>();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  List<Map<String, dynamic>> _branches = [];
  String? _selectedBranchId;
  String _selectedRole = AppConstants.roleCarpenter;
  bool _loadingBranches = true;
  bool _submitting = false;
  bool _showPassword = false;
  bool _showConfirmPassword = false;

  @override
  void initState() {
    super.initState();
    if (widget.completeGoogleProfile) {
      final googleUser = firebase_auth.FirebaseAuth.instance.currentUser;
      final fullName =
          (widget.googleProfile?['displayName'] as String?) ??
          googleUser?.displayName ??
          '';
      final nameParts = fullName.trim().split(RegExp(r'\s+'));
      _firstNameController.text = nameParts.isEmpty ? '' : nameParts.first;
      if (nameParts.length > 1) {
        _lastNameController.text = nameParts.skip(1).join(' ');
      }
      _emailController.text =
          (widget.googleProfile?['email'] as String?) ??
          googleUser?.email ??
          '';
      final existingRole = widget.googleProfile?['existingRole'] as String?;
      if (existingRole != null &&
          AppConstants.branchRegistrationRoles.contains(existingRole) &&
          existingRole != AppConstants.roleAdmin) {
        _selectedRole = existingRole;
      }
    }
    _loadBranches();
  }

  Future<void> _loadBranches() async {
    final branches = await BranchService().listActiveBranches();
    if (!mounted) return;
    setState(() {
      _branches = branches;
      if (branches.length == 1) {
        _selectedBranchId = branches.first['id'] as String;
      }
      _loadingBranches = false;
    });
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedBranchId == null) {
      _showMessage('Select a branch to continue.');
      return;
    }

    setState(() => _submitting = true);
    try {
      final notifier = ref.read(authProvider.notifier);
      if (widget.completeGoogleProfile) {
        await notifier.completeGoogleRegistration(
          firstName: _firstNameController.text.trim(),
          lastName: _lastNameController.text.trim(),
          phoneNumber: _phoneController.text.trim(),
          role: _selectedRole,
          branchId: _selectedBranchId!,
        );
      } else {
        await notifier.registerWithEmailAndPassword(
          firstName: _firstNameController.text.trim(),
          lastName: _lastNameController.text.trim(),
          email: _emailController.text.trim(),
          password: _passwordController.text,
          phoneNumber: _phoneController.text.trim(),
          role: _selectedRole,
          branchId: _selectedBranchId!,
        );
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  void _showMessage(String message, {bool isError = true}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? context.themeError : AppColors.success,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    ref.listen<AuthState>(authProvider, (_, state) {
      if (state is AuthAuthenticated) {
        final route = switch (state.role) {
          AppConstants.roleAdmin => '/admin',
          AppConstants.roleSuperAdmin => '/super-admin',
          _ => '/',
        };
        context.go(route);
      } else if (state is AuthError) {
        _showMessage(state.message);
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
                    securityMessage: 'Your information is protected',
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Icon(
                            Icons.person_add_alt_1_rounded,
                            size: 46,
                            color: context.themePrimary,
                          ),
                          const SizedBox(height: AppSpacing.md),
                          Text(
                            widget.completeGoogleProfile
                                ? 'Complete your Google registration'
                                : 'Create your account',
                            textAlign: TextAlign.center,
                            style: AppTypography.displaySmall(
                              color: context.themeTextPrimary,
                            ),
                          ),
                          const SizedBox(height: AppSpacing.xs),
                          Text(
                            widget.completeGoogleProfile
                                ? 'Add your mobile number and choose your branch and role to finish setting up your account.'
                                : 'Choose your role and the branch you belong to.',
                            textAlign: TextAlign.center,
                            style: AppTypography.bodyMedium(
                              color: context.themeTextSecondary,
                            ),
                          ),
                          const SizedBox(height: AppSpacing.xl2),
                          AppTextField(
                            controller: _firstNameController,
                            label: 'First name',
                            prefixIcon: Icons.person_outline,
                            validator: (value) =>
                                value == null || value.trim().isEmpty
                                ? 'Enter your first name'
                                : null,
                          ),
                          const SizedBox(height: AppSpacing.md),
                          AppTextField(
                            controller: _lastNameController,
                            label: 'Last name (optional)',
                            prefixIcon: Icons.person_outline,
                          ),
                          const SizedBox(height: AppSpacing.md),
                          AppTextField(
                            controller: _emailController,
                            label: 'Email',
                            prefixIcon: Icons.email_outlined,
                            keyboardType: TextInputType.emailAddress,
                            enabled: !widget.completeGoogleProfile,
                            validator: (value) {
                              final email = value?.trim() ?? '';
                              return RegExp(
                                    AppConstants.emailRegex,
                                  ).hasMatch(email)
                                  ? null
                                  : 'Enter a valid email address';
                            },
                          ),
                          const SizedBox(height: AppSpacing.md),
                          AppTextField.phone(
                            controller: _phoneController,
                            label: 'Mobile number',
                            validator: (value) => value?.trim().length == 10
                                ? null
                                : 'Enter a valid 10-digit mobile number',
                          ),
                          const SizedBox(height: AppSpacing.md),
                          if (!widget.completeGoogleProfile) ...[
                            AppTextField(
                              controller: _passwordController,
                              label: 'Password',
                              prefixIcon: Icons.lock_outline,
                              obscureText: !_showPassword,
                              suffix: IconButton(
                                tooltip: _showPassword
                                    ? 'Hide password'
                                    : 'Show password',
                                onPressed: () => setState(
                                  () => _showPassword = !_showPassword,
                                ),
                                icon: Icon(
                                  _showPassword
                                      ? Icons.visibility_off
                                      : Icons.visibility,
                                ),
                              ),
                              validator: (value) => (value?.length ?? 0) >= 6
                                  ? null
                                  : 'Use at least 6 characters',
                            ),
                            const SizedBox(height: AppSpacing.md),
                            AppTextField(
                              controller: _confirmPasswordController,
                              label: 'Confirm password',
                              prefixIcon: Icons.lock_outline,
                              obscureText: !_showConfirmPassword,
                              suffix: IconButton(
                                tooltip: _showConfirmPassword
                                    ? 'Hide password'
                                    : 'Show password',
                                onPressed: () => setState(
                                  () => _showConfirmPassword =
                                      !_showConfirmPassword,
                                ),
                                icon: Icon(
                                  _showConfirmPassword
                                      ? Icons.visibility_off
                                      : Icons.visibility,
                                ),
                              ),
                              validator: (value) =>
                                  value == _passwordController.text
                                  ? null
                                  : 'Passwords do not match',
                            ),
                          ],
                          const SizedBox(height: AppSpacing.lg),
                          _SelectionField<String>(
                            label: 'Role',
                            value: _selectedRole,
                            items: const {
                              AppConstants.roleCarpenter:
                                  'Carpenter / Woodworker',
                              AppConstants.roleArchitect: 'Architect',
                              AppConstants.roleInteriorDesigner:
                                  'Interior Designer',
                            },
                            enabled:
                                widget.googleProfile?['existingRole'] == null ||
                                widget.googleProfile?['existingRole'] ==
                                    _selectedRole,
                            onChanged: (value) {
                              if (value != null) {
                                setState(() => _selectedRole = value);
                              }
                            },
                          ),
                          const SizedBox(height: AppSpacing.md),
                          _BranchField(
                            branches: _branches,
                            selectedBranchId: _selectedBranchId,
                            isLoading: _loadingBranches,
                            onChanged: (value) =>
                                setState(() => _selectedBranchId = value),
                          ),
                          if (!_loadingBranches && _branches.isEmpty) ...[
                            const SizedBox(height: AppSpacing.xs),
                            Text(
                              'No active branches are available. Contact your administrator.',
                              style: AppTypography.caption(
                                color: context.themeError,
                              ),
                            ),
                          ],
                          const SizedBox(height: AppSpacing.sm),
                          Text(
                            widget.googleProfile?['existingRole'] ==
                                    AppConstants.roleAdmin
                                ? 'Your account already has an Admin role. Ask the Super Admin to assign your branch before continuing.'
                                : 'Branch Admin access is assigned by a Super Admin.',
                            style: AppTypography.caption(
                              color: context.themeTextSecondary,
                            ),
                          ),
                          const SizedBox(height: AppSpacing.xl),
                          AppButton.primary(
                            label: widget.completeGoogleProfile
                                ? 'Complete registration'
                                : 'Create account',
                            isLoading: _submitting,
                            onPressed:
                                _submitting ||
                                    _loadingBranches ||
                                    _branches.isEmpty ||
                                    widget.googleProfile?['existingRole'] ==
                                        AppConstants.roleAdmin
                                ? null
                                : _register,
                          ),
                          const SizedBox(height: AppSpacing.md),
                          TextButton(
                            onPressed: () async {
                              if (widget.completeGoogleProfile) {
                                await ref
                                    .read(authProvider.notifier)
                                    .cancelGoogleProfileCompletion();
                              }
                              if (context.mounted) context.go('/login');
                            },
                            child: const Text('Cancel and return to sign in'),
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

class _SelectionField<T> extends StatelessWidget {
  const _SelectionField({
    required this.label,
    required this.value,
    required this.items,
    required this.onChanged,
    this.enabled = true,
  });

  final String label;
  final T value;
  final Map<T, String> items;
  final ValueChanged<T?> onChanged;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<T>(
      key: ValueKey<T>(value),
      initialValue: value,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
      ),
      items: items.entries
          .map(
            (entry) =>
                DropdownMenuItem<T>(value: entry.key, child: Text(entry.value)),
          )
          .toList(),
      onChanged: enabled ? onChanged : null,
    );
  }
}

class _BranchField extends StatelessWidget {
  const _BranchField({
    required this.branches,
    required this.selectedBranchId,
    required this.isLoading,
    required this.onChanged,
  });

  final List<Map<String, dynamic>> branches;
  final String? selectedBranchId;
  final bool isLoading;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<String>(
      key: ValueKey<String?>(selectedBranchId),
      initialValue: selectedBranchId,
      decoration: InputDecoration(
        labelText: 'Branch',
        hintText: isLoading ? 'Loading branches…' : 'Select your branch',
        prefixIcon: const Icon(Icons.store_outlined),
        border: const OutlineInputBorder(),
      ),
      items: branches
          .map(
            (branch) => DropdownMenuItem<String>(
              value: branch['id'] as String,
              child: Text(branch['name'] as String? ?? branch['id'] as String),
            ),
          )
          .toList(),
      onChanged: isLoading ? null : onChanged,
      validator: (value) => value == null ? 'Select a branch' : null,
    );
  }
}
