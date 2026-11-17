import 'package:flutter/material.dart';

import 'package:balaji_points/core/design/app_colors.dart';
import 'package:balaji_points/core/design/app_radius.dart';
import 'package:balaji_points/core/design/app_typography.dart';
import 'package:balaji_points/core/notifications/notification_category.dart';
import 'package:balaji_points/l10n/app_localizations.dart';

/// One notification card: category icon and tag, title, message, time, and
/// a short "Open …" link when a tap leads somewhere.
class NotificationTile extends StatelessWidget {
  const NotificationTile({
    super.key,
    required this.category,
    required this.type,
    required this.title,
    required this.body,
    required this.time,
    required this.onTap,
  });

  final NotificationCategory category;
  final String? type;
  final String title;
  final String body;
  final String time;
  final VoidCallback onTap;

  /// Soft background and ink for the icon and tag. Navy for most, gold for
  /// rewards, green/red only for an approved/rejected bill.
  (Color, Color) _tone(BuildContext context) {
    if (type == 'billApproved' || type == 'accountApproved') {
      return (context.themeSuccessSoft, context.themeSuccessText);
    }
    if (type == 'billRejected') {
      return (context.themeErrorSoft, context.themeErrorText);
    }
    switch (category) {
      case NotificationCategory.offer:
      case NotificationCategory.festival:
      case NotificationCategory.dailySpin:
      case NotificationCategory.points:
        return (context.themeGoldSoft, context.themePendingText);
      default:
        return (context.themePrimarySoft, context.themePrimaryLight);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final (soft, ink) = _tone(context);
    final action = category.action(l10n);
    final isAnnouncement = type == 'announcement' || type == 'greeting';

    return Material(
      color: context.themeCard,
      borderRadius: AppRadius.all16,
      child: InkWell(
        onTap: onTap,
        borderRadius: AppRadius.all16,
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: AppRadius.all16,
            border: Border.all(
              color: isAnnouncement
                  ? context.themeGold.withValues(alpha: 0.55)
                  : context.themeBorder,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    color: soft,
                    borderRadius: AppRadius.md12,
                  ),
                  child: Icon(category.icon, color: ink, size: 24),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: soft,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                category.label(l10n),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: AppTypography.bodySmall().copyWith(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: ink,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Spacer(),
                          Text(
                            time,
                            style: AppTypography.bodySmall().copyWith(
                              fontSize: 12,
                              color: context.themeTextMuted,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        title,
                        style: AppTypography.buttonMedium().copyWith(
                          fontSize: 15,
                          color: context.themeTextPrimary,
                        ),
                      ),
                      if (body.isNotEmpty) ...[
                        const SizedBox(height: 3),
                        Text(
                          body,
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                          style: AppTypography.bodyMedium().copyWith(
                            fontSize: 13,
                            height: 1.35,
                            color: context.themeTextSecondary,
                          ),
                        ),
                      ],
                      if (action != null) ...[
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Text(
                              action,
                              style: AppTypography.bodySmall().copyWith(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: context.themePrimaryLight,
                              ),
                            ),
                            const SizedBox(width: 2),
                            Icon(
                              Icons.chevron_right_rounded,
                              size: 18,
                              color: context.themePrimaryLight,
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
