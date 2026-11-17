import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'users_filters.dart';
import 'package:balaji_points/core/design/app_colors.dart';
import 'search_header.dart';
import 'users_list_view.dart';
import 'add_carpenter_dialog.dart';

class UsersList extends ConsumerStatefulWidget {
  const UsersList({super.key});

  @override
  ConsumerState<UsersList> createState() => _UsersListState();
}

class _UsersListState extends ConsumerState<UsersList> {
  String _searchQuery = '';
  bool _isExporting = false;
  late TextEditingController _searchController;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _showAddCarpenterDialog() {
    showDialog(
      context: context,
      builder: (context) => AddCarpenterDialog(
        onCarpenterAdded: () {
          setState(() {});
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Sort, tier and member type come from the app bar filter button.
    final filters = ref.watch(usersFiltersProvider);
    final notifier = ref.read(usersFiltersProvider.notifier);
    return Scaffold(
      backgroundColor: context.themeBackground,
      resizeToAvoidBottomInset: true,
      body: GestureDetector(
        onTap: () {
          FocusScope.of(context).unfocus();
        },
        child: Column(
          children: [
            // Search Header
            SearchHeader(
              searchController: _searchController,
              searchQuery: _searchQuery,
              selectedTier: filters.tier,
              selectedSort: filters.sort,
              roleFilter: filters.role,
              onRoleFilterChanged: (f) =>
                  notifier.update(filters.copyWith(role: f)),
              tiers: UsersFilters.tiers,
              isExporting: _isExporting,
              onSearchChanged: (value) {
                setState(() => _searchQuery = value.toLowerCase());
              },
              onTierChanged: (tier) =>
                  notifier.update(filters.copyWith(tier: tier ?? 'All')),
              onSortChanged: (sort) =>
                  notifier.update(filters.copyWith(sort: sort ?? 'points')),
              onAddPressed: _showAddCarpenterDialog,
              onExportPressed: () async {
                // Export logic will be handled by SearchHeader
              },
            ),
            // Users List
            Expanded(
              child: UsersListView(
                searchQuery: _searchQuery,
                selectedTier: filters.tier,
                selectedSort: filters.sort,
                roleFilter: filters.role,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
