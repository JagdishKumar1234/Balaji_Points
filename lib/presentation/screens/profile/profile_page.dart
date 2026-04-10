import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:balaji_points/l10n/app_localizations.dart';
import 'package:balaji_points/core/theme/design_token.dart';
import 'package:balaji_points/config/theme.dart' hide AppColors;
import 'package:balaji_points/services/user_service.dart';
import 'package:balaji_points/services/session_service.dart';
import 'package:balaji_points/services/fcm_service.dart';
import 'package:balaji_points/services/user_points_sync_service.dart';
import 'package:balaji_points/presentation/providers/theme_provider.dart';
import 'package:balaji_points/presentation/providers/locale_provider.dart';
import 'package:balaji_points/presentation/widgets/home_nav_bar.dart';
import 'package:balaji_points/core/layout/carpenter_shell_layout.dart';

class ProfilePage extends ConsumerStatefulWidget {
  final bool showBottomNav;

  const ProfilePage({super.key, this.showBottomNav = true});

  @override
  ConsumerState<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends ConsumerState<ProfilePage>
    with WidgetsBindingObserver {
  final UserService _userService = UserService();
  final SessionService _sessionService = SessionService();
  final FCMService _fcmService = FCMService();
  final UserPointsSyncService _userPointsSyncService = UserPointsSyncService();
  Map<String, dynamic>? _userData;
  bool _isLoading = true;
  String _appVersion = '';
  VoidCallback? _userPointsListener;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadUserData();
    _loadAppVersion();
    _subscribeUserPoints();
  }

  Future<void> _handleRefresh() async {
    await _loadUserData();
    await _subscribeUserPoints();
  }

