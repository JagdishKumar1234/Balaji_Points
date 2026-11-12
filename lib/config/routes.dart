// filepath: lib/config/routes.dart
import 'package:balaji_points/services/telemetry/telemetry.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:balaji_points/presentation/screens/common/dashboard/dashboard_page.dart';
import 'package:balaji_points/presentation/screens/carpenter/home/home_page.dart';
import 'package:balaji_points/presentation/screens/carpenter/profile/edit_profile_page.dart';
import 'package:balaji_points/presentation/screens/carpenter/profile/profile_page.dart';
import 'package:balaji_points/presentation/screens/common/splash/splash_page.dart';

import 'package:balaji_points/presentation/screens/common/auth/login_page.dart';
import 'package:balaji_points/presentation/screens/common/auth/register_page.dart';
import 'package:balaji_points/presentation/screens/common/auth/forgot_password_page.dart';
import 'package:balaji_points/presentation/screens/common/auth/pin_login_page.dart';
import 'package:balaji_points/presentation/screens/common/auth/phone_pin_entry_page.dart';
import 'package:balaji_points/presentation/screens/common/auth/reset_pin_page.dart';
import 'package:balaji_points/presentation/screens/carpenter/spin/daily_spin_page.dart';
import 'package:balaji_points/presentation/screens/carpenter/wallet/wallet_page.dart';
import 'package:balaji_points/presentation/screens/admin/admin_home_page.dart';
import 'package:balaji_points/presentation/screens/admin/admin_add_bill_page.dart';
import 'package:balaji_points/presentation/screens/admin/admin_notifications_page.dart';
import 'package:balaji_points/presentation/screens/super_admin/super_admin_page.dart';
import 'package:balaji_points/presentation/screens/carpenter/bills/add_bill_page.dart';
import 'package:balaji_points/presentation/screens/carpenter/notifications/notifications_page.dart';
import 'package:balaji_points/services/auth/session_service.dart';
import 'package:balaji_points/presentation/screens/common/info/about_us_page.dart';
import 'package:balaji_points/presentation/screens/carpenter/profile/my_branch_page.dart';
import 'package:balaji_points/presentation/screens/common/info/legal_document_page.dart';
import 'package:balaji_points/presentation/screens/common/onboarding/onboarding_page.dart';
import 'package:balaji_points/presentation/screens/admin/carpenter_profile_detail_screen.dart';
import 'package:balaji_points/presentation/screens/admin/daily_spin_history_screen.dart';
// import 'package:balaji_points/presentation/screens/admin/duplicate_accounts_screen.dart';  // hidden tool, see the routes below
// import 'package:balaji_points/presentation/screens/admin/export_users_before_cleanup.dart';  // hidden tool, see the routes below
// import 'package:balaji_points/presentation/screens/admin/cleanup_duplicate_accounts_screen.dart';  // hidden tool, see the routes below
// import 'package:balaji_points/presentation/screens/admin/firestore_backup_screen.dart';  // hidden tool, see the routes below
// import 'package:balaji_points/presentation/screens/admin/firebase_duplicate_checker_screen.dart';  // hidden tool, see the routes below
// import 'package:balaji_points/presentation/screens/admin/smart_duplicate_cleanup_screen.dart';  // hidden tool, see the routes below
import 'package:balaji_points/presentation/screens/common/catalog/catalogs_page.dart';
import 'package:balaji_points/presentation/screens/common/contact/contact_us_page.dart';
import 'package:balaji_points/presentation/screens/guest/guest_home_page.dart';
import 'package:balaji_points/presentation/screens/guest/branches_page.dart';
import 'package:balaji_points/presentation/screens/guest/careers_page.dart';
import 'package:balaji_points/core/models/enquiry.dart';
import 'package:balaji_points/presentation/screens/common/catalog/catalog_viewer_page.dart';
import 'package:balaji_points/core/design/app_colors.dart';
import 'package:balaji_points/l10n/app_localizations.dart';
import 'package:balaji_points/core/logger.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

String? _lastLoggedRoutePath;

final routerProvider = Provider<GoRouter>((ref) {
  final router = _buildRouter();
  // The route pattern, never the real path, so ids never reach Analytics.
  void trackScreen() =>
      Telemetry.screen(router.routerDelegate.currentConfiguration.fullPath);
  router.routerDelegate.addListener(trackScreen);
  ref.onDispose(() => router.routerDelegate.removeListener(trackScreen));
  return router;
});

