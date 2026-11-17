import 'package:balaji_points/core/design/app_colors.dart';
import 'package:balaji_points/core/design/app_radius.dart';
import 'package:balaji_points/core/design/app_typography.dart';
import 'package:balaji_points/l10n/app_localizations.dart';
import 'package:balaji_points/providers/theme_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// The admin "More" tab: every section that is not a tab of its own, then
/// the app settings (theme) and Logout. Theme and logout live only here.
class AdminMorePage extends ConsumerWidget {
  const AdminMorePage({
    super.key,
    required this.onOpenSection,
    required this.onLogout,
    this.alertsBadge = 0,
    this.enquiriesBadge = 0,
  });

  final void Function(String section) onOpenSection;
  final VoidCallback onLogout;
  final int alertsBadge;
  final int enquiriesBadge;

  /// Section ids shown here, in order (ids as in admin_home_page.dart).
  static const sections = [
    'notifications',
    'broadcast',
    'greeting',
    'offers',
    'catalogs',
    'enquiries',
    'spin',
  ];

  static IconData iconOf(String id) => switch (id) {
    'notifications' => Icons.notifications_rounded,
    'broadcast' => Icons.campaign_rounded,
    'greeting' => Icons.celebration_rounded,
    'offers' => Icons.local_offer_rounded,
    'catalogs' => Icons.menu_book_rounded,
    'enquiries' => Icons.mark_email_unread_rounded,
    _ => Icons.casino_rounded,
  };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    String label(String id) => switch (id) {
      'notifications' => l10n.notifications,
      'broadcast' => l10n.sendNotification,
      'greeting' => l10n.sendGreeting,
      'offers' => l10n.offers,
      'catalogs' => l10n.catalogs,
      'enquiries' => l10n.enquiries,
      _ => l10n.spin,
    };
    String desc(String id) => switch (id) {
      'notifications' => l10n.adminDescNotifications,
      'broadcast' => l10n.adminDescBroadcast,
      'greeting' => l10n.adminDescGreeting,
      'offers' => l10n.adminDescOffers,
      'catalogs' => l10n.adminDescCatalogs,
      'enquiries' => l10n.adminDescEnquiries,
      _ => l10n.adminDescSpin,
    };
    int badge(String id) => switch (id) {
      'notifications' => alertsBadge,
      'enquiries' => enquiriesBadge,
      _ => 0,
    };

    return ColoredBox(
      color: context.themeBackground,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        children: [
          _Group(
            children: [
              for (final id in sections)
                _Row(
                  icon: iconOf(id),
                  title: label(id),
                  subtitle: desc(id),
                  badge: badge(id),
                  onTap: () => onOpenSection(id),
                ),
            ],
          ),
          const SizedBox(height: 16),
          _Group(
            children: [
              _Row(
                icon: isDark
                    ? Icons.wb_sunny_rounded
                    : Icons.nightlight_round_rounded,
                title: isDark ? l10n.switchToLight : l10n.switchToDark,
                onTap: () => ref.read(themeModeProvider.notifier).toggleTheme(),
                showChevron: false,
              ),
              _Row(
                icon: Icons.logout_rounded,
                title: l10n.logout,
                danger: true,
                onTap: onLogout,
                showChevron: false,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Group extends StatelessWidget {
  const _Group({required this.children});
  final List<Widget> children;

  @override
  Widget build(BuildContext context) => Material(
    color: context.themeCard,
    shape: RoundedRectangleBorder(
      borderRadius: AppRadius.all16,
      side: BorderSide(color: context.themeBorder),
    ),
    clipBehavior: Clip.antiAlias,
    child: Column(
      children: [
        for (var i = 0; i < children.length; i++) ...[
          if (i > 0)
            Divider(height: 1, indent: 70, color: context.themeDivider),
          children[i],
        ],
      ],
    ),
  );
}

class _Row extends StatelessWidget {
  const _Row({
    required this.icon,
    required this.title,
    required this.onTap,
    this.subtitle,
    this.badge = 0,
    this.danger = false,
    this.showChevron = true,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final int badge;
  final bool danger;
  final bool showChevron;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final squareColor = danger
        ? context.themeErrorSoft
        : context.isDarkMode
        ? AppColors.primaryOnDark.withValues(alpha: 0.28)
        : AppColors.primary;
    final iconColor = danger ? context.themeErrorText : AppColors.gold;
    return Semantics(
      button: true,
      label: badge > 0 ? '$title, $badge' : title,
      excludeSemantics: true,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 12, 10, 12),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: squareColor,
                  borderRadius: AppRadius.md12,
                ),
                child: Icon(icon, size: 22, color: iconColor),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: AppTypography.label(
                        color: danger
                            ? context.themeErrorText
                            : context.themeContentColor,
                      ).copyWith(fontSize: 14),
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        subtitle!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.caption(
                          color: context.themeTextSecondary,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              if (badge > 0)
                Container(
                  constraints: const BoxConstraints(minWidth: 24),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 7,
                    vertical: 2,
                  ),
                  decoration: const BoxDecoration(
                    color: AppColors.gold,
                    borderRadius: AppRadius.pill,
                  ),
                  child: Text(
                    '$badge',
                    textAlign: TextAlign.center,
                    style: AppTypography.labelSmall(color: AppColors.primary),
                  ),
                ),
              if (showChevron)
                Icon(
                  Icons.chevron_right_rounded,
                  color: context.themeTextMuted,
                ),
            ],
          ),
        ),
      ),
    );
  }
}
