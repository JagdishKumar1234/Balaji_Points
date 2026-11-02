import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/material.dart';

import 'package:balaji_points/core/design/app_colors.dart';
import 'package:balaji_points/core/design/app_radius.dart';
import 'package:balaji_points/core/design/app_spacing.dart';
import 'package:balaji_points/core/design/app_typography.dart';
import 'package:balaji_points/services/branch/super_admin_service.dart';
import 'package:balaji_points/presentation/screens/super_admin/super_admin_loading_view.dart';

String _adminAccountsError(Object error) {
  if (error is FirebaseFunctionsException && error.message != null) {
    return error.message!;
  }
  if (error is FirebaseException && error.code == 'permission-denied') {
    return 'Permission denied. Verify Firestore rules and your Super Admin account.';
  }
  return error.toString().replaceFirst('Exception: ', '');
}

class SuperAdminAdminAccountsPanel extends StatefulWidget {
  const SuperAdminAdminAccountsPanel({super.key});

  @override
  State<SuperAdminAdminAccountsPanel> createState() =>
      _SuperAdminAdminAccountsPanelState();
}

class _SuperAdminAdminAccountsPanelState
    extends State<SuperAdminAdminAccountsPanel> {
  final _searchController = TextEditingController();
  String _search = '';
  int _reloadKey = 0;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: AppSpacing.xl),
        Text(
          'Branch admin accounts',
          style: AppTypography.h4(color: context.themePrimary),
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          'Review each admin and the branch they manage. Reset passwords or remove an account.',
          style: AppTypography.bodySmall(color: context.themeTextSecondary),
        ),
        const SizedBox(height: AppSpacing.md),
        SearchBar(
          controller: _searchController,
          hintText: 'Search by name, email or branch',
          leading: const Icon(Icons.search_rounded),
          trailing: [
            if (_search.isNotEmpty)
              IconButton(
                tooltip: 'Clear search',
                onPressed: () {
                  _searchController.clear();
                  setState(() => _search = '');
                },
                icon: const Icon(Icons.clear_rounded),
              ),
          ],
          onChanged: (value) => setState(() => _search = value.trim()),
        ),
        const SizedBox(height: AppSpacing.md),
        StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
          key: ValueKey(_reloadKey),
          stream: FirebaseFirestore.instance
              .collection('users')
              .where('role', isEqualTo: 'admin')
              .snapshots(),
          builder: (context, adminsSnapshot) {
            if (adminsSnapshot.hasError) {
              return _AccountsMessage(
                message: _adminAccountsError(adminsSnapshot.error!),
                isError: true,
                onRetry: () => setState(() => _reloadKey++),
              );
            }
            if (!adminsSnapshot.hasData) {
              return const SuperAdminLoadingView(
                label: 'Loading branch admin accounts…',
              );
            }
            final admins = adminsSnapshot.data!.docs;
            if (admins.isEmpty) {
              return const _AccountsMessage(
                message: 'No branch admin accounts yet.',
              );
            }
            return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: FirebaseFirestore.instance
                  .collection('branches')
                  .snapshots(),
              builder: (context, branchesSnapshot) {
                if (branchesSnapshot.hasError) {
                  return _AccountsMessage(
                    message: _adminAccountsError(branchesSnapshot.error!),
                    isError: true,
                    onRetry: () => setState(() => _reloadKey++),
                  );
                }
                if (!branchesSnapshot.hasData) {
                  return const SuperAdminLoadingView(
                    label: 'Loading branch names…',
                  );
                }
                final branchNames = <String, String>{};
                for (final branch in branchesSnapshot.data?.docs ?? []) {
                  final data = branch.data();
                  branchNames[branch.id] =
                      (data['name'] as String?) ?? branch.id;
                }
                final rows = admins
                    .map((admin) {
                      final data = admin.data();
                      final branchId = data['branchId'] as String? ?? '';
                      final branchName =
                          branchNames[branchId] ??
                          (data['branchName'] as String?) ??
                          branchId;
                      final fullName = [
                        data['firstName'] as String? ?? '',
                        data['lastName'] as String? ?? '',
                      ].where((part) => part.trim().isNotEmpty).join(' ');
                      final searchBlob = [
                        fullName,
                        data['email'] as String? ?? '',
                        branchName,
                        data['phone'] as String? ?? '',
                      ].join(' ').toLowerCase();
                      if (_search.isNotEmpty &&
                          !searchBlob.contains(_search.toLowerCase())) {
                        return null;
                      }
                      return _AdminAccountCard(
                        uid: admin.id,
                        name: fullName.isEmpty ? 'Branch admin' : fullName,
                        email: data['email'] as String? ?? 'No email',
                        phone: data['phone'] as String? ?? '',
                        branchName: branchName,
                        onPasswordReset: (password) =>
                            SuperAdminService().updateBranchAdminPassword(
                              uid: admin.id,
                              password: password,
                            ),
                        onDelete: () =>
                            SuperAdminService().deleteBranchAdmin(admin.id),
                      );
                    })
                    .whereType<Widget>()
                    .toList();
                if (rows.isEmpty) {
                  return _AccountsMessage(
                    message: admins.isEmpty
                        ? 'No branch admin accounts yet.'
                        : 'No admin accounts match “$_search”.',
                  );
                }
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                      child: Row(
                        children: [
                          Text(
                            'Admin accounts',
                            style: AppTypography.labelLarge(
                              color: context.themeTextPrimary,
                            ),
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          Badge(
                            label: Text(rows.length.toString()),
                            child: const Icon(Icons.people_alt_outlined),
                          ),
                        ],
                      ),
                    ),
                    ...rows,
                  ],
                );
              },
            );
          },
        ),
      ],
    );
  }
}

