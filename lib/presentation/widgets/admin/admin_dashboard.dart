import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:balaji_points/core/design/app_colors.dart';
import 'package:balaji_points/core/design/app_typography.dart';

// Accent palette — icon color + light/dark card background tints
// Each entry: [iconColor, lightBg, darkBg]
const List<List<Color>> _kAccents = [
  [Color(0xFF2E7D32), Color(0xFFE8F5E9), Color(0xFF1B3A1F)], // green  — pending
  [Color(0xFF1565C0), Color(0xFFE3F2FD), Color(0xFF0D2A4A)], // blue   — history
  [Color(0xFFE65100), Color(0xFFFFF3E0), Color(0xFF3B1A00)], // orange — offers
  [Color(0xFF7B1FA2), Color(0xFFF3E5F5), Color(0xFF2D0B40)], // purple — users
  [Color(0xFFC62828), Color(0xFFFFEBEE), Color(0xFF3D0A0A)], // red    — notif/orders
  [Color(0xFF00838F), Color(0xFFE0F7FA), Color(0xFF003338)], // cyan   — products
  [Color(0xFFF9A825), Color(0xFFFFF8E1), Color(0xFF3A2A00)], // amber  — spin
];

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
            color: context.themePrimary,
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

                            return GridView.count(
                              padding: EdgeInsets.zero,
                              crossAxisCount: 2,
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
    final accent = _kAccents[section.accentIndex];
    final iconColor = accent[0];
    final cardBg  = isDark ? accent[2] : accent[1];

    return Material(
      borderRadius: BorderRadius.circular(20),
      elevation: 4,
      shadowColor: iconColor.withValues(alpha: 0.30),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                cardBg,
                Color.lerp(cardBg, iconColor, 0.08)!,
              ],
            ),
            border: Border.all(
              color: iconColor.withValues(alpha: isDark ? 0.35 : 0.30),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: iconColor.withValues(alpha: isDark ? 0.15 : 0.18),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
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
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: iconColor.withValues(alpha: isDark ? 0.25 : 0.18),
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: iconColor.withValues(alpha: 0.20),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Icon(section.icon, size: 28, color: iconColor),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        section.label,
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.labelLarge().copyWith(
                          fontSize: 13,
                          color: context.themeTextPrimary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              // Badge
              if (section.id == 'users' && secondaryCount != null)
                _Badge(label: '$secondaryCount', iconColor: iconColor)
              else if (count != null && count! > 0)
                _Badge(label: '$count', iconColor: iconColor),
            ],
          ),
        ),
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge({required this.label, required this.iconColor});
  final String label;
  final Color iconColor;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: 8,
      right: 8,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: iconColor,
          borderRadius: BorderRadius.circular(999),
          boxShadow: [
            BoxShadow(
              color: AppColors.black.withValues(alpha: 0.20),
              blurRadius: 4,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: Text(
          label,
          style: AppTypography.labelLarge().copyWith(
            fontSize: 12,
            color: AppColors.white,
          ),
        ),
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
    final baseBg = isDark ? AppColors.darkBackground : AppColors.lightSoftSurface;
    final lineColor = isDark
        ? AppColors.darkBorder.withValues(alpha: 0.25)
        : AppColors.lightSecondary.withValues(alpha: 0.06);
    final dotColor = isDark
        ? AppColors.darkBorder.withValues(alpha: 0.30)
        : AppColors.lightSecondary.withValues(alpha: 0.08);

    final rect = Rect.fromLTWH(0, 0, size.width, size.height);
    canvas.drawRect(rect, Paint()..color = baseBg);

    // Horizontal grain lines
    const grainSpacing = 28.0;
    final grainPaint = Paint()
      ..color = lineColor
      ..strokeWidth = 1.2
      ..style = PaintingStyle.stroke;
    for (double y = 0; y < size.height + grainSpacing; y += grainSpacing) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), grainPaint);
    }

    // Diagonal weave
    const diagonalSpacing = 32.0;
    final diagPaint = Paint()
      ..color = lineColor
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;
    for (double d = -size.height; d < size.width + size.height; d += diagonalSpacing) {
      canvas.drawLine(Offset(d, -1), Offset(d + size.height + 1, size.height + 1), diagPaint);
    }

    // Dot grid
    const dotSpacing = 20.0;
    final dotPaint = Paint()
      ..color = dotColor
      ..style = PaintingStyle.fill;
    for (double x = 0; x < size.width + dotSpacing; x += dotSpacing) {
      for (double y = 0; y < size.height + dotSpacing; y += dotSpacing) {
        canvas.drawCircle(Offset(x, y), 1.2, dotPaint);
      }
    }
  }

  @override
  bool shouldRepaint(_DashboardPatternPainter old) => old.isDark != isDark;
}
