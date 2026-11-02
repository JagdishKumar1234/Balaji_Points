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
import 'package:balaji_points/services/auth/role_service.dart';
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
  final _fullNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  List<Map<String, dynamic>> _branches = [];
  List<AppRole> _roles = [];
  String? _selectedBranchId;
  String? _selectedRole;
  bool _loadingBranches = true;
  bool _loadingRoles = true;
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
      _fullNameController.text = fullName;
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
    _loadRoles();
  }

  Future<void> _loadBranches() async {
    final branches = await BranchService().listActiveBranches();
    if (!mounted) return;
    setState(() {
      _branches = branches;
      if (_selectedBranchId != null &&
          !branches.any((branch) => branch['id'] == _selectedBranchId)) {
        _selectedBranchId = null;
      }
      if (branches.length == 1) {
        _selectedBranchId = branches.first['id'] as String;
      }
      _loadingBranches = false;
    });
  }

  Future<void> _loadRoles() async {
    final roles = await RoleService().listSignupRoles();
    if (!mounted) return;
    final existingRole = widget.googleProfile?['existingRole'] as String?;
    setState(() {
      _roles = roles;
      if (_selectedRole != null &&
          !roles.any((role) => role.id == _selectedRole)) {
        _selectedRole = null;
      }
      if (existingRole != null &&
          roles.any((role) => role.id == existingRole)) {
        _selectedRole = existingRole;
      }
      _loadingRoles = false;
    });
  }

  @override
  void dispose() {
    _fullNameController.dispose();
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
    final selectedRole = _selectedRole;
    if (selectedRole == null) {
      _showMessage('Select a role to continue.');
      return;
    }
    final selectedRoleData = _roles.where((role) => role.id == selectedRole);
    if (selectedRoleData.isEmpty || !selectedRoleData.first.isActive) {
      _showMessage('Select an active role to continue.');
      return;
    }
    final role = selectedRoleData.first;

    final nameParts = _fullNameController.text.trim().split(RegExp(r'\s+'));
    final firstName = nameParts.first;
    final lastName = nameParts.skip(1).join(' ');

    setState(() => _submitting = true);
    try {
      final notifier = ref.read(authProvider.notifier);
      if (widget.completeGoogleProfile) {
        await notifier.completeGoogleRegistration(
          firstName: firstName,
          lastName: lastName,
          phoneNumber: _phoneController.text.trim(),
          role: role.id,
          roleName: role.name,
          roleAbbreviation: role.abbreviation,
          branchId: _selectedBranchId!,
        );
      } else {
        await notifier.registerWithEmailAndPassword(
          firstName: firstName,
          lastName: lastName,
          email: _emailController.text.trim(),
          password: _passwordController.text,
          phoneNumber: _phoneController.text.trim(),
          role: role.id,
          roleName: role.name,
          roleAbbreviation: role.abbreviation,
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
                            controller: _fullNameController,
                            label: 'Full name',
                            prefixIcon: Icons.person_outline,
                            validator: (value) =>
                                value == null || value.trim().isEmpty
                                ? 'Enter your full name'
                                : null,
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
                          _RoleField(
                            roles: _roles,
                            selectedRoleId: _selectedRole,
                            isLoading: _loadingRoles,
                            enabled:
                                widget.googleProfile?['existingRole'] == null ||
                                widget.googleProfile?['existingRole'] ==
                                    _selectedRole,
                            onChanged: (value) {
                              setState(() => _selectedRole = value);
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
                          if (!_loadingRoles && _roles.isEmpty) ...[
                            const SizedBox(height: AppSpacing.xs),
                            Text(
                              'No active roles are available. Contact the Super Admin.',
                              style: AppTypography.caption(
                                color: context.themeError,
                              ),
                            ),
                          ],
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
                                    _loadingRoles ||
                                    _branches.isEmpty ||
                                    _roles.isEmpty ||
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

class _RoleField extends StatelessWidget {
  const _RoleField({
    required this.roles,
    required this.selectedRoleId,
    required this.isLoading,
    required this.enabled,
    required this.onChanged,
  });

  final List<AppRole> roles;
  final String? selectedRoleId;
  final bool isLoading;
  final bool enabled;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) {
    final hasSelectedRole = roles.any((role) => role.id == selectedRoleId);
    return DropdownButtonFormField<String>(
      key: ValueKey<String?>(hasSelectedRole ? selectedRoleId : null),
      initialValue: hasSelectedRole ? selectedRoleId : null,
      isExpanded: true,
      decoration: InputDecoration(
        labelText: 'Select role *',
        hintText: isLoading ? 'Loading roles…' : 'Choose one role',
        prefixIcon: const Icon(Icons.badge_outlined),
        filled: true,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
        ),
      ),
      items: roles
          .map(
            (role) => DropdownMenuItem<String>(
              value: role.id,
              child: Text(
                role.selectionLabel,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          )
          .toList(),
      onChanged: !isLoading && enabled && roles.isNotEmpty ? onChanged : null,
      validator: (value) => value == null ? 'Select a role to continue' : null,
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
    final availableIds = branches
        .map((branch) => branch['id'] as String? ?? '')
        .where((id) => id.isNotEmpty)
        .toSet();
    final safeSelectedId = availableIds.contains(selectedBranchId)
        ? selectedBranchId
        : null;
    final selectedBranch = branches.cast<Map<String, dynamic>?>().firstWhere(
      (branch) => branch?['id'] == safeSelectedId,
      orElse: () => null,
    );
    final selectedFullName = selectedBranch?['name'] as String?;
    final selectedShortName = selectedBranch?['shortName'] as String?;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        DropdownButtonFormField<String>(
          key: ValueKey<String?>(safeSelectedId),
          initialValue: safeSelectedId,
          isExpanded: true,
          decoration: InputDecoration(
            labelText: 'Branch *',
            hintText: isLoading ? 'Loading branches…' : 'Select your branch',
            prefixIcon: const Icon(Icons.store_rounded),
            filled: true,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          ),
          items: branches.map((branch) {
            final branchId = branch['id'] as String? ?? '';
            final fullName = branch['name'] as String? ?? branchId;
            final shortName = branch['shortName'] as String? ?? fullName;
            final branchCode =
                (branch['branchCode'] as String? ?? '').trim().isNotEmpty
                ? (branch['branchCode'] as String).trim()
                : branchId;
            return DropdownMenuItem<String>(
              value: branchId,
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      shortName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.labelLarge(
                        color: context.themeTextPrimary,
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Container(
                    constraints: const BoxConstraints(maxWidth: 88),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: context.themePrimary.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      branchCode,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.caption(color: context.themePrimary),
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
          onChanged: isLoading || branches.isEmpty ? null : onChanged,
          validator: (value) => value == null ? 'Select a branch' : null,
        ),
        if (selectedFullName != null &&
            selectedShortName != null &&
            selectedFullName != selectedShortName)
          Padding(
            padding: const EdgeInsets.only(left: 12, top: 6),
            child: Text(
              selectedFullName,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: AppTypography.caption(color: context.themeTextSecondary),
            ),
          ),
      ],
    );
  }
}
