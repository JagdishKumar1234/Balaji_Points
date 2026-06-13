import 'package:flutter/material.dart';
import 'package:balaji_points/core/design/app_colors.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:balaji_points/l10n/app_localizations.dart';
import 'package:balaji_points/services/user/user_service.dart';
import 'search_header.dart';
import 'users_list_view.dart';
import 'add_carpenter_dialog.dart';

class UsersList extends StatefulWidget {
  const UsersList({super.key});

  @override
  State<UsersList> createState() => _UsersListState();
}

class _UsersListState extends State<UsersList> {
  String _searchQuery = '';
  String _selectedTier = 'All';
  String _selectedSort = 'points';
  final List<String> _tiers = ['All', 'Platinum', 'Gold', 'Silver', 'Bronze'];
  final _userService = UserService();
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
    final l10n = AppLocalizations.of(context)!;

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
              selectedTier: _selectedTier,
              selectedSort: _selectedSort,
              tiers: _tiers,
              isExporting: _isExporting,
              onSearchChanged: (value) {
                setState(() => _searchQuery = value.toLowerCase());
              },
              onTierChanged: (tier) {
                setState(() => _selectedTier = tier ?? 'All');
              },
              onSortChanged: (sort) {
                setState(() => _selectedSort = sort ?? 'points');
              },
              onAddPressed: _showAddCarpenterDialog,
              onExportPressed: () async {
                // Export logic will be handled by SearchHeader
              },
            ),
            // Users List
            Expanded(
              child: UsersListView(
                searchQuery: _searchQuery,
                selectedTier: _selectedTier,
                selectedSort: _selectedSort,
                onCarpenterDeleted: () => setState(() {}),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
