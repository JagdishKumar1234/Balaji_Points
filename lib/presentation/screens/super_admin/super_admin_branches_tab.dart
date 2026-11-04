import 'package:flutter/material.dart';
import 'package:balaji_points/presentation/screens/super_admin/super_admin_branch_card.dart';
import 'package:balaji_points/presentation/widgets/shared/empty_state.dart';
import 'package:balaji_points/presentation/screens/super_admin/super_admin_section_header.dart';
import 'package:balaji_points/l10n/app_localizations.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:balaji_points/core/design/app_colors.dart';
import 'package:balaji_points/core/design/app_spacing.dart';
import 'package:balaji_points/services/branch/branch_service.dart';
import 'package:balaji_points/services/auth/session_service.dart';
import 'package:balaji_points/presentation/screens/super_admin/super_admin_loading_view.dart';

// ── Branches tab ──────────────────────────────────────────────────────────────

class SuperAdminBranchesTab extends StatefulWidget {
  const SuperAdminBranchesTab({super.key});

  @override
  State<SuperAdminBranchesTab> createState() => _SuperAdminBranchesTabState();
}

class _SuperAdminBranchesTabState extends State<SuperAdminBranchesTab> {
  late Stream<QuerySnapshot<Map<String, dynamic>>> _branchStream;

  @override
  void initState() {
    super.initState();
    _branchStream = BranchService().watchAllBranches();
  }

  void _retry() => setState(() {
    _branchStream = BranchService().watchAllBranches();
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: _branchStream,
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return SuperAdminLoadingView(
            label: AppLocalizations.of(context)!.loadingBranches,
          );
        }
        if (snap.hasError) {
          return _BranchLoadError(onRetry: _retry);
        }
        final docs = snap.data?.docs ?? [];
        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.md),
              child: SuperAdminSectionHeader(
                title: AppLocalizations.of(context)!.branchManagement,
                subtitle: AppLocalizations.of(
                  context,
                )!.branchesManageBranchAccessAndStatus('${docs.length}'),
                action: FilledButton.icon(
                  onPressed: () => _showCreateBranchDialog(context),
                  icon: const Icon(Icons.add_business_rounded),
                  label: Text(AppLocalizations.of(context)!.addBranch),
                ),
              ),
            ),
            Expanded(
              child: docs.isEmpty
                  ? Padding(
                      padding: const EdgeInsets.all(AppSpacing.md),
                      child: EmptyState(
                        icon: Icons.store_outlined,
                        title: AppLocalizations.of(context)!.noBranchesYet,
                        actionLabel: AppLocalizations.of(context)!.addBranch,
                        onAction: () => _showCreateBranchDialog(context),
                      ),
                    )
                  : BranchCardGrid(
                      itemCount: docs.length,
                      itemBuilder: (_, i) {
                        final d = docs[i];
                        final data = d.data();
                        final isActive = data['isActive'] as bool? ?? true;
                        return _BranchCard(
                          key: ValueKey(d.id),
                          branchId: d.id,
                          branchCode: data['branchCode'] as String? ?? d.id,
                          name: data['name'] as String? ?? d.id,
                          shortName: data['shortName'] as String? ?? '',
                          address: data['address'] as String? ?? '',
                          phone: data['phone'] as String? ?? '',
                          isActive: isActive,
                          celebrationEnabled:
                              data['diwaliCelebrationEnabled'] as bool? ??
                              d.id == kDefaultBranchId,
                        );
                      },
                    ),
            ),
          ],
        );
      },
    );
  }

  void _showCreateBranchDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const _CreateBranchDialog(),
    );
  }
}

