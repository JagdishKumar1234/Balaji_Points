import 'package:shared_preferences/shared_preferences.dart';

/// Persists home screen "rankings & daily winner" section expansion (less density on first open).
class HomeLayoutPrefs {
  HomeLayoutPrefs._();

  static const String _rankingsExpandedKey = 'home_rankings_expanded_v1';

  static Future<bool> isRankingsSectionExpanded() async {
    final p = await SharedPreferences.getInstance();
    // Default expanded so existing users keep the prior layout; once collapsed, pref sticks.
    return p.getBool(_rankingsExpandedKey) ?? true;
  }

  static Future<void> setRankingsSectionExpanded(bool value) async {
    final p = await SharedPreferences.getInstance();
    await p.setBool(_rankingsExpandedKey, value);
  }
}