GoRouter _buildRouter() {
  return GoRouter(
    navigatorKey: navigatorKey,
    initialLocation: '/splash',

    redirect: (context, state) async {
      final path = state.uri.path;
      if (_lastLoggedRoutePath != path) {
        _lastLoggedRoutePath = path;
        AppLogger.nav(path);
      }

      final role = (await SessionService().getUserRole())?.trim().toLowerCase();
      return redirectForRole(path, role);
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
                Icon(
                  Icons.error_outline_rounded,
                  size: 64,
                  color: AppColors.error,
                ),
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
                    final role = (await SessionService().getUserRole())
                        ?.trim()
                        .toLowerCase();
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

      GoRoute(path: '/login', builder: (context, _) => const LoginPage()),
      GoRoute(path: '/register', builder: (context, _) => const RegisterPage()),
      // Legal pages: open before login (registration) and from Profile.
      GoRoute(
        path: '/terms',
        builder: (context, _) =>
            const LegalDocumentPage(document: LegalDocument.terms),
      ),
      GoRoute(
        path: '/privacy',
        builder: (context, _) =>
            const LegalDocumentPage(document: LegalDocument.privacy),
      ),
      GoRoute(
        path: '/complete-registration',
        builder: (context, state) => RegisterPage(
          completeGoogleProfile: true,
          googleProfile: state.extra as Map<String, dynamic>?,
        ),
      ),
      GoRoute(
        path: '/forgot-password',
        builder: (context, state) =>
            ForgotPasswordPage(initialEmail: state.extra as String?),
      ),
      GoRoute(
        path: '/phone-pin-login',
        builder: (context, _) => const PhonePinEntryPage(),
      ),
      GoRoute(
        path: '/pin-login',
        builder: (context, state) =>
            PINLoginPage(phoneNumber: state.uri.queryParameters['phone'] ?? ''),
      ),
      GoRoute(
        path: '/pin-reset',
        builder: (context, state) =>
            ResetPINPage(phoneNumber: state.uri.queryParameters['phone'] ?? ''),
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
            path: '/my-branch',
            name: 'my-branch',
            builder: (context, state) => const MyBranchPage(),
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
      // Product catalogs: full screen, outside the tab shell, open to every
      // signed-in role. One screen (category chips + covers) -> reader.
      GoRoute(
        path: '/catalogs',
        builder: (context, _) => const CatalogsPage(),
        routes: [
          GoRoute(
            path: ':categoryId',
            // Old links: the same screen with that category's chip selected.
            builder: (context, state) => CatalogsPage(
              initialCategoryId: state.pathParameters['categoryId'],
            ),
            routes: [
              GoRoute(
                path: ':catalogId',
                builder: (context, state) => CatalogViewerPage(
                  categoryId: state.pathParameters['categoryId']!,
                  catalogId: state.pathParameters['catalogId']!,
                ),
                routes: [
                  // Old links: the reader now opens directly on the catalog.
                  GoRoute(
                    path: 'view',
                    redirect: (context, state) =>
                        '/catalogs/${state.pathParameters['categoryId']}'
                        '/${state.pathParameters['catalogId']}',
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
      GoRoute(
        path: '/contact-us',
        builder: (context, state) => ContactUsPage(
          initialType: switch (state.uri.queryParameters['type']) {
            null => null,
            final id => EnquiryType.fromId(id),
          },
        ),
      ),
      GoRoute(path: '/guest', builder: (context, _) => const GuestHomePage()),
      GoRoute(path: '/branches', builder: (context, _) => const BranchesPage()),
      GoRoute(path: '/careers', builder: (context, _) => const CareersPage()),
      GoRoute(path: '/admin', builder: (context, _) => const AdminHomePage()),
      GoRoute(
        path: '/admin/add-bill',
        builder: (context, _) => const AdminAddBillPage(),
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
        path: '/admin/spin-history',
        builder: (context, _) => const DailySpinHistoryScreen(),
      ),
      // Maintenance tools (duplicates, backup, cleanup) are hidden from
      // every branch admin (2026-11-12): their dashboard cards are commented
      // out, and these routes too, so they cannot be opened by typing the
      // address on web. Uncomment both to bring a tool back.
      // GoRoute(
      //   path: '/admin/duplicate-accounts',
      //   builder: (context, _) => const DuplicateAccountsScreen(),
      // ),
      // GoRoute(
      //   path: '/admin/export-users',
      //   builder: (context, _) => const ExportUsersBeforeCleanupScreen(),
      // ),
      // GoRoute(
      //   path: '/admin/cleanup-duplicates',
      //   builder: (context, _) => const CleanupDuplicateAccountsScreen(),
      // ),
      // GoRoute(
      //   path: '/admin/backup',
      //   builder: (context, _) => const FirestoreBackupScreen(),
      // ),
      // GoRoute(
      //   path: '/admin/check-duplicates',
      //   builder: (context, _) => const FirebaseDuplicateCheckerScreen(),
      // ),
      // GoRoute(
      //   path: '/admin/smart-cleanup',
      //   builder: (context, _) => const SmartDuplicateCleanupScreen(),
      // ),
      GoRoute(
        path: '/super-admin',
        builder: (context, _) => const SuperAdminPage(),
      ),
      // Note: trailing slash is normalized by the redirect.
    ],
  );
}

/// Where a screen request should go for this [role] (null = open it).
/// Pure, so tests can check every role against every screen. [role] is the
/// saved role, lower case, or null when no one is logged in.
@visibleForTesting
String? redirectForRole(String path, String? role) {
  // Skip role checks for public/auth routes.
  const publicPaths = [
    '/splash',
    '/login',
    '/register',
    '/complete-registration',
    '/forgot-password',
    '/phone-pin-login',
    '/pin-login',
    '/pin-reset',
    '/onboarding',
    '/terms',
    '/privacy',
    // Guest mode (no login): home, branches, careers, enquiry form.
    // Catalogs are open too (no admin path). Bills, points, offers and
    // profile stay behind login.
    '/contact-us',
    '/guest',
    '/branches',
    '/careers',
  ];
  if (publicPaths.any((p) => path.startsWith(p))) return null;

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

  // Only admins (and the super admin, handled above) may open admin
  // screens. Every member role (carpenter, architect, engineer,
  // interior designer, custom roles) and anyone not logged in is sent
  // home; this used to check carpenter only.
  if (role != 'admin') {
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
}
