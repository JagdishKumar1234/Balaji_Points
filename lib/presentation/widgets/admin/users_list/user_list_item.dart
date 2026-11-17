import 'package:balaji_points/core/constants/app_constants.dart';
import 'package:balaji_points/core/utils/points_utils.dart';
import 'package:balaji_points/presentation/widgets/shared/role_label.dart';
import 'package:flutter/material.dart';
import 'package:balaji_points/l10n/app_localizations.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:go_router/go_router.dart';
import 'package:balaji_points/core/design/app_radius.dart';
import 'package:balaji_points/core/design/app_colors.dart';
import 'package:balaji_points/core/design/app_typography.dart';
import 'package:intl/intl.dart';

/// Admin member card: photo or initials, name (phone when no name is
/// saved), role, phone, points, tier and join date. Every value fits on a
/// 360 px phone; long names shorten with "…".
class UserListItem extends StatelessWidget {
  final String userId;
  final Map<String, dynamic> userData;

  const UserListItem({required this.userId, required this.userData, super.key});

  static Color _tierColor(String tier) => switch (tier.toLowerCase()) {
    'platinum' => AppColors.tierPlatinum,
    'gold' => AppColors.tierGold,
    'silver' => AppColors.tierSilver,
    'bronze' => AppColors.tierBronze,
    _ => AppColors.textSecondary,
  };

  String get _roleId {
    final role = (userData['role'] as String? ?? '').trim().toLowerCase();
    return role.isEmpty ? AppConstants.roleCarpenter : role;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final firstName = (userData['firstName'] as String? ?? '').trim();
    final lastName = (userData['lastName'] as String? ?? '').trim();
    final phone = (userData['phone'] as String? ?? '').trim();
    final fullName = '$firstName $lastName'.trim();
    final title = fullName.isNotEmpty ? fullName : phone;
    final points = (userData['totalPoints'] as num?) ?? 0;
    final tier = (userData['tier'] as String?)?.trim().isNotEmpty == true
        ? userData['tier'] as String
        : 'Bronze';
    final profileImage = (userData['profileImage'] as String? ?? '').trim();
    final createdAt = userData['createdAt'] is Timestamp
        ? (userData['createdAt'] as Timestamp).toDate()
        : (userData['createdAt'] is DateTime
              ? userData['createdAt'] as DateTime
              : null);
    final initials = [
      if (firstName.isNotEmpty) firstName[0],
      if (lastName.isNotEmpty) lastName[0],
    ].join().toUpperCase();

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: context.themeCard,
        shape: RoundedRectangleBorder(
          borderRadius: AppRadius.all16,
          side: BorderSide(color: context.themeBorder),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () => context.push('/admin/carpenter-profile/$userId'),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(14, 14, 10, 12),
            child: Column(
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _Avatar(url: profileImage, initials: initials),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTypography.labelLarge().copyWith(
                              fontSize: 16,
                              color: context.themeTextPrimary,
                            ),
                          ),
                          const SizedBox(height: 4),
                          // Role of the member; old accounts with no role
                          // saved are carpenters.
                          RoleTag(
                            key: const ValueKey('user-role-tag'),
                            roleId: _roleId,
                            storedName: userData['roleName'] as String?,
                          ),
                          if (phone.isNotEmpty && fullName.isNotEmpty) ...[
                            const SizedBox(height: 6),
                            Row(
                              children: [
                                Icon(
                                  Icons.phone_rounded,
                                  size: 14,
                                  color: context.themeTextSecondary,
                                ),
                                const SizedBox(width: 4),
                                Flexible(
                                  child: Text(
                                    phone,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: AppTypography.bodyMedium().copyWith(
                                      fontSize: 13,
                                      color: context.themeTextSecondary,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Points stand out on the right.
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: context.themeGoldSoft,
                        borderRadius: AppRadius.md12,
                      ),
                      child: Column(
                        children: [
                          Text(
                            PointsUtils.formatPoints(points),
                            style: AppTypography.section(
                              color: context.themePendingText,
                            ),
                          ),
                          Text(
                            l10n.pointsLabel,
                            style: AppTypography.caption(
                              color: context.themePendingText,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Divider(height: 1, color: context.themeDivider),
                const SizedBox(height: 10),
                Row(
                  children: [
                    // Tier: a coloured dot keeps the label readable on any
                    // tier colour.
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        borderRadius: AppRadius.pill,
                        border: Border.all(color: context.themeBorder),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 10,
                            height: 10,
                            decoration: BoxDecoration(
                              color: _tierColor(tier),
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            tier,
                            style: AppTypography.labelSmall(
                              color: context.themeTextPrimary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 10),
                    if (createdAt != null)
                      Expanded(
                        child: Row(
                          children: [
                            Icon(
                              Icons.calendar_today_rounded,
                              size: 13,
                              color: context.themeTextSecondary,
                            ),
                            const SizedBox(width: 4),
                            Flexible(
                              child: Text(
                                DateFormat('dd MMM yyyy').format(createdAt),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: AppTypography.caption(
                                  color: context.themeTextSecondary,
                                ),
                              ),
                            ),
                          ],
                        ),
                      )
                    else
                      const Spacer(),
                    Icon(
                      Icons.chevron_right_rounded,
                      color: context.themeTextMuted,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Profile photo, or initials on navy (person icon when no name).
class _Avatar extends StatelessWidget {
  const _Avatar({required this.url, required this.initials});
  final String url;
  final String initials;

  @override
  Widget build(BuildContext context) {
    Widget fallback() => Container(
      width: 52,
      height: 52,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: AppColors.primary,
        shape: BoxShape.circle,
        border: Border.all(color: AppColors.gold, width: 1.5),
      ),
      child: initials.isEmpty
          ? const Icon(Icons.person_rounded, color: AppColors.gold, size: 26)
          : Text(
              initials,
              style: AppTypography.label(
                color: AppColors.gold,
              ).copyWith(fontSize: 17),
            ),
    );
    if (url.isEmpty) return fallback();
    return ClipOval(
      child: Image.network(
        url,
        width: 52,
        height: 52,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => fallback(),
        loadingBuilder: (context, child, progress) =>
            progress == null ? child : fallback(),
      ),
    );
  }
}
