import 'package:balaji_points/core/design/app_colors.dart';
import 'dart:math' as math;
import 'package:flutter/material.dart';

class UserProfileCard extends StatefulWidget {
  final String userName;
  final String? userImageUrl;
  final int totalPoints;
  final String tier;

  const UserProfileCard({
    super.key,
    required this.userName,
    this.userImageUrl,
    required this.totalPoints,
    this.tier = 'Silver',
  });

  @override
  State<UserProfileCard> createState() => _UserProfileCardState();
}

class _UserProfileCardState extends State<UserProfileCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _coinController;
  late Animation<double> _coinAnimation;

  @override
  void initState() {
    super.initState();
    _coinController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();

    _coinAnimation = Tween<double>(
      begin: 0,
      end: 2 * math.pi,
    ).animate(CurvedAnimation(parent: _coinController, curve: Curves.linear));
  }

  /// Check if URL is valid for NetworkImage (http or https)
  bool _isValidImageUrl(String? url) {
    if (url == null || url.isEmpty) return false;
    final trimmed = url.trim();
    return trimmed.startsWith('http://') || trimmed.startsWith('https://');
  }

  @override
  void dispose() {
    _coinController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          // Profile Avatar
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.white, width: 2),
              boxShadow: [
                BoxShadow(
                  color: AppColors.black.withValues(alpha: 0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: CircleAvatar(
              radius: 24,
              backgroundColor: AppColors.white,
              backgroundImage: _isValidImageUrl(widget.userImageUrl)
                  ? NetworkImage(widget.userImageUrl!)
                  : null,
              child: !_isValidImageUrl(widget.userImageUrl)
                  ? Icon(Icons.person, size: 28, color: context.themeSecondary)
                  : null,
            ),
          ),
          const SizedBox(width: 12),

          // User Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  widget.userName,
                  style: const TextStyle(fontFamily: 'Nunito', fontWeight: FontWeight.w700).copyWith(
                    color: AppColors.white,
                    fontSize: 16,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(Icons.star, color: AppColors.warning, size: 14),
                    const SizedBox(width: 4),
                    Text(
                      '${widget.tier} Tier',
                      style: const TextStyle(fontFamily: 'Nunito', fontWeight: FontWeight.w500).copyWith(
                        color: AppColors.white.withValues(alpha: 0.9),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Points Display with Animation
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: AppColors.white.withValues(alpha: 0.3),
                width: 1,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Animated Coin Icon
                AnimatedBuilder(
                  animation: _coinAnimation,
                  builder: (context, child) {
                    return Transform.rotate(
                      angle: _coinAnimation.value,
                      child: Icon(
                        Icons.monetization_on,
                        color: AppColors.warning,
                        size: 20,
                      ),
                    );
                  },
                ),
                const SizedBox(width: 6),
                // Points Text
                Text(
                  _formatPoints(widget.totalPoints),
                  style: const TextStyle(fontFamily: 'Nunito', fontWeight: FontWeight.w700).copyWith(
                    color: AppColors.white,
                    fontSize: 18,
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
