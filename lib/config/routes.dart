// filepath: lib/config/routes.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:balaji_points/presentation/screens/common/dashboard/dashboard_page.dart';
import 'package:balaji_points/presentation/screens/carpenter/home/home_page.dart';
import 'package:balaji_points/presentation/screens/carpenter/profile/edit_profile_page.dart';
import 'package:balaji_points/presentation/screens/carpenter/profile/profile_page.dart';
import 'package:balaji_points/presentation/screens/common/splash/splash_page.dart';

import 'package:balaji_points/presentation/screens/common/auth/login_page.dart';
import 'package:balaji_points/presentation/screens/common/auth/pin_setup_page.dart';
import 'package:balaji_points/presentation/screens/common/auth/pin_login_page.dart';
import 'package:balaji_points/presentation/screens/common/auth/reset_pin_page.dart';

import 'package:balaji_points/presentation/screens/carpenter/spin/daily_spin_page.dart';
import 'package:balaji_points/presentation/screens/carpenter/wallet/wallet_page.dart';
import 'package:balaji_points/presentation/screens/admin/admin_home_page.dart';
import 'package:balaji_points/presentation/screens/admin/admin_add_bill_page.dart';
import 'package:balaji_points/presentation/screens/admin/diagnostic_page.dart';
import 'package:balaji_points/presentation/screens/admin/admin_notifications_page.dart';
import 'package:balaji_points/presentation/screens/super_admin/super_admin_page.dart';
import 'package:balaji_points/presentation/screens/carpenter/bills/add_bill_page.dart';
import 'package:balaji_points/presentation/screens/carpenter/notifications/notifications_page.dart';
import 'package:balaji_points/services/auth/session_service.dart';
import 'package:balaji_points/presentation/screens/carpenter/products/product_list_page.dart';
import 'package:balaji_points/presentation/screens/carpenter/cart/cart_page.dart';
import 'package:balaji_points/presentation/screens/carpenter/products/product_detail_page.dart';
import 'package:balaji_points/presentation/screens/carpenter/orders/orders_page.dart';
import 'package:balaji_points/presentation/screens/carpenter/orders/order_detail_page.dart';
import 'package:balaji_points/presentation/screens/common/info/about_us_page.dart';
import 'package:balaji_points/presentation/screens/common/onboarding/onboarding_page.dart';
import 'package:balaji_points/presentation/screens/admin/carpenter_profile_detail_screen.dart';
import 'package:balaji_points/core/design/app_colors.dart';
import 'package:balaji_points/l10n/app_localizations.dart';
import 'package:balaji_points/core/logger.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

String? _lastLoggedRoutePath;

