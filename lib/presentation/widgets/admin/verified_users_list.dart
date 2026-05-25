import 'package:flutter/material.dart';
import 'package:balaji_points/core/design/app_colors.dart';
import 'package:balaji_points/core/design/app_typography.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class VerifiedUsersList extends StatelessWidget {
  const VerifiedUsersList({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.themeSoftSurface,
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .where('status', isEqualTo: 'verified')
            .where('role', isEqualTo: 'carpenter')
            .orderBy('totalPoints', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Text(
                'Error: ${snapshot.error}',
                style: AppTypography.bodyMedium().copyWith(color: context.themeError),
              ),
            );
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.people_outline,
                    size: 64,
                    color: context.themePrimary.withValues(alpha: 0.5),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No Verified Carpenters',
                    style: AppTypography.labelLarge().copyWith(
                      fontSize: 18,
                      color: context.themePrimary.withValues(alpha: 0.7),
                    ),
                  ),
                ],
              ),
            );
          }

          final users = snapshot.data!.docs;

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: users.length,
            itemBuilder: (context, index) {
              final doc = users[index];
              final data = doc.data() as Map<String, dynamic>;
              final uid = doc.id;
              final firstName = data['firstName'] ?? '';
              final lastName = data['lastName'] ?? '';
              final phone = data['phone'] ?? '';
              final totalPoints = data['totalPoints'] ?? 0;
              final tier = data['tier'] ?? 'Bronze';
              final city = data['city'] ?? 'N/A';
              final skill = data['skill'] ?? 'N/A';

              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: AppColors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.black.withValues(alpha: 0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: ExpansionTile(
                  tilePadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  childrenPadding: const EdgeInsets.all(16),
                  leading: Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [context.themePrimary, context.themeSecondary],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        '${firstName[0]}${lastName.isNotEmpty ? lastName[0] : ''}',
                        style: AppTypography.labelLarge().copyWith(
                          fontSize: 18,
                          color: AppColors.white,
                        ),
                      ),
                    ),
                  ),
                  title: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '$firstName $lastName',
                        style: AppTypography.labelLarge().copyWith(
                          fontSize: 16,
                          color: context.themePrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            Icons.phone,
                            size: 14,
                            color: context.themePrimary.withValues(alpha: 0.6),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            phone,
                            style: AppTypography.bodyMedium().copyWith(
                              fontSize: 13,
                              color: context.themePrimary.withValues(alpha: 0.6),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  trailing: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: _getTierColor(tier).withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: _getTierColor(tier).withValues(alpha: 0.3),
                            width: 1,
                          ),
                        ),
                        child: Text(
                          tier,
                          style: AppTypography.labelLarge().copyWith(
                            fontSize: 11,
                            color: _getTierColor(tier),
                          ),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.stars, size: 14, color: AppColors.warning),
                          const SizedBox(width: 4),
                          Text(
                            '$totalPoints',
                            style: AppTypography.labelLarge().copyWith(
                              fontSize: 14,
                              color: context.themePrimary,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  children: [
                    _buildDetailRow(context, Icons.location_city, 'City', city),
                    const SizedBox(height: 8),
                    _buildDetailRow(context, Icons.build, 'Skill', skill),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => CarpenterDetailPage(
                              userId: uid,
                              userName: '$firstName $lastName',
                              phone: phone,
                            ),
                          ),
                        );
                      },
                      icon: const Icon(Icons.person, size: 18),
                      label: Text(
                        'View Details',
                        style: AppTypography.labelLarge().copyWith(
                          fontSize: 14,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: context.themePrimary,
                        foregroundColor: AppColors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 12,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildDetailRow(BuildContext context, IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 16, color: context.themePrimary.withValues(alpha: 0.6)),
        const SizedBox(width: 8),
        Text(
          '$label: ',
          style: AppTypography.bodySmall().copyWith(
            fontSize: 13,
            color: context.themePrimary.withValues(alpha: 0.7),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: AppTypography.labelLarge().copyWith(
              fontSize: 13,
              color: context.themePrimary,
            ),
          ),
        ),
      ],
    );
  }

  Color _getTierColor(String tier) {
    switch (tier.toLowerCase()) {
      case 'bronze':
        return AppColors.lightSoftSurface;
      case 'silver':
        return AppColors.lightTextSecondary;
      case 'gold':
        return AppColors.warning;
      case 'platinum':
        return AppColors.lightPrimary;
      default:
        return AppColors.lightPrimary;
    }
  }
}

