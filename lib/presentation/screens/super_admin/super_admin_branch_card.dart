import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:balaji_points/core/design/app_colors.dart';
import 'package:balaji_points/core/design/app_radius.dart';
import 'package:balaji_points/core/design/app_spacing.dart';
import 'package:balaji_points/core/design/app_typography.dart';
import 'package:balaji_points/l10n/app_localizations.dart';

/// One branch in Super Admin → Branches.
///
/// Layout keeps the card short on phones: the details get the full width
/// (actions live in a ⋮ menu, not a button column on the right), every text
/// line is capped, and the Diwali toggle is a single compact row.
class SuperAdminBranchCard extends StatelessWidget {
  const SuperAdminBranchCard({
    super.key,
    required this.branchId,
    required this.branchCode,
    required this.name,
    required this.shortName,
    required this.address,
    required this.phone,
    required this.isActive,
    required this.celebrationEnabled,
    required this.updatingCelebration,
    required this.onCelebrationChanged,
    required this.onToggleActive,
    this.onEdit,
  });

  final String branchId, branchCode, name, shortName, address, phone;
  final bool isActive;
  final bool celebrationEnabled;
  final bool updatingCelebration;
  final ValueChanged<bool> onCelebrationChanged;

  /// Called after the user confirmed (de)activation.
  final VoidCallback onToggleActive;

  /// Opens the edit form.
  final VoidCallback? onEdit;

  String get _title => shortName.isNotEmpty ? shortName : name;

  Future<void> _confirmToggle(BuildContext context) async {
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        icon: Icon(
          isActive
              ? Icons.pause_circle_outline_rounded
              : Icons.play_circle_outline_rounded,
          color: isActive ? dialogContext.themeError : null,
        ),
        title: Text(
          isActive
              ? l10n.deactivateBranchTitle(_title)
              : l10n.activateBranchTitle(_title),
        ),
        content: Text(
          isActive ? l10n.deactivateBranchBody : l10n.activateBranchBody,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(l10n.cancel),
          ),
          isActive
              ? FilledButton(
                  onPressed: () => Navigator.pop(dialogContext, true),
                  style: FilledButton.styleFrom(
                    backgroundColor: dialogContext.themeError,
                    foregroundColor: dialogContext.themeOnError,
                  ),
                  child: Text(l10n.deactivate),
                )
              : FilledButton(
                  onPressed: () => Navigator.pop(dialogContext, true),
                  child: Text(l10n.activate),
                ),
        ],
      ),
    );
    if (confirmed == true) onToggleActive();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final secondary = context.themeTextSecondary;

    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 4, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── Header: icon · name · status · menu ─────────────────────────
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: isActive
                        ? AppColors.primary
                        : context.themeSoftSurface,
                    borderRadius: AppRadius.md12,
                  ),
                  child: Icon(
                    Icons.store_rounded,
                    size: 22,
                    color: isActive ? AppColors.gold : context.themeTextMuted,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.section(
                          color: context.themeTextPrimary,
                        ),
                      ),
                      if (shortName.isNotEmpty && shortName != name)
                        Text(
                          name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTypography.caption(color: secondary),
                        ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: _StatusTag(isActive: isActive),
                ),
                PopupMenuButton<String>(
                  tooltip: l10n.branchActions,
                  icon: const Icon(Icons.more_vert_rounded),
                  onSelected: (value) async {
                    if (value == 'edit') {
                      onEdit?.call();
                    } else if (value == 'toggle') {
                      await _confirmToggle(context);
                    } else if (value == 'copy') {
                      await Clipboard.setData(ClipboardData(text: branchId));
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(l10n.branchIdCopied)),
                        );
                      }
                    }
                  },
                  itemBuilder: (_) => [
                    if (onEdit != null)
                      PopupMenuItem(
                        value: 'edit',
                        child: ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: const Icon(Icons.edit_outlined),
                          title: Text(l10n.editLabel),
                        ),
                      ),
                    PopupMenuItem(
                      value: 'toggle',
                      child: ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: Icon(
                          isActive
                              ? Icons.pause_circle_outline_rounded
                              : Icons.play_circle_outline_rounded,
                          color: isActive ? context.themeError : null,
                        ),
                        title: Text(
                          isActive ? l10n.deactivate : l10n.activate,
                          style: TextStyle(
                            color: isActive ? context.themeError : null,
                          ),
                        ),
                      ),
                    ),
                    PopupMenuItem(
                      value: 'copy',
                      child: ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: const Icon(Icons.copy_rounded),
                        title: Text(l10n.copyBranchId),
                      ),
                    ),
                  ],
                ),
              ],
            ),

            // ── Details (each capped to keep the card short) ────────────────
            if (address.isNotEmpty || phone.isNotEmpty) ...[
              const SizedBox(height: 10),
              Padding(
                padding: const EdgeInsets.only(right: 12),
                child: Wrap(
                  spacing: 16,
                  runSpacing: 6,
                  children: [
                    if (address.isNotEmpty)
                      _Meta(
                        icon: Icons.location_on_outlined,
                        text: address,
                        maxLines: 2,
                      ),
                    if (phone.isNotEmpty)
                      _Meta(icon: Icons.call_outlined, text: phone),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 6),
            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: Text(
                l10n.codeId(branchCode, branchId),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTypography.caption(color: context.themeTextMuted),
              ),
            ),

            // ── Diwali toggle: one compact row ──────────────────────────────
            const SizedBox(height: 10),
            Divider(height: 1, color: context.themeDivider),
            const SizedBox(height: 4),
            MergeSemantics(
              child: Row(
                children: [
                  Icon(Icons.celebration_outlined, size: 20, color: secondary),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10n.diwaliCelebrationOnHome,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTypography.label(
                            color: context.themeTextPrimary,
                          ),
                        ),
                        Text(
                          celebrationEnabled
                              ? l10n.showsTheBranchPrizeListAnd
                              : l10n.offNoPopupAddBillRemains,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: AppTypography.caption(color: secondary),
                        ),
                      ],
                    ),
                  ),
                  if (updatingCelebration)
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16),
                      child: SizedBox.square(
                        dimension: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    )
                  else
                    Switch(
                      value: celebrationEnabled,
                      onChanged: onCelebrationChanged,
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatusTag extends StatelessWidget {
  const _StatusTag({required this.isActive});
  final bool isActive;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: isActive ? context.themeSuccessSoft : context.themeErrorSoft,
        borderRadius: AppRadius.sm8,
      ),
      child: Text(
        isActive ? l10n.active : l10n.inactive,
        style: AppTypography.labelSmall(
          color: isActive ? context.themeSuccessText : context.themeErrorText,
        ),
      ),
    );
  }
}

