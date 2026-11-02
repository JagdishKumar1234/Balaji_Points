import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'package:balaji_points/core/design/app_colors.dart';
import 'package:balaji_points/core/design/app_radius.dart';
import 'package:balaji_points/core/design/app_spacing.dart';
import 'package:balaji_points/core/design/app_typography.dart';
import 'package:balaji_points/presentation/screens/super_admin/super_admin_admin_accounts_panel.dart';
import 'package:balaji_points/presentation/screens/super_admin/super_admin_loading_view.dart';
import 'package:balaji_points/services/branch/branch_service.dart';
import 'package:balaji_points/services/branch/super_admin_service.dart';

String _superAdminErrorMessage(Object error) {
  if (error is FirebaseFunctionsException && error.message != null) {
    return error.message!;
  }
  if (error is FirebaseException && error.code == 'permission-denied') {
    return 'Permission denied. Check that Firestore rules are published and '
        'the signed-in account is the configured super admin.';
  }
  return error.toString().replaceFirst('Exception: ', '');
}

// ── Create admin tab ──────────────────────────────────────────────────────────

class SuperAdminCreateAdminTab extends StatefulWidget {
  const SuperAdminCreateAdminTab({super.key});

  @override
  State<SuperAdminCreateAdminTab> createState() =>
      SuperAdminCreateAdminTabState();
}

class SuperAdminCreateAdminTabState extends State<SuperAdminCreateAdminTab> {
  final _formKey = GlobalKey<FormState>();
  final _phoneCtrl = TextEditingController();
  final _firstCtrl = TextEditingController();
  final _lastCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _confirmPasswordCtrl = TextEditingController();

  List<Map<String, dynamic>> _branches = [];
  String? _selectedBranchId;
  bool _loadingBranches = true;
  bool _saving = false;
  bool _obscurePassword = true;

  @override
  void initState() {
    super.initState();
    _loadBranches();
  }

  Future<void> _loadBranches() async {
    final b = await BranchService().listActiveBranches();
    if (mounted) {
      setState(() {
        _branches = b;
        if (b.length == 1) _selectedBranchId = b.first['id'] as String;
        _loadingBranches = false;
      });
    }
  }

  @override
  void dispose() {
    _phoneCtrl.dispose();
    _firstCtrl.dispose();
    _lastCtrl.dispose();
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    _confirmPasswordCtrl.dispose();
    super.dispose();
  }

