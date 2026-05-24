import 'package:balaji_points/core/design/app_colors.dart';
import 'package:balaji_points/core/design/app_typography.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

class PointsHistoryCard extends StatefulWidget {
  const PointsHistoryCard({super.key});

  @override
  State<PointsHistoryCard> createState() => _PointsHistoryCardState();
}

class _PointsHistoryCardState extends State<PointsHistoryCard> {
  List<Map<String, dynamic>> _history = [];
  bool _isLoading = true;
  bool _isExpanded = false;

  @override
  void initState() {
    super.initState();
    _loadPointsHistory();
  }

  Future<void> _loadPointsHistory() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        setState(() => _isLoading = false);
        return;
      }

      final userPointsDoc = await FirebaseFirestore.instance
          .collection('user_points')
          .doc(user.uid)
          .get();

      if (userPointsDoc.exists) {
        final data = userPointsDoc.data();
        final history = data?['pointsHistory'] as List<dynamic>? ?? [];

        // Convert to list and sort by date (most recent first)
        final historyList = history.map((item) {
          return {
            'points': item['points'] ?? 0,
            'reason': item['reason'] ?? 'Unknown',
            'date': item['date'] ?? item['spinDate'],
          };
        }).toList();

        // Sort by date descending
        historyList.sort((a, b) {
          final dateA = _getDateTime(a['date']);
          final dateB = _getDateTime(b['date']);
          return dateB.compareTo(dateA);
        });

        setState(() {
          _history = historyList;
          _isLoading = false;
        });
      } else {
        setState(() {
          _history = [];
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading points history: $e');
      setState(() => _isLoading = false);
    }
  }

  DateTime _getDateTime(dynamic timestamp) {
    if (timestamp == null) return DateTime.now();
    if (timestamp is Timestamp) return timestamp.toDate();
    if (timestamp is DateTime) return timestamp;
    return DateTime.now();
  }

  String _formatDate(dynamic timestamp) {
    final date = _getDateTime(timestamp);
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      return 'Today at ${DateFormat('HH:mm').format(date)}';
    } else if (difference.inDays == 1) {
      return 'Yesterday at ${DateFormat('HH:mm').format(date)}';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else {
      return DateFormat('MMM dd, yyyy').format(date);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return _buildLoadingCard();
    }

    if (_history.isEmpty) {
      return _buildEmptyCard();
    }

    final displayedHistory = _isExpanded ? _history : _history.take(3).toList();

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.lightPrimary.withOpacity(0.1),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.lightSecondary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.history_rounded,
                    color: AppColors.lightSecondary,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Points History',
                        style: AppTypography.buttonMedium().copyWith(
                          fontSize: 18,
                          color: AppColors.lightPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${_history.length} transactions',
                        style: AppTypography.bodyMedium().copyWith(
                          fontSize: 13,
                          color: AppColors.grey600,
                        ),
                      ),
                    ],
                  ),
                ),
                if (_history.length > 3)
                  IconButton(
                    onPressed: () {
                      setState(() {
                        _isExpanded = !_isExpanded;
                      });
                    },
                    icon: Icon(
                      _isExpanded
                          ? Icons.keyboard_arrow_up
                          : Icons.keyboard_arrow_down,
                      color: AppColors.lightPrimary,
                    ),
                  ),
              ],
            ),
          ),

          // Divider
          Divider(height: 1, color: AppColors.grey200),

          // History List
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            padding: const EdgeInsets.all(16),
            itemCount: displayedHistory.length,
            separatorBuilder: (context, index) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final item = displayedHistory[index];
              return _buildHistoryItem(item);
            },
          ),

          // Show more button
          if (_history.length > 3 && !_isExpanded)
            Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: TextButton.icon(
                onPressed: () {
                  setState(() {
                    _isExpanded = true;
                  });
                },
                icon: Icon(Icons.arrow_downward, size: 16),
                label: Text('Show ${_history.length - 3} more'),
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.lightPrimary,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildHistoryItem(Map<String, dynamic> item) {
    final points = item['points'] as int;
    final reason = item['reason'] as String;
    final date = item['date'];

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.woodenBackground.withOpacity(0.3),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.lightPrimary.withOpacity(0.1),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          // Icon
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: points > 0
                  ? AppColors.success.withOpacity(0.1)
                  : AppColors.red.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              points > 0 ? Icons.add_circle : Icons.remove_circle,
              color: points > 0 ? AppColors.success : AppColors.error,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),

          // Details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  reason,
                  style: AppTypography.labelLarge().copyWith(
                    fontSize: 14,
                    color: AppColors.lightTextPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _formatDate(date),
                  style: AppTypography.bodyMedium().copyWith(
                    fontSize: 12,
                    color: AppColors.grey600,
                  ),
                ),
              ],
            ),
          ),

          // Points
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: points > 0
                  ? AppColors.success.withOpacity(0.1)
                  : AppColors.red.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.monetization_on,
                  size: 14,
                  color: points > 0 ? AppColors.success : AppColors.error,
                ),
                const SizedBox(width: 4),
                Text(
                  '${points > 0 ? '+' : ''}$points',
                  style: AppTypography.buttonMedium().copyWith(
                    fontSize: 14,
                    color: points > 0 ? AppColors.success : AppColors.error,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingCard() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(40),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.lightPrimary.withOpacity(0.1),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Center(
        child: CircularProgressIndicator(color: AppColors.lightPrimary),
      ),
    );
  }

  Widget _buildEmptyCard() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.lightPrimary.withOpacity(0.1),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(Icons.history_rounded, size: 60, color: AppColors.grey300),
          const SizedBox(height: 16),
          Text(
            'No Points History',
            style: AppTypography.buttonMedium().copyWith(
              fontSize: 16,
              color: AppColors.grey600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Your points transactions will appear here',
            style: AppTypography.bodyMedium().copyWith(
              fontSize: 13,
              color: AppColors.grey500,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
