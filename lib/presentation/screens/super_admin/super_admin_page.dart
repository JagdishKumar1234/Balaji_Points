import 'package:balaji_points/services/platform/enquiry_service.dart';
import 'package:balaji_points/presentation/widgets/admin/enquiries_management.dart';
import 'package:flutter/material.dart';
import 'package:balaji_points/presentation/widgets/admin/catalogs_management.dart';
import 'package:flutter/services.dart';
import 'package:balaji_points/l10n/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:balaji_points/core/design/app_colors.dart';
import 'package:balaji_points/core/design/app_spacing.dart';
import 'package:balaji_points/core/design/app_typography.dart';
import 'package:balaji_points/core/mixins/double_tap_exit_mixin.dart';
import 'package:balaji_points/providers/theme_provider.dart';
import 'package:balaji_points/providers/loading_provider.dart';
import 'package:balaji_points/core/layout/responsive.dart';
import 'package:balaji_points/presentation/widgets/shared/responsive_role_navigation.dart';
import 'package:balaji_points/presentation/screens/super_admin/super_admin_branches_tab.dart';
import 'package:balaji_points/presentation/screens/super_admin/super_admin_create_admin_tab.dart';
import 'package:balaji_points/presentation/screens/super_admin/super_admin_points_cleanup_tab.dart';
import 'package:balaji_points/presentation/screens/super_admin/super_admin_roles_tab.dart';
import 'package:balaji_points/services/auth/session_service.dart';
import 'package:firebase_auth/firebase_auth.dart';

class SuperAdminPage extends ConsumerStatefulWidget {
  const SuperAdminPage({super.key});

  @override
  ConsumerState<SuperAdminPage> createState() => _SuperAdminPageState();
}

