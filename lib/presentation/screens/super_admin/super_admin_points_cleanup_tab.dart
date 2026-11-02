import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';

import 'package:balaji_points/core/design/app_colors.dart';
import 'package:balaji_points/core/design/app_radius.dart';
import 'package:balaji_points/core/design/app_spacing.dart';
import 'package:balaji_points/core/design/app_typography.dart';
import 'package:balaji_points/services/branch/branch_service.dart';
import 'package:balaji_points/services/branch/super_admin_service.dart';
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

// ── Annual branch points reset ────────────────────────────────────────────────

class SuperAdminPointsCleanupTab extends StatefulWidget {
  const SuperAdminPointsCleanupTab({super.key});

  @override
  State<SuperAdminPointsCleanupTab> createState() =>
      SuperAdminPointsCleanupTabState();
}

class SuperAdminPointsCleanupTabState
    extends State<SuperAdminPointsCleanupTab> {
  String? _selectedBranchId;
  BranchPointsResetPreview? _preview;
  bool _loadingPreview = false;
  bool _clearing = false;

  Future<void> _loadPreview() async {
    final branchId = _selectedBranchId;
    if (branchId == null) return;
    setState(() {
      _loadingPreview = true;
      _preview = null;
    });
    try {
      final result = await SuperAdminService().previewBranchPointsReset(
        branchId,
      );
      if (mounted) setState(() => _preview = result);
    } catch (error) {
      if (mounted) {
        _showMessage(_superAdminErrorMessage(error), isError: true);
      }
    } finally {
      if (mounted) setState(() => _loadingPreview = false);
    }
  }

  Future<void> _resetPoints() async {
    final preview = _preview;
    if (preview == null || _clearing) return;
    final confirmationController = TextEditingController();
    final confirmedBranchId = await showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) {
          final matches =
              confirmationController.text.trim().toLowerCase() ==
              preview.branchId.toLowerCase();
          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: AppRadius.forCard),
            icon: Icon(
              Icons.warning_amber_rounded,
              color: context.themeError,
              size: 32,
            ),
            title: const Text('Reset branch points?'),
            content: SizedBox(
              width: 460,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${preview.branchName} has ${preview.eligibleUsers} '
                    'eligible users, ${preview.currentPoints} points and '
                    '${preview.embeddedHistoryEntries + preview.historyDocuments} '
                    'history items.',
                  ),
                  const SizedBox(height: AppSpacing.md),
                  const Text(
                    'This permanently clears points and points history for '
                    'carpenters, architects and interior designers in this '
                    'branch. User accounts, branch admins and bills are kept.',
                  ),
                  const SizedBox(height: AppSpacing.md),
                  TextField(
                    controller: confirmationController,
                    autofocus: true,
                    onChanged: (_) => setDialogState(() {}),
                    decoration: InputDecoration(
                      labelText: 'Type ${preview.branchId} to confirm',
                      border: OutlineInputBorder(
                        borderRadius: AppRadius.forInput,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext),
                child: const Text('Cancel'),
              ),
              FilledButton.icon(
                onPressed: matches
                    ? () => Navigator.pop(
                        dialogContext,
                        confirmationController.text.trim(),
                      )
                    : null,
                icon: const Icon(Icons.delete_sweep_outlined),
                label: const Text('Reset points and history'),
                style: FilledButton.styleFrom(
                  backgroundColor: context.themeError,
                  foregroundColor: AppColors.white,
                ),
              ),
            ],
          );
        },
      ),
    );
    confirmationController.dispose();
    if (confirmedBranchId == null || !mounted) return;

    setState(() => _clearing = true);
    try {
      final result = await SuperAdminService().clearBranchPoints(
        branchId: preview.branchId,
        confirmBranchId: confirmedBranchId,
        expectedUsers: preview.eligibleUsers,
      );
      if (!mounted) return;
      setState(() => _preview = null);
      _showMessage(
        '${result.branchName}: reset ${result.usersReset} users and deleted '
        '${result.historyDocumentsDeleted} history records. '
        'Accounts and bills were kept.',
      );
    } catch (error) {
      if (mounted) {
        _showMessage(_superAdminErrorMessage(error), isError: true);
      }
    } finally {
      if (mounted) setState(() => _clearing = false);
    }
  }

  void _showMessage(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: isError ? context.themeError : AppColors.success,
          behavior: SnackBarBehavior.floating,
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: BranchService().watchAllBranches(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SuperAdminLoadingView(label: 'Loading branches…');
        }
        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.cloud_off_rounded),
                const SizedBox(height: AppSpacing.sm),
                const Text('Could not load branches for points cleanup.'),
                TextButton.icon(
                  onPressed: () => setState(() {}),
                  icon: const Icon(Icons.refresh_rounded),
                  label: const Text('Try again'),
                ),
              ],
            ),
          );
        }
        final branches = snapshot.data?.docs ?? [];
        final hasSelectedBranch = branches.any(
          (branch) => branch.id == _selectedBranchId,
        );
        return Align(
          alignment: Alignment.topCenter,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 780),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Annual points reset',
                    style: AppTypography.h4(color: context.themePrimary),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'After prize distribution, start a fresh points season for '
                    'one branch.',
                    style: AppTypography.bodyMedium(
                      color: context.themeTextSecondary,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Container(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    decoration: BoxDecoration(
                      color: context.themeError.withValues(alpha: 0.08),
                      border: Border.all(
                        color: context.themeError.withValues(alpha: 0.24),
                      ),
                      borderRadius: AppRadius.forCard,
                    ),
                    child: const Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.info_outline_rounded),
                        SizedBox(width: AppSpacing.sm),
                        Expanded(
                          child: Text(
                            'Only points, tiers and points history for '
                            'carpenters, architects and interior designers '
                            'are cleared. User accounts, login access, branch '
                            'admins and bills stay unchanged.',
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  DropdownButtonFormField<String>(
                    initialValue: hasSelectedBranch ? _selectedBranchId : null,
                    isExpanded: true,
                    decoration: InputDecoration(
                      labelText: 'Branch to reset',
                      border: OutlineInputBorder(
                        borderRadius: AppRadius.forInput,
                      ),
                    ),
                    items: branches
                        .map(
                          (branch) => DropdownMenuItem<String>(
                            value: branch.id,
                            child: Text(
                              branch.data()['name'] as String? ?? branch.id,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        )
                        .toList(),
                    onChanged: _clearing
                        ? null
                        : (value) => setState(() {
                            _selectedBranchId = value;
                            _preview = null;
                          }),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  SizedBox(
                    height: 50,
                    child: OutlinedButton.icon(
                      onPressed:
                          !hasSelectedBranch || _loadingPreview || _clearing
                          ? null
                          : _loadPreview,
                      icon: _loadingPreview
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.preview_outlined),
                      label: Text(
                        _loadingPreview ? 'Checking branch…' : 'Preview reset',
                      ),
                    ),
                  ),
                  if (_preview != null) ...[
                    const SizedBox(height: AppSpacing.lg),
                    _buildPreviewCard(context, _preview!),
                  ],
                  if (branches.isEmpty)
                    Padding(
                      padding: const EdgeInsets.all(AppSpacing.xl),
                      child: Text(
                        'Create a branch before resetting points.',
                        textAlign: TextAlign.center,
                        style: AppTypography.bodyMedium(
                          color: context.themeTextSecondary,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildPreviewCard(
    BuildContext context,
    BranchPointsResetPreview preview,
  ) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: AppRadius.forCard,
        side: BorderSide(color: context.themeBorder),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Cleanup preview · ${preview.branchName}',
              style: AppTypography.h5(color: context.themePrimary),
            ),
            const SizedBox(height: AppSpacing.md),
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: [
                _PreviewMetric(
                  label: 'Eligible users',
                  value: preview.eligibleUsers.toString(),
                  icon: Icons.people_alt_outlined,
                ),
                _PreviewMetric(
                  label: 'Current points',
                  value: preview.currentPoints.toString(),
                  icon: Icons.stars_outlined,
                ),
                _PreviewMetric(
                  label: 'History items',
                  value:
                      (preview.embeddedHistoryEntries +
                              preview.historyDocuments)
                          .toString(),
                  icon: Icons.history_rounded,
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: FilledButton.icon(
                onPressed: preview.eligibleUsers == 0 || _clearing
                    ? null
                    : _resetPoints,
                icon: _clearing
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          color: AppColors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : const Icon(Icons.cleaning_services_rounded),
                label: Text(
                  _clearing
                      ? 'Resetting branch points…'
                      : 'Reset points and history',
                ),
                style: FilledButton.styleFrom(
                  backgroundColor: context.themeError,
                  foregroundColor: AppColors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: AppRadius.forButton,
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

class _PreviewMetric extends StatelessWidget {
  const _PreviewMetric({
    required this.label,
    required this.value,
    required this.icon,
  });

  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minWidth: 145),
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: context.themePrimary.withValues(alpha: 0.06),
        borderRadius: AppRadius.md12,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: context.themePrimary, size: 20),
          const SizedBox(width: AppSpacing.sm),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: AppTypography.labelLarge(color: context.themePrimary),
              ),
              Text(
                label,
                style: AppTypography.caption(color: context.themeTextSecondary),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
