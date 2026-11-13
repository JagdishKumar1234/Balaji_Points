import 'package:balaji_points/core/profile/profile_completeness.dart';
import 'package:balaji_points/services/branch/branch_support_service.dart';
import 'package:balaji_points/core/constants/app_constants.dart';
import 'package:balaji_points/core/design/app_radius.dart';
import 'package:flutter/material.dart';
import 'package:balaji_points/presentation/screens/carpenter/home/home_page.dart'
    show memberLogout;
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
import 'package:balaji_points/presentation/widgets/carpenter/member_identity.dart';
import 'package:balaji_points/presentation/widgets/shared/app_button.dart';
import 'package:balaji_points/presentation/widgets/shared/app_loader.dart';
import 'package:balaji_points/presentation/screens/carpenter/profile/widgets/profile_widgets.dart';
import 'package:balaji_points/services/auth/session_service.dart';
import 'package:balaji_points/providers/home_provider.dart';
import 'package:balaji_points/services/user/user_service.dart';
import 'package:balaji_points/services/user/user_points_sync_service.dart';

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

  Map<String, dynamic>? _userData;
  bool _isLoading = true;
  String _appVersion = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // Show what the app already has at once; the load below updates it silently.
    final known = ref.read(homeProvider).userData;
    if (known != null) {
      _userData = known;
      _isLoading = false;
    }
    _loadUserData();
    _loadAppVersion();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.resumed) {
      _loadUserData();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  Future<void> _handleRefresh() async {
    await ref.read(carpenterPointsProvider.notifier).refresh();
    await _loadUserData(forceRefresh: true);
  }

  Future<void> _loadAppVersion() async {
    try {
      final packageInfo = await PackageInfo.fromPlatform();
      if (mounted) {
        setState(() {
          _appVersion = AppLocalizations.of(
            context,
          )!.version('${packageInfo.version}', '${packageInfo.buildNumber}');
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
        final profileData = data != null
            ? Map<String, dynamic>.from(data)
            : null;
        profileData?.remove('totalPoints');
        profileData?.remove('tier');

        setState(() {
          _userData = profileData;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  String _displayName() {
    if (_userData == null) return AppLocalizations.of(context)!.user;
    final first = _userData!['firstName'] as String? ?? '';
    final last = _userData!['lastName'] as String? ?? '';
    final full = '$first $last'.trim();
    return full.isEmpty ? AppLocalizations.of(context)!.user : full;
  }

  /// Same logout as the Home side menu (confirm, loader, clean up).
  Future<void> _handleLogout(BuildContext context) =>
      memberLogout(context, ref);

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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '${AppLocalizations.of(context)!.couldNotMakeCall}: $e',
            ),
            backgroundColor: context.themeError,
          ),
        );
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
                    color: AppColors.primary,
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
                        child: const Icon(
                          Icons.support_agent_rounded,
                          color: AppColors.white,
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
                              style: AppTypography.h5(color: AppColors.white),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              l10n.getInTouch,
                              style: AppTypography.bodySmall(
                                color: AppColors.white.withValues(alpha: 0.9),
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.of(context).pop(),
                        icon: const Icon(
                          Icons.close_rounded,
                          color: AppColors.white,
                          size: 24,
                        ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
                  child: _buildBranchSupport(context),
                ),
                Padding(
                  padding: const EdgeInsets.all(24),
                  child: _buildContactSection(
                    context: context,
                    title: l10n.appSupport,
                    icon: Icons.support_agent_rounded,
                    iconColor: AppColors.success,
                    children: [
                      for (final (shown, dial)
                          in AppConstants.supportPhones) ...[
                        _buildContactItem(
                          context: context,
                          icon: Icons.phone_android_rounded,
                          label: l10n.mobile,
                          value: shown,
                          onTap: () => _makePhoneCall(context, dial),
                        ),
                        const SizedBox(height: 12),
                      ],
                      _buildContactItem(
                        context: context,
                        icon: Icons.email_outlined,
                        label: l10n.email,
                        value: AppConstants.supportEmail,
                        onTap: () => launchUrl(
                          Uri(
                            scheme: 'mailto',
                            path: AppConstants.supportEmail,
                          ),
                        ),
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

  /// The member's own branch: store phone and the branch admin's phone and
  /// email, read live so admin changes show up without an app update.
  Widget _buildBranchSupport(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Consumer(
      builder: (context, ref, _) {
        final support = ref.watch(branchSupportProvider).asData?.value;
        if (support == null || !support.hasAnyContact) {
          return const SizedBox.shrink();
        }
        return _buildContactSection(
          context: context,
          title: l10n.yourBranchSupport,
          icon: Icons.store_rounded,
          iconColor: context.themePrimary,
          children: [
            Text(
              support.branch.name,
              style: AppTypography.labelMedium(
                color: context.themeTextSecondary,
              ),
            ),
            const SizedBox(height: 12),
            if (support.branch.phone.isNotEmpty) ...[
              _buildContactItem(
                context: context,
                icon: Icons.phone_rounded,
                label: l10n.branchPhone,
                value: support.branch.phone,
                onTap: () => _makePhoneCall(
                  context,
                  BranchSupport.dialable(support.branch.phone),
                ),
              ),
              const SizedBox(height: 12),
            ],
            if (support.adminPhone.isNotEmpty) ...[
              _buildContactItem(
                context: context,
                icon: Icons.phone_android_rounded,
                label: support.adminName.isEmpty
                    ? l10n.branchAdmin
                    : '${l10n.branchAdmin} · ${support.adminName}',
                value: support.adminPhone,
                onTap: () => _makePhoneCall(
                  context,
                  BranchSupport.dialable(support.adminPhone),
                ),
              ),
              const SizedBox(height: 12),
            ],
            if (support.adminEmail.isNotEmpty)
              _buildContactItem(
                context: context,
                icon: Icons.email_outlined,
                label: l10n.email,
                value: support.adminEmail,
                onTap: () =>
                    launchUrl(Uri(scheme: 'mailto', path: support.adminEmail)),
              ),
          ],
        );
      },
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
            child: Icon(icon, color: AppColors.success, size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: AppTypography.labelSmall(
                    color: context.themeTextSecondary,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  value,
                  style: AppTypography.labelLarge().copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Container(
            decoration: BoxDecoration(
              color: AppColors.success,
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
                  child: Icon(
                    Icons.call_rounded,
                    color: AppColors.white,
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

  Widget _languageSelector() {
    final locale = ref.watch(localeProvider);
    final isHindi = locale.languageCode == 'hi';
    return ProfileMenuTile(
      icon: Icons.language_rounded,
      title: isHindi ? 'भाषा' : AppLocalizations.of(context)!.language,
      trailing: DropdownButtonHideUnderline(
        child: DropdownButton<Locale>(
          value: locale,
          isDense: true,
          icon: Icon(
            Icons.arrow_drop_down_rounded,
            color: context.themeContentColor,
          ),
          style: AppTypography.labelMedium(color: context.themeContentColor),
          dropdownColor: context.themeCard,
          borderRadius: AppRadius.md12,
          onChanged: (newLocale) {
            if (newLocale != null) {
              ref.read(localeProvider.notifier).setLocale(newLocale);
            }
          },
          items: [
            DropdownMenuItem(
              value: const Locale('en'),
              child: Text(AppLocalizations.of(context)!.languageEnglish),
            ),
            const DropdownMenuItem(value: Locale('hi'), child: Text('हिंदी')),
            const DropdownMenuItem(value: Locale('ta'), child: Text('தமிழ்')),
          ],
        ),
      ),
    );
  }

  Widget _themeToggle() {
    final themeMode = ref.watch(themeModeProvider);
    final l10n = AppLocalizations.of(context)!;
    return ProfileMenuTile(
      icon: themeMode == ThemeMode.dark
          ? Icons.dark_mode_rounded
          : Icons.light_mode_rounded,
      title: l10n.themeLabel,
      trailing: SegmentedButton<ThemeMode>(
        showSelectedIcon: false,
        style: SegmentedButton.styleFrom(
          selectedBackgroundColor: AppColors.gold,
          selectedForegroundColor: AppColors.primary,
          foregroundColor: context.themeContentColor,
          side: BorderSide(color: context.themeBorderStrong),
          padding: const EdgeInsets.symmetric(horizontal: 2),
          minimumSize: const Size(44, 36),
          visualDensity: VisualDensity.compact,
        ),
        segments: [
          ButtonSegment(
            value: ThemeMode.light,
            tooltip: l10n.themeLight,
            icon: const Icon(Icons.light_mode_rounded, size: 18),
          ),
          ButtonSegment(
            value: ThemeMode.dark,
            tooltip: l10n.themeDark,
            icon: const Icon(Icons.dark_mode_rounded, size: 18),
          ),
        ],
        selected: {themeMode == ThemeMode.system ? ThemeMode.light : themeMode},
        onSelectionChanged: (modes) {
          ref.read(themeModeProvider.notifier).setThemeMode(modes.first);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final carpenterPoints = ref.watch(carpenterPointsProvider);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: Column(
        children: [
          HomeNavBar(
            title: l10n.profile,
            showLogo: false,
            showProfileButton: false,
            // Quick logout, same confirmation as the button at the bottom.
            actions: [
              IconButton(
                tooltip: l10n.logout,
                onPressed: () => _handleLogout(context),
                icon: Icon(Icons.logout_rounded, color: context.themeError),
              ),
            ],
          ),
          Expanded(
            child: Container(
              color: theme.colorScheme.surface,
              child: _isLoading
                  ? const Center(child: AppLoader())
                  : RefreshIndicator(
                      onRefresh: _handleRefresh,
                      color: context.themePrimary,
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
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            ProfileHeader(
                              name: _displayName(),
                              roleName: memberRoleName(context, _userData),
                              imageUrl: _userData?['profileImage'] as String?,
                              displayId: _userData?['userDisplayId']
                                  ?.toString(),
                              phone: _userData?['phone'] as String?,
                              points: carpenterPoints.formattedPoints,
                              tier: carpenterPoints.tier,
                            ),
                            Padding(
                              padding: const EdgeInsets.fromLTRB(
                                20,
                                24,
                                20,
                                20,
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  ProfileChecklist(
                                    completeness: ProfileCompleteness.from(
                                      _userData,
                                    ),
                                    onComplete: () async {
                                      await context.push('/edit-profile');
                                      await _loadUserData(forceRefresh: true);
                                    },
                                  ),
                                  const SizedBox(height: 20),
                                  ProfileMenuGroup(
                                    title: l10n.profileSectionAccount,
                                    children: [
                                      ProfileMenuTile(
                                        icon: Icons.edit_rounded,
                                        title: l10n.editProfile,
                                        onTap: () async {
                                          await context.push('/edit-profile');
                                          await _loadUserData(
                                            forceRefresh: true,
                                          );
                                        },
                                      ),
                                      ProfileMenuTile(
                                        icon: Icons.store_rounded,
                                        title: l10n.myBranch,
                                        onTap: () => context.push('/my-branch'),
                                      ),
                                      ProfileMenuTile(
                                        icon: Icons.lock_reset_rounded,
                                        title: l10n.changePin,
                                        onTap: () async {
                                          final phone = await _sessionService
                                              .getPhoneNumber();
                                          if (phone != null &&
                                              context.mounted) {
                                            context.push(
                                              '/pin-reset?phone=$phone',
                                            );
                                          }
                                        },
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 20),
                                  ProfileMenuGroup(
                                    title: l10n.profileSectionSupport,
                                    children: [
                                      ProfileMenuTile(
                                        icon: Icons.mark_email_unread_rounded,
                                        title: l10n.contactUs,
                                        onTap: () =>
                                            context.push('/contact-us'),
                                      ),
                                      ProfileMenuTile(
                                        icon: Icons.support_agent_rounded,
                                        title: l10n.helpSupport,
                                        onTap: () =>
                                            _showSupportDialog(context),
                                      ),
                                      ProfileMenuTile(
                                        icon: Icons.info_rounded,
                                        title: l10n.profileAboutLink,
                                        onTap: () => context.push('/about-us'),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 20),
                                  ProfileMenuGroup(
                                    title: l10n.profileSectionLegal,
                                    children: [
                                      ProfileMenuTile(
                                        icon: Icons.gavel_rounded,
                                        title: l10n.legalTermsTitle,
                                        onTap: () => context.push('/terms'),
                                      ),
                                      ProfileMenuTile(
                                        icon: Icons.privacy_tip_rounded,
                                        title: l10n.legalPrivacyTitle,
                                        onTap: () => context.push('/privacy'),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 20),
                                  ProfileMenuGroup(
                                    title: l10n.profileSectionPreferences,
                                    children: [
                                      _languageSelector(),
                                      _themeToggle(),
                                    ],
                                  ),
                                  const SizedBox(height: 24),
                                  AppButton.danger(
                                    label: l10n.logout,
                                    icon: Icons.logout_rounded,
                                    onPressed: () => _handleLogout(context),
                                  ),
                                  if (_appVersion.isNotEmpty) ...[
                                    const SizedBox(height: 12),
                                    Text(
                                      _appVersion,
                                      textAlign: TextAlign.center,
                                      style: AppTypography.caption(
                                        color: context.themeTextSecondary,
                                      ),
                                    ),
                                  ],
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
