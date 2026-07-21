import 'package:balaji_points/core/design/app_radius.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:balaji_points/core/design/app_colors.dart';
import 'package:balaji_points/presentation/widgets/shared/app_text.dart';
import 'package:balaji_points/core/layout/responsive.dart';

// Accent palette — [iconColor, lightCardBg]
// In dark mode the card bg is always the same dark surface; only the icon
// colour changes so the grid stays calm instead of each tile being a
// different deep colour.
const List<List<Color>> _kAccents = [
  [Color(0xFF4CAF50), Color(0xFFE8F5E9)], // green  — pending
  [Color(0xFF42A5F5), Color(0xFFE3F2FD)], // blue   — history
  [Color(0xFFFF8A65), Color(0xFFFFF3E0)], // orange — offers
  [Color(0xFFBA68C8), Color(0xFFF3E5F5)], // purple — users
  [Color(0xFFEF5350), Color(0xFFFFEBEE)], // red    — notif/orders
  [Color(0xFF26C6DA), Color(0xFFE0F7FA)], // cyan   — products
  [Color(0xFFFFCA28), Color(0xFFFFF8E1)], // amber  — spin
];

// Single dark card surface used by every tile in dark mode
const Color _kDarkCardBg = Color(0xFF1A1F2E);

/// Admin dashboard: 8 section cards with live Firestore counts.
class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key, required this.onOpenSection});
  final void Function(String section) onOpenSection;

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  static const List<_SectionCard> _sections = [
    _SectionCard(id: 'pending',       label: 'Pending Bills',  icon: Icons.receipt_long,  accentIndex: 0),
    _SectionCard(id: 'history',       label: 'Bill History',   icon: Icons.history,        accentIndex: 1),
    _SectionCard(id: 'offers',        label: 'Offers',         icon: Icons.local_offer,    accentIndex: 2),
    _SectionCard(id: 'users',         label: 'Users',          icon: Icons.people,         accentIndex: 3),
    _SectionCard(id: 'notifications', label: 'Notifications',  icon: Icons.notifications,  accentIndex: 4),
    _SectionCard(id: 'products',      label: 'Products',       icon: Icons.inventory_2,    accentIndex: 5),
    _SectionCard(id: 'orders',        label: 'Orders',         icon: Icons.shopping_bag,   accentIndex: 4),
    _SectionCard(id: 'spin',          label: 'Spin',           icon: Icons.casino,         accentIndex: 6),
    _SectionCard(id: 'points-repair', label: 'Points Repair',  icon: Icons.build_circle,   accentIndex: 2),
  ];

  int _refreshKey = 0;

  Future<void> _onRefresh() async {
    setState(() => _refreshKey++);
    await Future.delayed(const Duration(milliseconds: 400));
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Stack(
      children: [
        Positioned.fill(
          child: CustomPaint(painter: _DashboardPatternPainter(isDark: isDark)),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
          child: RefreshIndicator(
            onRefresh: _onRefresh,
            color: context.themeContentColor,
            child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              key: ValueKey<int>(_refreshKey),
              stream: FirebaseFirestore.instance
                  .collection('bills')
                  .where('status', isEqualTo: 'pending')
                  .snapshots(),
              builder: (context, billsSnap) {
                final pendingBillsCount = billsSnap.data?.docs.length ?? 0;
                return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                  key: ValueKey<int>(_refreshKey),
                  stream: FirebaseFirestore.instance
                      .collection('orders')
                      .where('status', isEqualTo: 'pending')
                      .snapshots(),
                  builder: (context, ordersSnap) {
                    final pendingOrdersCount = ordersSnap.data?.docs.length ?? 0;
                    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                      key: ValueKey<int>(_refreshKey),
                      stream: FirebaseFirestore.instance
                          .collection('users')
                          .snapshots(),
                      builder: (context, usersSnap) {
                        final usersDocs = usersSnap.data?.docs ?? const [];
                        final totalUsersCount = usersDocs.length;
                        final carpentersCount = usersDocs.where((doc) {
                          final role = doc.data()['role'] as String?;
                          if (role == 'admin') return false;
                          return role == null || role.isEmpty || role == 'carpenter';
                        }).length;

                        return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                          stream: FirebaseFirestore.instance
                              .collection('notification_logs')
                              .where('type', whereIn: const [
                                'newPendingBill',
                                'newUserRegistered',
                              ])
                              .snapshots(),
                          builder: (context, notifSnap) {
                            final notificationCount =
                                notifSnap.hasError ? 0 : notifSnap.data?.docs.length ?? 0;

                            // Responsive grid: 2 columns on mobile, 3 on tablet, 4 on large desktop
                            final crossAxisCount = switch (context.deviceType) {
                              DeviceType.mobile => 2,
                              DeviceType.tablet => 3,
                              DeviceType.desktop => 3,
                              DeviceType.largeDesktop => 4,
                            };

                            return GridView.count(
                              padding: EdgeInsets.zero,
                              crossAxisCount: crossAxisCount,
                              mainAxisSpacing: 12,
                              crossAxisSpacing: 12,
                              childAspectRatio: 1.0,
                              physics: const AlwaysScrollableScrollPhysics(),
                              children: _sections.map((s) {
                                int? count;
                                int? secondaryCount;
                                if (s.id == 'pending') count = pendingBillsCount;
                                if (s.id == 'orders') count = pendingOrdersCount;
                                if (s.id == 'notifications') count = notificationCount;
                                if (s.id == 'users') {
                                  count = totalUsersCount;
                                  secondaryCount = carpentersCount;
                                }
                                return _SectionTile(
                                  section: s,
                                  count: count,
                                  secondaryCount: secondaryCount,
                                  isDark: isDark,
                                  onTap: () => widget.onOpenSection(s.id),
                                );
                              }).toList(),
                            );
                          },
                        );
                      },
                    );
                  },
                );
              },
            ),
          ),
        ),
      ],
    );
  }
}

