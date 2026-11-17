import 'dart:io';

import 'package:balaji_points/presentation/screens/admin/admin_notifications_page.dart';
import 'package:balaji_points/services/admin/admin_dashboard_prefs.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const defaults = ['requests', 'pending', 'history', 'offers', 'users'];

  group('admin menu order', () {
    test('no saved order keeps the default', () {
      expect(AdminDashboardPrefs.applyOrder(defaults, null), defaults);
      expect(AdminDashboardPrefs.applyOrder(defaults, []), defaults);
    });

    test('saved order is used', () {
      final saved = ['users', 'pending', 'requests', 'history', 'offers'];
      expect(AdminDashboardPrefs.applyOrder(defaults, saved), saved);
    });

    test('new sections go to the end, removed ones and repeats drop out', () {
      expect(
        AdminDashboardPrefs.applyOrder(defaults, [
          'users',
          'gone',
          'pending',
          'users',
        ]),
        ['users', 'pending', 'requests', 'history', 'offers'],
      );
    });
  });

  test('admin alert categories open the right admin screen', () {
    expect(
      AdminNotificationCategory.ofType('newPendingBill')?.section,
      'pending',
    );
    expect(
      AdminNotificationCategory.ofType('newUserRegistered')?.section,
      'requests',
    );
    expect(AdminNotificationCategory.ofType('billApproved'), isNull);
  });

  test('section screens show no theme toggle or logout', () {
    final source = File(
      'lib/presentation/screens/admin/admin_home_page.dart',
    ).readAsStringSync();
    expect(
      source,
      contains('if (_showDashboard)\n              _AdminMoreMenu('),
    );
    expect(source, isNot(contains('_AdminThemeToggle(')));
  });
}
