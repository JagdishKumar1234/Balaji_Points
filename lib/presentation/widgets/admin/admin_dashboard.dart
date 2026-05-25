import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:balaji_points/core/design/app_colors.dart';
import 'package:balaji_points/core/design/app_typography.dart';


/// Admin dashboard: 7 manage cards with counts (bills, orders) and pattern background.
class AdminDashboard extends StatefulWidget {
  const AdminDashboard({
    super.key,
    required this.onOpenSection,
  });

  final void Function(String section) onOpenSection;

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  static const List<_SectionCard> _sections = [
    _SectionCard(id: 'pending', label: 'Pending Bills', icon: Icons.receipt_long, color: Color(0xFFE8F5E9)),   // green
    _SectionCard(id: 'history', label: 'Bill History', icon: Icons.history, color: Color(0xFFE3F2FD)),         // blue
    _SectionCard(id: 'offers', label: 'Offers', icon: Icons.local_offer, color: AppColors.lightSoftSurface),            // orange
    _SectionCard(id: 'users', label: 'Users', icon: Icons.people, color: Color(0xFFF3E5F5)),                  // purple
    _SectionCard(id: 'notifications', label: 'Notifications', icon: Icons.notifications, color: Color(0xFFFFEBEE)), // red/pink
    _SectionCard(id: 'products', label: 'Products', icon: Icons.inventory_2, color: Color(0xFFE0F7FA)),       // cyan
    _SectionCard(id: 'orders', label: 'Orders', icon: Icons.shopping_bag, color: Color(0xFFFFEBEE)),          // red/pink
    _SectionCard(id: 'spin', label: 'Spin', icon: Icons.casino, color: AppColors.warning),                    // amber
  ];

  int _refreshKey = 0;

