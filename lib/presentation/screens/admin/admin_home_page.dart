import 'package:balaji_points/core/design/app_radius.dart';
import 'package:flutter/material.dart';
import 'package:balaji_points/core/design/app_colors.dart';
import 'package:balaji_points/presentation/widgets/shared/app_button.dart';
import 'package:balaji_points/presentation/widgets/shared/app_loader.dart';
import 'package:balaji_points/presentation/widgets/shared/app_text.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:go_router/go_router.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:balaji_points/core/constants/app_constants.dart';
import 'package:balaji_points/l10n/app_localizations.dart';
import 'package:balaji_points/core/mixins/double_tap_exit_mixin.dart';
import 'package:balaji_points/providers/theme_provider.dart';
import 'package:balaji_points/services/notifications/fcm_service.dart';
import 'package:balaji_points/services/auth/session_service.dart';
import '../../widgets/admin/admin_dashboard.dart';
import '../../widgets/admin/pending_bills_list.dart';
import '../../widgets/admin/offers_management.dart';
import '../../widgets/admin/products_management.dart';
import '../../widgets/admin/users_list.dart';
import '../../widgets/admin/daily_spin_management.dart';
import '../../widgets/admin/bill_history_list.dart';
import '../../widgets/admin/orders_management.dart';
import 'admin_notifications_page.dart';
import 'points_repair_page.dart';

class AdminHomePage extends ConsumerStatefulWidget {
  const AdminHomePage({super.key});

  @override
  ConsumerState<AdminHomePage> createState() => _AdminHomePageState();
}