class _AdminAccountCard extends StatefulWidget {
  const _AdminAccountCard({
    required this.uid,
    required this.name,
    required this.email,
    required this.phone,
    required this.branchName,
    required this.onPasswordReset,
    required this.onDelete,
  });

  final String uid;
  final String name;
  final String email;
  final String phone;
  final String branchName;
  final Future<void> Function(String password) onPasswordReset;
  final Future<void> Function() onDelete;

  @override
  State<_AdminAccountCard> createState() => _AdminAccountCardState();
}

class _AdminAccountCardState extends State<_AdminAccountCard> {
  bool _working = false;

  Future<void> _resetPassword() async {
    final password = await showDialog<String>(
      context: context,
      builder: (_) => const _AdminPasswordDialog(),
    );
    if (password == null || !mounted) return;
    setState(() => _working = true);
    try {
      await widget.onPasswordReset(password);
      if (mounted) _message('Password updated for ${widget.email}.');
    } catch (error) {
      if (mounted) _message(_adminAccountsError(error), error: true);
    } finally {
      if (mounted) setState(() => _working = false);
    }
  }

  Future<void> _delete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete branch admin?'),
        content: Text(
          'Delete ${widget.email} for ${widget.branchName}? They will lose sign-in access. Branch members and their points will be kept.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: context.themeError),
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Delete admin'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    setState(() => _working = true);
    try {
      await widget.onDelete();
      if (mounted) _message('Admin account deleted.');
    } catch (error) {
      if (mounted) _message(_adminAccountsError(error), error: true);
    } finally {
      if (mounted) setState(() => _working = false);
    }
  }

