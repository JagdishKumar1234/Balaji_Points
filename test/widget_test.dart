import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:balaji_points/app.dart';

void main() {
  testWidgets('BalajiPointsApp smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const ProviderScope(child: BalajiPointsApp()));
    expect(find.byType(BalajiPointsApp), findsOneWidget);
  });
}
