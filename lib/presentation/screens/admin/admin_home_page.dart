import 'package:flutter/material.dart';
import 'package:balaji_points/core/design/app_colors.dart';
import 'package:balaji_points/core/design/app_typography.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:go_router/go_router.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:balaji_points/core/constants/app_constants.dart';
import 'package:balaji_points/l10n/app_localizations.dart';
import 'package:balaji_points/core/mixins/double_tap_exit_mixin.dart';
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          l10n.logout,
          style: AppTypography.labelLarge().copyWith(fontSize: 22),
        ),
        content: Text(
          l10n.logoutConfirmation,
          style: AppTypography.bodyMedium().copyWith(fontSize: 16),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(
              l10n.cancel,
              style: AppTypography.bodySmall().copyWith(
                color: Colors.grey[600],
                fontSize: 16,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: AppColors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text(
              l10n.logout,
              style: AppTypography.labelLarge().copyWith(fontSize: 16),
            ),
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
              backgroundColor: Colors.red,
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Delete All Notifications'),
        content: const Text(
          'Are you sure you want to delete all admin notifications?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFE53935),
              foregroundColor: AppColors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    // Blocking progress.
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
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
          backgroundColor: AppColors.lightPrimary,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      if (!context.mounted) return;
      Navigator.of(context).pop(); // progress
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Delete failed: $e'),
          backgroundColor: AppColors.error,
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
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: Colors.white,
          foregroundColor: AppColors.lightPrimary,
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
                        borderRadius: BorderRadius.circular(10),
                        child: Image.asset(
                          AppConstants.logoPath,
                          width: 36,
                          height: 36,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color: AppColors.lightPrimary.withValues(
                                alpha: 0.15,
                              ),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(
                              Icons.forest,
                              color: AppColors.lightPrimary,
                              size: 22,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Balaji Points - Admin Panel',
                            style: AppTypography.labelLarge().copyWith(
                              fontSize: 17,
                              color: AppColors.lightPrimary,
                              letterSpacing: 0.3,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            AppConstants.shopNameShort,
                            style: AppTypography.bodyMedium().copyWith(
                              fontSize: 11,
                              color: AppColors.lightPrimary.withValues(
                                alpha: 0.65,
                              ),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ],
                  ),
                )
              : _selectedSection == 'users'
              ? _usersCountTitle()
              : Text(
                  _sectionTitle(_selectedSection!),
                  style: AppTypography.labelLarge().copyWith(
                    fontSize: 18,
                    color: AppColors.lightPrimary,
                  ),
                ),
          centerTitle: !_showDashboard,
          actions: [
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
              color: Colors.black.withValues(alpha: 0.08),
            ),
          ),
        ),
        body: Container(
          color: AppColors.woodenBackground,
          child: _showDashboard
              ? AdminDashboard(onOpenSection: _openSection)
              : _buildSectionContent(_selectedSection!),
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
          return Text(
            'Users - ...',
            style: AppTypography.labelLarge().copyWith(
              fontSize: 18,
              color: AppColors.lightPrimary,
            ),
          );
        }

        return Text(
          'Users - $count',
          style: AppTypography.labelLarge().copyWith(
            fontSize: 18,
            color: AppColors.lightPrimary,
          ),
        );
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
      default:
        return const SizedBox.shrink();
    }
  }
}
