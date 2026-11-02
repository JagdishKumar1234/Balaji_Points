import 'package:balaji_points/presentation/widgets/shared/responsive_role_navigation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const items = [
    RoleNavigationItem(
      label: 'Dashboard',
      icon: Icons.home_outlined,
      selectedIcon: Icons.home,
    ),
    RoleNavigationItem(
      label: 'Profile',
      icon: Icons.person_outline,
      selectedIcon: Icons.person,
    ),
  ];

  for (final width in [390.0, 800.0, 1024.0, 1440.0]) {
    testWidgets('role navigation adapts at ${width.toInt()}px', (tester) async {
      tester.view.physicalSize = Size(width, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(useMaterial3: true),
          home: Scaffold(
            body: ResponsiveRoleNavigation(
              roleLabel: 'Member',
              items: items,
              selectedIndex: 0,
              onSelected: (_) {},
              child: const Center(child: Text('Role content')),
            ),
          ),
        ),
      );

      expect(find.text('Role content'), findsOneWidget);
      expect(
        find.byType(NavigationRail),
        width >= 840 ? findsOneWidget : findsNothing,
      );
    });
  }
}
