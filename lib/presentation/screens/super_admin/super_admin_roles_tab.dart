import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'package:balaji_points/core/design/app_colors.dart';
import 'package:balaji_points/core/design/app_radius.dart';
import 'package:balaji_points/core/design/app_spacing.dart';
import 'package:balaji_points/core/design/app_typography.dart';
import 'package:balaji_points/services/auth/role_service.dart';
import 'package:balaji_points/presentation/screens/super_admin/super_admin_loading_view.dart';

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

class SuperAdminRolesTab extends StatefulWidget {
  const SuperAdminRolesTab({super.key});

  @override
  State<SuperAdminRolesTab> createState() => _SuperAdminRolesTabState();
}

class _SuperAdminRolesTabState extends State<SuperAdminRolesTab> {
  final _service = RoleService();
  List<AppRole> _roles = const [];
  bool _loading = true;
  String? _loadError;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final roles = await _service.listRoles();
      if (mounted) {
        setState(() {
          _roles = roles;
          _loadError = null;
        });
      }
    } catch (error) {
      if (mounted) {
        setState(() {
          _roles = AppRole.defaults;
          _loadError = _superAdminErrorMessage(error);
        });
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _add() async {
    final created = await showDialog<AppRole>(
      context: context,
      builder: (_) => const _AddRoleDialog(),
    );
    if (!mounted || created == null) return;
    await _load();
    if (mounted) {
      _message('Role created: ${created.name} (${created.id}).');
    }
  }

  Future<void> _toggle(AppRole role) async {
    final activating = !role.isActive;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: AppRadius.forCard),
        title: Text(activating ? 'Restore role?' : 'Delete role?'),
        content: Text(
          activating
              ? '${role.name} will be available for new account registration.'
              : '${role.name} will be removed from new registration. Existing users '
                    'keep their role and account data.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            style: FilledButton.styleFrom(
              backgroundColor: activating
                  ? context.themePrimary
                  : context.themeError,
              foregroundColor: AppColors.white,
            ),
            child: Text(activating ? 'Restore role' : 'Delete role'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    try {
      await _service.setRoleActive(role, activating);
      await _load();
      if (mounted) {
        _message('Role ${role.name}${activating ? ' restored.' : ' deleted.'}');
      }
    } catch (error) {
      if (mounted) _message(_superAdminErrorMessage(error), error: true);
    }
  }

  void _message(String value, {bool error = false}) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(value),
          backgroundColor: error ? context.themeError : AppColors.success,
          behavior: SnackBarBehavior.floating,
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.topCenter,
      child: RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.md),
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Account roles',
                        style: AppTypography.h4(color: context.themePrimary),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Manage the roles shown in create account.',
                        style: AppTypography.bodySmall(
                          color: context.themeTextSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                FilledButton.icon(
                  onPressed: _add,
                  icon: const Icon(Icons.add_rounded),
                  label: const Text('Add role'),
                  style: FilledButton.styleFrom(
                    backgroundColor: context.themePrimary,
                    foregroundColor: AppColors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: AppRadius.forButton,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: context.themePrimary.withValues(alpha: 0.06),
                borderRadius: AppRadius.forCard,
              ),
              child: const Text(
                'Role IDs are stored with user accounts. Deleting a role '
                'removes it from new registrations and preserves existing '
                'accounts.',
              ),
            ),
            if (_loadError != null) ...[
              const SizedBox(height: AppSpacing.sm),
              MaterialBanner(
                content: Text(
                  'Could not load saved roles. Showing the four built-in roles. '
                  '$_loadError',
                ),
                leading: Icon(
                  Icons.cloud_off_outlined,
                  color: context.themeError,
                ),
                actions: [
                  TextButton(onPressed: _load, child: const Text('Retry')),
                ],
              ),
            ],
            const SizedBox(height: AppSpacing.md),
            if (_loading)
              const SuperAdminLoadingView(label: 'Loading account roles…')
            else if (_roles.isEmpty)
              const Padding(
                padding: EdgeInsets.all(AppSpacing.xl),
                child: Center(child: Text('No roles found.')),
              )
            else
              ..._roles.map(
                (role) => Card(
                  margin: const EdgeInsets.only(bottom: AppSpacing.sm),
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: AppRadius.forCard,
                    side: BorderSide(color: context.themeBorder),
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.md,
                      vertical: AppSpacing.xs,
                    ),
                    leading: CircleAvatar(
                      backgroundColor: context.themePrimary.withValues(
                        alpha: 0.10,
                      ),
                      foregroundColor: context.themePrimary,
                      child: const Icon(Icons.badge_outlined),
                    ),
                    title: Text(
                      role.selectionLabel,
                      style: AppTypography.labelLarge(
                        color: context.themeTextPrimary,
                      ),
                    ),
                    subtitle: Text('Role ID: ${role.id}'),
                    trailing: Wrap(
                      crossAxisAlignment: WrapCrossAlignment.center,
                      spacing: AppSpacing.xs,
                      children: [
                        _RoleStatusChip(isActive: role.isActive),
                        TextButton.icon(
                          onPressed: () => _toggle(role),
                          icon: Icon(
                            role.isActive
                                ? Icons.delete_outline_rounded
                                : Icons.restart_alt_rounded,
                            size: 18,
                          ),
                          label: Text(role.isActive ? 'Delete' : 'Restore'),
                          style: TextButton.styleFrom(
                            foregroundColor: role.isActive
                                ? context.themeError
                                : context.themePrimary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _RoleStatusChip extends StatelessWidget {
  const _RoleStatusChip({required this.isActive});

  final bool isActive;

  @override
  Widget build(BuildContext context) {
    final color = isActive ? AppColors.success : context.themeTextMuted;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: AppRadius.pill,
      ),
      child: Text(
        isActive ? 'Active' : 'Deleted',
        style: AppTypography.caption(color: color),
      ),
    );
  }
}

class _AddRoleDialog extends StatefulWidget {
  const _AddRoleDialog();

  @override
  State<_AddRoleDialog> createState() => _AddRoleDialogState();
}

class _AddRoleDialogState extends State<_AddRoleDialog> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _abbreviation = TextEditingController();
  final _service = RoleService();
  bool _saving = false;

  @override
  void dispose() {
    _name.dispose();
    _abbreviation.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      final role = await _service.createRole(
        name: _name.text,
        abbreviation: _abbreviation.text,
      );
      if (mounted) Navigator.pop(context, role);
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_superAdminErrorMessage(error)),
          backgroundColor: context.themeError,
        ),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final roleId = _service.createRoleId(_name.text);
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: AppRadius.forCard),
      title: const Text('Add account role'),
      content: SizedBox(
        width: 440,
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _name,
                autofocus: true,
                onChanged: (_) => setState(() {}),
                textCapitalization: TextCapitalization.words,
                decoration: InputDecoration(
                  labelText: 'Role name *',
                  border: OutlineInputBorder(borderRadius: AppRadius.forInput),
                ),
                validator: (value) => (value?.trim().length ?? 0) < 2
                    ? 'Enter at least 2 characters'
                    : null,
              ),
              const SizedBox(height: AppSpacing.sm),
              TextFormField(
                controller: _abbreviation,
                textCapitalization: TextCapitalization.characters,
                decoration: InputDecoration(
                  labelText: 'Short form (optional)',
                  hintText: 'Example: Ar.',
                  border: OutlineInputBorder(borderRadius: AppRadius.forInput),
                ),
                validator: (value) => (value?.trim().length ?? 0) > 10
                    ? 'Use 10 characters or less'
                    : null,
              ),
              const SizedBox(height: AppSpacing.sm),
              Align(
                alignment: Alignment.centerLeft,
                child: Text('Role ID: ${roleId.isEmpty ? 'role_id' : roleId}'),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _saving ? null : () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton.icon(
          onPressed: _saving ? null : _save,
          icon: _saving
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: AppColors.white,
                  ),
                )
              : const Icon(Icons.save_outlined),
          label: Text(_saving ? 'Saving…' : 'Save role'),
        ),
      ],
    );
  }
}