  void _message(String message, {bool error = false}) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: error ? context.themeError : AppColors.success,
          behavior: SnackBarBehavior.floating,
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      elevation: 0,
      color: colors.surfaceContainerLow,
      shape: RoundedRectangleBorder(borderRadius: AppRadius.forCard),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          ListTile(
            contentPadding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.xs,
            ),
            leading: CircleAvatar(
              backgroundColor: colors.primaryContainer,
              foregroundColor: colors.onPrimaryContainer,
              child: const Icon(Icons.admin_panel_settings_rounded),
            ),
            title: Text(
              widget.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTypography.labelLarge(color: context.themeTextPrimary),
            ),
            subtitle: Text(
              widget.email,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTypography.bodySmall(color: context.themeTextSecondary),
            ),
            trailing: _working
                ? const SizedBox.square(
                    dimension: 22,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Icon(Icons.verified_user_outlined, color: colors.primary),
          ),
          const Divider(height: 1, indent: 72),
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.md,
              AppSpacing.sm,
              AppSpacing.md,
              AppSpacing.md,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  spacing: AppSpacing.xs,
                  runSpacing: AppSpacing.xs,
                  children: [
                    Chip(
                      avatar: Icon(Icons.store_outlined, color: colors.primary),
                      label: Text(widget.branchName),
                    ),
                    if (widget.phone.isNotEmpty)
                      Chip(
                        avatar: const Icon(Icons.phone_outlined),
                        label: Text(widget.phone),
                      ),
                  ],
                ),
                const SizedBox(height: AppSpacing.xs),
                Wrap(
                  spacing: AppSpacing.sm,
                  runSpacing: AppSpacing.xs,
                  children: [
                    OutlinedButton.icon(
                      onPressed: _working ? null : _resetPassword,
                      icon: const Icon(Icons.key_rounded),
                      label: const Text('Change password'),
                    ),
                    TextButton.icon(
                      onPressed: _working ? null : _delete,
                      style: TextButton.styleFrom(
                        foregroundColor: context.themeError,
                      ),
                      icon: const Icon(Icons.delete_outline_rounded),
                      label: const Text('Delete account'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _AdminPasswordDialog extends StatefulWidget {
  const _AdminPasswordDialog();

  @override
  State<_AdminPasswordDialog> createState() => _AdminPasswordDialogState();
}

class _AdminPasswordDialogState extends State<_AdminPasswordDialog> {
  final _formKey = GlobalKey<FormState>();
  final _password = TextEditingController();
  final _confirm = TextEditingController();
  bool _visible = false;

  @override
  void dispose() {
    _password.dispose();
    _confirm.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Change admin password'),
      content: SizedBox(
        width: 420,
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _password,
                obscureText: !_visible,
                decoration: InputDecoration(
                  labelText: 'New password',
                  suffixIcon: IconButton(
                    onPressed: () => setState(() => _visible = !_visible),
                    icon: Icon(
                      _visible ? Icons.visibility_off : Icons.visibility,
                    ),
                  ),
                ),
                validator: (value) => (value?.length ?? 0) < 8
                    ? 'Use at least 8 characters'
                    : null,
              ),
              const SizedBox(height: AppSpacing.sm),
              TextFormField(
                controller: _confirm,
                obscureText: !_visible,
                decoration: const InputDecoration(
                  labelText: 'Confirm new password',
                ),
                validator: (value) =>
                    value != _password.text ? 'Passwords do not match' : null,
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () {
            if (_formKey.currentState!.validate()) {
              Navigator.pop(context, _password.text);
            }
          },
          child: const Text('Update password'),
        ),
      ],
    );
  }
}

class _AccountsMessage extends StatelessWidget {
  const _AccountsMessage({
    required this.message,
    this.isError = false,
    this.onRetry,
  });

  final String message;
  final bool isError;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(AppSpacing.md),
    decoration: BoxDecoration(
      color: isError
          ? context.themeError.withValues(alpha: .08)
          : context.themeSurface,
      borderRadius: AppRadius.forCard,
      border: Border.all(
        color: isError
            ? context.themeError.withValues(alpha: .3)
            : context.themeBorder,
      ),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          message,
          style: AppTypography.bodyMedium(color: context.themeTextSecondary),
        ),
        if (onRetry != null)
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Try again'),
            ),
          ),
      ],
    ),
  );
}
