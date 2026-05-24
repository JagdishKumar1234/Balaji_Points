// filepath: lib/app.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:balaji_points/l10n/app_localizations.dart';
import 'core/design/app_theme.dart';
import 'core/constants/app_constants.dart';
import 'config/routes.dart';
import 'presentation/widgets/loading_overlay.dart';
import 'presentation/providers/theme_provider.dart';
import 'presentation/providers/locale_provider.dart';

class BalajiPointsApp extends ConsumerWidget {
  const BalajiPointsApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    final themeMode = ref.watch(themeModeProvider);
    final locale = ref.watch(localeProvider);

    return MaterialApp.router(
      debugShowCheckedModeBanner: false,
      title: AppConstants.appName,

      // Theme Configuration (Light & Dark)
      theme: AppThemeData.light,
      darkTheme: AppThemeData.dark,
      themeMode: themeMode,

      // Localization Configuration
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('en'), // English
        Locale('hi'), // Hindi
        Locale('ta'), // Tamil
      ],
      locale: locale, // User-selected locale

      // Routing
      routerConfig: router,

      // Loading Overlay
      builder: (context, child) => Stack(
        children: [
          if (child != null) child,
          const LoadingOverlay(),
        ],
      ),
    );
  }
}
