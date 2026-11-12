import 'package:balaji_points/core/points/points_rate.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';

import 'package:balaji_points/core/design/app_colors.dart';
import 'package:balaji_points/core/design/app_radius.dart';
import 'package:balaji_points/core/design/app_spacing.dart';
import 'package:balaji_points/core/design/app_typography.dart';
import 'package:balaji_points/l10n/app_localizations.dart';
import 'package:balaji_points/presentation/screens/super_admin/super_admin_loading_view.dart';
import 'package:balaji_points/presentation/screens/super_admin/super_admin_section_header.dart';
import 'package:balaji_points/presentation/widgets/shared/empty_state.dart';
import 'package:balaji_points/presentation/widgets/shared/role_label.dart';
import 'package:balaji_points/services/auth/role_service.dart';

String _superAdminErrorMessage(BuildContext context, Object error) {
  final l10n = AppLocalizations.of(context)!;
  if (error is RoleException) {
    return switch (error.code) {
      RoleErrorCode.invalidName => l10n.roleErrInvalidName,
      RoleErrorCode.reserved => l10n.roleErrReserved,
      RoleErrorCode.builtInId => l10n.roleErrBuiltIn,
      RoleErrorCode.duplicate => l10n.roleErrDuplicate,
      RoleErrorCode.protected => l10n.roleErrProtected,
    };
  }
  if (error is FirebaseFunctionsException && error.message != null) {
    return error.message!;
  }
  if (error is FirebaseException && error.code == 'permission-denied') {
    return l10n.permissionDeniedSuperAdmin;
  }
  return error.toString().replaceFirst('Exception: ', '');
}

enum _RoleFilter { all, active, deleted }

/// Super Admin → Roles. Streams the `roles` collection, so the list (and the
/// registration screen on every device) updates the moment a role changes.
class SuperAdminRolesTab extends StatefulWidget {
  const SuperAdminRolesTab({super.key, this.service});

  /// Injectable for tests.
  final RoleService? service;

  @override
  State<SuperAdminRolesTab> createState() => _SuperAdminRolesTabState();
}

class _SuperAdminRolesTabState extends State<SuperAdminRolesTab> {
  late final RoleService _service = widget.service ?? RoleService();
  late Stream<List<AppRole>> _roles = _service.watchRoles();
  _RoleFilter _filter = _RoleFilter.all;
  final Set<String> _busy = {};

  void _retry() => setState(() => _roles = _service.watchRoles());

  Future<void> _add(List<AppRole> current) async {
    final created = await showDialog<AppRole>(
      context: context,
      builder: (_) => _AddRoleDialog(
        service: _service,
        existingIds: {for (final r in current) r.id},
      ),
    );
    if (!mounted || created == null) return;
    _message(
      AppLocalizations.of(context)!.roleCreated(created.name, created.id),
    );
  }

  Future<void> _edit(AppRole role) async {
    final updated = await showDialog<AppRole>(
      context: context,
      builder: (_) => _AddRoleDialog(
        service: _service,
        existingIds: const {},
        existing: role,
      ),
    );
    if (!mounted || updated == null) return;
    _message(AppLocalizations.of(context)!.roleUpdated(updated.name));
  }

