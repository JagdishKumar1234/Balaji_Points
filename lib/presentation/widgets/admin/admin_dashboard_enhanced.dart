import 'package:flutter/material.dart';
import 'package:balaji_points/core/design/app_spacing.dart';
import 'package:balaji_points/core/design/app_typography.dart';
import 'package:balaji_points/core/design/app_radius.dart';
import 'package:balaji_points/core/layout/responsive.dart';

extension _BuildContextTheme on BuildContext {
  Color get themePrimary => Theme.of(this).primaryColor;
  Color get themeTextSecondary => Theme.of(this).textTheme.bodySmall?.color ?? Colors.grey;
  Color get themeBackground => Theme.of(this).scaffoldBackgroundColor;
}

/// Enhanced admin dashboard with attractive cards and responsive layout
class AdminDashboardEnhanced extends StatelessWidget {
  final int totalUsers;
  final int pendingBills;
  final int approvedBills;
  final int totalRevenue;
  final VoidCallback onPendingBillsClick;
  final VoidCallback onApprovedBillsClick;
  final VoidCallback onUsersClick;
  final VoidCallback onRevenueClick;

  const AdminDashboardEnhanced({
    super.key,
    required this.totalUsers,
    required this.pendingBills,
    required this.approvedBills,
    required this.totalRevenue,
    required this.onPendingBillsClick,
    required this.onApprovedBillsClick,
    required this.onUsersClick,
    required this.onRevenueClick,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          _buildHeader(context),
          const SizedBox(height: AppSpacing.xl2),

          // Stats Grid
          _buildStatsGrid(context),
          const SizedBox(height: AppSpacing.xl2),

          // Quick Actions
          _buildQuickActionsGrid(context),
          const SizedBox(height: AppSpacing.xl2),

          // Recent Activity Section (optional)
          _buildRecentActivitySection(context),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Dashboard',
          style: AppTypography.displaySmall(
            color: context.themePrimary,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          'Welcome back! Here\'s your business overview.',
          style: AppTypography.bodyMedium(
            color: context.themeTextSecondary,
          ),
        ),
      ],
    );
  }

  Widget _buildStatsGrid(BuildContext context) {
    final isDesktop = context.isDesktop;
    final crossAxisCount = isDesktop ? 4 : (context.isTablet ? 3 : 2);

    return GridView.count(
      crossAxisCount: crossAxisCount,
      mainAxisSpacing: AppSpacing.md,
      crossAxisSpacing: AppSpacing.md,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      childAspectRatio: 1.2,
      children: [
        _buildStatCard(
          context,
          icon: Icons.pending_actions,
          label: 'Pending Bills',
          value: '$pendingBills',
          color: Colors.orange,
          onTap: onPendingBillsClick,
        ),
        _buildStatCard(
          context,
          icon: Icons.check_circle,
          label: 'Approved Bills',
          value: '$approvedBills',
          color: Colors.green,
          onTap: onApprovedBillsClick,
        ),
        _buildStatCard(
          context,
          icon: Icons.people,
          label: 'Total Users',
          value: '$totalUsers',
          color: Colors.blue,
          onTap: onUsersClick,
        ),
        _buildStatCard(
          context,
          icon: Icons.trending_up,
          label: 'Revenue',
          value: '₹$totalRevenue',
          color: Colors.purple,
          onTap: onRevenueClick,
        ),
      ],
    );
  }

  Widget _buildStatCard(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String value,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.md),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                color.withValues(alpha: 0.12),
                color.withValues(alpha: 0.06),
              ],
            ),
            borderRadius: BorderRadius.circular(AppRadius.md),
            border: Border.all(
              color: color.withValues(alpha: 0.2),
              width: 1,
            ),
          ),
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Icon
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 28),
              ),
              const SizedBox(height: AppSpacing.sm),
              // Value
              Text(
                value,
                style: AppTypography.h3(color: context.themePrimary),
              ),
              // Label
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTypography.bodySmall(
                  color: context.themeTextSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuickActionsGrid(BuildContext context) {
    final isDesktop = context.isDesktop;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Quick Actions',
          style: AppTypography.h5(color: context.themePrimary),
        ),
        const SizedBox(height: AppSpacing.md),
        GridView.count(
          crossAxisCount: isDesktop ? 4 : (context.isTablet ? 2 : 1),
          mainAxisSpacing: AppSpacing.md,
          crossAxisSpacing: AppSpacing.md,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          childAspectRatio: 3.5,
          children: [
            _buildActionButton(
              context,
              icon: Icons.description,
              label: 'View Pending Bills',
              onTap: onPendingBillsClick,
            ),
            _buildActionButton(
              context,
              icon: Icons.people_alt,
              label: 'Manage Users',
              onTap: onUsersClick,
            ),
            _buildActionButton(
              context,
              icon: Icons.inventory_2,
              label: 'View Products',
              onTap: () {},
            ),
            _buildActionButton(
              context,
              icon: Icons.settings,
              label: 'Settings',
              onTap: () {},
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildActionButton(
    BuildContext context, {
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.sm),
        child: Container(
          decoration: BoxDecoration(
            color: context.themePrimary.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(AppRadius.sm),
            border: Border.all(
              color: context.themePrimary.withValues(alpha: 0.15),
              width: 1,
            ),
          ),
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.sm,
          ),
          child: Row(
            children: [
              Icon(icon, color: context.themePrimary, size: 20),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.bodyMedium(
                    color: context.themePrimary,
                  ),
                ),
              ),
              Icon(
                Icons.arrow_forward_ios,
                color: context.themePrimary.withValues(alpha: 0.5),
                size: 16,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRecentActivitySection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Recent Activity',
          style: AppTypography.h5(color: context.themePrimary),
        ),
        const SizedBox(height: AppSpacing.md),
        Container(
          decoration: BoxDecoration(
            color: context.themeBackground.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(AppRadius.md),
            border: Border.all(
              color: context.themePrimary.withValues(alpha: 0.1),
              width: 1,
            ),
          ),
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            children: [
              _buildActivityItem(
                context,
                icon: Icons.check_circle,
                title: 'Bill #B001 Approved',
                subtitle: 'by Admin - 2 hours ago',
                color: Colors.green,
              ),
              const Divider(height: AppSpacing.md),
              _buildActivityItem(
                context,
                icon: Icons.person_add,
                title: 'New User Registered',
                subtitle: 'Carpenter: John Doe - 4 hours ago',
                color: Colors.blue,
              ),
              const Divider(height: AppSpacing.md),
              _buildActivityItem(
                context,
                icon: Icons.trending_up,
                title: 'Revenue Updated',
                subtitle: 'Total: ₹15,450 - Just now',
                color: Colors.purple,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildActivityItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
  }) {
    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: AppTypography.bodyMedium(
                  color: context.themePrimary,
                ),
              ),
              Text(
                subtitle,
                style: AppTypography.bodySmall(
                  color: context.themeTextSecondary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