  Future<void> _loadAppVersion() async {
    try {
      final packageInfo = await PackageInfo.fromPlatform();
      if (mounted) {
        setState(() {
          _appVersion =
              'Version ${packageInfo.version} (${packageInfo.buildNumber})';
        });
      }
    } catch (e) {
      debugPrint('ProfilePage: Error loading app version: $e');
      if (mounted) {
        setState(() {
          _appVersion = 'Version 1.0.0';
        });
      }
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    // Reload user data when app comes to foreground
    if (state == AppLifecycleState.resumed) {
      _loadUserData();
      _subscribeUserPoints();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    if (_userPointsListener != null) {
      _userPointsSyncService.pointsData.removeListener(_userPointsListener!);
    }
    super.dispose();
  }

  Future<void> _loadUserData({bool forceRefresh = false}) async {
    try {
      debugPrint(
        'ProfilePage: Loading user data (forceRefresh: $forceRefresh)',
      );
      final data = await _userService.getCurrentUserData(
        forceRefresh: forceRefresh,
      );
      if (data != null) {
        await _sessionService.updateProfile(
          firstName: data['firstName'] as String?,
          lastName: data['lastName'] as String?,
          profileImage: data['profileImage'] as String?,
        );
      }
      if (mounted) {
        setState(() {
          _userData = data;
          _isLoading = false;
        });
        debugPrint('ProfilePage: User data loaded');
        debugPrint('  firstName: ${data?['firstName']}');
        debugPrint('  lastName: ${data?['lastName']}');
        debugPrint('  profileImage: ${data?['profileImage']}');
      }
    } catch (e) {
      debugPrint('ProfilePage: Error loading user data: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _subscribeUserPoints() async {
    _userPointsListener ??= () {
      if (!mounted) return;
      final data = _userPointsSyncService.pointsData.value;
      if (data == null) return;

      setState(() {
        _userData = {...?_userData, ...data};
      });
    };
    _userPointsSyncService.pointsData.removeListener(_userPointsListener!);
    _userPointsSyncService.pointsData.addListener(_userPointsListener!);
    await _userPointsSyncService.start();
    _userPointsListener?.call();
  }

  String _getUserDisplayName() {
    if (_userData == null) return 'User';
    final firstName = _userData!['firstName'] as String? ?? '';
    final lastName = _userData!['lastName'] as String? ?? '';
    return '$firstName $lastName'.trim().isEmpty
        ? 'User'
        : '$firstName $lastName'.trim();
  }

  String _getUserTier() {
    return _userData?['tier'] as String? ?? 'Bronze';
  }

  int _getUserPoints() {
    return _userData?['totalPoints'] as int? ?? 0;
  }

  Future<void> _handleLogout(BuildContext context, WidgetRef ref) async {
    final l10n = AppLocalizations.of(context)!;

    // Show confirmation dialog
    final shouldLogout = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          l10n.logout,
          style: AppTextStyles.nunitoBold.copyWith(fontSize: 22),
        ),
        content: Text(
          l10n.logoutConfirmation,
          style: AppTextStyles.nunitoRegular.copyWith(fontSize: 16),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(
              l10n.no,
              style: AppTextStyles.nunitoMedium.copyWith(
                color: DesignToken.grey600,
                fontSize: 16,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: DesignToken.error,
              foregroundColor: DesignToken.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text(
              l10n.yes,
              style: AppTextStyles.nunitoSemiBold.copyWith(fontSize: 16),
            ),
          ),
        ],
      ),
    );

    // If user confirmed logout
    if (shouldLogout == true && context.mounted) {
      try {
        // Delete FCM token before clearing session
        await _fcmService.deleteToken();

        // Clear session (logout)
        await _sessionService.clearSession();

        // Navigate to login screen
        if (context.mounted) {
          context.go('/login');
        }
      } catch (e) {
        // Show error if logout fails
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${l10n.logoutFailed}: ${e.toString()}'),
              backgroundColor: DesignToken.error,
            ),
          );
        }
      }
    }
  }

  void _onBottomNavTapped(int index) {
    switch (index) {
      case 0:
        context.go('/');
        break;
      case 1:
        context.go('/');
        break;
      case 2:
        // Already on profile page
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: Column(
        children: [
          // Modern Navigation Bar - Consistent height
          HomeNavBar(
            title: l10n.profile,
            showLogo: false,
            showProfileButton:
                false, // Don't show profile button on profile screen
          ),
          // Content
          Expanded(
            child: Container(
              color: theme.colorScheme.surface,
              child: _isLoading
                  ? const Center(
                      child: CircularProgressIndicator(
                        color: DesignToken.primary,
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _handleRefresh,
                      color: DesignToken.primary,
                      backgroundColor: theme.colorScheme.surface,
                      child: SingleChildScrollView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: EdgeInsets.only(
                          bottom:
                              CarpenterShellLayout.bottomPaddingForScrollView(
                                MediaQuery.of(context),
                              ),
                        ),
                        child: Column(
                          children: [
                            const SizedBox(height: 24),

                            // Simple Profile Card
                            Container(
                              margin: const EdgeInsets.symmetric(
                                horizontal: 20,
                              ),
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                color: theme.colorScheme.surface,
                                borderRadius: BorderRadius.circular(16),
                                boxShadow: [
                                  BoxShadow(
                                    color: DesignToken.black.withValues(
                                      alpha: 0.1,
                                    ),
                                    blurRadius: 10,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: Column(
                                children: [
                                  // Profile Image
                                  Container(
                                    width: 80,
                                    height: 80,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: DesignToken.primary,
                                        width: 3,
                                      ),
                                    ),
                                    child: ClipOval(
                                      child:
                                          _userData?['profileImage'] != null &&
                                              (_userData!['profileImage']
                                                      as String)
                                                  .isNotEmpty
                                          ? Image.network(
                                              _userData!['profileImage']
                                                  as String,
                                              key: ValueKey<String>(
                                                _userData!['profileImage']
                                                    as String,
                                              ),
                                              fit: BoxFit.cover,
                                              loadingBuilder: (context, child, loadingProgress) {
                                                if (loadingProgress == null)
                                                  return child;
                                                return Container(
                                                  color: DesignToken.secondary
                                                      .withValues(alpha: 0.3),
                                                  child: Center(
                                                    child: CircularProgressIndicator(
                                                      value:
                                                          loadingProgress
                                                                  .expectedTotalBytes !=
                                                              null
                                                          ? loadingProgress
                                                                    .cumulativeBytesLoaded /
                                                                loadingProgress
                                                                    .expectedTotalBytes!
                                                          : null,
                                                      strokeWidth: 3,
                                                      valueColor:
                                                          AlwaysStoppedAnimation<
                                                            Color
                                                          >(
                                                            DesignToken.primary,
                                                          ),
                                                    ),
                                                  ),
                                                );
                                              },
                                              errorBuilder:
                                                  (context, error, stackTrace) {
                                                    debugPrint(
                                                      'ProfilePage: Error loading profile image: $error',
                                                    );
                                                    return Container(
                                                      color:
                                                          DesignToken.secondary,
                                                      child: const Icon(
                                                        Icons.person,
                                                        color:
                                                            DesignToken.white,
                                                        size: 40,
                                                      ),
                                                    );
                                                  },
                                            )
                                          : Container(
                                              color: DesignToken.secondary,
                                              child: const Icon(
                                                Icons.person,
                                                color: DesignToken.white,
                                                size: 40,
                                              ),
                                            ),
                                    ),
                                  ),
                                  const SizedBox(height: 16),

                                  // User Name
                                  Text(
                                    _getUserDisplayName(),
                                    style: AppTextStyles.nunitoBold.copyWith(
                                      fontSize: 20,
                                      color: DesignToken.textDark,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                  const SizedBox(height: 4),

                                  // User Display ID
                                  if (_userData?['userDisplayId'] != null)
                                    Text(
                                      '#BP${_userData!['userDisplayId']}',
                                      style: AppTextStyles.nunitoMedium
                                          .copyWith(
                                            fontSize: 14,
                                            color: DesignToken.primary
                                                .withValues(alpha: 0.7),
                                            letterSpacing: 0.5,
                                          ),
                                      textAlign: TextAlign.center,
                                    ),
                                  const SizedBox(height: 8),

                                  // Phone Number
                                  if (_userData?['phone'] != null)
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          Icons.phone,
                                          size: 16,
                                          color: DesignToken.grey600,
                                        ),
                                        const SizedBox(width: 6),
                                        Text(
                                          _userData!['phone'] as String,
                                          style: AppTextStyles.nunitoRegular
                                              .copyWith(
                                                fontSize: 14,
                                                color: DesignToken.grey600,
                                              ),
                                          textAlign: TextAlign.center,
                                        ),
                                      ],
                                    ),
                                  const SizedBox(height: 8),

                                  // Points and Tier
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.monetization_on,
                                        color: DesignToken.amberShade700,
                                        size: 18,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        l10n.points(_getUserPoints()),
                                        style: AppTextStyles.nunitoSemiBold
                                            .copyWith(
                                              fontSize: 16,
                                              color: DesignToken.primary,
                                            ),
                                      ),
                                      const SizedBox(width: 12),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 12,
                                          vertical: 4,
                                        ),
                                        decoration: BoxDecoration(
                                          color: DesignToken.secondary
                                              .withOpacity(0.2),
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                        ),
                                        child: Text(
                                          _getUserTier(),
                                          style: AppTextStyles.nunitoSemiBold
                                              .copyWith(
                                                fontSize: 14,
                                                color: DesignToken.secondary,
                                              ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),

                            const SizedBox(height: 24),

                            // Simple Menu Items
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 20,
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  _profileSectionHeader(
                                    l10n.profileSectionAccount,
                                    theme,
                                  ),
                                  const SizedBox(height: 8),
                                  // Edit Profile Button
                                  _buildSimpleButton(
                                    icon: Icons.edit,
                                    title: l10n.editProfile,
                                    onTap: () async {
                                      // Navigate to edit profile and wait for return
                                      await context.push('/edit-profile');
                                      // Force refresh user data from server when returning
                                      debugPrint(
                                        'ProfilePage: Returned from edit profile, force refreshing data',
                                      );
                                      await _loadUserData(forceRefresh: true);
                                    },
                                  ),
                                  const SizedBox(height: 12),

                                  // Change PIN Button
                                  _buildSimpleButton(
                                    icon: Icons.lock_reset,
                                    title: l10n.changePin,
                                    onTap: () async {
                                      // Get current phone number from session
                                      final phoneNumber = await _sessionService
                                          .getPhoneNumber();
                                      if (phoneNumber != null &&
                                          context.mounted) {
                                        context.push(
                                          '/pin-reset?phone=$phoneNumber',
                                        );
                                      }
                                    },
                                  ),
                                  const SizedBox(height: 12),

                                  // My Orders Button
                                  _buildSimpleButton(
                                    icon: Icons.receipt_long,
                                    title: l10n.myOrders,
                                    onTap: () {
                                      context.push('/orders');
                                    },
                                  ),
                                  const SizedBox(height: 20),

                                  _profileSectionHeader(
                                    l10n.profileSectionSupport,
                                    theme,
                                  ),
                                  const SizedBox(height: 8),
                                  // Help & Support Button
                                  _buildSimpleButton(
                                    icon: Icons.phone,
                                    title: l10n.helpSupport,
                                    onTap: () => _showSupportDialog(context),
                                  ),
                                  const SizedBox(height: 20),

                                  _profileSectionHeader(
                                    l10n.profileSectionPreferences,
                                    theme,
                                  ),
                                  const SizedBox(height: 8),

                                  // Language Selection Button
                                  _buildLanguageSelector(ref),
                                  const SizedBox(height: 12),

                                  // Theme Toggle Button
                                  _buildThemeToggleButton(ref),

                                  const SizedBox(height: 24),

                                  // Logout Button
                                  Container(
                                    width: double.infinity,
                                    margin: const EdgeInsets.only(top: 8),
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(16),
                                      boxShadow: [
                                        BoxShadow(
                                          color: DesignToken.error.withOpacity(
                                            0.2,
                                          ),
                                          blurRadius: 10,
                                          offset: const Offset(0, 4),
                                        ),
                                      ],
                                    ),
                                    child: ElevatedButton(
                                      onPressed: () =>
                                          _handleLogout(context, ref),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor:
                                            DesignToken.redShade600,
                                        foregroundColor: DesignToken.white,
                                        padding: const EdgeInsets.symmetric(
                                          vertical: 18,
                                        ),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            16,
                                          ),
                                        ),
                                        elevation: 0,
                                      ),
                                      child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          const Icon(Icons.logout, size: 22),
                                          const SizedBox(width: 12),
                                          Text(
                                            l10n.logout,
                                            style: AppTextStyles.nunitoBold
                                                .copyWith(
                                                  fontSize: 18,
                                                  color: DesignToken.white,
                                                ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),

                                  const SizedBox(height: 12),

                                  TextButton.icon(
                                    onPressed: () => context.push('/about-us'),
                                    icon: Icon(
                                      Icons.info_outline_rounded,
                                      size: 20,
                                      color: DesignToken.secondary,
                                    ),
                                    label: Text(
                                      l10n.profileAboutLink,
                                      style: AppTextStyles.nunitoSemiBold
                                          .copyWith(
                                            fontSize: 15,
                                            color: DesignToken.secondary,
                                          ),
                                    ),
                                  ),

                                  const SizedBox(height: 8),

                                  // App Version
                                  if (_appVersion.isNotEmpty)
                                    Center(
                                      child: Text(
                                        _appVersion,
                                        style: AppTextStyles.nunitoRegular
                                            .copyWith(
                                              fontSize: 13,
                                              color: DesignToken.textDark
                                                  .withValues(alpha: 0.5),
                                            ),
                                      ),
                                    ),

                                  const SizedBox(height: 20),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: widget.showBottomNav
          ? BottomNavigationBar(
              currentIndex: 2, // Profile tab selected
              onTap: _onBottomNavTapped,
              selectedItemColor: DesignToken.secondary,
              unselectedItemColor: theme.colorScheme.onSurface,
              backgroundColor: theme.colorScheme.surface,
              type: BottomNavigationBarType.fixed,
              items: [
                BottomNavigationBarItem(
                  icon: const Icon(Icons.home),
                  label: l10n.home,
                ),
                BottomNavigationBarItem(
                  icon: const Icon(Icons.monetization_on_outlined),
                  label: l10n.addPoints,
                ),
                BottomNavigationBarItem(
                  icon: const Icon(Icons.person_outline),
                  label: l10n.profile,
                ),
              ],
            )
          : null,
    );
  }

  Future<void> _makePhoneCall(BuildContext context, String phoneNumber) async {
    final Uri phoneUri = Uri(scheme: 'tel', path: phoneNumber);
    try {
      if (await canLaunchUrl(phoneUri)) {
        await launchUrl(phoneUri);
      } else {
        throw 'Could not launch $phoneUri';
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not make call: $e'),
            backgroundColor: DesignToken.error,
          ),
        );
      }
    }
  }

  void _showSupportDialog(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    showDialog(
      context: context,
      barrierColor: DesignToken.black.withValues(alpha: 0.5),
      builder: (context) => Dialog(
        backgroundColor: DesignToken.transparent,
        insetPadding: const EdgeInsets.all(20),
        child: Container(
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: DesignToken.black.withValues(alpha: 0.2),
                blurRadius: 30,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header with Gradient
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [DesignToken.primary, DesignToken.secondary],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(24),
                      topRight: Radius.circular(24),
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: DesignToken.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.support_agent,
                          color: DesignToken.white,
                          size: 28,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              l10n.helpSupport,
                              style: AppTextStyles.nunitoBold.copyWith(
                                fontSize: 22,
                                color: DesignToken.white,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              l10n.getInTouch,
                              style: AppTextStyles.nunitoRegular.copyWith(
                                fontSize: 14,
                                color: DesignToken.white.withValues(alpha: 0.9),
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.of(context).pop(),
                        icon: const Icon(
                          Icons.close,
                          color: DesignToken.white,
                          size: 24,
                        ),
                      ),
                    ],
                  ),
                ),

                // Content
                Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Phone Numbers Section with Action Buttons
                      _buildModernContactSection(
                        title: l10n.contactUs,
                        icon: Icons.phone_rounded,
                        iconColor: DesignToken.greenShade600,
                        children: [
                          _buildActionableContactItem(
                            context: context,
                            icon: Icons.phone_android_rounded,
                            label: l10n.mobile,
                            value: l10n.supportPhone1,
                            phoneNumber: '9600609121',
                            onTap: () => _makePhoneCall(context, '9600609121'),
                          ),
                          const SizedBox(height: 12),
                          _buildActionableContactItem(
                            context: context,
                            icon: Icons.phone_rounded,
                            label: l10n.landline,
                            value: l10n.supportPhone2,
                            phoneNumber: '04243557187',
                            onTap: () => _makePhoneCall(context, '04243557187'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildModernContactSection({
    required String title,
    required IconData icon,
    required Color iconColor,
    required List<Widget> children,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: iconColor.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: iconColor.withValues(alpha: 0.2), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: iconColor, size: 22),
              ),
              const SizedBox(width: 12),
              Text(
                title,
                style: AppTextStyles.nunitoBold.copyWith(
                  fontSize: 18,
                  color: DesignToken.textDark,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...children,
        ],
      ),
    );
  }

  Widget _buildActionableContactItem({
    required BuildContext context,
    required IconData icon,
    required String label,
    required String value,
    required String phoneNumber,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: DesignToken.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: DesignToken.success.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: DesignToken.greenShade700, size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: AppTextStyles.nunitoMedium.copyWith(
                    fontSize: 12,
                    color: DesignToken.grey600,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  value,
                  style: AppTextStyles.nunitoSemiBold.copyWith(
                    fontSize: 16,
                    color: DesignToken.textDark,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          // Call Button
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [DesignToken.greenShade600, DesignToken.greenShade700],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: DesignToken.success.withValues(alpha: 0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Material(
              color: DesignToken.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: onTap,
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Icon(
                    Icons.call_rounded,
                    color: DesignToken.white,
                    size: 22,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _profileSectionHeader(String title, ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, top: 4),
      child: Text(
        title.toUpperCase(),
        style: AppTextStyles.nunitoSemiBold.copyWith(
          fontSize: 12,
          letterSpacing: 0.8,
          color: theme.colorScheme.onSurface.withValues(alpha: 0.55),
        ),
      ),
    );
  }

  Widget _buildSimpleButton({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);
    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: DesignToken.black.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: DesignToken.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
            child: Row(
              children: [
                Icon(icon, color: DesignToken.primary, size: 24),
                const SizedBox(width: 16),
                Text(
                  title,
                  style: AppTextStyles.nunitoSemiBold.copyWith(
                    fontSize: 16,
                    color: DesignToken.textDark,
                  ),
                ),
                const Spacer(),
                const Icon(Icons.chevron_right, color: DesignToken.grey400),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLanguageSelector(WidgetRef ref) {
    final locale = ref.watch(localeProvider);
    final isHindi = locale.languageCode == 'hi';
    final theme = Theme.of(context);

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: DesignToken.black.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
        child: Row(
          children: [
            const Icon(Icons.language, color: DesignToken.primary, size: 24),
            const SizedBox(width: 16),
            Text(
              isHindi ? 'भाषा' : 'Language',
              style: AppTextStyles.nunitoSemiBold.copyWith(
                fontSize: 16,
                color: DesignToken.textDark,
              ),
            ),
            const Spacer(),
            // Language Dropdown
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: DesignToken.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<Locale>(
                  value: locale,
                  isDense: true,
                  icon: Icon(
                    Icons.arrow_drop_down,
                    color: DesignToken.primary,
                    size: 20,
                  ),
                  style: AppTextStyles.nunitoSemiBold.copyWith(
                    fontSize: 14,
                    color: DesignToken.primary,
                  ),
                  dropdownColor: theme.colorScheme.surface,
                  borderRadius: BorderRadius.circular(12),
                  onChanged: (Locale? newLocale) {
                    if (newLocale != null) {
                      ref.read(localeProvider.notifier).setLocale(newLocale);
                    }
                  },
                  items: const [
                    DropdownMenuItem(
                      value: Locale('en'),
                      child: Text('English'),
                    ),
                    DropdownMenuItem(value: Locale('hi'), child: Text('हिंदी')),
                    DropdownMenuItem(value: Locale('ta'), child: Text('தமிழ்')),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildThemeToggleButton(WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);
    final isDark = themeMode == ThemeMode.dark;
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: DesignToken.black.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
        child: Row(
          children: [
            Icon(
              isDark ? Icons.dark_mode : Icons.light_mode,
              color: DesignToken.primary,
              size: 24,
            ),
            const SizedBox(width: 16),
            Text(
              l10n.darkMode,
              style: AppTextStyles.nunitoSemiBold.copyWith(
                fontSize: 16,
                color: DesignToken.textDark,
              ),
            ),
            const Spacer(),
            Switch(
              value: isDark,
              onChanged: (value) {
                ref.read(themeModeProvider.notifier).toggleTheme();
              },
              activeTrackColor: DesignToken.primary,
            ),
          ],
        ),
      ),
    );
  }
}
