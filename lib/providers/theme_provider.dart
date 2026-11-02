import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:balaji_points/core/constants/app_constants.dart';
import 'package:balaji_points/core/design/app_colors.dart';

/// Persists and exposes the app ThemeMode (light / dark / system).
class ThemeModeNotifier extends Notifier<ThemeMode> {
  @override
  ThemeMode build() {
    _load();
    return ThemeMode.system;
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString(AppConstants.keyThemeMode);
    if (saved != null) {
      state = ThemeMode.values.firstWhere(
        (m) => m.toString() == saved,
        orElse: () => ThemeMode.system,
      );
    }
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    state = mode;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(AppConstants.keyThemeMode, mode.toString());
  }

  Future<void> toggleTheme() async {
    await setThemeMode(state == ThemeMode.light ? ThemeMode.dark : ThemeMode.light);
  }

  bool get isDarkMode => state == ThemeMode.dark;
}

final themeModeProvider = NotifierProvider<ThemeModeNotifier, ThemeMode>(
  () => ThemeModeNotifier(),
);

/// Persists and exposes the app Color Palette (Navy, Emerald, Indigo, Crimson, Teal, Orange).
class ThemeColorPaletteNotifier extends Notifier<AppColorPalette> {
  @override
  AppColorPalette build() {
    _load();
    return AppColorPalette.navy;
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString(AppConstants.keyThemeColorPalette);
    if (saved != null) {
      state = AppColorPalette.values.firstWhere(
        (p) => p.toString() == saved,
        orElse: () => AppColorPalette.navy,
      );
    }
  }

  Future<void> setColorPalette(AppColorPalette palette) async {
    state = palette;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(AppConstants.keyThemeColorPalette, palette.toString());
  }
}

final themeColorPaletteProvider = NotifierProvider<ThemeColorPaletteNotifier, AppColorPalette>(
  () => ThemeColorPaletteNotifier(),
);

/// Convenience: `ref.watch(themeIsDarkProvider)` → bool.
/// Follows system theme when mode == ThemeMode.system.
final themeIsDarkProvider = Provider<bool>((ref) {
  final mode = ref.watch(themeModeProvider);
  if (mode == ThemeMode.system) {
    final brightness =
        WidgetsBinding.instance.platformDispatcher.platformBrightness;
    return brightness == Brightness.dark;
  }
  return mode == ThemeMode.dark;
});
