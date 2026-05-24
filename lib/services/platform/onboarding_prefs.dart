import 'package:shared_preferences/shared_preferences.dart';

/// Persists whether the user has finished the first-launch onboarding flow.
/// Cleared on app uninstall / data clear — onboarding shows again after reinstall.
class OnboardingPrefs {
  OnboardingPrefs._();

  static const String _keyCompleted = 'onboarding_completed_v1';

  static Future<bool> isCompleted() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyCompleted) ?? false;
  }

  static Future<void> setCompleted() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyCompleted, true);
  }
}
