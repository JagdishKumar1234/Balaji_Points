import 'package:flutter/material.dart';
import 'package:balaji_points/l10n/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:balaji_points/core/layout/carpenter_shell_layout.dart';
import 'package:balaji_points/core/layout/responsive.dart';
import 'package:balaji_points/core/mixins/double_tap_exit_mixin.dart';
import 'package:balaji_points/presentation/widgets/carpenter/carpenter_bottom_nav_bar.dart';
import 'package:balaji_points/presentation/widgets/shared/responsive_role_navigation.dart';
import 'package:balaji_points/services/auth/session_service.dart';
import 'package:balaji_points/core/logger.dart';
import 'package:balaji_points/providers/branch_celebration_provider.dart';

// ---------------------------------------------------------------------------
// Role provider — cached so DashboardPage never hits SharedPreferences twice
// ---------------------------------------------------------------------------

final _roleProvider = FutureProvider<String?>((ref) async {
  final role = await SessionService().getUserRole();
  AppLogger.nav('Dashboard role=$role');
  return role?.trim().toLowerCase();
});

// ---------------------------------------------------------------------------
// Dashboard shell — persistent bottom nav + child router outlet
// ---------------------------------------------------------------------------

class DashboardPage extends ConsumerStatefulWidget {
  final Widget? child;
  const DashboardPage({super.key, this.child});

  @override
  ConsumerState<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends ConsumerState<DashboardPage>
    with DoubleTapExitMixin {
  void _onTabTapped(int index) {
    switch (index) {
      case 0:
        GoRouter.of(context).go('/');
      case 1:
        GoRouter.of(context).go('/wallet');
      case 2:
        GoRouter.of(context).go('/notifications');
      case 3:
        GoRouter.of(context).go('/profile');
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final mq = MediaQuery.of(context);

    // Resolve role — show content immediately; nav bar appears once role is known
    final roleAsync = ref.watch(_roleProvider);
    final role = roleAsync.asData?.value;
    final celebrationAsync = ref.watch(branchCelebrationEnabledProvider);
    final celebrationEnabled = celebrationAsync.asData?.value ?? false;
    final showAddBill = !celebrationEnabled;
    final isAdmin = role == 'admin';
    final showNav = roleAsync.hasValue && !isAdmin && !context.isWideScreen;

    // The app theme already matches the UI spec (grey canvas, white cards),
    // so the shell no longer overrides surface colours.
    final shellTheme = theme;

    // Active tab index from current route
    final path = GoRouterState.of(context).uri.path;
    final tabIndex = path.startsWith('/wallet')
        ? 1
        : path.startsWith('/notifications')
        ? 2
        : path.startsWith('/profile')
        ? 3
        : 0;

    final navItems = <RoleNavigationItem>[
      RoleNavigationItem(
        label: AppLocalizations.of(context)!.dashboard,
        icon: Icons.home_outlined,
        selectedIcon: Icons.home_rounded,
      ),
      RoleNavigationItem(
        label: AppLocalizations.of(context)!.wallet,
        icon: Icons.account_balance_wallet_outlined,
        selectedIcon: Icons.account_balance_wallet_rounded,
      ),
      if (showAddBill)
        RoleNavigationItem(
          label: AppLocalizations.of(context)!.addBill,
          icon: Icons.add_circle_outline_rounded,
          selectedIcon: Icons.add_circle_rounded,
        ),
      RoleNavigationItem(
        label: AppLocalizations.of(context)!.notifications,
        icon: Icons.notifications_outlined,
        selectedIcon: Icons.notifications_rounded,
      ),
      RoleNavigationItem(
        label: AppLocalizations.of(context)!.profile,
        icon: Icons.person_outline_rounded,
        selectedIcon: Icons.person_rounded,
      ),
    ];
    final navPaths = <String>[
      '/',
      '/wallet',
      if (showAddBill) '/add-bill',
      '/notifications',
      '/profile',
    ];
    final selectedPath = switch (path) {
      final value when value.startsWith('/wallet') => '/wallet',
      final value when value.startsWith('/add-bill') && showAddBill =>
        '/add-bill',
      final value when value.startsWith('/notifications') => '/notifications',
      final value when value.startsWith('/profile') => '/profile',
      _ => '/',
    };

    final bottomChromeHeight = CarpenterShellLayout.chromeHeight(mq);

    return Theme(
      data: shellTheme,
      child: Builder(
        builder: (ctx) {
          final t = Theme.of(ctx);
          return PopScope(
            canPop: false,
            onPopInvokedWithResult: (didPop, _) async {
              if (!didPop) {
                if (Navigator.of(ctx).canPop()) {
                  Navigator.of(ctx).pop();
                  return;
                }
                await handleDoubleTapExit();
              }
            },
            child: Scaffold(
              backgroundColor: t.scaffoldBackgroundColor,
              body: ResponsiveRoleNavigation(
                roleLabel:
                    role?.replaceAll('_', ' ') ??
                    AppLocalizations.of(context)!.member,
                selectedIndex: navPaths.indexOf(selectedPath),
                items: navItems,
                onSelected: (index) => GoRouter.of(context).go(navPaths[index]),
                child: Stack(
                  children: [
                    // ── Page content with bottom padding so it clears the nav bar ──
                    Padding(
                      padding: EdgeInsets.only(
                        bottom: showNav ? bottomChromeHeight : 0,
                      ),
                      // Carpenter screens are phone-designed: on tablet /
                      // web keep them at a readable width, centred.
                      child: !isAdmin && !context.windowSize.isCompact
                          ? ColoredBox(
                              color: t.scaffoldBackgroundColor,
                              child: ReadableWidth(
                                child: widget.child ?? const SizedBox.shrink(),
                              ),
                            )
                          : widget.child ?? const SizedBox.shrink(),
                    ),

                    // ── Bottom nav bar ──
                    if (showNav)
                      Align(
                        alignment: Alignment.bottomCenter,
                        child: CarpenterBottomNavBar.fromContext(
                          ctx,
                          currentIndex: tabIndex,
                          onTabSelected: _onTabTapped,
                          onAddBillTap: () => context.push('/add-bill'),
                          showAddBill: showAddBill,
                        ),
                      ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