  Future<void> _create() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedBranchId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Select a branch first.'),
          backgroundColor: context.themeError,
        ),
      );
      return;
    }

    setState(() => _saving = true);
    try {
      final result = await SuperAdminService().createBranchAdmin(
        email: _emailCtrl.text.trim(),
        password: _passwordCtrl.text,
        firstName: _firstCtrl.text.trim(),
        lastName: _lastCtrl.text.trim(),
        phone: _phoneCtrl.text.trim(),
        branchId: _selectedBranchId!,
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Admin ${result.email} created for ${result.branchName}. '
            'They can sign in with email and password.',
          ),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
        ),
      );
      _formKey.currentState!.reset();
      _phoneCtrl.clear();
      _firstCtrl.clear();
      _lastCtrl.clear();
      _emailCtrl.clear();
      _passwordCtrl.clear();
      _confirmPasswordCtrl.clear();
      setState(() {
        _selectedBranchId = null;
        _obscurePassword = true;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_superAdminErrorMessage(e)),
            backgroundColor: context.themeError,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _sectionLabel('Admin Details'),
            const SizedBox(height: AppSpacing.sm),
            _field(
              _firstCtrl,
              'First Name *',
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Required' : null,
            ),
            const SizedBox(height: AppSpacing.sm),
            _field(_lastCtrl, 'Last Name'),
            const SizedBox(height: AppSpacing.sm),
            _field(
              _phoneCtrl,
              'Mobile number * (10 digits)',
              keyboardType: TextInputType.phone,
              validator: (v) {
                final s = v?.trim() ?? '';
                if (s.length != 10 || !RegExp(r'^[0-9]+$').hasMatch(s)) {
                  return 'Enter valid 10-digit phone';
                }
                return null;
              },
            ),
            const SizedBox(height: AppSpacing.md),
            _sectionLabel('Email and password login'),
            const SizedBox(height: AppSpacing.sm),
            _field(
              _emailCtrl,
              'Email address *',
              keyboardType: TextInputType.emailAddress,
              validator: (v) =>
                  RegExp(
                    r'^[^@\s]+@[^@\s]+\.[^@\s]+$',
                  ).hasMatch(v?.trim() ?? '')
                  ? null
                  : 'Enter a valid email address',
            ),
            const SizedBox(height: AppSpacing.sm),
            _field(
              _passwordCtrl,
              'Temporary password * (8 characters minimum)',
              obscureText: _obscurePassword,
              suffixIcon: IconButton(
                tooltip: _obscurePassword ? 'Show password' : 'Hide password',
                onPressed: () =>
                    setState(() => _obscurePassword = !_obscurePassword),
                icon: Icon(
                  _obscurePassword
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined,
                ),
              ),
              validator: (v) => v == null || v.length < 8
                  ? 'Use at least 8 characters'
                  : null,
            ),
            const SizedBox(height: AppSpacing.sm),
            _field(
              _confirmPasswordCtrl,
              'Confirm password *',
              obscureText: _obscurePassword,
              validator: (v) =>
                  v != _passwordCtrl.text ? 'Passwords do not match' : null,
            ),
            const SizedBox(height: AppSpacing.md),
            _sectionLabel('Assign Branch'),
            const SizedBox(height: AppSpacing.sm),
            _loadingBranches
                ? const Padding(
                    padding: EdgeInsets.all(AppSpacing.md),
                    child: SuperAdminLoadingView(
                      label: 'Loading active branches…',
                      compact: true,
                    ),
                  )
                : _branches.isEmpty
                ? Card.filled(
                    child: const Padding(
                      padding: EdgeInsets.all(AppSpacing.md),
                      child: Text(
                        'No active branches found. Create or activate a branch before adding an admin.',
                      ),
                    ),
                  )
                : Container(
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: context.themeBorder,
                        width: 1.5,
                      ),
                      borderRadius: AppRadius.forInput,
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: _selectedBranchId,
                        isExpanded: true,
                        hint: Text(
                          'Select branch',
                          style: AppTypography.bodyMedium(
                            color: context.themeTextSecondary,
                          ),
                        ),
                        items: _branches.map((b) {
                          return DropdownMenuItem<String>(
                            value: b['id'] as String,
                            child: Text(
                              b['name'] as String? ?? b['id'] as String,
                            ),
                          );
                        }).toList(),
                        onChanged: (v) => setState(() => _selectedBranchId = v),
                      ),
                    ),
                  ),
            const SizedBox(height: AppSpacing.xl),
            ElevatedButton.icon(
              onPressed: _saving ? null : _create,
              style: ElevatedButton.styleFrom(
                backgroundColor: context.themePrimary,
                foregroundColor: AppColors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: AppRadius.forButton,
                ),
              ),
              icon: _saving
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        color: AppColors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : const Icon(Icons.person_add),
              label: Text(
                _saving ? 'Creating account…' : 'Create admin account',
                style: AppTypography.labelLarge(color: AppColors.white),
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
            Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: AppColors.warning.withValues(alpha: 0.1),
                borderRadius: AppRadius.forCard,
                border: Border.all(
                  color: AppColors.warning.withValues(alpha: 0.4),
                ),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.info_outline,
                    color: AppColors.warning,
                    size: 20,
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Text(
                      'Share the temporary password securely. The admin can '
                      'change it after their first sign-in.',
                      style: AppTypography.bodySmall(
                        color: context.themeTextSecondary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SuperAdminAdminAccountsPanel(),
          ],
        ),
      ),
    );
  }

  Widget _sectionLabel(String text) =>
      Text(text, style: AppTypography.labelLarge(color: context.themePrimary));

  Widget _field(
    TextEditingController ctrl,
    String label, {
    String? Function(String?)? validator,
    TextInputType? keyboardType,
    bool obscureText = false,
    Widget? suffixIcon,
  }) {
    return TextFormField(
      controller: ctrl,
      keyboardType: keyboardType,
      validator: validator,
      obscureText: obscureText,
      autofillHints: keyboardType == TextInputType.emailAddress
          ? const [AutofillHints.email]
          : null,
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(borderRadius: AppRadius.forInput),
        isDense: true,
        suffixIcon: suffixIcon,
      ),
    );
  }
}
