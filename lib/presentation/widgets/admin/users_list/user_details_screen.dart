import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:balaji_points/core/design/app_radius.dart';
import 'package:balaji_points/core/design/app_colors.dart';
import 'package:balaji_points/core/design/app_typography.dart';
import 'package:balaji_points/l10n/app_localizations.dart';
import 'package:balaji_points/presentation/widgets/shared/app_text.dart';

class UserDetailsScreen extends StatelessWidget {
  final Map<String, dynamic> user;
  final VoidCallback? onDelete;

  const UserDetailsScreen({
    required this.user,
    this.onDelete,
    super.key,
  });

  Color _getTierColor(String tier) {
    switch (tier.toLowerCase()) {
      case 'platinum':
        return const Color(0xFFE5E4E2);
      case 'gold':
        return const Color(0xFFFFD700);
      case 'silver':
        return const Color(0xFFC0C0C0);
      case 'bronze':
        return const Color(0xFFCD7F32);
      default:
        return AppColors.textSecondary;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final firstName = user['firstName'] ?? '';
    final lastName = user['lastName'] ?? '';
    final phone = user['phone'] ?? '';
    final totalPoints = user['totalPoints'] ?? 0;
    final tier = user['tier'] ?? 'Bronze';
    final profileImage = user['profileImage'] ?? '';

    return Scaffold(
      backgroundColor: context.themeBackground,
      resizeToAvoidBottomInset: false,
      body: Column(
        children: [
          // Header
          Container(
            padding: EdgeInsets.only(
              top: MediaQuery.of(context).padding.top + 8,
              bottom: 20,
              left: 20,
              right: 20,
            ),
            decoration: BoxDecoration(color: context.themeContentColor),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back, color: AppColors.white),
                  onPressed: () => Navigator.of(context).pop(),
                ),
                ClipOval(
                  child: profileImage.isNotEmpty
                      ? Image.network(
                          profileImage,
                          width: 60,
                          height: 60,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              width: 60,
                              height: 60,
                              color: AppColors.white.withValues(alpha: 0.20),
                              child: const Icon(
                                Icons.person,
                                size: 35,
                                color: AppColors.white,
                              ),
                            );
                          },
                        )
                      : Container(
                          width: 60,
                          height: 60,
                          color: AppColors.white.withValues(alpha: 0.20),
                          child: const Icon(
                            Icons.person,
                            size: 35,
                            color: AppColors.white,
                          ),
                        ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '$firstName $lastName',
                        style: AppTypography.labelLarge().copyWith(
                          fontSize: 20,
                          color: AppColors.white,
                        ),
                      ),
                      Text(
                        phone,
                        style: AppTypography.bodyMedium().copyWith(
                          fontSize: 14,
                          color: AppColors.white.withValues(alpha: 0.9),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // Content
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Points Summary Card
                  StreamBuilder<DocumentSnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('users')
                        .doc(user['userId'])
                        .snapshots(),
                    builder: (context, snapshot) {
                      double currentPoints = (totalPoints as num).toDouble();
                      String currentTier = tier;

                      if (snapshot.hasData && snapshot.data!.exists) {
                        final userData =
                            snapshot.data!.data() as Map<String, dynamic>;
                        currentPoints =
                            (userData['totalPoints'] as num?)?.toDouble() ??
                            currentPoints;
                        currentTier = userData['tier'] as String? ?? tier;
                      }

                      return Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: context.themeSoftSurface,
                          borderRadius: AppRadius.all16,
                          border: Border.all(color: context.themeBorder),
                        ),
                        child: Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.stars,
                                  size: 32,
                                  color: context.themeContentColor,
                                ),
                                const SizedBox(width: 12),
                                AppText.label(
                                  currentPoints.toStringAsFixed(2),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              l10n.totalPointsLabel,
                              style: AppTypography.bodyMedium().copyWith(
                                fontSize: 14,
                                color: context.themeTextSecondary,
                              ),
                            ),
                            const SizedBox(height: 16),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 20,
                                vertical: 10,
                              ),
                              decoration: BoxDecoration(
                                color: _getTierColor(currentTier),
                                borderRadius: AppRadius.md12,
                              ),
                              child: Text(
                                l10n.tierLabel(currentTier),
                                style: AppTypography.labelLarge().copyWith(
                                  fontSize: 16,
                                  color: AppColors.white,
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 24),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: context.themePrimary.withValues(alpha: 0.05),
                      borderRadius: AppRadius.md12,
                      border: Border.all(
                        color: context.themePrimary.withValues(alpha: 0.2),
                        width: 1,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.info_outline,
                              color: context.themeContentColor,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            AppText.label('Carpenter Information'),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Phone: $phone\nTier: $tier\nPoints: ${totalPoints.toString()}',
                          style: AppTypography.bodyMedium().copyWith(
                            fontSize: 13,
                            color: context.themeTextSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