// Carpenter Detail Page
class CarpenterDetailPage extends StatelessWidget {
  final String userId;
  final String userName;
  final String phone;

  const CarpenterDetailPage({
    super.key,
    required this.userId,
    required this.userName,
    required this.phone,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.themePrimary,
      appBar: AppBar(
        backgroundColor: context.themePrimary,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          userName,
          style: AppTypography.labelLarge().copyWith(
            fontSize: 20,
            color: AppColors.white,
          ),
        ),
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .doc(userId)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final data = snapshot.data!.data() as Map<String, dynamic>?;
          final totalPoints = data?['totalPoints'] ?? 0;
          final tier = data?['tier'] ?? 'Bronze';

          return Container(
            color: context.themeSoftSurface,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  // Stats Card
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [context.themePrimary, context.themeSecondary],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: context.themePrimary.withValues(alpha: 0.3),
                          blurRadius: 15,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            _buildStatItem(
                              'Total Points',
                              '$totalPoints',
                              Icons.stars,
                            ),
                            _buildStatItem(
                              'Tier',
                              tier,
                              Icons.workspace_premium,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Bills Section
                  StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('bills')
                        .where('userId', isEqualTo: userId)
                        .orderBy('createdAt', descending: true)
                        .snapshots(),
                    builder: (context, billsSnapshot) {
                      if (!billsSnapshot.hasData) {
                        return const Center(child: CircularProgressIndicator());
                      }

                      final bills = billsSnapshot.data!.docs;

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Purchase Bills',
                            style: AppTypography.labelLarge().copyWith(
                              fontSize: 18,
                              color: context.themePrimary,
                            ),
                          ),
                          const SizedBox(height: 12),
                          if (bills.isEmpty)
                            Container(
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                color: AppColors.white,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Center(
                                child: Text(
                                  'No bills yet',
                                  style: AppTypography.bodyMedium().copyWith(
                                    color: context.themePrimary.withValues(alpha: 
                                      0.5,
                                    ),
                                  ),
                                ),
                              ),
                            )
                          else
                            ...bills.map((billDoc) {
                              final billData =
                                  billDoc.data() as Map<String, dynamic>;
                              final amount = billData['amount'] ?? 0.0;
                              final points = billData['points'] ?? 0;
                              final status = billData['status'] ?? 'pending';
                              final createdAt =
                                  billData['createdAt'] as Timestamp?;

                              return Container(
                                margin: const EdgeInsets.only(bottom: 8),
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: AppColors.white,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          '₹${amount.toStringAsFixed(0)}',
                                          style: AppTypography.labelLarge()
                                              .copyWith(
                                                fontSize: 18,
                                                color: context.themePrimary,
                                              ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          'Points: $points',
                                          style: AppTypography.bodyMedium()
                                              .copyWith(
                                                fontSize: 13,
                                                color: context.themePrimary
                                                    .withValues(alpha: 0.7),
                                              ),
                                        ),
                                        if (createdAt != null)
                                          Text(
                                            _formatDate(createdAt.toDate()),
                                            style: AppTypography.bodyMedium()
                                                .copyWith(
                                                  fontSize: 12,
                                                  color: context.themePrimary
                                                      .withValues(alpha: 0.5),
                                                ),
                                          ),
                                      ],
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 10,
                                        vertical: 6,
                                      ),
                                      decoration: BoxDecoration(
                                        color: status == 'approved'
                                            ? AppColors.success.withValues(alpha: 0.1)
                                            : AppColors.warning.withValues(alpha: 0.1),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Text(
                                        status.toUpperCase(),
                                        style: AppTypography.labelLarge()
                                            .copyWith(
                                              fontSize: 11,
                                              color: status == 'approved'
                                                  ? AppColors.success
                                                  : context.themeSecondary,
                                            ),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }),
                        ],
                      );
                    },
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: AppColors.white, size: 32),
        const SizedBox(height: 8),
        Text(
          value,
          style: AppTypography.labelLarge().copyWith(
            fontSize: 20,
            color: AppColors.white,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: AppTypography.bodyMedium().copyWith(
            fontSize: 12,
            color: AppColors.white.withValues(alpha: 0.9),
          ),
        ),
      ],
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}