  Future<void> _toggle(AppRole role) async {
    final l10n = AppLocalizations.of(context)!;
    final activating = !role.isActive;
    final name = roleDisplayName(context, role);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        icon: Icon(
          activating ? Icons.restore_rounded : Icons.delete_outline_rounded,
          color: activating ? null : dialogContext.themeError,
        ),
        title: Text(activating ? l10n.restoreRole : l10n.deleteRole),
        content: Text(
          activating
              ? l10n.willBeAvailableForNewAccount(name)
              : l10n.willBeRemovedFromNewRegistration(name),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(l10n.cancel),
          ),
          activating
              ? FilledButton(
                  onPressed: () => Navigator.pop(dialogContext, true),
                  child: Text(l10n.restoreRole2),
                )
              : FilledButton(
                  onPressed: () => Navigator.pop(dialogContext, true),
                  style: FilledButton.styleFrom(
                    backgroundColor: context.themeError,
                    foregroundColor: context.themeOnError,
                  ),
                  child: Text(l10n.deleteRole2),
                ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    setState(() => _busy.add(role.id));
    try {
      await _service.setRoleActive(role, activating);
      if (mounted) {
        _message(activating ? l10n.roleRestored(name) : l10n.roleDeleted(name));
      }
    } catch (error) {
      if (mounted)
        _message(_superAdminErrorMessage(context, error), error: true);
    } finally {
      if (mounted) setState(() => _busy.remove(role.id));
    }
  }

  void _message(String value, {bool error = false}) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(value),
          backgroundColor: error ? context.themeError : null,
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return StreamBuilder<List<AppRole>>(
      stream: _roles,
      builder: (context, snapshot) {
        final loading = !snapshot.hasData && !snapshot.hasError;
        // On error keep the built-ins visible so the admin can see what
        // registration falls back to.
        final roles =
            snapshot.data ??
            (snapshot.hasError ? AppRole.defaults : const <AppRole>[]);
        final activeCount = roles.where((r) => r.isActive).length;
        final visible = switch (_filter) {
          _RoleFilter.all => roles,
          _RoleFilter.active => roles.where((r) => r.isActive).toList(),
          _RoleFilter.deleted => roles.where((r) => !r.isActive).toList(),
        };

        return ListView(
          padding: const EdgeInsets.only(bottom: AppSpacing.xl3),
          children: [
            SuperAdminSectionHeader(
              title: l10n.accountRoles,
              subtitle: l10n.manageTheRolesShownInCreate,
              action: FilledButton.icon(
                onPressed: loading || snapshot.hasError
                    ? null
                    : () => _add(roles),
                icon: const Icon(Icons.add_rounded),
                label: Text(l10n.addRole),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            _InfoNote(
              icon: Icons.sync_rounded,
              text: '${l10n.rolesLiveSync} ${l10n.roleIdsAreStoredWithUser}',
            ),
            if (snapshot.hasError) ...[
              const SizedBox(height: AppSpacing.md),
              MaterialBanner(
                backgroundColor: context.themeErrorSoft,
                leading: Icon(
                  Icons.cloud_off_rounded,
                  color: context.themeErrorText,
                ),
                content: Text(
                  l10n.couldNotLoadSavedRolesShowing(
                    _superAdminErrorMessage(context, snapshot.error!),
                  ),
                  style: AppTypography.body(color: context.themeErrorText),
                ),
                actions: [
                  TextButton(onPressed: _retry, child: Text(l10n.retry)),
                ],
              ),
            ],
            const SizedBox(height: AppSpacing.lg),
            if (loading)
              SuperAdminLoadingView(label: l10n.loadingAccountRoles)
            else ...[
              Wrap(
                alignment: WrapAlignment.spaceBetween,
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: AppSpacing.md,
                runSpacing: AppSpacing.sm,
                children: [
                  SegmentedButton<_RoleFilter>(
                    showSelectedIcon: false,
                    segments: [
                      ButtonSegment(
                        value: _RoleFilter.all,
                        label: Text(l10n.roleShowAll),
                      ),
                      ButtonSegment(
                        value: _RoleFilter.active,
                        label: Text(l10n.roleShowActive),
                      ),
                      ButtonSegment(
                        value: _RoleFilter.deleted,
                        label: Text(l10n.roleShowDeleted),
                      ),
                    ],
                    selected: {_filter},
                    onSelectionChanged: (s) =>
                        setState(() => _filter = s.first),
                  ),
                  Text(
                    l10n.rolesSummary(activeCount, roles.length - activeCount),
                    style: AppTypography.caption(
                      color: context.themeTextSecondary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              if (roles.isEmpty)
                EmptyState(icon: Icons.badge_outlined, title: l10n.noRolesFound)
              else if (visible.isEmpty)
                EmptyState(
                  icon: Icons.filter_alt_off_rounded,
                  title: l10n.noRolesInFilter,
                )
              else
                for (final role in visible)
                  _RoleCard(
                    role: role,
                    busy: _busy.contains(role.id),
                    onToggle: snapshot.hasError ? null : () => _toggle(role),
                    onEdit: snapshot.hasError ? null : () => _edit(role),
                  ),
            ],
          ],
        );
      },
    );
  }
}

class _InfoNote extends StatelessWidget {
  const _InfoNote({required this.icon, required this.text});
  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: context.themeSoftSurface,
        borderRadius: AppRadius.md12,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: context.themeTextSecondary),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              text,
              style: AppTypography.caption(color: context.themeTextSecondary),
            ),
          ),
        ],
      ),
    );
  }
}

class _RoleCard extends StatelessWidget {
  const _RoleCard({
    required this.role,
    required this.busy,
    required this.onToggle,
    required this.onEdit,
  });

  final AppRole role;
  final bool busy;
  final VoidCallback? onToggle;
  final VoidCallback? onEdit;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final name = roleDisplayName(context, role);
    final initial = name.characters.isEmpty
        ? '?'
        : name.characters.first.toUpperCase();

