import 'package:balaji_points/core/layout/carpenter_shell_layout.dart';
import 'package:balaji_points/core/mixins/double_tap_exit_mixin.dart';
import 'package:balaji_points/core/theme/design_token.dart';
import 'package:balaji_points/presentation/widgets/carpenter/carpenter_bottom_nav_bar.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:balaji_points/services/session_service.dart';
import 'package:balaji_points/core/logger.dart';

class DashboardPage extends StatefulWidget {
  final Widget? child;

  const DashboardPage({super.key, this.child});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> with DoubleTapExitMixin {
  final SessionService _sessionService = SessionService();
  bool _roleLoaded = false;
  bool _isAdmin = false;

  @override
  void initState() {
    super.initState();
    _loadRole();
  }

  Future<void> _loadRole() async {
    final role = await _sessionService.getUserRole();
    if (!mounted) return;
    setState(() {
      _roleLoaded = true;
      _isAdmin = role == 'admin';
    });
  }

  void _onItemTapped(int index) {
    final router = GoRouter.of(context);
    switch (index) {
      case 0:
        router.go('/');
        break;
      case 1:
        router.go('/wallet');
        break;
      case 2:
        router.go('/notifications');
        break;
      case 3:
        router.go('/profile');
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final ThemeData shellTheme = isDark
        ? theme
        : theme.copyWith(
            scaffoldBackgroundColor: DesignToken.carpenterAppBackground,
            colorScheme: theme.colorScheme.copyWith(
              surface: DesignToken.carpenterAppBackground,
            ),
            appBarTheme: theme.appBarTheme.copyWith(
              backgroundColor: DesignToken.carpenterAppBackground,
              surfaceTintColor: Colors.transparent,
            ),
          );

    final location = GoRouterState.of(context).uri.path;
    int currentIndex = 0;
    if (location.startsWith('/wallet')) {
      currentIndex = 1;
    } else if (location.startsWith('/notifications')) {
      currentIndex = 2;
    } else if (location.startsWith('/profile')) {
      currentIndex = 3;
    }

    return Theme(
      data: shellTheme,
      child: Builder(
        builder: (context) {
          final t = Theme.of(context);
          final mq = MediaQuery.of(context);
          final showCarpenterBar = _roleLoaded && !_isAdmin;
          final bottomChromeHeight = CarpenterShellLayout.chromeHeight(mq);

          return PopScope(
            canPop: false,
            onPopInvokedWithResult: (didPop, _) async {
              if (!didPop) {
                if (Navigator.of(context).canPop()) {
                  Navigator.of(context).pop();
                  return;
                }
                await handleDoubleTapExit();
              }
            },
            child: Scaffold(
              backgroundColor: t.scaffoldBackgroundColor,
              body: Stack(
                children: [
                  Padding(
                    padding: EdgeInsets.only(
                      bottom: showCarpenterBar ? bottomChromeHeight : 0,
                    ),
                    child: widget.child ?? const SizedBox.shrink(),
                  ),
                  if (showCarpenterBar)
                    Align(
                      alignment: Alignment.bottomCenter,
                      child: CarpenterBottomNavBar.fromContext(
                        context,
                        currentIndex: currentIndex,
                        onTabSelected: _onItemTapped,
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
