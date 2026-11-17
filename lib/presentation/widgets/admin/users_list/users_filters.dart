import 'package:balaji_points/core/design/app_colors.dart';
import 'package:balaji_points/core/design/app_typography.dart';
import 'package:balaji_points/core/points/leaderboard_group.dart';
import 'package:balaji_points/l10n/app_localizations.dart';
import 'package:balaji_points/presentation/widgets/shared/group_labels.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Admin users list filters: sort, tier and member type. Shared so the
/// filter button in the app bar and the list use the same values.
class UsersFilters {
  const UsersFilters({
    this.sort = 'points',
    this.tier = 'All',
    this.role = MemberRoleFilter.all,
  });

  /// 'points', 'name' or 'recent'.
  final String sort;

  /// 'All', 'Platinum', 'Gold', 'Silver' or 'Bronze'.
  final String tier;
  final MemberRoleFilter role;

  static const tiers = ['All', 'Platinum', 'Gold', 'Silver', 'Bronze'];
  static const sorts = ['points', 'name', 'recent'];

  /// Filters that narrow the list (sorting does not count).
  int get activeCount =>
      (tier != 'All' ? 1 : 0) + (role != MemberRoleFilter.all ? 1 : 0);

  UsersFilters copyWith({String? sort, String? tier, MemberRoleFilter? role}) =>
      UsersFilters(
        sort: sort ?? this.sort,
        tier: tier ?? this.tier,
        role: role ?? this.role,
      );
}

class UsersFiltersNotifier extends Notifier<UsersFilters> {
  @override
  UsersFilters build() => const UsersFilters();

  void update(UsersFilters value) => state = value;
  void reset() => state = const UsersFilters();
}

final usersFiltersProvider =
    NotifierProvider<UsersFiltersNotifier, UsersFilters>(
      UsersFiltersNotifier.new,
    );

/// App bar button that opens the filter sheet; a gold dot shows how many
/// filters are on.
class UsersFilterButton extends ConsumerWidget {
  const UsersFilterButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final active = ref.watch(usersFiltersProvider).activeCount;
    final l10n = AppLocalizations.of(context)!;
    return IconButton(
      key: const ValueKey('users-filter-button'),
      tooltip: l10n.usersFilterButton,
      onPressed: () => showModalBottomSheet<void>(
        context: context,
        showDragHandle: true,
        isScrollControlled: true,
        backgroundColor: context.themeBackground,
        builder: (_) => const UsersFilterSheet(),
      ),
      icon: Badge(
        isLabelVisible: active > 0,
        backgroundColor: AppColors.gold,
        textColor: AppColors.primary,
        label: Text('$active'),
        child: Icon(Icons.tune_rounded, color: context.themeTextPrimary),
      ),
    );
  }
}

/// Bottom sheet with every users-list filter as chips. Changes apply at
/// once; Reset clears them.
class UsersFilterSheet extends ConsumerWidget {
  const UsersFilterSheet({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final f = ref.watch(usersFiltersProvider);
    final notifier = ref.read(usersFiltersProvider.notifier);

    String sortLabel(String s) => switch (s) {
      'name' => l10n.sortByName,
      'recent' => l10n.recentJoins,
      _ => l10n.sortByPoints,
    };

    Widget chip(String label, bool selected, VoidCallback onTap) => ChoiceChip(
      label: Text(label),
      selected: selected,
      showCheckmark: false,
      selectedColor: context.themePrimary,
      backgroundColor: context.themeCard,
      side: BorderSide(
        color: selected ? context.themePrimary : context.themeBorder,
      ),
      labelStyle: AppTypography.label(
        color: selected ? context.themeOnPrimary : context.themeTextPrimary,
      ),
      onSelected: (_) => onTap(),
    );

    Widget heading(String text) => Padding(
      padding: const EdgeInsets.only(top: 14, bottom: 8),
      child: Text(
        text,
        style: AppTypography.label(color: context.themeTextSecondary),
      ),
    );

    return SafeArea(
      top: false,
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    l10n.filters,
                    style: AppTypography.section(
                      color: context.themeTextPrimary,
                    ),
                  ),
                ),
                TextButton(
                  onPressed: notifier.reset,
                  child: Text(l10n.usersFilterReset),
                ),
              ],
            ),
            heading(l10n.usersFilterSort),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final s in UsersFilters.sorts)
                  chip(
                    sortLabel(s),
                    f.sort == s,
                    () => notifier.update(f.copyWith(sort: s)),
                  ),
              ],
            ),
            heading(l10n.usersFilterRole),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final r in MemberRoleFilter.options)
                  chip(
                    memberRoleFilterLabel(context, r),
                    f.role == r,
                    () => notifier.update(f.copyWith(role: r)),
                  ),
              ],
            ),
            heading(l10n.usersFilterTier),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final t in UsersFilters.tiers)
                  chip(
                    t == 'All' ? l10n.all : t,
                    f.tier == t,
                    () => notifier.update(f.copyWith(tier: t)),
                  ),
              ],
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.gold,
                  foregroundColor: AppColors.primary,
                  minimumSize: const Size.fromHeight(48),
                  shape: const StadiumBorder(),
                ),
                onPressed: () => Navigator.pop(context),
                child: Text(l10n.done),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
