import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:balaji_points/core/constants/app_constants.dart';

/// Locale notifier for managing language selection (English/Hindi/Tamil)
class LocaleNotifier extends Notifier<Locale> {
  @override
  Locale build() {
    _loadLocale();
    return const Locale('en'); // Default to English
  }

  /// Load locale from shared preferences
  Future<void> _loadLocale() async {
    final prefs = await SharedPreferences.getInstance();
    final languageCode = prefs.getString(AppConstants.keyLanguage);

    if (languageCode != null) {
      state = Locale(languageCode);
    }
  }

  /// Set specific locale
  Future<void> setLocale(Locale locale) async {
    state = locale;
    await _saveLocale();
  }

  /// Save locale to shared preferences
  Future<void> _saveLocale() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(AppConstants.keyLanguage, state.languageCode);
  }

  /// Toggle between English and Hindi
  Future<void> toggleLocale() async {
    state = state.languageCode == 'en'
        ? const Locale('hi')
        : const Locale('en');
    await _saveLocale();
  }

  /// Check if current language is Hindi
  bool get isHindi => state.languageCode == 'hi';

  /// Get current language name
  String get currentLanguageName {
    switch (state.languageCode) {
      case 'en':
        return 'English';
      case 'hi':
        return 'हिंदी';
      case 'ta':
        return 'தமிழ்';
      default:
        return 'English';
    }
  }
}

/// Provider for locale
final localeProvider = NotifierProvider<LocaleNotifier, Locale>(
  () => LocaleNotifier(),
);
