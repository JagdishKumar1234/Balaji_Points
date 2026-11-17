import 'package:shared_preferences/shared_preferences.dart';

/// How the admin likes the dashboard menu: the order of the sections and
/// grid or list. Kept on this device; a fresh install starts from defaults.
class AdminDashboardPrefs {
  AdminDashboardPrefs._();

  static const _orderKey = 'admin_dashboard_order';
  static const _listKey = 'admin_dashboard_list_view';

  /// [defaults] in the saved order. Sections added in a later version (not
  /// in [saved]) go at the end; ones no longer offered are dropped.
  static List<String> applyOrder(List<String> defaults, List<String>? saved) {
    if (saved == null || saved.isEmpty) return List.of(defaults);
    final known = defaults.toSet();
    final ordered = <String>[
      for (final id in saved)
        if (known.contains(id)) id,
    ];
    final seen = ordered.toSet();
    return [
      ...{...ordered},
      for (final id in defaults)
        if (!seen.contains(id)) id,
    ];
  }

  static Future<List<String>?> loadOrder() async {
    try {
      return (await SharedPreferences.getInstance()).getStringList(_orderKey);
    } catch (_) {
      return null;
    }
  }

  static Future<void> saveOrder(List<String>? order) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (order == null) {
        await prefs.remove(_orderKey);
      } else {
        await prefs.setStringList(_orderKey, order);
      }
    } catch (_) {}
  }

  static Future<bool> loadListView() async {
    try {
      return (await SharedPreferences.getInstance()).getBool(_listKey) ?? false;
    } catch (_) {
      return false;
    }
  }

  static Future<void> saveListView(bool list) async {
    try {
      await (await SharedPreferences.getInstance()).setBool(_listKey, list);
    } catch (_) {}
  }
}
