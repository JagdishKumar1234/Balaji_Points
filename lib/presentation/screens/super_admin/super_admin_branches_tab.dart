import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:balaji_points/core/design/app_colors.dart';
import 'package:balaji_points/core/design/app_radius.dart';
import 'package:balaji_points/core/design/app_spacing.dart';
import 'package:balaji_points/core/design/app_typography.dart';
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
          return const SuperAdminLoadingView(label: 'Loading branches…');
        }
        if (snap.hasError) {
          return _BranchLoadError(onRetry: _retry);
        }
        final docs = snap.data?.docs ?? [];
        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.md,
                AppSpacing.md,
                AppSpacing.md,
                AppSpacing.sm,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Branch management',
                          style: AppTypography.h4(color: context.themePrimary),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${docs.length} branches · manage branch access and status',
                          style: AppTypography.bodySmall(
                            color: context.themeTextSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  FilledButton.icon(
                    onPressed: () => _showCreateBranchDialog(context),
                    icon: const Icon(Icons.add_business_rounded),
                    label: const Text('Add branch'),
                    style: FilledButton.styleFrom(
                      backgroundColor: context.themePrimary,
                      foregroundColor: AppColors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.md,
                        vertical: 14,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: AppRadius.forButton,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: docs.isEmpty
                  ? Center(
                      child: Text(
                        'No branches yet.',
                        style: AppTypography.bodyMedium(
                          color: context.themeTextSecondary,
                        ),
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(AppSpacing.md),
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
              const Text('Branches could not be loaded.'),
              const SizedBox(height: AppSpacing.sm),
              FilledButton.tonalIcon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Try again'),
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
                    ? 'Diwali celebration enabled. Add Bill is hidden for this branch.'
                    : 'Diwali celebration disabled. Add Bill is available for this branch.'
              : 'Unable to update the branch celebration setting.',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final branchId = widget.branchId;
    final branchCode = widget.branchCode;
    final name = widget.name;
    final shortName = widget.shortName;
    final address = widget.address;
    final phone = widget.phone;
    final isActive = widget.isActive;
    final celebrationEnabled = widget.celebrationEnabled;
    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      shape: RoundedRectangleBorder(borderRadius: AppRadius.forCard),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: context.themePrimary.withValues(alpha: 0.1),
                borderRadius: AppRadius.md12,
              ),
              child: Icon(Icons.store, color: context.themePrimary),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          shortName.isNotEmpty ? shortName : name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTypography.labelLarge(
                            color: context.themePrimary,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: isActive
                              ? AppColors.success.withValues(alpha: 0.12)
                              : context.themeError.withValues(alpha: 0.12),
                          borderRadius: AppRadius.pill,
                        ),
                        child: Text(
                          isActive ? 'Active' : 'Inactive',
                          style: AppTypography.labelSmall(
                            color: isActive
                                ? AppColors.success
                                : context.themeError,
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (shortName.isNotEmpty && shortName != name) ...[
                    const SizedBox(height: 2),
                    Text(
                      name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.bodySmall(
                        color: context.themeTextSecondary,
                      ),
                    ),
                  ],
                  if (address.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      address,
                      style: AppTypography.bodySmall(
                        color: context.themeTextSecondary,
                      ),
                    ),
                  ],
                  if (phone.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      phone,
                      style: AppTypography.bodySmall(
                        color: context.themeTextSecondary,
                      ),
                    ),
                  ],
                  const SizedBox(height: 4),
                  Text(
                    'Code: $branchCode  ·  ID: $branchId',
                    style: AppTypography.caption(color: context.themeTextMuted),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  SwitchListTile.adaptive(
                    contentPadding: EdgeInsets.zero,
                    dense: true,
                    title: const Text('Diwali celebration on Home'),
                    subtitle: Text(
                      celebrationEnabled
                          ? 'Shows the branch prize list and hides Add Bill.'
                          : 'Off: no popup; Add Bill remains available.',
                      style: AppTypography.caption(
                        color: context.themeTextSecondary,
                      ),
                    ),
                    value: celebrationEnabled,
                    onChanged: _updatingCelebration ? null : _setCelebration,
                    secondary: _updatingCelebration
                        ? const SizedBox.square(
                            dimension: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.celebration_outlined),
                  ),
                ],
              ),
            ),
            TextButton.icon(
              onPressed: () async {
                final updated = await BranchService().updateBranch(
                  branchId,
                  isActive: !isActive,
                );
                if (!context.mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      updated
                          ? (isActive
                                ? 'Branch deactivated.'
                                : 'Branch activated.')
                          : 'Unable to update the branch.',
                    ),
                  ),
                );
              },
              icon: Icon(
                isActive
                    ? Icons.pause_circle_outline
                    : Icons.play_circle_outline,
                size: 18,
              ),
              label: Text(isActive ? 'Deactivate' : 'Activate'),
            ),
          ],
        ),
      ),
    );
  }
}