class _BranchLoadError extends StatelessWidget {
  const _BranchLoadError({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Center(
      child: Card.filled(
        margin: const EdgeInsets.all(AppSpacing.lg),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.cloud_off_rounded, color: colors.error, size: 32),
              const SizedBox(height: AppSpacing.sm),
              Text(AppLocalizations.of(context)!.branchesCouldNotBeLoaded),
              const SizedBox(height: AppSpacing.sm),
              FilledButton.tonalIcon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh_rounded),
                label: Text(AppLocalizations.of(context)!.tryAgain),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BranchCard extends StatefulWidget {
  final String branchId, branchCode, name, shortName, address, phone;
  final bool isActive;
  final bool celebrationEnabled;
  const _BranchCard({
    super.key,
    required this.branchId,
    required this.branchCode,
    required this.name,
    required this.shortName,
    required this.address,
    required this.phone,
    required this.isActive,
    required this.celebrationEnabled,
  });

  @override
  State<_BranchCard> createState() => _BranchCardState();
}

class _BranchCardState extends State<_BranchCard> {
  bool _updatingCelebration = false;

  Future<void> _setCelebration(bool enabled) async {
    setState(() => _updatingCelebration = true);
    final updated = await BranchService().updateBranch(
      widget.branchId,
      diwaliCelebrationEnabled: enabled,
    );
    if (!mounted) return;
    setState(() => _updatingCelebration = false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          updated
              ? enabled
                    ? AppLocalizations.of(
                        context,
                      )!.diwaliCelebrationEnabledAddBillIs
                    : AppLocalizations.of(
                        context,
                      )!.diwaliCelebrationDisabledAddBillIs
              : AppLocalizations.of(
                  context,
                )!.unableToUpdateTheBranchCelebration,
        ),
      ),
    );
  }

  Future<void> _toggleActive() async {
    final updated = await BranchService().updateBranch(
      widget.branchId,
      isActive: !widget.isActive,
    );
    if (!mounted) return;
    final l10n = AppLocalizations.of(context)!;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          updated
              ? (widget.isActive
                    ? l10n.branchDeactivated
                    : l10n.branchActivated)
              : l10n.unableToUpdateTheBranch,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SuperAdminBranchCard(
      branchId: widget.branchId,
      branchCode: widget.branchCode,
      name: widget.name,
      shortName: widget.shortName,
      address: widget.address,
      phone: widget.phone,
      isActive: widget.isActive,
      celebrationEnabled: widget.celebrationEnabled,
      updatingCelebration: _updatingCelebration,
      onCelebrationChanged: _setCelebration,
      onToggleActive: _toggleActive,
      onEdit: () => showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => _CreateBranchDialog(
          existing: BranchFormData(
            id: widget.branchId,
            name: widget.name,
            shortName: widget.shortName,
            branchCode: widget.branchCode,
            address: widget.address,
            phone: widget.phone,
          ),
        ),
      ),
    );
  }
}

/// Values of a branch being edited.
class BranchFormData {
  const BranchFormData({
    required this.id,
    required this.name,
    required this.shortName,
    required this.branchCode,
    required this.address,
    required this.phone,
  });
  final String id, name, shortName, branchCode, address, phone;
}

/// Add or edit a branch. With [existing] it edits (code locked).
class _CreateBranchDialog extends StatefulWidget {
  const _CreateBranchDialog({this.existing});
  final BranchFormData? existing;

  @override
  State<_CreateBranchDialog> createState() => _CreateBranchDialogState();
}

class _CreateBranchDialogState extends State<_CreateBranchDialog> {
  final _formKey = GlobalKey<FormState>();
  late final _nameCtrl = TextEditingController(text: widget.existing?.name);
  late final _shortCtrl = TextEditingController(text: widget.existing?.shortName);
  late final _codeCtrl = TextEditingController(text: widget.existing?.branchCode);
  late final _addrCtrl = TextEditingController(text: widget.existing?.address);
  late final _phoneCtrl = TextEditingController(text: widget.existing?.phone);
  bool _saving = false;