  Future<void> _onRefresh() async {
    setState(() => _refreshKey++);
    await Future.delayed(const Duration(milliseconds: 400));
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned.fill(
          child: CustomPaint(
            painter: _DashboardPatternPainter(),
          ),
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
                        // Total users = all docs in `users`
                        final totalUsersCount = usersDocs.length;
                        // Carpenters = matches the same rule used in UsersList:
                        // exclude role == 'admin', include role == 'carpenter' or missing/empty role.
                        final carpentersCount = usersDocs.where((doc) {
                          final data = doc.data();
                          final role = data['role'] as String?;
                          if (role == 'admin') return false;
                          return role == null || role.isEmpty || role == 'carpenter';
                        }).length;

                    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                      stream: FirebaseFirestore.instance
                          .collection('notification_logs')
                          .where('type',
                              whereIn: const [
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
                            if (s.id == 'notifications') {
                              count = notificationCount;
                            }
                            if (s.id == 'users') {
                              count = totalUsersCount;
                              secondaryCount = carpentersCount;
                            }
                            return _SectionTile(
                              section: s,
                              count: count,
                              secondaryCount: secondaryCount,
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
    required this.color,
  });
  final String id;
  final String label;
  final IconData icon;
  final Color color;
}

class _SectionTile extends StatelessWidget {
  const _SectionTile({
    required this.section,
    required this.onTap,
    this.count,
    this.secondaryCount,
  });
  final _SectionCard section;
  final VoidCallback onTap;
  final int? count;
  final int? secondaryCount;

  @override
  Widget build(BuildContext context) {
    final iconColor = _iconColorFor(section.color);
    return Material(
      borderRadius: BorderRadius.circular(20),
      elevation: 4,
      shadowColor: iconColor.withValues(alpha: 0.35),
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
                section.color,
                _darken(section.color, 0.06),
              ],
            ),
            border: Border.all(
              color: iconColor.withValues(alpha: 0.4),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: iconColor.withValues(alpha: 0.2),
                blurRadius: 8,
                offset: const Offset(0, 4),
                spreadRadius: 0,
              ),
              BoxShadow(
                color: AppColors.black.withValues(alpha: 0.06),
                blurRadius: 6,
                offset: const Offset(0, 2),
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
                          color: iconColor.withValues(alpha: 0.18),
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: iconColor.withValues(alpha: 0.2),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Icon(
                          section.icon,
                          size: 28,
                          color: iconColor,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        section.label,
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.labelLarge().copyWith(
                          fontSize: 13,
                          color: context.themePrimary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              if (section.id == 'users' && secondaryCount != null)
                Positioned(
                  top: 8,
                  right: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: iconColor,
                      borderRadius: BorderRadius.circular(999),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.black.withValues(alpha: 0.2),
                          blurRadius: 4,
                          offset: const Offset(0, 1),
                        ),
                      ],
                    ),
                    child: Text(
                      '$secondaryCount',
                      style: AppTypography.labelLarge().copyWith(
                        fontSize: 12,
                        color: AppColors.white,
                      ),
                    ),
                  ),
                )
              else if (count != null && count! > 0)
                Positioned(
                  top: 8,
                  right: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: iconColor,
                      borderRadius: BorderRadius.circular(999),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.black.withValues(alpha: 0.2),
                          blurRadius: 4,
                          offset: const Offset(0, 1),
                        ),
                      ],
                    ),
                    child: Text(
                      '$count',
                      style: AppTypography.labelLarge().copyWith(
                        fontSize: 12,
                        color: AppColors.white,
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

  Color _darken(Color color, double amount) {
    assert(amount >= 0 && amount <= 1);
    return Color.fromARGB(
      (color.a * 255.0).round().clamp(0, 255),
      (color.r * 255.0 * (1 - amount)).round().clamp(0, 255),
      (color.g * 255.0 * (1 - amount)).round().clamp(0, 255),
      (color.b * 255.0 * (1 - amount)).round().clamp(0, 255),
    );
  }

  Color _iconColorFor(Color bg) {
    if (bg.toARGB32() == const Color(0xFFE8F5E9).toARGB32()) return const Color(0xFF2E7D32);
    if (bg.toARGB32() == const Color(0xFFE3F2FD).toARGB32()) return const Color(0xFF1565C0);
    if (bg.toARGB32() == AppColors.lightSoftSurface.toARGB32()) return const Color(0xFFE65100);
    if (bg.toARGB32() == const Color(0xFFF3E5F5).toARGB32()) return const Color(0xFF7B1FA2);
    if (bg.toARGB32() == const Color(0xFFE0F7FA).toARGB32()) return const Color(0xFF00838F);
    if (bg.toARGB32() == const Color(0xFFFFEBEE).toARGB32()) return const Color(0xFFC62828);
    if (bg.toARGB32() == AppColors.warning.toARGB32()) return const Color(0xFFF9A825);
    return AppColors.lightPrimary;
  }
}

/// Stylish wooden-pattern background: base gradient, grain lines, and subtle weave.
class _DashboardPatternPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final rect = Rect.fromLTWH(0, 0, size.width, size.height);

    // Base: soft vertical gradient (lighter top, slightly darker bottom – wood feel)
    final baseGradient = LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [
        AppColors.lightSoftSurface,
        Color.lerp(AppColors.lightSoftSurface, AppColors.lightSoftSurface, 0.12)!,
        Color.lerp(AppColors.lightSoftSurface, AppColors.lightSoftSurface, 0.06)!,
      ],
      stops: const [0.0, 0.5, 1.0],
    );
    canvas.drawRect(rect, Paint()..shader = baseGradient.createShader(rect));

    // Horizontal wood-grain lines (stylish, subtle)
    const grainSpacing = 28.0;
    final grainPaint = Paint()
      ..color = AppColors.lightSecondary.withValues(alpha: 0.06)
      ..strokeWidth = 1.2
      ..style = PaintingStyle.stroke;
    for (double y = 0; y < size.height + grainSpacing; y += grainSpacing) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), grainPaint);
    }

    // Diagonal weave (left-going) – warm tint
    const diagonalSpacing = 32.0;
    final diagPaint = Paint()
      ..color = AppColors.lightSecondary.withValues(alpha: 0.055)
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;
    for (double d = -size.height; d < size.width + size.height; d += diagonalSpacing) {
      canvas.drawLine(
        Offset(d, -1),
        Offset(d + size.height + 1, size.height + 1),
        diagPaint,
      );
    }

    // Diagonal weave (right-going) – crosshatch
    final diag2Paint = Paint()
      ..color = AppColors.lightSecondary.withValues(alpha: 0.035)
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;
    for (double d = -size.height; d < size.width + size.height; d += diagonalSpacing) {
      canvas.drawLine(
        Offset(d + size.height + 1, -1),
        Offset(d, size.height + 1),
        diag2Paint,
      );
    }

    // Subtle dot grid for texture
    const dotSpacing = 20.0;
    final dotPaint = Paint()
      ..color = AppColors.lightSecondary.withValues(alpha: 0.08)
      ..style = PaintingStyle.fill;
    for (double x = 0; x < size.width + dotSpacing; x += dotSpacing) {
      for (double y = 0; y < size.height + dotSpacing; y += dotSpacing) {
        canvas.drawCircle(Offset(x, y), 1.2, dotPaint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
