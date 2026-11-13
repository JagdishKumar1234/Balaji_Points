import 'dart:async';

import 'package:balaji_points/l10n/app_localizations.dart';
import 'package:balaji_points/providers/loading_provider.dart';
import 'package:balaji_points/presentation/widgets/shared/loading_overlay.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

/// Logout shows the app loader until it finishes, then always hides it,
/// even though the screen that started it has been replaced.
void main() {
  testWidgets('loader shows during logout and clears after leaving', (
    tester,
  ) async {
    final done = Completer<void>();
    final showStarter = ValueNotifier(true);
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          builder: (_, child) =>
              Stack(children: [child!, const LoadingOverlay()]),
          home: ValueListenableBuilder<bool>(
            valueListenable: showStarter,
            builder: (_, show, __) => show
                ? Consumer(
                    builder: (context, ref, _) => TextButton(
                      onPressed: () => ref.withLoader(() async {
                        await done.future;
                        // Logout navigates away: the starting screen goes.
                        showStarter.value = false;
                      }, message: 'Logging out…'),
                      child: const Text('logout'),
                    ),
                  )
                : const Text('LOGIN'),
          ),
        ),
      ),
    );
    await tester.tap(find.text('logout'));
    await tester.pump();
    expect(find.text('Logging out…'), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    done.complete();
    await tester.pump();
    await tester.pump();
    expect(find.text('LOGIN'), findsOneWidget);
    expect(find.text('Logging out…'), findsNothing);
    expect(find.byType(CircularProgressIndicator), findsNothing);
  });
}
