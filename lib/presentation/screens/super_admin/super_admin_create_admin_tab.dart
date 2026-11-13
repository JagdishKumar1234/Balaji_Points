import 'package:flutter/material.dart';
import 'package:balaji_points/presentation/widgets/shared/app_loader.dart';
import 'package:balaji_points/l10n/app_localizations.dart';
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

String _superAdminErrorMessage(BuildContext context, Object error) {
  if (error is FirebaseFunctionsException && error.message != null) {
    return error.message!;
  }
  if (error is FirebaseException && error.code == 'permission-denied') {
    return AppLocalizations.of(context)!.permissionDeniedSuperAdmin;
  }
  return error.toString().replaceFirst('Exception: ', '');
}

// ── Admins tab: list first, "Add admin" opens the form ───────────────────────

class SuperAdminCreateAdminTab extends StatelessWidget {
  const SuperAdminCreateAdminTab({super.key});

  Future<void> _openAddAdmin(BuildContext context) async {
    final result = await showDialog<BranchAdminResult>(
      context: context,
      barrierDismissible: false,
      builder: (_) => const CreateBranchAdminDialog(),
    );
    if (result == null || !context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          AppLocalizations.of(
            context,
          )!.adminCreatedForTheyCanSign(result.email, result.branchName),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // The accounts panel streams admins live, so a new admin appears
    // as soon as the dialog closes.
    return SingleChildScrollView(
      padding: const EdgeInsets.only(bottom: AppSpacing.xl3),
      child: SuperAdminAdminAccountsPanel(
        action: FilledButton.icon(
          onPressed: () => _openAddAdmin(context),
          icon: const Icon(Icons.person_add_alt_1_rounded),
          label: Text(AppLocalizations.of(context)!.addAdmin),
        ),
      ),
    );
  }
}

/// Add-admin form. Full screen on phones, a 520 px dialog on wider screens.
/// Pops with the [BranchAdminResult] on success.
/// Current values of an admin being edited.
class AdminFormData {
  const AdminFormData({
    required this.uid,
    required this.firstName,
    required this.lastName,
    required this.phone,
    required this.email,
    required this.branchId,
    required this.branchName,
  });
  final String uid, firstName, lastName, phone, email, branchId, branchName;
}

class CreateBranchAdminDialog extends StatefulWidget {
  const CreateBranchAdminDialog({super.key, this.existing});

  /// When set, the dialog edits this admin (no password fields).
  final AdminFormData? existing;

  @override
  State<CreateBranchAdminDialog> createState() =>
      _CreateBranchAdminDialogState();
}

class _CreateBranchAdminDialogState extends State<CreateBranchAdminDialog> {
  String? _error;

  final _formKey = GlobalKey<FormState>();
  late final _phoneCtrl = TextEditingController(text: widget.existing?.phone);
  late final _firstCtrl = TextEditingController(
    text: widget.existing?.firstName,
  );
  late final _lastCtrl = TextEditingController(text: widget.existing?.lastName);
  late final _emailCtrl = TextEditingController(text: widget.existing?.email);
  final _passwordCtrl = TextEditingController();
  final _confirmPasswordCtrl = TextEditingController();

  List<Map<String, dynamic>> _branches = [];
  late String? _selectedBranchId = widget.existing?.branchId;

