import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:balaji_points/core/constants/app_constants.dart';
import 'package:balaji_points/core/firebase/app_firestore.dart';
import 'package:balaji_points/core/design/app_colors.dart';
import 'package:balaji_points/core/design/app_radius.dart';
import 'package:balaji_points/core/design/app_typography.dart';
import 'package:balaji_points/core/notifications/notification_category.dart';
import 'package:balaji_points/core/points/leaderboard_group.dart';
import 'package:balaji_points/l10n/app_localizations.dart';
import 'package:balaji_points/presentation/widgets/shared/admin_form_footer.dart';
import 'package:balaji_points/presentation/widgets/shared/app_button.dart';
import 'package:balaji_points/services/branch/current_branch_service.dart';
import 'package:balaji_points/services/notifications/role_broadcast_service.dart';

/// Admin: send a push notification to the members of this branch, picked by
/// role (all four are selected to start). Each member also gets it in their
/// Notifications list, where a tap opens the chosen category's screen.
class SendNotificationPage extends StatefulWidget {
  const SendNotificationPage({super.key, this.service});

  final RoleBroadcastService? service;

  @override
  State<SendNotificationPage> createState() => _SendNotificationPageState();
}

class _SendNotificationPageState extends State<SendNotificationPage> {
  late final RoleBroadcastService _service =
      widget.service ?? RoleBroadcastService();
  final _title = TextEditingController();
  final _body = TextEditingController();
  final Set<String> _roles = {...RoleBroadcastService.memberRoles};
  NotificationCategory _category = NotificationCategory.general;
  bool _sending = false;

  /// Approved members of this branch, kept live for the recipient count.
  late final Stream<QuerySnapshot<Map<String, dynamic>>> _members = appFirestore
      .collection('users')
      .forAdminBranch()
      .snapshots();

  bool get _allRoles =>
      _roles.length == RoleBroadcastService.memberRoles.length;

  @override
  void initState() {
    super.initState();
    _title.addListener(_refresh);
    _body.addListener(_refresh);
  }

  void _refresh() => setState(() {});

  @override
  void dispose() {
    _title.dispose();
    _body.dispose();
    super.dispose();
  }

  String _roleLabel(AppLocalizations l10n, String role) => switch (role) {
    AppConstants.roleCarpenter => l10n.carpenter,
    AppConstants.roleInteriorDesigner => l10n.roleInteriorDesigner,
    AppConstants.roleArchitect => l10n.roleArchitect,
    _ => l10n.roleEngineer,
  };

  int _countFor(QuerySnapshot<Map<String, dynamic>>? snap) {
    if (snap == null) return 0;
    return snap.docs.where((d) {
      final data = d.data();
      if (!MemberFilter.isActiveMember(data)) return false;
      final role = RoleBroadcastService.memberRoleOf(data['role'] as String?);
      return role != null && _roles.contains(role);
    }).length;
  }

  bool get _canSend =>
      !_sending &&
      _roles.isNotEmpty &&
      _title.text.trim().isNotEmpty &&
      _body.text.trim().isNotEmpty;