class _AdminHomePageState extends ConsumerState<AdminHomePage>
    with DoubleTapExitMixin {
  bool _showDashboard = true;
  String? _selectedSection;

  static const List<String> _adminNotificationTypes = [
    'newPendingBill',
    'newUserRegistered',
  ];

  void _openSection(String section) {
    setState(() {
      _showDashboard = false;
      _selectedSection = section;
    });
  }

  void _backToDashboard() {
    setState(() {
      _showDashboard = true;
      _selectedSection = null;
    });
  }

  Future<void> _handleLogout() async {
    final l10n = AppLocalizations.of(context)!;
    final shouldLogout = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: AppRadius.all16),
        title: AppText.h3(l10n.logout),
        content: AppText.body(l10n.logoutConfirmation),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: AppText.body(l10n.cancel, color: context.themeTextSecondary),
          ),
          AppButton(
            label: l10n.logout,
            onPressed: () => Navigator.of(context).pop(true),
            variant: AppButtonVariant.danger,
            fullWidth: false,
            verticalPadding: 12,
          ),
        ],
      ),
    );

    if (shouldLogout == true && mounted) {
      try {
        // Delete FCM token before signing out
        await FCMService().deleteToken();

        // Sign out from Firebase
        await FirebaseAuth.instance.signOut();

        // Clear secure session so splash redirects correctly by role.
        await SessionService().clearSession();

        if (mounted) {
          context.go('/login');
        }
      } catch (e) {
        if (mounted) {
          final l10n = AppLocalizations.of(context)!;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${l10n.logoutFailed}: ${e.toString()}'),
              backgroundColor: context.themeError,
            ),
          );
        }
      }
    }
  }

  Future<void> _deleteAllAdminNotifications() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: AppRadius.all16),
        title: const AppText.h4('Delete All Notifications'),
        content: const AppText.body(
          'Are you sure you want to delete all admin notifications?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          AppButton(
            label: 'Delete',
            onPressed: () => Navigator.of(context).pop(true),
            variant: AppButtonVariant.danger,
            fullWidth: false,
            verticalPadding: 10,
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    // Blocking progress.
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: AppLoader()),
    );

    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('notification_logs')
          .where('type', whereIn: _adminNotificationTypes)
          .get();

      final docs = snapshot.docs;
      if (docs.isEmpty) {
        if (!context.mounted) return;
        Navigator.of(context).pop(); // progress
        return;
      }

      // Firestore batch limit is 500 writes.
      const batchSize = 450;
      for (int i = 0; i < docs.length; i += batchSize) {
        final batch = FirebaseFirestore.instance.batch();
        final chunk = docs.sublist(
          i,
          i + batchSize < docs.length ? i + batchSize : docs.length,
        );
        for (final doc in chunk) {
          batch.delete(doc.reference);
        }
        await batch.commit();
      }

      if (!context.mounted) return;
      Navigator.of(context).pop(); // progress
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${docs.length} notification(s) deleted'),
          backgroundColor: context.themePrimary,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      if (!context.mounted) return;
      Navigator.of(context).pop(); // progress
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Delete failed: $e'),
          backgroundColor: context.themeError,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (!didPop) {
          // Check for dialogs first
          if (Navigator.of(context).canPop()) {
            Navigator.of(context).pop();
            return;
          }

          // Handle double-tap exit
          await handleDoubleTapExit();
        }
      },
      child: Scaffold(
        backgroundColor: context.themeBackground,
        appBar: AppBar(
          backgroundColor: context.themeBackground,
          foregroundColor: context.themeTextPrimary,
          elevation: 0,
          scrolledUnderElevation: 0,
          titleSpacing: _showDashboard ? 0 : null,
          leading: _showDashboard
              ? null
              : IconButton(
                  icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 22),
                  onPressed: _backToDashboard,
                ),
          title: _showDashboard
              ? Padding(
                  padding: const EdgeInsets.only(left: 14),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      ClipRRect(
                        borderRadius: AppRadius.sm8,
                        child: Image.asset(
                          AppConstants.logoPath,
                          width: 36,
                          height: 36,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color: context.themeTextPrimary.withValues(alpha: 0.15),
                              borderRadius: AppRadius.sm8,
                            ),
                            child: Icon(Icons.forest,
                                color: context.themeTextPrimary, size: 22),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          AppText.label(
                            'Balaji Points - Admin Panel',
                            color: context.themeTextPrimary,
                            maxLines: 1,
                          ),
                          const SizedBox(height: 2),
                          AppText.muted(
                            AppConstants.shopNameShort,
                            color: context.themeTextSecondary,
                            maxLines: 1,
                          ),
                        ],
                      ),
                    ],
                  ),
                )
              : _selectedSection == 'users'
              ? _usersCountTitle()
              : AppText.label(
                  _sectionTitle(_selectedSection!),
                  color: context.themeTextPrimary,
                ),
          centerTitle: !_showDashboard,
          actions: [
            // Theme toggle — same animated icon as carpenter home
            _AdminThemeToggle(fgColor: context.themeTextPrimary),
            if (!_showDashboard && _selectedSection == 'notifications')
              IconButton(
                icon: const Icon(Icons.delete_outline, size: 24),
                onPressed: _deleteAllAdminNotifications,
                tooltip: 'Delete All Notifications',
              )
            else
              IconButton(
                icon: const Icon(Icons.logout, size: 24),
                onPressed: _handleLogout,
              ),
          ],
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(1),
            child: Container(
              height: 1,
              color: context.themeBorder.withValues(alpha: 0.5),
            ),
          ),
        ),
        body: Container(
          color: context.themeSoftSurface,
          child: Column(
            children: [
              Expanded(
                child: _showDashboard
                    ? AdminDashboard(onOpenSection: _openSection)
                    : _buildSectionContent(_selectedSection!),
              ),
              // Bottom safe area padding
              SizedBox(
                height: MediaQuery.of(context).viewInsets.bottom +
                    MediaQuery.of(context).padding.bottom,
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _sectionTitle(String section) {
    switch (section) {
      case 'pending':
        return 'Pending Bills';
      case 'history':
        return 'Bill History';
      case 'offers':
        return 'Offers';
      case 'users':
        return 'Users';
      case 'notifications':
        return 'Notifications';
      case 'products':
        return 'Products';
      case 'orders':
        return 'Orders';
      case 'spin':
        return 'Spin';
      case 'points-repair':
        return 'Points Repair';
      default:
        return 'Admin';
    }
  }

  Widget _usersCountTitle() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('users').snapshots(),
      builder: (context, snapshot) {
        final docs = snapshot.data?.docs ?? const [];
        // Match UsersList filtering:
        // - Exclude admins
        // - Include carpenters (role == 'carpenter') OR missing/empty role
        final count = docs.where((doc) {
          final data = doc.data() as Map<String, dynamic>;
          final role = data['role'] as String?;
          if (role == 'admin') return false;
          return role == null || role.isEmpty || role == 'carpenter';
        }).length;

        if (snapshot.connectionState == ConnectionState.waiting) {
          return AppText.label('Users - ...', color: context.themeTextPrimary);
        }

        return AppText.label('Users - $count', color: context.themeTextPrimary);
      },
    );
  }

  Widget _buildSectionContent(String section) {
    switch (section) {
      case 'pending':
        return const PendingBillsList();
      case 'history':
        return const BillHistoryList();
      case 'offers':
        return const OffersManagement();
      case 'users':
        return const UsersList();
      case 'notifications':
        return const AdminNotificationsPage(embedded: true);
      case 'products':
        return const ProductsManagement();
      case 'orders':
        return const OrdersManagement();
      case 'spin':
        return const DailySpinManagement();
      case 'points-repair':
        return const PointsRepairPage();
      default:
        return const SizedBox.shrink();
    }
  }
}

// ---------------------------------------------------------------------------
// Theme toggle button — reusable for admin AppBar
// ---------------------------------------------------------------------------

class _AdminThemeToggle extends ConsumerWidget {
  final Color fgColor;
  const _AdminThemeToggle({required this.fgColor});

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
          color: fgColor,
        ),
      ),
    );
  }
}
