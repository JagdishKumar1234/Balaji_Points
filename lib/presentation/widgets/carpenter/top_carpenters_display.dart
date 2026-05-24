import 'package:balaji_points/core/design/app_colors.dart';
import 'package:flutter/material.dart';

class TopCarpentersDisplay extends StatelessWidget {
  final List<CarpenterRank> topCarpenters;
  final CarpenterRank? currentUser;

  const TopCarpentersDisplay({
    super.key,
    required this.topCarpenters,
    this.currentUser,
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
    if (topCarpenters.isEmpty) {
      return const SizedBox.shrink();
    }

    final top10 = topCarpenters.take(10).toList();
    final top3 = top10.take(3).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '🏆 Top 3 Carpenters',
          style: TextStyle(
            color: AppColors.lightSecondary,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 20),

        // Podium Display - Top 3
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            // Rank 2 - Left
            if (top3.length > 1) _buildPodiumCard(top3[1], 2),

            // Rank 1 - Center (tallest)
            if (top3.isNotEmpty) _buildPodiumCard(top3[0], 1),

            // Rank 3 - Right
            if (top3.length > 2) _buildPodiumCard(top3[2], 3),
          ],
        ),
      ],
    );
  }

  // Podium card for top 3
  Widget _buildPodiumCard(CarpenterRank carpenter, int rank) {
    Color trophyColor;
    double podiumHeight;

    switch (rank) {
      case 1:
        trophyColor = Colors.amber;
        podiumHeight = 120;
        break;
      case 2:
        trophyColor = Colors.grey.shade400;
        podiumHeight = 100;
        break;
      default:
        trophyColor = Colors.brown.shade400;
        podiumHeight = 80;
    }

    final isCurrentUser =
        currentUser != null && carpenter.userId == currentUser!.userId;

    return Expanded(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Trophy icon and rank
          Icon(
            Icons.emoji_events,
            size: rank == 1 ? 50 : 40,
            color: trophyColor,
          ),
          const SizedBox(height: 4),

          // Initials only (no profile images)
          CircleAvatar(
            radius: rank == 1 ? 35 : 30,
            backgroundColor: isCurrentUser
                ? AppColors.white
                : trophyColor.withValues(alpha: 0.2),
            child: Text(
              _getInitials(carpenter.name),
              style: TextStyle(
                fontSize: rank == 1 ? 20 : 16,
                fontWeight: FontWeight.bold,
                color: trophyColor,
              ),
            ),
          ),
          const SizedBox(height: 8),

          // Name
          Text(
            carpenter.name,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: rank == 1 ? 14 : 12,
              fontWeight: FontWeight.bold,
              color: isCurrentUser ? Colors.blue.shade700 : AppColors.black87,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),

          // Points
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.monetization_on, color: trophyColor, size: 16),
              const SizedBox(width: 2),
              Text(
                _formatPoints(carpenter.points),
                style: TextStyle(
                  fontSize: rank == 1 ? 14 : 12,
                  fontWeight: FontWeight.bold,
                  color: trophyColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Podium
          Container(
            height: podiumHeight,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  trophyColor.withValues(alpha: 0.7),
                  trophyColor.withValues(alpha: 0.5),
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(8),
              ),
              border: Border.all(color: trophyColor, width: 2),
            ),
            child: Center(
              child: Text(
                '#$rank',
                style: TextStyle(
                  fontSize: rank == 1 ? 32 : 24,
                  fontWeight: FontWeight.bold,
                  color: AppColors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // List item for all ranks 1-10
  String _formatPoints(int points) {
    if (points >= 1000) {
      return '${(points / 1000).toStringAsFixed(1)}K';
    }
    return points.toString();
  }
}

class CarpenterRank {
  final int rank;
  final String name;
  final int points;
  final String? imageUrl;
  final String? userId;
  final bool isCurrentUser;

  CarpenterRank({
    required this.rank,
    required this.name,
    required this.points,
    this.imageUrl,
    this.userId,
    this.isCurrentUser = false,
  });
}