  Future<void> _send(int count) async {
    final l10n = AppLocalizations.of(context)!;
    final branchId = CurrentBranchService.adminBranchId;
    if (branchId == null || branchId.isEmpty) return;
    FocusScope.of(context).unfocus();

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: AppRadius.all16),
        title: Text(l10n.sendNotificationConfirmTitle),
        content: Text(l10n.sendNotificationConfirm(count)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(l10n.send),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;

    setState(() => _sending = true);
    try {
      final res = await _service.send(
        branchId: branchId,
        roles: _roles,
        category: _category.id,
        title: _title.text,
        body: _body.text,
      );
      if (!mounted) return;
      _title.clear();
      _body.clear();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          backgroundColor: context.themePrimary,
          content: Text(l10n.sendNotificationDone(res.recipients, res.pushed)),
        ),
      );
    } on FirebaseFunctionsException catch (e) {
      _showError(e.message ?? l10n.sendNotificationFailed);
    } catch (_) {
      _showError(l10n.sendNotificationFailed);
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor: context.themeError,
        content: Text(message),
      ),
    );
  }

  Widget _label(String text, {Widget? trailing}) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Row(
      children: [
        Expanded(
          child: Text(
            text,
            style: AppTypography.label(color: context.themeTextSecondary),
          ),
        ),
        ?trailing,
      ],
    ),
  );

  Widget _chip({
    required String label,
    required bool selected,
    required VoidCallback onTap,
    IconData? icon,
  }) {
    return FilterChip(
      label: Text(label),
      avatar: icon == null
          ? null
          : Icon(
              icon,
              size: 16,
              color: selected
                  ? context.themeOnPrimary
                  : context.themePrimaryLight,
            ),
      selected: selected,
      showCheckmark: icon == null,
      checkmarkColor: context.themeOnPrimary,
      selectedColor: context.themePrimary,
      backgroundColor: context.themeCard,
      side: BorderSide(
        color: selected ? context.themePrimary : context.themeBorder,
      ),
      labelStyle: AppTypography.label(
        color: selected ? context.themeOnPrimary : context.themeTextPrimary,
      ),
      visualDensity: VisualDensity.compact,
      onSelected: (_) => onTap(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: _members,
      builder: (context, snap) {
        final count = _countFor(snap.data);
        return Scaffold(
          backgroundColor: context.themeBackground,
          bottomNavigationBar: AdminFormFooter(
            child: AppButton.primary(
              label: l10n.sendNotificationButton(count),
              icon: Icons.send_rounded,
              isLoading: _sending,
              onPressed: _canSend && count > 0 ? () => _send(count) : null,
            ),
          ),
          body: AbsorbPointer(
            absorbing: _sending,
            child: CustomScrollView(
              slivers: [
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _label(
                          l10n.sendNotificationTo,
                          trailing: Text(
                            l10n.sendNotificationMembers(count),
                            style: AppTypography.label(
                              color: context.themePrimaryLight,
                            ),
                          ),
                        ),
                        Wrap(
                          spacing: 8,
                          runSpacing: 6,
                          children: [
                            _chip(
                              label: l10n.allMembers,
                              selected: _allRoles,
                              onTap: () => setState(() {
                                if (_allRoles) {
                                  _roles.clear();
                                } else {
                                  _roles.addAll(
                                    RoleBroadcastService.memberRoles,
                                  );
                                }
                              }),
                            ),
                            for (final r in RoleBroadcastService.memberRoles)
                              _chip(
                                label: _roleLabel(l10n, r),
                                selected: _roles.contains(r),
                                onTap: () => setState(() {
                                  if (!_roles.remove(r)) _roles.add(r);
                                }),
                              ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        _label(l10n.sendNotificationCategory),
                        SizedBox(
                          height: 40,
                          child: ListView.separated(
                            scrollDirection: Axis.horizontal,
                            itemCount: NotificationCategory.sendable.length,
                            separatorBuilder: (_, _) =>
                                const SizedBox(width: 8),
                            itemBuilder: (context, i) {
                              final c = NotificationCategory.sendable[i];
                              return _chip(
                                label: c.label(l10n),
                                icon: c.icon,
                                selected: c == _category,
                                onTap: () => setState(() => _category = c),
                              );
                            },
                          ),
                        ),
                        if (_category.route != null)
                          Padding(
                            padding: const EdgeInsets.only(top: 6),
                            child: Text(
                              l10n.sendNotificationOpens(
                                _category.action(l10n) ?? '',
                              ),
                              style: AppTypography.caption(
                                color: context.themeTextMuted,
                              ),
                            ),
                          ),
                        const SizedBox(height: 16),
                        TextField(
                          controller: _title,
                          textCapitalization: TextCapitalization.sentences,
                          inputFormatters: [
                            LengthLimitingTextInputFormatter(
                              RoleBroadcastService.maxTitle,
                            ),
                          ],
                          decoration: InputDecoration(
                            labelText: l10n.sendNotificationTitle,
                            hintText: l10n.sendNotificationTitleHint,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Expanded(
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(minHeight: 110),
                            child: TextField(
                              controller: _body,
                              expands: true,
                              maxLines: null,
                              textAlignVertical: TextAlignVertical.top,
                              textCapitalization: TextCapitalization.sentences,
                              maxLength: RoleBroadcastService.maxBody,
                              decoration: InputDecoration(
                                labelText: l10n.sendNotificationMessage,
                                hintText: l10n.sendNotificationMessageHint,
                                alignLabelWithHint: true,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
