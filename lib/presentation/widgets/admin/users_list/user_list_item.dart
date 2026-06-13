import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:balaji_points/core/design/app_radius.dart';
import 'package:balaji_points/core/design/app_colors.dart';
import 'package:balaji_points/core/design/app_typography.dart';
import 'package:balaji_points/l10n/app_localizations.dart';
import 'package:intl/intl.dart';
import 'user_details_screen.dart';

class UserListItem extends StatelessWidget {
  final String userId;
  final Map<String, dynamic> userData;
  final VoidCallback onDeleted;

  const UserListItem({
    required this.userId,
    required this.userData,
    required this.onDeleted,
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

  Future<void> _deleteCarpenter(BuildContext context) async {
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Confirm Delete'),
            content: Text(l10n.deleteCarpenterWarning),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: Text(l10n.cancel),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: Text(l10n.delete),
                style: TextButton.styleFrom(
                  foregroundColor: context.themeError,
                ),
              ),
            ],
          ),
        ) ??
        false;

    if (!confirmed) return;

    if (!context.mounted) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(),
      ),
    );

    try {
      await FirebaseFirestore.instance.collection('users').doc(userId).delete();

      if (context.mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.carpenterDeletedSuccess),
            backgroundColor: AppColors.success,
            duration: const Duration(seconds: 2),
          ),
        );
        onDeleted();
      }
    } catch (e) {
      if (context.mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.failedToDeleteCarpenter),
            backgroundColor: context.themeError,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
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
          userData['userId'] = userId;
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => UserDetailsScreen(
                user: userData,
                onDelete: onDeleted,
              ),
            ),
          );
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
                                color: context.themeContentColor
                                    .withValues(alpha: 0.1),
                                child: Icon(
                                  Icons.person,
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
                                color: context.themeContentColor
                                    .withValues(alpha: 0.1),
                                child: Center(
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      context.themePrimary,
                                    ),
                                  ),
                                ),
                              );
                            },
                          )
                        : Container(
                            width: 48,
                            height: 48,
                            color: context.themeContentColor
                                .withValues(alpha: 0.1),
                            child: Icon(
                              Icons.person,
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
                  // Delete Button
                  OutlinedButton(
                    onPressed: () => _deleteCarpenter(context),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: context.themeError,
                      side: BorderSide(
                        color: context.themeError,
                        width: 1.5,
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      shape: RoundedRectangleBorder(
                        borderRadius: AppRadius.sm8,
                      ),
                    ),
                    child: Text(
                      l10n.delete,
                      style: AppTypography.labelLarge().copyWith(
                        fontSize: 13,
                        color: context.themeError,
                      ),
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
                        fontSize: 11,
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
                          Icons.stars,
                          size: 16,
                          color: context.themeContentColor,
                        ),
                        const SizedBox(width: 4),
                        Flexible(
                          child: Text(
                            '${(totalPoints as num).toStringAsFixed(2)} Points',
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
                            Icons.calendar_today,
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
