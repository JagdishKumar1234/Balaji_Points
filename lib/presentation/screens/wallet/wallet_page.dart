import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:balaji_points/l10n/app_localizations.dart';
import 'package:balaji_points/core/theme/design_token.dart';
import 'package:balaji_points/config/theme.dart' hide AppColors;
import 'package:balaji_points/services/session_service.dart';
import 'package:balaji_points/services/user_points_sync_service.dart';
import '../../widgets/home_nav_bar.dart';
import 'package:balaji_points/core/layout/carpenter_shell_layout.dart';

class WalletPage extends StatefulWidget {
  const WalletPage({super.key});

  @override
  State<WalletPage> createState() => _WalletPageState();
}

class _WalletPageState extends State<WalletPage> {
  final SessionService _sessionService = SessionService();
  final UserPointsSyncService _userPointsSyncService = UserPointsSyncService();
  int _refreshKey = 0;
  List<String> _carpenterIds = [];
  bool _idsLoaded = false;
  VoidCallback? _userPointsListener;

  @override
  void initState() {
    super.initState();
    _loadCarpenterIds();
    _startGlobalPointsSync();
  }

  @override
  void dispose() {
    if (_userPointsListener != null) {
      _userPointsSyncService.pointsData.removeListener(_userPointsListener!);
    }
    super.dispose();
  }

  Future<void> _loadCarpenterIds() async {
    final ids = await _sessionService.getCarpenterQueryIds();
    if (mounted) {
      setState(() {
        _carpenterIds = ids;
        _idsLoaded = true;
      });
    }
  }

  Future<void> _startGlobalPointsSync() async {
    _userPointsListener ??= () {
      if (!mounted) return;
      setState(() {});
    };
    _userPointsSyncService.pointsData.removeListener(_userPointsListener!);
    _userPointsSyncService.pointsData.addListener(_userPointsListener!);
    await _userPointsSyncService.start();
    _userPointsListener?.call();
  }

