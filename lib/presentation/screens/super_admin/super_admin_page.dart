import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:balaji_points/core/design/app_colors.dart';
import 'package:balaji_points/core/design/app_radius.dart';
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

  Future<void> _logout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: AppRadius.forCard),
        title: Text(
          'Logout',
          style: AppTypography.h5(color: context.themePrimary),
        ),
        content: Text(
          'Sign out of super admin?',
          style: AppTypography.bodyMedium(color: context.themeTextSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              'Cancel',
              style: AppTypography.labelLarge(
                color: context.themeTextSecondary,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: context.themeError,
              shape: RoundedRectangleBorder(borderRadius: AppRadius.forButton),
            ),
            child: Text(
              'Logout',
              style: AppTypography.labelLarge(color: AppColors.white),
            ),
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
          backgroundColor: context.themePrimary,
          foregroundColor: AppColors.white,
          elevation: 0,
          title: Row(
            children: [
              const Icon(Icons.admin_panel_settings_rounded, size: 24),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    compactTitle ? 'Super Admin' : 'Super Admin Console',
                    style: AppTypography.h5(color: AppColors.white),
                  ),
                  if (!compactTitle)
                    Text(
                      'Branches, administrators and points',
                      style: AppTypography.caption(
                        color: AppColors.white.withValues(alpha: 0.78),
                      ),
                    ),
                ],
              ),
            ],
          ),
          actions: [
            _ThemeToggleButton(),
            IconButton(
              icon: const Icon(Icons.logout),
              tooltip: 'Logout',
              onPressed: _logout,
            ),
          ],
          bottom: context.isWideScreen
              ? null
              : PreferredSize(
                  preferredSize: const Size.fromHeight(48),
                  child: Row(
                    children: [
                      _TabBtn(
                        label: 'Branches',
                        index: 0,
                        current: _tab,
                        onTap: () => setState(() => _tab = 0),
                      ),
                      _TabBtn(
                        label: 'Create Admin',
                        index: 1,
                        current: _tab,
                        onTap: () => setState(() => _tab = 1),
                      ),
                      _TabBtn(
                        label: 'Points',
                        index: 2,
                        current: _tab,
                        onTap: () => setState(() => _tab = 2),
                      ),
                      _TabBtn(
                        label: 'Roles',
                        index: 3,
                        current: _tab,
                        onTap: () => setState(() => _tab = 3),
                      ),
                    ],
                  ),
                ),
        ),
        body: ResponsiveRoleNavigation(
          roleLabel: 'Super admin',
          items: const [
            RoleNavigationItem(
              label: 'Branches',
              icon: Icons.store_outlined,
              selectedIcon: Icons.store_rounded,
            ),
            RoleNavigationItem(
              label: 'Create admin',
              icon: Icons.admin_panel_settings_outlined,
              selectedIcon: Icons.admin_panel_settings_rounded,
            ),
            RoleNavigationItem(
              label: 'Points reset',
              icon: Icons.cleaning_services_outlined,
              selectedIcon: Icons.cleaning_services_rounded,
            ),
            RoleNavigationItem(
              label: 'Roles',
              icon: Icons.badge_outlined,
              selectedIcon: Icons.badge_rounded,
            ),
          ],
          selectedIndex: _tab,
          onSelected: (index) => setState(() => _tab = index),
          onLogout: _logout,
          child: ResponsiveContainer(
            maxWidth: 1200,
            padding: const EdgeInsets.all(AppSpacing.md),
            child: switch (_tab) {
              0 => const SuperAdminBranchesTab(),
              1 => const SuperAdminCreateAdminTab(),
              2 => const SuperAdminPointsCleanupTab(),
              _ => const SuperAdminRolesTab(),
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
      tooltip: isDark ? 'Switch to Light' : 'Switch to Dark',
      onPressed: () => ref.read(themeModeProvider.notifier).toggleTheme(),
      icon: AnimatedSwitcher(
        duration: const Duration(milliseconds: 250),
        transitionBuilder: (child, anim) =>
            RotationTransition(turns: anim, child: child),
        child: Icon(
          isDark ? Icons.wb_sunny_rounded : Icons.nightlight_round,
          key: ValueKey(isDark),
          color: AppColors.white,
        ),
      ),
    );
  }
}

// ── Tab button ─────────────────────────────────────────────────────────────────

class _TabBtn extends StatelessWidget {
  final String label;
  final int index, current;
  final VoidCallback onTap;
  const _TabBtn({
    required this.label,
    required this.index,
    required this.current,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final active = index == current;
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          height: 48,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: active ? context.themeSecondary : AppColors.transparent,
                width: 3,
              ),
            ),
          ),
          child: Text(
            label,
            style: AppTypography.labelLarge(
              color: active
                  ? AppColors.white
                  : AppColors.white.withValues(alpha: 0.70),
            ),
          ),
        ),
      ),
    );
  }
}