class _CreateBranchDialog extends StatefulWidget {
  const _CreateBranchDialog();

  @override
  State<_CreateBranchDialog> createState() => _CreateBranchDialogState();
}

class _CreateBranchDialogState extends State<_CreateBranchDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _shortCtrl = TextEditingController();
  final _codeCtrl = TextEditingController();
  final _addrCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  bool _saving = false;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _shortCtrl.dispose();
    _codeCtrl.dispose();
    _addrCtrl.dispose();
    _phoneCtrl.dispose();
    super.dispose();
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
          id != null ? 'Branch created ($id)' : 'Failed to create branch',
        ),
        backgroundColor: id != null ? AppColors.success : context.themeError,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: AppRadius.forCard),
      title: Text(
        'New Branch',
        style: AppTypography.h5(color: context.themePrimary),
      ),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _field(
                _nameCtrl,
                'Branch Full Name *',
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Required' : null,
              ),
              const SizedBox(height: AppSpacing.sm),
              _field(
                _shortCtrl,
                'Short Name *',
                validator: (v) => (v == null || v.trim().isEmpty)
                    ? 'Enter a short branch name'
                    : null,
              ),
              const SizedBox(height: AppSpacing.sm),
              _field(
                _codeCtrl,
                'Branch Code *',
                validator: (value) =>
                    RegExp(
                      r'^[A-Za-z0-9-]{2,16}$',
                    ).hasMatch(value?.trim() ?? '')
                    ? null
                    : 'Use 2–16 letters, numbers or hyphens',
              ),
              const SizedBox(height: AppSpacing.sm),
              _field(_addrCtrl, 'Address'),
              const SizedBox(height: AppSpacing.sm),
              _field(_phoneCtrl, 'Phone', keyboardType: TextInputType.phone),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _saving ? null : () => Navigator.pop(context),
          child: Text(
            'Cancel',
            style: AppTypography.labelLarge(color: context.themeTextSecondary),
          ),
        ),
        ElevatedButton(
          onPressed: _saving ? null : _save,
          style: ElevatedButton.styleFrom(
            backgroundColor: context.themePrimary,
            shape: RoundedRectangleBorder(borderRadius: AppRadius.forButton),
          ),
          child: _saving
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    color: AppColors.white,
                    strokeWidth: 2,
                  ),
                )
              : Text(
                  'Create',
                  style: AppTypography.labelLarge(color: AppColors.white),
                ),
        ),
      ],
    );
  }

  Widget _field(
    TextEditingController ctrl,
    String label, {
    String? Function(String?)? validator,
    TextInputType? keyboardType,
  }) {
    return TextFormField(
      controller: ctrl,
      keyboardType: keyboardType,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: AppTypography.bodySmall(color: context.themeTextSecondary),
        border: OutlineInputBorder(borderRadius: AppRadius.forInput),
        isDense: true,
      ),
    );
  }
}
