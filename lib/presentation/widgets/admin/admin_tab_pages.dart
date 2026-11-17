import 'package:balaji_points/core/design/app_colors.dart';
import 'package:balaji_points/core/design/app_radius.dart';
import 'package:balaji_points/core/design/app_typography.dart';
import 'package:balaji_points/l10n/app_localizations.dart';
import 'package:flutter/material.dart';

import 'bill_history_list.dart';
import 'pending_bills_list.dart';
import 'users_list.dart';

/// Admin Bills tab: Pending and History, with the pending count.
class AdminBillsTab extends StatelessWidget {
  const AdminBillsTab({
    super.key,
    required this.pendingCount,
    this.initial = 0,
  });

  final int pendingCount;

  /// 0 = Pending, 1 = History.
  final int initial;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return DefaultTabController(
      length: 2,
      initialIndex: initial,
      child: Column(
        children: [
          ColoredBox(
            color: context.themeBackground,
            child: TabBar(
              labelColor: context.themeContentColor,
              unselectedLabelColor: context.themeTextSecondary,
              indicatorColor: AppColors.gold,
              indicatorWeight: 3,
              labelStyle: AppTypography.label(),
              tabs: [
                Tab(
                  text: pendingCount > 0
                      ? '${l10n.pendingBills} ($pendingCount)'
                      : l10n.pendingBills,
                ),
                Tab(text: l10n.billHistory),
              ],
            ),
          ),
          const Expanded(
            child: TabBarView(
              children: [PendingBillsList(), BillHistoryList()],
            ),
          ),
        ],
      ),
    );
  }
}

/// Admin Members tab: the members list, with account requests waiting on
/// top (they open the Account requests screen).
class AdminMembersTab extends StatelessWidget {
  const AdminMembersTab({
    super.key,
    required this.requestsCount,
    required this.onOpenRequests,
  });

  final int requestsCount;
  final VoidCallback onOpenRequests;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
          child: Material(
            color: requestsCount > 0
                ? context.themeGoldSoft
                : context.themeCard,
            shape: RoundedRectangleBorder(
              borderRadius: AppRadius.md12,
              side: BorderSide(
                color: requestsCount > 0
                    ? AppColors.gold.withValues(alpha: 0.6)
                    : context.themeBorder,
              ),
            ),
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              key: const ValueKey('admin-members-requests'),
              onTap: onOpenRequests,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 10, 8, 10),
                child: Row(
                  children: [
                    Icon(
                      Icons.how_to_reg_rounded,
                      color: requestsCount > 0
                          ? context.themePendingText
                          : context.themeContentColor,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        l10n.accountRequests,
                        style: AppTypography.label(
                          color: context.themeTextPrimary,
                        ),
                      ),
                    ),
                    if (requestsCount > 0)
                      Container(
                        constraints: const BoxConstraints(minWidth: 24),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 7,
                          vertical: 2,
                        ),
                        decoration: const BoxDecoration(
                          color: AppColors.gold,
                          borderRadius: AppRadius.pill,
                        ),
                        child: Text(
                          '$requestsCount',
                          textAlign: TextAlign.center,
                          style: AppTypography.labelSmall(
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                    Icon(
                      Icons.chevron_right_rounded,
                      color: context.themeTextMuted,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        const Expanded(child: UsersList()),
      ],
    );
  }
}
