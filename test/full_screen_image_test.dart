import 'dart:io';

import 'package:balaji_points/l10n/app_localizations.dart';
import 'package:balaji_points/presentation/widgets/shared/full_screen_image_viewer.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

const _closeKey = ValueKey('image-viewer-close');

Future<void> _open(WidgetTester tester) async {
  await tester.pumpWidget(
    MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Builder(
        builder: (context) => Scaffold(
          body: TextButton(
            onPressed: () =>
                showFullScreenImage(context, 'https://example.com/bill.jpg'),
            child: const Text('open'),
          ),
        ),
      ),
    ),
  );
  await tester.tap(find.text('open'));
  await tester.pumpAndSettle();
}

Matrix4 _matrix(WidgetTester tester) => tester
    .widget<InteractiveViewer>(find.byType(InteractiveViewer))
    .transformationController!
    .value;

void main() {
  testWidgets('fills the screen, with zoom up to 5x', (tester) async {
    await _open(tester);
    final viewer = tester.widget<InteractiveViewer>(
      find.byType(InteractiveViewer),
    );
    expect(viewer.maxScale, 5);
    expect(
      tester.getSize(find.byType(InteractiveViewer)),
      tester.getSize(find.byType(MaterialApp)),
    );
  });

  testWidgets('double tap zooms in, and again zooms back out', (tester) async {
    await _open(tester);
    final centre = tester.getCenter(find.byType(InteractiveViewer));
    Future<void> doubleTap() async {
      await tester.tapAt(centre);
      await tester.pump(const Duration(milliseconds: 50));
      await tester.tapAt(centre);
      await tester.pumpAndSettle();
    }

    await doubleTap();
    expect(_matrix(tester).getMaxScaleOnAxis(), 2.5);
    await doubleTap();
    expect(_matrix(tester).getMaxScaleOnAxis(), 1);
  });

  testWidgets('the close button returns to the screen behind', (tester) async {
    await _open(tester);
    await tester.tap(find.byKey(_closeKey));
    await tester.pumpAndSettle();
    expect(find.byType(FullScreenImageViewer), findsNothing);
    expect(find.text('open'), findsOneWidget);
  });

  testWidgets('device Back closes it too', (tester) async {
    await _open(tester);
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.byType(FullScreenImageViewer), findsNothing);
  });

  testWidgets('a failed image says so and can still be closed', (tester) async {
    await _open(tester);
    expect(find.text('Failed to load image'), findsOneWidget);
    expect(find.byKey(_closeKey), findsOneWidget);
  });

  test('offer and bill images all use the full-screen viewer', () {
    const files = [
      'lib/presentation/widgets/admin/pending_bills_list.dart',
      'lib/presentation/widgets/admin/bill_history_list.dart',
      'lib/presentation/widgets/admin/offers_management.dart',
      'lib/presentation/widgets/carpenter/offers_carousel.dart',
      'lib/presentation/screens/admin/bill_details_page.dart',
      'lib/presentation/screens/admin/carpenter_profile_detail_screen.dart',
      'lib/presentation/screens/carpenter/wallet/wallet_page.dart',
    ];
    for (final path in files) {
      final source = File(path).readAsStringSync();
      expect(source, contains('showFullScreenImage('), reason: path);
      expect(source, isNot(contains('InteractiveViewer(')), reason: path);
    }
  });

  test('both bill thumbnails on the carpenter profile can be tapped', () {
    final source = File(
      'lib/presentation/screens/admin/carpenter_profile_detail_screen.dart',
    ).readAsStringSync();
    // Pending bills and history both use one shared bill card, whose photo
    // opens full screen.
    expect(
      'showFullScreenImage(context, image)'.allMatches(source),
      hasLength(1),
    );
    expect(
      RegExp(r'_BillCard\(').allMatches(source).length,
      greaterThanOrEqualTo(3), // class + pending + history
    );
  });
}
