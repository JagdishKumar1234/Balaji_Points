import 'dart:async';

import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:balaji_points/core/design/app_colors.dart';
import 'package:balaji_points/core/design/app_radius.dart';
import 'package:balaji_points/core/design/app_typography.dart';
import 'package:balaji_points/core/points/leaderboard_group.dart';
import 'package:balaji_points/l10n/app_localizations.dart';
import 'package:balaji_points/presentation/widgets/shared/app_loader.dart';
import 'package:balaji_points/presentation/widgets/shared/empty_state.dart';
import 'package:balaji_points/presentation/widgets/shared/group_labels.dart';
import 'package:balaji_points/presentation/widgets/shared/role_label.dart';
import 'package:balaji_points/services/auth/account_approval_service.dart';
import 'package:balaji_points/services/auth/member_whatsapp.dart';
import 'package:balaji_points/services/auth/session_service.dart';
import 'package:balaji_points/services/branch/branch_support_service.dart';
import 'package:balaji_points/services/branch/current_branch_service.dart';

/// Branch admin only: new member sign-ups of their branch waiting for approval,
/// and rejected ones that can still be approved.
class AccountRequestsScreen extends StatefulWidget {
  const AccountRequestsScreen({super.key, this.service, this.branchIdForTest});

  /// For tests.
  final AccountApprovalService? service;

  /// For tests: skip the signed-in admin lookup and use this branch.
  final String? branchIdForTest;

  @override
  State<AccountRequestsScreen> createState() => _AccountRequestsScreenState();
}

class _AccountRequestsScreenState extends State<AccountRequestsScreen> {
  late final AccountApprovalService _service =
      widget.service ?? AccountApprovalService();

  String? _branchId;
  String _branchName = '';
  bool _resolving = true;
  MemberRoleFilter _filter = MemberRoleFilter.all;
  String _search = '';
  final Set<String> _busy = {};

  @override
  void initState() {
    super.initState();
    _resolveBranch();
  }

  /// Store name for the WhatsApp message ("... at Sri Balaji ... E Road").
  Future<void> _loadBranchName() async {
    final id = _branchId;
    if (id == null || id.isEmpty) return;
    try {
      final b = await _service.branchName(id);
      if (mounted) setState(() => _branchName = b);
    } catch (_) {}
  }