class _SuperAdminPageState extends ConsumerState<SuperAdminPage>
    with DoubleTapExitMixin {
  int _tab = 0; // branches, create admin, points reset, roles

  @override
  void initState() {
    super.initState();
    // Load guest enquiries in the background so the tab opens with the list
    // already there (kept for the session, live updates after that).
    ref.listenManual(enquiriesProvider(null), (_, __) {});
  }

  Future<void> _logout() async {
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        icon: const Icon(Icons.logout_rounded),
        title: Text(l10n.logout),
        content: Text(l10n.signOutOfSuperAdmin),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            style: FilledButton.styleFrom(
              backgroundColor: context.themeError,
              foregroundColor: context.themeOnError,
            ),
            child: Text(l10n.logout),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    ref.read(loadingProvider.notifier).start();
    try {
      await FirebaseAuth.instance.signOut();
      await SessionService().clearSession();
      if (mounted) context.go('/login');
    } finally {
      if (mounted) {
        ref.read(loadingProvider.notifier).stop();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final compactTitle = context.screenWidth < 420;
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) async {
        if (!didPop) await handleDoubleTapExit();
      },
      child: Scaffold(
        backgroundColor: context.themeBackground,
        appBar: AppBar(
          // Brand navy in light AND dark (themePrimary turns blue in dark).
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.white,
          systemOverlayStyle: SystemUiOverlayStyle.light,
          iconTheme: const IconThemeData(color: AppColors.white),
          actionsIconTheme: const IconThemeData(color: AppColors.white),
          shape: const Border(),
          elevation: 0,
          title: Row(
            children: [
              const Icon(Icons.admin_panel_settings_rounded, size: 24),
              const SizedBox(width: 10),
              Flexible(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      compactTitle
                          ? AppLocalizations.of(context)!.superAdmin
                          : AppLocalizations.of(context)!.superAdminConsole,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.h5(color: AppColors.white),
                    ),
                    if (!compactTitle)
                      Text(
                        AppLocalizations.of(
                          context,
                        )!.branchesAdministratorsAndPoints,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.caption(
                          color: AppColors.onPrimaryMuted,
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            _ThemeToggleButton(),
            IconButton(
              icon: const Icon(Icons.logout_rounded),
              tooltip: AppLocalizations.of(context)!.logout,
              onPressed: _logout,
            ),
          ],
        ),
        // Phones / small tablets: Material 3 navigation bar (labels, focus,
        // screen-reader states). Wide screens use the navy side rail.
        bottomNavigationBar: context.isWideScreen
            ? null
            : NavigationBar(
                selectedIndex: _tab,
                onDestinationSelected: (index) => setState(() => _tab = index),
                destinations: [
                  NavigationDestination(
                    icon: const Icon(Icons.store_outlined),
                    selectedIcon: const Icon(Icons.store_rounded),
                    label: AppLocalizations.of(context)!.branches,
                  ),
                  NavigationDestination(
                    icon: const Icon(Icons.manage_accounts_outlined),
                    selectedIcon: const Icon(Icons.manage_accounts_rounded),
                    label: AppLocalizations.of(context)!.adminsNav,
                  ),
                  NavigationDestination(
                    icon: const Icon(Icons.cleaning_services_outlined),
                    selectedIcon: const Icon(Icons.cleaning_services_rounded),
                    label: AppLocalizations.of(context)!.pointsLabel,
                  ),
                  NavigationDestination(
                    icon: const Icon(Icons.badge_outlined),
                    selectedIcon: const Icon(Icons.badge_rounded),
                    label: AppLocalizations.of(context)!.roles,
                  ),
                  NavigationDestination(
                    icon: const Icon(Icons.menu_book_outlined),
                    selectedIcon: const Icon(Icons.menu_book_rounded),
                    label: AppLocalizations.of(context)!.catalogs,
                  ),
                  NavigationDestination(
                    icon: const Icon(Icons.mark_email_unread_outlined),
                    selectedIcon: const Icon(Icons.mark_email_unread_rounded),
                    label: AppLocalizations.of(context)!.guestEnquiries,
                  ),
                ],
              ),
        body: ResponsiveRoleNavigation(
          roleLabel: AppLocalizations.of(context)!.superAdmin2,
          items: [
            RoleNavigationItem(
              label: AppLocalizations.of(context)!.branches,
              icon: Icons.store_outlined,
              selectedIcon: Icons.store_rounded,
            ),
            RoleNavigationItem(
              label: AppLocalizations.of(context)!.adminsNav,
              icon: Icons.manage_accounts_outlined,
              selectedIcon: Icons.manage_accounts_rounded,
            ),
            RoleNavigationItem(
              label: AppLocalizations.of(context)!.pointsLabel,
              icon: Icons.cleaning_services_outlined,
              selectedIcon: Icons.cleaning_services_rounded,
            ),
            RoleNavigationItem(
              label: AppLocalizations.of(context)!.roles,
              icon: Icons.badge_outlined,
              selectedIcon: Icons.badge_rounded,
            ),
            RoleNavigationItem(
              label: AppLocalizations.of(context)!.catalogs,
              icon: Icons.menu_book_outlined,
              selectedIcon: Icons.menu_book_rounded,
            ),
            RoleNavigationItem(
              label: AppLocalizations.of(context)!.guestEnquiries,
              icon: Icons.mark_email_unread_outlined,
              selectedIcon: Icons.mark_email_unread_rounded,
            ),
          ],
          selectedIndex: _tab,
          onSelected: (index) => setState(() => _tab = index),
          onLogout: _logout,
          child: ResponsiveContainer(
            maxWidth: 1200,
            alignment: Alignment.topCenter,
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg,
              AppSpacing.lg,
              AppSpacing.lg,
              0,
            ),
            child: switch (_tab) {
              0 => const SuperAdminBranchesTab(),
              1 => const SuperAdminCreateAdminTab(),
              2 => const SuperAdminPointsCleanupTab(),
              3 => const SuperAdminRolesTab(),
              4 => const CatalogsManagement(),
              // Guest enquiries only (no branch). Members' enquiries go to
              // their own branch admin, not here.
              _ => const EnquiriesManagement(),
            },
          ),
        ),
      ),
    );
  }
}

// ── Theme toggle ───────────────────────────────────────────────────────────────

class _ThemeToggleButton extends ConsumerWidget {
  const _ThemeToggleButton();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return IconButton(
      tooltip: isDark
          ? AppLocalizations.of(context)!.switchToLight
          : AppLocalizations.of(context)!.switchToDark,
      onPressed: () => ref.read(themeModeProvider.notifier).toggleTheme(),
      icon: AnimatedSwitcher(
        duration: const Duration(milliseconds: 250),
        transitionBuilder: (child, anim) =>
            RotationTransition(turns: anim, child: child),
        child: Icon(
          isDark ? Icons.wb_sunny_rounded : Icons.nightlight_round_rounded,
          key: ValueKey(isDark),
          color: AppColors.white,
        ),
      ),
    );
  }
}
