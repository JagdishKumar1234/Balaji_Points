import 'package:balaji_points/services/platform/enquiry_service.dart';
import 'package:balaji_points/core/firebase/app_firestore.dart';
import 'package:balaji_points/presentation/widgets/admin/enquiries_management.dart';
import 'package:balaji_points/services/notifications/notification_visibility.dart';
import 'package:balaji_points/core/design/app_radius.dart';
import 'package:flutter/material.dart';
import 'package:balaji_points/providers/loading_provider.dart';
import 'package:balaji_points/core/design/app_spacing.dart';
import 'package:balaji_points/core/design/app_typography.dart';
import 'package:balaji_points/presentation/screens/super_admin/super_admin_loading_view.dart';
import 'package:balaji_points/presentation/widgets/shared/empty_state.dart';
import 'package:balaji_points/presentation/widgets/shared/branch_banner.dart';
import 'package:balaji_points/services/branch/current_branch_service.dart';
import 'package:balaji_points/core/design/app_colors.dart';
import 'package:balaji_points/presentation/widgets/shared/app_button.dart';
import 'package:balaji_points/presentation/widgets/shared/app_loader.dart';
import 'package:balaji_points/presentation/widgets/shared/app_text.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:go_router/go_router.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:balaji_points/core/constants/app_constants.dart';
import 'package:balaji_points/core/points/leaderboard_group.dart';
import 'package:balaji_points/l10n/app_localizations.dart';
import 'package:balaji_points/core/mixins/double_tap_exit_mixin.dart';
import 'package:balaji_points/providers/theme_provider.dart';
import 'package:balaji_points/services/notifications/fcm_service.dart';
import 'package:balaji_points/services/auth/session_service.dart';
import '../../widgets/admin/admin_dashboard.dart';
import '../../widgets/admin/pending_bills_list.dart';
import '../../widgets/admin/offers_management.dart';
import '../../widgets/admin/catalogs_management.dart';
import '../../widgets/admin/users_list.dart';
import '../../widgets/admin/users_list/users_filters.dart';
import '../../widgets/admin/daily_spin_management.dart';
import '../../widgets/admin/bill_history_list.dart';
import 'admin_notifications_page.dart';
import 'points_repair_page.dart';
import 'duplicate_accounts_screen.dart';
import 'export_users_before_cleanup.dart';
import 'cleanup_duplicate_accounts_screen.dart';
import 'firestore_backup_screen.dart';
import 'firebase_duplicate_checker_screen.dart';
import 'smart_duplicate_cleanup_screen.dart';
import 'send_greeting_page.dart';
import 'send_notification_page.dart';
import '../../widgets/admin/admin_bottom_nav_bar.dart';
import '../../widgets/admin/admin_more_page.dart';
import '../../widgets/admin/admin_tab_pages.dart';
import 'package:balaji_points/core/layout/responsive.dart';
import 'package:balaji_points/providers/admin_counts_provider.dart';
import '../../widgets/shared/responsive_role_navigation.dart';

class AdminHomePage extends ConsumerStatefulWidget {
  const AdminHomePage({super.key});

  @override
  ConsumerState<AdminHomePage> createState() => _AdminHomePageState();
}

