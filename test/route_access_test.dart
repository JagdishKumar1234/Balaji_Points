import 'package:balaji_points/config/routes.dart';
import 'package:flutter_test/flutter_test.dart';

/// Who can open which screen, for every role (null = not logged in).
void main() {
  const members = [
    'carpenter',
    'architect',
    'engineer',
    'interior_designer',
    'mason', // a custom role from the super admin
  ];
  const everyone = [null, ...members, 'admin', 'super_admin'];

  test('guest screens open for everyone, logged in or not', () {
    for (final role in everyone) {
      for (final path in [
        '/guest',
        '/branches',
        '/careers',
        '/contact-us',
        '/login',
        '/register',
        '/terms',
        '/privacy',
      ]) {
        expect(redirectForRole(path, role), isNull, reason: '$role $path');
      }
    }
  });

  test('catalogs and the reader open for every role and guests', () {
    for (final role in [null, ...members, 'admin']) {
      for (final path in [
        '/catalogs',
        '/catalogs/doors',
        '/catalogs/doors/abc123',
      ]) {
        expect(redirectForRole(path, role), isNull, reason: '$role $path');
      }
    }
    // The super admin too (it is not an admin path).
    expect(redirectForRole('/catalogs/doors/abc123', 'super_admin'), isNull);
  });

  test('member roles and guests can never open admin screens', () {
    for (final role in [null, ...members]) {
      for (final path in [
        '/admin',
        '/admin/add-bill',
        '/admin/carpenter-profile/x',
        '/super-admin',
      ]) {
        expect(redirectForRole(path, role), '/', reason: '$role $path');
      }
    }
  });

  test('admin and super admin stay in their own panels', () {
    expect(redirectForRole('/admin', 'admin'), isNull);
    expect(redirectForRole('/admin/carpenter-profile/x', 'admin'), isNull);
    expect(redirectForRole('/super-admin', 'admin'), '/admin');
    expect(redirectForRole('/notifications', 'admin'), '/admin/notifications');
    expect(redirectForRole('/super-admin', 'super_admin'), isNull);
    expect(redirectForRole('/admin', 'super_admin'), '/super-admin');
  });

  test('members keep their own screens', () {
    for (final role in members) {
      for (final path in ['/', '/wallet', '/profile', '/add-bill']) {
        expect(redirectForRole(path, role), isNull, reason: '$role $path');
      }
    }
  });
}
