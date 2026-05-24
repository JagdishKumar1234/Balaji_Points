import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:balaji_points/core/design/app_colors.dart';
import 'package:balaji_points/core/layout/carpenter_shell_layout.dart';
import 'package:balaji_points/core/mixins/double_tap_exit_mixin.dart';
import 'package:balaji_points/presentation/widgets/carpenter/carpenter_bottom_nav_bar.dart';
import 'package:balaji_points/services/auth/session_service.dart';
import 'package:balaji_points/core/logger.dart';

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
      case 0: GoRouter.of(context).go('/');
      case 1: GoRouter.of(context).go('/wallet');
      case 2: GoRouter.of(context).go('/notifications');
      case 3: GoRouter.of(context).go('/profile');
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final mq = MediaQuery.of(context);

    // Resolve role — show content immediately; nav bar appears once role is known
    final roleAsync = ref.watch(_roleProvider);
    final role = roleAsync.asData?.value;
    final isAdmin = role == 'admin';
    final showNav = roleAsync.hasValue && !isAdmin;

    // Apply light-mode canvas override (matches fintech premium feel)
    final shellTheme = isDark
        ? theme
        : theme.copyWith(
            scaffoldBackgroundColor: AppColors.carpenterAppBackground,
            colorScheme: theme.colorScheme.copyWith(
              surface: AppColors.carpenterAppBackground,
            ),
            appBarTheme: theme.appBarTheme.copyWith(
              backgroundColor: AppColors.carpenterAppBackground,
              surfaceTintColor: Colors.transparent,
            ),
          );

    // Active tab index from current route
    final path = GoRouterState.of(context).uri.path;
    final tabIndex = path.startsWith('/wallet')
        ? 1
        : path.startsWith('/notifications')
            ? 2
            : path.startsWith('/profile')
                ? 3
                : 0;

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
              body: Stack(
                children: [
                  // ── Page content with bottom padding so it clears the nav bar ──
                  Padding(
                    padding: EdgeInsets.only(
                      bottom: showNav ? bottomChromeHeight : 0,
                    ),
                    child: widget.child ?? const SizedBox.shrink(),
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
                      ),
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