class _AdminHomePageState extends ConsumerState<AdminHomePage>
    with DoubleTapExitMixin {
  bool _showDashboard = true;
  String? _selectedSection;

  static const _adminRailSections = [
    null,
    'users',
    'pending',
    'history',
    'offers',
    'spin',
    'notifications',
  ];
  List<RoleNavigationItem> get _adminRailItems => [
    RoleNavigationItem(
      label: AppLocalizations.of(context)!.dashboard,
      icon: Icons.dashboard_outlined,
      selectedIcon: Icons.dashboard_rounded,
    ),
    RoleNavigationItem(
      label: AppLocalizations.of(context)!.users,
      icon: Icons.people_outline_rounded,
      selectedIcon: Icons.people_rounded,
    ),
    RoleNavigationItem(
      label: AppLocalizations.of(context)!.statPendingBills,
      icon: Icons.pending_actions_outlined,
      selectedIcon: Icons.pending_actions_rounded,
    ),
    RoleNavigationItem(
      label: AppLocalizations.of(context)!.transactions,
      icon: Icons.receipt_long_outlined,
      selectedIcon: Icons.receipt_long_rounded,
    ),
    RoleNavigationItem(
      label: AppLocalizations.of(context)!.offers,
      icon: Icons.local_offer_outlined,
      selectedIcon: Icons.local_offer_rounded,
    ),
    RoleNavigationItem(
      label: AppLocalizations.of(context)!.rewards,
      icon: Icons.emoji_events_outlined,
      selectedIcon: Icons.emoji_events_rounded,
    ),
    RoleNavigationItem(
      label: AppLocalizations.of(context)!.notifications,
      icon: Icons.notifications_outlined,
      selectedIcon: Icons.notifications_rounded,
    ),
  ];

  static const List<String> _adminNotificationTypes = [
    'newPendingBill',
    'newUserRegistered',
  ];

  /// Where Back goes from the open section: 'more' when it was opened from
  /// the More tab, otherwise the dashboard.
  String? _origin;

  /// Sections that are a bottom tab of their own on phones.
  static const _tabRoots = {'pending', 'history', 'users', 'more'};

  bool get _phone => !context.isWideScreen;

  bool get _isTabRoot =>
      _phone && !_showDashboard && _tabRoots.contains(_selectedSection);

  AdminTab? get _currentTab {
    if (_showDashboard) return AdminTab.home;
    return switch (_selectedSection) {
      'pending' || 'history' => AdminTab.bills,
      'users' => AdminTab.members,
      _ => AdminTab.more,
    };
  }

  void _openSection(String section) {
    // Account requests is its own screen (the super admin opens it too).
    if (section == 'requests') {
      context.push('/account-requests');
      return;
    }
    setState(() {
      _origin = !_tabRoots.contains(section) && _selectedSection == 'more'
          ? 'more'
          : null;
      _showDashboard = false;
      _selectedSection = section;
    });
  }

  void _backToDashboard() {
    setState(() {
      _showDashboard = true;
      _selectedSection = null;
      _origin = null;
    });
  }

  /// Back from a section: to More if it came from there, else the dashboard.
  void _goBack() {
    if (_origin == 'more') {
      setState(() {
        _selectedSection = 'more';
        _origin = null;
      });
    } else {
      _backToDashboard();
    }
  }

  void _onTab(AdminTab tab) {
    switch (tab) {
      case AdminTab.home:
        _backToDashboard();
      case AdminTab.bills:
        _openSection('pending');
      case AdminTab.members:
        _openSection('users');
      case AdminTab.more:
        _openSection('more');
    }
  }

  void _onRailSelected(int index) {
    final section = _adminRailSections[index];
    if (section == null) {
      _backToDashboard();
    } else {
      _openSection(section);
    }
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

    if (shouldLogout != true || !mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    final errorColor = context.themeError;
    final router = GoRouter.of(context);
    await ref.withLoader(() async {
      try {
        // Delete FCM token before signing out
        await FCMService().deleteToken();
        // Sign out from Firebase
        await FirebaseAuth.instance.signOut();
        // Clear secure session so splash redirects correctly by role.
        await SessionService().clearSession();
        router.go('/login');
      } catch (e) {
        messenger.showSnackBar(
          SnackBar(
            content: Text('${l10n.logoutFailed}: $e'),
            backgroundColor: errorColor,
          ),
        );
      }
    }, message: l10n.loggingOut);
  }

  Future<void> _deleteAllAdminNotifications() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: AppRadius.all16),
        title: AppText.h4(
          AppLocalizations.of(context)!.deleteAllNotifications2,
        ),
        content: AppText.body(
          AppLocalizations.of(context)!.areYouSureYouWantTo2,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(AppLocalizations.of(context)!.cancel),
          ),
          AppButton(
            label: AppLocalizations.of(context)!.delete,
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
      final snapshot = await appFirestore
          .collection('notification_logs')
          .where('type', whereIn: _adminNotificationTypes)
          .get();

      final docs = snapshot.docs.visibleToAdmin();
      if (docs.isEmpty) {
        if (!context.mounted) return;
        Navigator.of(context).pop(); // progress
        return;
      }

      // Firestore batch limit is 500 writes.
      const batchSize = 450;
      for (int i = 0; i < docs.length; i += batchSize) {
        final batch = appFirestore.batch();
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
          content: Text(
            AppLocalizations.of(
              context,
            )!.notificationSDeleted('${docs.length}'),
          ),
          backgroundColor: context.themePrimary,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      if (!context.mounted) return;
      Navigator.of(context).pop(); // progress
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context)!.deleteFailed('$e')),
          backgroundColor: context.themeError,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  /// Open enquiries for the More badge (none when they cannot be read).
  int _openEnquiries() {
    final async = ref.watch(enquiriesProvider(adminEnquiriesKey()));
    if (async.hasError) return 0;
    return async.asData?.value.where((e) => e.isOpen).length ?? 0;
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

          // From a section, Back returns to where it was opened from.
          if (!_showDashboard) {
            _goBack();
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
          // Tab screens on phones have no back arrow: the tab bar is there.
          automaticallyImplyLeading: false,
          leading: _showDashboard || _isTabRoot
              ? null
              : IconButton(
                  icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 22),
                  onPressed: _goBack,
                ),
          title: _showDashboard
              ? Padding(
                  padding: const EdgeInsets.only(left: 14),
                  child: Row(
                    mainAxisSize: MainAxisSize.max,
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
                              color: context.themeTextPrimary.withValues(
                                alpha: 0.15,
                              ),
                              borderRadius: AppRadius.sm8,
                            ),
                            child: Icon(
                              Icons.forest_rounded,
                              color: context.themeTextPrimary,
                              size: 22,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            AppText.label(
                              AppLocalizations.of(
                                context,
                              )!.balajiPointsAdminPanel,
                              color: context.themeTextPrimary,
                              maxLines: 1,
                            ),
                            const SizedBox(height: 2),
                            BranchNameLine(
                              fallback: AppConstants.shopNameShort,
                              style: AppTypography.caption(
                                color: context.themeTextSecondary,
                              ),
                            ),
                          ],
                        ),
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
          // Theme and logout: in the More tab on phones; wide screens (no
          // tab bar) keep them in the dashboard menu. Section screens show
          // only their own action (if any).
          actions: [
            // Home: notifications bell with the alerts count.
            if (_showDashboard)
              _AlertsBell(onTap: () => _openSection('notifications')),
            if (!_showDashboard && _selectedSection == 'users')
              const UsersFilterButton(),
            if (_showDashboard && !_phone)
              _AdminMoreMenu(onLogout: _handleLogout)
            else if (_selectedSection == 'notifications')
              IconButton(
                icon: const Icon(Icons.delete_outline_rounded, size: 24),
                onPressed: _deleteAllAdminNotifications,
                tooltip: AppLocalizations.of(context)!.deleteAllNotifications2,
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
        // Phones: admin tab bar, hidden while the keyboard is open so forms
        // keep their room.
        bottomNavigationBar:
            _phone && MediaQuery.viewInsetsOf(context).bottom == 0
            ? AdminBottomNavBar(
                current: _currentTab,
                onTab: _onTab,
                onAddBill: () => context.push('/admin/add-bill'),
                billsBadge:
                    ref.watch(adminPendingBillsCountProvider).value ?? 0,
                membersBadge: ref.watch(adminRequestsCountProvider).value ?? 0,
                moreBadge:
                    (ref.watch(adminAlertsCountProvider).value ?? 0) +
                    _openEnquiries(),
              )
            : null,
        body: Container(
          color: context.themeBackground,
          child: Column(
            children: [
              if (_showDashboard)
                const BranchBanner(margin: EdgeInsets.fromLTRB(16, 10, 16, 0)),
              Expanded(
                child: _branchGate(
                  (branch) => ResponsiveRoleNavigation(
                    roleLabel: branch.name,
                    items: _adminRailItems,
                    selectedIndex: _showDashboard
                        ? 0
                        : (_adminRailSections
                              .indexOf(_selectedSection)
                              .clamp(0, _adminRailSections.length - 1)),
                    onSelected: _onRailSelected,
                    child: Column(
                      children: [
                        Expanded(
                          child: _showDashboard
                              ? AdminDashboard(onOpenSection: _openSection)
                              : _buildSectionContent(_selectedSection!),
                        ),
                        // The Scaffold already shrinks for the keyboard;
                        // adding viewInsets here counted it twice and
                        // squeezed every admin form to nothing while typing.
                        // On phones the tab bar clears the system bar.
                        if (!_phone)
                          SizedBox(
                            height: MediaQuery.paddingOf(context).bottom,
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Branch admins only work inside their own branch: resolve it first and
  /// scope every admin query to it. Without a branch, show nothing.
  Widget _branchGate(Widget Function(CurrentBranch branch) builder) {
    final l10n = AppLocalizations.of(context)!;
    return ref
        .watch(currentBranchProvider)
        .when(
          loading: () => SuperAdminLoadingView(label: l10n.loadingBranch),
          error: (_, __) => Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: EmptyState(
              icon: Icons.store_mall_directory_outlined,
              title: l10n.noBranchAssigned,
            ),
          ),
          data: (branch) {
            CurrentBranchService.setAdminBranch(branch?.id);
            if (branch == null) {
              return Padding(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: EmptyState(
                  icon: Icons.store_mall_directory_outlined,
                  title: l10n.noBranchAssigned,
                ),
              );
            }
            return builder(branch);
          },
        );
  }

  String _sectionTitle(String section) {
    // On phones Pending and History are one Bills tab.
    if (_phone && (section == 'pending' || section == 'history')) {
      return AppLocalizations.of(context)!.adminTabBills;
    }
    switch (section) {
      case 'pending':
        return AppLocalizations.of(context)!.pendingBills;
      case 'history':
        return AppLocalizations.of(context)!.billHistory;
      case 'offers':
        return AppLocalizations.of(context)!.offers;
      case 'users':
        return AppLocalizations.of(context)!.users;
      case 'notifications':
        return AppLocalizations.of(context)!.notifications;
      case 'spin':
        return AppLocalizations.of(context)!.spin;
      case 'points-repair':
        return AppLocalizations.of(context)!.pointsRepair;
      case 'duplicates':
        return AppLocalizations.of(context)!.duplicateAccounts;
      case 'export-users':
        return AppLocalizations.of(context)!.exportUsers;
      case 'cleanup':
        return AppLocalizations.of(context)!.cleanUp;
      case 'backup':
        return AppLocalizations.of(context)!.backupDatabase;
      case 'check-duplicates':
        return AppLocalizations.of(context)!.checkFirebaseDuplicates;
      case 'smart-cleanup':
        return AppLocalizations.of(context)!.smartCleanup;
      case 'broadcast':
        return AppLocalizations.of(context)!.sendNotification;
      case 'greeting':
        return AppLocalizations.of(context)!.sendGreeting;
      case 'more':
        return AppLocalizations.of(context)!.navMore;
      case 'catalogs':
        return AppLocalizations.of(context)!.catalogs;
      case 'enquiries':
        return AppLocalizations.of(context)!.enquiries;
      default:
        return AppLocalizations.of(context)!.admin;
    }
  }

  Widget _usersCountTitle() {
    return StreamBuilder<QuerySnapshot>(
      stream: appFirestore.collection('users').forAdminBranch().snapshots(),
      builder: (context, snapshot) {
        final docs = snapshot.data?.docs ?? const [];
        // Match UsersList filtering:
        // - Exclude admins
        // - Include carpenters (role == 'carpenter') OR missing/empty role
        final count = docs.where((doc) {
          final data = doc.data() as Map<String, dynamic>;
          // Approved members only.
          return MemberFilter.isActiveMember(data);
        }).length;

        if (snapshot.connectionState == ConnectionState.waiting) {
          return AppText.label(
            AppLocalizations.of(context)!.users2,
            color: context.themeTextPrimary,
          );
        }

        return AppText.label(
          AppLocalizations.of(context)!.users3('$count'),
          color: context.themeTextPrimary,
        );
      },
    );
  }

  Widget _buildSectionContent(String section) {
    switch (section) {
      case 'pending':
      case 'history':
        if (_phone) {
          return AdminBillsTab(
            key: ValueKey(section),
            initial: section == 'history' ? 1 : 0,
            pendingCount: ref.watch(adminPendingBillsCountProvider).value ?? 0,
          );
        }
        return section == 'pending'
            ? const PendingBillsList()
            : const BillHistoryList();
      case 'more':
        return AdminMorePage(
          onOpenSection: _openSection,
          onLogout: _handleLogout,
          alertsBadge: ref.watch(adminAlertsCountProvider).value ?? 0,
          enquiriesBadge: _openEnquiries(),
        );
      case 'offers':
        return const OffersManagement();
      case 'users':
        if (_phone) {
          return AdminMembersTab(
            requestsCount: ref.watch(adminRequestsCountProvider).value ?? 0,
            onOpenRequests: () => _openSection('requests'),
          );
        }
        return const UsersList();
      case 'notifications':
        return AdminNotificationsPage(
          embedded: true,
          onOpenSection: _openSection,
        );
      case 'spin':
        return const DailySpinManagement();
      case 'points-repair':
        return const PointsRepairPage();
      case 'duplicates':
        return const DuplicateAccountsScreen();
      case 'export-users':
        return const ExportUsersBeforeCleanupScreen();
      case 'cleanup':
        return const CleanupDuplicateAccountsScreen();
      case 'backup':
        return const FirestoreBackupScreen();
      case 'check-duplicates':
        return const FirebaseDuplicateCheckerScreen();
      case 'smart-cleanup':
        return const SmartDuplicateCleanupScreen();
      case 'broadcast':
        return const SendNotificationPage();
      case 'greeting':
        return const SendGreetingPage(embedded: true);
      case 'catalogs':
        return const CatalogsManagement();
      case 'enquiries':
        // Only this admin's branch; never another branch's members.
        return Padding(
          padding: const EdgeInsets.all(16),
          child: EnquiriesManagement(branchId: adminEnquiriesKey()),
        );
      default:
        return const SizedBox.shrink();
    }
  }
}

// ---------------------------------------------------------------------------
// Home app bar: notifications bell with a count badge
// ---------------------------------------------------------------------------

class _AlertsBell extends ConsumerWidget {
  const _AlertsBell({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final count = ref.watch(adminAlertsCountProvider).value ?? 0;
    final l10n = AppLocalizations.of(context)!;
    return IconButton(
      key: const ValueKey('admin-alerts-bell'),
      tooltip: count > 0 ? '${l10n.notifications}, $count' : l10n.notifications,
      onPressed: onTap,
      icon: Badge(
        isLabelVisible: count > 0,
        backgroundColor: AppColors.gold,
        textColor: AppColors.primary,
        label: Text(count > 99 ? '99+' : '$count'),
        child: Icon(
          count > 0
              ? Icons.notifications_active_rounded
              : Icons.notifications_none_rounded,
          color: context.themeTextPrimary,
          size: 26,
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Dashboard "more" menu: theme and logout (not shown on section screens)
// ---------------------------------------------------------------------------

class _AdminMoreMenu extends ConsumerWidget {
  const _AdminMoreMenu({required this.onLogout});
  final VoidCallback onLogout;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return PopupMenuButton<String>(
      tooltip: l10n.adminMoreOptions,
      icon: Icon(Icons.more_vert_rounded, color: context.themeTextPrimary),
      shape: RoundedRectangleBorder(borderRadius: AppRadius.md12),
      onSelected: (value) {
        if (value == 'theme') {
          ref.read(themeModeProvider.notifier).toggleTheme();
        } else if (value == 'logout') {
          onLogout();
        }
      },
      itemBuilder: (context) => [
        PopupMenuItem(
          value: 'theme',
          child: Row(
            children: [
              Icon(
                isDark
                    ? Icons.wb_sunny_rounded
                    : Icons.nightlight_round_rounded,
                size: 20,
                color: context.themeContentColor,
              ),
              const SizedBox(width: 12),
              Text(isDark ? l10n.switchToLight : l10n.switchToDark),
            ],
          ),
        ),
        PopupMenuItem(
          value: 'logout',
          child: Row(
            children: [
              Icon(Icons.logout_rounded, size: 20, color: context.themeError),
              const SizedBox(width: 12),
              Text(l10n.logout, style: TextStyle(color: context.themeError)),
            ],
          ),
        ),
      ],
    );
  }
}
