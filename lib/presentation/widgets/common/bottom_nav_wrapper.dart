import 'package:balaji_points/core/design/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// A wrapper widget that adds bottom navigation bar to any screen
/// Used to maintain consistent bottom navigation across all logged-in screens
class BottomNavWrapper extends StatelessWidget {
  final Widget child;
  final int selectedIndex;

  const BottomNavWrapper({
    super.key,
    required this.child,
    this.selectedIndex = -1, // -1 means no tab selected (for non-main screens)
  });

  void _onItemTapped(BuildContext context, int index) {
    switch (index) {
      case 0:
        context.go('/');
        break;
      case 1:
        // Navigate to wallet page (which is at index 1 in DashboardPage)
        // For now, we'll push to home and let dashboard handle it
        context.go('/');
        break;
      case 2:
        context.go('/profile');
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.transparent,
      body: child,
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: selectedIndex >= 0 ? selectedIndex : 0,
        onTap: (index) => _onItemTapped(context, index),
        selectedItemColor: AppColors.lightSecondary,
        unselectedItemColor: AppColors.white,
        backgroundColor: AppColors.lightPrimary,
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: "Home"),
          BottomNavigationBarItem(
            icon: Icon(Icons.monetization_on_outlined),
            label: "Earn",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            label: "Profile",
          ),
        ],
      ),
    );
  }
}