  Future<void> _resolveBranch() async {
    if (widget.branchIdForTest != null) {
      setState(() {
        _branchId = widget.branchIdForTest;
        _resolving = false;
      });
      unawaited(_loadBranchName());
      return;
    }
    // Only a branch admin reviews requests, and only for their own branch.
    final role = (await SessionService().getUserRole())?.toLowerCase();
    String? branch;
    if (role == 'admin') {
      // Opened from a push before the admin shell set the branch.
      branch =
          CurrentBranchService.adminBranchId ??
          await CurrentBranchService().resolveBranchId();
    }
    if (!mounted) return;
    setState(() {
      _branchId = branch;
      _resolving = false;
    });
    unawaited(_loadBranchName());
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return DefaultTabController(
      length: 2,
      child: StreamBuilder<List<AccountRequest>>(
        stream: _resolving ? null : _service.watchRequests(_branchId),
        builder: (context, snap) {
          final all = snap.data ?? const <AccountRequest>[];
          final shown = all.where((r) {
            if (!_filter.matches(r.role)) return false;
            if (_search.isEmpty) return true;
            return r.name.toLowerCase().contains(_search) ||
                r.phone.contains(_search);
          }).toList();
          final pending = shown
              .where((r) => r.status != AccountApproval.rejected)
              .toList();
          final rejected = shown
              .where((r) => r.status == AccountApproval.rejected)
              .toList();

          return Scaffold(
            backgroundColor: context.themeBackground,
            appBar: AppBar(
              title: Text(l10n.accountRequests),
              leading: IconButton(
                icon: const Icon(Icons.arrow_back_rounded),
                onPressed: () =>
                    context.canPop() ? context.pop() : context.go('/admin'),
              ),
              bottom: TabBar(
                tabs: [
                  Tab(
                    text: l10n.accountRequestsPendingTab('${pending.length}'),
                  ),
                  Tab(
                    text: l10n.accountRequestsRejectedTab('${rejected.length}'),
                  ),
                ],
              ),
            ),
            body: Column(
              children: [
                _filters(context),
                Expanded(
                  child:
                      _resolving ||
                          snap.connectionState == ConnectionState.waiting
                      ? const Center(child: AppLoader())
                      : TabBarView(
                          children: [
                            _list(context, pending, all, rejectedTab: false),
                            _list(context, rejected, all, rejectedTab: true),
                          ],
                        ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _filters(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: TextField(
                  decoration: InputDecoration(
                    hintText: l10n.searchByNameOrPhone,
                    prefixIcon: const Icon(Icons.search_rounded),
                    isDense: true,
                    border: const OutlineInputBorder(),
                  ),
                  onChanged: (v) =>
                      setState(() => _search = v.trim().toLowerCase()),
                ),
              ),
              const SizedBox(width: 8),
              Flexible(
                child: DropdownButtonFormField<MemberRoleFilter>(
                  initialValue: _filter,
                  isExpanded: true,
                  decoration: const InputDecoration(
                    isDense: true,
                    border: OutlineInputBorder(),
                  ),
                  items: [
                    for (final f in MemberRoleFilter.options)
                      DropdownMenuItem(
                        value: f,
                        child: Padding(
                          padding: EdgeInsets.only(
                            left: f.roleValue != null ? 12 : 0,
                          ),
                          child: Text(
                            memberRoleFilterLabel(context, f),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ),
                  ],
                  onChanged: (f) =>
                      setState(() => _filter = f ?? MemberRoleFilter.all),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _list(
    BuildContext context,
    List<AccountRequest> items,
    List<AccountRequest> everyone, {
    required bool rejectedTab,
  }) {
    final l10n = AppLocalizations.of(context)!;
    if (items.isEmpty) {
      return ListView(
        padding: const EdgeInsets.all(16),
        children: [
          EmptyState(
            icon: rejectedTab ? Icons.block_rounded : Icons.how_to_reg_rounded,
            title: rejectedTab
                ? l10n.noRejectedRequests
                : l10n.noPendingRequests,
            message: rejectedTab ? null : l10n.noPendingRequestsHint,
          ),
        ],
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      itemCount: items.length,
      separatorBuilder: (_, _) => const SizedBox(height: 10),
      itemBuilder: (context, i) =>
          _card(context, items[i], everyone, rejectedTab: rejectedTab),
    );
  }

  Widget _card(
    BuildContext context,
    AccountRequest r,
    List<AccountRequest> everyone, {
    required bool rejectedTab,
  }) {
    final l10n = AppLocalizations.of(context)!;
    final name = r.name.isEmpty ? r.phone : r.name;
    final group = LeaderboardGroups.of(r.role);
    final busy = _busy.contains(r.id);
    final requested = r.requestedAt;
    // Same name as another request in this branch: worth a second look.
    final sameName = everyone.where(
      (o) =>
          o.id != r.id &&
          r.name.isNotEmpty &&
          o.name.toLowerCase() == r.name.toLowerCase(),
    );
    final reason = (r.data['rejectReason'] as String? ?? '').trim();

    return Container(
      key: ValueKey('request-${r.id}'),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: context.themeSurface,
        borderRadius: AppRadius.md12,
        border: Border.all(color: context.themeBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                backgroundColor: context.themePrimary.withValues(alpha: 0.1),
                child: Text(
                  name.isEmpty ? '?' : name.characters.first.toUpperCase(),
                  style: AppTypography.labelLarge(color: context.themePrimary),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.labelLarge(
                        color: context.themeTextPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        RoleTag(
                          roleId: r.role.isEmpty ? 'carpenter' : r.role,
                          storedName: r.data['roleName'] as String?,
                        ),
                        if (group != null)
                          Text(
                            group.shortLabel(context),
                            style: AppTypography.bodySmall(
                              color: context.themeTextSecondary,
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              if (r.phone.isNotEmpty)
                IconButton(
                  tooltip: r.phone,
                  icon: Icon(Icons.call_rounded, color: context.themePrimary),
                  onPressed: () => launchUrl(
                    Uri(scheme: 'tel', path: BranchSupport.dialable(r.phone)),
                    mode: LaunchMode.externalApplication,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            [
              if (r.phone.isNotEmpty) r.phone,
              if (requested != null)
                l10n.requestedOn(
                  DateFormat('d MMM y, h:mm a').format(requested),
                ),
            ].join(' · '),
            style: AppTypography.bodySmall(color: context.themeTextSecondary),
          ),
          if (sameName.isNotEmpty) ...[
            const SizedBox(height: 6),
            Row(
              children: [
                const Icon(
                  Icons.warning_amber_rounded,
                  size: 16,
                  color: AppColors.warning,
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    l10n.possibleDuplicate(sameName.first.name),
                    style: AppTypography.bodySmall(color: AppColors.warning),
                  ),
                ),
              ],
            ),
          ],
          if (rejectedTab && reason.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              l10n.rejectReasonValue(reason),
              style: AppTypography.bodySmall(color: context.themeError),
            ),
          ],
          const SizedBox(height: 12),
          Row(
            children: [
              if (!rejectedTab) ...[
                Expanded(
                  child: OutlinedButton.icon(
                    key: ValueKey('reject-${r.id}'),
                    onPressed: busy ? null : () => _reject(r, name),
                    icon: const Icon(Icons.close_rounded),
                    label: Text(l10n.reject),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: context.themeError,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
              ],
              Expanded(
                child: FilledButton.icon(
                  key: ValueKey('approve-${r.id}'),
                  onPressed: busy ? null : () => _approve(r, name),
                  icon: busy
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: AppLoader(size: 16, color: AppColors.white),
                        )
                      : const Icon(Icons.check_rounded),
                  label: Text(l10n.approve),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _approve(AccountRequest r, String name) async {
    final l10n = AppLocalizations.of(context)!;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.approve),
        content: Text(l10n.approveAccountConfirm(name)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(MaterialLocalizations.of(ctx).cancelButtonLabel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(l10n.approve),
          ),
        ],
      ),
    );
    if (ok != true) return;
    await _run(r, approve: true, toast: l10n.accountApprovedToast(name));
  }

  Future<void> _reject(AccountRequest r, String name) async {
    final l10n = AppLocalizations.of(context)!;
    final reason = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => _RejectSheet(name: name),
    );
    if (reason == null) return; // cancelled
    await _run(
      r,
      approve: false,
      reason: reason,
      toast: l10n.accountRejectedToast(name),
    );
  }

  Future<void> _run(
    AccountRequest r, {
    required bool approve,
    String? reason,
    required String toast,
  }) async {
    setState(() => _busy.add(r.id));
    var done = false;
    final messenger = ScaffoldMessenger.of(context);
    final errorColor = context.themeError;
    try {
      await _service.review(userId: r.id, approve: approve, reason: reason);
      messenger.showSnackBar(SnackBar(content: Text(toast)));
      done = true;
    } catch (e) {
      final message = e is FirebaseFunctionsException && e.message != null
          ? e.message!
          : '$e';
      messenger.showSnackBar(
        SnackBar(content: Text(message), backgroundColor: errorColor),
      );
    } finally {
      if (mounted) setState(() => _busy.remove(r.id));
    }
    // Then offer a WhatsApp message from the admin's phone.
    if (done && mounted) {
      await _offerWhatsApp(r, approve: approve, reason: reason);
    }
  }
}

/// After Approve / Reject: offer a ready WhatsApp message to the member,
/// sent from the admin's own phone. Returns quietly when the member has no
/// usable number.
extension on _AccountRequestsScreenState {
  Future<void> _offerWhatsApp(
    AccountRequest r, {
    required bool approve,
    String? reason,
  }) async {
    final l10n = AppLocalizations.of(context)!;
    final name = r.name.isEmpty ? r.phone : r.name;
    final branch = _branchName.isNotEmpty ? _branchName : 'Balaji Points';
    final why = (reason ?? '').trim();
    final message = approve
        ? l10n.waApprovedMessage(name, branch)
        : l10n.waRejectedMessage(
            name,
            branch,
            why.isEmpty ? '' : l10n.waReasonPart(why),
          );
    final uri = MemberWhatsApp.chatUri(r.phone, message);
    if (uri == null) return;

    final send = await showModalBottomSheet<bool>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
          child: Column(
            key: const ValueKey('whatsapp-offer'),
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                l10n.letMemberKnowTitle(name),
                style: AppTypography.h5(color: ctx.themeTextPrimary),
              ),
              const SizedBox(height: 6),
              Text(
                approve
                    ? l10n.letMemberKnowApproved
                    : l10n.letMemberKnowRejected,
                style: AppTypography.bodyMedium(color: ctx.themeTextSecondary),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: ctx.themeSoftSurface,
                  borderRadius: AppRadius.md12,
                ),
                child: Text(
                  message,
                  key: const ValueKey('whatsapp-message'),
                  style: AppTypography.bodySmall(color: ctx.themeTextPrimary),
                ),
              ),
              const SizedBox(height: 16),
              FilledButton.icon(
                key: const ValueKey('send-whatsapp'),
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF1FA855),
                  foregroundColor: AppColors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                icon: const Icon(Icons.chat_rounded),
                label: Text(l10n.sendWhatsApp),
                onPressed: () => Navigator.pop(ctx, true),
              ),
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: Text(l10n.notNow),
              ),
            ],
          ),
        ),
      ),
    );
    if (send != true || !mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    var opened = false;
    try {
      opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {
      opened = false;
    }
    if (!opened) {
      messenger.showSnackBar(
        SnackBar(content: Text(l10n.whatsAppNotAvailable)),
      );
    }
  }
}

/// Bottom sheet to confirm a rejection with an optional reason.
/// Pops the reason ('' for none), or null when cancelled.
class _RejectSheet extends StatefulWidget {
  const _RejectSheet({required this.name});

  final String name;

  @override
  State<_RejectSheet> createState() => _RejectSheetState();
}

class _RejectSheetState extends State<_RejectSheet> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final presets = [
      l10n.rejectReasonNotCustomer,
      l10n.rejectReasonWrongBranch,
      l10n.rejectReasonDuplicate,
    ];
    return Padding(
      padding: EdgeInsets.fromLTRB(
        16,
        16,
        16,
        16 + MediaQuery.viewInsetsOf(context).bottom,
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              l10n.rejectAccountTitle(widget.name),
              style: AppTypography.h5(color: context.themeTextPrimary),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final p in presets)
                  ActionChip(
                    label: Text(p),
                    onPressed: () => setState(() => _controller.text = p),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _controller,
              maxLength: 200,
              decoration: InputDecoration(
                labelText: l10n.rejectReasonOptional,
                hintText: l10n.enterRejectReason,
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text(
                      MaterialLocalizations.of(context).cancelButtonLabel,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: FilledButton(
                    key: const ValueKey('confirm-reject'),
                    style: FilledButton.styleFrom(
                      backgroundColor: context.themeError,
                      foregroundColor: context.themeOnError,
                    ),
                    onPressed: () =>
                        Navigator.pop(context, _controller.text.trim()),
                    child: Text(l10n.reject),
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