class _SectionCard {
  const _SectionCard({
    required this.id,
    required this.label,
    required this.icon,
    required this.accentIndex,
  });
  final String id;
  final String label;
  final IconData icon;
  final int accentIndex;
}

class _SectionTile extends StatelessWidget {
  const _SectionTile({
    required this.section,
    required this.onTap,
    required this.isDark,
    this.count,
    this.secondaryCount,
  });
  final _SectionCard section;
  final VoidCallback onTap;
  final bool isDark;
  final int? count;
  final int? secondaryCount;

  @override
  Widget build(BuildContext context) {
    final accent     = _kAccents[section.accentIndex];
    final iconColor  = accent[0];
    // Dark mode: one unified surface colour for all cards — only the icon
    // colour differs, keeping the grid calm and readable.
    final cardBg     = isDark ? _kDarkCardBg : accent[1];
    final borderColor = isDark
        ? AppColors.darkBorder
        : iconColor.withValues(alpha: 0.20);

    return Material(
      borderRadius: AppRadius.all16,
      elevation: isDark ? 0 : 2,
      shadowColor: isDark ? AppColors.transparent : iconColor.withValues(alpha: 0.20),
      color: cardBg,
      child: InkWell(
        onTap: onTap,
        borderRadius: AppRadius.all16,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: AppRadius.all16,
            border: Border.all(color: borderColor, width: 1),
          ),
          child: Stack(
            children: [
              Center(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Icon container — accent tint only
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: iconColor.withValues(alpha: isDark ? 0.15 : 0.12),
                          borderRadius: AppRadius.all16,
                        ),
                        child: Icon(section.icon, size: 28, color: iconColor),
                      ),
                      const SizedBox(height: 10),
                      AppText.label(
                        section.label,
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ),
              // Badge
              if (section.id == 'users' && secondaryCount != null)
                _Badge(label: '$secondaryCount', iconColor: iconColor, isDark: isDark)
              else if (count != null && count! > 0)
                _Badge(label: '$count', iconColor: iconColor, isDark: isDark),
            ],
          ),
        ),
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge({required this.label, required this.iconColor, required this.isDark});
  final String label;
  final Color iconColor;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: 10,
      right: 10,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: isDark ? iconColor.withValues(alpha: 0.85) : iconColor,
          borderRadius: BorderRadius.circular(999),
        ),
        child: AppText.labelSmall(label, color: AppColors.white),
      ),
    );
  }
}

/// Background pattern — adapts to light/dark.
class _DashboardPatternPainter extends CustomPainter {
  final bool isDark;
  const _DashboardPatternPainter({required this.isDark});

  @override
  void paint(Canvas canvas, Size size) {
    final baseBg = isDark ? AppColors.darkBackground : AppColors.softSurface;
    final dotColor = isDark
        ? AppColors.darkBorder.withValues(alpha: 0.18)
        : AppColors.gold.withValues(alpha: 0.06);

    final rect = Rect.fromLTWH(0, 0, size.width, size.height);
    canvas.drawRect(rect, Paint()..color = baseBg);

    // Subtle dot grid only — cleaner than grain lines
    const dotSpacing = 24.0;
    final dotPaint = Paint()
      ..color = dotColor
      ..style = PaintingStyle.fill;
    for (double x = dotSpacing / 2; x < size.width; x += dotSpacing) {
      for (double y = dotSpacing / 2; y < size.height; y += dotSpacing) {
        canvas.drawCircle(Offset(x, y), 1.0, dotPaint);
      }
    }
  }

  @override
  bool shouldRepaint(_DashboardPatternPainter old) => old.isDark != isDark;
}