final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    navigatorKey: navigatorKey,
    initialLocation: '/splash',

    redirect: (context, state) async {
      final path = state.uri.path;
      if (_lastLoggedRoutePath != path) {
        _lastLoggedRoutePath = path;
        AppLogger.nav(path);
      }

      // Skip role checks for public/auth routes.
      const publicPaths = ['/splash', '/login', '/pin-setup', '/pin-login', '/pin-reset', '/onboarding'];
      if (publicPaths.any((p) => path.startsWith(p))) return null;

      final role = (await SessionService().getUserRole())?.trim().toLowerCase();

      // super_admin must never access branch admin panel.
      if (role == 'super_admin') {
        if (path.startsWith('/admin')) return '/super-admin';
        return null;
      }

      // admin must never access super_admin panel.
      if (role == 'admin') {
        if (path == '/super-admin') return '/admin';
        // Redirect admin notifications route.
        if (path == '/notifications') return '/admin/notifications';
      }

      // Prevent carpenter from entering admin routes.
      if (role == 'carpenter' || role == null) {
        if (path.startsWith('/admin') || path == '/super-admin') return '/';
      }

      // Robust fallback: normalize admin/notifications sub-paths.
      if (path.startsWith('/admin/notifications') &&
          path != '/admin/notifications') {
        return '/admin/notifications';
      }

      // Allow admin to access carpenter profile routes
      if (role == 'admin' && path.startsWith('/admin/carpenter-profile/')) {
        return null;
      }

      return null;
    },

    errorBuilder: (context, state) {
      final l10n = AppLocalizations.of(context);
      final title = l10n?.routeErrorTitle ?? 'Page not found';
      final body = l10n?.routeErrorNotFound ?? 'This page could not be opened.';
      final goHome = l10n?.routeErrorGoHome ?? 'Go home';
      final detailsLabel = l10n?.routeErrorDetailsLabel ?? 'Details';
      return Scaffold(
        appBar: AppBar(title: Text(title)),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, size: 64, color: AppColors.error),
                const SizedBox(height: 16),
                Text(
                  body,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
                const SizedBox(height: 8),
                SelectableText(
                  state.uri.toString(),
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                if (state.error != null) ...[
                  const SizedBox(height: 12),
                  Text(
                    detailsLabel,
                    style: Theme.of(context).textTheme.labelSmall,
                  ),
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: SelectableText(
                      '${state.error}',
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 11),
                    ),
                  ),
                ],
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () async {
                    final role =
                        (await SessionService().getUserRole())?.trim().toLowerCase();
                    if (!context.mounted) return;
                    if (role == 'super_admin') {
                      context.go('/super-admin');
                    } else if (role == 'admin') {
                      context.go('/admin');
                    } else {
                      context.go('/');
                    }
                  },
                  child: Text(goHome),
                ),
              ],
            ),
          ),
        ),
      );
    },

    routes: [
      GoRoute(path: '/splash', builder: (context, _) => const SplashPage()),

      GoRoute(
        path: '/onboarding',
        name: 'onboarding',
        builder: (context, _) => const OnboardingPage(),
      ),

      GoRoute(
        path: '/login',
        builder: (context, _) => const LoginPage(),
      ),

      GoRoute(
        path: '/pin-setup',
        builder: (context, state) {
          final phone = state.uri.queryParameters['phone'] ?? '';
          return PINSetupPage(phoneNumber: phone);
        },
      ),

      GoRoute(
        path: '/pin-login',
        builder: (context, state) {
          final phone = state.uri.queryParameters['phone'] ?? '';
          return PINLoginPage(phoneNumber: phone);
        },
      ),

      GoRoute(
        path: '/pin-reset',
        builder: (context, state) {
          final phone = state.uri.queryParameters['phone'] ?? '';
          return ResetPINPage(phoneNumber: phone);
        },
      ),

      // Carpenter shell with persistent bottom tab bar
      ShellRoute(
        builder: (context, state, child) => DashboardPage(child: child),
        routes: [
          GoRoute(
            path: '/',
            name: 'home',
            builder: (context, state) => const HomePage(),
          ),
          GoRoute(
            path: '/wallet',
            name: 'wallet',
            builder: (context, state) => const WalletPage(),
          ),
          GoRoute(
            path: '/notifications',
            name: 'notifications',
            builder: (context, state) => const NotificationsPage(),
          ),
          GoRoute(
            path: '/profile',
            name: 'profile',
            builder: (context, state) =>
                const ProfilePage(showBottomNav: false),
          ),
          GoRoute(
            path: '/add-bill',
            name: 'add-bill',
            builder: (context, state) => const AddBillPage(),
          ),
          GoRoute(
            path: '/about-us',
            name: 'about-us',
            builder: (context, state) => const AboutUsPage(),
          ),
          GoRoute(
            path: '/products',
            name: 'products',
            builder: (context, state) {
              final category = state.uri.queryParameters['category'];
              return ProductListPage(initialCategory: category);
            },
          ),
          GoRoute(
            path: '/cart',
            name: 'cart',
            builder: (context, state) => const CartPage(),
          ),
          GoRoute(
            path: '/product-detail/:id',
            name: 'product-detail',
            builder: (context, state) {
              final id = state.pathParameters['id']!;
              return ProductDetailPage(productId: id);
            },
          ),
          GoRoute(
            path: '/orders',
            name: 'orders',
            builder: (context, state) => const OrdersPage(),
          ),
          GoRoute(
            path: '/order-detail/:id',
            name: 'order-detail',
            builder: (context, state) {
              final id = state.pathParameters['id']!;
              return OrderDetailPage(orderId: id);
            },
          ),
          GoRoute(
            path: '/edit-profile',
            builder: (context, state) {
              final isFirstTime =
                  state.uri.queryParameters['firstTime'] == 'true';
              return EditProfilePage(isFirstTime: isFirstTime);
            },
          ),
        ],
      ),
      GoRoute(
        path: '/daily-spin',
        builder: (context, _) => const DailySpinPage(),
      ),
      GoRoute(
        path: '/admin',
        builder: (context, _) => const AdminHomePage(),
      ),
      GoRoute(
        path: '/admin/add-bill',
        builder: (context, _) => const AdminAddBillPage(),
      ),
      GoRoute(
        path: '/admin/diagnostic',
        builder: (context, _) => const DiagnosticPage(),
      ),
      GoRoute(
        path: '/admin/notifications',
        builder: (context, _) => const AdminNotificationsPage(),
      ),
      GoRoute(
        path: '/admin/carpenter-profile/:carpenterId',
        builder: (context, state) {
          final carpenterId = state.pathParameters['carpenterId']!;
          return CarpenterProfileDetailScreen(carpenterId: carpenterId);
        },
      ),
      GoRoute(
        path: '/super-admin',
        builder: (context, _) => const SuperAdminPage(),
      ),
      // Note: trailing slash is normalized by the redirect.
    ],
  );
});
