import 'package:balaji_points/config/routes.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  // The real app router must know both legal pages; an unknown path is what
  // throws a GoException when Profile or registration opens them.
  for (final path in [
    '/terms',
    '/privacy',
    '/about-us',
    '/register',
    '/my-branch',
  ]) {
    test('app router has a page for $path', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final router = container.read(routerProvider);
      final match = router.configuration.findMatch(Uri.parse(path));
      expect(match.isError, isFalse, reason: '$path has no route');
      expect(match.uri.path, path);
    });
  }
}