  bool get _editing => widget.existing != null;
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
    final existing = widget.existing;
    // Keep the admin's current branch selectable even if it was deactivated.
    if (existing != null &&
        existing.branchId.isNotEmpty &&
        !b.any((x) => x['id'] == existing.branchId)) {
      b.insert(0, {'id': existing.branchId, 'name': existing.branchName});
    }
    if (mounted) {
      setState(() {
        _branches = b;
        if (b.length == 1 && _selectedBranchId == null) {
          _selectedBranchId = b.first['id'] as String;
        }
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
      setState(() => _error = AppLocalizations.of(context)!.selectABranchFirst);
      return;
    }

    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      final result = _editing
          ? await SuperAdminService().updateBranchAdmin(
              uid: widget.existing!.uid,
              email: _emailCtrl.text.trim(),
              firstName: _firstCtrl.text.trim(),
              lastName: _lastCtrl.text.trim(),
              phone: _phoneCtrl.text.trim(),
              branchId: _selectedBranchId!,
            )
          : await SuperAdminService().createBranchAdmin(
              email: _emailCtrl.text.trim(),
              password: _passwordCtrl.text,
              firstName: _firstCtrl.text.trim(),
              lastName: _lastCtrl.text.trim(),
              phone: _phoneCtrl.text.trim(),
              branchId: _selectedBranchId!,
            );

      if (mounted) Navigator.of(context).pop(result);
    } catch (e) {
      if (mounted) setState(() => _error = _superAdminErrorMessage(context, e));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final fullscreen = MediaQuery.sizeOf(context).width < 600;
    final content = SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (_error != null) ...[
              Container(
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: context.themeErrorSoft,
                  borderRadius: AppRadius.md12,
                ),
                child: Text(
                  _error!,
                  style: AppTypography.body(color: context.themeErrorText),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
            ],
            _sectionLabel(AppLocalizations.of(context)!.adminDetails),
            const SizedBox(height: AppSpacing.sm),
            _field(
              _firstCtrl,
              AppLocalizations.of(context)!.firstNameRequired,
              hint: AppLocalizations.of(context)!.enterFirstName,
              validator: (v) => (v == null || v.trim().isEmpty)
                  ? AppLocalizations.of(context)!.requiredLabel
                  : null,
            ),
            const SizedBox(height: AppSpacing.sm),
            _field(
              _lastCtrl,
              AppLocalizations.of(context)!.lastName,
              hint: AppLocalizations.of(context)!.enterLastName,
            ),
            const SizedBox(height: AppSpacing.sm),
            _field(
              _phoneCtrl,
              AppLocalizations.of(context)!.mobileNumber10Digits,
              hint: AppLocalizations.of(context)!.hintPhone,
              keyboardType: TextInputType.phone,
              validator: (v) {
                final s = v?.trim() ?? '';
                if (s.length != 10 || !RegExp(r'^[0-9]+$').hasMatch(s)) {
                  return AppLocalizations.of(context)!.enterValid10DigitPhone;
                }
                return null;
              },
            ),
            const SizedBox(height: AppSpacing.md),
            _sectionLabel(
              _editing
                  ? AppLocalizations.of(context)!.email
                  : AppLocalizations.of(context)!.emailAndPasswordLogin,
            ),
            const SizedBox(height: AppSpacing.sm),
            _field(
              _emailCtrl,
              AppLocalizations.of(context)!.emailAddress,
              hint: AppLocalizations.of(context)!.hintEmail,
              keyboardType: TextInputType.emailAddress,
              validator: (v) =>
                  RegExp(
                    r'^[^@\s]+@[^@\s]+\.[^@\s]+$',
                  ).hasMatch(v?.trim() ?? '')
                  ? null
                  : AppLocalizations.of(context)!.enterAValidEmailAddress,
            ),
            if (!_editing) ...[
              const SizedBox(height: AppSpacing.sm),
              _field(
                _passwordCtrl,
                AppLocalizations.of(
                  context,
                )!.temporaryPassword8CharactersMinimum,
                hint: AppLocalizations.of(context)!.hintPasswordMin,
                obscureText: _obscurePassword,
                suffixIcon: IconButton(
                  tooltip: _obscurePassword
                      ? AppLocalizations.of(context)!.showPassword
                      : AppLocalizations.of(context)!.hidePassword,
                  onPressed: () =>
                      setState(() => _obscurePassword = !_obscurePassword),
                  icon: Icon(
                    _obscurePassword
                        ? Icons.visibility_outlined
                        : Icons.visibility_off_outlined,
                  ),
                ),
                validator: (v) => v == null || v.length < 8
                    ? AppLocalizations.of(context)!.useAtLeast8Characters
                    : null,
              ),
              const SizedBox(height: AppSpacing.sm),
              _field(
                _confirmPasswordCtrl,
                AppLocalizations.of(context)!.confirmPassword,
                hint: AppLocalizations.of(context)!.hintConfirmPassword,
                obscureText: _obscurePassword,
                validator: (v) => v != _passwordCtrl.text
                    ? AppLocalizations.of(context)!.passwordsDoNotMatch
                    : null,
              ),
            ],
            const SizedBox(height: AppSpacing.md),
            _sectionLabel(AppLocalizations.of(context)!.assignBranch),
            const SizedBox(height: AppSpacing.sm),
            _loadingBranches
                ? Padding(
                    padding: EdgeInsets.all(AppSpacing.md),
                    child: SuperAdminLoadingView(
                      label: AppLocalizations.of(
                        context,
                      )!.loadingActiveBranches,
                      compact: true,
                    ),
                  )
                : _branches.isEmpty
                ? Card.filled(
                    child: Padding(
                      padding: EdgeInsets.all(AppSpacing.md),
                      child: Text(
                        AppLocalizations.of(
                          context,
                        )!.noActiveBranchesFoundCreateOr,
                      ),
                    ),
                  )
                : DropdownButtonFormField<String>(
                    initialValue: _selectedBranchId,
                    isExpanded: true,
                    decoration: InputDecoration(
                      labelText: AppLocalizations.of(context)!.selectBranch,
                    ),
                    validator: (v) => v == null
                        ? AppLocalizations.of(context)!.selectBranchRequired
                        : null,
                    items: _branches.map((b) {
                      return DropdownMenuItem<String>(
                        value: b['id'] as String,
                        child: Text(
                          b['name'] as String? ?? b['id'] as String,
                          overflow: TextOverflow.ellipsis,
                        ),
                      );
                    }).toList(),
                    onChanged: (v) => setState(() => _selectedBranchId = v),
                  ),
            if (_editing && _selectedBranchId != widget.existing!.branchId) ...[
              const SizedBox(height: AppSpacing.sm),
              Text(
                AppLocalizations.of(context)!.adminBranchChangeNote,
                style: AppTypography.caption(color: context.themePendingText),
              ),
            ],
            const SizedBox(height: AppSpacing.lg),
            ElevatedButton.icon(
              onPressed: _saving ? null : _create,
              icon: _saving
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: AppLoader(
                        color: AppColors.primary,
                        strokeWidth: 2,
                      ),
                    )
                  : Icon(
                      _editing ? Icons.check_rounded : Icons.person_add_rounded,
                    ),
              label: Text(
                _saving
                    ? (_editing
                          ? AppLocalizations.of(context)!.saving
                          : AppLocalizations.of(context)!.creatingAccount)
                    : (_editing
                          ? AppLocalizations.of(context)!.saveChanges
                          : AppLocalizations.of(context)!.createAdminAccount),
                style: AppTypography.labelLarge(),
              ),
            ),
            if (!_editing) ...[
              const SizedBox(height: AppSpacing.md),
              Container(
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: context.themePendingSoft,
                  borderRadius: AppRadius.md12,
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.info_outline_rounded,
                      color: context.themePendingText,
                      size: 20,
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Text(
                        AppLocalizations.of(
                          context,
                        )!.shareTheTemporaryPasswordSecurelyThe,
                        style: AppTypography.caption(
                          color: context.themePendingText,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
    final close = IconButton(
      tooltip: l10n.cancel,
      onPressed: _saving ? null : () => Navigator.of(context).pop(),
      icon: const Icon(Icons.close_rounded),
    );
    if (fullscreen) {
      return Dialog.fullscreen(
        child: Scaffold(
          appBar: AppBar(
            leading: close,
            title: Text(_editing ? l10n.editAdmin : l10n.addAdmin),
          ),
          body: SafeArea(child: content),
        ),
      );
    }
    return Dialog(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: 520,
          maxHeight: MediaQuery.sizeOf(context).height * 0.9,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 16, 8, 0),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      _editing ? l10n.editAdmin : l10n.addAdmin,
                      style: AppTypography.title(),
                    ),
                  ),
                  close,
                ],
              ),
            ),
            Flexible(child: content),
          ],
        ),
      ),
    );
  }

  Widget _sectionLabel(String text) => Semantics(
    header: true,
    child: Text(
      text,
      style: AppTypography.section(color: context.themeContentColor),
    ),
  );

  Widget _field(
    TextEditingController ctrl,
    String label, {
    String? hint,
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
        hintText: hint,
        suffixIcon: suffixIcon,
      ),
    );
  }
}