class _Meta extends StatelessWidget {
  const _Meta({required this.icon, required this.text, this.maxLines = 1});
  final IconData icon;
  final String text;
  final int maxLines;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 1),
          child: Icon(icon, size: 16, color: context.themeTextSecondary),
        ),
        const SizedBox(width: 4),
        Flexible(
          child: Text(
            text,
            maxLines: maxLines,
            overflow: TextOverflow.ellipsis,
            style: AppTypography.caption(color: context.themeTextSecondary),
          ),
        ),
      ],
    );
  }
}

/// Lays branch cards out in 1 column on phones and 2 on wide screens.
class BranchCardGrid extends StatelessWidget {
  const BranchCardGrid({
    super.key,
    required this.itemCount,
    required this.itemBuilder,
  });

  final int itemCount;
  final IndexedWidgetBuilder itemBuilder;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        const gap = AppSpacing.md;
        const pad = EdgeInsets.only(bottom: AppSpacing.xl3);
        final usable = constraints.maxWidth - pad.horizontal;
        final columns = usable >= 860 ? 2 : 1;
        if (columns == 1) {
          return ListView.separated(
            padding: pad,
            itemCount: itemCount,
            separatorBuilder: (_, _) => const SizedBox(height: gap),
            itemBuilder: itemBuilder,
          );
        }
        final width = (usable - gap) / 2;
        return SingleChildScrollView(
          padding: pad,
          child: Wrap(
            spacing: gap,
            runSpacing: gap,
            children: [
              for (var i = 0; i < itemCount; i++)
                SizedBox(width: width, child: itemBuilder(context, i)),
            ],
          ),
        );
      },
    );
  }
}