  bool get _editing => widget.existing != null;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _shortCtrl.dispose();
    _codeCtrl.dispose();
    _addrCtrl.dispose();
    _phoneCtrl.dispose();
    super.dispose();
  }

  Future<void> _saveEdit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    final ok = await BranchService().updateBranch(
      widget.existing!.id,
      name: _nameCtrl.text.trim(),
      shortName: _shortCtrl.text.trim(),
      address: _addrCtrl.text.trim(),
      phone: _phoneCtrl.text.trim(),
    );
    if (!mounted) return;
    setState(() => _saving = false);
    final l10n = AppLocalizations.of(context)!;
    if (ok) Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(ok ? l10n.branchUpdated : l10n.unableToUpdateTheBranch),
        backgroundColor: ok ? null : context.themeError,
      ),
    );
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    final creatorId = await SessionService().getUserId() ?? 'super_admin';
    final id = await BranchService().createBranch(
      name: _nameCtrl.text.trim(),
      shortName: _shortCtrl.text.trim(),
      branchCode: _codeCtrl.text.trim().toUpperCase(),
      address: _addrCtrl.text.trim(),
      phone: _phoneCtrl.text.trim(),
      createdBy: creatorId,
    );
    if (!mounted) return;
    setState(() => _saving = false);
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          id != null
              ? AppLocalizations.of(context)!.branchCreated('$id')
              : AppLocalizations.of(context)!.failedToCreateBranch,
        ),
        backgroundColor: id != null ? AppColors.success : context.themeError,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(
        _editing
            ? AppLocalizations.of(context)!.editBranch
            : AppLocalizations.of(context)!.newBranch,
      ),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _field(
                _nameCtrl,
                AppLocalizations.of(context)!.branchFullName, hint: AppLocalizations.of(context)!.hintBranchFullName,
                validator: (v) => (v == null || v.trim().isEmpty)
                    ? AppLocalizations.of(context)!.requiredLabel
                    : null,
              ),
              const SizedBox(height: AppSpacing.sm),
              _field(
                _shortCtrl,
                AppLocalizations.of(context)!.shortName, hint: AppLocalizations.of(context)!.hintShortName,
                validator: (v) => (v == null || v.trim().isEmpty)
                    ? AppLocalizations.of(context)!.enterAShortBranchName
                    : null,
              ),
              const SizedBox(height: AppSpacing.sm),
              _field(
                _codeCtrl,
                AppLocalizations.of(context)!.branchCode, hint: AppLocalizations.of(context)!.hintBranchCode,
                enabled: !_editing,
                helperText: _editing
                    ? AppLocalizations.of(context)!.branchCodeLocked
                    : null,
                validator: (value) =>
                    RegExp(
                      r'^[A-Za-z0-9-]{2,16}$',
                    ).hasMatch(value?.trim() ?? '')
                    ? null
                    : AppLocalizations.of(context)!.use216LettersNumbersOr,
              ),
              const SizedBox(height: AppSpacing.sm),
              _field(_addrCtrl, AppLocalizations.of(context)!.address, hint: AppLocalizations.of(context)!.hintAddress),
              const SizedBox(height: AppSpacing.sm),
              _field(
                _phoneCtrl,
                AppLocalizations.of(context)!.phone, hint: AppLocalizations.of(context)!.hintPhone,
                keyboardType: TextInputType.phone,
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _saving ? null : () => Navigator.pop(context),
          child: Text(AppLocalizations.of(context)!.cancel),
        ),
        ElevatedButton(
          onPressed: _saving ? null : (_editing ? _saveEdit : _save),
          child: _saving
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    color: AppColors.primary,
                    strokeWidth: 2,
                  ),
                )
              : Text(
                  _editing
                      ? AppLocalizations.of(context)!.saveChanges
                      : AppLocalizations.of(context)!.create,
                ),
        ),
      ],
    );
  }

  Widget _field(
    TextEditingController ctrl,
    String label, {
    String? hint,
    String? Function(String?)? validator,
    TextInputType? keyboardType,
    bool enabled = true,
    String? helperText,
  }) {
    return TextFormField(
      controller: ctrl,
      keyboardType: keyboardType,
      validator: validator,
      enabled: enabled,
      decoration: InputDecoration(
        labelText: label, hintText: hint,
        helperText: helperText,
        helperMaxLines: 2,
      ),
    );
  }
}
