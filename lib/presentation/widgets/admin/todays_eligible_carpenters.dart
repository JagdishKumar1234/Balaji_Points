import 'package:flutter/material.dart';
import 'package:balaji_points/core/design/app_colors.dart';
import 'package:balaji_points/core/design/app_typography.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class TodaysEligibleCarpenters extends StatelessWidget {
  const TodaysEligibleCarpenters({super.key});

  Future<List<Map<String, dynamic>>> _getTodaysEligibleCarpenters() async {
    try {
      // Get today's date in YYYY-MM-DD format
      final today = DateTime.now();
      final todayStr =
          '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';

      debugPrint('Fetching eligible carpenters for date: $todayStr');

      // Query bills that were approved today
      final billsQuery = await FirebaseFirestore.instance
          .collection('bills')
          .where('status', isEqualTo: 'approved')
          .where('approvedDate', isEqualTo: todayStr)
          .get();

      debugPrint('Found ${billsQuery.docs.length} approved bills today');

      // Get unique carpenter IDs
      final carpenterIds = <String>{};
      final carpenterBills = <String, List<Map<String, dynamic>>>{};

      for (final doc in billsQuery.docs) {
        final data = doc.data();
        final carpenterId = data['userId'] as String?;

        if (carpenterId != null) {
          carpenterIds.add(carpenterId);

          // Store bill info for this carpenter
          if (!carpenterBills.containsKey(carpenterId)) {
            carpenterBills[carpenterId] = [];
          }
          carpenterBills[carpenterId]!.add({
            'billNumber': data['billNumber'],
            'totalAmount': data['totalAmount'] ?? 0,
            'points': data['points'] ?? 0,
          });
        }
      }

      debugPrint(
        'Unique carpenters with approved bills today: ${carpenterIds.length}',
      );

      // Fetch carpenter details
      final eligibleCarpenters = <Map<String, dynamic>>[];

      for (final carpenterId in carpenterIds) {
        try {
          final userDoc = await FirebaseFirestore.instance
              .collection('users')
              .doc(carpenterId)
              .get();

          if (userDoc.exists) {
            final userData = userDoc.data();
            if (userData != null) {
              final firstName = userData['firstName'] as String? ?? '';
              final lastName = userData['lastName'] as String? ?? '';
              final name = '$firstName $lastName'.trim().isEmpty
                  ? 'Unknown'
                  : '$firstName $lastName'.trim();

              final bills = carpenterBills[carpenterId] ?? [];
              final totalPoints = bills.fold<int>(
                0,
                (sum, bill) => sum + (bill['points'] as int? ?? 0),
              );

              eligibleCarpenters.add({
                'id': carpenterId,
                'name': name,
                'firstName': firstName,
                'lastName': lastName,
                'profileImage': userData['profileImage'],
                'phone': userData['phone'],
                'billsCount': bills.length,
                'totalPoints': totalPoints,
                'bills': bills,
              });
            }
          }
        } catch (e) {
          debugPrint('Error fetching user $carpenterId: $e');
        }
      }

      // Sort by total points descending
      eligibleCarpenters.sort(
        (a, b) => (b['totalPoints'] as int).compareTo(a['totalPoints'] as int),
      );

      debugPrint('Returning ${eligibleCarpenters.length} eligible carpenters');
      return eligibleCarpenters;
    } catch (e) {
      debugPrint('Error getting today\'s eligible carpenters: $e');
      return [];
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _getTodaysEligibleCarpenters(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _buildLoadingCard();
        }

        if (snapshot.hasError) {
          return _buildErrorCard(snapshot.error.toString());
        }

        final carpenters = snapshot.data ?? [];

        if (carpenters.isEmpty) {
          return _buildEmptyCard();
        }

        return _buildEligibleCarpentersList(carpenters);
      },
    );
  }

  Widget _buildLoadingCard() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(AppColors.lightSecondary),
          ),
          const SizedBox(height: 16),
          Text(
            'Loading eligible carpenters...',
            style: AppTypography.bodyMedium().copyWith(
              fontSize: 14,
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorCard(String error) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.red.shade200),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.error_outline, color: Colors.red.shade600, size: 48),
          const SizedBox(height: 12),
          Text(
            'Error loading data',
            style: AppTypography.labelLarge().copyWith(
              fontSize: 16,
              color: Colors.red.shade800,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            error,
            style: AppTypography.bodyMedium().copyWith(
              fontSize: 12,
              color: Colors.red.shade600,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyCard() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.receipt_long_outlined,
            size: 64,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 16),
          Text(
            'No Eligible Carpenters Today',
            style: AppTypography.labelLarge().copyWith(
              fontSize: 18,
              color: AppColors.lightPrimary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'No carpenters have approved bills today.\nApprove bills to make them eligible for the daily spin!',
            style: AppTypography.bodyMedium().copyWith(
              fontSize: 14,
              color: Colors.grey.shade600,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildEligibleCarpentersList(List<Map<String, dynamic>> carpenters) {
    final todayStr = DateFormat('MMMM d, y').format(DateTime.now());

    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppColors.lightSecondary,
                  AppColors.lightSecondary.withValues(alpha: 0.8),
                ],
              ),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.check_circle,
                    color: Colors.white,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Today\'s Eligible Carpenters',
                        style: AppTypography.labelLarge().copyWith(
                          fontSize: 20,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '$todayStr • ${carpenters.length} eligible',
                        style: AppTypography.bodyMedium().copyWith(
                          fontSize: 13,
                          color: Colors.white.withValues(alpha: 0.9),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // List of carpenters
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            padding: const EdgeInsets.all(16),
            itemCount: carpenters.length,
            separatorBuilder: (context, index) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final carpenter = carpenters[index];
              return _buildCarpenterCard(carpenter, index + 1);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildCarpenterCard(Map<String, dynamic> carpenter, int rank) {
    final name = carpenter['name'] as String;
    final phone = carpenter['phone'] as String? ?? 'N/A';
    final billsCount = carpenter['billsCount'] as int;
    final totalPoints = carpenter['totalPoints'] as int;
    final profileImage = carpenter['profileImage'] as String?;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.lightSecondary.withValues(alpha: 0.2),
          width: 1.5,
        ),
      ),
      child: Row(
        children: [
          // Rank badge
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.lightSecondary.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                '$rank',
                style: AppTypography.labelLarge().copyWith(
                  fontSize: 18,
                  color: AppColors.lightSecondary,
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),

          // Profile image
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: AppColors.lightSecondary.withValues(alpha: 0.3),
                width: 2,
              ),
            ),
            child: ClipOval(
              child: _isValidImageUrl(profileImage)
                  ? Image.network(
                      profileImage!,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          color: AppColors.lightSecondary.withValues(alpha: 0.1),
                          child: Icon(
                            Icons.person,
                            size: 28,
                            color: AppColors.lightSecondary,
                          ),
                        );
                      },
                    )
                  : Container(
                      color: AppColors.lightSecondary.withValues(alpha: 0.1),
                      child: Icon(
                        Icons.person,
                        size: 28,
                        color: AppColors.lightSecondary,
                      ),
                    ),
            ),
          ),
          const SizedBox(width: 16),

          // Carpenter info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: AppTypography.labelLarge().copyWith(
                    fontSize: 16,
                    color: AppColors.lightPrimary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(Icons.phone, size: 14, color: Colors.grey.shade600),
                    const SizedBox(width: 4),
                    Text(
                      phone,
                      style: AppTypography.bodyMedium().copyWith(
                        fontSize: 13,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Stats
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.green.shade200),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.receipt, size: 14, color: Colors.green.shade700),
                    const SizedBox(width: 4),
                    Text(
                      '$billsCount',
                      style: AppTypography.labelLarge().copyWith(
                        fontSize: 13,
                        color: Colors.green.shade800,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.amber.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.amber.shade200),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.monetization_on,
                      size: 14,
                      color: Colors.amber.shade700,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '+$totalPoints',
                      style: AppTypography.labelLarge().copyWith(
                        fontSize: 13,
                        color: Colors.amber.shade900,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  bool _isValidImageUrl(String? url) {
    if (url == null || url.isEmpty) return false;
    final trimmed = url.trim();
    return trimmed.startsWith('http://') || trimmed.startsWith('https://');
  }
}
