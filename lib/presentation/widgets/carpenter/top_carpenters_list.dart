import 'package:balaji_points/core/design/app_colors.dart';
import 'package:flutter/material.dart';
import 'top_carpenters_display.dart';

class TopCarpentersList extends StatelessWidget {
  final List<CarpenterRank> carpenters;
  final bool showViewAll;

  const TopCarpentersList({
    super.key,
    required this.carpenters,
    this.showViewAll = true,
  });

  /// Get initials from name (e.g., "Ramesh Kumar" -> "RK")
  String _getInitials(String name) {
    final parts = name.trim().split(' ');
    if (parts.isEmpty) return '?';
    if (parts.length == 1) {
      return parts[0].isNotEmpty ? parts[0][0].toUpperCase() : '?';
    }
    final firstInitial = parts[0].isNotEmpty ? parts[0][0] : '';
    final lastInitial = parts[parts.length - 1].isNotEmpty
        ? parts[parts.length - 1][0]
        : '';
    return (firstInitial + lastInitial).toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    if (carpenters.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '🏆 Top Carpenters',
                style: TextStyle(
                  color: AppColors.lightSecondary,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (showViewAll)
                TextButton(onPressed: () {}, child: const Text('View All')),
            ],
          ),
        ),
        const SizedBox(height: 8),
        // Carpenters list with cards
        ...carpenters.map((carpenter) => _buildLeaderboardCard(carpenter)),
      ],
    );
  }

  Widget _buildLeaderboardCard(CarpenterRank carpenter) {
    // Determine rank badge color based on position
    Color rankBgColor;
    Color rankTextColor;

    if (carpenter.rank == 1) {
      rankBgColor = Colors.amber.shade100;
      rankTextColor = Colors.amber.shade700;
    } else if (carpenter.rank == 2) {
      rankBgColor = Colors.grey.shade200;
      rankTextColor = Colors.grey.shade700;
    } else if (carpenter.rank == 3) {
      rankBgColor = Colors.brown.shade100;
      rankTextColor = Colors.brown.shade700;
    } else {
      rankBgColor = AppColors.lightSecondary.withValues(alpha: 0.1);
      rankTextColor = AppColors.lightSecondary;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.lightSecondary.withValues(alpha: 0.2),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Rank badge - Simple number for all ranks
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: rankBgColor,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                '${carpenter.rank}',
                style: TextStyle(
                  color: rankTextColor,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),

          // Initials only (no profile images)
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: rankBgColor,
              border: Border.all(
                color: AppColors.lightSecondary.withValues(alpha: 0.3),
                width: 2,
              ),
            ),
            child: Center(
              child: Text(
                _getInitials(carpenter.name),
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: rankTextColor,
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),

          // Name
          Expanded(
            child: Text(
              carpenter.name,
              style: const TextStyle(fontFamily: 'Nunito', fontWeight: FontWeight.w600).copyWith(
                fontSize: 16,
                color: AppColors.lightTextPrimary,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 12),

          // Points
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.amber.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.amber.shade200, width: 1),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.monetization_on,
                  color: Colors.amber.shade700,
                  size: 20,
                ),
                const SizedBox(width: 4),
                Text(
                  _formatPoints(carpenter.points),
                  style: const TextStyle(fontFamily: 'Nunito', fontWeight: FontWeight.w700).copyWith(
                    fontSize: 16,
                    color: Colors.amber.shade900,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatPoints(int points) {
    if (points >= 1000) {
      return '${(points / 1000).toStringAsFixed(1)}K';
    }
    return points.toString();
  }
}
