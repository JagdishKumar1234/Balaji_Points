import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/material.dart';
import 'package:balaji_points/presentation/screens/super_admin/super_admin_create_admin_tab.dart';
import 'package:balaji_points/presentation/widgets/shared/empty_state.dart';
import 'package:balaji_points/core/firebase/app_firestore.dart';
import 'package:balaji_points/presentation/screens/super_admin/super_admin_section_header.dart';
import 'package:balaji_points/l10n/app_localizations.dart';

import 'package:balaji_points/core/design/app_colors.dart';
import 'package:balaji_points/core/design/app_radius.dart';
import 'package:balaji_points/core/design/app_spacing.dart';
import 'package:balaji_points/core/design/app_typography.dart';
import 'package:balaji_points/services/branch/super_admin_service.dart';
import 'package:balaji_points/presentation/screens/super_admin/super_admin_loading_view.dart';

String _adminAccountsError(BuildContext context, Object error) {
  if (error is FirebaseFunctionsException && error.message != null) {
    return error.message!;
  }
  if (error is FirebaseException && error.code == 'permission-denied') {
    return AppLocalizations.of(context)!.permissionDeniedSuperAdmin;
  }
  return error.toString().replaceFirst('Exception: ', '');
}

class SuperAdminAdminAccountsPanel extends StatefulWidget {
  const SuperAdminAdminAccountsPanel({super.key, this.action});

