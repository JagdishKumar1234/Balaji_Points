import 'package:balaji_points/core/design/app_radius.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:package_info_plus/package_info_plus.dart';

import 'package:balaji_points/core/design/app_colors.dart';
import 'package:balaji_points/core/design/app_typography.dart';
import 'package:balaji_points/core/layout/carpenter_shell_layout.dart';
import 'package:balaji_points/l10n/app_localizations.dart';
import 'package:balaji_points/providers/locale_provider.dart';
import 'package:balaji_points/providers/theme_provider.dart';
import 'package:balaji_points/presentation/widgets/carpenter/home_nav_bar.dart';
import 'package:balaji_points/services/notifications/fcm_service.dart';
import 'package:balaji_points/services/auth/session_service.dart';
import 'package:balaji_points/services/user/user_points_sync_service.dart';
import 'package:balaji_points/services/user/user_service.dart';

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

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
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
    } catch (_) {
      if (mounted) setState(() => _appVersion = 'Version 1.0.0');
    }
  }

  Future<void> _loadUserData({bool forceRefresh = false}) async {
    try {
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
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _subscribeUserPoints() async {
    if (_userPointsListener != null) {
      _userPointsSyncService.pointsData.removeListener(_userPointsListener!);
    }
    _userPointsListener = () {
      if (!mounted) return;
      final data = _userPointsSyncService.pointsData.value;
      if (data == null) return;
      setState(() => _userData = {...?_userData, ...data});
    };
    _userPointsSyncService.pointsData.addListener(_userPointsListener!);
    await _userPointsSyncService.start();
    _userPointsListener?.call();
  }

  String _displayName() {
    if (_userData == null) return 'User';
    final first = _userData!['firstName'] as String? ?? '';
    final last = _userData!['lastName'] as String? ?? '';
    final full = '$first $last'.trim();
    return full.isEmpty ? 'User' : full;
  }

  String _tier() => _userData?['tier'] as String? ?? 'Bronze';
  int _points() {
    final raw = _userData?['totalPoints'];
    return raw is num ? raw.toInt() : 0;
  }

  Future<void> _handleLogout(BuildContext context) async {
    final l10n = AppLocalizations.of(context)!;
    final shouldLogout = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: AppRadius.all16),
        title: Text(l10n.logout, style: AppTypography.h4()),
        content: Text(
          l10n.logoutConfirmation,
          style: AppTypography.bodyMedium(color: context.themeTextSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(l10n.no,
                style: AppTypography.labelLarge(color: context.themeTextSecondary)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: context.themeError,
              foregroundColor: AppColors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: AppRadius.md12),
            ),
            child: Text(l10n.yes,
                style: AppTypography.labelLarge(color: AppColors.white)
                    .copyWith(fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );

    if (shouldLogout == true && context.mounted) {
      try {
        await _fcmService.deleteToken();
        await _sessionService.clearSession();
        if (context.mounted) context.go('/login');
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('${l10n.logoutFailed}: ${e.toString()}'),
            backgroundColor: context.themeError,
          ));
        }
      }
    }
  }

  Future<void> _makePhoneCall(BuildContext context, String number) async {
    final uri = Uri(scheme: 'tel', path: number);
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
      } else {
        throw 'Could not launch $uri';
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Could not make call: $e'),
          backgroundColor: context.themeError,
        ));
      }
    }
  }

  void _showSupportDialog(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      barrierColor: AppColors.black.withValues(alpha: 0.5),
      builder: (context) => Dialog(
        backgroundColor: AppColors.transparent,
        insetPadding: const EdgeInsets.all(20),
        child: Container(
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: AppRadius.all24,
            boxShadow: [
              BoxShadow(
                color: AppColors.black.withValues(alpha: 0.2),
                blurRadius: 30,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [context.themePrimary, context.themeSecondary],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(24),
                      topRight: Radius.circular(24),
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.white.withValues(alpha: 0.2),
                          borderRadius: AppRadius.md12,
                        ),
                        child: const Icon(Icons.support_agent,
                            color: AppColors.white, size: 28),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(l10n.helpSupport,
                                style: AppTypography.h5(color: AppColors.white)),
                            const SizedBox(height: 4),
                            Text(l10n.getInTouch,
                                style: AppTypography.bodySmall(
                                    color: AppColors.white
                                        .withValues(alpha: 0.9))),
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.of(context).pop(),
                        icon: const Icon(Icons.close,
                            color: AppColors.white, size: 24),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(24),
                  child: _buildContactSection(
                    context: context,
                    title: l10n.contactUs,
                    icon: Icons.phone_rounded,
                    iconColor: const Color(0xFF43A047),
                    children: [
                      _buildContactItem(
                        context: context,
                        icon: Icons.phone_android_rounded,
                        label: l10n.mobile,
                        value: l10n.supportPhone1,
                        onTap: () => _makePhoneCall(context, '9600609121'),
                      ),
                      const SizedBox(height: 12),
                      _buildContactItem(
                        context: context,
                        icon: Icons.phone_rounded,
                        label: l10n.landline,
                        value: l10n.supportPhone2,
                        onTap: () => _makePhoneCall(context, '04243557187'),
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

  Widget _buildContactSection({
    required BuildContext context,
    required String title,
    required IconData icon,
    required Color iconColor,
    required List<Widget> children,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: iconColor.withValues(alpha: 0.05),
        borderRadius: AppRadius.all16,
        border: Border.all(color: iconColor.withValues(alpha: 0.2)),
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
                  borderRadius: AppRadius.md12,
                ),
                child: Icon(icon, color: iconColor, size: 22),
              ),
              const SizedBox(width: 12),
              Text(title, style: AppTypography.h5()),
            ],
          ),
          const SizedBox(height: 16),
          ...children,
        ],
      ),
    );
  }

  Widget _buildContactItem({
    required BuildContext context,
    required IconData icon,
    required String label,
    required String value,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: AppRadius.md12,
        boxShadow: [
          BoxShadow(
            color: AppColors.black.withValues(alpha: 0.05),
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
              color: AppColors.success.withValues(alpha: 0.1),
              borderRadius: AppRadius.sm8,
            ),
            child: Icon(icon, color: const Color(0xFF388E3C), size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: AppTypography.labelSmall(
                        color: context.themeTextSecondary)),
                const SizedBox(height: 6),
                Text(value,
                    style: AppTypography.labelLarge()
                        .copyWith(fontWeight: FontWeight.w600)),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Container(
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF43A047), Color(0xFF388E3C)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: AppRadius.md12,
              boxShadow: [
                BoxShadow(
                  color: AppColors.success.withValues(alpha: 0.30),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Material(
              color: AppColors.transparent,
              child: InkWell(
                borderRadius: AppRadius.md12,
                onTap: onTap,
                child: const Padding(
                  padding: EdgeInsets.all(12),
                  child: Icon(Icons.call_rounded,
                      color: AppColors.white, size: 22),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionHeader(String title, ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, top: 4),
      child: Text(
        title.toUpperCase(),
        style: AppTypography.overline(
          color: theme.colorScheme.onSurface.withValues(alpha: 0.55),
        ),
      ),
    );
  }

  Widget _menuButton({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);
    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: AppRadius.md12,
        boxShadow: [
          BoxShadow(
            color: AppColors.black.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: AppColors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: AppRadius.md12,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
            child: Row(
              children: [
                Icon(icon, color: context.themePrimary, size: 24),
                const SizedBox(width: 16),
                Text(
                  title,
                  style: AppTypography.labelLarge()
                      .copyWith(fontWeight: FontWeight.w600),
                ),
                const Spacer(),
                Icon(Icons.chevron_right, color: context.themeTextMuted),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _languageSelector() {
    final locale = ref.watch(localeProvider);
    final isHindi = locale.languageCode == 'hi';
    final theme = Theme.of(context);

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: AppRadius.md12,
        boxShadow: [
          BoxShadow(
            color: AppColors.black.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
        child: Row(
          children: [
            Icon(Icons.language, color: context.themePrimary, size: 24),
            const SizedBox(width: 16),
            Text(
              isHindi ? 'भाषा' : 'Language',
              style: AppTypography.labelLarge()
                  .copyWith(fontWeight: FontWeight.w600),
            ),
            const Spacer(),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: context.themePrimary.withValues(alpha: 0.1),
                borderRadius: AppRadius.sm8,
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<Locale>(
                  value: locale,
                  isDense: true,
                  icon: Icon(Icons.arrow_drop_down,
                      color: context.themePrimary, size: 20),
                  style: AppTypography.labelMedium(color: context.themePrimary),
                  dropdownColor: theme.colorScheme.surface,
                  borderRadius: AppRadius.md12,
                  onChanged: (Locale? newLocale) {
                    if (newLocale != null) {
                      ref
                          .read(localeProvider.notifier)
                          .setLocale(newLocale);
                    }
                  },
                  items: const [
                    DropdownMenuItem(value: Locale('en'), child: Text('English')),
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

  Widget _themeToggle() {
    final themeMode = ref.watch(themeModeProvider);
    final theme = Theme.of(context);

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: AppRadius.md12,
        boxShadow: [
          BoxShadow(
            color: AppColors.black.withValues(alpha: 0.1),
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
              themeMode == ThemeMode.dark ? Icons.dark_mode : Icons.light_mode,
              color: context.themePrimary,
              size: 24,
            ),
            const SizedBox(width: 16),
            Text('Theme',
                style: AppTypography.labelLarge(
                    color: theme.colorScheme.onSurface)
                    .copyWith(fontWeight: FontWeight.w600)),
            const Spacer(),
            SegmentedButton<ThemeMode>(
              style: SegmentedButton.styleFrom(
                selectedBackgroundColor: context.themePrimary,
                selectedForegroundColor: AppColors.white,
                side: BorderSide(color: theme.colorScheme.outline),
                padding: const EdgeInsets.symmetric(horizontal: 4),
                minimumSize: const Size(40, 36),
                textStyle: AppTypography.labelSmall(),
              ),
              segments: const [
                ButtonSegment(
                  value: ThemeMode.light,
                  label: Text('Light'),
                  icon: Icon(Icons.light_mode, size: 16),
                ),
                ButtonSegment(
                  value: ThemeMode.dark,
                  label: Text('Dark'),
                  icon: Icon(Icons.dark_mode, size: 16),
                ),
              ],
              selected: {
                themeMode == ThemeMode.system ? ThemeMode.light : themeMode
              },
              onSelectionChanged: (modes) {
                ref
                    .read(themeModeProvider.notifier)
                    .setThemeMode(modes.first);
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: Column(
        children: [
          HomeNavBar(
            title: l10n.profile,
            showLogo: false,
            showProfileButton: false,
          ),
          Expanded(
            child: Container(
              color: theme.colorScheme.surface,
              child: _isLoading
                  ? Center(
                      child: CircularProgressIndicator(
                          color: context.themePrimary))
                  : RefreshIndicator(
                      onRefresh: _handleRefresh,
                      color: context.themePrimary,
                      backgroundColor: theme.colorScheme.surface,
                      child: SingleChildScrollView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: EdgeInsets.only(
                          bottom: CarpenterShellLayout
                              .bottomPaddingForScrollView(
                                  MediaQuery.of(context)),
                        ),
                        child: Column(
                          children: [
                            const SizedBox(height: 24),

                            // Profile card
                            Container(
                              margin: const EdgeInsets.symmetric(horizontal: 20),
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                color: theme.colorScheme.surface,
                                borderRadius: AppRadius.all16,
                                boxShadow: [
                                  BoxShadow(
                                    color: AppColors.black
                                        .withValues(alpha: 0.1),
                                    blurRadius: 10,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: Column(
                                children: [
                                  // Avatar
                                  Container(
                                    width: 80,
                                    height: 80,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: context.themePrimary,
                                        width: 3,
                                      ),
                                    ),
                                    child: ClipOval(
                                      child: _userData?['profileImage'] !=
                                                  null &&
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
                                              loadingBuilder: (context, child,
                                                  progress) {
                                                if (progress == null) {
                                                  return child;
                                                }
                                                return Container(
                                                  color: context.themeSecondary
                                                      .withValues(alpha: 0.3),
                                                  child: Center(
                                                    child: CircularProgressIndicator(
                                                      value: progress
                                                                  .expectedTotalBytes !=
                                                              null
                                                          ? progress
                                                                  .cumulativeBytesLoaded /
                                                              progress
                                                                  .expectedTotalBytes!
                                                          : null,
                                                      strokeWidth: 3,
                                                      valueColor:
                                                          const AlwaysStoppedAnimation<
                                                                  Color>(
                                                              AppColors.primary),
                                                    ),
                                                  ),
                                                );
                                              },
                                              errorBuilder:
                                                  (context, error, _) =>
                                                      Container(
                                                color:
                                                    context.themeSecondary,
                                                child: const Icon(Icons.person,
                                                    color: AppColors.white,
                                                    size: 40),
                                              ),
                                            )
                                          : Container(
                                              color: context.themeSecondary,
                                              child: const Icon(Icons.person,
                                                  color: AppColors.white,
                                                  size: 40),
                                            ),
                                    ),
                                  ),
                                  const SizedBox(height: 16),

                                  Text(_displayName(),
                                      style: AppTypography.h4(),
                                      textAlign: TextAlign.center),
                                  const SizedBox(height: 4),

                                  if (_userData?['userDisplayId'] != null)
                                    Text(
                                      '#BP${_userData!['userDisplayId']}',
                                      style: AppTypography.labelMedium(
                                        color: context.themePrimary
                                            .withValues(alpha: 0.7),
                                      ).copyWith(letterSpacing: 0.5),
                                      textAlign: TextAlign.center,
                                    ),
                                  const SizedBox(height: 8),

                                  if (_userData?['phone'] != null)
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Icon(Icons.phone,
                                            size: 16,
                                            color: context.themeTextSecondary),
                                        const SizedBox(width: 6),
                                        Text(
                                          _userData!['phone'] as String,
                                          style: AppTypography.bodySmall(
                                              color: context.themeTextSecondary),
                                        ),
                                      ],
                                    ),
                                  const SizedBox(height: 8),

                                  // Points + tier
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.center,
                                    children: [
                                      const Icon(Icons.monetization_on,
                                          color: Color(0xFFFFA000),
                                          size: 18),
                                      const SizedBox(width: 4),
                                      Text(
                                        l10n.points(_points()),
                                        style: AppTypography.labelLarge(
                                          color: context.themePrimary,
                                        ).copyWith(fontWeight: FontWeight.w600),
                                      ),
                                      const SizedBox(width: 12),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 12, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: context.themeSecondary
                                              .withValues(alpha: 0.2),
                                          borderRadius:
                                              AppRadius.md12,
                                        ),
                                        child: Text(
                                          _tier(),
                                          style: AppTypography.labelSmall(
                                            color: context.themeSecondary,
                                          ).copyWith(fontWeight: FontWeight.w600),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),

                            const SizedBox(height: 24),

                            Padding(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 20),
                              child: Column(
                                crossAxisAlignment:
                                    CrossAxisAlignment.stretch,
                                children: [
                                  _sectionHeader(
                                      l10n.profileSectionAccount, theme),
                                  const SizedBox(height: 8),

                                  _menuButton(
                                    icon: Icons.edit,
                                    title: l10n.editProfile,
                                    onTap: () async {
                                      await context.push('/edit-profile');
                                      await _loadUserData(forceRefresh: true);
                                    },
                                  ),
                                  const SizedBox(height: 12),

                                  _menuButton(
                                    icon: Icons.lock_reset,
                                    title: l10n.changePin,
                                    onTap: () async {
                                      final phone = await _sessionService
                                          .getPhoneNumber();
                                      if (phone != null && context.mounted) {
                                        context.push(
                                            '/pin-reset?phone=$phone');
                                      }
                                    },
                                  ),
                                  const SizedBox(height: 12),

                                  _menuButton(
                                    icon: Icons.receipt_long,
                                    title: l10n.myOrders,
                                    onTap: () => context.push('/orders'),
                                  ),
                                  const SizedBox(height: 20),

                                  _sectionHeader(
                                      l10n.profileSectionSupport, theme),
                                  const SizedBox(height: 8),

                                  _menuButton(
                                    icon: Icons.phone,
                                    title: l10n.helpSupport,
                                    onTap: () =>
                                        _showSupportDialog(context),
                                  ),
                                  const SizedBox(height: 20),

                                  _sectionHeader(
                                      l10n.profileSectionPreferences,
                                      theme),
                                  const SizedBox(height: 8),

                                  _languageSelector(),
                                  const SizedBox(height: 12),
                                  _themeToggle(),

                                  const SizedBox(height: 24),

                                  // Logout button
                                  Container(
                                    width: double.infinity,
                                    margin: const EdgeInsets.only(top: 8),
                                    decoration: BoxDecoration(
                                      borderRadius:
                                          AppRadius.all16,
                                      boxShadow: [
                                        BoxShadow(
                                          color: context.themeError
                                              .withValues(alpha: 0.2),
                                          blurRadius: 10,
                                          offset: const Offset(0, 4),
                                        ),
                                      ],
                                    ),
                                    child: ElevatedButton(
                                      onPressed: () =>
                                          _handleLogout(context),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor:
                                            context.themeError,
                                        foregroundColor: AppColors.white,
                                        padding:
                                            const EdgeInsets.symmetric(
                                                vertical: 18),
                                        shape: RoundedRectangleBorder(
                                          borderRadius:
                                              AppRadius.all16,
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
                                            style: AppTypography.buttonLarge(
                                                color: AppColors.white),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),

                                  const SizedBox(height: 12),

                                  TextButton.icon(
                                    onPressed: () =>
                                        context.push('/about-us'),
                                    icon: Icon(
                                      Icons.info_outline_rounded,
                                      size: 20,
                                      color: context.themeSecondary,
                                    ),
                                    label: Text(
                                      l10n.profileAboutLink,
                                      style: AppTypography.labelLarge(
                                          color: context.themeSecondary)
                                          .copyWith(fontWeight: FontWeight.w600),
                                    ),
                                  ),

                                  const SizedBox(height: 8),

                                  if (_appVersion.isNotEmpty)
                                    Center(
                                      child: Text(
                                        _appVersion,
                                        style: AppTypography.caption(
                                          color: context.themeTextSecondary,
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
    );
  }
}
