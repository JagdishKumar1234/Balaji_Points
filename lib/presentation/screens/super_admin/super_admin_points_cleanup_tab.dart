import 'package:flutter/material.dart';
import 'package:balaji_points/presentation/screens/super_admin/super_admin_section_header.dart';
import 'package:balaji_points/l10n/app_localizations.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';

import 'package:balaji_points/core/design/app_colors.dart';
import 'package:balaji_points/core/design/app_radius.dart';
import 'package:balaji_points/core/design/app_spacing.dart';
import 'package:balaji_points/core/design/app_typography.dart';
import 'package:balaji_points/services/branch/branch_service.dart';
import 'package:balaji_points/services/branch/super_admin_service.dart';
import 'package:balaji_points/presentation/screens/super_admin/super_admin_loading_view.dart';

String _superAdminErrorMessage(BuildContext context, Object error) {
  if (error is FirebaseFunctionsException && error.message != null) {
    return error.message!;
  }
  if (error is FirebaseException && error.code == 'permission-denied') {
    return AppLocalizations.of(context)!.permissionDeniedSuperAdmin;
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
        _showMessage(_superAdminErrorMessage(context, error), isError: true);
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
            title: Text(AppLocalizations.of(context)!.resetBranchPoints),
            content: SizedBox(
              width: 460,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    AppLocalizations.of(
                      context,
                    )!.hasEligibleUsersPointsAndHistory(
                      '${preview.branchName}',
                      '${preview.eligibleUsers}',
                      '${preview.currentPoints}',
                      '${preview.embeddedHistoryEntries + preview.historyDocuments}',
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Text(
                    AppLocalizations.of(
                      context,
                    )!.thisPermanentlyClearsPointsAndPoints,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  TextField(
                    controller: confirmationController,
                    autofocus: true,
                    onChanged: (_) => setDialogState(() {}),
                    decoration: InputDecoration(
                      labelText: AppLocalizations.of(
                        context,
                      )!.typeToConfirm('${preview.branchId}'),
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
                child: Text(AppLocalizations.of(context)!.cancel),
              ),
              FilledButton.icon(
                onPressed: matches
                    ? () => Navigator.pop(
                        dialogContext,
                        confirmationController.text.trim(),
                      )
                    : null,
                icon: const Icon(Icons.delete_sweep_outlined),
                label: Text(
                  AppLocalizations.of(context)!.resetPointsAndHistory,
                ),
                style: FilledButton.styleFrom(
                  backgroundColor: context.themeError,
                  foregroundColor: context.themeOnError,
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
        AppLocalizations.of(context)!.resetUsersAndDeletedHistoryRecords(
          '${result.branchName}',
          '${result.usersReset}',
          '${result.historyDocumentsDeleted}',
        ),
      );
    } catch (error) {
      if (mounted) {
        _showMessage(_superAdminErrorMessage(context, error), isError: true);
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
          return SuperAdminLoadingView(
            label: AppLocalizations.of(context)!.loadingBranches,
          );
        }
        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.cloud_off_rounded),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  AppLocalizations.of(context)!.couldNotLoadBranchesForPoints,
                ),
                TextButton.icon(
                  onPressed: () => setState(() {}),
                  icon: const Icon(Icons.refresh_rounded),
                  label: Text(AppLocalizations.of(context)!.tryAgain),
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
          alignment: Alignment.topLeft,
          child: SingleChildScrollView(
            padding: const EdgeInsets.only(bottom: AppSpacing.xl3),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 780),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SuperAdminSectionHeader(
                    title: AppLocalizations.of(context)!.annualPointsReset,
                    subtitle: AppLocalizations.of(
                      context,
                    )!.afterPrizeDistributionStartAFresh,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Container(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    decoration: BoxDecoration(
                      color: context.themeErrorSoft,
                      borderRadius: AppRadius.md12,
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          Icons.warning_amber_rounded,
                          color: context.themeErrorText,
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Expanded(
                          child: Text(
                            AppLocalizations.of(
                              context,
                            )!.onlyPointsTiersAndPointsHistory,
                            style: AppTypography.body(
                              color: context.themeErrorText,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  DropdownButtonFormField<String>(
                    initialValue: hasSelectedBranch ? _selectedBranchId : null,
                    isExpanded: true,
                    hint: Text(AppLocalizations.of(context)!.selectBranch),
                    decoration: InputDecoration(
                      labelText: AppLocalizations.of(context)!.branchToReset,
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
                        _loadingPreview
                            ? AppLocalizations.of(context)!.checkingBranch
                            : AppLocalizations.of(context)!.previewReset,
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
                        AppLocalizations.of(
                          context,
                        )!.createABranchBeforeResettingPoints,
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
              AppLocalizations.of(
                context,
              )!.cleanupPreview('${preview.branchName}'),
              style: AppTypography.h5(color: context.themePrimary),
            ),
            const SizedBox(height: AppSpacing.md),
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: [
                _PreviewMetric(
                  label: AppLocalizations.of(context)!.eligibleUsers,
                  value: preview.eligibleUsers.toString(),
                  icon: Icons.people_alt_outlined,
                ),
                _PreviewMetric(
                  label: AppLocalizations.of(context)!.currentPoints,
                  value: preview.currentPoints.toString(),
                  icon: Icons.stars_outlined,
                ),
                _PreviewMetric(
                  label: AppLocalizations.of(context)!.historyItems,
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
                          color: AppColors.primary,
                          strokeWidth: 2,
                        ),
                      )
                    : const Icon(Icons.cleaning_services_rounded),
                label: Text(
                  _clearing
                      ? AppLocalizations.of(context)!.resettingBranchPoints
                      : AppLocalizations.of(context)!.resetPointsAndHistory,
                ),
                style: FilledButton.styleFrom(
                  backgroundColor: context.themeError,
                  foregroundColor: context.themeOnError,
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
        color: context.themeSoftSurface,
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