    final Widget action = busy
        ? const Padding(
            padding: EdgeInsets.all(14),
            child: SizedBox.square(
              dimension: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          )
        : PopupMenuButton<String>(
            tooltip: l10n.roleActions,
            icon: const Icon(Icons.more_vert_rounded),
            enabled: onEdit != null || onToggle != null,
            onSelected: (value) {
              if (value == 'edit') onEdit?.call();
              if (value == 'toggle') onToggle?.call();
            },
            itemBuilder: (_) => [
              PopupMenuItem(
                value: 'edit',
                enabled: onEdit != null,
                child: ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.edit_outlined),
                  title: Text(l10n.editLabel),
                ),
              ),
              // Carpenter is protected: it can be renamed but never deleted.
              if (!role.isProtected)
                PopupMenuItem(
                  value: 'toggle',
                  enabled: onToggle != null,
                  child: ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Icon(
                      role.isActive
                          ? Icons.delete_outline_rounded
                          : Icons.restore_rounded,
                      color: role.isActive ? context.themeError : null,
                    ),
                    title: Text(
                      role.isActive ? l10n.delete : l10n.restore,
                      style: TextStyle(
                        color: role.isActive ? context.themeError : null,
                      ),
                    ),
                  ),
                ),
            ],
          );

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Opacity(
        opacity: role.isActive ? 1 : 0.72,
        child: Card(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 8, 12),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: role.isActive
                        ? AppColors.primary
                        : context.themeSoftSurface,
                    borderRadius: AppRadius.md12,
                  ),
                  child: Text(
                    initial,
                    style: AppTypography.section(
                      color: role.isActive
                          ? AppColors.gold
                          : context.themeTextSecondary,
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        role.abbreviation.isEmpty
                            ? name
                            : '$name · ${role.abbreviation}',
                        style: AppTypography.input(
                          color: context.themeTextPrimary,
                        ).copyWith(fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 6),
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          _Tag(
                            label: PointsRate.label(role.rupeesPerPoint),
                            bg: context.themeGoldSoft,
                            fg: context.themeTextPrimary,
                          ),
                          _Tag(
                            label: role.isActive ? l10n.active : l10n.deleted,
                            bg: role.isActive
                                ? context.themeSuccessSoft
                                : context.themeErrorSoft,
                            fg: role.isActive
                                ? context.themeSuccessText
                                : context.themeErrorText,
                          ),
                          if (role.isProtected)
                            Tooltip(
                              message: l10n.roleProtectedTooltip,
                              child: Icon(
                                Icons.lock_outline_rounded,
                                size: 16,
                                color: context.themeTextSecondary,
                              ),
                            ),
                          _Tag(
                            label: role.isBuiltIn
                                ? l10n.roleBuiltInBadge
                                : l10n.roleCustomBadge,
                            bg: context.themeSoftSurface,
                            fg: context.themeTextSecondary,
                          ),
                          Text(
                            l10n.roleId(role.id),
                            style: AppTypography.caption(
                              color: context.themeTextSecondary,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                action,
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Tag extends StatelessWidget {
  const _Tag({required this.label, required this.bg, required this.fg});
  final String label;
  final Color bg;
  final Color fg;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(color: bg, borderRadius: AppRadius.sm8),
      child: Text(label, style: AppTypography.labelSmall(color: fg)),
    );
  }
}

class _AddRoleDialog extends StatefulWidget {
  const _AddRoleDialog({
    required this.service,
    required this.existingIds,
    this.existing,
  });

  final RoleService service;

  /// When set, the dialog edits this role (ID locked) instead of adding.
  final AppRole? existing;

  /// IDs already in the live list — lets the form flag duplicates instantly.
  final Set<String> existingIds;

  @override
  State<_AddRoleDialog> createState() => _AddRoleDialogState();
}

class _AddRoleDialogState extends State<_AddRoleDialog> {
  final _formKey = GlobalKey<FormState>();
  late final _name = TextEditingController(text: widget.existing?.name);
  late final _abbreviation = TextEditingController(
    text: widget.existing?.abbreviation,
  );
  late final _rate = TextEditingController(
    text:
        '${widget.existing?.rupeesPerPoint ?? PointsRate.defaultRupeesPerPoint}',
  );
  bool _saving = false;
  String? _serverError;

  bool get _editing => widget.existing != null;

  @override
  void dispose() {
    _name.dispose();
    _abbreviation.dispose();
    _rate.dispose();
    super.dispose();
  }

  String? _validateName(String? value) {
    final l10n = AppLocalizations.of(context)!;
    final name = (value ?? '').trim();
    if (name.length < RoleService.nameMinLength) {
      return l10n.enterAtLeast2Characters;
    }
    // Editing keeps the existing ID, so any script is fine for the name.
    if (_editing) {
      return name.length > RoleService.nameMaxLength
          ? l10n.roleErrInvalidName
          : null;
    }
    final id = widget.service.createRoleId(name);
    if (name.length > RoleService.nameMaxLength || id.length < 2) {
      return l10n.roleErrInvalidName;
    }
    if (id == 'admin' || id == 'super_admin') return l10n.roleErrReserved;
    if (AppRole.builtInIds.contains(id)) return l10n.roleErrBuiltIn;
    if (widget.existingIds.contains(id)) return l10n.roleErrDuplicate;
    return null;
  }

  Future<void> _save() async {
    setState(() => _serverError = null);
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      final rate = int.parse(_rate.text.trim());
      final role = _editing
          ? await widget.service.updateRole(
              widget.existing!,
              name: _name.text,
              abbreviation: _abbreviation.text,
              rupeesPerPoint: rate,
            )
          : await widget.service.createRole(
              name: _name.text,
              abbreviation: _abbreviation.text,
              rupeesPerPoint: rate,
            );
      if (mounted) Navigator.pop(context, role);
    } catch (error) {
      if (mounted)
        setState(() => _serverError = _superAdminErrorMessage(context, error));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final roleId = _editing
        ? widget.existing!.id
        : widget.service.createRoleId(_name.text);
    return AlertDialog(
      title: Text(_editing ? l10n.editRole : l10n.addAccountRole),
      content: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 440),
        child: Form(
          key: _formKey,
          autovalidateMode: AutovalidateMode.onUserInteraction,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextFormField(
                  controller: _name,
                  autofocus: true,
                  enabled: !_saving,
                  maxLength: RoleService.nameMaxLength,
                  textCapitalization: TextCapitalization.words,
                  textInputAction: TextInputAction.next,
                  onChanged: (_) => setState(() => _serverError = null),
                  decoration: InputDecoration(
                    labelText: l10n.roleName,
                    hintText: l10n.hintRoleName,
                  ),
                  validator: _validateName,
                ),
                const SizedBox(height: AppSpacing.sm),
                TextFormField(
                  controller: _abbreviation,
                  enabled: !_saving,
                  maxLength: RoleService.abbreviationMaxLength,
                  maxLengthEnforcement: MaxLengthEnforcement.enforced,
                  textInputAction: TextInputAction.done,
                  onFieldSubmitted: (_) => _saving ? null : _save(),
                  decoration: InputDecoration(
                    labelText: l10n.shortFormOptional,
                    hintText: l10n.exampleAr,
                  ),
                  validator: (value) =>
                      (value?.trim().length ?? 0) >
                          RoleService.abbreviationMaxLength
                      ? l10n.use10CharactersOrLess
                      : null,
                ),
                const SizedBox(height: AppSpacing.sm),
                // Rupees of purchases that earn one point for this role.
                TextFormField(
                  controller: _rate,
                  enabled: !_saving,
                  keyboardType: TextInputType.number,
                  textInputAction: TextInputAction.done,
                  onFieldSubmitted: (_) => _saving ? null : _save(),
                  decoration: InputDecoration(
                    labelText: l10n.rupeesPerPoint,
                    hintText: l10n.enterRupeesPerPoint,
                    helperText: l10n.rupeesPerPointHint,
                    prefixText: '₹ ',
                  ),
                  validator: (value) {
                    final n = int.tryParse((value ?? '').trim());
                    return n == null ||
                            n < PointsRate.minRupeesPerPoint ||
                            n > PointsRate.maxRupeesPerPoint
                        ? l10n.enterValidRate
                        : null;
                  },
                ),
                const SizedBox(height: AppSpacing.sm),
                Container(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  decoration: BoxDecoration(
                    color: context.themeSoftSurface,
                    borderRadius: AppRadius.md12,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.roleIdPreview(roleId.isEmpty ? '—' : roleId),
                        style: AppTypography.label(
                          color: context.themeTextPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _editing ? l10n.roleIdLocked : l10n.roleIdHelp,
                        style: AppTypography.caption(
                          color: context.themeTextSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                if (_serverError != null) ...[
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    _serverError!,
                    style: AppTypography.body(color: context.themeError),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _saving ? null : () => Navigator.pop(context),
          child: Text(l10n.cancel),
        ),
        FilledButton.icon(
          onPressed: _saving ? null : _save,
          icon: _saving
              ? const SizedBox.square(
                  dimension: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.check_rounded),
          label: Text(_saving ? l10n.saving : l10n.saveRole),
        ),
      ],
    );
  }
}
