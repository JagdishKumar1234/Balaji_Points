import 'package:flutter/material.dart';
import 'package:balaji_points/presentation/widgets/shared/app_loader.dart';
import 'package:balaji_points/l10n/app_localizations.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:go_router/go_router.dart';
import 'package:balaji_points/core/design/app_radius.dart';
import 'package:balaji_points/core/design/app_colors.dart';
import 'package:balaji_points/core/design/app_typography.dart';
import 'package:intl/intl.dart';

class UserListItem extends StatelessWidget {
  final String userId;
  final Map<String, dynamic> userData;

  const UserListItem({required this.userId, required this.userData, super.key});

  Color _getTierColor(String tier) {
    switch (tier.toLowerCase()) {
      case 'platinum':
        return AppColors.tierPlatinum;
      case 'gold':
        return AppColors.tierGold;
      case 'silver':
        return AppColors.tierSilver;
      case 'bronze':
        return AppColors.tierBronze;
      default:
        return AppColors.textSecondary;
    }
  }

  @override
  Widget build(BuildContext context) {
    final firstName = userData['firstName'] ?? '';
    final lastName = userData['lastName'] ?? '';
    final phone = userData['phone'] ?? '';
    final totalPoints = userData['totalPoints'] ?? 0;
    final tier = userData['tier'] ?? 'Bronze';
    final profileImage = userData['profileImage'] ?? '';
    final createdAt = userData['createdAt'] is Timestamp
        ? (userData['createdAt'] as Timestamp).toDate()
        : (userData['createdAt'] is DateTime
              ? userData['createdAt'] as DateTime
              : null);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: AppRadius.all16,
        side: BorderSide(color: context.themeBorder, width: 1),
      ),
      child: InkWell(
        onTap: () {
          context.push('/admin/carpenter-profile/$userId');
        },
        borderRadius: AppRadius.all16,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              // Top Row: Rank, Profile, Name, Actions
              Row(
                children: [
                  // Profile Image
                  ClipOval(
                    child: profileImage.isNotEmpty
                        ? Image.network(
                            profileImage,
                            width: 48,
                            height: 48,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return Container(
                                width: 48,
                                height: 48,
                                color: context.themeContentColor.withValues(
                                  alpha: 0.1,
                                ),
                                child: Icon(
                                  Icons.person_rounded,
                                  size: 24,
                                  color: context.themeContentColor,
                                ),
                              );
                            },
                            loadingBuilder: (context, child, loadingProgress) {
                              if (loadingProgress == null) return child;
                              return Container(
                                width: 48,
                                height: 48,
                                color: context.themeContentColor.withValues(
                                  alpha: 0.1,
                                ),
                                child: Center(
                                  child: AppLoader(
                                    color: context.themePrimary,
                                    strokeWidth: 2,
                                  ),
                                ),
                              );
                            },
                          )
                        : Container(
                            width: 48,
                            height: 48,
                            color: context.themeContentColor.withValues(
                              alpha: 0.1,
                            ),
                            child: Icon(
                              Icons.person_rounded,
                              size: 24,
                              color: context.themeContentColor,
                            ),
                          ),
                  ),
                  const SizedBox(width: 12),
                  // User Name
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '$firstName $lastName',
                          style: AppTypography.labelLarge().copyWith(
                            fontSize: 16,
                            color: context.themeContentColor,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          phone,
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
              const SizedBox(height: 12),
              // Bottom Row: Tier, Points, Joined Date
              Row(
                children: [
                  // Tier Badge
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: _getTierColor(tier),
                      borderRadius: AppRadius.sm8,
                    ),
                    child: Text(
                      tier,
                      style: AppTypography.labelLarge().copyWith(
                        fontSize: 12,
                        color: AppColors.white,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Points
                  Flexible(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.stars_rounded,
                          size: 16,
                          color: context.themeContentColor,
                        ),
                        const SizedBox(width: 4),
                        Flexible(
                          child: Text(
                            AppLocalizations.of(context)!.points2(
                              '${(totalPoints as num).toStringAsFixed(2)}',
                            ),
                            style: AppTypography.labelLarge().copyWith(
                              fontSize: 14,
                              color: context.themeContentColor,
                            ),
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Joined Date
                  if (createdAt != null)
                    Flexible(
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.calendar_today_rounded,
                            size: 14,
                            color: context.themeTextSecondary,
                          ),
                          const SizedBox(width: 4),
                          Flexible(
                            child: Text(
                              DateFormat('dd MMM yyyy').format(createdAt),
                              style: AppTypography.bodyMedium().copyWith(
                                fontSize: 12,
                                color: context.themeTextSecondary,
                              ),
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