  Future<void> _handleRefresh() async {
    await _loadCarpenterIds();
    setState(() {
      _refreshKey++; // Force rebuild of StreamBuilders
    });
    await _userPointsSyncService.refresh();
    // Add a small delay to show the refresh indicator
    await Future.delayed(const Duration(milliseconds: 500));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    final idsReady = _idsLoaded && _carpenterIds.isNotEmpty;

    final theme = Theme.of(context);
    final pageBackground = theme.scaffoldBackgroundColor;
    final bottomPadding = CarpenterShellLayout.bottomPaddingForScrollView(
      MediaQuery.of(context),
    );
    return Scaffold(
      backgroundColor: pageBackground,
      body: Column(
        children: [
          // Standard Navigation Bar - Material Design kToolbarHeight (56dp)
          HomeNavBar(
            title: l10n.wallet,
            showLogo: false,
            showProfileButton: false,
          ),
          // Content area
          Expanded(
            child: Container(
              color: pageBackground,
              child: RefreshIndicator(
                key: ValueKey(_refreshKey),
                onRefresh: _handleRefresh,
                color: DesignToken.primary,
                backgroundColor: DesignToken.white,
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: EdgeInsets.fromLTRB(16, 14, 16, bottomPadding),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _buildWalletIntro(theme),

                      const SizedBox(height: 14),

                      // Total Points Card
                      _buildTotalPointsCard(),

                      const SizedBox(height: 14),

                      // Stats Cards Row
                      Row(
                        children: [
                          Expanded(
                            child: _buildStatCard(
                              icon: Icons.pending_actions,
                              label: l10n.pending,
                              value: _buildPendingCount(idsReady),
                              color: DesignToken.orange,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildStatCard(
                              icon: Icons.check_circle,
                              label: l10n.approved,
                              value: _buildApprovedCount(idsReady),
                              color: DesignToken.success,
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 14),

                      // Quick Action Button
                      Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              DesignToken.secondary,
                              DesignToken.purpleShade500,
                              DesignToken.blue600,
                            ],
                            begin: Alignment.centerLeft,
                            end: Alignment.centerRight,
                          ),
                          borderRadius: BorderRadius.circular(18),
                          boxShadow: [
                            BoxShadow(
                              color: DesignToken.secondary.withValues(alpha: 0.28),
                              blurRadius: 16,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: Material(
                          color: DesignToken.transparent,
                          child: InkWell(
                            onTap: () => context.push('/add-bill'),
                            borderRadius: BorderRadius.circular(18),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 14,
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(7),
                                    decoration: BoxDecoration(
                                      color: DesignToken.white.withValues(alpha: 0.2),
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(
                                      Icons.add_circle_outline,
                                      color: DesignToken.white,
                                      size: 24,
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Text(
                                    l10n.addNewBill,
                                    style: AppTextStyles.nunitoBold.copyWith(
                                      fontSize: 16,
                                      color: DesignToken.white,
                                      letterSpacing: 0.2,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 16),

                      // Recent Bills Section
                      _buildSectionHeader(
                        icon: Icons.receipt_long,
                        title: l10n.recentBills,
                        subtitle: 'Latest 10 updates',
                      ),

                      const SizedBox(height: 8),

                      // Bills List
                      _buildBillsList(idsReady),

                      const SizedBox(height: 14),
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

  Widget _buildWalletIntro(ThemeData theme) {
    final isDark = theme.brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: isDark
            ? theme.colorScheme.surface.withValues(alpha: 0.8)
            : DesignToken.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: DesignToken.primary.withValues(alpha: isDark ? 0.3 : 0.12),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: DesignToken.primary.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.account_balance_wallet_outlined,
              size: 18,
              color: DesignToken.primary,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Track your points and bill rewards in one place',
              style: AppTextStyles.nunitoSemiBold.copyWith(
                fontSize: 13,
                color: DesignToken.textDark.withValues(alpha: 0.75),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: DesignToken.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: DesignToken.primary, size: 18),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: AppTextStyles.nunitoBold.copyWith(
                  fontSize: 18,
                  color: DesignToken.textDark,
                ),
              ),
              Text(
                subtitle,
                style: AppTextStyles.nunitoRegular.copyWith(
                  fontSize: 12,
                  color: DesignToken.textDark.withValues(alpha: 0.6),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTotalPointsCard() {
    final l10n = AppLocalizations.of(context)!;
    final pointsData = _userPointsSyncService.pointsData.value;
    final totalPoints = (pointsData?['totalPoints'] as num?)?.toInt() ?? 0;
    final tier = pointsData?['tier'] as String? ?? 'Bronze';
    final isReady = pointsData != null;
    if (!isReady && !_idsLoaded) {
      // Show loading state
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              DesignToken.primary,
              DesignToken.primary.withOpacity(0.85),
              DesignToken.primary.withOpacity(0.7),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(22),
          boxShadow: [
            BoxShadow(
              color: DesignToken.primary.withOpacity(0.35),
              blurRadius: 20,
              spreadRadius: 2,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Total Points',
                      style: AppTextStyles.nunitoRegular.copyWith(
                        fontSize: 14,
                        color: DesignToken.white.withValues(alpha: 0.9),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '0',
                      style: AppTextStyles.nunitoBold.copyWith(
                        fontSize: 32,
                        color: DesignToken.white,
                      ),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 7,
                  ),
                  decoration: BoxDecoration(
                    color: DesignToken.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    'Silver',
                    style: AppTextStyles.nunitoSemiBold.copyWith(
                      fontSize: 14,
                      color: DesignToken.white,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
          ],
        ),
      );
    }

    return _buildPointsCardContent(
      totalPoints: totalPoints,
      tier: tier,
      l10n: l10n,
    );
  }

  Widget _buildPointsCardContent({
    required int totalPoints,
    required String tier,
    required AppLocalizations l10n,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            DesignToken.primary,
            DesignToken.primary.withOpacity(0.85),
            DesignToken.primary.withOpacity(0.7),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: DesignToken.primary.withOpacity(0.35),
            blurRadius: 20,
            spreadRadius: 2,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.totalPoints,
                    style: AppTextStyles.nunitoRegular.copyWith(
                      fontSize: 14,
                      color: DesignToken.white.withValues(alpha: 0.9),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '$totalPoints',
                    style: AppTextStyles.nunitoBold.copyWith(
                      fontSize: 32,
                      color: DesignToken.white,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 7,
                ),
                decoration: BoxDecoration(
                  color: DesignToken.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  tier,
                  style: AppTextStyles.nunitoSemiBold.copyWith(
                    fontSize: 14,
                    color: DesignToken.white,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String label,
    required Widget value,
    required Color color,
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final bg = isDark ? theme.colorScheme.surface : DesignToken.white;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: DesignToken.primary.withOpacity(isDark ? 0.14 : 0.08),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: DesignToken.black.withValues(alpha: 0.08),
              blurRadius: 14,
            spreadRadius: 1,
              offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(9),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [color.withOpacity(0.2), color.withOpacity(0.1)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(11),
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(height: 14),
          value,
          const SizedBox(height: 6),
          Text(
            label,
            style: AppTextStyles.nunitoMedium.copyWith(
              fontSize: 12,
              color: DesignToken.textDark.withOpacity(0.7),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPendingCount(bool idsReady) {
    if (!idsReady) {
      return Text(
        '...',
        style: AppTextStyles.nunitoBold.copyWith(
          fontSize: 20,
          color: DesignToken.textDark,
        ),
      );
    }

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('bills')
          .where('carpenterId', whereIn: _carpenterIds)
          .where('status', isEqualTo: 'pending')
          .snapshots(),
      builder: (context, snapshot) {
        final count = snapshot.hasData ? snapshot.data!.docs.length : 0;
        return Text(
          '$count',
          style: AppTextStyles.nunitoBold.copyWith(
            fontSize: 20,
            color: DesignToken.textDark,
          ),
        );
      },
    );
  }

  Widget _buildApprovedCount(bool idsReady) {
    if (!idsReady) {
      return Text(
        '...',
        style: AppTextStyles.nunitoBold.copyWith(
          fontSize: 20,
          color: DesignToken.textDark,
        ),
      );
    }

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('bills')
          .where('carpenterId', whereIn: _carpenterIds)
          .where('status', isEqualTo: 'approved')
          .snapshots(),
      builder: (context, snapshot) {
        final count = snapshot.hasData ? snapshot.data!.docs.length : 0;
        return Text(
          '$count',
          style: AppTextStyles.nunitoBold.copyWith(
            fontSize: 20,
            color: DesignToken.textDark,
          ),
        );
      },
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'approved':
        return DesignToken.success;
      case 'pending':
        return DesignToken.orange;
      case 'rejected':
        return DesignToken.error;
      default:
        return DesignToken.grey500;
    }
  }

  String _getStatusLabel(String status, BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    switch (status.toLowerCase()) {
      case 'approved':
        return l10n.statusApproved;
      case 'pending':
        return l10n.statusPending;
      case 'rejected':
        return l10n.statusRejected;
      default:
        return status.toUpperCase();
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status.toLowerCase()) {
      case 'approved':
        return Icons.check_circle;
      case 'pending':
        return Icons.pending;
      case 'rejected':
        return Icons.cancel;
      default:
        return Icons.receipt;
    }
  }

  Widget _buildBillsList(bool idsReady) {
    if (!idsReady) {
      return const Padding(
        padding: EdgeInsets.all(32),
        child: Center(child: CircularProgressIndicator()),
      );
    }

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('bills')
          .where('carpenterId', whereIn: _carpenterIds)
          .orderBy('createdAt', descending: true)
          .limit(10)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          final theme = Theme.of(context);
          final isDark = theme.brightness == Brightness.dark;
          return Container(
              padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              color: isDark ? theme.colorScheme.surface : DesignToken.white,
                borderRadius: BorderRadius.circular(18),
            ),
            child: Column(
              children: [
                const Icon(
                  Icons.error_outline,
                  size: 48,
                  color: DesignToken.error,
                ),
                const SizedBox(height: 12),
                Text(
                  'Error loading bills',
                  style: AppTextStyles.nunitoSemiBold.copyWith(
                    fontSize: 16,
                    color: DesignToken.error,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '${snapshot.error}',
                  style: AppTextStyles.nunitoRegular.copyWith(
                    fontSize: 12,
                    color: DesignToken.textDark.withOpacity(0.5),
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          );
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: CircularProgressIndicator(),
            ),
          );
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          final theme = Theme.of(context);
          final isDarkEmpty = theme.brightness == Brightness.dark;
          return Container(
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              color: isDarkEmpty
                  ? theme.colorScheme.surface
                  : DesignToken.white,
              borderRadius: BorderRadius.circular(18),
            ),
            child: Column(
              children: [
                Icon(
                  Icons.receipt_long_outlined,
                  size: 48,
                  color: DesignToken.textDark.withOpacity(0.3),
                ),
                const SizedBox(height: 12),
                Text(
                  AppLocalizations.of(context)!.noBillsYet,
                  style: AppTextStyles.nunitoSemiBold.copyWith(
                    fontSize: 16,
                    color: DesignToken.textDark.withOpacity(0.6),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  AppLocalizations.of(context)!.submitFirstBill,
                  style: AppTextStyles.nunitoRegular.copyWith(
                    fontSize: 14,
                    color: DesignToken.textDark.withOpacity(0.5),
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          );
        }

        final bills = snapshot.data!.docs;

        return ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: bills.length,
          separatorBuilder: (context, index) => const SizedBox(height: 6),
          itemBuilder: (context, index) {
            final bill = bills[index].data() as Map<String, dynamic>;
            final amount = bill['amount'] ?? 0.0;
            final status = bill['status'] ?? 'pending';
            final pointsEarned = bill['pointsEarned'] ?? 0;
            final createdAt = bill['createdAt'] as Timestamp?;
            final storeName = bill['storeName'] ?? '';

            final theme = Theme.of(context);
            final isDark = theme.brightness == Brightness.dark;
            final cardBg = isDark
                ? theme.colorScheme.surface
                : DesignToken.white;
            return Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: cardBg,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: DesignToken.primary.withOpacity(isDark ? 0.14 : 0.09),
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: DesignToken.black.withValues(alpha: 0.06),
                    blurRadius: 14,
                    spreadRadius: 0.5,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    width: 46,
                    height: 46,
                    decoration: BoxDecoration(
                      color: _getStatusColor(status).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      _getStatusIcon(status),
                      color: _getStatusColor(status),
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          storeName.isNotEmpty
                              ? storeName
                              : AppLocalizations.of(context)!.billLabel,
                          style: AppTextStyles.nunitoBold.copyWith(
                            fontSize: 14,
                            color: DesignToken.textDark,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Text(
                              '₹${amount.toStringAsFixed(0)}',
                              style: AppTextStyles.nunitoSemiBold.copyWith(
                                fontSize: 13,
                                color: DesignToken.primary,
                              ),
                            ),
                            if (pointsEarned > 0) ...[
                              const SizedBox(width: 6),
                              Text(
                                '• $pointsEarned pts',
                                style: AppTextStyles.nunitoRegular.copyWith(
                                  fontSize: 12,
                                  color: DesignToken.textDark.withOpacity(0.6),
                                ),
                              ),
                            ],
                          ],
                        ),
                        if (createdAt != null) ...[
                          const SizedBox(height: 4),
                          Text(
                            _formatDate(createdAt.toDate()),
                            style: AppTextStyles.nunitoRegular.copyWith(
                              fontSize: 11,
                              color: DesignToken.textDark.withOpacity(0.5),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: _getStatusColor(status).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: _getStatusColor(status).withOpacity(0.3),
                      ),
                    ),
                    child: Text(
                      _getStatusLabel(status, context),
                      style: AppTextStyles.nunitoSemiBold.copyWith(
                        fontSize: 11,
                        color: _getStatusColor(status),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  String _formatDate(DateTime date) {
    final l10n = AppLocalizations.of(context)!;
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      if (difference.inHours == 0) {
        if (difference.inMinutes == 0) {
          return l10n.justNow;
        }
        return l10n.minutesAgo(difference.inMinutes);
      }
      return l10n.hoursAgo(difference.inHours);
    } else if (difference.inDays == 1) {
      return l10n.yesterday;
    } else if (difference.inDays < 7) {
      return l10n.daysAgo(difference.inDays);
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }
}