  /// Main action shown in the section header (e.g. "Add admin").
  final Widget? action;

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
        SuperAdminSectionHeader(
          title: AppLocalizations.of(context)!.branchAdminsTitle,
          subtitle: AppLocalizations.of(context)!.reviewEachAdminAndTheBranch,
          action: widget.action,
        ),
        const SizedBox(height: AppSpacing.md),
        TextField(
          controller: _searchController,
          textInputAction: TextInputAction.search,
          onChanged: (value) => setState(() => _search = value.trim()),
          decoration: InputDecoration(
            hintText: AppLocalizations.of(context)!.searchByNameEmailOrBranch,
            floatingLabelBehavior: FloatingLabelBehavior.never,
            prefixIcon: const Icon(Icons.search_rounded),
            suffixIcon: _search.isEmpty
                ? null
                : IconButton(
                    tooltip: AppLocalizations.of(context)!.clearSearch,
                    onPressed: () {
                      _searchController.clear();
                      setState(() => _search = '');
                    },
                    icon: const Icon(Icons.clear_rounded),
                  ),
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
          key: ValueKey(_reloadKey),
          stream: appFirestore
              .collection('users')
              .where('role', isEqualTo: 'admin')
              .snapshots(),
          builder: (context, adminsSnapshot) {
            if (adminsSnapshot.hasError) {
              return _AccountsMessage(
                message: _adminAccountsError(context, adminsSnapshot.error!),
                isError: true,
                onRetry: () => setState(() => _reloadKey++),
              );
            }
            if (!adminsSnapshot.hasData) {
              return SuperAdminLoadingView(
                label: AppLocalizations.of(context)!.loadingBranchAdminAccounts,
              );
            }
            final admins = adminsSnapshot.data!.docs;
            if (admins.isEmpty) {
              return EmptyState(
                icon: Icons.manage_accounts_outlined,
                title: AppLocalizations.of(context)!.noBranchAdminAccountsYet,
              );
            }
            return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: appFirestore.collection('branches').snapshots(),
              builder: (context, branchesSnapshot) {
                if (branchesSnapshot.hasError) {
                  return _AccountsMessage(
                    message: _adminAccountsError(
                      context,
                      branchesSnapshot.error!,
                    ),
                    isError: true,
                    onRetry: () => setState(() => _reloadKey++),
                  );
                }
                if (!branchesSnapshot.hasData) {
                  return SuperAdminLoadingView(
                    label: AppLocalizations.of(context)!.loadingBranchNames,
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
                        firstName: data['firstName'] as String? ?? '',
                        lastName: data['lastName'] as String? ?? '',
                        branchId: branchId,
                        name: fullName.isEmpty
                            ? AppLocalizations.of(context)!.branchAdmin
                            : fullName,
                        email:
                            data['email'] as String? ??
                            AppLocalizations.of(context)!.noEmail,
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
                        ? AppLocalizations.of(context)!.noBranchAdminAccountsYet
                        : AppLocalizations.of(
                            context,
                          )!.noAdminAccountsMatch('$_search'),
                  );
                }
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                      child: Text(
                        AppLocalizations.of(context)!.adminsCount(rows.length),
                        style: AppTypography.caption(
                          color: context.themeTextSecondary,
                        ),
                      ),
                    ),
                    LayoutBuilder(
                      builder: (context, constraints) {
                        const gap = AppSpacing.md;
                        final columns = constraints.maxWidth >= 860 ? 2 : 1;
                        final width =
                            (constraints.maxWidth - gap * (columns - 1)) /
                            columns;
                        return Wrap(
                          spacing: gap,
                          runSpacing: gap,
                          children: [
                            for (final row in rows)
                              SizedBox(width: width, child: row),
                          ],
                        );
                      },
                    ),
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
    required this.firstName,
    required this.lastName,
    required this.branchId,
    required this.name,
    required this.email,
    required this.phone,
    required this.branchName,
    required this.onPasswordReset,
    required this.onDelete,
  });

  final String uid;
  final String firstName;
  final String lastName;
  final String branchId;
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

  Future<void> _edit() async {
    final result = await showDialog<BranchAdminResult>(
      context: context,
      barrierDismissible: false,
      builder: (_) => CreateBranchAdminDialog(
        existing: AdminFormData(
          uid: widget.uid,
          firstName: widget.firstName,
          lastName: widget.lastName,
          phone: widget.phone,
          email: widget.email,
          branchId: widget.branchId,
          branchName: widget.branchName,
        ),
      ),
    );
    if (result == null || !mounted) return;
    _message(AppLocalizations.of(context)!.adminUpdated(result.email));
  }

  Future<void> _resetPassword() async {
    final password = await showDialog<String>(
      context: context,
      builder: (_) => const _AdminPasswordDialog(),
    );
    if (password == null || !mounted) return;
    setState(() => _working = true);
    try {
      await widget.onPasswordReset(password);
      if (mounted)
        _message(
          AppLocalizations.of(context)!.passwordUpdatedFor('${widget.email}'),
        );
    } catch (error) {
      if (mounted) _message(_adminAccountsError(context, error), error: true);
    } finally {
      if (mounted) setState(() => _working = false);
    }
  }

  Future<void> _delete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(AppLocalizations.of(context)!.deleteBranchAdmin),
        content: Text(
          AppLocalizations.of(context)!.deleteForTheyWillLoseSign(
            '${widget.email}',
            '${widget.branchName}',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(AppLocalizations.of(context)!.cancel),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: context.themeError,
              foregroundColor: context.themeOnError,
            ),
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(AppLocalizations.of(context)!.deleteAdmin),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    setState(() => _working = true);
    try {
      await widget.onDelete();
      if (mounted) _message(AppLocalizations.of(context)!.adminAccountDeleted);
    } catch (error) {
      if (mounted) _message(_adminAccountsError(context, error), error: true);
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
          backgroundColor: error ? context.themeError : null,
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final parts = widget.name.trim().split(RegExp(r'\s+'));
    final initials = parts
        .where((p) => p.isNotEmpty)
        .take(2)
        .map((p) => p.characters.first.toUpperCase())
        .join();
    final secondary = context.themeTextSecondary;

    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 4, 14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 44,
              height: 44,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: AppRadius.md12,
              ),
              child: Text(
                initials.isEmpty ? '?' : initials,
                style: AppTypography.section(color: AppColors.gold),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.section(
                      color: context.themeTextPrimary,
                    ),
                  ),
                  Text(
                    widget.email,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.caption(color: secondary),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(top: 1),
                        child: Icon(
                          Icons.store_outlined,
                          size: 16,
                          color: secondary,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          widget.branchName,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: AppTypography.caption(color: secondary),
                        ),
                      ),
                    ],
                  ),
                  if (widget.phone.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(Icons.call_outlined, size: 16, color: secondary),
                        const SizedBox(width: 4),
                        Text(
                          widget.phone,
                          style: AppTypography.caption(color: secondary),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            if (_working)
              const Padding(
                padding: EdgeInsets.all(14),
                child: SizedBox.square(
                  dimension: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              )
            else
              PopupMenuButton<String>(
                tooltip: l10n.adminActions,
                icon: const Icon(Icons.more_vert_rounded),
                onSelected: (value) {
                  if (value == 'edit') _edit();
                  if (value == 'password') _resetPassword();
                  if (value == 'delete') _delete();
                },
                itemBuilder: (_) => [
                  PopupMenuItem(
                    value: 'edit',
                    child: ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.edit_outlined),
                      title: Text(l10n.editDetails),
                    ),
                  ),
                  PopupMenuItem(
                    value: 'password',
                    child: ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.key_rounded),
                      title: Text(l10n.changePassword),
                    ),
                  ),
                  PopupMenuItem(
                    value: 'delete',
                    child: ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: Icon(
                        Icons.delete_outline_rounded,
                        color: context.themeError,
                      ),
                      title: Text(
                        l10n.deleteAccount,
                        style: TextStyle(color: context.themeError),
                      ),
                    ),
                  ),
                ],
              ),
          ],
        ),
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
      title: Text(AppLocalizations.of(context)!.changeAdminPassword),
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
                  labelText: AppLocalizations.of(context)!.newPassword,
                  suffixIcon: IconButton(
                    onPressed: () => setState(() => _visible = !_visible),
                    icon: Icon(
                      _visible
                          ? Icons.visibility_off_rounded
                          : Icons.visibility_rounded,
                    ),
                  ),
                ),
                validator: (value) => (value?.length ?? 0) < 8
                    ? AppLocalizations.of(context)!.useAtLeast8Characters
                    : null,
              ),
              const SizedBox(height: AppSpacing.sm),
              TextFormField(
                controller: _confirm,
                obscureText: !_visible,
                decoration: InputDecoration(
                  labelText: AppLocalizations.of(context)!.confirmNewPassword,
                ),
                validator: (value) => value != _password.text
                    ? AppLocalizations.of(context)!.passwordsDoNotMatch
                    : null,
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(AppLocalizations.of(context)!.cancel),
        ),
        FilledButton(
          onPressed: () {
            if (_formKey.currentState!.validate()) {
              Navigator.pop(context, _password.text);
            }
          },
          child: Text(AppLocalizations.of(context)!.updatePassword),
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
              label: Text(AppLocalizations.of(context)!.tryAgain),
            ),
          ),
      ],
    ),
  );
}
