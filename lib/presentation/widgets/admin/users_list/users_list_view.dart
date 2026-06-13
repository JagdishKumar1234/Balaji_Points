import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:balaji_points/core/design/app_radius.dart';
import 'package:balaji_points/core/design/app_colors.dart';
import 'package:balaji_points/core/design/app_typography.dart';
import 'user_list_item.dart';

class UsersListView extends StatelessWidget {
  final String searchQuery;
  final String selectedTier;
  final String selectedSort;
  final VoidCallback onCarpenterDeleted;

  const UsersListView({
    required this.searchQuery,
    required this.selectedTier,
    required this.selectedSort,
    required this.onCarpenterDeleted,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('users').snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(context.themePrimary),
            ),
          );
        }

        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, color: AppColors.error, size: 48),
                const SizedBox(height: 16),
                Text(
                  'Error loading users',
                  style: AppTypography.bodyMedium()
                      .copyWith(color: AppColors.error),
                ),
              ],
            ),
          );
        }

        var users = snapshot.data?.docs ?? [];

        // Filter: Only show non-admin users (carpenters)
        users = users.where((doc) {
          final data = doc.data() as Map<String, dynamic>;
          final role = data['role'] as String?;
          if (role == 'admin') return false;
          return role == null || role.isEmpty || role == 'carpenter';
        }).toList();

        // Apply search filter
        if (searchQuery.isNotEmpty) {
          users = users.where((doc) {
            final data = doc.data() as Map<String, dynamic>;
            final firstName = (data['firstName'] ?? '').toString().toLowerCase();
            final lastName = (data['lastName'] ?? '').toString().toLowerCase();
            final phone = (data['phoneNumber'] ?? data['phone'] ?? '')
                .toString()
                .toLowerCase();

            return firstName.contains(searchQuery) ||
                lastName.contains(searchQuery) ||
                phone.contains(searchQuery);
          }).toList();
        }

        // Apply tier filter
        if (selectedTier != 'All') {
          users = users.where((doc) {
            final data = doc.data() as Map<String, dynamic>;
            final tier = data['tier'] ?? 'Bronze';
            return tier == selectedTier;
          }).toList();
        }

        // Apply sorting
        users.sort((a, b) {
          final dataA = a.data() as Map<String, dynamic>;
          final dataB = b.data() as Map<String, dynamic>;

          switch (selectedSort) {
            case 'name':
              final nameA = '${dataA['firstName'] ?? ''} ${dataA['lastName'] ?? ''}'
                  .toLowerCase();
              final nameB = '${dataB['firstName'] ?? ''} ${dataB['lastName'] ?? ''}'
                  .toLowerCase();
              return nameA.compareTo(nameB);

            case 'recent':
              final dateA = dataA['createdAt'] as Timestamp?;
              final dateB = dataB['createdAt'] as Timestamp?;
              return (dateB?.toDate() ?? DateTime(2000))
                  .compareTo(dateA?.toDate() ?? DateTime(2000));

            case 'points':
            default:
              final pointsA = (dataA['totalPoints'] ?? 0) as num;
              final pointsB = (dataB['totalPoints'] ?? 0) as num;
              return pointsB.compareTo(pointsA);
          }
        });

        if (users.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.people_outline,
                    color: context.themeTextSecondary, size: 48),
                const SizedBox(height: 16),
                Text(
                  'No carpenters found',
                  style: AppTypography.bodyMedium()
                      .copyWith(color: context.themeTextSecondary),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          itemCount: users.length,
          itemBuilder: (context, index) {
            final user = users[index];
            final data = user.data() as Map<String, dynamic>;

            return UserListItem(
              userId: user.id,
              userData: data,
              onDeleted: onCarpenterDeleted,
            );
          },
        );
      },
    );
  }
}
